#!/bin/sh
#===----------------------------------------------------------------------
#
# This source file is part of the Swift Atomics open source project
#
# Copyright (c) 2021 Apple Inc. and the Swift project authors
# Licensed under Apache License v2.0 with Runtime Library Exception
#
# See https://swift.org/LICENSE.txt for license information
#
#===----------------------------------------------------------------------

# Build & test this package in as many configurations as possible.
# It is a good idea to run this script before each release to uncover
# potential problems not covered by the usual CI runs.
#
# Note that this is not a fully automated solution -- some manual editing will
# sometimes be required when e.g. testing the package on older Xcode releases.

set -eu

cd "$(dirname $0)/.."

build_dir="$(mktemp -d "/tmp/$(basename $0).XXXXX")"

bold_on="$(tput bold)"
bold_off="$(tput sgr0)"

red_on="$(tput setaf 1)"
red_off="$(tput sgr0)"

spm_flags=""

if [ "$(uname)" = "Darwin" ]; then
    swift="xcrun swift"
else
    swift="swift"
    spm_flags="$spm_flags -j 1"
fi

echo "Build output logs are saved in $bold_on$build_dir$bold_off"
swift --version

report_failure() {
    logs="$1"
}

_count=0
try() {
    label="$1"
    shift
    _count=$(($_count + 1))
    count="$(printf "%02d" $_count)"
    output="$build_dir/$count.$label.log"
    echo "$bold_on[$count $label]$bold_off $@"
    start="$(date +%s)"
    if "$@" >"$output" 2>&1; then
        end="$(date +%s)"
        echo "  Completed in $(($end - $start))s"
    else
        end="$(date +%s)"
        echo "  ${red_on}${bold_on}Failed in $(($end - $start))s.${bold_off}${red_off}" \
             "${red_on}See $output for full console output.${red_off}"
        tail -10 "$output" | sed 's/^/  /'
    fi
}

# Build using SPM
try "spm.debug" $swift test -c debug $spm_flags --build-path "$build_dir/spm.debug"
try "spm.release" $swift test -c release $spm_flags --build-path "$build_dir/spm.release"
if [ "$(uname)" = "Linux" ]; then
    try "spm.release.dword" $swift test -c release $spm_flags -Xcc -mcx16 -Xswiftc -DENABLE_DOUBLEWIDE_ATOMICS --build-path "$build_dir/spm.release.dword"
fi

# Build with CMake
cmake_debug_build_dir="$build_dir/cmake.debug"
try "cmake.debug.generate" cmake -S . -B "$cmake_debug_build_dir" -G Ninja -DCMAKE_BUILD_TYPE=DEBUG
try "cmake.debug.build-with-ninja" ninja -C "$cmake_debug_build_dir" 

cmake_release_build_dir="$build_dir/cmake.release"
try "cmake.release.generate" cmake -S . -B "$cmake_release_build_dir" -G Ninja -DCMAKE_BUILD_TYPE=RELEASE
try "cmake.release.build-with-ninja" ninja -C "$cmake_release_build_dir"
if [ "$(uname)" != "Darwin" ]; then # We have not hooked up cmake tests on Darwin yet
    try "cmake.release.test" "$cmake_release_build_dir/bin/AtomicsTestBundle"
fi


if [ "$(uname)" = "Darwin" ]; then
    # Build using xcodebuild
    try "xcodebuild.build" \
        xcodebuild -scheme swift-atomics \
        -configuration Release \
        -destination "generic/platform=macOS" \
        -destination "generic/platform=macOS,variant=Mac Catalyst" \
        -destination "generic/platform=iOS" \
        -destination "generic/platform=iOS Simulator" \
        -destination "generic/platform=watchOS" \
        -destination "generic/platform=watchOS Simulator" \
        -destination "generic/platform=tvOS" \
        -destination "generic/platform=tvOS Simulator" \
        clean build
    try "xcodebuild.test" \
        xcodebuild -scheme swift-atomics \
        -configuration Release \
        -destination "platform=macOS" \
        -destination "platform=macOS,variant=Mac Catalyst" \
        -destination "platform=iOS Simulator,name=iPhone 12" \
        -destination "platform=watchOS Simulator,name=Apple Watch Series 6 - 44mm" \
        -destination "platform=tvOS Simulator,name=Apple TV 4K (at 1080p) (2nd generation)" \
        test
fi

# Build with custom configurations

# Some people like to build their dependencies in warnings-as-errors mode.
try "spm.warnings-as-errors.debug"  $swift build -c debug -Xswiftc -warnings-as-errors $spm_flags --build-path "$build_dir/spm.warnings-as-errors"
try "spm.warnings-as-errors.release"  $swift build -c release -Xswiftc -warnings-as-errors $spm_flags --build-path "$build_dir/spm.warnings-as-errors"

# Build with library evolution enabled. (This configuration is
# unsupported, but let's make some effort not to break it.)
if [ "$(uname)" = "Darwin" ]; then
    try "spm.library-evolution" \
        $swift build \
        -c release \
        $spm_flags \
        --build-path "$build_dir/spm.library-evolution"  \
        -Xswiftc -enable-library-evolution
    try "xcodebuild.library-evolution" \
        xcodebuild -scheme swift-atomics \
        -destination "generic/platform=macOS" \
        -destination "generic/platform=iOS" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES
fi

$swift package clean
