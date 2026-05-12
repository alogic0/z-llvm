# Cycle 07: Selected Stage4 Corpus Refresh

## Goal

Run the next development-cycle step from the future optimizer backlog without
inventing a new optimizer implementation target. The selected slice refreshes
small source-backed Zig-emitted IR rows with the authoritative stage4 emitter
and checks whether the checked corpus has drifted.

## Source-Backed Evidence

Backlog source:

```text
docs/roadmap/future_optimizer_backlog.md
```

Selected rows:

```text
tiny_scalar_release_fast_captured
integers_release_fast
switch_control_release_fast
optional_pointer_release_fast
```

These rows were chosen because they are small optimizer-input fixtures and
cover scalar canonicalization, integer intrinsics, switch table lowering with
cast/GEP flags, and optional-pointer null lowering.

## Compiler Check

The authoritative emitter was checked before regeneration:

```text
scripts/check_zig_stage4_emitter.sh
ok stage4 emitter 0.17.0-dev.304+9787df942 matches ../ziglang HEAD 9787df942
```

Emitter policy:

```text
Zig emitter: ../ziglang/build/stage4/bin/zig
Zig source revision: 9787df9421
Target: x86_64-linux-gnu
Mode: ReleaseFast
```

## Commands

```text
scripts/capture_zig_ir.sh test/zig/inputs/tiny_scalar.zig ReleaseFast
scripts/capture_zig_ir.sh test/zig/inputs/integers.zig ReleaseFast
scripts/capture_zig_ir.sh test/zig/inputs/switch_control.zig ReleaseFast
scripts/capture_zig_ir.sh test/zig/inputs/optional_pointer.zig ReleaseFast
scripts/lint_zig_ir_manifest.sh
```

## Result

All four regenerated checked captures were byte-identical to the tracked files:

```text
test/zig/captured/tiny_scalar.ReleaseFast.x86_64.ll
test/zig/captured/integers.ReleaseFast.x86_64.ll
test/zig/captured/switch_control.ReleaseFast.x86_64.ll
test/zig/captured/optional_pointer.ReleaseFast.x86_64.ll
```

No parser, verifier, optimizer, manifest, or expected-output implementation
change was required.

## LLVM Reference Mapping

No new LLVM behavior was implemented in this cycle. The refreshed rows continue
to exercise the existing documented mapping:

- `llvm/lib/AsmParser/LLParser.cpp`: textual IR parsing for module records,
  aliases, function headers, scalar instructions, calls, globals, constant
  expressions, and metadata attachments.
- `llvm/lib/IR/AsmWriter.cpp`: textual IR printing and preservation of the
  accepted source-backed IR surface.
- `llvm/lib/IR/Verifier.cpp`: verifier entry points for functions,
  instructions, aliases, globals, attributes, casts, GEPs, and PHI/branch
  structure.
- `llvm/lib/Transforms/InstCombine/InstructionCombining.cpp` and
  `llvm/lib/Analysis/InstructionSimplify.cpp`: scalar integer canonicalization
  references for `tiny_scalar` and `integers`.
- `llvm/lib/Transforms/Scalar/SimplifyCFGPass.cpp` and
  `llvm/lib/Transforms/Utils/SimplifyCFG.cpp`: control-flow and switch/table
  canonicalization references for `switch_control`.

Known broader LLVM behavior remains documented in the existing IR, pass, and
unsupported-surface docs; this cycle did not promote any future-only row.

## Acceptance Criteria

- [x] Select a bounded slice from the future optimizer backlog.
- [x] Verify the stage4 emitter matches `../ziglang` HEAD.
- [x] Regenerate the selected checked captures.
- [x] Confirm the selected captures are byte-identical to tracked files.
- [x] Lint the Zig IR fixture manifest.
- [x] Record upstream mapping status and known non-expansion boundary.

## Validation

```text
scripts/check_zig_stage4_emitter.sh
scripts/lint_zig_ir_manifest.sh
```
