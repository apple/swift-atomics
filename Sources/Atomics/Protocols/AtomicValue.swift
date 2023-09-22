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

/// A type that supports atomic operations through a separate atomic storage
/// representation.
public protocol AtomicValue {
  /// The atomic storage representation for this value.
  associatedtype AtomicRepresentation: AtomicStorage
  /* where Self is a subtype of AtomicRepresentation.Value */
}
