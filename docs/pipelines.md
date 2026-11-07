# Named pipelines and invocation

The canonical definitions and registry are in [pipelines.zig](../src/pipelines.zig).
Names describe local subsets and intended analogues; `release-o3` and LTO names
do not assert LLVM algorithm parity, full LTO support, or optimizer completeness.
See [current architecture](architecture.md) for the full route map.

## Accepted and development pipelines

| Pipeline | Current contract |
| --- | --- |
| `zig-debug-accepted` | `verify` only. |
| `zig-release-fast-accepted`, `zig-release-safe-accepted`, `zig-release-small-accepted` | `verify,simplifycfg,instcombine,simplifycfg,instcombine,dce,verify`. All three share this list; the second cleanup consumes newly constant library results and safety branches. |
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

Object, assembly, and selection-owner-manifest output use shared preparation in
[compilation.zig](../src/compilation.zig), called by
[main_flow.zig](../src/main_flow.zig) before selection. Explicit `--passes` and
`--pipeline` requests run on these routes; without an explicit request, the
module is verified and emitted without optimization. Exported AIR uses this
same preparation contract after lowering, including for IR output.

An explicit pipeline can run in the same invocation as local codegen:

```sh
zig build run -- --passes=release-o3 --target=x86_64-unknown-linux-gnu --generic-cfg-selector --emit=obj input.ll > output.o
```

Add `--profile=profile.json` for exclusive compilation-phase measurements and
`--selection-owner-output=owners.tsv` for ownership from the object-emission run.
These do not require optimizer pass timing and never write into object stdout.
Independent replay remains `--emit=selection-owner-manifest` with the same
input, target, pass and selection options.

Add `--profile-events=progress.jsonl` to flush progress after each function,
phase, normalization activity, legalizer attempt and original-form retry. It
works independently of `--profile` and preserves the final profile schema.
After interruption, complete JSONL records identify the active work; a partial
last line can be ignored. Progress records alone do not establish a completed
selection census. The whole-compiler diagnostic runner exposes this option as
`--profile-events` and retains the stream beside its final profile and failures.

The patched Zig preopt textual hook chooses an accepted mode alias. The postopt
hook leaves module optimization with LLVM. The separate structured writer helper
in [main_flow_ir_writer.zig](../src/main_flow_ir_writer.zig) conditionally runs
`sccp,simplifycfg,instcombine,dce` for selected surfaces when the relevant preopt
and Zig-mode environment fields are present. That helper sets
`verify_each_pass=false`; it is not the ordinary accepted alias.

Structured descriptor and writer envelopes preserve explicit optimization as a
validated deferred recipe when emitted as IR. Their codegen route builds the
typed module, runs the conditional helper, replays that recipe, then applies
the current CLI request through shared preparation. The envelope body itself
is not optimized as an ordinary textual module. Artifact-generation operations
`--emit=ir-writer` and `--emit=semantic-descriptor` reject optimization requests.

## Verification and analysis lifetime

[ModulePassManager](../src/pass_manager.zig) defaults to verification after each
executed pass. Callers can override that option. When debug variable-location
intrinsics are present, it skips transform categories because salvage is not
modeled, and reports the skipped count.

There is no shared cached-analysis/preservation API. Passes build local analyses
and own the responsibility for updating or rebuilding them after mutation.
Default post-pass verification checks supported IR invariants; it cannot prove
semantic equivalence or repair stale analysis state.

Tracing, timing, and pass limits apply to explicit preparation on all supported
routes. Codegen diagnostics go to stderr; codegen pass controls without an
explicit optimization request are rejected. For textual optimization:

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
