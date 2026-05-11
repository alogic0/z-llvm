# Zig-Emitted IR Corpus

This directory documents the fixture corpus for LLVM IR emitted by Zig's LLVM
backend. The corpus exists so parser, verifier, optimizer, and comparison work
starts from real Zig output instead of hand-written LLVM IR alone.

The first checked fixture group is `tiny_scalar`, backed by:

```text
test/zig/inputs/tiny_scalar.zig
test/zig/expected/tiny_scalar.normalized.ll
test/zig/expected/tiny_scalar.project_lowered.ll
test/zig/expected/tiny_scalar.project_optimized.ll
```

The `src/testdata/zig_tiny_scalar.*.ll` copies exist only because Zig unit tests
embed files from inside the module root.

## Layout

```text
docs/fixtures/zig_ir/README.md
docs/fixtures/zig_ir/manifest.tsv
test/zig/inputs/<group>.zig
test/zig/expected/<group>.<kind>.ll
tmp/zig_ir/raw/<group>.<mode>.ll
```

Tracked fixture files should be normalized or project-produced outputs. Raw
Zig-emitted LLVM IR may contain machine-local debug paths and very large stdlib
support sections, so raw files are generated under `tmp/` unless a slice
explicitly sanitizes and checks them in.

## Manifest Format

`manifest.tsv` is tab-separated and has these columns:

```text
id
group
source
zig_version
target_arg
emitted_target_triple
optimize_mode
command
raw_ir_path
checked_ir_path
classification
inventory_links
notes
```

Classifications:

```text
parse
verify
optimizer-input
unsupported
future
```

A fixture can list multiple classifications separated by commas. Use
`unsupported` when Zig emits real LLVM IR that the local parser/verifier cannot
consume yet. Use `future` when the mode or feature is documented but not yet a
driver for implementation.

## Regeneration Commands

Generate raw LLVM IR for the first scalar group:

```sh
mkdir -p tmp/zig_ir/raw
zig build-obj -fllvm -flibllvm -fno-emit-bin -femit-llvm-ir=tmp/zig_ir/raw/tiny_scalar.Debug.ll -O Debug -target x86_64-linux-gnu test/zig/inputs/tiny_scalar.zig
zig build-obj -fllvm -flibllvm -fno-emit-bin -femit-llvm-ir=tmp/zig_ir/raw/tiny_scalar.ReleaseSafe.ll -O ReleaseSafe -target x86_64-linux-gnu test/zig/inputs/tiny_scalar.zig
zig build-obj -fllvm -flibllvm -fno-emit-bin -femit-llvm-ir=tmp/zig_ir/raw/tiny_scalar.ReleaseFast.ll -O ReleaseFast -target x86_64-linux-gnu test/zig/inputs/tiny_scalar.zig
zig build-obj -fllvm -flibllvm -fno-emit-bin -femit-llvm-ir=tmp/zig_ir/raw/tiny_scalar.ReleaseSmall.ll -O ReleaseSmall -target x86_64-linux-gnu test/zig/inputs/tiny_scalar.zig
```

The checked normalized fixture currently corresponds to the scalar signatures
from the `ReleaseFast` raw output.

## Tiny Scalar Group

Purpose:

- scalar exported functions;
- module target records;
- aliases emitted for exported Zig functions;
- optimized integer `add nsw`;
- mode differences between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.

Current local status:

| Mode | Status |
| --- | --- |
| `Debug` | raw IR generated successfully, but it pulls in large debug/std support and is classified as `future`. |
| `ReleaseSafe` | raw IR generated successfully, but it is still large because safety/std support remains visible; classified as `future`. |
| `ReleaseFast` | normalized scalar signature fixture is checked in and classified as `parse,verify,optimizer-input`. |
| `ReleaseSmall` | raw IR is small, but aliases, size attrs, and raw function attrs are not yet accepted by the local parser; classified as `unsupported`. |

Connection to the LLVM pass inventory:

| Fixture area | Inventory connection |
| --- | --- |
| `Debug` raw mode | `debug-o0`, `verify`, `always-inline`, debug metadata placeholders. |
| `ReleaseFast` normalized scalar mode | `release-o3`, `verify`, `instsimplify`, `instcombine`, `simplifycfg`, scalar pipeline aliases. |
| `ReleaseSafe` raw mode | `release-o3`, safety-check emitted IR, future unsupported-IR discovery. |
| `ReleaseSmall` raw mode | `release-oz`, size attributes, alias/global handling, unsupported-IR discovery. |

## Current Gaps

- Raw aliases such as `@add = alias ...` are not accepted by the local parser.
- Raw function attributes, attribute groups, and target-feature strings are
  normalized away for the checked scalar fixture.
- Debug metadata and module flags are preserved only in documentation for this
  group.
- `Debug` and `ReleaseSafe` raw IR are too broad for the first corpus slice and
  should be reduced or sanitized before being checked in.

