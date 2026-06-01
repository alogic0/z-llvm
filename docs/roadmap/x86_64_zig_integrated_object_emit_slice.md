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
    -> z_llvm --emit=ir-writer writes the selected textual LLVM IR module
    -> z_llvm runs the accepted Zig-mode pipeline
    -> z_llvm emits x86_64 relocatable .o
    -> Zig native linker links C ABI main wrappers with
       zig build-exe -fno-lld -fno-compiler-rt -lc
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
ir_writer_input=selected textual LLVM IR module written by z_llvm
                --emit=ir-writer into ZLLVM_IR_PATH
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
ir-writer full set:    total=32 executable_ok=32 link_only_ok=0 local_fail=0
ir-writer table load:  zig build distribution-zig-ir-writer -- --case=releasesmall_base64_table_lookup
ir-writer table load:  total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer condbr:      zig build distribution-zig-ir-writer -- --case=releasefast_runtime_cond_branch
ir-writer condbr:      total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer phi merge:   zig build distribution-zig-ir-writer -- --case=releasefast_runtime_phi_merge
ir-writer phi merge:   total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer loop sum:    zig build distribution-zig-ir-writer -- --case=releasefast_runtime_loop_sum
ir-writer loop sum:    total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer switch:      zig build distribution-zig-ir-writer -- --case=releasefast_runtime_switch
ir-writer switch:      total=1 executable_ok=1 link_only_ok=0 local_fail=0
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
ir-writer full set:    scalar_runtime_rows=32 minimal_wrapper_rows=0
ir-writer surfaces:    scalar-add-ret=1 integer-arithmetic=1
                       error-switch-select=2 direct-call=1 global-load=2
                       i64-arithmetic=1 i64-call-return=1
                       table-indexed-load=1
                       checked-add-runtime-boundary=1 runtime-condbr=1
                       runtime-phi-merge=1 runtime-loop-sum=1
                       runtime-switch=1 global-update=1
                       pointer-load-store=1 volatile-roundtrip=1
                       optional-pointer=1 abi-arg-call=1 tls-read=1
                       tls-bump=1 atomic-add=1
                       inline-asm-barrier=1 aggregate-pair-abi=1
                       float-less=1 float-mul=1 float-add=1
                       float-select=1 float-sub=1 double-div=1
                       float-rem=1 minimal-ret0=0
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
still uses Zig LLVM Builder for general backend state: yes
still serializes/parses/prints the Builder module through libLLVM for the
selected emitted object module: no
still uses LLVM module optimization pipeline: no
still uses LLVM target-machine object emission: no
still uses LLVM linker/LLD: no, final link uses Zig build-exe -fno-lld
textual IR bodies owned by patched Zig: no, z_llvm owns --emit=ir-writer
```

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
the LLVM module after Zig IR construction.

For the selected `ZIG_USE_ZLLVM_IR_WRITER=1` rows, patched Zig validates the
external contract and calls `z_llvm --emit=ir-writer` to write the textual LLVM
IR module, then `z_llvm` performs the accepted Zig-mode optimization pipeline
and emits the relocatable object, and Zig's native linker links the executable.
The external writer now emits 32/32 selected rows as runtime surfaces:
`scalar-add-ret`, `integer-arithmetic`, `error-switch-select`, `direct-call`,
`global-load`, `i64-arithmetic`, `i64-call-return`, `table-indexed-load`, and
`checked-add-runtime-boundary`, plus `runtime-condbr` and
`runtime-phi-merge`, `runtime-loop-sum`, `runtime-switch`, and
`global-update`, `pointer-load-store`, `volatile-roundtrip`,
`optional-pointer`, `abi-arg-call`, `tls-read`, `tls-bump`, `atomic-add`,
`inline-asm-barrier`, `aggregate-pair-abi`, `float-less`, `float-mul`,
`float-add`, `float-select`, `float-sub`, `double-div`, and `float-rem`; no selected rows remain as
`minimal-ret0` hook-only
proofs. LLVM's module optimization pipeline, LLVM
TargetMachine codegen, libLLVM bitcode parse/print of the selected object
module, and patched-Zig ownership of case-specific IR text are bypassed for
those rows.
