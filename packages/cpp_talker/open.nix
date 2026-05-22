# Open shell: run the prebuilt cpp_talker against the working-copy cpp_greeter
# WITHOUT rebuilding the talker. The talker is built "open" -- its dependency is
# a hole that the shell fills with a real library.
#
# Unlike the (real) dev/artefact shells, the talker here is built *header-only*:
#   - it compiles against cpp_greeter's headers, and
#   - it links cpp_greeter's stub libgreeter.so (right soname, trivial bodies).
# Both depend only on the greeter interface, so editing src/greeter.cpp does not
# change this talker's hash -- entering the shell rebuilds only the greeter.
#
# The shell injects the real (working-copy) greeter; the talker's NEEDED
# libgreeter.so is resolved from it at runtime (the env's $out/lib, which the
# overlay's wrappers prepend to LD_LIBRARY_PATH), so `ros2 run` loads the edited
# implementation.
let
  base = import ../../ros2 { };
  pkgs = base.pkgs;
  ros = pkgs.rosPackages.${base.rosDistro};
  greeter = import ../cpp_greeter { };

  hoCMake = pkgs.writeText "CMakeLists.txt" ''
    cmake_minimum_required(VERSION 3.10)
    project(cpp_talker)
    find_package(ament_cmake REQUIRED)
    find_package(rclcpp REQUIRED)
    find_package(std_msgs REQUIRED)
    add_executable(talker src/talker.cpp)
    target_include_directories(talker PRIVATE ${greeter.headers}/include)
    target_link_libraries(talker ${greeter.stub}/lib/libgreeter.so)
    ament_target_dependencies(talker rclcpp std_msgs)
    install(TARGETS talker DESTINATION lib/cpp_talker)
    ament_package()
  '';

  # Header-only talker: depends on the greeter interface (headers + stub) only.
  talker = ros.buildRosPackage {
    pname = "cpp_talker";
    version = "0.0.1";
    src = base.filter {
      root = ./.;
      include = [ "CMakeLists.txt" "package.xml" (base.dirExt "src" "cpp") ];
    };
    buildType = "ament_cmake";
    nativeBuildInputs = [ ros.ament-cmake ];
    propagatedBuildInputs = [ ros.rclcpp ros.std-msgs ];
    postPatch = ''cp ${hoCMake} CMakeLists.txt'';
  };
in
{
  inherit talker;

  shell = pkgs.mkShell {
    name = "cpp_talker-open-shell";
    packages = [ (ros.buildEnv { paths = base.rosEnvPaths ++ [ talker greeter.package ]; }) ];
  };
}
