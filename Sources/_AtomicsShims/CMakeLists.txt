#[[
This source file is part of the Swift Atomics Open Source Project

Copyright (c) 2021 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

add_library(_AtomicsShims STATIC
  src/_AtomicsShims.c)
target_include_directories(_AtomicsShims PUBLIC
  include)
target_compile_definitions(_AtomicsShims PUBLIC
  ENABLE_DOUBLEWIDE_ATOMICS)
if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
  target_compile_options(_AtomicsShims PUBLIC
    "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-Xcc -mcx16>")
endif()

set_property(GLOBAL APPEND PROPERTY SWIFT_ATOMICS_EXPORTS _AtomicsShims)
