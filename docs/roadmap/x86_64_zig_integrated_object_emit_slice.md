# x86_64 Zig Integrated Object Emit Slice

This slice moves the selected source-backed proof from an external capture
pipeline into Zig's LLVM backend object-emission boundary:

```text
Zig build-obj
  -> Zig constructs LLVM IR with libLLVM
  -> patched Zig writes optimized LLVM IR at the object emission boundary
  -> z_llvm emits x86_64 relocatable .o
  -> Zig native linker links C ABI main wrappers with
     zig build-exe -fno-lld -fno-compiler-rt -lc
  -> executable cases run, link-only cases remain boundary accounting
```

Validation gate:

```text
zig build distribution-zig-integrated-object
```

## Zig Object-Emission Boundary

Current Zig call path in `../ziglang`:

```text
src/codegen/llvm.zig:Object.emit
  lowers Object.EmitOptions into bindings.TargetMachine.EmitOptions
  calls bindings.TargetMachine.emitToFile

src/codegen/llvm/bindings.zig:TargetMachine.emitToFile
  extern binding to ZigLLVMTargetMachineEmitToFile

src/zig_llvm.cpp:ZigLLVMTargetMachineEmitToFile
  builds the LLVM optimization pipeline
  creates legacy codegen_pm
  calls TargetMachine::addPassesToEmitFile(..., CodeGenFileType::ObjectFile)
  runs module_pm.run(...)
  runs codegen_pm.run(...)
```

That `TargetMachine::addPassesToEmitFile(... ObjectFile)` call is the current
LLVM target-machine object-emission boundary. The experimental hook is placed
there so Zig's IR construction remains unchanged.

## Hook Contract

Opt-in environment:

```text
ZIG_USE_ZLLVM_OBJECT=1
ZLLVM_EXE=/path/to/zig-out/bin/z_llvm
```

Contract:

```text
input=optimized LLVM IR text file written by patched Zig
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
object path. If it is set and `z_llvm` fails, the diagnostic reports the IR
path, object path, target, and exit status.

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
total=10
executable_ok=9
link_only_ok=1
local_fail=0
```

## Fallback Accounting

Remaining LLVM dependency:

```text
still uses libLLVM for Zig IR construction: yes
still uses LLVM target-machine object emission: no, for selected hook rows
still uses LLVM linker/LLD: no, final link uses Zig build-exe -fno-lld
final linker: Zig native linker/toolchain
```

The claim is intentionally x86_64-only and excludes AArch64, wasm, LTO, Debug
expansion, Zig startup runtime replacement, compiler_rt sub-compilation
replacement, broad runtime behavior, dynamic TLS, libc/compiler-rt replacement,
and target-complete object/codegen coverage.

## Milestone Claim

For the selected x86_64 source-backed release slice, libLLVM target-machine
object emission is not needed after Zig constructs LLVM IR for the selected
object rows. Patched Zig emits optimized IR at the object boundary, `z_llvm`
emits the relocatable object, and Zig's native linker owns the final executable
path.
