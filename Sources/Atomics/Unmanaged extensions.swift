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

#if ATOMICS_SINGLE_MODULE
@_silgen_name("_sa_retain_n")
internal func _sa_retain_n(_ object: UnsafeMutableRawPointer, _ delta: UInt32)

@_silgen_name("_sa_release_n")
internal func _sa_release_n(_ object: UnsafeMutableRawPointer, _ delta: UInt32)
#else
// Note: This file contains the last remaining import of the shims
// module, and we only need it to get the declarations for
// _sa_retain_n/_sa_release_n. The import is unfortunately still
// problematic; these functions need to be moved into the stdlib or
// (preferably) we need a compiler-level fix for
// https://github.com/apple/swift/issues/56105 to get rid of it.
//
// Hiding the import using @_implementationOnly is not possible unless
// Swift's library evolution dialect is enabled. (Which we cannot easily test
// here.) Perhaps `internal import` will help work around this at some point.
import _AtomicsShims
#endif

extension Unmanaged {
  internal func retain(by delta: Int) {
    _sa_retain_n(toOpaque(), UInt32(delta))
  }

  internal func release(by delta: Int) {
    _sa_release_n(toOpaque(), UInt32(delta))
  }
}

extension Unmanaged {
  @inline(__always)
  internal static func passRetained(_ instance: __owned Instance?) -> Self? {
    guard let instance = instance else { return nil }
    return .passRetained(instance)
  }
}

