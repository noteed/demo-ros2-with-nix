let
  base = import ../../ros2 { };
in
{
  pkgs ? base.pkgs,
  rosDistro ? base.rosDistro,
}:

let
  ros = pkgs.rosPackages.${rosDistro};

  deps = [ ros.rclpy ros.std-msgs ];

  package = ros.buildRosPackage {
    pname = "py_talker";
    version = "0.0.1";
    src = base.filter {
      root = ./.;
      include = [ "package.xml" "setup.py" "setup.cfg" "resource" (base.dirExt "py_talker" "py") ];
    };
    buildType = "ament_python";
    propagatedBuildInputs = deps;
  };
in
{
  inherit package;

  # Base env plus py_talker's dependencies, for building the working copy with
  # colcon.
  devShell = pkgs.mkShell {
    name = "py_talker-dev-shell";
    packages = [ (ros.buildEnv { paths = base.rosEnvPaths ++ deps; }) ];
  };

  # Base env plus the prebuilt package, so `ros2 run py_talker talker` works
  # directly.
  artefactShell = pkgs.mkShell {
    name = "py_talker-artefact-shell";
    packages = [ (ros.buildEnv { paths = base.rosEnvPaths ++ [ package ]; }) ];
  };
}
