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

private final class Node: AtomicReference {
  let value: Int

  init(_ value: Int = 0) {
    self.value = value
    Node.instances.wrappingIncrement(ordering: .relaxed)
  }
  deinit {
    precondition(Node.instances.load(ordering: .relaxed) > 0)
    Node.instances.wrappingDecrement(ordering: .relaxed)
  }

  static let instances = ManagedAtomic<Int>(0)
}

extension Node: CustomStringConvertible {
  var description: String {
    let unmanaged = Unmanaged.passRetained(self)
    defer { unmanaged.release() }
    return String(UInt(bitPattern: unmanaged.toOpaque()), radix: 16)
  }
}

@inline(never)
public func blackHole(_ value: AnyObject) {}
@inline(never)
public func blackHole(_ value: AnyObject?) {}

class StrongReferenceRace: XCTestCase {
  override func tearDown() {
    super.tearDown()
    let leftover = Node.instances.load(ordering: .relaxed)
    XCTAssertEqual(
      leftover, 0,
      "Leak - \(leftover) leftover instances remaining")
  }

  func checkLoad(count: Int, iterations: Int, file: StaticString = #file, line: UInt = #line) {
    let ref = UnsafeAtomic<Node>.create(Node())
    defer { ref.destroy() }

    DispatchQueue.concurrentPerform(iterations: count) { id in
      for _ in 0 ..< iterations {
        blackHole(ref.load(ordering: .relaxed))
      }
    }
  }
  func testLoad1() { checkLoad(count: 1, iterations: iterations) }
  func testLoad2() { checkLoad(count: 2, iterations: iterations) }
  func testLoad4() { checkLoad(count: 4, iterations: iterations) }
  func testLoad8() { checkLoad(count: 8, iterations: iterations) }
  func testLoad16() { checkLoad(count: 16, iterations: iterations) }

  func checkCompareExchange(count: Int, iterations: Int, file: StaticString = #file, line: UInt = #line) {
    let a = Node()
    let b = Node()
    let ref = UnsafeAtomic<Node>.create(a)
    defer { ref.destroy() }

    DispatchQueue.concurrentPerform(iterations: count) { id in
      var expected = a
      for _ in 0 ..< iterations {
        var done = false
        repeat {
          (done, expected) = ref.compareExchange(
            expected: expected,
            desired: expected === a ? b : a,
            ordering: .relaxed)
        } while !done
      }
    }
  }
  func testCompareExchange1() { checkCompareExchange(count: 1, iterations: iterations) }
  func testCompareExchange2() { checkCompareExchange(count: 2, iterations: iterations) }
  func testCompareExchange4() { checkCompareExchange(count: 4, iterations: iterations) }
  func testCompareExchange8() { checkCompareExchange(count: 8, iterations: iterations) }
  func testCompareExchange16() { checkCompareExchange(count: 16, iterations: iterations) }

  func checkCompareExchangeNil(count: Int, iterations: Int, file: StaticString = #file, line: UInt = #line) {
    let a = Node()
    let b = Node()
    let ref = UnsafeAtomic<Node?>.create(nil)
    defer { ref.destroy() }

    DispatchQueue.concurrentPerform(iterations: count) { id in
      var expected: Node? = nil
      for _ in 0 ..< iterations {
        var done = false
        repeat {
          (done, expected) = ref.compareExchange(
            expected: expected,
            desired: expected == nil ? a : expected === a ? b : nil,
            ordering: .relaxed)
        } while !done
      }
    }
  }
  func testCompareExchangeNil_01() { checkCompareExchangeNil(count: 1, iterations: iterations) }
  func testCompareExchangeNil_02() { checkCompareExchangeNil(count: 2, iterations: iterations) }
  func testCompareExchangeNil_04() { checkCompareExchangeNil(count: 4, iterations: iterations) }
  func testCompareExchangeNil_08() { checkCompareExchangeNil(count: 8, iterations: iterations) }
  func testCompareExchangeNil_16() { checkCompareExchangeNil(count: 16, iterations: iterations) }

  func checkLoadStore(readers: Int, writers: Int, iterations: Int, file: StaticString = #file, line: UInt = #line) {
    let a = Node()
    let b = Node()
    let ref = UnsafeAtomic<Node>.create(a)
    defer { ref.destroy() }

    DispatchQueue.concurrentPerform(iterations: readers + writers) { id in
      if id < writers {
        var next = b
        for _ in 0 ..< iterations {
          ref.store(next, ordering: .relaxed)
          next = next === a ? b : a
        }
      } else {
        for _ in 0 ..< iterations {
          blackHole(ref.load(ordering: .relaxed))
        }
      }
    }
  }
  func testLoadStore_01_01() { checkLoadStore(readers: 1, writers: 1, iterations: iterations) }
  func testLoadStore_02_01() { checkLoadStore(readers: 2, writers: 1, iterations: iterations) }
  func testLoadStore_04_01() { checkLoadStore(readers: 4, writers: 1, iterations: iterations) }
  func testLoadStore_08_01() { checkLoadStore(readers: 8, writers: 1, iterations: iterations) }
  func testLoadStore_16_01() { checkLoadStore(readers: 16, writers: 1, iterations: iterations) }

  func testLoadStore_01_02() { checkLoadStore(readers: 1, writers: 2, iterations: iterations) }
  func testLoadStore_02_02() { checkLoadStore(readers: 2, writers: 2, iterations: iterations) }
  func testLoadStore_04_02() { checkLoadStore(readers: 4, writers: 2, iterations: iterations) }
  func testLoadStore_08_02() { checkLoadStore(readers: 8, writers: 2, iterations: iterations) }
  func testLoadStore_16_02() { checkLoadStore(readers: 16, writers: 2, iterations: iterations) }

  func testLoadStore_01_04() { checkLoadStore(readers: 1, writers: 4, iterations: iterations) }
  func testLoadStore_02_04() { checkLoadStore(readers: 2, writers: 4, iterations: iterations) }
  func testLoadStore_04_04() { checkLoadStore(readers: 4, writers: 4, iterations: iterations) }
  func testLoadStore_08_04() { checkLoadStore(readers: 8, writers: 4, iterations: iterations) }
  func testLoadStore_16_04() { checkLoadStore(readers: 16, writers: 4, iterations: iterations) }

  func checkExchange(readers: Int, writers: Int, iterations: Int, file: StaticString = #file, line: UInt = #line) {
    let a = Node()
    let b = Node()
    let ref = UnsafeAtomic<Node?>.create(nil)
    defer { ref.destroy() }

    DispatchQueue.concurrentPerform(iterations: readers + writers) { id in
      if id < writers {
        var next: Node? = nil
        for _ in 0 ..< iterations {
          let old = ref.exchange(next, ordering: .relaxed)
          if old == nil { next = a }
          else if old === a { next = b }
          else { next = nil }
        }
      } else {
        for _ in 0 ..< iterations {
          blackHole(ref.load(ordering: .relaxed))
        }
      }
    }
  }
  func testExchange_01_01() { checkExchange(readers: 1, writers: 1, iterations: iterations) }
  func testExchange_02_01() { checkExchange(readers: 2, writers: 1, iterations: iterations) }
  func testExchange_04_01() { checkExchange(readers: 4, writers: 1, iterations: iterations) }
  func testExchange_08_01() { checkExchange(readers: 8, writers: 1, iterations: iterations) }
  func testExchange_16_01() { checkExchange(readers: 16, writers: 1, iterations: iterations) }

  func testExchange_01_02() { checkExchange(readers: 1, writers: 2, iterations: iterations) }
  func testExchange_02_02() { checkExchange(readers: 2, writers: 2, iterations: iterations) }
  func testExchange_04_02() { checkExchange(readers: 4, writers: 2, iterations: iterations) }
  func testExchange_08_02() { checkExchange(readers: 8, writers: 2, iterations: iterations) }
  func testExchange_16_02() { checkExchange(readers: 16, writers: 2, iterations: iterations) }

  func testExchange_01_04() { checkExchange(readers: 1, writers: 4, iterations: iterations) }
  func testExchange_02_04() { checkExchange(readers: 2, writers: 4, iterations: iterations) }
  func testExchange_04_04() { checkExchange(readers: 4, writers: 4, iterations: iterations) }
  func testExchange_08_04() { checkExchange(readers: 8, writers: 4, iterations: iterations) }
  func testExchange_16_04() { checkExchange(readers: 16, writers: 4, iterations: iterations) }

  func checkLifetimes(count: Int, iterations: Int, file: StaticString = #file, line: UInt = #line) {
    precondition(count > 1)
    let objects = (0 ..< count).map { ManagedAtomic<Node>(Node($0)) }
    let originals = objects.map { $0.load(ordering: .relaxed).value }

    DispatchQueue.concurrentPerform(iterations: count) { id in
      var object = objects[id].load(ordering: .acquiring)
      var i = id
      for _ in 0 ..< iterations {
        let j = (i + 1) % count
        object = objects[j].exchange(object, ordering: .acquiringAndReleasing)
        object = objects[i].exchange(object, ordering: .acquiringAndReleasing)
        i = j
      }
      while true {
        let new = objects[object.value].exchange(object, ordering: .acquiringAndReleasing)
        if new === object { break }
        object = new
      }
    }

    let reordered = objects.map { $0.load(ordering: .relaxed).value }
    print(originals, reordered)
    XCTAssertEqual(Set(originals), Set(reordered))
  }
  func testLifetimes_02() { checkLifetimes(count: 2, iterations: iterations) }
  func testLifetimes_04() { checkLifetimes(count: 4, iterations: iterations) }
  func testLifetimes_08() { checkLifetimes(count: 8, iterations: iterations) }
  func testLifetimes_16() { checkLifetimes(count: 16, iterations: iterations) }

#if MANUAL_TEST_DISCOVERY
  public static var allTests = [
    ("testLoad1", testLoad1),
    ("testLoad2", testLoad2),
    ("testLoad4", testLoad4),
    ("testLoad8", testLoad8),
    ("testLoad16", testLoad16),
    ("testCompareExchange1", testCompareExchange1),
    ("testCompareExchange2", testCompareExchange2),
    ("testCompareExchange4", testCompareExchange4),
    ("testCompareExchange8", testCompareExchange8),
    ("testCompareExchange16", testCompareExchange16),
    ("testCompareExchangeNil_01", testCompareExchangeNil_01),
    ("testCompareExchangeNil_02", testCompareExchangeNil_02),
    ("testCompareExchangeNil_04", testCompareExchangeNil_04),
    ("testCompareExchangeNil_08", testCompareExchangeNil_08),
    ("testCompareExchangeNil_16", testCompareExchangeNil_16),
    ("testLoadStore_01_01", testLoadStore_01_01),
    ("testLoadStore_02_01", testLoadStore_02_01),
    ("testLoadStore_04_01", testLoadStore_04_01),
    ("testLoadStore_08_01", testLoadStore_08_01),
    ("testLoadStore_16_01", testLoadStore_16_01),
    ("testLoadStore_01_02", testLoadStore_01_02),
    ("testLoadStore_02_02", testLoadStore_02_02),
    ("testLoadStore_04_02", testLoadStore_04_02),
    ("testLoadStore_08_02", testLoadStore_08_02),
    ("testLoadStore_16_02", testLoadStore_16_02),
    ("testLoadStore_01_04", testLoadStore_01_04),
    ("testLoadStore_02_04", testLoadStore_02_04),
    ("testLoadStore_04_04", testLoadStore_04_04),
    ("testLoadStore_08_04", testLoadStore_08_04),
    ("testLoadStore_16_04", testLoadStore_16_04),
    ("testExchange_01_01", testExchange_01_01),
    ("testExchange_02_01", testExchange_02_01),
    ("testExchange_04_01", testExchange_04_01),
    ("testExchange_08_01", testExchange_08_01),
    ("testExchange_16_01", testExchange_16_01),
    ("testExchange_01_02", testExchange_01_02),
    ("testExchange_02_02", testExchange_02_02),
    ("testExchange_04_02", testExchange_04_02),
    ("testExchange_08_02", testExchange_08_02),
    ("testExchange_16_02", testExchange_16_02),
    ("testExchange_01_04", testExchange_01_04),
    ("testExchange_02_04", testExchange_02_04),
    ("testExchange_04_04", testExchange_04_04),
    ("testExchange_08_04", testExchange_08_04),
    ("testExchange_16_04", testExchange_16_04),
    ("testLifetimes_02", testLifetimes_02),
    ("testLifetimes_04", testLifetimes_04),
    ("testLifetimes_08", testLifetimes_08),
    ("testLifetimes_16", testLifetimes_16),
  ]
#endif
}
