# Named pipelines and invocation

The canonical definitions and registry are in [pipelines.zig](../src/pipelines.zig).
Names describe local subsets and intended analogues; `release-o3` and LTO names
do not assert LLVM algorithm parity, full LTO support, or optimizer completeness.
See [current architecture](architecture.md) for the full route map.

## Accepted and development pipelines

| Pipeline | Current contract |
| --- | --- |
| `zig-debug-accepted` | `verify` only. |
| `zig-release-fast-accepted`, `zig-release-safe-accepted`, `zig-release-small-accepted` | `verify,simplifycfg,instcombine,dce,verify`. All three share this list. |
| `aarch64-target-independent` | `verify,instcombine,dce,verify`; no AArch64 codegen claim. |
| `scalar-foundation`, `zig-scalar-foundation` | Shared development scalar list, including SCCP, Early CSE, GVN, and cleanup. |
| `memory-foundation` | `simplifycfg,sroa,mem2reg,dce`. |
| `debug-o0` | Broader Debug descriptor with mandatory/instrumentation entries; distinct from verifier-only accepted Debug. |
| `release-o3`, `release-oz` | Broader development scalar/memory/global pipelines; O3 additionally includes loop transforms. Entries include explicit placeholders. |
| `lto-prelink-o3`, `lto-prelink-oz` | Development prelink-oriented lists; names do not establish bitcode/ThinLTO implementation. |

Use `zig build release-pipeline-policy` for the implementation/placeholder
report. Full pass order and status come from the source registry rather than a
second exhaustive copy in this document.

## When passes actually run

For ordinary LLVM-compatible input, the CLI's default IR output runs
`instcombine,dce`; `--passes` and `--pipeline` select the local list. Textual
`module(...)`, `function(...)`, `loop(...)`, and `cgscc(...)` nesting is flattened
into module-pass execution. There are no distinct nested pass managers.

Object, assembly, and selection-owner-manifest output take an earlier branch in
[main_flow.zig](../src/main_flow.zig) and return before the CLI pass manager.
Exported AIR input likewise lowers/prints or lowers/emits without using that
ordinary text-input pass path. Do not infer optimization from a supplied
`--passes` flag on those routes.

Use explicit stages when testing optimizer output through local codegen:

```sh
zig build run -- --passes=release-o3 input.ll > optimized.ll
zig build run -- --target=x86_64-unknown-linux-gnu --generic-cfg-selector --emit=obj optimized.ll > output.o
```

The patched Zig preopt textual hook chooses an accepted mode alias. The postopt
hook leaves module optimization with LLVM. The separate structured writer helper
in [main_flow_ir_writer.zig](../src/main_flow_ir_writer.zig) conditionally runs
`sccp,simplifycfg,instcombine,dce` for selected surfaces when the relevant preopt
and Zig-mode environment fields are present. That helper sets
`verify_each_pass=false`; it is not the ordinary accepted alias.

## Verification and analysis lifetime

[ModulePassManager](../src/pass_manager.zig) defaults to verification after each
executed pass. Callers can override that option. When debug variable-location
intrinsics are present, it skips transform categories because salvage is not
modeled, and reports the skipped count.

There is no shared cached-analysis/preservation API. Passes build local analyses
and own the responsibility for updating or rebuilding them after mutation.
Default post-pass verification checks supported IR invariants; it cannot prove
semantic equivalence or repair stale analysis state.

Tracing, timing, and pass limits are available on the text optimization route:

```sh
zig build run -- --passes=scalar-foundation --trace input.ll
zig build run -- --passes=scalar-foundation --time input.ll
zig build run -- --passes=scalar-foundation --pass-limit=2 input.ll
```

## Evidence boundaries

`compare-opt` covers its named fixture/pass pairs. `optimizer-correctness`
executes 16 regression functions after the focused pipeline and `release-o3`,
using LLVM to compile transformed IR. The standalone behavioral suite instead
checks local composed codegen from unoptimized input; its reference/harness
release modes do not select local release pipelines.

The compiler-core real-row gate lowers exported AIR directly to objects without
invoking this module pass manager. Integrated routes have their own contracts.
A passing `distribution-all` run therefore does not establish every development
pass on every real function. Pass promotion needs explicit pipeline, population,
and executable evidence under [validation tiers](validation_tiers.md).
