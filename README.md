# z_llvm

An experimental Zig implementation of the LLVM IR, optimization, and x86_64
code-generation behavior needed by the Zig compiler. Selected fixtures and
compiler-core rows are supported; this is not a complete LLVM replacement or a
self-hosting Zig backend.

## Build and isolated tests

Use **Zig 0.16.0**, pinned in `.zigversion`. If PATH selects another compiler,
invoke the 0.16.0 executable explicitly. Build-tool subprocesses inherit that
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

For a cached comparison, reuse the same roots and omit `--fresh-real-rows`.
The runner allocates unique run directories. All three root/emitter selections
are required. Validation/cache roots must exist, be relative, and have the same
final component (`current` above); see [the recorded command](docs/evidence/project_improvement/implementation.md).

## Artifacts and project status

Artifacts use a local content-addressed store with per-run JSON manifests;
there is no separate control Git repository or fixed workstation topology.
See [storage](docs/zllvm_artifact_retention_contract.md) and
[retention](docs/retention_headroom_policy.md) for publication and cleanup.

[Current state](docs/current_state.md) distinguishes accepted evidence from
pending development. The [improvement plan](docs/roadmap/project_improvement_plan.md)
records implementation progress; [documentation](docs/README.md) contains the
compiler architecture and historical roadmap.
