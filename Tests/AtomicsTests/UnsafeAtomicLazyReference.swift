//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
import Atomics

class UnsafeAtomicLazyReferenceTests: XCTestCase {
  func test_create_destroy() {
    let v = UnsafeAtomicLazyReference<LifetimeTracked>.create()
    defer { v.destroy() }
    XCTAssertNil(v.load())
  }

  func test_storeIfNilThenLoad() {
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

#if !SWIFT_PACKAGE
  public static var allTests = [
    ("test_create_destroy", test_create_destroy),
    ("test_storeIfNilThenLoad", test_storeIfNilThenLoad),
  ]
#endif
}
