# Install the full compiler on another machine

The release includes `bin/zig`, `bin/z_llvm` and the SDK under `lib/zig`.
It covers pure Zig and its compiler runtime in ReleaseFast on baseline
`x86_64-linux-gnu`. Use the archive for the exact reviewed binaries. The
source procedure below builds a new installation.

## Install the reviewed archive

The [G2 release](https://github.com/alogic0/z-llvm/releases/tag/sdk-0.17.0-g2)
includes the [SDK archive](https://github.com/alogic0/z-llvm/releases/download/sdk-0.17.0-g2/zig-z_llvm-0.17.0-x86_64-linux-gnu.tar.zst)
and its [manifest](evidence/artifacts/zig-z_llvm-releasefast-x86_64-linux-gnu-20261119.json).
On x86-64 Linux, start in an empty directory with curl, GNU tar and zstd
installed. The following commands download the archive, check it, and extract
it into a new SDK directory. Each checksum should print `OK`.

```sh
set -e
archive=zig-z_llvm-0.17.0-x86_64-linux-gnu.tar.zst
sdk="$HOME/zig-zllvm-0.17.0-g2"
curl --fail --location --retry 3 --remote-name \
  "https://github.com/alogic0/z-llvm/releases/download/sdk-0.17.0-g2/$archive"
printf '%s  %s\n' f7f2c83a43475c775e0da17bec9d8fa88a0d2df696ba395240959488a08270c9 "$archive" | sha256sum -c -
mkdir "$sdk"
tar --zstd --no-same-owner --same-permissions --delay-directory-restore -xf "$archive" -C "$sdk"
(cd "$sdk" && sha256sum -c - <<'SUMS'
f8b24bfd4613325a9b25abd6d912c6174ae3d341a3d1722bdf835cd7f66f39f4  bin/zig
771baaa8526d927d5f4b2389ec7086f18f1b017110e72865c1012dec02a670a4  bin/z_llvm
SUMS
)
```

## Build from the pinned sources

Start in an empty directory with Git, curl and zstd installed. The release
tag selects the backend source. The [patched Zig source archive](https://github.com/alogic0/z-llvm/releases/download/sdk-0.17.0-g2/zig-bd0e36fa-src.tar.zst)
contains the driver changes required for the external object provider.
Verify the downloaded bytes and both source revisions before building.
[Source pins and generation comparison](evidence/llvm_free_self_rebuild_20261119.md#accepted-g2-package)

```sh
set -e
work=$(pwd -P)
git clone --depth 1 --branch sdk-0.17.0-g2 https://github.com/alogic0/z-llvm.git backend-src
test "$(git -C backend-src rev-parse HEAD)" = 8c91f09ea8f3082e3dd104c10866661d5ba0f8d1
source_archive=zig-bd0e36fa-src.tar.zst
curl --fail --location --retry 3 --remote-name \
  "https://github.com/alogic0/z-llvm/releases/download/sdk-0.17.0-g2/$source_archive"
printf '%s  %s\n' 922c3208d627a2216f3d0b4731f2d25405a20d6d6ac022feee1d7d862cdc2039 "$source_archive" | sha256sum -c -
zstd -d "$source_archive" -o zig-src.tar
test "$(git get-tar-commit-id < zig-src.tar)" = bd0e36fadb55abd10f502dac3d194488ff861ab8
tar -xf zig-src.tar
```

**Build a seed compiler.** If you already have the extracted release SDK,
set `seed` to its absolute directory and skip to the provider builds below.
For a source-only start, install CMake, a system C/C++ toolchain and compatible
LLVM, Clang and LLD 22 development libraries. Use the pinned Zig checkout's
CMake `stage3` target for the LLVM-enabled bootstrap. Set `CMAKE_PREFIX_PATH`
if those libraries are outside CMake's search path. The original qualification
used an existing LLVM-enabled driver at this step.
[Recorded seed and first installation](evidence/llvm_free_zig_toolchain_20261119.md#what-built-the-package)

```sh
cmake -S "$work/zig-src" -B "$work/bootstrap" -DCMAKE_BUILD_TYPE=Release -DZIG_VERSION=0.17.0
cmake --build "$work/bootstrap" --target stage3
bootstrap="$work/bootstrap/stage3/bin/zig"
seed="$work/seed"
(cd "$work/zig-src" && ZIG_LIB_DIR="$work/zig-src/lib" "$bootstrap" build install \
  --prefix "$seed" --cache-dir "$work/cache-seed-zig" --global-cache-dir "$work/global-seed-zig" -j1 \
  -Dtarget=x86_64-linux-gnu -Dcpu=baseline -Doptimize=ReleaseFast -Dstrip=true \
  -Ddev=full -Dversion-string=0.17.0 -Denable-llvm=false -Duse-llvm=false \
  -Dflat=false -Dno-lib=false -Dno-langref=true)
(cd "$work/backend-src" && "$seed/bin/zig" build install \
  --prefix "$seed" --cache-dir "$work/cache-seed-helper" --global-cache-dir "$work/global-seed-helper" -j1 \
  -Dtarget=x86_64-linux-gnu -Dcpu=baseline -Doptimize=ReleaseFast -Dstrip=true)
```

**Build both tools with the installed provider.** Use a fresh output prefix.
Each build uses the same seed compiler and provider and has its own empty
caches. The release review ran these two installs with G1 in an environment
excluding host LLVM, Clang and LLD. A different seed can produce different
binary hashes. [Two-generation rebuild evidence](evidence/llvm_free_self_rebuild_20261119.md#accepted-g2-package)

```sh
sdk="$work/rebuilt-sdk"
mkdir "$sdk"
(cd "$work/zig-src" && "$seed/bin/zig" build install \
  --prefix "$sdk" --cache-dir "$work/cache-zig" --global-cache-dir "$work/global-zig" -j1 \
  -Dtarget=x86_64-linux-gnu -Dcpu=baseline -Doptimize=ReleaseFast -Dstrip=true \
  -Dzllvm-object-provider="$seed/bin/z_llvm" -Ddev=full -Dversion-string=0.17.0 \
  -Denable-llvm=false -Dflat=false -Dno-lib=false -Dno-langref=true)
(cd "$work/backend-src" && "$seed/bin/zig" build install \
  --prefix "$sdk" --cache-dir "$work/cache-helper" --global-cache-dir "$work/global-helper" -j1 \
  -Dtarget=x86_64-linux-gnu -Dcpu=baseline -Doptimize=ReleaseFast -Dstrip=true \
  -Dzllvm-object-provider="$seed/bin/z_llvm")
```

## Check the installation

With `sdk` pointing to either installation, compile a small program in a
fresh directory. Expect `0.17.0` from the driver and `hello` on standard error
from the executable. The package review also records a complete upstream
`cat` build and six I/O checks. [Reviewed invocation](evidence/llvm_free_self_rebuild_20261119.md#using-the-package)

```sh
"$sdk/bin/zig" version
demo=$(mktemp -d)
printf '%s\n' 'pub fn main() void { @import("std").debug.print("hello\n", .{}); }' > "$demo/main.zig"
"$sdk/bin/zig" build-exe "$demo/main.zig" -O ReleaseFast -target x86_64-linux-gnu \
  -mcpu=baseline -fllvm -fno-libllvm -fno-lld --zllvm-object-provider "$sdk/bin/z_llvm" \
  -femit-bin="$demo/hello" && "$demo/hello"
```
