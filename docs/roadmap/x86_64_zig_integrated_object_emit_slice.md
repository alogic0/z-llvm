# x86_64 Zig Integrated Object Emit Slice

This slice moves the selected source-backed proof from an external capture
pipeline into Zig's LLVM backend object-emission boundary. It now has three
hook levels:

```text
postopt:
  Zig build-obj
    -> Zig constructs LLVM IR with libLLVM
    -> LLVM runs Zig's normal module optimization pipeline
    -> patched Zig writes optimized LLVM IR at the object emission boundary
    -> z_llvm emits x86_64 relocatable .o
    -> Zig native linker links C ABI main wrappers with
       zig build-exe -fno-lld -fno-compiler-rt -lc

preopt:
  Zig build-obj
    -> Zig constructs LLVM IR with libLLVM
    -> patched Zig writes pre-optimization LLVM IR before module_pm.run(...)
    -> z_llvm runs the accepted Zig-mode pipeline
    -> z_llvm emits x86_64 relocatable .o
    -> Zig native linker links C ABI main wrappers with
       zig build-exe -fno-lld -fno-compiler-rt -lc

ir-writer:
  Zig build-obj
    -> Zig frontend validates the selected wrapper and comptime fixture checks
    -> patched Zig Object.emit validates the external IR writer contract
    -> z_llvm --emit=ir-writer writes the selected LLVM IR module through
       the structured builder or the textual subset
    -> z_llvm runs the accepted Zig-mode pipeline
    -> z_llvm emits x86_64 relocatable .o
    -> Zig native linker links C ABI main wrappers with
       zig build-exe -fno-lld -fno-compiler-rt -lc

source-owned ir-writer:
  Zig build-obj
    -> patched Zig passes wrapper/mode/target/output/marker metadata
    -> the runner supplies source fixture and source-backed tag metadata
    -> z_llvm resolves the row from source metadata, not ZLLVM_CASE_ID
    -> z_llvm lowers through src/zig_semantic_lowering.zig into structured IR
    -> z_llvm emits x86_64 relocatable .o through generic lowering
    -> Zig native linker links the executable
```

The preopt hook bypasses LLVM's module optimization pipeline for selected rows,
including the registered pipeline-start additions in `zig_llvm.cpp`, and
replaces it with the selected local accepted pipeline:

```text
ReleaseFast  -> zig-release-fast-accepted
ReleaseSafe  -> zig-release-safe-accepted
ReleaseSmall -> zig-release-small-accepted
```

Validation gates:

```text
zig build distribution-zig-integrated-object   # postopt
zig build distribution-zig-integrated-preopt   # preopt
zig build distribution-zig-integrated-preopt -- --mode=ReleaseFast
zig build distribution-zig-ir-writer-tiny-scalar
zig build distribution-zig-ir-writer
zig build distribution-x86_64-release-source-owned
```

## Zig Object-Emission Boundary

Current Zig call path in `../ziglang` with line anchors from the local patched
checkout:

```text
src/codegen/llvm.zig:771 Object.emit
  first checks the experimental external IR writer hook at
  src/codegen/llvm.zig:777 and returns early when it emits a selected object.

src/codegen/llvm.zig:1137 emitZllvmIrWriterObject
  validates ZIG_USE_ZLLVM_IR_WRITER=1, ZLLVM_IR_WRITER_MODE=external, case,
  mode, wrapper, ZLLVM_IR_PATH, x86_64 Linux target, and object-only emission.

src/codegen/llvm.zig:1233 runZllvmIrWriterEmitIr
  calls z_llvm --emit=ir-writer. z_llvm, not patched Zig, owns the case model
  and emitted textual IR body.

src/codegen/llvm.zig:1246 runZllvmIrWriterCommand
  runs z_llvm --passes=<accepted Zig-mode pipeline> and z_llvm --emit=obj.

src/codegen/llvm.zig:780 normal libLLVM path
  finalizes the LLVM builder module, serializes Zig's LLVM bitcode, and parses
  that bitcode back into a libLLVM Module.

src/codegen/llvm.zig:1105 and :1121
  calls bindings.TargetMachine.emitToFile with lowered EmitOptions.

src/codegen/llvm/bindings.zig:136 TargetMachine.emitToFile
  extern binding to ZigLLVMTargetMachineEmitToFile

src/zig_llvm.cpp:476 ZigLLVMTargetMachineEmitToFile
  builds the LLVM optimization pipeline
  creates legacy codegen_pm
  calls TargetMachine::addPassesToEmitFile(..., CodeGenFileType::ObjectFile)
  postopt hook: module_pm.run(...) at src/zig_llvm.cpp:686, then print IR
  preopt hook: print IR at src/zig_llvm.cpp:681 before module_pm.run(...)
  normal LLVM path: module_pm.run(...) at src/zig_llvm.cpp:698, then
                    codegen_pm.run(...)
```

That `TargetMachine::addPassesToEmitFile(... ObjectFile)` call is the current
LLVM target-machine object-emission boundary. The experimental hook is placed
there so Zig's IR construction remains unchanged. In preopt mode, LLVM still
parses, owns, and prints the module after Zig IR construction; LLVM's module
optimization pipeline and TargetMachine object codegen are bypassed for the
selected rows.

## Hook Contract

Opt-in environment:

```text
ZIG_USE_ZLLVM_OBJECT=1
ZIG_USE_ZLLVM_IR_WRITER=1
ZLLVM_EXE=/path/to/zig-out/bin/z_llvm
ZLLVM_PIPELINE=postopt|preopt
ZLLVM_ZIG_MODE=ReleaseFast|ReleaseSafe|ReleaseSmall
ZLLVM_CASE_ID=<case>
ZLLVM_WRAPPER=<wrapper source>
ZLLVM_IR_WRITER_MODE=external
ZLLVM_IR_PATH=<path>
```

Contract:

```text
postopt_input=optimized LLVM IR text file written by patched Zig
preopt_input=pre-optimization LLVM IR text file written by patched Zig
ir_writer_input=selected LLVM IR module written by z_llvm --emit=ir-writer
                into ZLLVM_IR_PATH through the structured builder or textual
                subset
output=x86_64 Linux relocatable object
object_target=x86_64-unknown-linux-gnu
link_target=x86_64-linux-gnu
modes=ReleaseFast, ReleaseSafe, ReleaseSmall
linker=Zig native linker selected with -fno-lld
wrapper_abi=C ABI main linked with -fno-compiler-rt -lc to keep Zig startup
            runtime and compiler_rt sub-compilations out of this slice
unsupported=LTO, non-x86_64 Linux targets, simultaneous asm+object emission
```

If `ZIG_USE_ZLLVM_OBJECT` is unset, Zig uses its existing LLVM target-machine
object path. If `ZLLVM_PIPELINE` is unset, the hook defaults to `postopt` to
preserve the previous experimental behavior. If `z_llvm` fails, the diagnostic
reports the source wrapper metadata, mode, IR path, object path, target,
command, exit status, and failure category.

If `ZIG_USE_ZLLVM_IR_WRITER=1` is set, the hook is intentionally stricter: it
requires `ZLLVM_PIPELINE=preopt`, `ZLLVM_IR_WRITER_MODE=external`, a supported
mode, case ID, wrapper path, `ZLLVM_IR_PATH`, x86_64 Linux object emission, and
`ZLLVM_EXE`. If any of those are missing or unsupported, patched Zig fails
clearly. With the env var unset, the libLLVM fallback path is untouched. Case
expansion belongs in z_llvm's `--emit=ir-writer` implementation, not in patched
Zig.

The source-owned release gate keeps the patched Zig hook stable by passing the
sentinel `ZLLVM_CASE_ID=source-wrapper-dispatch` plus
`ZLLVM_IR_WRITER_DISPATCH=source-owned`, `ZLLVM_SOURCE_FIXTURE`, and
`ZLLVM_SOURCE_TAG`. z_llvm uses the wrapper/mode/fixture/tag tuple to resolve
an AIR-shaped DescriptorV2 program and then the structured module. The gate
requires all 90 current x86_64 release source-backed rows to report
`lowering=semantic-descriptor-v2`, `zllvm_semantic_descriptor_version = "v2"`,
`zllvm_surface_dispatch = "not-used"`, `llvm_text_parse=not-used`,
`codegen=generic-x86_64-lowering`, no fallback, and no case-id ownership.

Marker fields:

```text
pipeline=preopt|postopt
zllvm_passes=<pipeline-or-empty>
target=x86_64-unknown-linux-gnu
zig_target=<raw Zig LLVM triple>
object=<path>
ir=<path>
case_id=<case>
wrapper=<path>
mode=<mode>
ir_writer=external         # only for ZIG_USE_ZLLVM_IR_WRITER=1
ir_writer_mode=external
```

## FuncGen Inventory

The current 10 wrappers deliberately enforce source behavior with `comptime`
checks and, for the normal postopt/preopt hook path, expose a minimal runtime
C ABI `main` returning zero. The external writer path replaces the emitted
wrapper IR with z_llvm-owned runtime surfaces for all 10 selected rows. That
makes the object-emitted `FuncGen.zig` surface for these rows much smaller than
the source fixtures they cover:

```text
covered by promoted runtime-emitted writer rows:
  ../ziglang/src/codegen/llvm/FuncGen.zig:570  airCall
  ../ziglang/src/codegen/llvm/FuncGen.zig:446 dispatches .ret AIR
  ../ziglang/src/codegen/llvm/FuncGen.zig:934 airRet
  ../ziglang/src/codegen/llvm/FuncGen.zig:1027 emits wip.ret(operand)
  ../ziglang/src/codegen/llvm/FuncGen.zig:3344 airAdd
  ../ziglang/src/codegen/llvm/FuncGen.zig:4760 airLoad
  ../ziglang/src/codegen/llvm/FuncGen.zig:5499 airSelect
  ../ziglang/src/codegen/llvm/FuncGen.zig:1533 airCondBr

source-backed fixture constructs checked at comptime or in separate
object/native-link fixture gates, not yet emitted by the external IR writer:
  ../ziglang/src/codegen/llvm/FuncGen.zig:4702 airStore
```

External IR writer emission surface for this slice:

```text
runtime-emitted rows:
  module header: source_filename, x86_64 Linux target triple,
                 zllvm_ir_writer_contract=external,
                 zllvm_ir_writer_surface=<surface>

  releasefast_tiny_scalar: scalar-add-ret
    dso_local i32 @main computes add i32 40, 2 and exits 42

  releasefast_integers: integer-arithmetic
    dso_local i32 @main checks wrapping add, compare/select, and shift/xor mix
    against constants and exits 0 only if all checks pass

  releasefast_error_switch: error-switch-select
    dso_local i32 @main emits icmp/select error-switch-style results plus a
    constant conditional branch; local x86_64 lowering now accepts the reduced
    constant-condbr object shape

  releasefast_control_flow_calls: direct-call
    internal no-arg callee returns 41; dso_local i32 @main calls it, adds one,
    and exits 42

  releasefast_globals_comptime: global-load
    private i32 global is loaded by globals_comptime.read_global; main calls
    that function and exits 5

  releasefast_runtime_cond_branch: runtime-condbr
    dso_local i32 @main branches on a runtime i1 ABI argument and returns from
    separate then/else blocks; the focused executable gate covers a real
    parameter-driven conditional branch without phi merging

  releasefast_runtime_phi_merge: runtime-phi-merge
    dso_local i32 @main emits a two-way branch, reconverges through an i32 phi,
    and returns the merged value; the ReleaseFast accepted pipeline canonicalizes
    the selected phi to a runtime select before local x86_64 object emission

  releasefast_runtime_loop_sum: runtime-loop-sum
    private control_flow_calls.loop_sum emits an actual counted i32
    accumulation loop and is exposed to the C entry point through a main alias;
    the focused executable gate validates the loop through the existing
    selected loop-sum object path

  releasefast_runtime_switch: runtime-switch
    private switch_control.dense_switch emits the source-backed dense switch
    table, range fallback, and phi merge shape, then exposes it to the C entry
    point through a main alias; the focused executable gate validates the
    selected switch/table path and exits 13 for argc=1

  releasefast_runtime_global_update: global-update
    private globals_comptime.update_global loads a mutable i32 global, adds the
    runtime i32 ABI argument, stores the updated value back, and returns it
    through a main alias; the focused executable gate validates argc=1 updates
    the initial value 3 to exit code 4

  releasefast_runtime_call_chain: abi-arg-call
    dso_local control_flow_calls.callee receives an i32 ABI argument, the
    private control_flow_calls.call_chain calls it directly, adds one to the
    i32 return value, and is exposed through a main alias; the focused
    executable gate validates argc=1 exits 3

  releasesmall_runtime_i64_call: i64-call-return
    dso_local i64_arithmetic.i64_value returns an i64 constant, main calls it,
    compares the i64 return value, and exits 0 only if the selected non-i32
    call-return path succeeds under the ReleaseSmall accepted pipeline

  releasefast_runtime_tls_read: tls-read
    internal thread_local(localexec) i32 tls_concurrency.tls_counter is loaded
    by tls_concurrency.read_tls and exposed through a main alias; the focused
    executable gate validates the selected x86_64 local-exec TLS read path and
    exits 1

  releasefast_runtime_tls_bump: tls-bump
    internal thread_local(localexec) i32 tls_concurrency.tls_counter is loaded,
    incremented by the runtime i32 ABI argument, stored back, and exposed
    through a main alias; the focused executable gate validates argc=1 updates
    the initial TLS value 1 to exit code 2

  releasefast_runtime_atomic_add: atomic-add
    private i32 atomics_inline_asm_debug.atomic_counter is updated by a
    monotonic atomicrmw add, exposed through a main alias, and validated through
    the selected x86_64 lock xadd object path

  releasesmall_i64_arithmetic: i64-arithmetic
    dso_local i32 @main computes an i64 add, checks the i64 result, and exits 0

  releasesafe_error_switch: error-switch-select
    same compare/select error-switch-style surface under the ReleaseSafe
    accepted pipeline, exiting 0 only if the checks pass

  releasesafe_tiny_scalar_runtime_boundary: checked-add-runtime-boundary
    dso_local i32 @main emits llvm.sadd.with.overflow.i32, branches to a
    panic-runtime declaration on overflow, validates that edge as a boundary,
    and executes the selected constant non-overflow object path

  releasesmall_globals_comptime: global-load
    same private global load surface under the ReleaseSmall accepted pipeline,
    exiting 5

  releasesmall_base64_table_lookup: table-indexed-load
    private [4 x i8] table, trunc/zext index, getelementptr, i8 load, zext to
    i32, and a runtime check before returning 0

attributes: none
```

This is intentionally not a generic replacement for `FuncGen.zig`. The next
expansion should promote one concrete runtime-emitted construct from the
unsupported list into z_llvm's external textual writer, then add a focused
wrapper that requires it. The full writer gate now fails on unexpected
`minimal-ret0` for selected rows.

## Fixture Pairing

Every integrated wrapper is paired with an existing source-backed fixture. The
gate prints the pairing for each row and fails if a case lacks a wrapper,
covered fixture, mode, or proof string.

```text
wrapper=test/zig/integrated/tiny_scalar_main.zig
covered_fixture=test/zig/inputs/tiny_scalar.zig
mode=ReleaseFast
proof=integrated Zig build-obj object path plus Zig build-exe native link
```

The wrappers use compile-time semantic checks against the paired source shape
and expose a minimal C ABI `main` returning zero in the normal postopt/preopt
hook path. The external IR writer path substitutes z_llvm-owned runtime IR for
the selected rows. That keeps the preopt gate focused on the integrated hook,
local accepted optimizer pipeline, object emission, and native-link handoff,
while the writer gate proves selected runtime surfaces. Broader callable ABI
behavior remains covered by the object/native-link fixture gates.

Selected rows:

```text
ReleaseFast executable:
  wrapper=test/zig/integrated/tiny_scalar_main.zig
  covered_fixture=test/zig/inputs/tiny_scalar.zig

  wrapper=test/zig/integrated/integers_main.zig
  covered_fixture=test/zig/inputs/integers.zig

  wrapper=test/zig/integrated/control_flow_calls_main.zig
  covered_fixture=test/zig/inputs/control_flow_calls.zig

  wrapper=test/zig/integrated/globals_comptime_main.zig
  covered_fixture=test/zig/inputs/globals_comptime.zig
  note=integrated wrapper covers the comptime constant path; mutable global
       load/store remains covered by object/native-link fixture gates

  wrapper=test/zig/integrated/error_switch_main.zig
  covered_fixture=test/zig/inputs/error_switch.zig

  wrapper=test/zig/integrated/runtime_cond_branch_main.zig
  covered_fixture=test/zig/inputs/switch_control.zig

  wrapper=test/zig/integrated/runtime_phi_merge_main.zig
  covered_fixture=test/zig/inputs/switch_control.zig

  wrapper=test/zig/integrated/runtime_loop_sum_main.zig
  covered_fixture=test/zig/inputs/control_flow_calls.zig

  wrapper=test/zig/integrated/runtime_switch_main.zig
  covered_fixture=test/zig/inputs/switch_control.zig

  wrapper=test/zig/integrated/runtime_global_update_main.zig
  covered_fixture=test/zig/inputs/globals_comptime.zig

  wrapper=test/zig/integrated/control_flow_calls_main.zig
  covered_fixture=test/zig/inputs/control_flow_calls.zig
  note=releasefast_runtime_call_chain covers the ABI-argument direct-call
       surface for the same source fixture

  wrapper=test/zig/integrated/runtime_tls_read_main.zig
  covered_fixture=test/zig/inputs/tls_concurrency.zig
  note=releasefast_runtime_tls_read and releasefast_runtime_tls_bump cover the
       selected local-exec TLS read/update surfaces for the same source fixture

ReleaseSafe executable:
  wrapper=test/zig/integrated/error_switch_main.zig
  covered_fixture=test/zig/inputs/error_switch.zig

ReleaseSafe executable with validated panic edge boundary:
  wrapper=test/zig/integrated/tiny_scalar_releasesafe_boundary_main.zig
  covered_fixture=test/zig/inputs/tiny_scalar.zig
  boundary=validated-zig-panic-edge

ReleaseSmall executable:
  wrapper=test/zig/integrated/globals_comptime_small_main.zig
  covered_fixture=test/zig/inputs/globals_comptime.zig
  note=integrated wrapper covers the comptime constant path; mutable global
       load/store remains covered by object/native-link fixture gates

  wrapper=test/zig/integrated/i64_arithmetic_main.zig
  covered_fixture=test/zig/inputs/i64_arithmetic.zig

  wrapper=test/zig/integrated/i64_arithmetic_main.zig
  covered_fixture=test/zig/inputs/i64_arithmetic.zig
  note=releasesmall_runtime_i64_call covers the i64 call-return surface for
       the same source fixture

  wrapper=test/zig/integrated/base64_table_lookup_main.zig
  covered_fixture=test/zig/inputs/base64_table_lookup.zig
```

Expected summary:

```text
postopt: total=10 executable_ok=9 link_only_ok=1 local_fail=0
preopt:  total=10 executable_ok=9 link_only_ok=1 local_fail=0
ir-writer tiny scalar: total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer tiny scalar: scalar_runtime_rows=1 minimal_wrapper_rows=0
ir-writer full set:    total=146 executable_ok=146 link_only_ok=0 local_fail=0
ir-writer table load:  zig build distribution-zig-ir-writer -- --case=releasesmall_base64_table_lookup
ir-writer table load:  total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer base64 step: zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_decode_step
ir-writer base64 step: total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer base64 store:
                       zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_store_step
ir-writer base64 store:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer base64 residual:
                       zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_base64_residual_byte_step
ir-writer base64 residual:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer condbr:      zig build distribution-zig-ir-writer -- --case=releasefast_runtime_cond_branch
ir-writer condbr:      total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer phi merge:   zig build distribution-zig-ir-writer -- --case=releasefast_runtime_phi_merge
ir-writer phi merge:   total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer loop sum:    zig build distribution-zig-ir-writer -- --case=releasefast_runtime_loop_sum
ir-writer loop sum:    total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer releasesafe loop sum:
                       zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_loop_sum
ir-writer releasesafe loop sum:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer switch:      zig build distribution-zig-ir-writer -- --case=releasefast_runtime_switch
ir-writer switch:      total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer releasesafe branch mix:
                       zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_branch_mix
ir-writer releasesafe branch mix:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer global update:
                       zig build distribution-zig-ir-writer -- --case=releasefast_runtime_global_update
ir-writer global update:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer pointer store:
                       zig build distribution-zig-ir-writer -- --case=releasefast_runtime_pointer_load_store
ir-writer pointer store:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer volatile:
                       zig build distribution-zig-ir-writer -- --case=releasefast_runtime_volatile_roundtrip
ir-writer volatile:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer optional ptr:
                       zig build distribution-zig-ir-writer -- --case=releasefast_runtime_optional_pointer
ir-writer optional ptr:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer packed flag:
                       zig build distribution-zig-ir-writer -- --case=releasefast_runtime_packed_read_flag
ir-writer packed flag:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer packed replace:
                       zig build distribution-zig-ir-writer -- --case=releasefast_runtime_packed_replace_low
ir-writer packed replace:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer call chain:  zig build distribution-zig-ir-writer -- --case=releasefast_runtime_call_chain
ir-writer call chain:  total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer i64 call:    zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_i64_call
ir-writer i64 call:    total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer tls read:    zig build distribution-zig-ir-writer -- --case=releasefast_runtime_tls_read
ir-writer tls read:    total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer tls bump:    zig build distribution-zig-ir-writer -- --case=releasefast_runtime_tls_bump
ir-writer tls bump:    total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer atomic add:  zig build distribution-zig-ir-writer -- --case=releasefast_runtime_atomic_add
ir-writer atomic add:  total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer inline asm:  zig build distribution-zig-ir-writer -- --case=releasefast_runtime_inline_asm_barrier
ir-writer inline asm:  total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer aggregate pair:
                       zig build distribution-zig-ir-writer -- --case=releasefast_runtime_aggregate_pair
ir-writer aggregate pair:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer float less:  zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_less
ir-writer float less:  total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer float mul:   zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_mul
ir-writer float mul:   total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer float add:   zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_add
ir-writer float add:   total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer float select:
                       zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_select
ir-writer float select:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer float sub:   zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_sub
ir-writer float sub:   total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer double div:  zig build distribution-zig-ir-writer -- --case=releasefast_runtime_double_div
ir-writer double div:  total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer float rem:   zig build distribution-zig-ir-writer -- --case=releasefast_runtime_float_rem
ir-writer float rem:   total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer struct sum:  zig build distribution-zig-ir-writer -- --case=releasefast_runtime_struct_sum
ir-writer struct sum:  total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer array sum:   zig build distribution-zig-ir-writer -- --case=releasefast_runtime_array_sum
ir-writer array sum:   total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer optional payload:
                       zig build distribution-zig-ir-writer -- --case=releasefast_runtime_optional_payload
ir-writer optional payload:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer error union:
                       zig build distribution-zig-ir-writer -- --case=releasefast_runtime_error_union_payload
ir-writer error union:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer slice sum:   zig build distribution-zig-ir-writer -- --case=releasefast_runtime_slice_sum
ir-writer slice sum:   total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer fp constants:
                       zig build distribution-zig-ir-writer -- --case=releasefast_runtime_fp_constants
ir-writer fp constants:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer comptime const:
                       zig build distribution-zig-ir-writer -- --case=releasefast_runtime_comptime_const
ir-writer comptime const:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer debug location:
                       zig build distribution-zig-ir-writer -- --case=releasefast_runtime_debug_location
ir-writer debug location:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer releasesafe debug location:
                       zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_debug_location
ir-writer releasesafe debug location:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer releasesafe comptime const:
                       zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_comptime_const
ir-writer releasesafe comptime const:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer releasesafe global update:
                       zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_global_update
ir-writer releasesafe global update:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer releasesafe pointer load/store:
                       zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_pointer_load_store
ir-writer releasesafe pointer load/store:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer releasesafe call chain:
                       zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_call_chain
ir-writer releasesafe call chain:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer releasesafe TLS bump:
                       zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_tls_bump
ir-writer releasesafe TLS bump:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer releasesafe array sum:
                       zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_array_sum
ir-writer releasesafe array sum:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer releasesafe struct sum:
                       zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_struct_sum
ir-writer releasesafe struct sum:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer releasesafe slice sum:
                       zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_slice_sum
ir-writer releasesafe slice sum:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer read global:
                       zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_read_global
ir-writer read global:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer TLS read:    zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_tls_read
ir-writer TLS read:    total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer side-effect-free:
                       zig build distribution-zig-ir-writer -- --case=releasesafe_runtime_side_effect_free
ir-writer side-effect-free:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer hidden access:
                       zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_hidden_access
ir-writer hidden access:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer mix C add:   zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_mix_c_add_zig
ir-writer mix C add:   total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer mix C panic add:
                       zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_mix_c_add_may_panic
ir-writer mix C panic add:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer umul fix sat:
                       zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_umul_fix_sat_i64
ir-writer umul fix sat:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer inherit i64:
                       zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_inherit_want_safety_i64
ir-writer inherit i64:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer compile asm:
                       zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_compile_asm_unreachable
ir-writer compile asm:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer str from float:
                       zig build distribution-zig-ir-writer -- --case=releasesmall_runtime_str_from_float_help
ir-writer str from float:
                       total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer full set:    scalar_runtime_rows=146 structured_direct_rows=146
                       structured_textual_rows=0 textual_boundary_rows=0
                       generic_codegen_rows=146
                       case_specific_codegen_rows=0
                       minimal_wrapper_rows=0
ir-writer surfaces:    scalar-add-ret=1 integer-arithmetic=3
                       error-switch-select=2 direct-call=1 global-load=3
                       i64-arithmetic=1 i64-call-return=1
                       table-indexed-load=1
                       checked-add-runtime-boundary=2 runtime-condbr=2
                       runtime-phi-merge=1 runtime-loop-sum=2
                       checked-loop-sum-boundary=1
                       runtime-switch=2 checked-branch-mix-boundary=2
                       global-update=1
                       pointer-load-store=2 volatile-roundtrip=1
                       optional-pointer=1 packed-read-flag=1
                       packed-replace-low=1 abi-arg-call=2 tls-read=2
                       tls-bump=1 atomic-add=1
                       inline-asm-barrier=1 aggregate-pair-abi=1
                       float-less=2 float-mul=1 float-add=2
                       float-select=1 float-sub=2 double-div=1
                       float-rem=1 void-noop-call=1
                       hidden-global-access=1 mixed-c-zig-add=1
                       mixed-c-zig-panic-add=1
                       umul-fix-sat-i64=1
                       inherit-i64-return=1
                       compile-asm-unreachable=1
                       str-from-float-help=1
                       base64-decode-step=1
                       base64-store-step=1
                       base64-residual-byte-step=1
                       base64-padding-tail-step=1
                       base64-padding-loop-step=1
                       base64-padding-length-step=1
                       base64-chunk-guard-step=1
                       base64-source-stride-step=1
                       base64-source-bundle-step=1
                       base64-next-source-bundle-step=1
                       base64-third-source-bundle-step=1
                       base64-bit-buffer-store-step=1
                       base64-loop-advance-step=1
                       base64-residual-guard-step=1
                       base64-residual-bundle-step=1
                       base64-residual-store-step=1
                       base64-residual-length-step=1
                       base64-residual-table-check-step=1
                       base64-residual-accumulator-step=1
                       base64-residual-loop-advance-step=1
                       base64-residual-padding-check-step=1
                       base64-residual-final-mask-step=1
                       base64-residual-padding-loop-step=1
                       base64-decode-exit-step=1
                       struct-field-sum=2
                       array-scalar-sum=2 optional-scalar-payload=1
                       error-union-payload=1
                       slice-loop-sum=2 fp-literal-return=1
                       comptime-const-mul=1
                       add-imm-return=1
                       checked-add-imm-boundary=1
                       checked-comptime-const-boundary=1
                       checked-global-update-boundary=2
                       checked-pointer-load-store-boundary=2
                       checked-call-chain-boundary=1
                       checked-tls-bump-boundary=1
                       checked-array-sum-boundary=2
                       checked-struct-sum-boundary=1
                       checked-slice-loop-sum-boundary=1
                       minimal-ret0=0
```

## Fallback Accounting

Remaining LLVM dependency:

```text
still uses libLLVM for Zig IR construction: yes
still uses libLLVM to parse, hold, and print the LLVM module: yes
still uses LLVM module optimization pipeline: postopt yes, preopt no
still uses LLVM target-machine object emission: no, for selected hook rows
still uses LLVM linker/LLD: no, final link uses Zig build-exe -fno-lld
final linker: Zig native linker/toolchain
```

For `ZIG_USE_ZLLVM_IR_WRITER=1` selected rows:

```text
ir-construction=zllvm-structured-builder or
ir-construction=zllvm-structured-builder
llvm-module=not-used
llvm-optimizer=not-used
llvm-targetmachine=not-used
object-emission=z_llvm
linker=zig-native-fno-lld
```

`zig build distribution-zig-ir-writer` now reports that ownership proof for
each selected row and fails if a selected row falls back to libLLVM module
parse/print, LLVM TargetMachine object emission, or a `minimal-ret0` surface.
The full selected gate also fails if any row is not constructed through
`src/structured_ir_builder.zig`, any textual row remains, or any structured row
uses case-specific codegen.
The normal Zig/libLLVM fallback remains available when the selected writer env
vars are unset.

The claim is intentionally x86_64-only and excludes AArch64, wasm, LTO, Debug
expansion, Zig startup runtime replacement, compiler_rt sub-compilation
replacement, broad runtime behavior, dynamic TLS, libc/compiler-rt replacement,
and target-complete object/codegen coverage.

Unsupported external IR writer constructs remain explicit:

```text
runtime integer arithmetic beyond the selected scalar/i64/integer rows
branches beyond the selected runtime-condbr, constant-condbr, checked-add
boundary, loop, and dense-switch shapes
stores beyond the selected mutable global update semantics
calls beyond the selected i32 ABI argument direct-call and selected i64
call-return shapes
error unions and ReleaseSafe runtime/panic paths beyond the selected
validated panic-runtime edge boundary
TLS beyond selected local-exec read/update, atomics beyond selected monotonic
add, inline asm beyond the selected memory barrier, vectors
aggregate ABI beyond the selected two-i32 pair, sret/byval, varargs
debug metadata, DWARF, unwind/personality records
non-x86_64 targets, LTO, simultaneous asm+object emission
```

## Milestone Claim

For selected x86_64 Zig source rows, patched Zig writes pre-optimization LLVM
IR, `z_llvm` runs the selected local accepted Zig-mode pipeline and emits the
relocatable object, and Zig's native linker links the executable. LLVM
TargetMachine codegen and LLVM's module optimization pipeline are bypassed for
those selected preopt rows. Zig still uses libLLVM to parse, hold, and print
the LLVM module after Zig IR construction when the external IR writer is not
selected.

For the selected `ZIG_USE_ZLLVM_IR_WRITER=1` rows, patched Zig validates the
external contract and calls `z_llvm --emit=ir-writer` to write the selected
LLVM IR module as a z_llvm-owned internal IR module, then `z_llvm` emits the
relocatable object, and Zig's native linker links the executable. The external
writer now emits 146/146 selected rows as runtime surfaces with all 146 rows
constructed directly through `src/structured_ir_builder.zig` and no textual
boundary rows. All 146 structured-direct rows now report generic x86_64 codegen
ownership:
`scalar-add-ret`, `integer-arithmetic`, `error-switch-select`, `direct-call`,
`global-load`, `i64-arithmetic`, `i64-call-return`, `table-indexed-load`, and
`checked-add-runtime-boundary`, plus `runtime-condbr` and
`runtime-phi-merge`, `runtime-loop-sum`, `runtime-switch`,
`checked-loop-sum-boundary`, `checked-branch-mix-boundary`, and
`global-update`, `pointer-load-store`, `volatile-roundtrip`,
`optional-pointer`, `packed-read-flag`, `packed-replace-low`,
`abi-arg-call`, `tls-read`, `tls-bump`, `void-noop-call`,
`hidden-global-access`, `mixed-c-zig-add`, `mixed-c-zig-panic-add`,
`umul-fix-sat-i64`,
`inherit-i64-return`,
`compile-asm-unreachable`,
`str-from-float-help`,
`base64-decode-step`,
`base64-store-step`,
`base64-residual-byte-step`,
`base64-padding-tail-step`,
`base64-padding-loop-step`,
`base64-padding-length-step`,
`base64-chunk-guard-step`,
`base64-source-stride-step`,
`base64-source-bundle-step`,
`base64-next-source-bundle-step`,
`base64-third-source-bundle-step`,
`base64-bit-buffer-store-step`,
`base64-loop-advance-step`,
`base64-residual-guard-step`,
`base64-residual-bundle-step`,
`base64-residual-store-step`,
`base64-residual-length-step`,
`base64-residual-table-check-step`,
`base64-residual-accumulator-step`,
`base64-residual-loop-advance-step`,
`base64-residual-padding-check-step`,
`base64-residual-final-mask-step`,
`base64-residual-padding-loop-step`,
`base64-decode-exit-step`,
`atomic-add`,
`inline-asm-barrier`, `aggregate-pair-abi`, `float-less`, `float-mul`,
`float-add`, `float-select`, `float-sub`, `double-div`, `float-rem`, and
`struct-field-sum`, `array-scalar-sum`, `optional-scalar-payload`, and
`error-union-payload`, `slice-loop-sum`, `fp-literal-return`, and
`comptime-const-mul`, `add-imm-return`, `checked-add-imm-boundary`, and
`checked-comptime-const-boundary`, `checked-global-update-boundary`, and
`checked-pointer-load-store-boundary`, `checked-call-chain-boundary`, and
`checked-tls-bump-boundary`, `checked-array-sum-boundary`, and
`checked-struct-sum-boundary`, and `checked-slice-loop-sum-boundary`, plus
`start-trampoline`, `getauxval-pointer-walk`, `f128-sret-byval`,
`noreturn-unreachable-stub`, `address-space-volatile-store`,
`raw-start-loop`, `i1-const-return`, `constant-string-slice-return`, and
`libfuzzer-vtable-run`; no
selected rows remain as
`minimal-ret0` hook-only
proofs. The per-row markers are:

```text
construction=ir-construction=zllvm-structured-builder
llvm_text_parse=not-used
codegen_ownership=codegen=generic-x86_64-lowering
ownership=llvm-module=not-used;llvm-optimizer=not-used;llvm-targetmachine=not-used;object-emission=z_llvm;linker=zig-native-fno-lld
```

LLVM's module optimization pipeline, LLVM TargetMachine codegen, and libLLVM
bitcode parse/print of the selected rows are bypassed. The
structured-direct milestone removes handwritten body ownership and textual
parse/print ownership for all 146 selected rows. The generic-codegen milestone adds
measured generic x86_64 lowering ownership for those rows but does
not claim full Zig IR construction or full backend replacement.

The case registry is now backed by reusable writer helpers in
`src/ir_writer_helpers.zig`. Shared helpers cover function headers, named
blocks, unconditional and conditional branches, two-input phis, loop
headers/latches, GEP/load/store, table loads, aggregate/global declarations,
TLS globals/accesses, stack slots, inline asm calls, indirect/vtable calls,
pointer index advancement, byte masks, shifts, truncation, calls, lifetime
intrinsics, memcpy/memset, and checked arithmetic panic-edge branches. Base64
full/reduced rows, selected loop/phi rows, the ReleaseSafe checked loop edge,
checked aggregate/pointer rows, TLS rows, inline-asm boundary rows,
ReleaseSmall mixed C/Zig rows, `strFromFloatHelp`, and float binary/check rows
use that layer. The remaining case-specific code is intentionally limited to
semantic fixture bodies whose exact shape is the evidence: base64 decoder CFG,
`strFromFloatHelp` decimal/pow-table control flow, aggregate ABI packing,
atomics, packed bits, and optional/error-union payload rows.
The next milestone starts after the frozen selected claim: the
`releasesmall_runtime_base64_decode_base_64_full` row registers a full
`@base64.decode_base_64` textual IR body for ReleaseSmall whole-function
boundary closure. Its `@main` performs executable validation for
`TWFu -> Man`, `TWE= -> Ma`, `TQ== -> M`, and invalid `!!!! -> -1`. The decoder
object path is now real table-driven x86_64 lowering with loop phis, table
loads, padding exits, success exit, and fail exit, so the base64 matrix row is
promoted to whole-function evidence.
