//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020-2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import XCTest
import Atomics

class DoubleWordTests: XCTestCase {
  func testMemoryLayout() {
    XCTAssertEqual(MemoryLayout<DoubleWord>.size, 2 * MemoryLayout<UInt>.size)
    XCTAssertEqual(MemoryLayout<DoubleWord>.stride, MemoryLayout<DoubleWord>.size)
    XCTAssertEqual(MemoryLayout<DoubleWord>.alignment, 2 * MemoryLayout<UInt>.alignment) 
  }

  struct UIntPair: Equatable {
    var first: UInt
    var second: UInt

    init(_ first: UInt, _ second: UInt) {
      self.first = first
      self.second = second
    }
  }

  func componentsInMemoryOrder(of dword: DoubleWord) -> UIntPair {
    let p = UnsafeMutableRawPointer.allocate(
      byteCount: MemoryLayout<DoubleWord>.size,
      alignment: MemoryLayout<DoubleWord>.alignment)
    p.storeBytes(of: dword, as: DoubleWord.self)
    let first = p.load(as: UInt.self)
    let second = p.load(fromByteOffset: MemoryLayout<UInt>.stride, as: UInt.self)
    return UIntPair(first, second)
  }

  func testFirstSecondInitializer() {
    let value = DoubleWord(first: 1, second: 2)
    XCTAssertEqual(componentsInMemoryOrder(of: value), UIntPair(1, 2))
  }

  func testHighLowInitializer() {
    let value = DoubleWord(high: 1, low: 2)
    #if _endian(little)
    XCTAssertEqual(componentsInMemoryOrder(of: value), UIntPair(2, 1))
    #else
    XCTAssertEqual(componentsInMemoryOrder(of: value), UIntPair(1, 2))
    #endif
  }

  func testPropertyGetters() {
    let value = DoubleWord(first: UInt.max, second: 0)
    XCTAssertEqual(value.first, UInt.max)
    XCTAssertEqual(value.second, 0)
    #if _endian(little)
    XCTAssertEqual(value.high, 0)
    XCTAssertEqual(value.low, UInt.max)
    #else
    XCTAssertEqual(value.high, UInt.max)
    XCTAssertEqual(value.low, 0)
    #endif
  }

  func testPropertySetters() {
    var value = DoubleWord(first: 1, second: 2)
    value.first = 3
    XCTAssertEqual(componentsInMemoryOrder(of: value), UIntPair(3, 2))
    value.second = 4
    XCTAssertEqual(componentsInMemoryOrder(of: value), UIntPair(3, 4))
    value.low = 5
    #if _endian(little)
    XCTAssertEqual(componentsInMemoryOrder(of: value), UIntPair(5, 4))
    #else
    XCTAssertEqual(componentsInMemoryOrder(of: value), UIntPair(3, 5))
    #endif
    value.high = 6
    #if _endian(little)
    XCTAssertEqual(componentsInMemoryOrder(of: value), UIntPair(5, 6))
    #else
    XCTAssertEqual(componentsInMemoryOrder(of: value), UIntPair(6, 5))
    #endif
  }

#if !SWIFT_PACKAGE
  public static var allTests = [
    ("testMemoryLayout", testMemoryLayout),
    ("testFirstSecondInitializer", testFirstSecondInitializer),
    ("testHighLowInitializer", testHighLowInitializer),
    ("testPropertyGetters", testPropertyGetters),
    ("testPropertySetters", testPropertySetters),
  ]
#endif
}
