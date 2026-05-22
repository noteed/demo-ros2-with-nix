# Usage:
#
#   nix-shell -A shells.base
#   nix-shell -A shells.py_talker-dev
#   nix-shell -A shells.py_talker-artefact
#
#   nix-build -A packages.py_talker
let
  base = import ./ros2 { };
  py_talker = import ./packages/py_talker { };
  cpp_greeter = import ./packages/cpp_greeter { };
  cpp_talker = import ./packages/cpp_talker { };
in
{
  shells = {
    base = base.baseShell;
    # Plain non-Nix workflow: the Nix env is only the underlay (toolchain);
    # `colcon build` builds every package from source into the workspace
    # overlay. No package comes prebuilt from Nix. (Defined in ros2/.)
    workspace = base.workspaceShell;
    py_talker-dev = py_talker.devShell;
    py_talker-artefact = py_talker.artefactShell;
    cpp_greeter-dev = cpp_greeter.devShell;
    cpp_greeter-artefact = cpp_greeter.artefactShell;
    cpp_talker-dev = cpp_talker.devShell;
    cpp_talker-artefact = cpp_talker.artefactShell;
    # Runs the prebuilt cpp_talker against the working-copy cpp_greeter, no rebuild.
    cpp_talker-open = (import ./packages/cpp_talker/open.nix).shell;
  };

  packages = {
    py_talker = py_talker.package;
    cpp_greeter = cpp_greeter.package;
    cpp_talker = cpp_talker.package;
  };
}
