// swift-tools-version:5.10
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 - 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import PackageDescription

var _cSettings: [CSetting] = []
var _swiftSettings: [SwiftSetting] = []

// Enable the use of native Swift compiler builtins instead of C atomics.
_cSettings += [
]
_swiftSettings += [
  .enableExperimentalFeature("BuiltinModule")
]

let package = Package(
  name: "swift-atomics",
  products: [
    .library(
      name: "Atomics",
      targets: ["Atomics"]),
  ],
  targets: [
    .target(
      name: "_AtomicsShims",
      exclude: [
        "CMakeLists.txt"
      ]
    ),
    .target(
      name: "Atomics",
      dependencies: ["_AtomicsShims"],
      exclude: [
        "CMakeLists.txt",
        "Conformances/AtomicBool.swift.gyb",
        "Conformances/IntegerConformances.swift.gyb",
        "Conformances/PointerConformances.swift.gyb",
        "Primitives/Primitives.native.swift.gyb",
        "Types/IntegerOperations.swift.gyb",
      ],
      cSettings: _cSettings,
      swiftSettings: _swiftSettings
    ),
    .testTarget(
      name: "AtomicsTests",
      dependencies: ["Atomics"],
      exclude: [
        "main.swift",
        "Basics/BasicTests.gyb-template",
        "Basics/BasicAtomicBoolTests.swift.gyb",
        "Basics/BasicAtomicDoubleWordTests.swift.gyb",
        "Basics/BasicAtomicInt16Tests.swift.gyb",
        "Basics/BasicAtomicInt32Tests.swift.gyb",
        "Basics/BasicAtomicInt64Tests.swift.gyb",
        "Basics/BasicAtomicInt8Tests.swift.gyb",
        "Basics/BasicAtomicIntTests.swift.gyb",
        "Basics/BasicAtomicMutablePointerTests.swift.gyb",
        "Basics/BasicAtomicMutableRawPointerTests.swift.gyb",
        "Basics/BasicAtomicOptionalMutablePointerTests.swift.gyb",
        "Basics/BasicAtomicOptionalMutableRawPointerTests.swift.gyb",
        "Basics/BasicAtomicOptionalPointerTests.swift.gyb",
        "Basics/BasicAtomicOptionalRawPointerTests.swift.gyb",
        "Basics/BasicAtomicOptionalRawRepresentableTests.swift.gyb",
        "Basics/BasicAtomicOptionalReferenceTests.swift.gyb",
        "Basics/BasicAtomicOptionalUnmanagedTests.swift.gyb",
        "Basics/BasicAtomicPointerTests.swift.gyb",
        "Basics/BasicAtomicRawPointerTests.swift.gyb",
        "Basics/BasicAtomicRawRepresentableTests.swift.gyb",
        "Basics/BasicAtomicReferenceTests.swift.gyb",
        "Basics/BasicAtomicUInt16Tests.swift.gyb",
        "Basics/BasicAtomicUInt32Tests.swift.gyb",
        "Basics/BasicAtomicUInt64Tests.swift.gyb",
        "Basics/BasicAtomicUInt8Tests.swift.gyb",
        "Basics/BasicAtomicUIntTests.swift.gyb",
        "Basics/BasicAtomicUnmanagedTests.swift.gyb",
      ],
      swiftSettings: _swiftSettings
    ),
  ]
)
