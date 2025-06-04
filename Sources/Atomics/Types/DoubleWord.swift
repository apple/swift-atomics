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

import Builtin

#if _pointerBitWidth(_32)
@frozen
@_alignment(8)
public struct DoubleWord {
  @usableFromInline
  internal typealias _Builtin = Builtin.Int64

  public var first: UInt
  public var second: UInt

  @inlinable @inline(__always)
  public init(first: UInt, second: UInt) {
    self.first = first
    self.second = second
  }
}
#elseif _pointerBitWidth(_64)
@frozen
@_alignment(16)
public struct DoubleWord {
  @usableFromInline
  internal typealias _Builtin = Builtin.Int128

  public var first: UInt
  public var second: UInt

  @inlinable @inline(__always)
  public init(first: UInt, second: UInt) {
    self.first = first
    self.second = second
  }
}
#else
#error("Unexpected pointer bit width")
#endif

extension DoubleWord {
  @_alwaysEmitIntoClient
  @_transparent
  internal init(_ builtin: _Builtin) {
    self = unsafeBitCast(builtin, to: DoubleWord.self)
  }

  @_alwaysEmitIntoClient
  @_transparent
  internal var _value: _Builtin {
    unsafeBitCast(self, to: _Builtin.self)
  }
}

extension DoubleWord {
  /// Initialize a new `DoubleWord` value given its high- and
  /// low-order words.
  @available(*, deprecated, renamed: "init(first:second:)")
  @inlinable @inline(__always)
  public init(high: UInt, low: UInt) {
    self.init(first: low, second: high)
  }

  /// The most significant word in `self`, considering it as a single,
  /// wide integer value.
  @available(*, deprecated, renamed: "second")
  @inlinable @inline(__always)
  public var high: UInt {
    get { second }
    set { second = newValue }
  }

  /// The least significant word in `self`, considering it as a
  /// single, wide integer value. This may correspond to either
  /// `first` or `second`, depending on the endianness of the
  /// underlying architecture.
  @available(*, deprecated, renamed: "first")
  @inlinable @inline(__always)
  public var low: UInt {
    get { first }
    set { first = newValue }
  }
}

extension DoubleWord: Equatable {
  @inlinable
  public static func ==(left: Self, right: Self) -> Bool {
    left.first == right.first && left.second == right.second
  }
}

extension DoubleWord: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.first)
    hasher.combine(self.second)
  }
}

extension DoubleWord: CustomStringConvertible {
  public var description: String {
    "DoubleWord(first: \(first), second: \(second))"
  }
}
