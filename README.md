# z_llvm

An experimental LLVM IR parser, optimizer, and x86-64 code generator written in
Zig. The project implements the compiler behavior needed by Zig's LLVM backend,
with explicit validation against LLVM and native execution.

See the [current architecture](docs/architecture.md) for input routes, optimizer
invocation, selector ownership, and the scope of validation evidence.

## Status

The accepted 2026-11-13 result at backend source `dbf7ade0` emits complete local
objects for all **8,928 original compiler definitions**, **455 original runtime
definitions**, and **7,874 original Debug behavior definitions**. The separate
Small-runtime population also completes all 503 definitions.

The unchanged pinned Zig compiler builds through the local postopt hook and
rebuilds itself with fresh backend execution, inheriting stack and CPU settings
without validation overrides. Both compiler generations match all 2,097 named
reference outcomes, including reference skips, in every mode through both the
normal LLVM and local-hook routes: **16 complete results and 33,552 exact outcome
comparisons**. All 20 delivered local objects pass independent audits.

Debug and ReleaseSafe each pass 2,364 unit tests, 65 structural checks, and two
profiling checks. All eight readiness procedures, 17 integration gates and both
225-population native suites pass; all 6,724 required fault controls are detected.
LLVM frontend optimization and declared LLVM/system providers remain in use.

See the [final acceptance](docs/evidence/compiler_behavior_follow_up_acceptance_20261113.json),
[completed plan](docs/plans/2026-11-11-complete-compiler-object-and-self-rebuild.md),
[current state](docs/current_state.md), and [next steps](docs/next_steps.md).

## Build and isolated tests

The tested development platform is **Linux x86-64**, with Ubuntu 24.04 used in CI.
Use [**Zig 0.17.0**](https://ziglang.org/download/0.17.0/), pinned in
[`.zigversion`](.zigversion). If PATH selects another compiler,
invoke the 0.17.0 executable explicitly. Build-tool subprocesses inherit that
same compiler; the patched integration emitter is selected separately.

```sh
zig build
zig build test-unit
zig build test-unit -Dtest-filter=verifier
zig build structural-smoke artifact-store-test
zig build test-tool-regex
zig build test-tool-regex -Doptimize=ReleaseSafe
zig build check-docs
zig build run -- --help
```

For a small optimization example, build and run:

```sh
zig build -Doptimize=ReleaseSafe
./zig-out/bin/z_llvm --emit=ir --passes=instcombine test/opt/inputs/instcombine.ll
```

This folds the redundant add and multiply into a direct return of the argument.
Use `./zig-out/bin/z_llvm --help` to inspect the available input and output modes.

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

Unit tests and storage tests do not require the patched sibling compiler,
historical worktrees, or LLVM utilities. `zig build test` additionally runs the
ABI integration gate and retains its external requirements.

[GitHub Actions](.github/workflows/ci.yml) builds and runs the isolated checks
in Debug and ReleaseSafe. See [CONTRIBUTING.md](CONTRIBUTING.md) for the same
commands and guidance on additional integration validation.

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

Integration uses the pinned patched compiler in `../ziglang/build/stage4/bin/zig`
and LLVM 22 comparison tools. `ZIG_EMITTER` and `ZIG_SOURCE_DIR` select the emitter
and source checkout. See [environment](docs/environment.md),
[build steps](docs/build_steps.md), and [validation tiers](docs/validation_tiers.md).

```sh
zig build behavioral-diff  # requires clang-22
zig build check-zig-stage4-emitter
mkdir -p local-state/validations/current local-state/caches/current
zig build distribution-all -- --serial --fresh-real-rows \
  --zig-emitter=/absolute/path/to/ziglang/build/stage4/bin/zig \
  --real-rows-validation-root=local-state/validations/current \
  --real-rows-cache-root=local-state/caches/current
```

A fresh run requires a cache root without any `ReleaseFast`, `ReleaseSafe`, or
`ReleaseSmall` entries. The runner checks this before launching subgates. After
a failed fresh run, inspect the retained cache before choosing a new generation;
remove only verified disposable state. Existing generations are never overwritten.

For a cached comparison, reuse the same roots and omit `--fresh-real-rows`.
The runner allocates unique run directories. All three root/emitter selections
are required. Validation/cache roots must exist, be relative, and have the same
final component (`current` above); see [the recorded command](docs/evidence/project_improvement/implementation.md).

To reproduce only the real-row group, use the project compiler on PATH and run:

```sh
zig run tools/run_distribution_real_rows_parallel.zig -- --fresh-export \
  --scratch-root=local-state/validations/current \
  --export-cache-root=local-state/caches/current \
  --zig-emitter=/absolute/path/to/ziglang/build/stage4/bin/zig
```

Omit `--fresh-export` for the required-hit run; cached execution still reruns all
real-row and cohort checks. The same root restrictions apply.

Compare focused logs with `zig run tools/compare_distribution_all_logs.zig -- --real-rows fresh.log cached.log`.
For full Tier-3 logs, omit `--real-rows`. Both modes validate the raw cohort records
before normalizing the independently built wrapper hashes; selected object hashes,
byte counts, results and counters must still match.

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
pending development. The [improvement plan](docs/roadmap/project_improvement_plan.md)
records implementation progress; [documentation](docs/README.md) contains the
compiler architecture and historical roadmap.

For the initial repository upload, see [publishing on GitHub](docs/github.md).

## License

[MIT](LICENSE). Included dependencies and upstream fixtures retain their
[third-party notices](THIRD_PARTY_NOTICES.md).
