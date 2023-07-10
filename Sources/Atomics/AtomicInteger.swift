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

/// A type that supports atomic integer operations through a separate
/// atomic storage representation.
///
/// Atomic integer types provide a number of additional atomic
/// operations beyond the ones supported by `AtomicValue`, such as
/// atomic increments/decrements as well as atomic bitwise operations.
/// These may be mapped to dedicated instructions that can be more
/// efficient than implementations based on the general compare and
/// exchange operation; however, this depends on the capabilities of
/// the compiler and the underlying hardware.
public protocol AtomicInteger: AtomicValue, FixedWidthInteger
where
  AtomicRepresentation: AtomicIntegerStorage,
  AtomicRepresentation.Value == Self
{}

/// The storage representation for an atomic integer value, providing
/// pointer-based atomic operations.
///
/// This is a low-level implementation detail of atomic types; instead
/// of directly handling conforming types, it is usually better to use
/// the `UnsafeAtomic` or `ManagedAtomic` generics -- these provide a
/// more reliable interface while ensuring that the storage is
/// correctly constructed and destroyed.
public protocol AtomicIntegerStorage: AtomicStorage {
  /// Perform an atomic wrapping increment operation on the value referenced by
  /// `pointer` and return the original value, applying the specified memory
  /// ordering.
  ///
  /// Note: This operation silently wraps around on overflow, like the
  /// `&+=` operator does on integer values.
  ///
  /// - Parameter operand: The value to add to the current value.
  /// - Parameter pointer: A memory location previously initialized with a value
  ///   returned by `prepareAtomicRepresentation(for:)`.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  static func atomicLoadThenWrappingIncrement(
    by operand: Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> Value

  /// Perform an atomic wrapping decrement operation on the value referenced by
  /// `pointer` and return the original value, applying the specified memory
  /// ordering.
  ///
  /// Note: This operation silently wraps around on overflow, like the
  /// `&-=` operator does on integer values.
  ///
  /// - Parameter operand: The value to subtract from the current value.
  /// - Parameter pointer: A memory location previously initialized with a value
  ///   returned by `prepareAtomicRepresentation(for:)`.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  static func atomicLoadThenWrappingDecrement(
    by operand: Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> Value

  /// Perform an atomic bitwise AND operation on the value referenced by
  /// `pointer` and return the original value, applying the specified memory
  /// ordering.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter pointer: A memory location previously initialized with a value
  ///   returned by `prepareAtomicRepresentation(for:)`.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  static func atomicLoadThenBitwiseAnd(
    with operand: Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> Value

  /// Perform an atomic bitwise OR operation on the value referenced by
  /// `pointer` and return the original value, applying the specified memory
  /// ordering.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter pointer: A memory location previously initialized with a value
  ///   returned by `prepareAtomicRepresentation(for:)`.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  static func atomicLoadThenBitwiseOr(
    with operand: Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> Value

  /// Perform an atomic bitwise XOR operation on the value referenced by
  /// `pointer` and return the original value, applying the specified memory
  /// ordering.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter pointer: A memory location previously initialized with a value
  ///   returned by `prepareAtomicRepresentation(for:)`.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  static func atomicLoadThenBitwiseXor(
    with operand: Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> Value
}
