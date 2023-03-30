//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// A lock-free linked list concurrency test. `n` threads are each
// racing on a linked list containing `n` values; in each iteration,
// each thread unlinks its corresponding value then reinserts it at
// the end of the list.

import XCTest
import Atomics
import Dispatch

private var iterations: Int {
  #if SWIFT_ATOMICS_LONG_TESTS
  return 1_000_000
  #else
  return 50_000
  #endif
}

private let nodeCount = ManagedAtomic<Int>(0)

private class List<Value: Equatable> {
  final class Node: AtomicReference {
    private let _next: UnsafeAtomic<Node?>
    private let _value: UnsafeAtomic<UnsafeMutablePointer<Value>?>

    init(pointer: UnsafeMutablePointer<Value>?, next: Node? = nil) {
      self._next = .create(next)
      self._value = .create(pointer)
      nodeCount.wrappingIncrement(ordering: .relaxed)
    }

    convenience init(_ value: Value?, next: Node? = nil) {
      if let value = value {
        let p = UnsafeMutablePointer<Value>.allocate(capacity: 1)
        p.initialize(to: value)
        self.init(pointer: p, next: next)
      } else {
        self.init(pointer: nil, next: next)
      }
    }

    deinit {
      // Prevent stack overflow when deinitializing a long chain
      var node = self._next.destroy()
      while node != nil && isKnownUniquelyReferenced(&node) {
        let next = node!._next.exchange(nil, ordering: .relaxed)
        withExtendedLifetime(node) {}
        node = next
      }

      if let p = self._value.destroy() {
        p.deinitialize(count: 1)
        p.deallocate()
      }
      nodeCount.wrappingDecrement(ordering: .relaxed)
    }

    var value: Value? { _value.load(ordering: .sequentiallyConsistent)?.pointee }

    func clearValue() -> UnsafeMutablePointer<Value>? {
      withExtendedLifetime(self) {
        _value.exchange(nil, ordering: .sequentiallyConsistent)
      }
    }

    var next: Node? { _next.load(ordering: .sequentiallyConsistent) }

    func clearNext() -> Node? {
      withExtendedLifetime(self) {
        _next.exchange(nil, ordering: .sequentiallyConsistent)
      }
    }

    func compareExchangeNext(expected: Node?, desired: Node?) -> (exchanged: Bool, original: Node?) {
      withExtendedLifetime(self) {
        _next.compareExchange(expected: expected, desired: desired, ordering: .sequentiallyConsistent)
      }
    }
  }

  let head: Node

  init<Elements: Collection>(from elements: Elements)
  where Elements.Element == Value {
    var n: Node? = nil
    for value in elements.reversed() {
      n = Node(value, next: n)
    }
    self.head = Node(nil, next: n)
  }

  deinit {
    // Prevent a stack overflow while recursively releasing list nodes.
    var node = head.clearNext()
    while let n = node {
      let next = n.clearNext()
      node = next
    }
  }
}

extension List {
  /// Move the given value to the end of this list. It is safe to call
  /// this concurrently on multiple threads as long as all invocations
  /// are using distinct values.
  func sink(_ value: Value) {
    var current = self.head
    var next = self.head.next
    var anchor = current
    var anchorNext = next
    var found = false

    var new: Node?
    while true {
      if let n = next {
        var v = n.value
        if !found, v == value {
          // Mark this node as deleted.
          found = true
          new = Node(pointer: n.clearValue(), next: nil)
          precondition(new?.value == value, "Concurrent sink invocations with the same value")
          v = nil
        }
        current = n
        next = n.next
        if v != nil {
          if current !== anchor {
            // Opportunistically unlink the chain of deleted nodes between `anchor` and `n`.
            _ = anchor.compareExchangeNext(expected: anchorNext, desired: n)
          }
          anchor = current
          anchorNext = next
        }
      } else {
        // `next` is nil. Append `new` to the end of the list.
        precondition(found, "Lost value \(value) in \(read())")
        let (exchanged, original) = current.compareExchangeNext(expected: nil, desired: new)
        if exchanged {
          if current !== anchor {
            // Opportunistically unlink the chain of deleted nodes between `anchor` and `new`.
            _ = anchor.compareExchangeNext(expected: anchorNext, desired: new)
          }
          return
        }
        next = original
      }
    }
  }

  /// Read out and return the contents of this list in an array. Note
  /// that this may return duplicate or missing elements if it is
  /// called concurrently with `sink`. (This is still safe -- the
  /// results may be useless, but the returned values are still
  /// valid.)
  @inline(never)
  func read() -> [Value?] {
    var result: [Value?] = []
    var node = head
    while let next = node.next {
      result.append(next.value)
      node = next
    }
    withExtendedLifetime(node) {}
    return result
  }
}

extension List where Value: Hashable {
  @inline(never)
  func readUnique(expectedCount: Int = 0) -> Set<Value> {
    var result: Set<Value> = []
    result.reserveCapacity(expectedCount)
    var node = head
    while let next = node.next {
      if let value = next.value {
        result.insert(value)
      }
      node = next
    }
    withExtendedLifetime(node) {}
    return result
  }
}


class StrongReferenceShuffleTests: XCTestCase {
  override func tearDown() {
    XCTAssertEqual(nodeCount.load(ordering: .relaxed), 0)
  }

  func checkSink(
    writers: Int,
    readers: Int,
    iterations: Int,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let list = List<Int>(from: 0 ..< writers)

    XCTAssertEqual(list.read(), Array(0 ..< writers),
      "Unexpected list contents at start",
      file: file, line: line)

    DispatchQueue.concurrentPerform(iterations: readers + writers) { id in
      if id < writers {
        for _ in 0 ..< iterations {
          list.sink(id)
        }
      } else {
        for _ in 0 ..< iterations {
          let elements = list.readUnique(expectedCount: writers)
          precondition(elements.count <= writers)
        }
      }
    }

    let contents = list.read()
    print(
      contents
        .map { value -> String in
          if let value = value { return "\(value)" }
          return "nil"
        }
        .joined(separator: ", "))
    let values = Set(contents.compactMap { $0 })
    XCTAssertEqual(values, Set(0 ..< writers),
      "Unexpected list contents at end",
      file: file, line: line)
  }

  func test_sink_01_00() { checkSink(writers: 1, readers: 0, iterations: iterations) }
  func test_sink_02_00() { checkSink(writers: 2, readers: 0, iterations: iterations) }
  func test_sink_04_00() { checkSink(writers: 4, readers: 0, iterations: iterations) }
  func test_sink_08_00() { checkSink(writers: 8, readers: 0, iterations: iterations) }

  func test_sink_01_01() { checkSink(writers: 1, readers: 1, iterations: iterations) }
  func test_sink_02_01() { checkSink(writers: 2, readers: 1, iterations: iterations) }
  func test_sink_04_01() { checkSink(writers: 4, readers: 1, iterations: iterations) }
  func test_sink_08_01() { checkSink(writers: 8, readers: 1, iterations: iterations) }

  func test_sink_01_02() { checkSink(writers: 1, readers: 2, iterations: iterations) }
  func test_sink_02_02() { checkSink(writers: 2, readers: 2, iterations: iterations) }
  func test_sink_04_02() { checkSink(writers: 4, readers: 2, iterations: iterations) }
  func test_sink_08_02() { checkSink(writers: 8, readers: 2, iterations: iterations) }

  func test_sink_01_04() { checkSink(writers: 1, readers: 4, iterations: iterations) }
  func test_sink_02_04() { checkSink(writers: 2, readers: 4, iterations: iterations) }
  func test_sink_04_04() { checkSink(writers: 4, readers: 4, iterations: iterations) }
  func test_sink_08_04() { checkSink(writers: 8, readers: 4, iterations: iterations) }

  func test_sink_01_08() { checkSink(writers: 1, readers: 8, iterations: iterations) }
  func test_sink_02_08() { checkSink(writers: 2, readers: 8, iterations: iterations) }
  func test_sink_04_08() { checkSink(writers: 4, readers: 8, iterations: iterations) }
  func test_sink_08_08() { checkSink(writers: 8, readers: 8, iterations: iterations) }

#if MANUAL_TEST_DISCOVERY
  public static var allTests = [
    ("test_sink_01_00", test_sink_01_00),
    ("test_sink_02_00", test_sink_02_00),
    ("test_sink_04_00", test_sink_04_00),
    ("test_sink_08_00", test_sink_08_00),
    ("test_sink_01_01", test_sink_01_01),
    ("test_sink_02_01", test_sink_02_01),
    ("test_sink_04_01", test_sink_04_01),
    ("test_sink_08_01", test_sink_08_01),
    ("test_sink_01_02", test_sink_01_02),
    ("test_sink_02_02", test_sink_02_02),
    ("test_sink_04_02", test_sink_04_02),
    ("test_sink_08_02", test_sink_08_02),
    ("test_sink_01_04", test_sink_01_04),
    ("test_sink_02_04", test_sink_02_04),
    ("test_sink_04_04", test_sink_04_04),
    ("test_sink_08_04", test_sink_08_04),
    ("test_sink_01_08", test_sink_01_08),
    ("test_sink_02_08", test_sink_02_08),
    ("test_sink_04_08", test_sink_04_08),
    ("test_sink_08_08", test_sink_08_08),
  ]
#endif
}
