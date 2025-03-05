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
// RUN: %empty-directory(%t)
// RUN: %gyb %s -o %t/UnsafeAtomicInitializers.swift
// RUN: %line-directive %t/UnsafeAtomicInitializers.swift -- %target-swift-frontend -typecheck -verify %t/UnsafeAtomicInitializers.swift

// #############################################################################
// #                                                                           #
// #            DO NOT EDIT THIS FILE; IT IS AUTOGENERATED.                    #
// #                                                                           #
// #############################################################################

import Atomics

class Foo {
  var value = 0
}
struct Bar {
  var value = 0
}

func test_Int() -> UnsafeAtomic<Int> {
  var storage = UnsafeAtomic<Int>.Storage(0)
  let atomic = UnsafeAtomic<Int>(at: &storage)
  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<Int>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<Int>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_Int64() -> UnsafeAtomic<Int64> {
  var storage = UnsafeAtomic<Int64>.Storage(0)
  let atomic = UnsafeAtomic<Int64>(at: &storage)
  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<Int64>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<Int64>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_Int32() -> UnsafeAtomic<Int32> {
  var storage = UnsafeAtomic<Int32>.Storage(0)
  let atomic = UnsafeAtomic<Int32>(at: &storage)
  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<Int32>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<Int32>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_Int16() -> UnsafeAtomic<Int16> {
  var storage = UnsafeAtomic<Int16>.Storage(0)
  let atomic = UnsafeAtomic<Int16>(at: &storage)
  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<Int16>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<Int16>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_Int8() -> UnsafeAtomic<Int8> {
  var storage = UnsafeAtomic<Int8>.Storage(0)
  let atomic = UnsafeAtomic<Int8>(at: &storage)
  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<Int8>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<Int8>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_UInt() -> UnsafeAtomic<UInt> {
  var storage = UnsafeAtomic<UInt>.Storage(0)
  let atomic = UnsafeAtomic<UInt>(at: &storage)
  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<UInt>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<UInt>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_UInt64() -> UnsafeAtomic<UInt64> {
  var storage = UnsafeAtomic<UInt64>.Storage(0)
  let atomic = UnsafeAtomic<UInt64>(at: &storage)
  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<UInt64>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<UInt64>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_UInt32() -> UnsafeAtomic<UInt32> {
  var storage = UnsafeAtomic<UInt32>.Storage(0)
  let atomic = UnsafeAtomic<UInt32>(at: &storage)
  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<UInt32>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<UInt32>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_UInt16() -> UnsafeAtomic<UInt16> {
  var storage = UnsafeAtomic<UInt16>.Storage(0)
  let atomic = UnsafeAtomic<UInt16>(at: &storage)
  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<UInt16>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<UInt16>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_UInt8() -> UnsafeAtomic<UInt8> {
  var storage = UnsafeAtomic<UInt8>.Storage(0)
  let atomic = UnsafeAtomic<UInt8>(at: &storage)
  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<UInt8>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<UInt8>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_URP() -> UnsafeAtomic<UnsafeRawPointer> {
  var storage = UnsafeAtomic<UnsafeRawPointer>.Storage(
    UnsafeRawPointer(
      UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: 8)))
  let atomic = UnsafeAtomic<UnsafeRawPointer>(at: &storage)
  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<UnsafeRawPointer>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<UnsafeRawPointer>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_UP() -> UnsafeAtomic<UnsafePointer<Bar>> {
  var storage = UnsafeAtomic<UnsafePointer<Bar>>.Storage(
    UnsafePointer(UnsafeMutablePointer<Bar>.allocate(capacity: 1)))
  let atomic = UnsafeAtomic<UnsafePointer<Bar>>(at: &storage)  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<UnsafePointer<Bar>>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<UnsafePointer<Bar>>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_UMRP() -> UnsafeAtomic<UnsafeMutableRawPointer> {
  var storage = UnsafeAtomic<UnsafeMutableRawPointer>.Storage(
    .allocate(byteCount: 8, alignment: 8))
  let atomic = UnsafeAtomic<UnsafeMutableRawPointer>(at: &storage)  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<UnsafeMutableRawPointer>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<UnsafeMutableRawPointer>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_UMP() -> UnsafeAtomic<UnsafeMutablePointer<Bar>> {
  var storage = UnsafeAtomic<UnsafeMutablePointer<Bar>>.Storage(
    .allocate(capacity: 1))
  let atomic = UnsafeAtomic<UnsafeMutablePointer<Bar>>(at: &storage)  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<UnsafeMutablePointer<Bar>>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<UnsafeMutablePointer<Bar>>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_Unmanaged() -> UnsafeAtomic<Unmanaged<Foo>> {
  var storage = UnsafeAtomic<Unmanaged<Foo>>.Storage(
    Unmanaged.passRetained(Foo()))
  let atomic = UnsafeAtomic<Unmanaged<Foo>>(at: &storage)  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<Unmanaged<Foo>>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<Unmanaged<Foo>>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_URPOpt() -> UnsafeAtomic<UnsafeRawPointer?> {
  var storage = UnsafeAtomic<UnsafeRawPointer?>.Storage(nil)
  let atomic = UnsafeAtomic<UnsafeRawPointer?>(at: &storage)  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<UnsafeRawPointer?>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<UnsafeRawPointer?>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_UPOpt() -> UnsafeAtomic<UnsafePointer<Bar>?> {
  var storage = UnsafeAtomic<UnsafePointer<Bar>?>.Storage(nil)
  let atomic = UnsafeAtomic<UnsafePointer<Bar>?>(at: &storage)  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<UnsafePointer<Bar>?>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<UnsafePointer<Bar>?>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_UMRPOpt() -> UnsafeAtomic<UnsafeMutableRawPointer?> {
  var storage = UnsafeAtomic<UnsafeMutableRawPointer?>.Storage(nil)
  let atomic = UnsafeAtomic<UnsafeMutableRawPointer?>(at: &storage)  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<UnsafeMutableRawPointer?>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<UnsafeMutableRawPointer?>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_UMPOpt() -> UnsafeAtomic<UnsafeMutablePointer<Bar>?> {
  var storage = UnsafeAtomic<UnsafeMutablePointer<Bar>?>.Storage(nil)
  let atomic = UnsafeAtomic<UnsafeMutablePointer<Bar>?>(at: &storage)  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<UnsafeMutablePointer<Bar>?>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<UnsafeMutablePointer<Bar>?>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}
func test_UnmanagedOpt() -> UnsafeAtomic<Unmanaged<Foo>?> {
  var storage = UnsafeAtomic<Unmanaged<Foo>?>.Storage(nil)
  let atomic = UnsafeAtomic<Unmanaged<Foo>?>(at: &storage)  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<Unmanaged<Foo>?>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<Unmanaged<Foo>?>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}

func test_UnsafeAtomicLazyReference() -> UnsafeAtomicLazyReference<Foo> {
  var value = UnsafeAtomicLazyReference<Foo>.Storage()
  let atomic = UnsafeAtomicLazyReference(at: &value)  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
  // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomicLazyReference<Foo>.Storage' to 'UnsafeMutablePointer<UnsafeAtomicLazyReference<Foo>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
  // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  return atomic
}

class BrokenAtomicCounter {  // THIS IS BROKEN; DO NOT USE
  private var _storage = UnsafeAtomic<Int>.Storage(0)
  private var _value: UnsafeAtomic<Int>?

  init() {
    // This escapes the ephemeral pointer generated by the inout expression,
    // so it leads to undefined behavior when the pointer gets dereferenced
    // in the atomic operations below. DO NOT DO THIS.
    _value = UnsafeAtomic(at: &_storage)  // expected-warning {{inout expression creates a temporary pointer, but argument 'at' should be a pointer that outlives the call to 'init(at:)'}}
    // expected-note@-1 {{implicit argument conversion from 'UnsafeAtomic<Int>.Storage' to 'UnsafeMutablePointer<UnsafeAtomic<Int>.Storage>' produces a pointer valid only for the duration of the call to 'init(at:)'}}
    // expected-note@-2 {{use 'withUnsafeMutablePointer' in order to explicitly convert argument to pointer valid for a defined scope}}
  }

  func increment() {
    _value!.wrappingIncrement(by: 1, ordering: .relaxed)
  }

  func get() -> Int {
    _value!.load(ordering: .relaxed)
  }
}

struct AtomicCounter {
  typealias Value = Int
  typealias Header = UnsafeAtomic<Value>.Storage

  class Buffer: ManagedBuffer<Header, Void> {
    deinit {
      withUnsafeMutablePointerToHeader { header in
        _ = header.pointee.dispose()
      }
    }
  }

  let buffer: Buffer

  init() {
    buffer =
      Buffer.create(minimumCapacity: 0) { _ in
        Header(0)
      } as! Buffer
  }

  private func _withAtomicPointer<R>(
    _ body: (UnsafeAtomic<Int>) throws -> R
  ) rethrows -> R {
    try buffer.withUnsafeMutablePointerToHeader { header in
      try body(UnsafeAtomic<Int>(at: header))
    }
  }

  func increment() {
    _withAtomicPointer { $0.wrappingIncrement(ordering: .relaxed) }
  }

  func load() -> Int {
    _withAtomicPointer { $0.load(ordering: .relaxed) }
  }
}

struct AtomicUnmanagedRef<Instance: AnyObject> {
  typealias Value = Unmanaged<Instance>?
  typealias Header = UnsafeAtomic<Value>.Storage

  class Buffer: ManagedBuffer<Header, Void> {
    deinit {
      withUnsafeMutablePointerToHeader { header in
        _ = header.pointee.dispose()
      }
    }
  }

  let buffer: Buffer

  init() {
    buffer =
      Buffer.create(minimumCapacity: 0) { _ in
        Header(nil)
      } as! Buffer
  }

  private func _withAtomicPointer<R>(
    _ body: (UnsafeAtomic<Value>) throws -> R
  ) rethrows -> R {
    try buffer.withUnsafeMutablePointerToHeader { header in
      try body(UnsafeAtomic<Value>(at: header))
    }
  }

  func store(_ desired: Value) {
    _withAtomicPointer { $0.store(desired, ordering: .sequentiallyConsistent) }
  }

  func load() -> Value {
    _withAtomicPointer { $0.load(ordering: .sequentiallyConsistent) }
  }
}
