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

/// An unsafe reference type holding a lazily initializable atomic
/// strong reference, requiring manual memory management of the
/// underlying storage representation.
///
/// These values can be set (initialized) exactly once, but read many
/// times.
@frozen
public struct UnsafeAtomicLazyReference<Instance: AnyObject> {
  /// The value logically stored in an atomic lazy reference value.
  public typealias Value = Instance?

  @usableFromInline
  internal typealias _Rep = Optional<Unmanaged<Instance>>.AtomicRepresentation

  @usableFromInline
  internal let _ptr: UnsafeMutablePointer<_Rep>

  /// Initialize an unsafe atomic lazy reference that uses the supplied memory
  /// location for storage. The storage location must already be initialized to
  /// represent a valid atomic value.
  ///
  /// At the end of the lifetime of the atomic value, you must manually ensure
  /// that the storage location is correctly `dispose()`d, deinitalized and
  /// deallocated.
  ///
  /// Note: This is not an atomic operation.
  @_transparent // Debug performance
  public init(@_nonEphemeral at pointer: UnsafeMutablePointer<Storage>) {
    // `Storage` is layout-compatible with its only stored property.
    _ptr = UnsafeMutableRawPointer(pointer).assumingMemoryBound(to: _Rep.self)
  }
}

extension UnsafeAtomicLazyReference: @unchecked Sendable
where Instance: Sendable {}

extension UnsafeAtomicLazyReference {
  /// The storage representation for an atomic lazy reference value.
  @frozen
  public struct Storage {
    @usableFromInline
    internal var _storage: _Rep

    /// Initialize a new atomic lazy reference storage value holding `nil`.
    ///
    /// Note: This is not an atomic operation. This call may have side effects
    /// (such as unpaired retains of strong references) that will need to be
    /// undone by calling `dispose()` before the storage value is
    /// deinitialized.
    @inlinable @inline(__always)
    public init() {
      _storage = _Rep(nil)
    }

    /// Prepare this atomic storage value for deinitialization, extracting the
    /// logical value it represents. This invalidates this atomic storage; you
    /// must not perform any operations on it after this call (except for
    /// deinitialization).
    ///
    /// This call prevents resource leaks when destroying the storage
    /// representation of certain `AtomicValue` types. (In particular, ones
    /// that model strong references.)
    ///
    /// Note: This is not an atomic operation. Logically, it implements a
    /// custom destructor for the underlying non-copiable value.
    @inlinable @inline(__always)
    @discardableResult
    public mutating func dispose() -> Value {
      defer { _storage = _Rep(nil) }
      return _storage.dispose()?.takeRetainedValue()
    }
  }
}

extension UnsafeAtomicLazyReference {
  /// Create a new `UnsafeAtomicLazyReference` value by dynamically allocating
  /// storage for it.
  ///
  /// This call is usually paired with `destroy` to get rid of the allocated
  /// storage at the end of its lifetime.
  ///
  /// Note: This is not an atomic operation.
  @inlinable
  public static func create() -> Self {
    let ptr = UnsafeMutablePointer<Storage>.allocate(capacity: 1)
    ptr.initialize(to: Storage())
    return Self(at: ptr)
  }

  /// Disposes of the current value of the storage location corresponding to
  /// this unsafe atomic lazy reference, then deinitializes and deallocates the
  /// storage.
  ///
  /// Note: This is not an atomic operation.
  ///
  /// - Returns: The last value stored in the storage representation before it
  ///   was destroyed.
  @discardableResult
  @inlinable
  public func destroy() -> Value {
    // `Storage` is layout-compatible with its only stored property.
    let address = UnsafeMutableRawPointer(_ptr)
      .assumingMemoryBound(to: Storage.self)
    defer { address.deallocate() }
    return address.pointee.dispose()
  }
}

extension UnsafeAtomicLazyReference {
  /// Atomically initializes this reference if its current value is nil, then
  /// returns the initialized value. If this reference is already initialized,
  /// then `storeIfNilThenLoad(_:)` discards its supplied argument and returns
  /// the current value without updating it.
  ///
  /// The following example demonstrates how this can be used to implement a
  /// thread-safe lazily initialized reference:
  ///
  /// ```
  /// class Image {
  ///   var _histogram: UnsafeAtomicLazyReference<Histogram> = .init()
  ///
  ///   // This is safe to call concurrently from multiple threads.
  ///   var atomicLazyHistogram: Histogram {
  ///     if let histogram = _histogram.load() { return histogram }
  ///     // Note that code here may run concurrently on
  ///     // multiple threads, but only one of them will get to
  ///     // succeed setting the reference.
  ///     let histogram = ...
  ///     return _histogram.storeIfNilThenLoad(histogram)
  /// }
  /// ```
  ///
  /// This operation uses acquiring-and-releasing memory ordering.
  public func storeIfNilThenLoad(_ desired: __owned Instance) -> Instance {
    let desiredUnmanaged = Unmanaged.passRetained(desired)
    let (exchanged, current) = _Rep.atomicCompareExchange(
      expected: nil,
      desired: desiredUnmanaged,
      at: _ptr,
      ordering: .acquiringAndReleasing)
    if !exchanged {
      // The reference has already been initialized. Balance the retain that
      // we performed on `desired`.
      desiredUnmanaged.release()
      return current!.takeUnretainedValue()
    }
    return desiredUnmanaged.takeUnretainedValue()
  }

  /// Atomically loads and returns the current value of this reference.
  ///
  /// The load operation is performed with the memory ordering
  /// `AtomicLoadOrdering.acquiring`.
  public func load() -> Instance? {
    let value = _Rep.atomicLoad(at: _ptr, ordering: .acquiring)
    return value?.takeUnretainedValue()
  }
}
