//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2021 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#if MANUAL_TEST_DISCOVERY
import XCTest

var testCases = [
  // Basics
  testCase(BasicAtomicBoolTests.allTests),
  testCase(BasicAtomicDoubleWordTests.allTests),
  testCase(BasicAtomicInt16Tests.allTests),
  testCase(BasicAtomicInt32Tests.allTests),
  testCase(BasicAtomicInt64Tests.allTests),
  testCase(BasicAtomicInt8Tests.allTests),
  testCase(BasicAtomicIntTests.allTests),
  testCase(BasicAtomicMutablePointerTests.allTests),
  testCase(BasicAtomicMutableRawPointerTests.allTests),
  testCase(BasicAtomicOptionalMutablePointerTests.allTests),
  testCase(BasicAtomicOptionalMutableRawPointerTests.allTests),
  testCase(BasicAtomicOptionalPointerTests.allTests),
  testCase(BasicAtomicOptionalRawPointerTests.allTests),
  testCase(BasicAtomicOptionalReferenceTests.allTests),
  testCase(BasicAtomicOptionalUnmanagedTests.allTests),
  testCase(BasicAtomicPointerTests.allTests),
  testCase(BasicAtomicRawPointerTests.allTests),
  testCase(BasicAtomicRawRepresentableTests.allTests),
  testCase(BasicAtomicReferenceTests.allTests),
  testCase(BasicAtomicUInt16Tests.allTests),
  testCase(BasicAtomicUInt32Tests.allTests),
  testCase(BasicAtomicUInt64Tests.allTests),
  testCase(BasicAtomicUInt8Tests.allTests),
  testCase(BasicAtomicUIntTests.allTests),
  testCase(BasicAtomicUnmanagedTests.allTests),

  testCase(LockFreeSingleConsumerStackTests.allTests),
  testCase(DoubleWordTests.allTests),
  testCase(AtomicLazyReferenceTests.allTests),
  testCase(QueueTests.allTests),
  testCase(StrongReferenceRace.allTests),
  testCase(StrongReferenceShuffleTests.allTests),
]

XCTMain(testCases)
#endif
