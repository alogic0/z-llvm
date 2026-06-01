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
checks and expose a minimal runtime C ABI `main` returning zero. That makes the
object-emitted `FuncGen.zig` surface for these rows much smaller than the
source fixtures they cover:

```text
needed for the first runtime-emitted writer row:
  ../ziglang/src/codegen/llvm/FuncGen.zig:446 dispatches .ret AIR
  ../ziglang/src/codegen/llvm/FuncGen.zig:934 airRet
  ../ziglang/src/codegen/llvm/FuncGen.zig:1027 emits wip.ret(operand)
  ../ziglang/src/codegen/llvm/FuncGen.zig:3344 airAdd

source-backed fixture constructs checked at comptime or in separate
object/native-link fixture gates, not yet emitted by the external IR writer:
  ../ziglang/src/codegen/llvm/FuncGen.zig:570  airCall
  ../ziglang/src/codegen/llvm/FuncGen.zig:1533 airCondBr
  ../ziglang/src/codegen/llvm/FuncGen.zig:1686 airSwitchBr
  ../ziglang/src/codegen/llvm/FuncGen.zig:4702 airStore
  ../ziglang/src/codegen/llvm/FuncGen.zig:4760 airLoad
  ../ziglang/src/codegen/llvm/FuncGen.zig:5499 airSelect
```

External IR writer emission surface for this slice:

```text
releasefast_tiny_scalar:
  module header: source_filename, x86_64 Linux target triple,
                 zllvm_ir_writer_contract=external,
                 zllvm_ir_writer_surface=scalar-add-ret
  function: dso_local i32 @main() local_unnamed_addr
  basic block: entry
  instruction: %v = add i32 40, 2
  terminator: ret i32 %v

remaining 9 rows:
  module header: source_filename, x86_64 Linux target triple,
                 zllvm_ir_writer_contract=external,
                 zllvm_ir_writer_surface=minimal-ret0
  function: dso_local i32 @main() local_unnamed_addr
  basic block: entry
  terminator: ret i32 0

metadata: none
globals: none
attributes: none
```

This is intentionally not a generic replacement for `FuncGen.zig`. The next
expansion should promote one concrete runtime-emitted construct from the
unsupported list into z_llvm's external textual writer, then add a focused wrapper that
requires it.

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
and expose a minimal C ABI `main` returning zero. That keeps the preopt gate
focused on the integrated hook, local accepted optimizer pipeline, object
emission, and native-link handoff. Runtime behavior is still executed for the
wrapper binary itself; broader callable ABI behavior remains covered by the
object/native-link fixture gates.

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

ReleaseSafe executable:
  wrapper=test/zig/integrated/error_switch_main.zig
  covered_fixture=test/zig/inputs/error_switch.zig

ReleaseSafe link-only boundary:
  wrapper=test/zig/integrated/tiny_scalar_releasesafe_boundary_main.zig
  covered_fixture=test/zig/inputs/tiny_scalar.zig
  boundary=zig-panic-runtime

ReleaseSmall executable:
  wrapper=test/zig/integrated/globals_comptime_small_main.zig
  covered_fixture=test/zig/inputs/globals_comptime.zig
  note=integrated wrapper covers the comptime constant path; mutable global
       load/store remains covered by object/native-link fixture gates

  wrapper=test/zig/integrated/i64_arithmetic_main.zig
  covered_fixture=test/zig/inputs/i64_arithmetic.zig

  wrapper=test/zig/integrated/base64_table_lookup_main.zig
  covered_fixture=test/zig/inputs/base64_table_lookup.zig
```

Expected summary:

```text
postopt: total=10 executable_ok=9 link_only_ok=1 local_fail=0
preopt:  total=10 executable_ok=9 link_only_ok=1 local_fail=0
ir-writer tiny scalar: total=1 executable_ok=1 link_only_ok=0 local_fail=0
ir-writer tiny scalar: scalar_runtime_rows=1 minimal_wrapper_rows=0
ir-writer full set:    total=10 executable_ok=9 link_only_ok=1 local_fail=0
ir-writer full set:    scalar_runtime_rows=1 minimal_wrapper_rows=9
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
runtime integer arithmetic beyond the releasefast_tiny_scalar scalar-add-ret row
branches, switches, phi/select emission, loops
loads, stores, globals, constants, table data
calls and calling-convention variants
error unions and ReleaseSafe runtime/panic paths
TLS, atomics, inline asm, vectors
aggregate ABI lowering, sret/byval, varargs
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
The `releasefast_tiny_scalar` row now emits real scalar runtime behavior
(`scalar-add-ret`) and exits 42; the remaining 9 rows remain minimal wrapper
proofs (`minimal-ret0`). LLVM's module optimization pipeline, LLVM
TargetMachine codegen, libLLVM bitcode parse/print of the selected object
module, and patched-Zig ownership of case-specific IR text are bypassed for
those rows.
