#[[
This source file is part of the Swift Atomics Open Source Project

Copyright (c) 2021 - 2025 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

cmake_minimum_required(VERSION 3.16)
project(swift-atomics
  LANGUAGES C Swift)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_Swift_MODULE_DIRECTORY ${CMAKE_BINARY_DIR}/swift)

if(CMAKE_SYSTEM_NAME STREQUAL Windows OR CMAKE_SYSTEM_NAME STREQUAL Darwin)
  option(BUILD_SHARED_LIBS "Build shared libraries by default" YES)
endif()

include(CTest)
include(SwiftSupport)

set(ATOMICS_SWIFT_FLAGS)
set(ATOMICS_C_FLAGS)

if(CMAKE_Swift_COMPILER_VERSION VERSION_GREATER_EQUAL 5.9)
  list(APPEND ATOMICS_SWIFT_FLAGS
    "-enable-experimental-feature BuiltinModule"
    )
endif()

add_subdirectory(Sources)
if(BUILD_TESTING)
  add_subdirectory(Tests)
endif()

get_property(SWIFT_ATOMICS_EXPORTS GLOBAL PROPERTY SWIFT_ATOMICS_EXPORTS)
export(TARGETS ${SWIFT_ATOMICS_EXPORTS}
  NAMESPACE SwiftAtomics::
  FILE swift-atomics-config.cmake
  EXPORT_LINK_INTERFACE_LIBRARIES)
