# ROS2 with Nix

This is a small repository using Nix to develop and build ROS2 packages. It
uses `lopsided98/nix-ros-overlay` to provide ROS2 and nixpkgs.

We demo 3 workflows that support each the following constraint:

We have two packages, A and B. B depends on A (conversely, B is a reverse
dependency of A). We want to be able to work on A, recompile it, and exercise
it in the context of B, **without** recompiling B.

The basic reason this is possible at all is that A provides a dynamically
loaded library to B. As long as B can find the right `.so` in the right place,
B doesn't need to be recompiled. (This assumes that newer As are ABI-compatible
with what B expects.)

Nix, when used to build packages, breaks the ability to change A under B
without changing B too. The 3 workflows we show sidestep that (otherwise
desired) property.

The 3 workflows are independent of each other and can co-exist. They are:

- Use Nix to provide only the development dependencies, then use the regular
  ROS2 development workflow (i.e. build everything (or only what we'er working
  on) with `colcon`). This doesn't fix a particular A under B, and allows to
  change A without changing B.

  This is a bit similar to using Nix to provide e.g. `cargo` then use `cargo`
  directly to provide dependencies.

- Use Nix to build everything (i.e. A and B). Use Nix to enter a shell where
  those built A and B are present. Source a script in that shell that shadow
  (including from B perspective) the built A by a modified A.

  As long as we stay in the same shell, modifying A can be done in the same
  working copy. If we want the ability to exit and enter the shell again, we
  need to have the modified A living elsewhere, e.g. in a separate Git clone or
  worktree. We can also have a way to enter a shell that doesn't depend at all
  on the working copy.

- Use Nix to build everything (i.e. A and B) but in such a way that B is
  actually built against a stub version of A. When A is modified and built
  again, B doesn't need to be rebuilt because it depends only on the stub,
  which remains unchanged (as long as A's ABI is not impacted by the changes).

  Conceptually, we build a version of B that depends only on A's header files,
  and not its `.cpp` files. Unfortunatly it seems that building B requires some
  object file for A, so we use a stub.

  Managing stubs is additional work. It seems this can be automated easily from
  an existing `.so` file. This means we would need to generate the stub when the
  ABI changes, and commit its source to the repository.

  Generating a stub from the header files, and thus without needing to commit
  other files to the repository, seems technically feasible, but even more
  additional work.

  In this workflow, we can easily enter (and exit and re-enter) a shell: even
  if we change A in the current working copy, B doesn't need to be rebuilt.

# Shells

For each package, it's nice to provide two shells: a development shell (used to
e.g. compile the packagge source), and an artefact shell (where the Nix-built
package is provided, to exercise something "closer" to production).

If the package we're working on is B, we might want to have a modified A in
both shells.

I.e. we want to be able to run a modified package (e.g. because it's beeing
developed in a feature branch)

- from a development shell for that specific package (which thus must provides
  its dependencies, including the ones from the repository)
- from an artefact shell for that specific package
- from a development shell of a reverse dependency
- from an artefact shell of a reverse dependency

(with the constraint that we don't want to rebuild the reverse dependency).

# File hierarchy

- The `ros2/` directory provides two shells:
  - a minimal, base shell, enough to start working with ROS2 and that can be
    used to build richer shells for specific pcackages.
  - a "complete" shell to support the first workflow, i.e. that provides all
    the dependencies for all the packages.

- `packages/py_talker`: just a Python example package, not used in the
  following demos.

- `packages/cpp_greeter`: this is a C++ example package, acting as our A
  dependency. It builds a "greeting" string.

- `packages/cpp_talker`: this is a C++ example package, acting as our B reverse
  dependency. It publishes the `greeting` string.

# Workflow 1 (the ROS2 way)

Note: When building with `colcon`, we'll get `build/`, `install/`, and `log/`
directories. It's a good idea to remove them between demos to avoid a previous
demo to influence the next one.

In this workflow, we enter the "complete" shell, that can be used to build the
whole repository:

```
$ nix-shell -A shells.workspace
```

Note: The same shell is exposed as `nix-shell ros2/default.nix -A
workspaceShell`.

In the shell:

```
# 1. Build everything from source
$ colcon build --base-paths packages
$ source install/setup.bash

# 2. Run. Note we see the current greeting
$ sha1sum install/cpp_talker/lib/cpp_talker/talker
$ sha1sum install/cpp_greeter/lib/libgreeter.so
$ ros2 run cpp_talker talker
^C

# 3. Edit the greeter string
$ sed -i 's/hello-from-cpp-greeter/hello-from-123-xyz/' packages/cpp_greeter/src/greeter.cpp

# 4. Rebuild only the greeter, not cpp_talker
$ colcon build --base-paths packages --packages-select cpp_greeter
# No need for source install/setup.bash here

# 5. Re-run. Note we're using the same talker binary, with a new greeting.
$ sha1sum install/cpp_talker/lib/cpp_talker/talker
$ sha1sum install/cpp_greeter/lib/libgreeter.so
$ ros2 run cpp_talker talker
^C
```

# Workflow 2 (two working copies)

To demonstrate this workflow, prepare a second clone of this repository. We
assume the current one is called `demo-ros2-with-nix`. The new one will act as
the "main" one (`demo-ros2-with-nix-main`):

```
$ cd ..
$ git clone demo-ros2-with-nix demo-ros2-with-nix-main
$ cd -
```

In the "feature" branch, edit the greeter string and build the package. Note
its output path:

```
$ cd ../demo-ros2-with-nix
$ sed -i 's/hello-from-cpp-greeter/hello-from-789-def/' packages/cpp_greeter/src/greeter.cpp
$ nix-build -A packages.cpp_greeter --no-out-link
/nix/store/xxxx-cpp_greeter-0.0.1
/nix/store/zxmqspyl40wrsxjk3d084zkyz8dvld7j-cpp_greeter-0.0.1
```

In the "main" branch, enter the artefact shell of the reverse dependency:

```
$ cd ../demo-ros2-with-nix-main
$ nix-shell -A shells.cpp_talker-artefact
```

And source the shadowing script:

```
$ source scripts/shadow-lib.sh /nix/store/xxxx-cpp_greeter-0.0.1
```

Then run the talker:

```
$ ros2 run cpp_talker talker
^C
```

You should see the modified greeting string.

Note: Entering the shell, then doing changes to the working copy without
exiting/reentering the shell, doesn't change the shell, so it acts as a second
copy too.

# Workflow 3 (using stubs)

## Normal artefact shell

First we demonstate the normal (non-stub) artefact shell.

We can enter the artefact shell of the talker (i.e. B) and see the exact binary
it will use when run. Run these commands and notice the Nix store path and the
displayed message:

```
$ nix-shell packages/cpp_talker/default.nix -A artefactShell --run 'ls -la $(ros2 pkg prefix cpp_talker)/lib/cpp_talker'
$ nix-shell packages/cpp_talker/default.nix -A artefactShell --run 'ros2 run cpp_talker talker'
^C
```

Change `"hello-from-cpp-greeter "` in `cpp_greeter/src/greeter.cpp`, then
re-run the above commands.

```
$ sed -i 's/hello-from-cpp-greeter/hello-from-456-abc/' packages/cpp_greeter/src/greeter.cpp
```

The displayed message is useful to confirm the changed code has been picked up.

You'll see that Nix builds `-cpp_talker-0.0.1.drv`, `-cpp_greeter-0.0.1.drv`,
and `-ros-env.drv`, and the `lib/cpp_talker` directory points at a different
location than at the first run.

## Stub artefact shell

Re-do the experiment while using a different artefact shell:

```
$ nix-shell packages/cpp_talker/open.nix -A shell --run 'ls -la $(ros2 pkg prefix cpp_talker)/lib/cpp_talker'
$ nix-shell packages/cpp_talker/open.nix -A shell --run 'ros2 run cpp_talker talker'
^C
```

This time, the message is also different, but the pointed location stays the
same: `cpp_talker` was not rebuilt, only the environment.

Note: Since we're using artefact shells, we don't have the `colcon`-built
directories appear.
