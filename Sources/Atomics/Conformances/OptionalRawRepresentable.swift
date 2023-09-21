//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2021 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

extension RawRepresentable
where
  Self: AtomicOptionalWrappable,
  RawValue: AtomicOptionalWrappable,
  RawValue.AtomicOptionalRepresentation.Value == RawValue?
{
  public typealias AtomicOptionalRepresentation =
    AtomicOptionalRawRepresentableStorage<Self>
}

/// A default atomic storage representation for a `RawRepresentable` type
/// whose `RawValue` conforms to `AtomicOptionalWrappable`.
@frozen
public struct AtomicOptionalRawRepresentableStorage<Wrapped>: AtomicStorage
where
  Wrapped: RawRepresentable,
  Wrapped.RawValue: AtomicOptionalWrappable,
  Wrapped.RawValue.AtomicOptionalRepresentation.Value == Wrapped.RawValue?
{

  public typealias Value = Optional<Wrapped>

  @usableFromInline
  internal typealias _Storage = Wrapped.RawValue.AtomicOptionalRepresentation

  @usableFromInline
  internal var _storage: _Storage

  @_transparent @_alwaysEmitIntoClient
  public init(_ value: __owned Optional<Wrapped>) {
    self._storage = _Storage(value?.rawValue)
  }

  @_transparent @_alwaysEmitIntoClient
  __consuming public func dispose() -> Optional<Wrapped> {
    _storage.dispose().flatMap(Wrapped.init(rawValue:))
  }

  @usableFromInline
  @_transparent @_alwaysEmitIntoClient
  static func _extract(
    _ ptr: UnsafeMutablePointer<Self>
  ) -> UnsafeMutablePointer<_Storage> {
    // `Self` is layout-compatible with its only stored property.
    return UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: _Storage.self)
  }

  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public static func atomicLoad(
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicLoadOrdering
  ) -> Optional<Wrapped> {
    let ro = _Storage.atomicLoad(
      at: _extract(pointer), ordering: ordering)
    return ro.flatMap(Wrapped.init(rawValue:))
  }

  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public static func atomicStore(
    _ desired: __owned Optional<Wrapped>,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicStoreOrdering
  ) {
    _Storage.atomicStore(
      desired?.rawValue, at: _extract(pointer), ordering: ordering)
  }

  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public static func atomicExchange(
    _ desired: __owned Optional<Wrapped>,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> Optional<Wrapped> {
    let ro = _Storage.atomicExchange(
      desired?.rawValue, at: _extract(pointer), ordering: ordering)
    return ro.flatMap(Wrapped.init(rawValue:))
  }

  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public static func atomicCompareExchange(
    expected: Optional<Wrapped>,
    desired: __owned Optional<Wrapped>,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> (exchanged: Bool, original: Optional<Wrapped>) {
    let ro = _Storage.atomicCompareExchange(
      expected: expected?.rawValue,
      desired: desired?.rawValue,
      at: _extract(pointer),
      ordering: ordering)
    return (ro.exchanged, ro.original.flatMap(Wrapped.init(rawValue:)))
  }

  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public static func atomicCompareExchange(
    expected: Optional<Wrapped>,
    desired: __owned Optional<Wrapped>,
    at pointer: UnsafeMutablePointer<Self>,
    successOrdering: AtomicUpdateOrdering,
    failureOrdering: AtomicLoadOrdering
  ) -> (exchanged: Bool, original: Optional<Wrapped>) {
    let ro = _Storage.atomicCompareExchange(
      expected: expected?.rawValue,
      desired: desired?.rawValue,
      at: _extract(pointer),
      successOrdering: successOrdering,
      failureOrdering: failureOrdering)
    return (ro.exchanged, ro.original.flatMap(Wrapped.init(rawValue:)))
  }

  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public static func atomicWeakCompareExchange(
    expected: Optional<Wrapped>,
    desired: __owned Optional<Wrapped>,
    at pointer: UnsafeMutablePointer<Self>,
    successOrdering: AtomicUpdateOrdering,
    failureOrdering: AtomicLoadOrdering
  ) -> (exchanged: Bool, original: Optional<Wrapped>) {
    let ro = _Storage.atomicWeakCompareExchange(
      expected: expected?.rawValue,
      desired: desired?.rawValue,
      at: _extract(pointer),
      successOrdering: successOrdering,
      failureOrdering: failureOrdering)
    return (ro.exchanged, ro.original.flatMap(Wrapped.init(rawValue:)))
  }
}
