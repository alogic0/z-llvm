# Future Optimizer Backlog

This file holds optional follow-up work after the completed finish burn-down
for replacing Zig's LLVM library dependency. It is not an active roadmap.
Promote one item only after selecting a concrete source-backed fixture,
opt-22 delta, or readiness-gate failure.

The current finish state has no active source-backed blocker:

```text
manifest rows=40
optimizer_input=33
unsupported=0
future=4
debug-info-only=0
```

The four future rows are explicit boundaries, not unowned blockers:

```text
tiny_scalar_debug: future
tiny_scalar_release_safe: future
tiny_scalar_release_small: future
vector_future_release_fast: parse,verify,future
```

Latest accepted-pipeline freshness sweep:

```text
tmp/zig_ir/continuous_20260530_151319_debug
  mode=Debug
  passes=zig-debug-accepted
  processed=1474 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0

tmp/zig_ir/continuous_20260530_151319_releasefast
  mode=ReleaseFast
  passes=zig-release-fast-accepted
  processed=1474 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0

tmp/zig_ir/continuous_20260530_151319_releasesafe
  mode=ReleaseSafe
  passes=zig-release-safe-accepted
  processed=1474 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0

tmp/zig_ir/continuous_20260530_151319_releasesmall
  mode=ReleaseSmall
  passes=zig-release-small-accepted
  processed=1474 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0
```

No backlog item is promoted from this sweep because it found no measured
source-backed blocker, no opt-22 mismatch, and no readiness-gate failure.

Latest x86_64 accepted optimizer refresh after the SimplifyCFG common-code
hoist follow-up:

```text
tmp/zig_ir/accepted_20260530_193848_releasefast
  local_commit=d35c341
  mode=ReleaseFast
  target=x86_64-linux-gnu
  passes=zig-release-fast-accepted
  summary=tmp/zig_ir/accepted_20260530_193848_releasefast/summary.txt
  processed=1474 compile_skip=1009 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0

tmp/zig_ir/accepted_20260530_195245_releasesafe
  local_commit=d35c341
  mode=ReleaseSafe
  target=x86_64-linux-gnu
  passes=zig-release-safe-accepted
  summary=tmp/zig_ir/accepted_20260530_195245_releasesafe/summary.txt
  processed=1474 compile_skip=1009 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0

tmp/zig_ir/accepted_20260530_201347_releasesmall
  local_commit=d35c341
  mode=ReleaseSmall
  target=x86_64-linux-gnu
  passes=zig-release-small-accepted
  summary=tmp/zig_ir/accepted_20260530_201347_releasesmall/summary.txt
  processed=1474 compile_skip=1009 emit_ok=465 local_ok=465
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0
```

ReleaseFast remains the primary optimizer replacement row. ReleaseSafe was
refreshed only because SimplifyCFG can affect safety/runtime-call CFG shapes,
and ReleaseSmall was refreshed as milestone evidence. Debug remains optional
for this refresh because no debug metadata or O0 behavior changed. The refreshed
ReleaseFast, ReleaseSafe, and ReleaseSmall discovery artifacts did not capture
optimized output for canonical-form comparison; they prove only that no new
failing source row appeared under the accepted pipelines. Under the focused
validation policy, no handoff/codegen gate was promoted. The four future rows
above are reaffirmed as boundaries; no new evidence changes their status, and
no implementation slice is promoted.

Optimized-output capture is now available through
`tools/zig_corpus_discovery.zig --capture-optimized-output`. The focused
ReleaseFast CFG-sensitive baseline is:

```text
tmp/zig_ir/optimized_cfg_releasefast_20260530
  mode=ReleaseFast
  target=x86_64-linux-gnu
  passes=zig-release-fast-accepted
  processed=11 compile_skip=0 emit_ok=11 local_ok=11
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0
  optimized_output=tmp/zig_ir/optimized_cfg_releasefast_20260530/optimized-ir
```

No prior optimized-output artifact directory existed for a historical diff, so
this baseline does not promote a handoff/codegen gate by itself.

Milestone 1 for `ReleaseFast / x86_64-linux-gnu / asm-object` records a
conservative boundary for the selected Zig-backed object subset in
`docs/roadmap/releasefast_x86_64_object_milestone_1.md`. The broader captured
ReleaseFast object probe over
`tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` now succeeds for
all 17 rows, including the selected `aggregate_abi`, `aggregates`,
`atomics_inline_asm_debug`, `control_flow_calls`, `error_switch`,
floating-point, globals, integer, pointer/memory, switch, and local-exec TLS
shapes.

## Object Evidence

The release-mode object evidence is closed for the selected x86_64 captured
subsets:

| Mode | Capture | Result | Status |
| --- | --- | --- | --- |
| ReleaseFast | `tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` | 17 ok / 0 fail | Conservative boundary for the selected Zig-backed object subset. |
| ReleaseSafe | `tmp/zig_ir/distribution_m2_releasesafe_20260530/optimized-ir` | 17 ok / 0 fail | Conservative boundary for the captured optimized-output object subset. |
| ReleaseSmall | `tmp/zig_ir/distribution_m3_releasesmall_20260531/optimized-ir` | 465 ok / 0 fail / 0 excluded | Conservative boundary for the named captured subset. |

ReleaseFast covers the selected `aggregate_abi`, `aggregates`,
`atomics_inline_asm_debug`, `control_flow_calls`, `error_switch`,
floating-point, globals, integer, pointer/memory, switch, and local-exec TLS
shapes.

### ReleaseSafe Closure

The ReleaseSafe probe started at 8 successes and 9 failures. The closed
blocker rows were:

| Row | Selected closure |
| --- | --- |
| `aggregates.zig.ReleaseSafe.x86_64.optimized.ll` | Checked aggregate sum aliases. |
| `atomics_inline_asm_debug.zig.ReleaseSafe.x86_64.optimized.ll` | Checked `@debug_location`, plus already covered inline-asm/atomic aliases. |
| `control_flow_calls.zig.ReleaseSafe.x86_64.optimized.ll` | Checked `@loop_sum` and guarded `@call_chain`. |
| `error_switch.zig.ReleaseSafe.x86_64.optimized.ll` | Straight-line `@error_switch` `icmp`/`select` lowering. |
| `globals_comptime.zig.ReleaseSafe.x86_64.optimized.ll` | `@comptime_const`, `@update_global`, and `@read_global`. |
| `pointers_memory.zig.ReleaseSafe.x86_64.optimized.ll` | Checked `@load_store` pointer load/add/store and panic edge. |
| `switch_control.zig.ReleaseSafe.x86_64.optimized.ll` | Checked `@branch_mix` and already covered `@dense_switch`. |
| `tiny_scalar.zig.ReleaseSafe.x86_64.optimized.ll` | Checked `@add` and `@sideEffectFree`. |
| `tls_concurrency.zig.ReleaseSafe.x86_64.optimized.ll` | Checked local-exec `@bump_tls` and `@read_tls`. |

### ReleaseSmall Closure

The ReleaseSmall probe started at 263 successes and 202 failures. The broad
row was reduced by closing selected shapes in order, while leaving broad,
multi-slice rows as explicit boundaries where appropriate.

Early closures:

| Row | Selected closure |
| --- | --- |
| `behavior_export_keyword.zig.ReleaseSmall.x86_64.optimized.ll` | Volatile absolute-address store for `@writeToVRam` and `@testPackedStuff`. |
| `behavior_sizeof_and_typeof.zig.ReleaseSmall.x86_64.optimized.ll` | Noreturn unreachable stubs for `@c_fopen`, `@c_ftell`, `@c_fputs`, and `@c_printf`. |
| `c_abi_main.zig.ReleaseSmall.x86_64.optimized.ll` | C ABI fp128, scalar returns, aggregate returns, comparisons, split structs, byval/sret, vector/scalar float shapes, pointer/integer equality, and local panic/trap stubs. |
| `cases_address_space_pointer_access_chaining_pointer_to_optional_array.zig.ReleaseSmall.x86_64.optimized.ll` | Naked startup inline-asm trampoline with `R_X86_64_PLT32` relocation. |
| `cases_array_in_anon_struct.zig.ReleaseSmall.x86_64.optimized.ll` | `getauxval` auxv scan loop over `@os.linux.elf_aux_maybe`. |
| `cases_compile_errors_illegal_operation_on_logical_ptr.zig.ReleaseSmall.x86_64.optimized.ll` | Empty noreturn unreachable compile-error stub. |
| `cases_inherit_want_safety.zig.ReleaseSmall.x86_64.optimized.ll` | i64 constant return materialization. |
| `cases_no_compile_panic_for_unchecked_arith.zig.ReleaseSmall.x86_64.optimized.ll` | Selected `llvm.umul.fix.sat.i64` constant-call return. |
| `standalone_compile_asm_main.zig.ReleaseSmall.x86_64.optimized.ll` | Empty noreturn unreachable stub. |

Final adjusted closures:

| Row | Selected closure |
| --- | --- |
| `standalone_extern_exports.zig.ReleaseSmall.x86_64.optimized.ll` | Hidden `@getHidden` / `@updateHidden` i32 global access. |
| `standalone_install_raw_hex_main.zig.ReleaseSmall.x86_64.optimized.ll` | Two-block infinite loop through unconditional self-branch lowering. |
| `standalone_libfuzzer_main.zig.ReleaseSmall.x86_64.optimized.ll` | `@runner_futex_wait`, string-slice `@runner_test_name`, and runtime-call `@runner_test_run`. |
| `standalone_mix_c_files_main.zig.ReleaseSmall.x86_64.optimized.ll` | Mixed Zig/C `@add_zig` global-add and checked `@add_may_panic` panic-edge branch. |

The former ReleaseSmall exclusions are closed local object boundaries,
validated by `zig build distribution-releasesmall-boundary`:

- `standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll`
  - Proof: `whole-function:str-from-float-help`
  - Fixture:
    `test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll`

- `standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll`
  - Proof: `whole-function:base64-decode-base-64`
  - Fixture:
    `test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll`

## Distribution And Boundary Gates

| Gate | Evidence |
| --- | --- |
| `zig build distribution-no-llvm` | Composes ReleaseFast, ReleaseSafe, selected ReleaseSmall, selected Debug, and handoff validation for `TARGET=x86_64-unknown-linux-gnu`. |
| `zig build distribution-linker-boundary` | Confirms local `z_llvm` stops at `ir`, `asm`, and `obj`; `--emit=exe` fails closed. |
| `zig build distribution-native-link` | Links ABI-stable local objects with `zig build-exe -fno-lld`; current selected probe result is 45 accepted / 0 failed. |
| `zig build distribution-native-link-boundary2` | Broad ReleaseFast, ReleaseSafe, ReleaseSmall, and Debug native-link accounting reports `local_fail=0` with Zig runtime/TLS/compiler-rt/libc boundaries classified separately. |
| `zig build distribution-zig-source-native-link` | Proves 10 selected Zig source rows through stage4 LLVM IR emission, local `z_llvm` object emission, and Zig native linking: 9 executable proofs and 1 ReleaseSafe panic-runtime link-only boundary. |
| `zig build distribution-aarch64-boundary` | Confirms non-x86_64 object target rejection for `--emit=obj --target=aarch64-unknown-linux-gnu`. |
| `zig build distribution-debug-unwind` | Confirms selected Debug objects emit normal object sections but no `.debug_*` or `.eh_frame` ownership. |
| `zig build distribution-boundary` | Composes linker/CRT, ReleaseSmall exclusions, Debug DWARF/unwind, and AArch64 target boundaries. |
| `zig build distribution-all` | Composes the positive no-LLVM-codegen subset, selected native-link proof/probe, and conservative boundary gates. |

Selected executable validation through `zig cc -target "$cc_target"` is
driver/toolchain handoff evidence. Native-linker-only evidence is recorded by
the stricter `zig build distribution-native-link` and
`zig build probe-native-linker` gates.

Broad object probes are reproducible with
`zig build probe-distribution-objects --`, a compatibility shim over
`tools/probe_distribution_objects.zig`. It reports stable per-row
ok/fail/excluded lines, first failure, failure categories, and exclusion
categories.

## Debug Evidence

Debug remains a conservative subset:

- `zig build distribution-debug-object` reports 9 object successes and 0
  failures over `test/zig/expected/debug_*.reduced.ll`.
- Closed selected blockers include call-result plus immediate-add lowering,
  `llvm.dbg.declare` / `llvm.dbg.value` object no-ops, reduced Debug loop-sum,
  reduced Debug scope-branch phi, selected O0 alloca debug prologue before
  volatile pointer roundtrip, Debug/O0 c_* panic-call unreachable stubs, and
  the Debug/O0 f128 sret C ABI shape from `c_abi_main.zig.Debug.x86_64.ll`.
- Selected raw rows are object-clean:
  `tmp/zig_ir/raw/tiny_scalar.Debug.x86_64.ll`,
  `tmp/zig_ir/raw/control_flow_calls.Debug.ll`,
  `tmp/zig_ir/raw/pointers_memory.Debug.ll`, and
  `tmp/zig_ir/raw/tiny_scalar.Debug.ll`.
- Closed broad-Debug parser/verifier boundaries include LLVM `#dbg_*` records,
  `ret` / `unreachable` metadata, sizeless `DIBasicType`, and columnless
  `DILocation` nodes.
- Continuous Debug first-100, first-200, and first-300 optimizer-ok prefixes
  are object-clean; the first-300 prefix is recorded at
  `tmp/zig_ir/debug_object_probe_continuous_prefix300_20260531/ir`.

Broad Debug asm/object still requires LLVM fallback because DWARF/unwind
emission, full O0 codegen, variable-location salvage, broad std Debug rows, and
target-complete ABI lowering remain outside this reduced subset.

## Activation Rule

- Start new work only from a measured source-backed blocker, a concrete
  opt-22 mismatch, or a failing readiness check.
- Use `zig build probe-distribution-objects --` for broad optimized-output
  object probes before adding new ad hoc shell-loop evidence.
- Add or identify the fixture before creating a new cycle.
- Record the LLVM upstream source mapping before marking the cycle complete.
- Keep local conservative behavior documented when LLVM is broader.
- Run `zig build readiness` before closing the cycle.

## Corpus Discovery Candidates

- Refresh selected Zig-emitted IR rows from the current `../ziglang` stage4
  compiler and compare them with the checked manifest rows.
- Add one small Zig source fixture only when it exposes a construct not already
  covered by accepted rows.
- Reduce broad Debug IR only when it contains a concrete uncovered Debug
  construct.
- Reduce broad ReleaseSafe IR only when it contains a concrete uncovered safety
  or runtime-call construct.
- Promote the vector future row only when vector FP semantics, vector-condition
  legality, scalable-vector policy, target-cost modeling, or native vector
  lowering becomes a measured requirement.

## Optimizer Quality Candidates

These are quality improvements, not finish blockers. Pick one only when a
fixture shows the current local behavior is too conservative for a Zig-backed
case.

- SROA: extend aggregate rewriting only when a new fixture shows pressure
  beyond covered scalar leaf partitions, such as memcpy/memmove, padding,
  widening, packed aggregates, or vector fields.
- GVN: add one measured PRE or load-availability slice beyond the current
  MemorySSA-backed fixtures.
- ADCE: improve one measured control-dependence case beyond the current acyclic
  dead-region fixtures.
- DSE: extend MemorySSA-backed byte-range reasoning only for a concrete
  source-backed store pattern.
- EarlyCSE: replace linear expression scans with scoped hash buckets only after
  expression keys include all needed alias-sensitive memory facts.

## Floating-Point Candidates

The parser/verifier and conservative optimizer boundary already cover the
current accepted FP corpus. Further FP work needs new source-backed pressure or
explicit opt-22 parity work.

- Expand the APFloat-shaped semantic model only for a fixture involving NaN,
  infinity, signed zero, subnormals, or target-dependent literals.
- Teach InstSimplify/InstCombine strict FP identities only after legal
  NaN/signed-zero/exception fixtures exist.
- Use fast-math flags as optimization facts only after matching the required
  LLVM `FastMathFlags` legality for the chosen transform.
- Extend SCCP with an FP constant lattice only after APFloat comparison fixtures
  exist.
- Enable FP value numbering/CSE only after strict and fast-math equality rules
  are represented.

## Debug Candidates

Current debug-location-only behavior is fixture-backed. Full variable-location
salvage remains outside the finish scope.

- Treat reduced Debug object emission as a conservative subset only; do not
  promote broad Debug asm/object until a source-backed broad Debug row is
  captured, probed, and reduced from a concrete first blocker.
- Add a debug salvage slice only when a source-backed transform removes or
  replaces an instruction carrying `!dbg` in a way not covered by existing
  fixtures.
- Keep `llvm.dbg.value` and `llvm.dbg.declare` transform pipelines disabled
  until variable-location salvage is represented.
- Reduce new Debug-mode rows only when they contain an uncovered DI node,
  intrinsic, or verifier requirement.

## Backend And Handoff Candidates

The local backend remains validation-only and bounded to documented x86_64
smoke coverage.

- Add one handoff proof only when an accepted optimized IR shape cannot be
  validated by the existing scalar, memory, loop, global, call, stack, and
  stack-memory-to-call cases.
- Keep broad register allocation, scheduling, unwind/debug object generation,
  target-complete ABI lowering, and multi-object-format parity out of scope.

## Explicitly Completed Or Superseded Items

The following earlier backlog ideas are no longer active backlog items because
they were completed, superseded, or converted into conservative boundaries:

- [x] Inline asm representation and barrier preservation.
- [x] `atomicrmw`, `cmpxchg`, and `fence` representation with fail-closed
      verifier rules.
- [x] Vector parser/verifier bootstrap and narrow lane-operation transforms.
- [x] AArch64 target-independent optimizer-input policy.
- [x] Reduced Debug metadata rows for the accepted Debug boundary.
- [x] Path-aware MemorySSA foundation and follow-up vector-lane clobber fix.
- [x] Stale ReleaseSmall unsupported-row closure.
- [x] Selected stage4 corpus freshness audit for `tiny_scalar`, `integers`,
      `switch_control`, and `optional_pointer` ReleaseFast checked captures.
