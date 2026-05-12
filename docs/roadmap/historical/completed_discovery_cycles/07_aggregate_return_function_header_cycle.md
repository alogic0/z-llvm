# Cycle 07: Aggregate Return Function Header Parser Closure

## Goal

Close the next source-backed parser blocker found by the three-agent discovery,
fix, and review loop: LLVM function definitions with anonymous aggregate return
types.

This cycle is intentionally narrow. It accepts balanced anonymous aggregate
type spelling where the local parser already stores aggregate types opaquely,
without adding aggregate ABI lowering or optimizer semantics.

## Source-Backed Evidence

Discovery command:

```text
zig run tools/zig_corpus_discovery.zig -- --out-dir=tmp/zig_ir/agent_discovery_01 --progress-every=100
```

Sweep summary:

```text
complete=true
zig_exe=../ziglang/build/stage4/bin/zig
test_root=../ziglang/test
mode=ReleaseFast
target=x86_64-linux-gnu
passes=verify
candidates=1474
processed=1474
compile_skip=1009
emit_ok=465
local_ok=336
input_too_large=122
parse_fail=3
verify_fail=4
optimizer_fail=0
```

Selected row:

```text
parse-fail	standalone/empty_global_error_set/main.zig	tmp/zig_ir/agent_discovery_01/ir/standalone_empty_global_error_set_main.zig.ReleaseFast.x86_64.ll	tmp/zig_ir/agent_discovery_01/logs/standalone_empty_global_error_set_main.zig.parse-fail.stderr.txt	error: InvalidFunctionHeader
```

Failing source-backed header:

```llvm
define private fastcc { ptr, i64 } @main.errorName(i16 %0) unnamed_addr #0 align 1 {
```

Minimal fixture shape:

```llvm
define private fastcc { ptr, i64 } @main.errorName(i16 %0) unnamed_addr #0 align 1 {
  ret { ptr, i64 } undef
}
```

## Root Cause

`parseTrailingType` split function-header prefixes at the final whitespace. For
`private fastcc { ptr, i64 }`, that selected `i64 }` as the return type instead
of the balanced aggregate type `{ ptr, i64 }`, which made the parser report
`InvalidFunctionHeader`.

The same fixture also needed `parseLeadingType` to treat a leading balanced
aggregate type as one unit for the return terminator:

```llvm
ret { ptr, i64 } undef
```

## LLVM Reference Mapping

The behavior follows the source-backed subset of:

- `llvm-project-22/llvm/lib/AsmParser/LLParser.cpp`
  - `LLParser::parseFunctionHeader`: parses optional linkage, calling
    convention, return attributes, return type, function name, parameters, and
    function attributes for `define`/`declare` headers.
  - `LLParser::parseType`: parses return and value types, including anonymous
    aggregate type spelling.
  - `LLParser::parseAnonStructType`: handles anonymous structure types parsed
    inline in type positions.
  - `LLParser::parseStructBody`: parses the balanced aggregate body for
    anonymous structs.
  - `LLParser::parseRet`: parses return instruction typed values using the same
    type parser.
- `llvm/docs/LangRef.rst`
  - function definitions;
  - structure types;
  - return instruction typed values.

## Implementation

- Added reverse balanced-delimiter helpers for trailing aggregate type
  detection in function prefixes.
- Extended leading type parsing to accept balanced anonymous aggregate and array
  type spellings before the typed value.
- Kept aggregate body semantics opaque, matching the current local `Type`
  policy.
- Added a focused parser/verifier/printer test for the packet-shaped function
  header and return instruction.

Changed files:

```text
src/ir/parser.zig
src/tests.zig
```

## Agent Handoff Evidence

Scratch artifacts from the three-agent loop:

```text
tmp/scratch/bug_packets/01_next_source_backed_blocker.md
tmp/scratch/fix_reports/01_aggregate_return_function_header.md
tmp/scratch/review_reports/01_aggregate_return_function_header.md
tmp/scratch/agent_orchestration_log.md
```

Reviewer verdict:

```text
accepted
```

Reviewer findings:

```text
No blocking findings.
```

## Acceptance Criteria

- [x] The selected source-backed IR parses and verifies.
- [x] Anonymous aggregate return types in function headers are preserved by the
      printer.
- [x] The packet-shaped `ret { ptr, i64 } undef` terminator parses and verifies.
- [x] The new test would catch the original `InvalidFunctionHeader` failure.
- [x] The implementation does not claim aggregate ABI lowering or optimizer
      support.
- [x] Reviewer accepted the fix.
- [x] The normal gates pass.

## Verification

Commands run by the fixer/reviewer/parent loop:

```text
zig fmt src/ir/parser.zig src/tests.zig
zig build test
../ziglang/build/stage4/bin/zig build run -- --passes=verify --trace tmp/zig_ir/agent_discovery_01/ir/standalone_empty_global_error_set_main.zig.ReleaseFast.x86_64.ll
git diff --check
bash scripts/compare_opt.sh
bash scripts/run_readiness_checks.sh
```

## Remaining Discovery Groups

This cycle did not fix the other groups found by the same sweep:

- `input-too-large` / `StreamTooLong`: 122 rows.
- `parse-fail` / unsupported binary op flag: `or disjoint` in
  `standalone/emit_llvm_no_bin/main.zig`.
- `parse-fail` / unsupported floating global initializer in
  `standalone/extern/exports.zig`.
- `verify-fail` / call operand bundles or call metadata after attribute groups:
  3 safety rows.
- `verify-fail` / nested constant-expression GEP operand in
  `standalone/mix_o_files/base64.zig`.

## Non-Goals

- Full aggregate layout validation.
- Aggregate ABI lowering.
- Optimizer transforms for aggregate returns.
- Input-size policy changes.
- Fixing unrelated parser/verifier groups from the same sweep.

## Close-Out Notes

- [x] Discovery packet written.
- [x] Fix report written.
- [x] Review report written.
- [x] Code reviewed by the reviewer agent.
- [x] Parent readiness gate passed.
