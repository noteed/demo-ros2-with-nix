# Use lopsided98/nix-ros-overlay to provide ROS2 and nixpkgs.
{
  # Pin the overlay. Replace `master` with a commit and uncomment sha256 for
  # reproducible builds.
  rosOverlay ? builtins.fetchTarball {
    url = "https://github.com/lopsided98/nix-ros-overlay/archive/master.tar.gz";
    # sha256 = "0000000000000000000000000000000000000000000000000000";
  },
  # The overlay's root default.nix returns nixpkgs with the overlay applied.
  pkgs ? import rosOverlay { },
  rosDistro ? "jazzy",
  # nix-filter, exposed as `filter` so packages can scope their `src` precisely.
  nixFilter ? builtins.fetchTarball {
    url = "https://github.com/numtide/nix-filter/archive/main.tar.gz";
    # sha256 = "0000000000000000000000000000000000000000000000000000";
  },
}:

let
  ros = pkgs.rosPackages.${rosDistro};
  rosEnvPaths = [
    pkgs.colcon
    ros.ros-core
  ];
  filter = import nixFilter;
  rosEnv = ros.buildEnv { paths = rosEnvPaths; };
  shellHook = ''
    eval "$(register-python-argcomplete ros2)"
    eval "$(register-python-argcomplete colcon)"
  '';
in
{
  inherit pkgs rosDistro rosEnvPaths filter;
  # nix-filter matcher: files with extension `ext` under directory `dir`. The
  # directories themselves pass through so the filter descends into them.
  dirExt = dir: ext: filter.and (filter.inDirectory dir) (filter.or_ filter.isDirectory (filter.matchExt ext));
  nixpkgs = pkgs.path;

  baseShell = pkgs.mkShell {
    name = "ros2-${rosDistro}-shell";
    packages = [ rosEnv ];
    inherit shellHook;
  };

  # Like baseShell, but with ament_cmake as a build input (its cmake setup hook
  # makes find_package(ament_cmake_core) work) so `colcon build` can build C++
  # packages from source. rclcpp/std_msgs/rclpy already come from ros-core.
  workspaceShell = pkgs.mkShell {
    name = "ros2-${rosDistro}-workspace-shell";
    nativeBuildInputs = [ ros.ament-cmake ];
    packages = [ rosEnv ];
    inherit shellHook;
  };
}
