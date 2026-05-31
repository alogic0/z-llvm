# x86_64 Distribution Replacement Matrix

This matrix tracks the initial `x86_64-linux-gnu` replacement path by Zig mode
and stage. It is narrower than the historical finish line: a row is useful only
when it changes, proves, or bounds removal of Zig's LLVM library fallback for
the selected distribution path.

Status keys:

```text
local replacement: current local implementation has source-backed evidence
conservative boundary: accepted locally only with documented narrower behavior
LLVM fallback required: Zig still needs LLVM or Zig-owned backend work here
out of scope: not part of the current x86_64 milestone
```

## Matrix

| Mode | Parse | Verify | Optimize | Handoff | Asm/Object |
| --- | --- | --- | --- | --- | --- |
| Debug | conservative boundary | conservative boundary | conservative boundary | LLVM fallback required | LLVM fallback required |
| ReleaseFast | local replacement | local replacement | local replacement | conservative boundary | conservative boundary |
| ReleaseSafe | local replacement | local replacement | local replacement | conservative boundary | LLVM fallback required |
| ReleaseSmall | local replacement | local replacement | local replacement | conservative boundary | LLVM fallback required |

## Evidence

ReleaseFast, ReleaseSafe, and ReleaseSmall parse/verify/optimize rows are backed
by the accepted x86_64 sweeps recorded in
`docs/roadmap/source_backed_readiness_audit.md`:

```text
tmp/zig_ir/accepted_20260530_193848_releasefast
tmp/zig_ir/accepted_20260530_195245_releasesafe
tmp/zig_ir/accepted_20260530_201347_releasesmall
```

Each completed with:

```text
processed=1474 compile_skip=1009 emit_ok=465 local_ok=465
input_too_large=0 parse_fail=0 verify_fail=0 optimizer_fail=0
```

Debug parse/verify/optimize remains a conservative boundary for the distribution
matrix because broad raw Debug rows are still future evidence; reduced Debug
metadata rows and the accepted Debug sweep prove only the documented local
subset.

Handoff is conservative for release modes because
`bash scripts/run_handoff_validation.sh` validates selected scalar, memory,
loop, global, stack, and optimized scalar shapes, but not arbitrary accepted
ReleaseFast, ReleaseSafe, or ReleaseSmall optimized output. The focused
ReleaseFast CFG-sensitive optimized-output baseline is:

```text
tmp/zig_ir/optimized_cfg_releasefast_20260530
  mode=ReleaseFast
  target=x86_64-linux-gnu
  passes=zig-release-fast-accepted
  processed=11 emit_ok=11 local_ok=11
  parse_fail=0 verify_fail=0 optimizer_fail=0 input_too_large=0
  optimized_output=tmp/zig_ir/optimized_cfg_releasefast_20260530/optimized-ir
```

No prior optimized-output artifact directory existed for a historical diff, so
this is a baseline for future canonical-form comparisons rather than evidence
that optimized forms were unchanged across commits.

The first ReleaseFast asm/object fallback reduction tracks the selected empty
optimized module as `test/handoff/inputs/releasefast_empty_module.ll`. The
handoff gate now proves that a metadata-only accepted optimized module emits no
assembly and still produces an x86_64 ELF relocatable object with `.text` and
`.symtab` records.

ReleaseFast asm/object is now a conservative boundary for the selected
Zig-backed optimized-output subset recorded in
`docs/roadmap/releasefast_x86_64_object_milestone_1.md`. The object-ready subset
covers empty modules, `tiny_scalar`, `integers_add_wrap`,
`switch_control_branch_mix`, `control_flow_calls_call_chain`, and
`globals_comptime_const`, `optional_pointer_value`, and
`switch_control_dense_switch`. It explicitly excludes general branch/select
lowering beyond the selected add/sub pattern, variable shift/or chains beyond
the selected shl-by-one plus or-one pattern, integer multiply beyond the
selected multiply-by-five pattern, global data emission, pointer loads and
null-branch control flow beyond the selected nullable i32 load, switch-table
lowering beyond the selected dense constant-return shape, alias/export symbol
emission beyond selected local function aliases, debug/unwind records, linker
behavior, executable validation beyond selected Milestone 1 public aliases, and
target-complete ABI lowering.

Asm/object remains LLVM fallback required for Debug, ReleaseSafe, and
ReleaseSmall, and for ReleaseFast outside the named Milestone 1 subset.
Existing docs explicitly exclude broad register allocation, scheduling,
debug/unwind object records, linker ownership, and target-complete ABI lowering.

## First Fallback Row

The first implementation target should be:

```text
mode=ReleaseFast
target=x86_64-linux-gnu
stage=asm/object
status=LLVM fallback required
```

Reason: ReleaseFast is the primary optimizer replacement row and a common Zig
distribution path. The next bounded slice should not attempt broad backend
parity. It should reduce one concrete accepted ReleaseFast optimized-output
shape that cannot pass the existing x86_64 handoff or asm/object validation
subset, then add the smallest fixture and validation gate for that shape.

Milestone 1 selected that row and closed the first subset boundary. Milestone 2
starts from the first remaining blocker:

```text
broader ReleaseFast object coverage
current blocker=first broad optimized-output object failure is atomics_inline_asm_debug
missing capability=selected debug_location add-immediate lowering
```
