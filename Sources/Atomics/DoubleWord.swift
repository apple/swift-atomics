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

import _AtomicsShims

public typealias DoubleWord = _AtomicsShims.DoubleWord

extension DoubleWord {
  /// Initialize a new `DoubleWord` value given its high- and
  /// low-order words.
  @inlinable @inline(__always)
  public init(high: UInt, low: UInt) {
    self = _sa_dword_create(high, low)
  }

  /// Initialize a new `DoubleWord` value given its component words,
  /// in the order in which they are laid out in memory.
  @inlinable @inline(__always)
  public init(first: UInt, second: UInt) {
#if _endian(little)
    self = _sa_dword_create(second, first)
#else
    self = _sa_dword_create(first, second)
#endif
  }

  /// The most significant word in `self`, considering it as a single,
  /// wide integer value. This may correspond to either `first` or
  /// `second`, depending on the endianness of the underlying
  /// architecture.
  @inlinable @inline(__always)
  public var high: UInt {
    get { _sa_dword_extract_high(self) }
    set { self = _sa_dword_create(newValue, low) }
  }

  /// The least significant word in `self`, considering it as a
  /// single, wide integer value. This may correspond to either
  /// `first` or `second`, depending on the endianness of the
  /// underlying architecture.
  @inlinable @inline(__always)
  public var low: UInt {
    get { _sa_dword_extract_low(self) }
    set { self = _sa_dword_create(high, newValue) }
  }


  /// The first word in `self` in its underlying binary
  /// representation.
  @inlinable @inline(__always)
  public var first: UInt {
    get {
        #if _endian(little)
        return _sa_dword_extract_low(self)
        #else
        return _sa_dword_extract_high(self)
        #endif
    }
    set {
        #if _endian(little)
        self = _sa_dword_create(high, newValue)
        #else
        self = _sa_dword_create(newValue, low)
        #endif
    }
  }

  /// The second word in `self` in its underlying binary
  /// representation.
  @inlinable @inline(__always)
  public var second: UInt {
    get {
        #if _endian(little)
        return _sa_dword_extract_high(self)
        #else
        return _sa_dword_extract_low(self)
        #endif
    }
    set {
        #if _endian(little)
        self = _sa_dword_create(newValue, low)
        #else
        self = _sa_dword_create(high, newValue)
        #endif
    }
  }
}

extension DoubleWord: Equatable {
  @inlinable
  public static func ==(left: Self, right: Self) -> Bool {
    left.high == right.high && left.low == right.low
  }
}

extension DoubleWord: Hashable {
  @inlinable
  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.high)
    hasher.combine(self.low)
  }
}

extension DoubleWord: CustomStringConvertible {
  public var description: String {
    "DoubleWord(high: \(high), low: \(low))"
  }
}
