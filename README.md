# Swift Atomics ⚛︎︎

[SE-0282]: https://github.com/apple/swift-evolution/blob/master/proposals/0282-atomics.md
[SE-0282r0]: https://github.com/apple/swift-evolution/blob/3a358a07e878a58bec256639d2beb48461fc3177/proposals/0282-atomics.md

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

## Getting Started

To use `Atomics` in your own project, you need to set it up as a package dependency:

```swift
// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "MyPackage",
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-atomics.git", 
      from: "0.0.1"
    )
  ],
  targets: [
    .target(
      name: "MyTarget",
      dependencies: [
        .product(name: "Atomics", package: "swift-atomics")
      ]
    )
  ]
)
```

Because `Atomics` has not reached version 1.0 yet, source stability is only guaranteed within minor versions (e.g. between 0.0.1 and 0.0.2). If you don't want potentially source-breaking package updates, use this dependency specification instead:

```swift
   .package(
      url: "https://github.com/apple/swift-atomics.git", 
      .upToNextMinor(from: "0.0.1")
    )
```


## Supported Types

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

## Lock-Free vs Wait-Free Operations

All atomic operations exposed by this package are guaranteed to have lock-free implementations. However, we do not guarantee wait-free operation -- depending on the capabilities of the target platform, some of the exposed operations may be implemented by compare-and-exchange loops. That said, all atomic operations map directly to dedicated CPU instructions where available -- to the extent supported by llvm & Clang.

## Portability Concerns

Lock-free double-wide atomics requires support for such things from the underlying target platform. Where such support isn't available, this package doesn't implement `DoubleWord` atomics or atomic strong references. While modern multiprocessing CPUs have been providing double-wide atomic instructions for a number of years now, some platforms still target older architectures by default; these require a special compiler option to enable double-wide atomic instructions. This currently includes Linux operating systems running on x86_64 processors, where the `cmpxchg16b` instruction isn't considered a baseline requirement.

To enable double-wide atomics on Linux/x86_64, you currently have to manually supply a couple of additional options on the SPM build invocation:

```
$ swift build -Xcc -mcx16 -Xswiftc -DENABLE_DOUBLEWIDE_ATOMICS -c release
```

(`-mcx16` turns on support for `cmpxchg16b` in Clang, and `-DENABLE_DOUBLEWIDE_ATOMICS` makes Swift aware that double-wide atomics are available. Note that the resulting binaries won't run on some older AMD64 CPUs.)

The package cannot currently configure this automatically.

## Memory Management

Atomic access is implemented in terms of dedicated atomic storage representations that are kept distinct from the corresponding regular (non-atomic) type. (E.g., the actual integer value underlying the counter above isn't directly accessible.) This has several advantages:

- it helps prevent accidental non-atomic access to atomic variables,
- it enables custom storage representations (such as the one used by atomic strong references), and
- it is a better fit with the standard C atomics library that we use to implement the actual operations (as enabled by [SE-0282]).

[SE-0282]: https://github.com/apple/swift-evolution/blob/master/proposals/0282-atomics.md

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

## Contributing

Swift Atomics is a standalone library separate from the core Swift project. We expect some of the atomics APIs may eventually get incorporated into the Swift Standard Library. If and when that happens such changes will be proposed to the Swift Standard Library using the established evolution process of the Swift project.

This library is licensed under the [Swift License]. For more information, see the Swift.org [Community Guidelines], [Contribution Guidelines], as well as the files [LICENSE.txt](./LICENSE.txt), [CONTRIBUTING.md](./CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) at the root of this repository.

Swift Atomics uses GitHub issues to track bugs and enhancement requests. We use pull requests for development.

[Swift License]: https://swift.org/LICENSE.txt
[Community Guidelines]: https://swift.org/community/
[Contribution Guidelines]: https://swift.org/contributing/

## Development

This package defines a large number of similar-but-not-quite-the-same operations. To make it easier to maintain these, we use code generation to produce them.

A number of [source files](./Sources/Atomics) have a `.swift.gyb` extension. These are using a Python-based code generation utility called [gyb](./Utilities/gyb.py) which we also use within the Swift Standard Library (the name is short for Generate Your Boilerplate). To make sure the package remains buildable by SPM, the autogenerated output files are committed into this repository. You must never edit the contents of `autogenerated` subdirectories, or your changes will get overwritten the next time the code is regenerated.

To regenerate sources (and to update the inventory of XCTest tests), you need to manually run the script [`generate-sources`](./generate-sources) in the root of this repository. This needs to be done every time you modify one of the template files.

The same script also runs `swift test --generate-linuxmain` to register any newly added unit tests.

In addition to gyb, the [`_AtomicsShims.h`](./Sources/_AtomicsShims/include/_AtomicsShims.h) header file uses the C preprocessor to define trivial wrapper functions for every supported atomic operation -- memory ordering pairing.

⚛︎︎

<!-- Local Variables: -->
<!-- mode: markdown -->
<!-- fill-column: 10000 -->
<!-- eval: (setq-local whitespace-style '(face tabs newline empty)) -->
<!-- eval: (whitespace-mode 1) -->
<!-- eval: (visual-line-mode 1) -->
<!-- End: -->
