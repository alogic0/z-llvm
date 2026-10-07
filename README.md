# z_llvm

An experimental Zig implementation of the LLVM IR, optimization, and x86_64
code-generation behavior needed by the Zig compiler. Selected fixtures and
compiler-core rows are supported; this is not a complete LLVM replacement or a
self-hosting Zig backend.

See the [current architecture](docs/architecture.md) for input routes, optimizer
invocation, selector ownership, and the scope of validation evidence.

## Build and isolated tests

Use **Zig 0.17.0**, pinned in `.zigversion`. If PATH selects another compiler,
invoke the 0.17.0 executable explicitly. Build-tool subprocesses inherit that
same compiler; the patched integration emitter is selected separately.

```sh
zig build
zig build test-unit
zig build test-unit -Dtest-filter=verifier
zig build structural-smoke artifact-store-test
zig build check-docs
zig build run -- --help
```

Unit tests and storage tests do not require the patched sibling compiler,
historical worktrees, or LLVM utilities. `zig build test` additionally runs the
ABI integration gate and retains its external requirements.

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

[Current state](docs/current_state.md) distinguishes accepted evidence from
pending development. The [improvement plan](docs/roadmap/project_improvement_plan.md)
records implementation progress; [documentation](docs/README.md) contains the
compiler architecture and historical roadmap.
