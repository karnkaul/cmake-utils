include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

# usage: get_get_commit_hash(<cache_var>)
# sets ${cache_var} to commit hash at HEAD, or "unknown"
function(git_get_commit_hash OUTPUT_VAR)
  set(git_commit_hash "[unknown]")
  execute_process(COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    OUTPUT_VARIABLE git_commit_hash
    ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  set(${OUTPUT_VAR} ${git_commit_hash} CACHE STRING "Git commit hash")
  message(STATUS "Git commit hash [${git_commit_hash}] saved to [${OUTPUT_VAR}]")
endfunction()

# usage: git_update_submodules([message_type=WARNING])
# calls git submodule update --init --recursive, outputs message(${message_type}) on failure
function(git_update_submodules)
  set(msg_type WARNING)
  if(${ARGC} GREATER 0)
    set(msg_type ${ARGV0})
  endif()
  message(STATUS "Updating git submodules...")
  execute_process(COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    RESULT_VARIABLE UPDATE_SUBMODULES_RESULT
  )
  if(NOT UPDATE_SUBMODULES_RESULT EQUAL "0")
    message(${msg_type} "git submodule update failed!")
  endif()
endfunction()

# usage: unzip_archive(<archive_name> <subdir>)
# unzips ${subdir}/${archive_name} at ${subdir}, hard error if file doesn't exist
function(unzip_archive archive_name subdir)
  if(NOT EXISTS "${subdir}/${archive_name}")
    message(FATAL_ERROR "Required archvive(s) missing!\n${subdir}/${archive_name}")
  endif()
  message(STATUS "Extracting ${archive_name}...")
  execute_process(COMMAND 
    ${CMAKE_COMMAND} -E tar -xf "${archive_name}"
    WORKING_DIRECTORY "${subdir}"
  )
endfunction()

# usage: target_source_group(<target_name> [prefix])
# sets source group on all sources using current source dir; optionally with prefix
function(target_source_group target)
  get_target_property(sources ${target} SOURCES)
  if(${ARGC} GREATER 1)
    source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}" PREFIX ${ARGV1} FILES ${sources})
  else()
    source_group(TREE "${CMAKE_CURRENT_SOURCE_DIR}" FILES ${sources})
  endif()
endfunction()

# usage: install_target(<target_name> <namespace>)
# installs ${target_name} and its exports under ${namespace} as ${target-name}-targets 
function(install_target target_name namespace)
  message(STATUS "Install ${target_name} under ${namespace}::")
  # install and export targets
  install(TARGETS ${target_name} EXPORT ${target_name}-targets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  )
  # install exported targets
  install(EXPORT ${target_name}-targets
    FILE ${target_name}-targets.cmake
    NAMESPACE ${namespace}::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${target_name}
  )
endfunction()

# usage: install_target_headers()
# installs include/*.hpp and CURRENT_BINARY_DIR/include/*.hpp
function(install_target_headers)
  message(STATUS "Install *.hpp from ${CMAKE_CURRENT_SOURCE_DIR}/include and ${CMAKE_CURRENT_BINARY_DIR}/include")
  # install headers from include
  install(DIRECTORY include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING PATTERN "*.hpp"
  )
  # install generated headers
  install(DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/include/"
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
    FILES_MATCHING PATTERN "*.hpp"
  )
endfunction()

# usage: install_pkg_config(<target_name> [filename=config.cmake.in])
# configures and installs package configuration file ${filename} to CURRENT_BINARY_DIR/${target_name}-config.cmake
function(install_pkg_config target_name)
  set(filename config.cmake.in)
  if(${ARGC} GREATER 1)
    set(filename ${ARGV1})
  endif()
  message(STATUS "Install ${target_name}-config.cmake to ${CMAKE_INSTALL_LIBDIR}/cmake/${target_name}")
  # configure ${target_name}-config.cmake
  configure_package_config_file(${CMAKE_CURRENT_SOURCE_DIR}/${filename}
    "${CMAKE_CURRENT_BINARY_DIR}/${target_name}-config.cmake"
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${target_name}
  )
  # install ${target_name}-config.cmake
  install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${target_name}-config.cmake"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${target_name}
  )
endfunction()

# usage: install_pkg_version(<target_name> <version>)
# configures and installs package configuration version file to CURRENT_BINARY_DIR/${target_name}-config-version.cmake
function(install_pkg_version target_name version)
  message(STATUS "Install ${target_name}-config-version.cmake to ${CMAKE_INSTALL_LIBDIR}/cmake/${target_name}")
  # configure ${target_name}-version.cmake
  write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/${target_name}-config-version.cmake"
    VERSION ${version}
    COMPATIBILITY AnyNewerVersion
  )
  # install ${target_name}-config.cmake, ${target_name}-version.cmake
  install(FILES "${target_name}-version.cmake"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${target_name}
  )
endfunction()

# usage: export_target_to_build_tree(<target_name> <namespace>)
# exports ${target_name} to CURRENT_BINARY_DIR/${target_name}-targets.cmake
function(export_target_to_build_tree target_name namespace)
  message(STATUS "Exporting ${target_name}-targets.cmake to ${CMAKE_CURRENT_BINARY_DIR}")
  # export targets to current build tree
  export(EXPORT ${target_name}-targets
    FILE "${CMAKE_CURRENT_BINARY_DIR}/${target_name}-targets.cmake"
    NAMESPACE ${namespace}::
  )
endfunction()

# usage: install_and_export_target(<target_name> [namespace=target_name] [headers=ON] [build_export=ON])
# installs and exports ${target_name}, optionally with headers and to CURRENT_BINARY_DIR
# installs package configuration version if ${${namespace}_version} is set
function(install_and_export_target target_name)
  set(namespace ${target_name})
  set(headers ON)
  set(build_export ON)
  if(${ARGC} GREATER 1)
    set(namespace ${ARGV1})
  endif()
  if(${ARGC} GREATER 2)
    set(headers ${ARGV2})
  endif()
  if(${ARGC} GREATER 3)
    set(build_export ${ARGV3})
  endif()
  install_target(${target_name} ${namespace})
  if(headers)
    install_target_headers()
  endif()
  install_pkg_config(${target_name})
  if(NOT "${${namespace}_version}" STREQUAL "")
    install_pkg_version(${target_name} ${${namespace}_version})
  endif()
  if(build_export)
    export_target_to_build_tree(${target_name} ${namespace})
  endif()
endfunction()
