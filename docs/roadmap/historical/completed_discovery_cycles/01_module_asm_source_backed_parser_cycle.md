# Cycle 01: Module ASM Source-Backed Parser Closure

## Goal

Close the first concrete root-cause blocker found by the broad Zig test
discovery sweep: Zig-emitted module-level inline assembly records currently
fall through as non-function instructions and fail parsing with
`LineOutsideFunction`.

This is a parser and preservation cycle, not an inline-assembly lowering cycle.
The local optimizer should accept and preserve module-level `module asm`
records without claiming native MC/object lowering or full LLVM inline-asm
semantics.

## Source-Backed Evidence

- Zig source: `ziglang/test/behavior/asm.zig`
- Emitter: `ziglang/build/stage4/bin/zig`
- Emitter version: `0.17.0-dev.304+9787df942`
- Zig source revision: `9787df9421`
- Discovery IR:
  `z_llvm/tmp/zig_ir/discovery/ir/behavior_asm.zig.ReleaseFast.x86_64.ll`
- Current failure:
  `z_llvm/tmp/zig_ir/discovery/logs/behavior_asm.zig.verify-fail.stderr.txt`
- Current local error: `LineOutsideFunction`

Observed IR shape:

```llvm
module asm ".globl this_is_my_alias;"
module asm ".type this_is_my_alias, @function;"
module asm ".set this_is_my_alias, derp;"
```

LLVM source mapping:

- `llvm-project-22/llvm/docs/LangRef.rst`: module-level inline assembly syntax.
- `llvm-project-22/llvm/lib/AsmParser/LLParser.cpp`: top-level `module asm`
  parsing.
- `llvm-project-22/llvm/lib/IR/Module.cpp`: module inline-asm storage and
  printing behavior.

## Plan

- [x] Add a reduced source-backed fixture for the `behavior/asm.zig` module-asm
      shape.
- [x] Extend the IR module model with an ordered collection of opaque
      module-level assembly records.
- [x] Parse top-level `module asm "..."` before the generic top-level fallback
      that currently produces `LineOutsideFunction`.
- [x] Preserve escaped string spelling enough to round-trip the current
      Zig-emitted records.
- [x] Print module-asm records in module scope before globals/functions, matching
      the observed Zig-emitted ordering.
- [x] Verify module-asm records as opaque module-level records; do not inspect
      target assembly syntax.
- [x] Keep optimizer behavior conservative: passes must preserve module-asm
      records and must not treat their contents as analyzable IR facts.
- [x] Add a discovery classification check so this root cause is reported as
      `parse-fail` until closed, then `verify-ok`.
- [x] Rerun a focused discovery check for `behavior/asm.zig`.
- [x] Rerun the normal corpus/readiness gates.

## Acceptance Criteria

- [x] The reduced module-asm fixture parses, verifies, and prints without losing
      any `module asm` records.
- [x] `zig build run -- --passes=verify --trace <module-asm fixture>` succeeds.
- [x] A focused discovery run over `ziglang/test/behavior/asm.zig` or a directory
      containing it reports `verify-ok` for that row.
- [x] No optimizer pass drops module-asm records when run through the accepted
      ReleaseFast subset.
- [x] The cycle does not claim support for target assembly validation, alias
      resolution inside assembly text, MC/object lowering, or codegen semantics.

## Non-Goals

- Native lowering of module assembly to object files.
- Parsing target assembly syntax inside the string.
- Resolving `.globl`, `.type`, `.set`, or symbol references inside module asm.
- Treating module asm as proof that a private function/global is live, except
  where a later GlobalDCE/linkage cycle deliberately adds a conservative policy.
- Closing unrelated discovery failures such as `inttoptr` pointer constants or
  external global pointer constants.

## Close-Out Notes

- [x] Record final fixture path and test command.
- [x] Record whether the broad discovery failure count changed after the fix.
- [x] Move this cycle to historical after implementation and verification.

## Completed Slice

```text
Final fixture:
  test/zig/expected/behavior_asm_module_asm.reduced.ll

Opt fixture:
  behavior_asm_module_asm_verify_preserve

Focused commands:
  zig build run -- --passes=verify --trace test/zig/expected/behavior_asm_module_asm.reduced.ll
  zig build run -- --passes=zig-release-fast-accepted test/zig/expected/behavior_asm_module_asm.reduced.ll
  zig run tools/zig_corpus_discovery.zig -- --test-root=../ziglang/test/behavior --out-dir=tmp/zig_ir/module_asm_focus --mode=ReleaseFast --target=x86_64-linux-gnu --passes=verify --max=7 --progress-every=0

Normal gates:
  zig build test
  bash scripts/compare_opt.sh
  bash scripts/run_readiness_checks.sh
```

The focused discovery run reports `behavior/asm.zig` as `verify-ok`. The
original broad discovery artifact was already present under
`tmp/zig_ir/discovery`; this cycle does not rerun the whole broad discovery set,
so no broad failure-count delta is claimed.
