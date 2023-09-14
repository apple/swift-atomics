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

/// An atomic value that also supports atomic operations when wrapped
/// in an `Optional`. Atomic optional wrappable types come with a
/// standalone atomic representation for their optional-wrapped
/// variants.
public protocol AtomicOptionalWrappable: AtomicValue {
  /// The atomic storage representation for `Optional<Self>`.
  associatedtype AtomicOptionalRepresentation: AtomicStorage
  where AtomicOptionalRepresentation.Value == AtomicRepresentation.Value?
}

extension Optional: AtomicValue
where
  Wrapped: AtomicOptionalWrappable,
  Wrapped.AtomicRepresentation.Value == Wrapped
{
  public typealias AtomicRepresentation = Wrapped.AtomicOptionalRepresentation
}
