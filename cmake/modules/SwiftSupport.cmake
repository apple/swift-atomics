#[[
This source file is part of the Swift Atomics Open Source Project

Copyright (c) 2021 Apple Inc. and the Swift project authors
Licensed under Apache License v2.0 with Runtime Library Exception

See https://swift.org/LICENSE.txt for license information
#]]

if(NOT SwiftAtomics_MODULE_TRIPLE)
  set(target_info_cmd "${CMAKE_Swift_COMPILER}" -print-target-info)
  if(CMAKE_Swift_COMPILER_TARGET)
    list(APPEND target_info_cmd -target ${CMAKE_Swift_COMPILER_TARGET})
  endif()
  execute_process(COMMAND ${target_info_cmd} OUTPUT_VARIABLE target_info_json)
  message(CONFIGURE_LOG "Swift target info: ${target_info_cmd}\n"
  "${target_info_json}")

  string(JSON module_triple GET "${target_info_json}" "target" "moduleTriple")
  set(SwiftAtomics_MODULE_TRIPLE "${module_triple}" CACHE STRING "Triple used for installed swift{doc,module, interface} files")
  mark_as_advanced(SwiftAtomics_MODULE_TRIPLE)

  message(CONFIGURE_LOG "Swift module triple: ${module_triple}")
endif()

# Returns the os name in a variable
#
# Usage:
#   get_swift_host_os(result_var_name)
#
#
# Sets ${result_var_name} with the converted OS name derived from
# CMAKE_SYSTEM_NAME.
function(get_swift_host_os result_var_name)
  if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
    set(${result_var_name} macosx PARENT_SCOPE)
  else()
    string(TOLOWER ${CMAKE_SYSTEM_NAME} cmake_system_name_lc)
    set(${result_var_name} ${cmake_system_name_lc} PARENT_SCOPE)
  endif()
endfunction()

function(_install_target module)
  get_swift_host_os(swift_os)
  get_target_property(type ${module} TYPE)

  if(type STREQUAL STATIC_LIBRARY)
    set(swift swift_static)
  else()
    set(swift swift)
  endif()

  install(TARGETS ${module}
    ARCHIVE DESTINATION lib/${swift}/${swift_os}
    LIBRARY DESTINATION lib/${swift}/${swift_os}
    RUNTIME DESTINATION bin)
  if(type STREQUAL EXECUTABLE)
    return()
  endif()

  get_target_property(module_name ${module} Swift_MODULE_NAME)
  if(NOT module_name)
    set(module_name ${module})
  endif()

  install(FILES $<TARGET_PROPERTY:${module},Swift_MODULE_DIRECTORY>/${module_name}.swiftdoc
    DESTINATION lib/${swift}/${swift_os}/${module_name}.swiftmodule
    RENAME ${SwiftAtomics_MODULE_TRIPLE}.swiftdoc)
  install(FILES $<TARGET_PROPERTY:${module},Swift_MODULE_DIRECTORY>/${module_name}.swiftmodule
    DESTINATION lib/${swift}/${swift_os}/${module_name}.swiftmodule
    RENAME ${SwiftAtomics_MODULE_TRIPLE}.swiftmodule)
endfunction()
