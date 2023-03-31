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

class AtomicLazyReferenceTests: XCTestCase {
  func test_unsafe_create_destroy() {
    XCTAssertEqual(LifetimeTracked.instances, 0)
    let v = UnsafeAtomicLazyReference<LifetimeTracked>.create()
    defer {
      v.destroy()
      XCTAssertEqual(LifetimeTracked.instances, 0)
    }
    XCTAssertNil(v.load())
  }

  func test_unsafe_storeIfNilThenLoad() {
    XCTAssertEqual(LifetimeTracked.instances, 0)
    do {
      let v = UnsafeAtomicLazyReference<LifetimeTracked>.create()
      XCTAssertNil(v.load())

      let ref = LifetimeTracked(42)
      XCTAssertTrue(v.storeIfNilThenLoad(ref) === ref)
      XCTAssertTrue(v.load() === ref)

      let ref2 = LifetimeTracked(23)
      XCTAssertTrue(v.storeIfNilThenLoad(ref2) === ref)
      XCTAssertTrue(v.load() === ref)

      v.destroy()
    }
    XCTAssertEqual(LifetimeTracked.instances, 0)
  }

  func test_managed_storeIfNilThenLoad() {
    XCTAssertEqual(LifetimeTracked.instances, 0)
    do {
      let v = ManagedAtomicLazyReference<LifetimeTracked>()
      XCTAssertNil(v.load())

      let ref = LifetimeTracked(42)
      XCTAssertTrue(v.storeIfNilThenLoad(ref) === ref)
      XCTAssertTrue(v.load() === ref)

      let ref2 = LifetimeTracked(23)
      XCTAssertTrue(v.storeIfNilThenLoad(ref2) === ref)
      XCTAssertTrue(v.load() === ref)
    }
    XCTAssertEqual(LifetimeTracked.instances, 0)
  }

#if MANUAL_TEST_DISCOVERY
  public static var allTests = [
    ("test_unsafe_create_destroy", test_unsafe_create_destroy),
    ("test_unsafe_storeIfNilThenLoad", test_unsafe_storeIfNilThenLoad),
    ("test_managed_storeIfNilThenLoad", test_managed_storeIfNilThenLoad),
  ]
#endif
}
