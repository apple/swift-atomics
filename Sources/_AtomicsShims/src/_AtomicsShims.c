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

#include "_AtomicsShims.h"

#if ENABLE_DOUBLEWIDE_ATOMICS
// FIXME: These should be static inline header-only shims, but Swift 5.3 doesn't
// like calls to swift_retain_n/swift_release_n appearing in Swift code, not
// even when imported through C. (See https://bugs.swift.org/browse/SR-13708)

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
#endif
