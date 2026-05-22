# From an artefact shell of a reverse dependency, from a "main" working copy,
# this script can be sourced to shadow one library with one provided by a
# "feature" working copy.
#
# Given a built dependency's store path, it:
#   - prepends that path's lib/ to LD_LIBRARY_PATH for ros2 invocations, and
#   - replaces `ros2` with a shell function that calls the (unwrapped) ros2.
#     (Unwrapped, because the nix-ros buildEnv wrapper also prepends its own
#     $out/lib and undo the shadow.)
#
# The shadowing dependency must keep the same soname/ABI.
#
# Usage (e.g. from `nix-shell -A shells.cpp_talker-artefact`):
#
#   source scripts/shadow-lib.sh /nix/store/...-cpp_greeter-0.0.1
#   ros2 run cpp_talker talker      # This uses the shadowing libgreeter.so
#   shadow_lib_off                  # Restore the original (wrapped) ros2

if [ -z "${1:-}" ]; then
  echo "usage: source scripts/shadow-lib.sh <dependency-store-path>" >&2
  return 1 2>/dev/null || exit 1
fi

_shadow_lib="$1/lib"
if [ ! -d "$_shadow_lib" ]; then
  echo "shadow-lib: no lib/ under $1" >&2
  return 1 2>/dev/null || exit 1
fi

# The unwrapped ros2 that the buildEnv wrapper exec's. `type -P` ignores any
# `ros2` function we may have already defined (so re-sourcing is safe).
_shadow_real_ros2="$(grep -oE '/nix/store/[^ "'"'"']*/bin/ros2' "$(type -P ros2)" | tail -1)"
if [ ! -x "$_shadow_real_ros2" ]; then
  echo "shadow-lib: could not locate the unwrapped ros2 from $(type -P ros2)" >&2
  return 1 2>/dev/null || exit 1
fi

ros2() {
  LD_LIBRARY_PATH="$_shadow_lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    "$_shadow_real_ros2" "$@"
}

shadow_lib_off() {
  unset -f ros2 2>/dev/null
  echo "shadow-lib: restored the normal ros2"
}

echo "shadow-lib: ros2 now loads libraries from $_shadow_lib first"
echo "shadow-lib: (via the unwrapped ros2 at $_shadow_real_ros2)."
echo "shadow-lib: run 'shadow_lib_off' to restore the original ros2."
