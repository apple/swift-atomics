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

#if ATOMICS_NATIVE_BUILTINS
import Swift
#endif
#if !ATOMICS_SINGLE_MODULE
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

