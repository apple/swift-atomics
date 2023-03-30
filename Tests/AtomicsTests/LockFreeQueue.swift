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

// A lock-free concurrent queue implementation adapted from
// M. Michael and M. Scott's 1996 paper [Michael 1996].
//
// [Michael 1996]: https://doi.org/10.1145/248052.248106
//
// While this is a nice illustration of the use of atomic strong references,
// this is a somewhat sloppy implementation of an old algorithm. If you need a
// lock-free queue for actual production use, it would probably be a good idea
// to look at some more recent algorithms before deciding on this one.
//
// Note: because this implementation uses reference counting, we don't need
// to implement a free list to resolve the original algorithm's use-after-free
// problem.

import XCTest
import Dispatch
import Atomics

private var iterations: Int {
  #if SWIFT_ATOMICS_LONG_TESTS
  return 1_000_000
  #else
  return 50_000
  #endif
}

private let nodeCount = ManagedAtomic<Int>(0)

class LockFreeQueue<Element> {
  final class Node: AtomicReference {
    let next: ManagedAtomic<Node?>
    var value: Element?

    init(value: Element?, next: Node?) {
      self.value = value
      self.next = ManagedAtomic(next)
      nodeCount.wrappingIncrement(ordering: .relaxed)
    }

    deinit {
      var values = 0
      // Prevent stack overflow when reclaiming a long queue
      var node = self.next.exchange(nil, ordering: .relaxed)
      while node != nil && isKnownUniquelyReferenced(&node) {
        let next = node!.next.exchange(nil, ordering: .relaxed)
        withExtendedLifetime(node) {
          values += 1
        }
        node = next
      }
      if values > 0 {
        print(values)
      }
      nodeCount.wrappingDecrement(ordering: .relaxed)
    }
  }

  let head: ManagedAtomic<Node>
  let tail: ManagedAtomic<Node>

  // Used to distinguish removed nodes from active nodes with a nil `next`.
  let marker = Node(value: nil, next: nil)

  init() {
    let dummy = Node(value: nil, next: nil)
    self.head = ManagedAtomic(dummy)
    self.tail = ManagedAtomic(dummy)
  }

  func enqueue(_ newValue: Element) {
    let new = Node(value: newValue, next: nil)

    var tail = self.tail.load(ordering: .acquiring)
    while true {
      let next = tail.next.load(ordering: .acquiring)
      if tail === marker || next === marker {
        // The node we loaded has been unlinked by a dequeue on another thread.
        // Try again.
        tail = self.tail.load(ordering: .acquiring)
        continue
      }
      if let next = next {
        // Assist competing threads by nudging `self.tail` forward a step.
        let (exchanged, original) = self.tail.compareExchange(
          expected: tail,
          desired: next,
          ordering: .acquiringAndReleasing)
        tail = (exchanged ? next : original)
        continue
      }
      let (exchanged, current) = tail.next.compareExchange(
        expected: nil,
        desired: new,
        ordering: .acquiringAndReleasing
      )
      if exchanged {
        _ = self.tail.compareExchange(expected: tail, desired: new, ordering: .releasing)
        return
      }
      tail = current!
    }
  }

  func dequeue() -> Element? {
    while true {
      let head = self.head.load(ordering: .acquiring)
      let next = head.next.load(ordering: .acquiring)
      if next === marker { continue }
      guard let n = next else { return nil }
      let tail = self.tail.load(ordering: .acquiring)
      if head === tail {
        // Nudge `tail` forward a step to make sure it doesn't fall off the
        // list when we unlink this node.
        _ = self.tail.compareExchange(expected: tail, desired: n, ordering: .acquiringAndReleasing)
      }
      if self.head.compareExchange(expected: head, desired: n, ordering: .releasing).exchanged {
        let result = n.value!
        n.value = nil
        // To prevent threads that are suspended in `enqueue`/`dequeue` from
        // holding onto arbitrarily long chains of removed nodes, we unlink
        // removed nodes by replacing their `next` value with the special
        // `marker`.
        head.next.store(marker, ordering: .releasing)
        return result
      }
    }
  }
}

class QueueTests: XCTestCase {
  override func tearDown() {
    XCTAssertEqual(nodeCount.load(ordering: .relaxed), 0)
  }

  func check(readers: Int, writers: Int, count: Int) {
    let queue = LockFreeQueue<(writer: Int, value: Int)>()
    let num = ManagedAtomic(0)
    DispatchQueue.concurrentPerform(iterations: writers + readers) { id in
      if id < writers {
        // Writer
        for i in 0 ..< count {
          queue.enqueue((id, i))
        }
      } else {
        // Reader
        var values = (0 ..< writers).map { _ in -1 }
        while num.load(ordering: .relaxed) < writers * count {
          // Spin until we get a value
          guard let (writer, value) = queue.dequeue() else { continue }
          precondition(writer >= 0 && writer < writers)
          precondition(readers == 1 ? value == values[writer] + 1 : value > values[writer])
          values[writer] = value
          num.wrappingIncrement(ordering: .relaxed)
        }
      }
    }
  }

  func test01_10() {
    check(readers: 1, writers: 10, count: iterations)
  }

  func test02_10() {
    check(readers: 2, writers: 10, count: iterations)
  }

  func test04_10() {
    check(readers: 2, writers: 10, count: iterations)
  }

  func test16_16() {
    check(readers: 16, writers: 16, count: iterations)
  }

#if MANUAL_TEST_DISCOVERY
  public static var allTests = [
    ("test01_10", test01_10),
    ("test02_10", test02_10),
    ("test04_10", test04_10),
    ("test16_16", test16_16),
  ]
#endif
}
