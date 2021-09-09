//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if !SWIFT_PACKAGE
import XCTest

var testCases = [
  // Basics
  testCase(BasicAtomicIntTests.allTests),
  testCase(BasicAtomicInt8Tests.allTests),
  testCase(BasicAtomicInt16Tests.allTests),
  testCase(BasicAtomicInt32Tests.allTests),
  testCase(BasicAtomicInt64Tests.allTests),
  testCase(BasicAtomicUIntTests.allTests),
  testCase(BasicAtomicUInt8Tests.allTests),
  testCase(BasicAtomicUInt16Tests.allTests),
  testCase(BasicAtomicUInt32Tests.allTests),
  testCase(BasicAtomicUInt64Tests.allTests),
  testCase(BasicAtomicBoolTests.allTests),
  testCase(BasicAtomicPointerTests.allTests),
  testCase(BasicAtomicOptionalPointerTests.allTests),
  testCase(BasicAtomicMutablePointerTests.allTests),
  testCase(BasicAtomicOptionalMutablePointerTests.allTests),
  testCase(BasicAtomicRawPointerTests.allTests),
  testCase(BasicAtomicOptionalRawPointerTests.allTests),
  testCase(BasicAtomicMutableRawPointerTests.allTests),
  testCase(BasicAtomicOptionalMutableRawPointerTests.allTests),
  testCase(BasicAtomicUnmanagedTests.allTests),
  testCase(BasicAtomicOptionalUnmanagedTests.allTests),
  testCase(BasicAtomicRawRepresentableTests.allTests),

  // LockFreeSingleConsumerStackTests
  testCase(LockFreeSingleConsumerStackTests.allTests),

  // DoubleWord
  testCase(DoubleWordTests.allTests),

  // UnsafeAtomicLazyReferenceTests
  testCase(UnsafeAtomicLazyReferenceTests.allTests),
]

#if !(os(Linux) && arch(x86_64)) || ENABLE_DOUBLEWIDE_ATOMICS
testCases += [
  testCase(BasicAtomicDoubleWordTests.allTests),
  testCase(BasicAtomicReferenceTests.allTests),
  testCase(BasicAtomicOptionalReferenceTests.allTests),

  // LockFreeQueue
  testCase(QueueTests.allTests),

  // StrongReferenceRace
  testCase(StrongReferenceRace.allTests),

  // StrongReferenceShuffle
  testCase(StrongReferenceShuffleTests.allTests),
]
#endif

XCTMain(testCases)
#endif
