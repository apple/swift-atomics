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

/// An unsafe reference type holding an atomic value, requiring manual memory
/// management of the underlying storage representation.
@frozen
public struct UnsafeAtomic<Value: AtomicValue>
where Value.AtomicRepresentation.Value == Value {
  // Note: the Value.AtomicRepresentation.Value == Value requirement could be
  // relaxed, at the cost of adding a bunch of potentially ambiguous overloads.
  // (We'd need one set of implementations for the type equality condition, and
  // another for `Value: AtomicReference`.)

  public typealias Storage = Value.AtomicRepresentation
  @usableFromInline
  internal typealias _Storage = Storage

  @usableFromInline
  internal let _ptr: UnsafeMutablePointer<Storage>

  /// Initialize an unsafe atomic value that uses the supplied memory location
  /// for storage. The storage location must already be initialized to
  /// represent a valid atomic value.
  ///
  /// At the end of the lifetime of the atomic value, you must manually ensure
  /// that the storage location is correctly `dispose()`d, deinitalized and
  /// deallocated.
  ///
  /// Note: This is not an atomic operation.
  @_transparent // Debug performance
  public init(
    @_nonEphemeral at pointer: UnsafeMutablePointer<Storage>
  ) {
    self._ptr = pointer
  }

  /// Create a new `UnsafeAtomic` value with the supplied initial value by
  /// dynamically allocating storage for it.
  ///
  /// This call is usually paired with `destroy` to get rid of the allocated
  /// storage at the end of its lifetime.
  ///
  /// Note: This is not an atomic operation.
  @inlinable
  public static func create(_ initialValue: __owned Value) -> Self {
    let ptr = UnsafeMutablePointer<Storage>.allocate(capacity: 1)
    ptr.initialize(to: Storage(initialValue))
    return Self(at: ptr)
  }

  /// Disposes of the current value of the storage location corresponding to
  /// this unsafe atomic value, then deinitializes and deallocates the storage.
  ///
  /// Note: This is not an atomic operation.
  ///
  /// - Returns: The last value stored in the storage representation before it
  ///   was destroyed.
  @discardableResult
  @inlinable
  public func destroy() -> Value {
    let result = _ptr.pointee.dispose()
    _ptr.deinitialize(count: 1)
    _ptr.deallocate()
    return result
  }
}

extension UnsafeAtomic: @unchecked Sendable where Value: Sendable {}

extension UnsafeAtomic {
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
