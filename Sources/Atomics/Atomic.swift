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

#if compiler(>=5.9) && $RawLayout
import Builtin

// FIXME: What we actually want to say is @_rawLayout(like: Value.AtomicRepresentation)
@_rawLayout(like: DoubleWord.AtomicRepresentation)
@frozen
public struct Atomic<Value: AtomicValue>: ~Copyable
where Value.AtomicRepresentation.Value == Value
{
  @usableFromInline
  internal typealias _Storage = Value.AtomicRepresentation

  @_transparent @_alwaysEmitIntoClient
  internal var _ptr: UnsafeMutablePointer<_Storage> {
    .init(Builtin.addressOfBorrow(self))
  }

  public init(_ initialValue: __owned Value) {
    _ptr.initialize(to: _Storage(initialValue))
  }

  deinit {
    _ = _ptr.pointee.dispose()
    _ptr.deinitialize(count: 1)
  }
}

extension Atomic {
  /// Atomically loads and returns the current value, applying the specified
  /// memory ordering.
  ///
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The current value.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func load(
    ordering: AtomicLoadOrdering
  ) -> Value {
    _Storage.atomicLoad(at: _ptr, ordering: ordering)
  }

  /// Atomically sets the current value to `desired`, applying the specified
  /// memory ordering.
  ///
  /// - Parameter desired: The desired new value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func store(
    _ desired: __owned Value,
    ordering: AtomicStoreOrdering
  ) {
    _Storage.atomicStore(desired, at: _ptr, ordering: ordering)
  }

  /// Atomically sets the current value to `desired` and returns the original
  /// value, applying the specified memory ordering.
  ///
  /// - Parameter desired: The desired new value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func exchange(
    _ desired: __owned Value,
    ordering: AtomicUpdateOrdering
  ) -> Value {
    _Storage.atomicExchange(desired, at: _ptr, ordering: ordering)
  }

  /// Perform an atomic compare and exchange operation on the current value,
  /// applying the specified memory ordering.
  ///
  /// This operation performs the following algorithm as a single atomic
  /// transaction:
  ///
  /// ```
  /// atomic(self) { currentValue in
  ///   let original = currentValue
  ///   guard original == expected else { return (false, original) }
  ///   currentValue = desired
  ///   return (true, original)
  /// }
  /// ```
  ///
  /// This method implements a "strong" compare and exchange operation
  /// that does not permit spurious failures.
  ///
  /// - Parameter expected: The expected current value.
  /// - Parameter desired: The desired new value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: A tuple `(exchanged, original)`, where `exchanged` is true if
  ///   the exchange was successful, and `original` is the original value.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func compareExchange(
    expected: Value,
    desired: __owned Value,
    ordering: AtomicUpdateOrdering
  ) -> (exchanged: Bool, original: Value) {
    _Storage.atomicCompareExchange(
      expected: expected,
      desired: desired,
      at: _ptr,
      ordering: ordering)
  }

  /// Perform an atomic compare and exchange operation on the current value,
  /// applying the specified success/failure memory orderings.
  ///
  /// This operation performs the following algorithm as a single atomic
  /// transaction:
  ///
  /// ```
  /// atomic(self) { currentValue in
  ///   let original = currentValue
  ///   guard original == expected else { return (false, original) }
  ///   currentValue = desired
  ///   return (true, original)
  /// }
  /// ```
  ///
  /// The `successOrdering` argument specifies the memory ordering to use when
  /// the operation manages to update the current value, while `failureOrdering`
  /// will be used when the operation leaves the value intact.
  ///
  /// This method implements a "strong" compare and exchange operation
  /// that does not permit spurious failures.
  ///
  /// - Parameter expected: The expected current value.
  /// - Parameter desired: The desired new value.
  /// - Parameter successOrdering: The memory ordering to apply if this
  ///    operation performs the exchange.
  /// - Parameter failureOrdering: The memory ordering to apply on this
  ///    operation does not perform the exchange.
  /// - Returns: A tuple `(exchanged, original)`, where `exchanged` is true if
  ///   the exchange was successful, and `original` is the original value.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func compareExchange(
    expected: Value,
    desired: __owned Value,
    successOrdering: AtomicUpdateOrdering,
    failureOrdering: AtomicLoadOrdering
  ) -> (exchanged: Bool, original: Value) {
    _Storage.atomicCompareExchange(
      expected: expected,
      desired: desired,
      at: _ptr,
      successOrdering: successOrdering,
      failureOrdering: failureOrdering)
  }

  /// Perform an atomic weak compare and exchange operation on the current
  /// value, applying the memory ordering. This compare-exchange variant is
  /// allowed to spuriously fail; it is designed to be called in a loop until
  /// it indicates a successful exchange has happened.
  ///
  /// This operation performs the following algorithm as a single atomic
  /// transaction:
  ///
  /// ```
  /// atomic(self) { currentValue in
  ///   let original = currentValue
  ///   guard original == expected else { return (false, original) }
  ///   currentValue = desired
  ///   return (true, original)
  /// }
  /// ```
  ///
  /// (In this weak form, transient conditions may cause the `original ==
  /// expected` check to sometimes return false when the two values are in fact
  /// the same.)
  ///
  /// - Parameter expected: The expected current value.
  /// - Parameter desired: The desired new value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: A tuple `(exchanged, original)`, where `exchanged` is true if
  ///   the exchange was successful, and `original` is the original value.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func weakCompareExchange(
    expected: Value,
    desired: __owned Value,
    ordering: AtomicUpdateOrdering
  ) -> (exchanged: Bool, original: Value) {
    _Storage.atomicWeakCompareExchange(
      expected: expected,
      desired: desired,
      at: _ptr,
      ordering: ordering)
  }

  /// Perform an atomic weak compare and exchange operation on the current
  /// value, applying the specified success/failure memory orderings. This
  /// compare-exchange variant is allowed to spuriously fail; it is designed to
  /// be called in a loop until it indicates a successful exchange has happened.
  ///
  /// This operation performs the following algorithm as a single atomic
  /// transaction:
  ///
  /// ```
  /// atomic(self) { currentValue in
  ///   let original = currentValue
  ///   guard original == expected else { return (false, original) }
  ///   currentValue = desired
  ///   return (true, original)
  /// }
  /// ```
  ///
  /// (In this weak form, transient conditions may cause the `original ==
  /// expected` check to sometimes return false when the two values are in fact
  /// the same.)
  ///
  /// The `ordering` argument specifies the memory ordering to use when the
  /// operation manages to update the current value, while `failureOrdering`
  /// will be used when the operation leaves the value intact.
  ///
  /// - Parameter expected: The expected current value.
  /// - Parameter desired: The desired new value.
  /// - Parameter successOrdering: The memory ordering to apply if this
  ///    operation performs the exchange.
  /// - Parameter failureOrdering: The memory ordering to apply on this
  ///    operation does not perform the exchange.
  /// - Returns: A tuple `(exchanged, original)`, where `exchanged` is true if
  ///   the exchange was successful, and `original` is the original value.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func weakCompareExchange(
    expected: Value,
    desired: __owned Value,
    successOrdering: AtomicUpdateOrdering,
    failureOrdering: AtomicLoadOrdering
  ) -> (exchanged: Bool, original: Value) {
    _Storage.atomicWeakCompareExchange(
      expected: expected,
      desired: desired,
      at: _ptr,
      successOrdering: successOrdering,
      failureOrdering: failureOrdering)
  }
}

extension Atomic where Value: AtomicInteger {
  /// Perform an atomic wrapping add operation and return the original value, applying
  /// the specified memory ordering.
  ///
  /// Note: This operation silently wraps around on overflow, like the
  /// `&+` operator does on `Int` values.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func loadThenWrappingIncrement(
    by operand: Value = 1,
    ordering: AtomicUpdateOrdering
  ) -> Value {
    _Storage.atomicLoadThenWrappingIncrement(
      by: operand,
      at: _ptr,
      ordering: ordering)
  }
  /// Perform an atomic wrapping subtract operation and return the original value, applying
  /// the specified memory ordering.
  ///
  /// Note: This operation silently wraps around on overflow, like the
  /// `&-` operator does on `Int` values.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func loadThenWrappingDecrement(
    by operand: Value = 1,
    ordering: AtomicUpdateOrdering
  ) -> Value {
    _Storage.atomicLoadThenWrappingDecrement(
      by: operand,
      at: _ptr,
      ordering: ordering)
  }
  /// Perform an atomic bitwise AND operation and return the original value, applying
  /// the specified memory ordering.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func loadThenBitwiseAnd(
    with operand: Value,
    ordering: AtomicUpdateOrdering
  ) -> Value {
    _Storage.atomicLoadThenBitwiseAnd(
      with: operand,
      at: _ptr,
      ordering: ordering)
  }
  /// Perform an atomic bitwise OR operation and return the original value, applying
  /// the specified memory ordering.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func loadThenBitwiseOr(
    with operand: Value,
    ordering: AtomicUpdateOrdering
  ) -> Value {
    _Storage.atomicLoadThenBitwiseOr(
      with: operand,
      at: _ptr,
      ordering: ordering)
  }
  /// Perform an atomic bitwise XOR operation and return the original value, applying
  /// the specified memory ordering.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func loadThenBitwiseXor(
    with operand: Value,
    ordering: AtomicUpdateOrdering
  ) -> Value {
    _Storage.atomicLoadThenBitwiseXor(
      with: operand,
      at: _ptr,
      ordering: ordering)
  }

  /// Perform an atomic wrapping add operation and return the new value, applying
  /// the specified memory ordering.
  ///
  /// Note: This operation silently wraps around on overflow, like the
  /// `&+` operator does on `Int` values.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The new value after the operation.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func wrappingIncrementThenLoad(
    by operand: Value = 1,
    ordering: AtomicUpdateOrdering
  ) -> Value {
    let original = _Storage.atomicLoadThenWrappingIncrement(
      by: operand,
      at: _ptr,
      ordering: ordering)
    return original &+ operand
  }
  /// Perform an atomic wrapping subtract operation and return the new value, applying
  /// the specified memory ordering.
  ///
  /// Note: This operation silently wraps around on overflow, like the
  /// `&-` operator does on `Int` values.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The new value after the operation.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func wrappingDecrementThenLoad(
    by operand: Value = 1,
    ordering: AtomicUpdateOrdering
  ) -> Value {
    let original = _Storage.atomicLoadThenWrappingDecrement(
      by: operand,
      at: _ptr,
      ordering: ordering)
    return original &- operand
  }
  /// Perform an atomic bitwise AND operation and return the new value, applying
  /// the specified memory ordering.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The new value after the operation.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func bitwiseAndThenLoad(
    with operand: Value,
    ordering: AtomicUpdateOrdering
  ) -> Value {
    let original = _Storage.atomicLoadThenBitwiseAnd(
      with: operand,
      at: _ptr,
      ordering: ordering)
    return original & operand
  }
  /// Perform an atomic bitwise OR operation and return the new value, applying
  /// the specified memory ordering.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The new value after the operation.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func bitwiseOrThenLoad(
    with operand: Value,
    ordering: AtomicUpdateOrdering
  ) -> Value {
    let original = _Storage.atomicLoadThenBitwiseOr(
      with: operand,
      at: _ptr,
      ordering: ordering)
    return original | operand
  }
  /// Perform an atomic bitwise XOR operation and return the new value, applying
  /// the specified memory ordering.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The new value after the operation.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func bitwiseXorThenLoad(
    with operand: Value,
    ordering: AtomicUpdateOrdering
  ) -> Value {
    let original = _Storage.atomicLoadThenBitwiseXor(
      with: operand,
      at: _ptr,
      ordering: ordering)
    return original ^ operand
  }

  /// Perform an atomic wrapping increment operation applying the
  /// specified memory ordering.
  ///
  /// Note: This operation silently wraps around on overflow, like the
  /// `&+=` operator does on `Int` values.
  ///
  /// - Parameter operand: The value to add to the current value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func wrappingIncrement(
    by operand: Value = 1,
    ordering: AtomicUpdateOrdering
  ) {
    _ = _Storage.atomicLoadThenWrappingIncrement(
      by: operand,
      at: _ptr,
      ordering: ordering)
  }

  /// Perform an atomic wrapping decrement operation applying the
  /// specified memory ordering.
  ///
  /// Note: This operation silently wraps around on overflow, like the
  /// `&-=` operator does on `Int` values.
  ///
  /// - Parameter operand: The value to subtract from the current value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func wrappingDecrement(
    by operand: Value = 1,
    ordering: AtomicUpdateOrdering
  ) {
    _ = _Storage.atomicLoadThenWrappingDecrement(
      by: operand,
      at: _ptr,
      ordering: ordering)
  }
}

#endif
