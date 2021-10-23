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

## Table of Contents

  * [Getting Started](#getting-started)
  * [Features](#features)
    * [Lock\-Free vs Wait\-Free Operations](#lock-free-vs-wait-free-operations)
    * [Portability Concerns](#portability-concerns)
    * [Memory Management](#memory-management)
  * [Source Stability](#source-stability)
  * [Contributing to Swift Atomics](#contributing-to-swift-atomics)
  * [Development](#development)


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
      .upToNextMajor(from: "1.0.0") // or `.upToNextMinor
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

### Portability Concerns

Lock-free double-wide atomics requires support for such things from the underlying target platform. Where such support isn't available, this package doesn't implement `DoubleWord` atomics or atomic strong references. While modern multiprocessing CPUs have been providing double-wide atomic instructions for a number of years now, some platforms still target older architectures by default; these require a special compiler option to enable double-wide atomic instructions. This currently includes Linux operating systems running on x86_64 processors, where the `cmpxchg16b` instruction isn't considered a baseline requirement.

To enable double-wide atomics on Linux/x86_64, you currently have to manually supply a couple of additional options on the SPM build invocation:

```
$ swift build -Xcc -mcx16 -Xswiftc -DENABLE_DOUBLEWIDE_ATOMICS -c release
```

(`-mcx16` turns on support for `cmpxchg16b` in Clang, and `-DENABLE_DOUBLEWIDE_ATOMICS` makes Swift aware that double-wide atomics are available. Note that the resulting binaries won't run on some older AMD64 CPUs.)

The package cannot currently configure this automatically.

### Memory Management

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

## Source Stability

The Swift Atomics package is source stable. The version numbers follow [Semantic Versioning][semver] -- source breaking changes to public API can only land in a new major version.

[semver]: https://semver.org

The public API of version 1.0 of the `swift-atomics` package consists of non-underscored declarations that are marked `public` in the `Atomics` module.

By "underscored declarations" we mean declarations that have a leading underscore anywhere in their fully qualified name. For instance, here are some names that wouldn't be considered part of the public API, even if they were technically marked public:

- `FooModule.Bar._someMember(value:)` (underscored member)
- `FooModule._Bar.someMember` (underscored type)
- `_FooModule.Bar` (underscored module)
- `FooModule.Bar.init(_value:)` (underscored initializer)

Interfaces that aren't part of the public API may continue to change in any release, including patch releases. 

Note that contents of the `_AtomicsShims` module explicitly aren't public API. (As implied by its underscored module name.) The definitions therein may therefore change at whim, and the entire module may be removed in any new release -- do not import this module directly. We also don't make any source compatibility promises about the contents of the `Utilities` and `Tests` subdirectories.

If you have a use case that requires using underscored APIs, please [submit a Feature Request][enhancement] describing it! We'd like the public interface to be as useful as possible -- although preferably without compromising safety or limiting future evolution.

Future minor versions of the package may introduce changes to these rules as needed.

We'd like this package to quickly embrace Swift language and toolchain improvements that are relevant to its mandate. Accordingly, from time to time, we expect that new versions of this package will require clients to upgrade to a more recent Swift toolchain release. (This allows the package to make use of new language/stdlib features, build on compiler bug fixes, and adopt new package manager functionality as soon as they are available.)

Requiring a new Swift release will only require a minor version bump.

## Contributing to Swift Atomics

Swift Atomics is a standalone library separate from the core Swift project. We expect some of the atomics APIs may eventually get incorporated into the Swift Standard Library. If and when that happens such changes will be proposed to the Swift Standard Library using the established evolution process of the Swift project.

This library is licensed under the [Swift License]. For more information, see the Swift.org [Community Guidelines], [Contribution Guidelines], as well as the files [LICENSE.txt](./LICENSE.txt), [CONTRIBUTING.md](./CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) at the root of this repository.

Swift Atomics uses GitHub issues to track bugs and enhancement requests. We use pull requests for development.

[Swift License]: https://swift.org/LICENSE.txt
[Community Guidelines]: https://swift.org/community/
[Contribution Guidelines]: https://swift.org/contributing/

We have a dedicated [Swift Atomics Forum][forum] where people can ask and answer questions on how to use or work on this package. It's also a great place to discuss its evolution.

[forum]: https://forums.swift.org/c/related-projects/swift-atomics

If you find something that looks like a bug, please open a [Bug Report][bugreport]! Fill out as many details as you can.

To fix a small issue or make a tiny improvement, simply [submit a PR][PR] with the changes you want to make. If there is an [existing issue][issues] for the bug you're fixing, please include a reference to it. Make sure to add tests covering whatever changes you are making.

[PR]: https://github.com/apple/swift-atomics/compare
[issues]: https://github.com/apple/swift-atomics/issues
[bugreport]: https://github.com/apple/swift-atomics/issues/new?assignees=&labels=bug&template=BUG_REPORT.md

For larger feature additions, it's a good idea to discuss your idea in a new [Feature Request][enhancement] or on the [forum] before starting to work on it. If the discussions indicate the feature would be desirable, submit the implementation in a PR, and participate in its review discussion.

[enhancement]: https://github.com/apple/swift-atomics/issues/new?assignees=&labels=enhancement&template=FEATURE_REQUEST.md


## Development

This package defines a large number of similar-but-not-quite-the-same operations. To make it easier to maintain these, we use code generation to produce them.

A number of [source files](./Sources/Atomics) have a `.swift.gyb` extension. These are using a Python-based code generation utility called [gyb](./Utilities/gyb.py) which we also use within the Swift Standard Library (the name is short for Generate Your Boilerplate). To make sure the package remains buildable by SPM, the autogenerated output files are committed into this repository. You should not edit the contents of `autogenerated` subdirectories, or your changes will get overwritten the next time the code is regenerated.

To regenerate sources (and to update the inventory of XCTest tests), you need to manually run the script [`generate-sources.sh`](./Utilities/generate-sources.sh) in the Utilities folder of this repository. This needs to be done every time you modify one of the template files.

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
