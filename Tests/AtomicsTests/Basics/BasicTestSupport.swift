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

import Atomics

extension Unmanaged: Equatable {  // FIXME: This is terrible
  public static func == (left: Self, right: Self) -> Bool {
    left.toOpaque() == right.toOpaque()
  }
}

struct Foo: Equatable, CustomStringConvertible {
  var value: Int
  init(_ value: Int) { self.value = value }
  var description: String { "Foo(\(value))" }
}

class Bar: Equatable, CustomStringConvertible {
  var value: Int
  init(_ value: Int) { self.value = value }
  var description: String { "Bar(\(value))" }
  static func == (left: Bar, right: Bar) -> Bool {
    left === right
  }
}

final class Baz: Equatable, CustomStringConvertible, AtomicReference {
  var value: Int
  init(_ value: Int) { self.value = value }
  var description: String { "Bar(\(value))" }
  static func == (left: Baz, right: Baz) -> Bool {
    left === right
  }
}

enum Fred: Int, AtomicValue {
  case one
  case two
}

struct Hyacinth: RawRepresentable, Equatable, AtomicOptionalWrappable {
  var rawValue: UnsafeRawPointer

  static let bucket: Hyacinth = Hyacinth(
    rawValue: UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: 8))
}
