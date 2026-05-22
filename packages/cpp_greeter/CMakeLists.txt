cmake_minimum_required(VERSION 3.10)
project(cpp_greeter)

find_package(ament_cmake REQUIRED)

# Shared library exporting its headers, for downstream packages to link
# dynamically (so reverse deps need not rebuild against it).
add_library(greeter SHARED src/greeter.cpp)
target_compile_features(greeter PUBLIC cxx_std_17)
target_include_directories(greeter PUBLIC
  "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
  "$<INSTALL_INTERFACE:include>")

install(DIRECTORY include/ DESTINATION include)
install(
  TARGETS greeter
  EXPORT export_cpp_greeter
  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION bin
  INCLUDES DESTINATION include)

ament_export_targets(export_cpp_greeter HAS_LIBRARY_TARGET)

ament_package()
