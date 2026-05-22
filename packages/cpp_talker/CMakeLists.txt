cmake_minimum_required(VERSION 3.10)
project(cpp_talker)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(std_msgs REQUIRED)
find_package(cpp_greeter REQUIRED)

add_executable(talker src/talker.cpp)
target_link_libraries(talker cpp_greeter::greeter)
ament_target_dependencies(talker rclcpp std_msgs)

install(TARGETS talker DESTINATION lib/${PROJECT_NAME})

ament_package()
