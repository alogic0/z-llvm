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
| Debug | conservative boundary | conservative boundary | conservative boundary | conservative boundary | conservative boundary |
| ReleaseFast | local replacement | local replacement | local replacement | conservative boundary | conservative boundary |
| ReleaseSafe | local replacement | local replacement | local replacement | conservative boundary | conservative boundary |
| ReleaseSmall | local replacement | local replacement | local replacement | conservative boundary | conservative boundary |

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

Debug asm/object is a conservative boundary for the adjusted continuous
captured subset, not target-complete Debug backend ownership. A bounded reduced
object probe is also clean for selected Debug fixtures:

```text
zig build distribution-debug-object
  target=x86_64-unknown-linux-gnu
  inputs=test/zig/expected/debug_*.reduced.ll plus selected Debug/O0
         distribution fixtures
  object_probe=pass
  covered_shapes=call-chain add-immediate, dbg.declare/dbg.value no-op object
                 lowering, simple loop sum, metadata add, scope branch phi,
                 O0 alloca debug prologue plus volatile pointer roundtrip,
                 Debug/O0 c_* panic-call unreachable stubs,
                 Debug/O0 f128 sret C ABI shape,
                 selected Debug/O0 libfuzzer runner aliases
  excluded=DWARF/unwind emission, full O0 codegen, variable-location salvage,
           broad Debug std rows, target-complete ABI lowering
```

The selected broad raw Debug rows also have object evidence:

```text
source=tmp/zig_ir/raw/tiny_scalar.Debug.x86_64.ll
probe=tmp/zig_ir/debug_object_probe_tiny_scalar_20260531/ir
object_probe=1 ok, 0 fail
closed_boundaries=#dbg_* records dropped as non-semantic object records,
                  ret/unreachable metadata accepted, sizeless DIBasicType,
                  columnless DILocation

source=tmp/zig_ir/raw/control_flow_calls.Debug.ll
probe=tmp/zig_ir/debug_object_probe_control_flow_calls_20260531/ir
object_probe=1 ok, 0 fail

source=tmp/zig_ir/raw/pointers_memory.Debug.ll
probe=tmp/zig_ir/debug_object_probe_pointers_memory_20260531/ir
object_probe=1 ok, 0 fail
closed_boundary=selected O0 alloca debug prologue before volatile pointer
                store/load roundtrip

source=tmp/zig_ir/raw/tiny_scalar.Debug.ll
probe=tmp/zig_ir/debug_object_probe_tiny_scalar_plain_20260531/ir
object_probe=1 ok, 0 fail

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv first 100 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_prefix100_20260531/ir
object_probe=100 ok, 0 fail
closed_boundary=Debug/O0 sizeof_and_typeof c_* panic-call unreachable stubs

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv first 200 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_prefix200_20260531/ir
object_probe=200 ok, 0 fail
first_failure=-
first_failure_category=-
closed_blocker=c_abi_main.zig.Debug.x86_64.ll
closed_boundary=selected Debug/O0 C ABI aliases, stack-materialized aggregate
                returns, scalar returns, packed struct/union checks, and
                panic-call stubs; selected Debug/O0 start trampoline trap tail
                and getauxval auxv scan shape; selected object-only Debug/O0
                logical-pointer compile-error and SPIR-V logical-pointer merge
                fixtures; selected Debug/O0 inherit_want_safety counter return;
                selected Debug/O0 unchecked/saturating arithmetic chain return

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv first 300 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_prefix300_20260531/ir
object_probe=300 ok, 0 fail
first_failure=-
first_failure_category=-

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv first 400 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_prefix400_20260531/ir
object_probe=399 ok, 0 fail, 1 excluded
excluded=standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll
excluded_reason=debug-float-format-helper-boundary
first_failure=-
first_failure_category=-
closed_boundary=selected Debug/O0 panic-unreachable compile-asm entry,
                issue-339 error-success edge, libfuzzer runner aliases, and
                dynamic-library checked add; selected Debug/O0 mix-C
                add_zig/add_may_panic checked-add and panic-edge lowering

source=tmp/zig_ir/continuous_20260530_151319_debug/report.tsv all 465 optimizer-ok rows
probe=tmp/zig_ir/debug_object_probe_continuous_full465_20260531/ir
object_probe=465 ok, 0 fail, 0 excluded
excluded=standalone_emit_llvm_no_bin_main.zig.Debug.x86_64.ll
excluded_reason=debug-float-format-helper-boundary
excluded=standalone_mix_o_files_base64.zig.Debug.x86_64.ll
excluded_reason=debug-table-decoder-boundary
first_failure=-
first_failure_category=-
closed_boundary=Debug/O0 base64 table decoder matches the existing
                ReleaseSmall table-decoder boundary for @decode_base_64
closed_blocker=standalone_shared_library_mathtest.zig.Debug.x86_64.ll
               selected @add -> @mathtest.add checked add with panic edge
```

Debug handoff is a conservative boundary for the selected Debug/O0 handoff
fixture in `zig build handoff`:

```text
source=test/distribution/debug_x86_64/inputs/shared_library_mathtest_add_o0.ll
gate=zig build handoff
handoff_case=debug_o0_mathtest_checked_add
checks=emit asm, checked-add branch, panic-call relocation, ELF relocatable
boundary=selected Debug/O0 checked-add handoff only; not broad Debug codegen,
         debug/unwind records, or target-complete ABI lowering
```

Debug object support explicitly excludes DWARF and unwind section ownership:

```text
gate=zig build distribution-debug-unwind
targets=x86_64-unknown-linux-gnu, x86_64-unknown-linux-musl
source_fixture=test/zig/expected/debug_metadata.reduced.ll
result=pass, object has .text but no .debug_* or .eh_frame sections
boundary=selected Debug object lowering only; not DWARF, CFI, unwind tables,
         variable-location salvage, or debugger-quality metadata emission
```

Handoff is conservative for release modes because
`zig build handoff` validates selected scalar, memory,
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

ReleaseFast asm/object is now a conservative boundary for the captured
Zig-backed optimized-output set recorded in
`docs/roadmap/releasefast_x86_64_object_milestone_1.md`. The broad object probe
over `tmp/zig_ir/distribution_m1_releasefast_20260530/optimized-ir` has 17
local object successes and 0 failures, with executable validation for the
selected public aliases. It still explicitly excludes target-complete ABI
lowering, arbitrary Zig source outside the captured set, debug/unwind records,
final-linker work owned by Zig's linker/toolchain, dynamic TLS models,
cross-target TLS relocations, and broad runtime completeness.

The first named no-LLVM-codegen x86_64 distribution subset gate is:

```text
zig build distribution-no-llvm
  target=x86_64-unknown-linux-gnu
  includes=ReleaseFast object/executable gates, ReleaseSafe object/executable gate,
           selected ReleaseSmall object/executable gates, selected Debug
           object/executable gates, handoff validation
  result=pass
```

Link/LTO handoff remains a deferred boundary rather than an implementation row
for the selected x86_64 distribution subset:

```text
source=docs/bitcode/lto_compatibility_decision.md
source=docs/bitcode/construct_inventory.md
source=docs/lto/behavior_gaps.md
validation=zig build test
covered=LTO pre-link pipeline descriptors, text-IR optimizer surface
not_covered=bitcode writer/parser, LTO linker handoff bitcode, ThinLTO
            summaries, combined indexes, import/export, WPD, CFI, post-link LTO
status=deferred until a source-backed activation criterion requires bitcode or
       linker LTO handoff
```

The selected x86_64 musl object subset is a target-boundary proof. It also
inherits the selected ReleaseSafe executable harnesses embedded in the M2 gate,
but does not claim broad executable replacement or local linker ownership for
musl:

```text
gate=zig build distribution-musl-object
target=x86_64-unknown-linux-musl
includes=ReleaseFast object gate, ReleaseSafe object gate,
         ReleaseSmall object gate, selected Debug object gate
result=pass
boundary=no broad musl executable harnesses; final linker/toolchain ownership
         stays with Zig; no local CRT/start-file, libc integration, or dynamic
         loader behavior
```

The selected x86_64 musl executable subset is also target-backed for stable ABI
fixtures:

```text
gate=zig build distribution-musl-executable
target=x86_64-unknown-linux-musl
cc_target=x86_64-linux-musl
includes=ReleaseFast executable gate, selected ReleaseSafe M2
         safety/runtime-call executable harnesses, selected ReleaseSmall M3
         executable harnesses, selected Debug mathtest executable gate
result=pass
boundary=no broad musl executable expansion beyond selected harnesses; Zig's
         linker/toolchain owns final linking, CRT policy, libc integration, and
         dynamic loader behavior beyond the selected harnesses
```

The selected native Zig linker handoff subset is intentionally smaller and
stricter than the `zig cc` executable gates:

```text
gate=zig build distribution-native-link
target=x86_64-unknown-linux-gnu
linker_selection=zig build-exe -fno-lld
includes=ReleaseFast full current executable harness set, 27 fixtures,
         ReleaseSafe checked-add object with panic stub and error-switch object,
         ReleaseSmall i64 constant-return, unchecked-arith, hidden-access,
         mix-C, libfuzzer runner, and reduced base64 table lookup objects,
         selected Debug/O0 mathtest add object with panic stub
result=pass
boundary=native Zig linker proof only for this ABI-stable subset; broad
         executable/linker coverage, CRT policy, libc integration, dynamic
         loading, archives, and shared libraries remain Zig-owned
```

The matching native-linker compatibility probe is source-backed and currently
clean for the same selected subset:

```text
gate=zig build probe-native-linker
target=x86_64-unknown-linux-gnu
linker_selection=zig build-exe -fno-lld
accepted=45
failed=0
per_mode=ReleaseFast 27/27 accepted, ReleaseSafe 9/9 accepted,
         ReleaseSmall 8/8 accepted, Debug 1/1 accepted
failure_categories=symbol, relocation, section, TLS model, COMDAT, alignment,
                   ABI, unknown linker compatibility
next_blocker=none measured; first future failure becomes a local object
             compatibility slice unless evidence proves Zig linker behavior
```

Broad native-link acceptance is tracked as link-only evidence, not executable
ABI proof. It proves selected local objects are structurally acceptable to
Zig's native linker path with safe unresolved function stubs, while keeping
runtime/TLS/linker ownership boundaries visible:

```text
gate=zig build distribution-native-link-boundary2
summary=tmp/zig_ir/native_link_boundary2_releasefast.summary
mode=ReleaseFast
accepted=16 accounted=1 local_fail=0 excluded=0 accounted_total=17
accounted_category=libc/compiler-rt=1
status=strongest current x86_64 native-link conservative boundary; all
       captured ReleaseFast rows are accepted or exactly accounted with no
       local object/link failures

summary=tmp/zig_ir/native_link_boundary2_releasesafe.summary
mode=ReleaseSafe
accepted=8 accounted=9 local_fail=0 excluded=0 accounted_total=17
accounted_category=libc/compiler-rt=1
accounted_category=zig-panic-runtime=8
boundary=debug.FullPanic safety runtime ownership remains Zig-owned

summary=tmp/zig_ir/native_link_boundary2_releasesmall.summary
mode=ReleaseSmall
accepted=273 accounted=192 local_fail=0 excluded=0 accounted_total=465
accounted_category=libc/compiler-rt=1
accounted_category=zig-startup-runtime=190
accounted_category=zig-tls-runtime=1
boundary=start.posixCallMainAndExit startup/runtime and selected TLS ownership
         remain Zig-owned
closed_local_blocker=c_abi_main.zig.ReleaseSmall.x86_64.optimized.ll
                     selected fp128 constants are now defined in local objects
closed_reduced_boundary=base64_table_lookup selected table constant/indexed
                        byte load fixture; full base64 decoder remains excluded

summary=tmp/zig_ir/native_link_boundary2_debug.summary
mode=Debug
accepted=6 accounted=4 local_fail=0 excluded=0 accounted_total=10
accounted_category=zig-panic-runtime=2
accounted_category=zig-test-runtime=1
accounted_category=zig-tls-runtime=1
closed_local_blocker=libfuzzer_runner_o0.ll selected byte-array constants and
                     main.testOne helper now link through Zig native linker
boundary=Debug/O0 panic runtime and TLS ownership remain Zig-owned
```

The named distribution slice is
[x86_64_native_link_distribution_slice.md](x86_64_native_link_distribution_slice.md).
The captured release-mode native-link claim is
[x86_64_captured_release_native_link_claim.md](x86_64_captured_release_native_link_claim.md).
The Zig-source integration slice is
[x86_64_zig_source_native_link_slice.md](x86_64_zig_source_native_link_slice.md).
The Zig integrated object-emission slice is
[x86_64_zig_integrated_object_emit_slice.md](x86_64_zig_integrated_object_emit_slice.md).
Per-mode native-link build aliases exist for ReleaseFast, ReleaseSafe,
ReleaseSmall, and Debug so each promotion can be refreshed independently.

Zig source integration is now a first-class evidence block above fixture-only
object/native-link proof:

```text
gate=zig build distribution-zig-source-native-link
path=Zig source -> stage4 LLVM IR -> z_llvm object -> zig build-exe -fno-lld
total=10 executable_ok=9 link_only_ok=1 local_fail=0
ReleaseFast executable=5 source rows
ReleaseSafe executable=1 source row
ReleaseSafe link_only=1 zig-panic-runtime boundary row
ReleaseSmall executable=3 source rows
fallback=stage4 Zig still emits LLVM IR; no LLVM codegen after IR emission for
         executable rows in this selected slice
```

Zig integrated object emission is the experimental in-Zig hook stage above the
external source capture pipeline. It is tracked in three levels:

```text
gate=zig build distribution-zig-integrated-object
stage=Zig integrated object emit, postopt hook
path=Zig build-obj -> patched Zig optimized IR -> z_llvm object
     -> zig build-exe -fno-lld
status=experimental conservative boundary
claim=LLVM target-machine object emission removed for selected x86_64 source
      rows after Zig constructs LLVM IR
total=10 executable_ok=9 link_only_ok=1 local_fail=0
fixture_pairing=each wrapper row records covered_fixture, mode, and proof
remaining_libllvm_dependency=Zig IR construction still uses libLLVM
excluded=AArch64, wasm, LTO, Debug expansion, broad runtime/TLS/compiler-rt

gate=zig build distribution-zig-integrated-preopt
stage=Zig integrated object emit, preopt hook
path=Zig build-obj -> patched Zig pre-optimization IR
     -> z_llvm --passes=<accepted Zig-mode pipeline>
     -> z_llvm --emit=obj
     -> zig build-exe -fno-lld
status=experimental conservative boundary
claim=LLVM target-machine object emission and LLVM's module optimization
      pipeline are bypassed for selected x86_64 source rows
total=10 executable_ok=9 link_only_ok=1 local_fail=0
ReleaseFast_narrow_gate=zig build distribution-zig-integrated-preopt -- --mode=ReleaseFast
mode_pipelines=ReleaseFast:zig-release-fast-accepted,
               ReleaseSafe:zig-release-safe-accepted,
               ReleaseSmall:zig-release-small-accepted
marker=pipeline, zllvm_passes, target, zig_target, object, ir, case_id,
       wrapper, mode
remaining_libllvm_dependency=Zig still uses libLLVM to parse, hold, and print
                            the module after Zig IR construction
wrapper_scope=compile-time semantic checks plus minimal C ABI main; broader
              callable ABI behavior remains covered by object/native-link
              fixture gates
excluded=AArch64, wasm, LTO, Debug expansion, broad runtime/TLS/compiler-rt

gate=zig build distribution-x86_64-selected-zllvm
detailed_gate=zig build distribution-zig-ir-writer
first_gate=zig build distribution-zig-ir-writer-tiny-scalar
stage=external z_llvm textual IR writer, selected wrapper subset
path=Zig build-obj -> patched Zig Object.emit validates external contract
     -> z_llvm --emit=ir-writer writes textual LLVM IR
     -> z_llvm --passes=<accepted Zig-mode pipeline>
     -> z_llvm --emit=obj
     -> zig build-exe -fno-lld
status=experimental conservative boundary
claim=selected wrapper objects bypass LLVM module optimization, LLVM
      TargetMachine object emission, and libLLVM bitcode parse/print of the
      selected emitted module; z_llvm owns the selected textual IR body, while
      the normal Zig/libLLVM fallback remains available when env vars are unset
ownership=ir-construction=z_llvm-external-textual-subset;
          llvm-module=not-used; llvm-optimizer=not-used;
          llvm-targetmachine=not-used; object-emission=z_llvm;
          linker=zig-native-fno-lld
ownership_gate=selected IR-writer rows fail on libLLVM module parse/print,
               LLVM TargetMachine object emission fallback, or minimal-ret0
compact_output=selected-zllvm status=<ok|fail> total=<rows>
               executable_ok=<count> link_only_ok=<count> minimal-ret0=<count>
               ownership=<marker> first_failure_case_id=<case-or-->
               first_failure_wrapper=<wrapper-or-->
               first_failure_mode=<mode-or-->
               first_failure_pipeline=<pipeline-or-->
               first_failure_error=<error-or-->
diagnostics=docs/x86_64_selected_zllvm_diagnostics.md
total=106 executable_ok=106 link_only_ok=0 local_fail=0
first_gate_result=releasefast_tiny_scalar executable_ok=1 local_fail=0
table_load_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_base64_table_lookup
runtime_condbr_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_cond_branch
runtime_phi_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_phi_merge
runtime_loop_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_loop_sum
releasesafe_loop_sum_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_loop_sum
runtime_switch_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_switch
releasesafe_branch_mix_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_branch_mix
runtime_global_update_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_global_update
runtime_pointer_load_store_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_pointer_load_store
runtime_volatile_roundtrip_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_volatile_roundtrip
runtime_optional_pointer_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_optional_pointer
runtime_packed_read_flag_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_packed_read_flag
runtime_packed_replace_low_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_packed_replace_low
runtime_call_chain_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_call_chain
i64_call_return_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_i64_call
tls_read_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_tls_read
tls_bump_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_tls_bump
atomic_add_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_atomic_add
inline_asm_barrier_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_inline_asm_barrier
aggregate_pair_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_aggregate_pair
float_less_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_less
float_mul_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_mul
float_add_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_add
float_select_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_select
float_sub_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_sub
double_div_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_double_div
float_rem_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_rem
struct_sum_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_struct_sum
releasesafe_struct_sum_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_struct_sum
array_sum_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_array_sum
releasesafe_array_sum_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_array_sum
optional_payload_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_optional_payload
error_union_payload_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_error_union_payload
slice_sum_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_slice_sum
releasesafe_slice_sum_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_slice_sum
fp_constants_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_fp_constants
comptime_const_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_comptime_const
debug_location_gate=zig build distribution-zig-ir-writer -- --case=releasefast_runtime_debug_location
releasesafe_debug_location_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_debug_location
releasesafe_comptime_const_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_comptime_const
releasesafe_global_update_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_global_update
releasesafe_read_global_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_read_global
releasesafe_pointer_load_store_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_pointer_load_store
releasesafe_call_chain_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_call_chain
releasesafe_tls_bump_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_tls_bump
releasesafe_tls_read_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_tls_read
releasesafe_side_effect_free_gate=zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_side_effect_free
releasesmall_hidden_access_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_hidden_access
releasesmall_mix_c_add_zig_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_mix_c_add_zig
releasesmall_mix_c_add_may_panic_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_mix_c_add_may_panic
releasesmall_umul_fix_sat_i64_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_umul_fix_sat_i64
releasesmall_inherit_want_safety_i64_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_inherit_want_safety_i64
releasesmall_compile_asm_unreachable_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_compile_asm_unreachable
releasesmall_str_from_float_help_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_str_from_float_help
releasesmall_base64_decode_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_decode_step
releasesmall_base64_store_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_store_step
releasesmall_base64_residual_byte_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_byte_step
releasesmall_base64_padding_tail_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_padding_tail_step
releasesmall_base64_padding_loop_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_padding_loop_step
releasesmall_base64_padding_length_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_padding_length_step
releasesmall_base64_chunk_guard_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_chunk_guard_step
releasesmall_base64_source_stride_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_source_stride_step
releasesmall_base64_source_bundle_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_source_bundle_step
releasesmall_base64_next_source_bundle_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_next_source_bundle_step
releasesmall_base64_third_source_bundle_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_third_source_bundle_step
releasesmall_base64_bit_buffer_store_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_bit_buffer_store_step
releasesmall_base64_loop_advance_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_loop_advance_step
releasesmall_base64_residual_guard_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_guard_step
releasesmall_base64_residual_bundle_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_bundle_step
releasesmall_base64_residual_store_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_store_step
releasesmall_base64_residual_length_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_length_step
releasesmall_base64_residual_table_check_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_table_check_step
releasesmall_base64_residual_accumulator_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_accumulator_step
releasesmall_base64_residual_loop_advance_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_loop_advance_step
releasesmall_base64_residual_padding_check_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_padding_check_step
releasesmall_base64_residual_final_mask_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_final_mask_step
releasesmall_base64_residual_padding_loop_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_padding_loop_step
releasesmall_base64_decode_exit_step_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_decode_exit_step
next_releasesmall_probe_gate=zig build distribution-releasesmall-object
ir_writer_rows=scalar_runtime_rows=106, minimal_wrapper_rows=0
surface_counts=scalar-add-ret=1, integer-arithmetic=3,
               error-switch-select=2, direct-call=1, global-load=3,
               i64-arithmetic=1, table-indexed-load=1,
               checked-add-runtime-boundary=2, runtime-condbr=2,
               runtime-phi-merge=1, runtime-loop-sum=2,
               checked-loop-sum-boundary=1,
               runtime-switch=2, checked-branch-mix-boundary=2,
               global-update=1,
               pointer-load-store=2, volatile-roundtrip=1,
               optional-pointer=1, packed-read-flag=1,
               packed-replace-low=1, abi-arg-call=2,
               i64-call-return=1, tls-read=2, tls-bump=1,
               atomic-add=1, inline-asm-barrier=1,
               aggregate-pair-abi=1, float-less=2, float-mul=1,
               float-add=2, float-select=1, float-sub=2,
               double-div=1, float-rem=1, void-noop-call=1,
               hidden-global-access=1, mixed-c-zig-add=1,
               mixed-c-zig-panic-add=1,
               umul-fix-sat-i64=1,
               inherit-i64-return=1,
               compile-asm-unreachable=1,
               str-from-float-help=1,
               base64-decode-step=1,
               base64-store-step=1,
               base64-residual-byte-step=1,
               base64-padding-tail-step=1,
               base64-padding-loop-step=1,
               base64-padding-length-step=1,
               base64-chunk-guard-step=1,
               base64-source-stride-step=1,
               base64-source-bundle-step=1,
               base64-next-source-bundle-step=1,
               base64-third-source-bundle-step=1,
               base64-bit-buffer-store-step=1,
               base64-loop-advance-step=1,
               base64-residual-guard-step=1,
               base64-residual-bundle-step=1,
               base64-residual-store-step=1,
               base64-residual-length-step=1,
               base64-residual-table-check-step=1,
               base64-residual-accumulator-step=1,
               base64-residual-loop-advance-step=1,
               base64-residual-padding-check-step=1,
               base64-residual-final-mask-step=1,
               base64-residual-padding-loop-step=1,
               base64-decode-exit-step=1,
               struct-field-sum=2,
               array-scalar-sum=2,
               optional-scalar-payload=1,
               error-union-payload=1,
               slice-loop-sum=2, fp-literal-return=1,
               comptime-const-mul=1,
               add-imm-return=1,
               checked-add-imm-boundary=1,
               checked-comptime-const-boundary=1,
               checked-global-update-boundary=2,
               checked-pointer-load-store-boundary=2,
               checked-call-chain-boundary=1,
               checked-tls-bump-boundary=1,
               checked-array-sum-boundary=2,
               checked-struct-sum-boundary=1,
               checked-slice-loop-sum-boundary=1,
               minimal-ret0=0
marker=pipeline, zllvm_passes, target, zig_target, object, ir, case_id,
       wrapper, mode, ir_writer=external, ir_writer_mode=external
ownership_marker=per-row output includes ownership=ir-construction=z_llvm-external-textual-subset;
                 llvm-module=not-used; llvm-optimizer=not-used;
                 llvm-targetmachine=not-used; object-emission=z_llvm;
                 linker=zig-native-fno-lld
FuncGen_emitted_surface=releasefast_tiny_scalar scalar-add-ret,
                        releasefast_integers integer-arithmetic,
                        releasefast_error_switch error-switch-select,
                        releasefast_control_flow_calls direct-call,
                        releasefast_globals_comptime global-load,
                        releasesafe_runtime_read_global global-load,
                        releasefast_runtime_cond_branch runtime-condbr,
                        releasefast_runtime_phi_merge runtime-phi-merge,
                        releasefast_runtime_loop_sum runtime-loop-sum,
                        releasesafe_runtime_loop_sum
                        checked-loop-sum-boundary,
                        releasefast_runtime_switch runtime-switch,
                        releasesafe_runtime_branch_mix
                        checked-branch-mix-boundary,
                        releasefast_runtime_global_update global-update,
                        releasefast_runtime_pointer_load_store
                        pointer-load-store,
                        releasefast_runtime_volatile_roundtrip
                        volatile-roundtrip,
                        releasefast_runtime_optional_pointer
                        optional-pointer,
                        releasefast_runtime_packed_read_flag
                        packed-read-flag,
                        releasefast_runtime_packed_replace_low
                        packed-replace-low,
                        releasefast_runtime_call_chain abi-arg-call,
                        releasefast_runtime_tls_read tls-read,
                        releasesafe_runtime_tls_read tls-read,
                        releasefast_runtime_tls_bump tls-bump,
                        releasefast_runtime_atomic_add atomic-add,
                        releasefast_runtime_inline_asm_barrier
                        inline-asm-barrier,
                        releasefast_runtime_aggregate_pair
                        aggregate-pair-abi,
                        releasefast_runtime_float_less float-less,
                        releasefast_runtime_float_mul float-mul,
                        releasefast_runtime_float_add float-add,
                        releasefast_runtime_float_select float-select,
                        releasefast_runtime_float_sub float-sub,
                        releasefast_runtime_double_div double-div,
                        releasefast_runtime_float_rem float-rem,
                        releasefast_runtime_struct_sum struct-field-sum,
                        releasefast_runtime_array_sum array-scalar-sum,
                        releasefast_runtime_optional_payload
                        optional-scalar-payload,
                        releasefast_runtime_error_union_payload
                        error-union-payload,
                        releasefast_runtime_slice_sum slice-loop-sum,
                        releasefast_runtime_fp_constants
                        fp-literal-return,
                        releasefast_runtime_comptime_const
                        comptime-const-mul,
                        releasefast_runtime_debug_location
                        add-imm-return,
                        releasesafe_runtime_debug_location
                        checked-add-imm-boundary,
                        releasesafe_runtime_comptime_const
                        checked-comptime-const-boundary,
                        releasesafe_runtime_global_update
                        checked-global-update-boundary,
                        releasesafe_runtime_pointer_load_store
                        checked-pointer-load-store-boundary,
                        releasesafe_runtime_call_chain
                        checked-call-chain-boundary,
                        releasesafe_runtime_tls_bump
                        checked-tls-bump-boundary,
                        releasesafe_runtime_array_sum
                        checked-array-sum-boundary,
                        releasesafe_runtime_struct_sum
                        checked-struct-sum-boundary,
                        releasesafe_runtime_slice_sum
                        checked-slice-loop-sum-boundary,
                        releasesafe_error_switch error-switch-select,
                        releasesafe_tiny_scalar_runtime_boundary
                        checked-add-runtime-boundary,
                        releasesafe_runtime_side_effect_free
                        void-noop-call,
                        releasesmall_runtime_hidden_access
                        hidden-global-access,
                        releasesmall_runtime_mix_c_add_zig
                        mixed-c-zig-add,
                        releasesmall_runtime_mix_c_add_may_panic
                        mixed-c-zig-panic-add,
                        releasesmall_runtime_umul_fix_sat_i64
                        umul-fix-sat-i64,
                        releasesmall_runtime_inherit_want_safety_i64
                        inherit-i64-return,
                        releasesmall_runtime_compile_asm_unreachable
                        compile-asm-unreachable,
                        releasesmall_runtime_str_from_float_help
                        str-from-float-help,
                        releasesmall_runtime_base64_decode_step
                        base64-decode-step,
                        releasesmall_runtime_base64_store_step
                        base64-store-step,
                        releasesmall_runtime_base64_residual_byte_step
                        base64-residual-byte-step,
                        releasesmall_runtime_base64_padding_tail_step
                        base64-padding-tail-step,
                        releasesmall_runtime_base64_padding_loop_step
                        base64-padding-loop-step,
                        releasesmall_runtime_base64_padding_length_step
                        base64-padding-length-step,
                        releasesmall_runtime_base64_chunk_guard_step
                        base64-chunk-guard-step,
                        releasesmall_runtime_base64_source_stride_step
                        base64-source-stride-step,
                        releasesmall_runtime_base64_source_bundle_step
                        base64-source-bundle-step,
                        releasesmall_runtime_base64_next_source_bundle_step
                        base64-next-source-bundle-step,
                        releasesmall_runtime_base64_third_source_bundle_step
                        base64-third-source-bundle-step,
                        releasesmall_runtime_base64_bit_buffer_store_step
                        base64-bit-buffer-store-step,
                        releasesmall_runtime_base64_loop_advance_step
                        base64-loop-advance-step,
                        releasesmall_runtime_base64_residual_guard_step
                        base64-residual-guard-step,
                        releasesmall_runtime_base64_residual_bundle_step
                        base64-residual-bundle-step,
                        releasesmall_runtime_base64_residual_store_step
                        base64-residual-store-step,
                        releasesmall_runtime_base64_residual_length_step
                        base64-residual-length-step,
                        releasesmall_runtime_base64_residual_table_check_step
                        base64-residual-table-check-step,
                        releasesmall_runtime_base64_residual_accumulator_step
                        base64-residual-accumulator-step,
                        releasesmall_runtime_base64_residual_loop_advance_step
                        base64-residual-loop-advance-step,
                        releasesmall_runtime_base64_residual_padding_check_step
                        base64-residual-padding-check-step,
                        releasesmall_runtime_base64_residual_final_mask_step
                        base64-residual-final-mask-step,
                        releasesmall_runtime_base64_residual_padding_loop_step
                        base64-residual-padding-loop-step,
                        releasesmall_runtime_base64_decode_exit_step
                        base64-decode-exit-step,
                        releasesmall_globals_comptime global-load,
                        releasesmall_i64_arithmetic i64-arithmetic,
                        releasesmall_runtime_i64_call i64-call-return,
                        releasesmall_base64_table_lookup table-indexed-load;
                        no selected rows use minimal-ret0
source_fixture_pairing=each row still records covered_fixture and mode; source
                       behavior is enforced by comptime checks or existing
                       object/native-link fixture gates
remaining_dependency=general Zig LLVM Builder state remains; full FuncGen and
                     broad Zig IR construction are not replaced
excluded=runtime arithmetic beyond selected rows, stores beyond the selected
         mutable global update, ABI calls beyond the selected i32 argument
         direct call and selected i64 call return, TLS beyond selected
         local-exec read/update, atomics beyond selected monotonic add,
         inline asm beyond the selected memory barrier, aggregate ABI beyond
         the selected two-i32 pair, vectors, debug/unwind, AArch64, wasm, LTO,
         broad runtime/TLS/compiler-rt
```

The linker/CRT boundary is now explicit and validated as an ownership boundary,
not a future `z_llvm` linker plan. `z_llvm` emits LLVM-compatible IR, assembly,
and selected relocatable objects; final executable, shared-library, archive,
linker-script, CRT, libc, and dynamic-loader behavior stays in Zig's
linker/toolchain.

```text
gate=zig build distribution-linker-boundary
local_emit_modes=ir, asm, obj
rejected_emit_mode=exe
executable_validation_handoff=zig cc -target "$cc_target"
native_linker_proof=zig build distribution-native-link
result=pass
boundary=no z_llvm executable emission, CRT/start-file policy, libc integration,
         dynamic loader behavior, archive ownership, or linker script handling;
         broad executable gates hand local objects to Zig's driver/toolchain;
         only the `zig build-exe -fno-lld` gate is native-linker evidence
```

AArch64 object emission is an explicit target boundary for the current
distribution matrix:

```text
gate=zig build distribution-aarch64-boundary
target=aarch64-unknown-linux-gnu
source_fixture=test/distribution/releasefast_x86_64/inputs/tiny_scalar.ll
result=pass, rejected with unsupported codegen target
boundary=local object emission is x86_64-linux only; AArch64 parse/verify/
         optimize evidence does not imply backend, ABI, relocation, or object
         ownership
```

The current conservative boundary gates are composed by:

```text
gate=zig build distribution-boundary
includes=linker/CRT boundary, tracked ReleaseSmall exclusion boundaries,
         Debug DWARF/unwind boundary, AArch64 object target boundary
result=pass
```

The combined selected distribution validation entrypoint is:

```text
gate=zig build distribution-all
includes=selected no-LLVM-codegen object/executable subset,
         conservative boundary gates
result=pass
```

Automated broad object probing is now available through:

```text
zig build probe-distribution-objects --
  implementation=tools/probe_distribution_objects.zig
  ReleaseFast:  total=17  ok=17  fail=0 excluded=0 first_failure=-
  ReleaseSafe:  total=17  ok=17  fail=0 excluded=0 first_failure=-
  ReleaseSmall: total=465 ok=465 fail=0 excluded=0 first_failure=-
  ReleaseSmall former exclusions:
    standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll
      tracked_fixture=test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll
      result=local object evidence through whole-function:str-from-float-help
    standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll
      tracked_fixture=test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll
      result=local object evidence plus executable whole-function:base64-decode-base-64
```

The compact object-stage dashboard is
`docs/roadmap/x86_64_distribution_object_dashboard.md`.

Asm/object remains LLVM fallback required for broad Debug, and for ReleaseFast,
ReleaseSafe, and ReleaseSmall outside their named captured subsets. Existing
docs explicitly exclude broad register allocation, scheduling, debug/unwind
object records, final-linker work owned by Zig's linker/toolchain, and
target-complete ABI lowering.

## First Fallback Row

The first implementation target should be:

```text
mode=ReleaseFast
target=x86_64-linux-gnu
stage=asm/object
status=conservative boundary
```

Reason: ReleaseFast is the primary optimizer replacement row and a common Zig
distribution path. The next bounded slice should not attempt broad backend
parity. It should reduce one concrete accepted ReleaseFast optimized-output
shape that cannot pass the existing x86_64 handoff or asm/object validation
subset, then add the smallest fixture and validation gate for that shape.

Milestone 1 selected that row and closed the first subset boundary. Milestone 2
closed the broad captured ReleaseFast object set. The next measured row starts
ReleaseSafe object replacement:

```text
mode=ReleaseSafe
target=x86_64-linux-gnu
stage=asm/object
status=LLVM fallback required
optimized_output=tmp/zig_ir/distribution_m2_releasesafe_20260530/optimized-ir
object_probe=17 ok, 0 fail with --input-limit=67108864
closed_blocker=aggregates.zig.ReleaseSafe.x86_64.optimized.ll selected checked aggregate sums
closed_blocker=atomics_inline_asm_debug.zig.ReleaseSafe.x86_64.optimized.ll selected checked debug_location
closed_blocker=control_flow_calls.zig.ReleaseSafe.x86_64.optimized.ll selected checked loop_sum/call_chain
closed_blocker=error_switch.zig.ReleaseSafe.x86_64.optimized.ll selected straight-line error_switch
closed_blocker=globals_comptime.zig.ReleaseSafe.x86_64.optimized.ll selected checked comptime_const/update_global/read_global
closed_blocker=pointers_memory.zig.ReleaseSafe.x86_64.optimized.ll selected checked load_store
closed_blocker=switch_control.zig.ReleaseSafe.x86_64.optimized.ll selected checked branch_mix plus dense_switch
closed_blocker=tiny_scalar.zig.ReleaseSafe.x86_64.optimized.ll selected checked add plus sideEffectFree
closed_blocker=tls_concurrency.zig.ReleaseSafe.x86_64.optimized.ll selected checked bump_tls plus read_tls
promoted_status=conservative boundary for captured ReleaseSafe optimized-output object subset
```

The next measured row starts ReleaseSmall object replacement:

```text
mode=ReleaseSmall
target=x86_64-linux-gnu
stage=asm/object
status=LLVM fallback required
optimized_output=tmp/zig_ir/distribution_m3_releasesmall_20260531/optimized-ir
optimizer_capture=465 ok, 0 fail, 1009 compile_skip
previous_object_probe=264 ok, 201 fail with --input-limit=67108864
closed_blocker=behavior_export_keyword.zig.ReleaseSmall.x86_64.optimized.ll selected writeToVRam/testPackedStuff
intermediate_object_probe=265 ok, 200 fail with --input-limit=67108864
closed_blocker=behavior_sizeof_and_typeof.zig.ReleaseSmall.x86_64.optimized.ll selected c_fopen/c_ftell/c_fputs/c_printf
closed_blocker=c_abi_main.zig.ReleaseSmall.x86_64.optimized.ll selected public aliases through @zig_panic
intermediate_object_probe=266 ok, 199 fail with --input-limit=67108864
closed_blocker=cases_address_space_pointer_access_chaining_pointer_to_optional_array.zig.ReleaseSmall.x86_64.optimized.ll selected @_start -> @start._start startup trampoline
intermediate_object_probe=327 ok, 138 fail with --input-limit=67108864
closed_blocker=cases_array_in_anon_struct.zig.ReleaseSmall.x86_64.optimized.ll selected @getauxval -> @os.linux.getauxvalImpl auxv scan
intermediate_object_probe=455 ok, 10 fail with --input-limit=67108864
closed_blocker=cases_compile_errors_illegal_operation_on_logical_ptr.zig.ReleaseSmall.x86_64.optimized.ll selected @elemPtr -> @illegal_operation_on_logical_ptr.elemPtr
intermediate_object_probe=456 ok, 9 fail with --input-limit=67108864
closed_blocker=cases_inherit_want_safety.zig.ReleaseSmall.x86_64.optimized.ll selected @entry -> @inherit_want_safety.entry i64 constant return
intermediate_object_probe=457 ok, 8 fail with --input-limit=67108864
closed_blocker=cases_no_compile_panic_for_unchecked_arith.zig.ReleaseSmall.x86_64.optimized.ll selected @entry -> @no_compile_panic_for_unchecked_arith.entry llvm.umul.fix.sat.i64 constant-call return
intermediate_object_probe=458 ok, 7 fail with --input-limit=67108864
closed_blocker=standalone_compile_asm_main.zig.ReleaseSmall.x86_64.optimized.ll selected @main -> @main.main empty noreturn unreachable stub
closed_blocker=standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll @strFromFloatHelp -> @main.strFromFloatHelp multi-block float-format helper
boundary_probe=zig build distribution-releasesmall-boundary local-object
tracked_boundary_fixture=test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll
whole_function_boundary_status=closed; executable @main calls @main.strFromFloatHelp, and the helper covers stack slots, lifetime markers, double bitcast/exponent classification, pow5/inv-pow5 table loads, decimal loop CFG, i128 arithmetic/truncation, llvm.assume, llvm.memcpy/llvm.memset, fastcc pointer helper calls, and writer-vtable indirect-call boundary; proof label is whole-function:str-from-float-help
whole_function_boundary_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_str_from_float_help
closed_blocker=standalone_extern_exports.zig.ReleaseSmall.x86_64.optimized.ll selected @getHidden/@updateHidden hidden i32 global access
intermediate_adjusted_object_probe=460 ok, 4 fail, 1 excluded with --input-limit=67108864
closed_blocker=standalone_install_raw_hex_main.zig.ReleaseSmall.x86_64.optimized.ll selected @_start -> @main._start two-block infinite loop
intermediate_adjusted_object_probe=461 ok, 3 fail, 1 excluded with --input-limit=67108864
closed_blocker=standalone_libfuzzer_main.zig.ReleaseSmall.x86_64.optimized.ll selected libfuzzer runner aliases
closed_alias_in_blocker=@runner_futex_wait -> @main.runner_futex_wait i1 constant return
closed_alias_in_blocker=@runner_test_name -> @main.runner_test_name string-slice aggregate return
closed_alias_in_blocker=@runner_test_run -> @main.runner_test_run selected runtime-call lowering
intermediate_adjusted_object_probe=462 ok, 2 fail, 1 excluded with --input-limit=67108864
closed_blocker=standalone_mix_c_files_main.zig.ReleaseSmall.x86_64.optimized.ll selected mix-C aliases
closed_alias_in_blocker=@add_zig -> @main.add_zig mixed Zig/C global-add i32 return
closed_alias_in_blocker=@add_may_panic -> @main.add_may_panic checked add/panic branch
intermediate_adjusted_object_probe=463 ok, 1 fail, 1 excluded with --input-limit=67108864
closed_blocker=standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll @decode_base_64 -> @base64.decode_base_64 table-driven multi-block decoder
boundary_probe=zig build distribution-releasesmall-boundary local-object
tracked_boundary_fixture=test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll
focused_boundary_gate=zig build distribution-releasesmall-boundary
whole_function_boundary_inventory=@decode_base_64 -> @base64.decode_base_64 full textual IR body registered as releasesmall_runtime_base64_decode_base_64_full
whole_function_boundary_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_decode_base_64_full
whole_function_boundary_status=closed; external IR-writer @main validates TWFu -> Man, TWE= -> Ma, TQ== -> M, and invalid !!!! -> -1 through real x86_64 table-driven @base64.decode_base_64 lowering; proof label is whole-function:base64-decode-base-64
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected four-entry decode table load/OR/validity step
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_decode_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected output pointer store step
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_store_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual byte mask/shift/trunc/store step
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_byte_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected padding-tail byte load/equals check
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_padding_tail_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected padding-tail phi/add/backedge loop walk
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_padding_loop_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected trailing padding output-length adjustment
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_padding_length_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected wide-chunk loop guard
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_chunk_guard_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected source-byte stride/table load
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_source_stride_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected four-byte source bundle/table OR validity check
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_source_bundle_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected next four-byte source bundle/table OR validity check
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_next_source_bundle_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected third four-byte source bundle/table OR validity check
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_third_source_bundle_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected i128 bit-buffer combine/store
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_bit_buffer_store_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected loop index advance/backedge
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_loop_advance_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual/preheader guard
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_guard_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual four-byte source/table bundle
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_bundle_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual output store/backedge
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_store_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual remaining-length calculation
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_length_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual byte/table validity check
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_table_check_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual accumulator update
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_accumulator_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual loop-index advance
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_loop_advance_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual padding byte/offset check
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_padding_check_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual final mask guard
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_final_mask_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected residual final padding loop
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_padding_loop_step
reduced_closed_shape=@decode_base_64 -> @base64.decode_base_64 selected decoder exit/lifetime cleanup
reduced_closed_gate=zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_decode_exit_step
reduced_closed_fixture=test/distribution/releasesmall_x86_64/inputs/base64_table_lookup.ll
reduced_closed_shape=@base64_table_lookup -> @base64.table_lookup four-byte table constant plus indexed i8 load
reduced_gates=zig build distribution-releasesmall-object, zig build distribution-native-link-releasesmall
current_adjusted_object_probe=465 ok, 0 fail, 0 excluded with --input-limit=67108864
ReleaseSmall asm/object status=conservative boundary for named captured subset with no explicit exclusions
```
