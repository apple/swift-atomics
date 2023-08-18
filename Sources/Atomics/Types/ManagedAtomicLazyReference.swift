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

/// A reference type holding a lazily initializable atomic
/// strong reference, with automatic memory management.
///
/// These values can be set (initialized) exactly once, but read many
/// times.
@_fixed_layout
public class ManagedAtomicLazyReference<Instance: AnyObject> {
  /// The value logically stored in an atomic lazy reference value.
  public typealias Value = Instance?

  @usableFromInline
  internal typealias _Rep = Optional<Unmanaged<Instance>>.AtomicRepresentation

  /// The atomic representation of the value stored inside.
  ///
  /// Warning: This ivar must only ever be accessed via `_ptr` after
  /// its initialization.
  @usableFromInline
  internal let _storage: _Rep

  /// Initializes a new managed atomic lazy reference with a nil value.
  @inlinable
  public init() {
    _storage = _Rep(nil)
  }

  deinit {
    if let unmanaged = _ptr.pointee.dispose() {
      unmanaged.release()
    }
  }

  @_alwaysEmitIntoClient @inline(__always)
  internal var _ptr: UnsafeMutablePointer<_Rep> {
    _getUnsafePointerToStoredProperties(self).assumingMemoryBound(to: _Rep.self)
  }
}

extension ManagedAtomicLazyReference: @unchecked Sendable
where Instance: Sendable {}

extension ManagedAtomicLazyReference {
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
