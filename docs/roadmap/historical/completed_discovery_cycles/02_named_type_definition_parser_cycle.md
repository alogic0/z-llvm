# Cycle 02: Named Type Definition Parser Closure

## Goal

Close the dominant source-backed parser blocker from the post-Cycle-01
discovery sweep: Zig-emitted top-level named LLVM type definitions currently
fall through as non-function instructions and fail with `LineOutsideFunction`.

This is a parser, verifier, and printer preservation cycle. It should accept
opaque named type definitions that appear in real Zig-emitted IR without
claiming complete LLVM type-system semantics or aggregate layout lowering.

## Source-Backed Evidence

Discovery sweep:

```text
directory: z_llvm/tmp/zig_ir/discovery_after_cycle01
candidates=1474
processed=1474
emit_ok=465
local_ok=267
parse_fail=76
verify_fail=122
optimizer_fail=0
```

Cycle 01 proof:

```text
behavior/asm.zig: verify-ok
```

Dominant remaining parse bucket:

```text
73 parse-fail rows: error: LineOutsideFunction
```

Representative Zig sources:

- `ziglang/test/cases/hello_world.zig`
- `ziglang/test/cases/simple_addition_and_subtraction.zig`
- `ziglang/test/cases/address_spaces_pointer_access_chaining_array_pointer.zig`

Representative emitted IR:

```llvm
%os.linux.rlimit = type { i64, i64 }
%os.linux.stack_t__struct_3163 = type { ptr, i32, [4 x i8], i64 }
```

Representative failure:

```text
z_llvm/tmp/zig_ir/discovery_after_cycle01/logs/cases_hello_world.zig.parse-fail.stderr.txt
error: LineOutsideFunction
```

LLVM source mapping:

- `llvm-project-22/llvm/docs/LangRef.rst`: structure types and identified
  structure type definitions.
- `llvm-project-22/llvm/lib/AsmParser/LLParser.cpp`: top-level named type
  parsing for `%name = type ...`.
- `llvm-project-22/llvm/lib/IR/Type.cpp`: identified struct type storage and
  printing behavior.

## Plan

- [x] Add a reduced source-backed fixture for the observed named type records.
- [x] Extend the IR module model with an ordered collection of top-level named
      type definitions.
- [x] Parse top-level `%name = type ...` records before the generic top-level
      fallback that currently reports `LineOutsideFunction`.
- [x] Preserve the textual type body opaquely for now, including aggregate
      bodies such as `{ i64, i64 }` and `{ ptr, i32, [4 x i8], i64 }`.
- [x] Print named type definitions in module scope after target records and
      module asm, before globals/functions, matching observed Zig-emitted IR.
- [x] Verify named type definitions conservatively:
      - names are unique within named type definitions;
      - the opaque body is non-empty;
      - no layout or recursive type validation is claimed in this cycle.
- [x] Ensure parser behavior remains conservative for unsupported type forms:
      accept only the source-backed top-level spelling, not arbitrary type
      aliases or recursive opaque structs unless covered by fixtures.
- [x] Run a focused discovery check over a directory containing
      `cases/hello_world.zig` or a reduced local fixture.
- [x] Rerun the full discovery sweep or a representative subset and confirm the
      `LineOutsideFunction` bucket drops.
- [x] Rerun the normal corpus/readiness gates.

## Acceptance Criteria

- [x] The reduced named-type fixture parses, verifies, and prints without losing
      named type records.
- [x] `zig build run -- --passes=verify --trace <named-type fixture>` succeeds.
- [x] `cases/hello_world.zig` no longer fails because of top-level named type
      definitions.
- [x] Existing `behavior/asm.zig` module-asm discovery row remains `verify-ok`.
- [x] The accepted ReleaseFast pipeline preserves named type records and does
      not use them for aggregate layout optimization unless an existing pass
      already has independent DataLayout-backed support.
- [x] No unrelated blockers are silently folded into this cycle.

## Non-Goals

- Full LLVM identified-struct type semantics.
- Recursive or opaque struct completion rules beyond the observed source-backed
  spelling.
- DataLayout-backed aggregate ABI lowering for named types.
- Closing `inttoptr` constant-expression parsing.
- Closing pointer-typed global constants.
- Raising or redesigning the CLI input-size limit that produced
  `StreamTooLong` rows.

## Follow-Up Candidates

- Cycle 03: pointer constant expressions such as
  `ptr inttoptr (i64 536870912 to ptr)`.
- Cycle 04: pointer-typed global constants such as
  `constant ptr @external_variable`.
- Harness cleanup: classify `StreamTooLong` as `input-too-large` instead of a
  verifier failure.

## Close-Out Notes

- [x] Record final fixture path and focused discovery command.
- [x] Record before/after counts for `LineOutsideFunction`.
- [x] Record any remaining named-type rows that still fail and why.
- [x] Archive this cycle after implementation and verification.

## Completed Slice

```text
Final fixture:
  test/zig/expected/named_type_definitions.reduced.ll

Opt fixture:
  named_type_definitions_verify_preserve

Focused commands:
  zig build run -- --passes=verify --trace test/zig/expected/named_type_definitions.reduced.ll
  zig build run -- --passes=zig-release-fast-accepted test/zig/expected/named_type_definitions.reduced.ll
  zig run tools/zig_corpus_discovery.zig -- --test-root=tmp/zig_ir/named_type_focus_sources --out-dir=tmp/zig_ir/named_type_focus --mode=ReleaseFast --target=x86_64-linux-gnu --passes=verify --max=0 --progress-every=0
  zig run tools/zig_corpus_discovery.zig -- --test-root=tmp/zig_ir/named_type_representative_sources --out-dir=tmp/zig_ir/named_type_representative --mode=ReleaseFast --target=x86_64-linux-gnu --passes=verify --max=0 --progress-every=0

Normal gates:
  zig build test
  bash scripts/compare_opt.sh
  bash scripts/run_readiness_checks.sh
```

The pre-cycle discovery artifact reported `73` `LineOutsideFunction` parse
failures, including `cases/hello_world.zig` and the other representative rows.
The representative post-cycle discovery set reports:

```text
asm.zig: verify-ok
hello_world.zig: parse-fail UnsupportedGlobalVariable
simple_addition_and_subtraction.zig: parse-fail UnsupportedGlobalVariable
address_spaces_pointer_access_chaining_array_pointer.zig: parse-fail UnsupportedGlobalVariable
```

Those rows no longer stop at top-level named type definitions. Remaining
failures are intentionally deferred global-variable parser coverage, not named
type parser failures.
