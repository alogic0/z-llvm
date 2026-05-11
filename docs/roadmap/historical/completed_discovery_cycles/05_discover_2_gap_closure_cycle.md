# Cycle 05: Discover 2 Gap Closure With LLVM Reference Mapping

## Goal

Resolve the remaining source-backed issues reported by
`tmp/zig_ir/discover_2/report.tsv`, using LLVM 22 source code and LangRef as
the reference for each accepted IR grammar or verifier behavior.

This cycle is not a request to clone LLVM's parser wholesale. It is a measured
gap-closure cycle: group the `discover_2` failures, reduce representative
fixtures, map each group to upstream LLVM code, then implement the smallest
Zig-native parser/verifier/printer behavior needed to move the sweep forward.

## Source-Backed Evidence

Discovery input:

```text
tmp/zig_ir/discover_2/report.tsv
tmp/zig_ir/discover_2/summary.txt
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
local_ok=317
parse_fail=14
verify_fail=134
optimizer_fail=0
```

Failure groups:

```text
122 verify-fail  error: StreamTooLong
 11 parse-fail   error: UnsupportedGlobalVariable
  6 verify-fail  error: UnsupportedCallAttribute
  3 verify-fail  error: UnsupportedNamedTypeDefinition
  2 verify-fail  error: UnsupportedVarArgs
  1 verify-fail  error: InvalidCharacter
  1 parse-fail   error: UnsupportedType
  1 parse-fail   error: UnsupportedGlobalAlias
  1 parse-fail   error: InvalidCharacter
```

Representative rows:

```text
behavior/export_keyword.zig: InvalidCharacter
cases/address_of_extern_var_as_const.zig: UnsupportedGlobalVariable
cases/array_in_anon_struct.zig: UnsupportedNamedTypeDefinition
cases/f32_passed_to_variadic_fn.zig: UnsupportedVarArgs
cases/f_segment_address_space_reading_and_writing.zig: InvalidCharacter
cases/safety/noreturn returned.zig: UnsupportedGlobalAlias
cases/safety/slice_cast_change_len_0.zig: UnsupportedCallAttribute
standalone/issue_11595/main.zig: UnsupportedType
c_abi/main.zig: StreamTooLong
```

Representative emitted IR:

```llvm
@address_of_extern_var_as_const.p_external_variable =
  private unnamed_addr constant ptr @external_variable, align 8

@bar = alias void (), ptr @"noreturn returned.T.bar"

%"atomic.Value(usize)" = type { i64 }
%Io.Operation = type { <{ %Io.Operation.NetRead, [24 x i8] }>, i3, [7 x i8] }

declare void @llvm.memcpy.p0.p0.i64(
  ptr noalias writeonly captures(none),
  ptr noalias readonly captures(none),
  i64,
  i1 immarg
)

%127 = call i64 asm sideeffect "syscall", "..."(
  i64 231,
  i64 range(i64 0, 2) 1
) #10

store i64 98765, ptr addrspace(257) null, align 4294967296
```

## LLVM Reference Mapping

For each checked item below, record the exact upstream file/function used as
the behavioral reference before marking the item complete.

- `llvm-project-22/llvm/docs/LangRef.rst`
  - global variables and constant initializers;
  - aliases and quoted global names;
  - identified structure names, quoted names, and packed structure syntax;
  - call and declaration parameter attributes;
  - varargs function declarations and calls;
  - address-space-qualified pointer syntax;
  - alignment syntax and limits.
- `llvm-project-22/llvm/lib/AsmParser/LLParser.cpp`
  - `parseGlobal`;
  - global aliases;
  - named type definitions;
  - type parsing, including address-space pointers and packed structs;
  - call argument and function declaration parameter parsing;
  - parameter attribute parsing.
- `llvm-project-22/llvm/lib/IR/AsmWriter.cpp`
  - printing globals, aliases, named types, call operands, and parameter
    attributes.
- `llvm-project-22/llvm/lib/IR/Verifier.cpp`
  - global declaration/initializer invariants;
  - alias invariants;
  - parameter attribute placement rules;
  - varargs constraints.
- `llvm-project-22/llvm/lib/IR/Attributes.cpp`
  - attribute spelling and payload validation.
- `llvm-project-22/llvm/lib/IR/Type.cpp`
  - identified and packed structure type handling.

## Plan

- [x] Added the durable grouped artifact
      `docs/fixtures/zig_ir/discover_2_gap_summary.md`.
- [x] Kept compile-skip rows out of the IR closure count and documented the
      parser/verifier-only bucket split.
- [x] Reclassified `StreamTooLong` as `input-too-large` in the discovery
      harness while preserving the normal CLI read limit.
- [x] Added the reduced verifier-preserve fixture
      `test/zig/expected/discover2_gap_closure.reduced.ll`.
- [x] Implemented pointer global initializer preservation and referenced
      symbol checks.
- [x] Implemented quoted and `weak_odr` global alias preservation.
- [x] Implemented quoted identified type names, anonymous aggregate global
      type prefixes, and packed-structure body preservation.
- [x] Implemented source-backed declaration and call argument attributes:
      `noundef`, `noalias`, `writeonly`, `readonly`, `captures(none)`,
      `immarg`, `range(type lo, hi)`, and related pointer payload forms.
- [x] Kept call attributes as parser/verifier/print facts only.
- [x] Implemented varargs declarations and source-backed fixed plus varargs
      calls.
- [x] Implemented address-space store pointer parsing and `u64` alignment
      preservation.
- [x] Implemented source-backed `trunc nuw` flag parsing, metadata call
      operands, `!prof` metadata, and multi-edge PHI verifier behavior.
- [x] Added the opt verifier-preserve fixture row
      `discover2_gap_closure_verify_preserve`.
- [x] Reran focused `discover_2` representatives for each bucket and recorded
      them in the durable summary.
- [x] Reran the normal gates before closing the cycle.

## Acceptance Criteria

- [x] `tmp/zig_ir/discover_2/report.tsv` has been converted into a durable
      grouped backlog with representative fixture targets.
- [x] Each implemented sub-slice cites the LLVM reference source file and
      function used to reproduce the behavior.
- [x] All non-compile-skip `discover_2` rows are either:
      - accepted by parser/verifier;
      - classified as `input-too-large`;
      - classified as an explicit unsupported boundary with a source-backed
        reason; or
      - moved to a named follow-up cycle with representative fixture evidence.
- [x] No row remains hidden under accidental raw parser errors such as
      `InvalidCharacter` from a failed integer parse.
- [x] The focused bucket sweep shows no unclassified `parse_fail` or
      `verify_fail` representatives from `discover_2`.
- [x] The normal gates pass:

```text
zig build test
bash scripts/compare_opt.sh
bash scripts/run_readiness_checks.sh
```

## Non-Goals

- Cloning LLVM's C++ IR parser.
- Full LangRef grammar coverage.
- Full object/linker relocation behavior for global references or aliases.
- Full recursive identified-struct type semantics.
- Full varargs ABI lowering.
- Using new call attributes as optimization facts without separate legality
  fixtures.
- Treating Zig compile-error tests or target-incompatible tests as local IR
  bugs.

## Follow-Up Candidates

- Split `StreamTooLong` into its own harness cycle if raising/configuring the
  input limit touches CLI policy.
- Split varargs into an ABI/handoff cycle if source-backed calls require more
  than parse/verify/print preservation.
- Split address-space semantics into a target/DataLayout cycle if optimizers
  need address-space-aware alias rules.
- Split named-type layout semantics into a DataLayout aggregate cycle if a
  source-backed optimizer fixture requires it.

## Close-Out Notes

- [x] Record final grouped `discover_2` summary.
- [x] Record final fixture paths.
- [x] Record LLVM source mappings used by each implemented sub-slice.
- [x] Record focused sweep before/after counts.
- [x] Record any follow-up cycle files created from deferred buckets.
- [x] Archive this cycle after implementation and verification.
