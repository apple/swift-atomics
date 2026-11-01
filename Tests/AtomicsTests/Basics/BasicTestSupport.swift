//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2020 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Atomics

#if compiler(>=6.0)
extension Unmanaged: @retroactive Equatable { // FIXME: This is terrible
  public static func ==(left: Self, right: Self) -> Bool {
    left.toOpaque() == right.toOpaque()
  }
}
#else
extension Unmanaged: Equatable { // FIXME: This is terrible
  public static func ==(left: Self, right: Self) -> Bool {
    left.toOpaque() == right.toOpaque()
  }
}
#endif

struct Foo: Equatable, CustomStringConvertible {
  var value: Int
  init(_ value: Int) { self.value = value }
  var description: String { "Foo(\(value))" }
}

class Bar: Equatable, CustomStringConvertible {
  var value: Int
  init(_ value: Int) { self.value = value }
  var description: String { "Bar(\(value))" }
  static func ==(left: Bar, right: Bar) -> Bool {
    left === right
  }
}

final class Baz: Equatable, CustomStringConvertible, AtomicReference {
  var value: Int
  init(_ value: Int) { self.value = value }
  var description: String { "Bar(\(value))" }
  static func ==(left: Baz, right: Baz) -> Bool {
    left === right
  }
}

enum Fred: Int, AtomicValue {
  case one
  case two
}

struct Hyacinth: RawRepresentable, Equatable, AtomicOptionalWrappable {
  var rawValue: UnsafeRawPointer

  init(rawValue: UnsafeRawPointer) {
    self.rawValue = rawValue
  }

  static let bucket: Hyacinth = Hyacinth(
    rawValue: UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: 8))
}

/// Returns operands that exercise the edge cases of atomic integer operations:
/// overflow in both directions, the sign bit, and bits throughout the full
/// width of the type. (The list contains duplicates for some types.)
func integerBoundaryValues<T: FixedWidthInteger>(of type: T.Type) -> [T] {
  let pattern = T(truncatingIfNeeded: 0x5A5A_5A5A_5A5A_5A5A as UInt64)
  return [
    .min, .min &+ 1,
    ~0, // -1 in signed types
    0, 1,
    pattern, ~pattern,
    .max &- 1, .max,
  ]
}
