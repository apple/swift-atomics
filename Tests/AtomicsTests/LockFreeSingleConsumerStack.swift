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

class LockFreeSingleConsumerStack<Element> {
  struct Node {
    let value: Element
    var next: UnsafeMutablePointer<Node>?
  }
  typealias NodePtr = UnsafeMutablePointer<Node>

  private var _last = UnsafeAtomic<NodePtr?>.create(nil)
  private var _consumerCount = UnsafeAtomic<Int>.create(0)
  private var foo = 0

  deinit {
    // Discard remaining nodes
    while let _ = pop() {}
    _last.destroy()
    _consumerCount.destroy()
  }

  // Push the given element to the top of the stack.
  // It is okay to concurrently call this in an arbitrary number of threads.
  func push(_ value: Element) {
    let new = NodePtr.allocate(capacity: 1)
    new.initialize(to: Node(value: value, next: nil))

    var done = false
    var current = _last.load(ordering: .relaxed)
    while !done {
      new.pointee.next = current
      (done, current) = _last.compareExchange(
        expected: current,
        desired: new,
        ordering: .releasing)
    }
  }

  // Pop and return the topmost element from the stack.
  // This method does not support multiple overlapping concurrent calls.
  func pop() -> Element? {
    precondition(
      _consumerCount.loadThenWrappingIncrement(ordering: .acquiring) == 0,
      "Multiple consumers detected")
    defer { _consumerCount.wrappingDecrement(ordering: .releasing) }
    var done = false
    var current = _last.load(ordering: .acquiring)
    while let c = current {
      (done, current) = _last.compareExchange(
        expected: c,
        desired: c.pointee.next,
        ordering: .acquiring)
      if done {
        let result = c.move()
        c.deallocate()
        return result.value
      }
    }
    return nil
  }
}

class LockFreeSingleConsumerStackTests: XCTestCase {
  func test_Basics() {
    let stack = LockFreeSingleConsumerStack<Int>()
    XCTAssertNil(stack.pop())
    stack.push(0)
    XCTAssertEqual(0, stack.pop())

    stack.push(1)
    stack.push(2)
    stack.push(3)
    stack.push(4)
    XCTAssertEqual(4, stack.pop())
    XCTAssertEqual(3, stack.pop())
    XCTAssertEqual(2, stack.pop())
    XCTAssertEqual(1, stack.pop())
    XCTAssertNil(stack.pop())
  }

  func test_ConcurrentPushes() {
    let stack = LockFreeSingleConsumerStack<(thread: Int, value: Int)>()

    let numThreads = 100
    let numValues = 10_000
    DispatchQueue.concurrentPerform(iterations: numThreads) { thread in
      for value in 1 ... numValues {
        stack.push((thread: thread, value: value))
      }
    }

    var expected: [Int] = Array(repeating: numValues, count: numThreads)
    while let (thread, value) = stack.pop() {
      XCTAssertEqual(expected[thread], value)
      expected[thread] -= 1
    }
    XCTAssertEqual(Array(repeating: 0, count: numThreads), expected)
  }

  func test_ConcurrentPushesAndPops() {
    let stack = LockFreeSingleConsumerStack<(thread: Int, value: Int)>()

    let numThreads = 100
    let numValues = 10_000

    var perThreadSums: [Int] = Array(repeating: 0, count: numThreads)
    let consumerQueue = DispatchQueue(label: "org.swift.background")
    consumerQueue.async {
      var count = 0
      while count < numThreads * numValues {
        // Note: busy wait
        if let (thread, value) = stack.pop() {
          perThreadSums[thread] += value
          count += 1
        }
      }
    }

    DispatchQueue.concurrentPerform(iterations: numThreads + 1) { thread in
      if thread < numThreads {
        // Producers
        for value in 0 ..< numValues {
          stack.push((thread: thread, value: value))
        }
      }
    }

    consumerQueue.sync {
      XCTAssertEqual(Array(repeating: numValues * (numValues - 1) / 2, count: numThreads), perThreadSums)
    }
  }

#if MANUAL_TEST_DISCOVERY
  public static var allTests = [
    ("test_Basics", test_Basics),
    ("test_ConcurrentPushes", test_ConcurrentPushes),
    ("test_ConcurrentPushesAndPops", test_ConcurrentPushesAndPops),
  ]
#endif
}
