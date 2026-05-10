# Zig-Emitted IR Fixtures

Goal: keep a small checked-in bridge from real Zig LLVM backend output to the
LLVM-compatible subset that this project can parse and compare.

Regenerate the raw fixture with Zig 0.16.0:

```bash
zig build-obj -fllvm -flibllvm -fno-emit-bin -femit-llvm-ir=/tmp/z_llvm_tiny_scalar.ll -O ReleaseFast -target x86_64-linux-gnu test/zig/inputs/tiny_scalar.zig
```

Current checked-in fixture:

```text
test/zig/inputs/tiny_scalar.zig
test/zig/expected/tiny_scalar.normalized.ll
test/zig/expected/tiny_scalar.project_lowered.ll
test/zig/expected/tiny_scalar.project_optimized.ll
src/testdata/zig_tiny_scalar.normalized.ll
src/testdata/zig_tiny_scalar.project_lowered.ll
src/testdata/zig_tiny_scalar.project_optimized.ll
```

The `src/testdata/` copy exists because Zig `@embedFile` in unit tests cannot
embed files outside the module root.

Fixture classification:

```text
zig-equivalent:
  tiny_scalar.normalized.ll preserves module target records and scalar function signatures from Zig-emitted LLVM IR.

local project bridge:
  tiny_scalar.project_lowered.ll is the AIR-like bridge output for the same scalar signatures.
  tiny_scalar.project_optimized.ll is the `zig-scalar-foundation` output for that bridge fixture.
```

Normalization policy:

```text
keep source_filename, target datalayout, target triple
keep scalar function signatures and return types
keep scalar integer arithmetic needed by the comparison
drop aliases, debug metadata, attribute groups, target-feature strings, and unrelated std/debug support emitted into raw Zig IR
drop instruction debug attachments
drop raw function header attrs until the project consumes their semantics
instruction flags are compared structurally for now; exact Zig-emitted nsw/nuw parity is a later poison/overflow slice
```

Known raw Zig IR constructs not represented yet:

```text
module aliases such as @add = alias ...
debug metadata and llvm.module.flags
attribute groups with target features
raw target triples with versioned OS/ABI components are parsed but not treated as supported target identities
stdlib/support functions pulled into Debug builds
```
