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

#include "_AtomicsShims.h"

// FIXME: _sa_retain_n and _sa_release_n should be static inline header-only
// shims, but Swift 5.3 doesn't like calls to swift_retain_n/swift_release_n
// appearing in Swift code, not even when imported through C.
// (See https://github.com/apple/swift/issues/56105)
//
// Additionally, on Apple platforms we use dlopen/dlsym to avoid linkage issues
// when this shims module is built as a standalone dylib, which happens
// sometimes with the Xcode integration. There is no good way for a package to
// declare that one of its C modules has to link with the Swift runtime, so
// the module fails to link when built as a standalone library.
// (See https://github.com/apple/swift-atomics/issues/55)

#if !(defined(__APPLE__) && defined(__MACH__))
void _sa_retain_n(void *object, uint32_t n)
{
  extern void *swift_retain_n(void *object, uint32_t n);
  swift_retain_n(object, n);
}

void _sa_release_n(void *object, uint32_t n)
{
  extern void swift_release_n(void *object, uint32_t n);
  swift_release_n(object, n);
}
#endif // defined(__APPLE__) && defined(__MACH__)
