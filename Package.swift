// swift-tools-version:5.1
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import PackageDescription

let package = Package(
  name: "swift-atomics",
  products: [
    .library(
      name: "Atomics",
      targets: ["Atomics"]),
  ],
  targets: [
    .target(name: "_AtomicsShims"),
    .target(
      name: "Atomics",
      dependencies: ["_AtomicsShims"],
      path: "Sources/Atomics"
    ),
    .testTarget(
      name: "AtomicsTests",
      dependencies: ["Atomics"]
    ),
  ]
)
