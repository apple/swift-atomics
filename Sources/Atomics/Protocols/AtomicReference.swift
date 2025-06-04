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

/// A class type that supports atomic strong references.
///
///     class MyObject: AtomicReference {}
///
///     let object = MyObject()
///     let ref = ManagedAtomic<MyObject>(object)
///
///     ref.load(ordering: .relaxed) // Returns `object`.
///
/// The conforming class is allowed to be non-final, but `ManagedAtomic` and
/// `UnsafeAtomic` do not support using a subclass as their generic argument --
/// the type of an atomic reference must be precisely the same class that
/// originally conformed to the protocol.
///
///
///     class Derived: MyObject {}
///
///     let ref2: ManagedAtomic<Derived>
///     // error: 'ManagedAtomic' requires the types 'Derived' and 'Base' be equivalent
///
/// Note that this limitation only affects the static type of the
/// `ManagedAtomic`/`UnsafeAtomic` variables. Such references still fully
/// support holding instances of subclasses of the conforming class. (Returned
/// may be downcasted from the base type after an `is` check.)
///
///     let child = Derived()
///     ref.store(child, ordering: .relaxed) // OK!
///     let value = ref.load(ordering: .relaxed)
///     // `value` is a variable of type `MyObject`, holding a `Derived` instance.
///     print(value is Derived) // Prints "true"
///
public protocol AtomicReference: AnyObject, AtomicOptionalWrappable
where
  AtomicRepresentation == AtomicReferenceStorage<_AtomicBase>,
  AtomicOptionalRepresentation == AtomicOptionalReferenceStorage<_AtomicBase>
{
  /// This is a utility type that enables non-final classes to conform to
  /// `AtomicReference`.
  ///
  /// This associated type must be left at its default value, `Self`.
  /// `ManagedAtomic` et al. currently require that `Self == _AtomicBase`,
  /// so conformances that set this to anything else will technically build,
  /// but they will not be very practical.
  ///
  /// Ideally we could just require that `Self` should be a subtype of
  /// `AtomicRepresentation.Value`; however we have no good way to
  /// express that requirement.
  ///
  ///     protocol AtomicValue where Self: AtomicRepresentation.Value {
  ///       associatedtype AtomicRepresentation: AtomicStorage
  ///     }
  ///
  /// See https://github.com/apple/swift-atomics/issues/53 for more details.
  associatedtype _AtomicBase: AnyObject = Self
}

/// The maximum number of other threads that can start accessing a
/// strong reference before an in-flight update needs to cancel and
/// retry.
@inlinable @inline(__always)
internal var _concurrencyWindow: Int { 20 }

extension DoubleWord {
  fileprivate init(_raw: UnsafeRawPointer?, readers: Int, version: Int) {
    let r = UInt(bitPattern: readers) & Self._readersMask
    assert(r == readers)
    self.init(
      first: UInt(bitPattern: _raw),
      second: r | (UInt(bitPattern: version) &<< Self._readersBitWidth))
  }

  @inline(__always)
  fileprivate var _raw: UnsafeMutableRawPointer? {
    get { UnsafeMutableRawPointer(bitPattern: first) }
    set { first = UInt(bitPattern: newValue) }
  }

  @inline(__always)
  fileprivate var _unmanaged: Unmanaged<AnyObject>? {
    guard let raw = _raw else { return nil }
    return .fromOpaque(raw)
  }

  @inline(__always)
  fileprivate static var _readersBitWidth: Int {
    // This reserves 8 bits for the accesses-in-flight counter on 32-bit
    // systems, and 16 bits on 64-bit systems.
    Int.bitWidth / 4
  }

  @inline(__always)
  fileprivate static var _readersMask: UInt { (1 &<< _readersBitWidth) - 1  }

  @inline(__always)
  fileprivate var _readers: Int {
    get { Int(bitPattern: second & Self._readersMask) }
    set {
      let n = UInt(bitPattern: newValue) & Self._readersMask
      assert(n == newValue)
      second = (second & ~Self._readersMask) | n
    }
  }

  @inline(__always)
  fileprivate var _version: Int {
    get { Int(bitPattern: second &>> Self._readersBitWidth) }
    set {
      // Silently truncate any high bits we cannot store.
      second = (
        (UInt(bitPattern: newValue) &<< Self._readersBitWidth) |
        second & Self._readersMask)
    }
  }
}

extension Optional where Wrapped == AnyObject {
  fileprivate var _raw: UnsafeMutableRawPointer? {
    guard let value = self else { return nil }
    return Unmanaged.passUnretained(value).toOpaque()
  }
}

extension UnsafeMutablePointer where Pointee == _AtomicReferenceStorage {
  @inlinable @inline(__always)
  internal var _extract: UnsafeMutablePointer<DoubleWord.AtomicRepresentation> {
    UnsafeMutableRawPointer(self)
      .assumingMemoryBound(to: DoubleWord.AtomicRepresentation.self)
  }
}

@usableFromInline
internal struct _AtomicReferenceStorage {
  internal typealias Storage = DoubleWord.AtomicRepresentation
  internal var _storage: Storage

  @usableFromInline
  internal init(_ value: __owned AnyObject?) {
    let dword = DoubleWord(
      _raw: Unmanaged.passRetained(value)?.toOpaque(),
      readers: 0,
      version: 0)
    _storage = Storage(dword)
  }

  @usableFromInline
  internal func dispose() -> AnyObject? {
    let value = _storage.dispose()
    precondition(value._readers == 0,
      "Attempt to dispose of a busy atomic strong reference \(value)")
    return value._unmanaged?.takeRetainedValue()
  }

  private static func _startLoading(
    from pointer: UnsafeMutablePointer<Self>,
    hint: DoubleWord? = nil
  ) -> DoubleWord {
    var old = hint ?? Storage.atomicLoad(at: pointer._extract, ordering: .relaxed)
    if old._raw == nil {
      atomicMemoryFence(ordering: .acquiring)
      return old
    }
    // Increment reader count
    while true {
      let new = DoubleWord(
        _raw: old._raw,
        readers: old._readers &+ 1,
        version: old._version)
      var done: Bool
      (done, old) = Storage.atomicWeakCompareExchange(
        expected: old,
        desired: new,
        at: pointer._extract,
        successOrdering: .acquiring,
        failureOrdering: .acquiring)
      if done { return new }
      if old._raw == nil { return old }
    }
  }

  private static func _finishLoading(
    _ value: DoubleWord,
    from pointer: UnsafeMutablePointer<Self>
  ) -> AnyObject? {
    if value._raw == nil { return nil }

    // Retain result before we exit the access.
    let result = value._unmanaged!.takeUnretainedValue()

    // Decrement reader count, using the version number to prevent any
    // ABA issues.
    var current = value
    var done = false
    repeat {
      assert(current._readers >= 1)
      (done, current) = Storage.atomicWeakCompareExchange(
        expected: current,
        desired: DoubleWord(
          _raw: current._raw,
          readers: current._readers &- 1,
          version: current._version),
        at: pointer._extract,
        successOrdering: .acquiringAndReleasing,
        failureOrdering: .acquiring)
    } while !done && current._raw == value._raw && current._version == value._version
    if !done {
      // The reference changed while we were loading it. Cancel out
      // our part of the refcount bias for the loaded instance.
      value._unmanaged!.release()
    }
    return result
  }

  @usableFromInline
  internal static func atomicLoad(
    at pointer: UnsafeMutablePointer<Self>
  ) -> AnyObject? {
    let new = _startLoading(from: pointer)
    return _finishLoading(new, from: pointer)
  }

  /// Try updating the current value from `old` to `new`. Don't do anything if the
  /// current value differs from `old`.
  ///
  /// Returns a tuple `(exchanged, original)` where `exchanged` indicates whether the
  /// update was successful. If `exchange` true, then `original` contains the original
  /// reference value; otherwise `original` is nil.
  ///
  /// On an unsuccessful exchange, this function updates `old` to the latest known value,
  /// and reenters the current thread as a reader of it.
  private static func _tryExchange(
    old: inout DoubleWord,
    new: Unmanaged<AnyObject>?,
    at pointer: UnsafeMutablePointer<Self>
  ) -> (exchanged: Bool, original: AnyObject?) {
    let new = DoubleWord(_raw: new?.toOpaque(), readers: 0, version: old._version &+ 1)
    guard let ref = old._unmanaged else {
      // Try replacing the current nil value with the desired new value.
      let (done, current) = Storage.atomicCompareExchange(
        expected: old,
        desired: new,
        at: pointer._extract,
        ordering: .acquiringAndReleasing)
      if done {
        return (true, nil)
      }
      // Someone else changed the reference. Give up for now.
      old = _startLoading(from: pointer, hint: current)
      return (false, nil)
    }
    assert(old._readers >= 1)
    var delta = old._readers + _concurrencyWindow
    ref.retain(by: delta)
    while true {
      // Try replacing the current value with the desired new value.
      let (done, current) = Storage.atomicCompareExchange(
        expected: old,
        desired: new,
        at: pointer._extract,
        ordering: .acquiringAndReleasing)
      if done {
        // Successfully replaced the object. Clean up extra retains.
        assert(current._readers == old._readers)
        assert(current._raw == old._raw)
        assert(current._readers <= delta)
        ref.release(by: delta - current._readers + 1) // +1 is for our own role as a reader.
        return (true, ref.takeRetainedValue())
      }
      if current._version != old._version {
        // Someone else changed the reference. Give up for now.
        ref.release(by: delta + 1) // +1 covers our reader bias
        old = _startLoading(from: pointer, hint: current)
        return (false, nil)
      }
      // Some readers entered or left while we were processing things. Try again.
      assert(current._raw == old._raw)
      assert(current._raw != nil)
      assert(current._readers >= 1)
      if current._readers > delta {
        // We need to do more retains to cover readers.
        let d = current._readers + _concurrencyWindow
        ref.retain(by: d - delta)
        delta = d
      }
      old = current
    }
  }

  @usableFromInline
  internal static func atomicExchange(
    _ desired: __owned AnyObject?,
    at pointer: UnsafeMutablePointer<Self>
  ) -> AnyObject? {
    let new = Unmanaged.passRetained(desired)
    var old = _startLoading(from: pointer)
    var (exchanged, original) = _tryExchange(old: &old, new: new, at: pointer)
    while !exchanged {
      (exchanged, original) = _tryExchange(old: &old, new: new, at: pointer)
    }
    return original
  }

  @usableFromInline
  internal static func atomicCompareExchange(
    expected: AnyObject?,
    desired: __owned AnyObject?,
    at pointer: UnsafeMutablePointer<Self>
  ) -> (exchanged: Bool, original: AnyObject?) {
    let expectedRaw = expected._raw
    let new = Unmanaged.passRetained(desired)
    var old = _startLoading(from: pointer)
    while old._raw == expectedRaw {
      let (exchanged, original) = _tryExchange(old: &old, new: new, at: pointer)
      if exchanged {
        assert(original === expected)
        return (true, original)
      }
    }
    // We did not find the expected value. Cancel the retain of the new value
    // and return the old value.
    new?.release()
    return (false, _finishLoading(old, from: pointer))
  }
}

@frozen
public struct AtomicReferenceStorage<Value: AnyObject> {
  @usableFromInline
  internal var _storage: _AtomicReferenceStorage

  @inlinable
  public init(_ value: __owned Value) {
    _storage = .init(value)
  }

  @inlinable
  public func dispose() -> Value {
    return unsafeDowncast(_storage.dispose()!, to: Value.self)
  }
}

extension AtomicReferenceStorage {
  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static func _extract(
    _ ptr: UnsafeMutablePointer<Self>
  ) -> UnsafeMutablePointer<_AtomicReferenceStorage> {
    // `Self` is layout-compatible with its only stored property.
    return UnsafeMutableRawPointer(ptr)
      .assumingMemoryBound(to: _AtomicReferenceStorage.self)
  }
}

extension AtomicReferenceStorage: AtomicStorage {
  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  @_semantics("atomics.requires_constant_orderings")
  public static func atomicLoad(
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicLoadOrdering
  ) -> Value {
    // FIXME: All orderings are treated as acquiring-and-releasing.
    let result = _AtomicReferenceStorage.atomicLoad(at: Self._extract(pointer))
    return unsafeDowncast(result!, to: Value.self)
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  @_semantics("atomics.requires_constant_orderings")
  public static func atomicStore(
    _ desired: __owned Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicStoreOrdering
  ) {
    // FIXME: All orderings are treated as acquiring-and-releasing.
    _ = _AtomicReferenceStorage.atomicExchange(
      desired,
      at: _extract(pointer))
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  @_semantics("atomics.requires_constant_orderings")
  public static func atomicExchange(
    _ desired: __owned Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> Value {
    // FIXME: All orderings are treated as acquiring-and-releasing.
    let result = _AtomicReferenceStorage.atomicExchange(
      desired,
      at: _extract(pointer))
    return unsafeDowncast(result!, to: Value.self)
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  @_semantics("atomics.requires_constant_orderings")
  public static func atomicCompareExchange(
    expected: Value,
    desired: __owned Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> (exchanged: Bool, original: Value) {
    // FIXME: All orderings are treated as acquiring-and-releasing.
    let result = _AtomicReferenceStorage.atomicCompareExchange(
      expected: expected,
      desired: desired,
      at: _extract(pointer))
    return (result.exchanged, unsafeDowncast(result.original!, to: Value.self))
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  @_semantics("atomics.requires_constant_orderings")
  public static func atomicCompareExchange(
    expected: Value,
    desired: __owned Value,
    at pointer: UnsafeMutablePointer<Self>,
    successOrdering: AtomicUpdateOrdering,
    failureOrdering: AtomicLoadOrdering
  ) -> (exchanged: Bool, original: Value) {
    // FIXME: All orderings are treated as acquiring-and-releasing.
    let result = _AtomicReferenceStorage.atomicCompareExchange(
      expected: expected,
      desired: desired,
      at: _extract(pointer))
    return (result.exchanged, unsafeDowncast(result.original!, to: Value.self))
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  @_semantics("atomics.requires_constant_orderings")
  public static func atomicWeakCompareExchange(
    expected: Value,
    desired: __owned Value,
    at pointer: UnsafeMutablePointer<Self>,
    successOrdering: AtomicUpdateOrdering,
    failureOrdering: AtomicLoadOrdering
  ) -> (exchanged: Bool, original: Value) {
    // FIXME: All orderings are treated as acquiring-and-releasing.
    let result = _AtomicReferenceStorage.atomicCompareExchange(
      expected: expected,
      desired: desired,
      at: _extract(pointer))
    return (result.exchanged, unsafeDowncast(result.original!, to: Value.self))
  }
}

@frozen
public struct AtomicOptionalReferenceStorage<Instance: AnyObject> {
  @usableFromInline
  internal var _storage: _AtomicReferenceStorage

  @inlinable
  public init(_ value: __owned Instance?) {
    _storage = .init(value)
  }

  @inlinable
  public func dispose() -> Instance? {
    guard let value = _storage.dispose() else { return nil }
    return unsafeDowncast(value, to: Instance.self)
  }
}

extension AtomicOptionalReferenceStorage {
  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  static func _extract(
    _ ptr: UnsafeMutablePointer<Self>
  ) -> UnsafeMutablePointer<_AtomicReferenceStorage> {
    // `Self` is layout-compatible with its only stored property.
    return UnsafeMutableRawPointer(ptr)
      .assumingMemoryBound(to: _AtomicReferenceStorage.self)
  }
}

extension AtomicOptionalReferenceStorage: AtomicStorage {
  public typealias Value = Instance?

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  @_semantics("atomics.requires_constant_orderings")
  public static func atomicLoad(
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicLoadOrdering
  ) -> Instance? {
    // FIXME: All orderings are treated as acquiring-and-releasing.
    let result = _AtomicReferenceStorage.atomicLoad(at: Self._extract(pointer))
    guard let r = result else { return nil }
    return unsafeDowncast(r, to: Instance.self)
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  @_semantics("atomics.requires_constant_orderings")
  public static func atomicStore(
    _ desired: __owned Instance?,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicStoreOrdering
  ) {
    // FIXME: All orderings are treated as acquiring-and-releasing.
    _ = _AtomicReferenceStorage.atomicExchange(
      desired,
      at: _extract(pointer))
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  @_semantics("atomics.requires_constant_orderings")
  public static func atomicExchange(
    _ desired: __owned Instance?,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> Instance? {
    // FIXME: All orderings are treated as acquiring-and-releasing.
    let result = _AtomicReferenceStorage.atomicExchange(
      desired,
      at: _extract(pointer))
    guard let r = result else { return nil }
    return unsafeDowncast(r, to: Instance.self)
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  @_semantics("atomics.requires_constant_orderings")
  public static func atomicCompareExchange(
    expected: Instance?,
    desired: __owned Instance?,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> (exchanged: Bool, original: Instance?) {
    // FIXME: All orderings are treated as acquiring-and-releasing.
    let result = _AtomicReferenceStorage.atomicCompareExchange(
      expected: expected,
      desired: desired,
      at: _extract(pointer))
    guard let original = result.original else { return (result.exchanged, nil) }
    return (result.exchanged, unsafeDowncast(original, to: Instance.self))
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  @_semantics("atomics.requires_constant_orderings")
  public static func atomicCompareExchange(
    expected: Instance?,
    desired: __owned Instance?,
    at pointer: UnsafeMutablePointer<Self>,
    successOrdering: AtomicUpdateOrdering,
    failureOrdering: AtomicLoadOrdering
  ) -> (exchanged: Bool, original: Instance?) {
    // FIXME: All orderings are treated as acquiring-and-releasing.
    let result = _AtomicReferenceStorage.atomicCompareExchange(
      expected: expected,
      desired: desired,
      at: _extract(pointer))
    guard let original = result.original else { return (result.exchanged, nil) }
    return (result.exchanged, unsafeDowncast(original, to: Instance.self))
  }

  @inlinable @inline(__always)
  @_alwaysEmitIntoClient
  @_semantics("atomics.requires_constant_orderings")
  public static func atomicWeakCompareExchange(
    expected: Instance?,
    desired: __owned Instance?,
    at pointer: UnsafeMutablePointer<Self>,
    successOrdering: AtomicUpdateOrdering,
    failureOrdering: AtomicLoadOrdering
  ) -> (exchanged: Bool, original: Instance?) {
    // FIXME: All orderings are treated as acquiring-and-releasing.
    let result = _AtomicReferenceStorage.atomicCompareExchange(
      expected: expected,
      desired: desired,
      at: _extract(pointer))
    guard let original = result.original else { return (result.exchanged, nil) }
    return (result.exchanged, unsafeDowncast(original, to: Instance.self))
  }
}
