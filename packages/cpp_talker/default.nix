let
  base = import ../../ros2 { };
in
{
  pkgs ? base.pkgs,
  rosDistro ? base.rosDistro,
}:

let
  ros = pkgs.rosPackages.${rosDistro};

  cpp_greeter = (import ../cpp_greeter { inherit pkgs rosDistro; }).package;

  deps = [ ros.rclcpp ros.std-msgs cpp_greeter ];

  package = ros.buildRosPackage {
    pname = "cpp_talker";
    version = "0.0.1";
    src = base.filter {
      root = ./.;
      include = [ "CMakeLists.txt" "package.xml" (base.dirExt "src" "cpp") ];
    };
    buildType = "ament_cmake";
    nativeBuildInputs = [ ros.ament-cmake ];
    propagatedBuildInputs = deps;
  };
in
{
  inherit package;

  # Base env plus build tooling and cpp_talker's dependencies, for building the
  # working copy with colcon.
  devShell = pkgs.mkShell {
    name = "cpp_talker-dev-shell";
    inputsFrom = [ package ];
    packages = [ (ros.buildEnv { paths = base.rosEnvPaths; }) ];
  };

  # Base env plus the prebuilt package, so `ros2 run cpp_talker talker` works
  # directly.
  artefactShell = pkgs.mkShell {
    name = "cpp_talker-artefact-shell";
    packages = [ (ros.buildEnv { paths = base.rosEnvPaths ++ [ package ]; }) ];
  };
}
