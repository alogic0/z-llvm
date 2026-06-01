# x86_64 Zig Source Native-Link Slice

This slice is the first integration gate that starts from Zig source instead of
checked LLVM IR fixtures:

```text
Zig source
  -> stage4 Zig emits LLVM IR
  -> z_llvm emits x86_64 relocatable object
  -> Zig native linker links with zig build-exe -fno-lld
  -> executable cases run, link-only cases remain boundary accounting
```

Validation gate:

```text
zig build distribution-zig-source-native-link
```

Latest result:

```text
total=10
executable_ok=9
link_only_ok=1
local_fail=0
```

## Selected Rows

Executable proof:

```text
ReleaseFast:
  test/zig/inputs/tiny_scalar.zig
  test/zig/inputs/integers.zig
  test/zig/inputs/control_flow_calls.zig
  test/zig/inputs/globals_comptime.zig
  test/zig/inputs/error_switch.zig

ReleaseSafe:
  test/zig/inputs/error_switch.zig

ReleaseSmall:
  test/zig/inputs/globals_comptime.zig
  test/zig/inputs/i64_arithmetic.zig
  test/zig/inputs/base64_table_lookup.zig
```

Link-only boundary proof:

```text
ReleaseSafe:
  test/zig/inputs/tiny_scalar.zig
  boundary=zig-panic-runtime
```

## Fallback Accounting

Every row intentionally still uses stage4 Zig to emit LLVM IR:

```text
fallback=ir-emission:stage4-llvm-ir
```

The source integration claim begins after that IR exists. For executable rows,
there is no LLVM codegen fallback after IR emission: object emission is local
`z_llvm`, and final linking is Zig native linker only.

The ReleaseSafe tiny-scalar row is link-only because its checked-add IR imports
Zig-owned panic runtime behavior:

```text
fallback=ir-emission:stage4-llvm-ir;boundary:zig-panic-runtime
```

Runtime stubs are used only for that link-only proof. They are not executable
behavior evidence.

## Claim

For this selected x86_64 source-backed release slice, LLVM codegen is not
needed after Zig emits LLVM IR.

This does not claim full Zig distribution replacement, full runtime behavior,
CRT/linker ownership inside `z_llvm`, broad ReleaseSafe panic semantics,
dynamic TLS, libc/compiler-rt replacement, or Debug metadata/unwind quality.
