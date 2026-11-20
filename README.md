# z_llvm

`z_llvm` parses and optimizes LLVM IR and emits x86-64 ELF objects. It is written in Zig.
The project packages it with a patched **Zig 0.17.0** compiler. Together they
compile pure Zig and its compiler runtime in **ReleaseFast for baseline
`x86_64-linux-gnu`** without `libLLVM`, `libclang-cpp` or LLD.
Programs that need the system C library or startup objects still use those
system inputs. [Architecture](docs/architecture.md)

To get the full Zig driver and provider on another machine, follow the
[installation and source-build guide](docs/install_toolchain.md).
If you have the SDK installed, [compile a Zig program](#use-the-packaged-compiler).
From a fresh clone, [build the standalone optimizer](#build-the-standalone-optimizer).

## Use the packaged compiler

Install the accepted second-generation (G2) archive and keep its two
executables and SDK together. [Archive location, checksum and extraction](docs/install_toolchain.md#install-the-reviewed-archive)

From the repository root, compile and run the checked-in hello program.
Set `sdk` to your installation directory if you used another location.

```sh
sdk="${sdk:-$HOME/zig-zllvm-0.17.0-g2}"
"$sdk/bin/zig" build-exe test/zig/integrated/std_debug_hello.zig \
  -O ReleaseFast -target x86_64-linux-gnu -mcpu=baseline \
  -fllvm -fno-libllvm -fno-lld --zllvm-object-provider "$sdk/bin/z_llvm" \
  -femit-bin=./hello && ./hello
```

The program prints `hello` to standard error. To compile your own program,
replace the fixture path with your `main.zig`. The `-fllvm` flag selects
Zig's IR builder. The explicit provider optimizes the IR and emits the object,
and `-fno-lld` selects Zig's native ELF linker.
[Hello source](test/zig/integrated/std_debug_hello.zig) · [Package checksum and recorded upstream `cat` example](docs/evidence/llvm_free_self_rebuild_20261119.md#using-the-package)

## Build the standalone optimizer

From a fresh clone on x86-64 Linux, use Zig 0.17.0 to build `z_llvm` and
optimize a small LLVM IR file. This requires no separate LLVM installation.
[Pinned Zig version](.zigversion) · [Zig 0.17.0 download](https://ziglang.org/download/0.17.0/)

```sh
zig build
./zig-out/bin/z_llvm --emit=ir --passes=instcombine test/opt/inputs/instcombine.ll
```

The input adds zero and multiplies by one. The optimized function returns
its argument directly. [Input IR](test/opt/inputs/instcombine.ll) · [Expected IR](test/opt/expected/z_llvm/instcombine.ll)

```llvm
define i32 @instcombine(i32 %a) {
entry:
  ret i32 %a
}
```

## Do I need LLVM?

| Task | Host LLVM or Clang needed? | Tools used |
| --- | --- | --- |
| Compile pure Zig in ReleaseFast on baseline `x86_64-linux-gnu` | No | Packaged `bin/zig`, `bin/z_llvm` and SDK. Zig links the result with its native ELF linker. |
| Build the standalone optimizer from a clone | No separate installation | Zig 0.17.0 builds `zig-out/bin/z_llvm`. |
| Rebuild Zig and `z_llvm` with the installed toolchain | No | The first installed generation rebuilt both second-generation executables with host LLVM, Clang and LLD excluded. |
| Bootstrap the original compiler from source | Yes for the recorded bootstrap | The initial compiler (G0) used LLVM and Clang to seed the first installed generation (G1). |
| Run comparisons against LLVM | Yes | The development suites use reference tools such as `clang-22` and `opt-22`. |

[Toolchain and bootstrap evidence](docs/evidence/llvm_free_self_rebuild_20261119.md#accepted-g2-package) · [Development environment and comparison tools](docs/environment.md)

## Status

For the November 19, 2026 release, G1 and G2 each matched all 2,097 ordered
upstream ReleaseFast behavior outcomes (2,063 passes and 34 skips) and
produced byte-identical `cat` executables. Separately, the packaged `z_llvm`
helper passed all 17 integration gates, including 237 native regression
cases in each of ReleaseFast, ReleaseSafe and ReleaseSmall.
[Self-rebuild evidence](docs/evidence/llvm_free_self_rebuild_20261119.md) · [Current state and earlier qualifications](docs/current_state.md)

For compiler time, generated-program runtime and binary sizes, see the
[performance comparisons](docs/performance.md). The [next experiment](docs/next_steps.md)
targets slow object emission in the self-built helper.

## Build and isolated tests

CI uses Ubuntu 24.04 x86-64. Use `zig build test-unit` for isolated unit
tests and `zig build test` for unit tests plus the ABI integration gate.
The [contributor instructions](CONTRIBUTING.md#build-and-check-a-change)
give the pinned compiler, focused test filter and full CI commands.

Native tool regex assertions use the public `zig-regex` package source, pinned
with per-file digests. See [tool dependency provenance](tools/vendor/README.md).
Standalone and nested `zig run tools/FILE.zig` commands keep their existing
interface; `zig build verify-regex-source` verifies the snapshot.

Program validation, candidate selection/fact freezing, and performance
measurement run in Zig with pinned `zig-process` and `zig-test-support`
sources. The maintained tools require no Python interpreter. Run
`zig build real-program-policy-tests verify-validation-sources` for their
policy and lifecycle tests. See [validation tooling](docs/validation_tools.md)
for commands, provenance and the migration boundary.

The independent source-analysis CLI is also pinned for this repository:

```sh
zig build source-audit
zig build source-audit -- --json
zig build source-audit -- --include tools --rules architecture.json
```

It scans `src` by default; additional includes and optional rule JSON are passed
to the shared CLI. Metrics and cycles advise review. This adds no new compiler
architecture gate or ABI acceptance claim. [Snapshot identities](tools/vendor/README.md)
record the independent source owner and digests.

## Local experiments

Use `scratch/` for local compiler experiments and their generated IR or assembly.
The directory is ignored by Git. Preserve the original thirteen probes under the
[retention policy](docs/retention_headroom_policy.md); ignoring them does not make
them disposable.

When a probe demonstrates a useful regression case, copy a minimal reproduction
into the appropriate `test/` suite, add explicit assertions, and connect it to
the existing test runner with a documented command. Keep the original probe intact.

## Compiler profiling

For compiler performance investigations, use the [profiling guide](docs/compiler_profiling.md).
User-space hardware sampling was verified on R780M with `perf_event_paranoid=2`
and `--call-graph fp --user-callchains`. Check access before each investigation;
the guide includes recording, stack verification, and separate throughput measurements.

## Integration

The full integration suite uses the pinned patched stage4 fixture emitter and
LLVM 22 reference tools. Run it through the managed launcher with fresh
scratch and cache directories. The Tier 3 guide gives the command, explains
the fresh and cached modes, and identifies the result log.
[Run the full integration suite](docs/validation_tiers.md#run-the-full-integration-suite)
· [Development environment](docs/environment.md) · [Build targets](docs/build_steps.md)

## Artifacts and project status

Artifacts use a local content-addressed store with per-run JSON manifests;
there is no separate control Git repository or fixed workstation topology.
See [storage](docs/zllvm_artifact_retention_contract.md) and
[retention](docs/retention_headroom_policy.md) for publication and cleanup.
The [automatic storage collector](docs/storage_cleanup.md) reviews completed
private caches and explicitly released artifacts, then removes verified
candidates with `tools/clean-storage --apply`. The project policy keeps the
minimum verified state without an arbitrary idle delay. Use
`tools/clean-storage maintain -- COMMAND` to collect after a job under the shared
storage lease; unknown evidence and active/queued work remain protected.

The Git repository contains source, fixtures, and acceptance summaries.
Large raw validation runs, build caches, installed binaries, and scratch
experiments stay in ignored local directories. Historical evidence may refer
to those original artifact paths; the isolated checks above run from a fresh
checkout without them.

[Current state](docs/current_state.md) distinguishes accepted evidence from
pending development. [Next steps](docs/next_steps.md) tracks proposed work.
The [documentation index](docs/README.md) links the compiler architecture and
historical roadmap.

For the initial repository upload, see [publishing on GitHub](docs/github.md).

## License

[MIT](LICENSE). Included dependencies and upstream fixtures retain their
[third-party notices](THIRD_PARTY_NOTICES.md).
