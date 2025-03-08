# ``Atomics``

An atomics library for Swift.

## Overview

This package implements an atomics library for Swift, providing atomic operations for a variety of Swift types, including integers and pointer values. The goal is to enable intrepid developers to start building synchronization constructs directly in Swift. 

Atomic operations aren't subject to the usual exclusivity rules. The same memory location may be safely read and updated from multiple concurrent threads of execution, as long as all such access is done through atomic operations. For example, here is a trivial atomic counter:

``` swift
import Atomics
import Dispatch

let counter = ManagedAtomic<Int>(0)

DispatchQueue.concurrentPerform(iterations: 10) { _ in
for _ in 0 ..< 1_000_000 {
counter.wrappingIncrement(ordering: .relaxed)
}
}
counter.load(ordering: .relaxed) // ⟹ 10_000_000
```

The only way to access the counter value is to use one of the methods provided by `ManagedAtomic`, each of which implement a particular atomic operation, and each of which require an explicit ordering value. (Swift supports a subset of the C/C++ memory orderings.) 

## Features

The package implements atomic operations for the following Swift constructs, all of which conform to the public `AtomicValue` protocol:

- Standard signed integer types (`Int`, `Int64`, `Int32`, `Int16`, `Int8`)
- Standard unsigned integer types (`UInt`, `UInt64`, `UInt32`, `UInt16`, `UInt8`)
- Booleans (`Bool`)
- Standard pointer types (`UnsafeRawPointer`, `UnsafeMutableRawPointer`, `UnsafePointer<T>`, `UnsafeMutablePointer<T>`), along with their optional-wrapped forms (such as `Optional<UnsafePointer<T>>`)
- Unmanaged references (`Unmanaged<T>`, `Optional<Unmanaged<T>>`)
- A special `DoubleWord` type that consists of two `UInt` values, `low` and `high`, providing double-wide atomic primitives
- Any `RawRepresentable` type whose `RawValue` is in turn an atomic type (such as simple custom enum types)
- Strong references to class instances that opted into atomic use (by conforming to the `AtomicReference` protocol)

Of particular note is full support for atomic strong references. This provides a convenient memory reclamation solution for concurrent data structures that fits perfectly with Swift's reference counting memory management model. (Atomic strong references are implemented in terms of `DoubleWord` operations.) However, accessing an atomic strong reference is (relatively) expensive, so we also provide a separate set of efficient constructs (`ManagedAtomicLazyReference` and `UnsafeAtomicLazyReference`) for the common case of a lazily initialized (but otherwise constant) atomic strong reference.

### Lock-Free vs Wait-Free Operations

All atomic operations exposed by this package are guaranteed to have lock-free implementations. However, we do not guarantee wait-free operation -- depending on the capabilities of the target platform, some of the exposed operations may be implemented by compare-and-exchange loops. That said, all atomic operations map directly to dedicated CPU instructions where available -- to the extent supported by llvm & Clang.

### Memory Management

Atomic access is implemented in terms of dedicated atomic storage representations that are kept distinct from the corresponding regular (non-atomic) type. (E.g., the actual integer value underlying the counter above isn't directly accessible.) This has several advantages:

- it helps prevent accidental non-atomic access to atomic variables,
- it enables custom storage representations (such as the one used by atomic strong references), and
- it is a better fit with the standard C atomics library that we use to implement the actual operations (as enabled by [SE-0282]).

[SE-0282]: https://github.com/swiftlang/swift-evolution/blob/main/proposals/0282-atomics.md

While the underlying pointer-based atomic operations are exposed as static methods on the corresponding `AtomicStorage` types, we strongly recommend the use of higher-level atomic wrappers to manage the details of preparing/disposing atomic storage. This version of the library provides two wrapper types:

- an easy to use, memory-safe `ManagedAtomic<T>` generic class and
- a less convenient, but more flexible `UnsafeAtomic<T>` generic struct.

Both constructs provide the following operations on all `AtomicValue` types:

```swift
func load(ordering: AtomicLoadOrdering) -> Value
func store(_ desired: Value, ordering: AtomicStoreOrdering)
func exchange(_ desired: Value, ordering: AtomicUpdateOrdering) -> Value

func compareExchange(
expected: Value,
desired: Value,
ordering: AtomicUpdateOrdering
) -> (exchanged: Bool, original: Value)

func compareExchange(
expected: Value,
desired: Value,
successOrdering: AtomicUpdateOrdering,
failureOrdering: AtomicLoadOrdering
) -> (exchanged: Bool, original: Value)

func weakCompareExchange(
expected: Value,
desired: Value,
successOrdering: AtomicUpdateOrdering,
failureOrdering: AtomicLoadOrdering
) -> (exchanged: Bool, original: Value)
```

Integer types come with additional atomic operations for incrementing or decrementing values and bitwise logical operations. `Bool` provides select additional boolean operations along the same vein.

For an introduction to the APIs provided by this package, for now please see the [first version of SE-0282][SE-0282r0]. 

Note that when/if Swift gains support for non-copiable types, we expect to replace both `ManagedAtomic` and `UnsafeAtomic` with a single move-only atomic struct that combines the performance and versatility of `UnsafeAtomic` with the ease-of-use and memory safety of `ManagedAtomic`.

The current version of the `Atomics` module does not implement APIs for tagged atomics (see [issue #1](https://github.com/apple/swift-atomics/issues/1)), although it does expose a `DoubleWord` type that can be used to implement them. (Atomic strong references are already implemented in terms of `DoubleWord`, although in their current form they do not expose any user-customizable bits.)


## Topics

### Atomic Container Types

- ``ManagedAtomic``
- ``UnsafeAtomic``
- ``ManagedAtomicLazyReference``
- ``UnsafeAtomicLazyReference``

### Memory Orderings

- ``AtomicLoadOrdering``
- ``AtomicStoreOrdering``
- ``AtomicUpdateOrdering``

### Atomic Value Protocols

- ``AtomicValue``
- ``AtomicInteger``
- ``AtomicReference``
- ``AtomicOptionalWrappable``

### Atomic Storage Representations

- ``AtomicStorage``
- ``AtomicIntegerStorage``
- ``AtomicRawRepresentableStorage``
- ``AtomicReferenceStorage``
- ``AtomicOptionalReferenceStorage``

### Fences

- ``atomicMemoryFence(ordering:)``

### Value Types

- ``DoubleWord``
