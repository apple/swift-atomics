//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Atomics
import XCTest

private class Base: AtomicReference {
  let value: Int

  init(_ value: Int) {
    self.value = value
  }
}

private class Child: Base {}
private class Grandchild: Child {}

class StrongReferenceSubclass: XCTestCase {
  func test_base_unsafe() {
    let object = Child(42)
    let v = UnsafeAtomic<Base>.create(object)

    XCTAssertTrue(v.load(ordering: .relaxed) === object)

    let object2 = Grandchild(23)
    let o = v.exchange(object2, ordering: .relaxed)
    XCTAssertTrue(o === object)

    XCTAssertTrue(v.load(ordering: .relaxed) === object2)

    let r = v.destroy()
    XCTAssertTrue(r === object2)
  }

  func test_base_managed() {
    let object = Child(42)
    let v = ManagedAtomic<Base>(object)

    XCTAssertTrue(v.load(ordering: .relaxed) === object)

    let object2 = Grandchild(23)
    let o = v.exchange(object2, ordering: .relaxed)
    XCTAssertTrue(o === object)

    XCTAssertTrue(v.load(ordering: .relaxed) === object2)
  }

  func test_optional_base_unsafe() {
    let v = UnsafeAtomic<Base?>.create(nil)

    XCTAssertTrue(v.load(ordering: .relaxed) == nil)

    let object = Grandchild(23)
    let o = v.exchange(object, ordering: .relaxed)
    XCTAssertTrue(o == nil)

    XCTAssertTrue(v.load(ordering: .relaxed) === object)

    let r = v.destroy()
    XCTAssertTrue(r === object)
  }

  func test_optional_base_managed() {
    let v = ManagedAtomic<Base?>(nil)

    XCTAssertTrue(v.load(ordering: .relaxed) == nil)

    let object = Grandchild(23)
    let o = v.exchange(object, ordering: .relaxed)
    XCTAssertTrue(o == nil)

    XCTAssertTrue(v.load(ordering: .relaxed) === object)
  }
}
