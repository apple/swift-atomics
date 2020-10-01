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

extension RawRepresentable where Self: AtomicValue, RawValue: AtomicValue {
  public typealias AtomicRepresentation = AtomicRawRepresentableStorage<Self>
}

/// The default atomic storage representation for an atomic `RawRepresentable`
/// type whose `RawValue` conforms to `AtomicValue`.
@frozen
public struct AtomicRawRepresentableStorage<Value>: AtomicStorage
where Value: RawRepresentable, Value.RawValue: AtomicValue {
  @usableFromInline internal typealias Storage = Value.RawValue.AtomicRepresentation
  @usableFromInline
  internal var _storage: Storage

  @_transparent @_alwaysEmitIntoClient
  public init(_ value: __owned Value) {
    _storage = Storage(value.rawValue)
  }

  @_transparent @_alwaysEmitIntoClient
  public func dispose() -> Value {
    Value(rawValue: _storage.dispose())!
  }

  @_transparent @_alwaysEmitIntoClient
  internal static func _extract(
    _ ptr: UnsafeMutablePointer<Self>
  ) -> UnsafeMutablePointer<Storage> {
    // `Self` is layout-compatible with its only stored property.
    UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: Storage.self)
  }

  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public static func atomicLoad(
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicLoadOrdering
  ) -> Value {
    let raw = Storage.atomicLoad(at: _extract(pointer), ordering: ordering)
    return Value(rawValue: raw)!
  }

  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public static func atomicStore(
    _ desired: Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicStoreOrdering
  ) {
    Storage.atomicStore(desired.rawValue, at: _extract(pointer), ordering: ordering)
  }

  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public static func atomicExchange(
    _ desired: Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> Value {
    let raw = Storage.atomicExchange(desired.rawValue, at: _extract(pointer), ordering: ordering)
    return Value(rawValue: raw)!
  }

  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public static func atomicCompareExchange(
    expected: Value,
    desired: Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> (exchanged: Bool, original: Value) {
    let raw = Storage.atomicCompareExchange(
            expected: expected.rawValue,
            desired: desired.rawValue,
            at: _extract(pointer),
            ordering: ordering)
    return (raw.exchanged, Value(rawValue: raw.original)!)
  }

  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public static func atomicCompareExchange(
    expected: Value,
    desired: Value,
    at pointer: UnsafeMutablePointer<Self>,
    successOrdering: AtomicUpdateOrdering,
    failureOrdering: AtomicLoadOrdering
  ) -> (exchanged: Bool, original: Value) {
    let raw = Storage.atomicCompareExchange(
            expected: expected.rawValue,
            desired: desired.rawValue,
            at: _extract(pointer),
            successOrdering: successOrdering,
            failureOrdering: failureOrdering)
    return (raw.exchanged, Value(rawValue: raw.original)!)
  }

  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public static func atomicWeakCompareExchange(
    expected: Value,
    desired: Value,
    at pointer: UnsafeMutablePointer<Self>,
    successOrdering: AtomicUpdateOrdering,
    failureOrdering: AtomicLoadOrdering
  ) -> (exchanged: Bool, original: Value) {
    let raw = Storage.atomicWeakCompareExchange(
            expected: expected.rawValue,
            desired: desired.rawValue,
            at: _extract(pointer),
            successOrdering: successOrdering,
            failureOrdering: failureOrdering)
    return (raw.exchanged, Value(rawValue: raw.original)!)
  }
}
