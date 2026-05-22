let
  base = import ../../ros2 { };
in
{
  pkgs ? base.pkgs,
  rosDistro ? base.rosDistro,
}:

let
  ros = pkgs.rosPackages.${rosDistro};

  package = ros.buildRosPackage {
    pname = "cpp_greeter";
    version = "0.0.1";
    src = base.filter {
      root = ./.;
      include = [ "CMakeLists.txt" "package.xml" (base.dirExt "src" "cpp") (base.dirExt "include" "hpp") ];
    };
    buildType = "ament_cmake";
    nativeBuildInputs = [ ros.ament-cmake ];
  };

  # An attribute with only the headers. This should change less often then the
  # cpp code.
  headers = pkgs.runCommand "cpp_greeter-headers" { } ''
    mkdir -p "$out"
    cp -r ${./include} "$out/include"
  '';

  # Stub libgreeter.so with the right soname and exported symbols. Built from
  # the headers, so it too can change less often than the real implementation.
  stubSource = pkgs.writeText "greeter_stub.cpp" ''
    #include "cpp_greeter/greeter.hpp"
    namespace cpp_greeter { std::string make_greeting(int) { return {}; } }
  '';
  stub = pkgs.runCommand "cpp_greeter-stub" { nativeBuildInputs = [ pkgs.gcc ]; } ''
    mkdir -p "$out/lib"
    g++ -shared -fPIC -std=c++17 -I${headers}/include \
      -Wl,-soname,libgreeter.so -o "$out/lib/libgreeter.so" ${stubSource}
  '';
in
{
  inherit package headers stub;

  # Base env plus cpp_greeter's dependencies, for building the working copy with
  # colcon.
  devShell = pkgs.mkShell {
    name = "cpp_greeter-dev-shell";
    inputsFrom = [ package ];
    packages = [ (ros.buildEnv { paths = base.rosEnvPaths; }) ];
  };

  # Base env plus the prebuilt library in scope (header + lib + cmake config).
  artefactShell = pkgs.mkShell {
    name = "cpp_greeter-artefact-shell";
    packages = [ (ros.buildEnv { paths = base.rosEnvPaths ++ [ package ]; }) ];
  };
}
