# cmake-utils

Utility functions used across multiple CMake projects.

## Usage

Use `FetchContent` to populate this repository into your project:

```cmake
include(FetchContent)
set(FETCHCONTENT_QUIET OFF)
FetchContent_Declare(
  cmake-utils
  GIT_REPOSITORY https://github.com/karnkaul/cmake-utils
  GIT_TAG v1.0
)
FetchContent_MakeAvailable(cmake-utils)
FetchContent_GetProperties(cmake-utils)
```

Include the script and call functions as desired:

```cmake
set(${PROJECT_NAME}_version 1.0.0)
set(${PROJECT_NAME}_soversion 1)
add_library(${PROJECT_NAME})
add_library(${PROJECT_NAME}::${PROJECT_NAME} ALIAS ${PROJECT_NAME})
set_property(TARGET ${PROJECT_NAME} PROPERTY VERSION ${${PROJECT_NAME}_version})
set_property(TARGET ${PROJECT_NAME} PROPERTY SOVERSION ${${PROJECT_NAME}_soversion})
set_property(TARGET ${PROJECT_NAME} PROPERTY INTERFACE_${PROJECT_NAME}_MAJOR_VERSION ${${PROJECT_NAME}_soversion})
set_property(TARGET ${PROJECT_NAME} APPEND PROPERTY COMPATIBLE_INTERFACE_STRING ${PROJECT_NAME}_MAJOR_VERSION)

# ...
include("${cmake-utils_SOURCE_DIR}/cmake-utils.cmake")
install_and_export_target(${PROJECT_NAME})
```
