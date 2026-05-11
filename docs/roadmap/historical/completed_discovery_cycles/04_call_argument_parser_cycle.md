# Cycle 04: Call Argument Parser Closure

## Goal

Close the next measured source-backed blocker exposed after Cycle 03:
`hello_world.zig` no longer fails on top-level globals, but the full emitted IR
now reaches call parsing and fails while parsing a call argument value.

This cycle should reproduce the LLVM IR call-argument parsing behavior needed
by Zig-emitted IR, not clone LLVM's complete parser. LLVM's parser is the
source reference; this project keeps a Zig-native parser and implements only
the source-backed grammar slices required by current fixtures.

## Source-Backed Evidence

Focused post-Cycle-03 discovery:

```text
zig run tools/zig_corpus_discovery.zig -- \
  --test-root=tmp/zig_ir/global_focus_sources \
  --out-dir=tmp/zig_ir/global_focus_check \
  --mode=ReleaseFast \
  --target=x86_64-linux-gnu \
  --passes=verify \
  --max=0 \
  --progress-every=0
```

Current result:

```text
verify-fail hello_world.zig ... error: InvalidCharacter
```

Representative failure:

```text
tmp/zig_ir/global_focus_check/logs/hello_world.zig.verify-fail.stderr.txt
error: InvalidCharacter
src/ir/parser.zig:1858:22: parseValue
src/ir/parser.zig:1197:23: parseCallArgs
```

Representative emitted IR:

```llvm
tail call void asm sideeffect "...", "..."(
  ptr nonnull @start._start,
  ptr nonnull @start.posixCallMainAndExit
) #11

tail call void @llvm.assume(i1 %lcmp.mod58)
call void @llvm.lifetime.start.p0(ptr nonnull %3)
call void @llvm.lifetime.end.p0(ptr nonnull %3)
%1 = tail call i32 @puts(ptr nonnull readonly align 1 dereferenceable(1) @__anon_3154)
```

The first visible parser gap is a typed call operand where LLVM parameter
attributes appear between the argument type and the value, for example:

```llvm
ptr nonnull @start._start
ptr nonnull readonly align 1 dereferenceable(1) @__anon_3154
```

## LLVM Source Mapping

- `llvm-project-22/llvm/docs/LangRef.rst`: call instruction syntax, parameter
  attributes, operand bundles, varargs, inline asm calls, and intrinsic calls.
- `llvm-project-22/llvm/lib/AsmParser/LLParser.cpp`: `parseCall`, call
  argument parsing, parameter attributes, and inline asm call parsing.
- `llvm-project-22/llvm/lib/IR/Instructions.cpp`: `CallBase`, `CallInst`, and
  operand/attribute invariants.
- `llvm-project-22/llvm/lib/IR/Attributes.cpp`: parameter attribute storage and
  validation rules.

## Plan

- [x] Add a reduced source-backed fixture for the observed `hello_world.zig`
      call-argument forms, separate from the large full emitted IR.
- [x] Parse call arguments as `type attrs* value` instead of only
      `type value`.
- [x] Preserve source-backed parameter attributes opaquely on `CallArg`,
      including:
      - `nonnull`;
      - `readonly`;
      - `align N`;
      - `dereferenceable(N)`.
- [x] Preserve source-backed call-site attribute group suffixes such as `#11`
      on direct calls and inline asm calls.
- [x] Ensure inline asm calls use the same call-argument parser as direct calls
      for source-backed typed operands.
- [x] Add verifier checks that remain conservative:
      - unknown or duplicate call-argument attributes are rejected unless
        already supported elsewhere;
      - `align` requires a valid power-of-two alignment;
      - `dereferenceable(N)` requires a non-empty integer payload;
      - parameter attributes are preserved but not used for optimization facts
        in this cycle.
- [x] Print call arguments with attributes in the original LLVM order expected
      by the reduced fixture.
- [x] Add an opt fixture proving verifier-only preservation for the reduced
      call-argument fixture.
- [x] Rerun focused discovery for `hello_world.zig` and record whether it moves
      to the next blocker.
- [x] Rerun the normal gates before closing the cycle.

## Acceptance Criteria

- [x] The reduced call-argument fixture parses, verifies, and prints without
      dropping argument attributes.
- [x] `zig build run -- --passes=verify --trace <call-argument fixture>`
      succeeds.
- [x] `zig build run -- --passes=zig-release-fast-accepted <call-argument fixture>`
      succeeds or documents the next pass-specific blocker explicitly.
- [x] Focused `hello_world.zig` discovery no longer fails with
      `InvalidCharacter` from call-argument value parsing.
- [x] Existing call, inline asm, intrinsic, ABI-attribute, debug-intrinsic, and
      global fixtures still pass.
- [x] No full LLVM parser clone, complete parameter-attribute semantics,
      operand-bundle support, or varargs support is claimed.

## Non-Goals

- Cloning LLVM's C++ IR parser.
- Full LLVM call grammar.
- Full `AttributeList` or `CallBase` semantic parity.
- Operand bundles.
- Varargs support beyond explicit conservative rejection.
- Using `nonnull`, `readonly`, `align`, or `dereferenceable` as optimization
  facts unless an existing pass already has independent legality support.
- Solving later blockers exposed by the full `hello_world.zig` module after
  this call-argument layer parses.

## Follow-Up Candidates

- Intrinsic declarations and verifier policy for `llvm.assume`,
  `llvm.lifetime.start/end`, `llvm.memset`, and `llvm.memcpy`.
- Inline asm constraint validation beyond side-effecting barrier preservation.
- Call argument attributes as optimization facts, only after a source-backed
  fixture requires it.
- Pointer constant-expression parsing if a later global or call operand exposes
  it.

## Close-Out Notes

- [x] Record final fixture path.
- [x] Record opt fixture name.
- [x] Record focused discovery command and before/after result.
- [x] Record the next blocker exposed by `hello_world.zig`, if any.
- [x] Archive this cycle after implementation and verification.

## Completed Slice

```text
Final fixture:
  test/zig/expected/call_argument_attributes.reduced.ll

Opt fixture:
  call_argument_attributes_verify_preserve

Focused commands:
  zig build run -- --passes=verify --trace test/zig/expected/call_argument_attributes.reduced.ll
  zig build run -- --passes=zig-release-fast-accepted test/zig/expected/call_argument_attributes.reduced.ll
  zig run tools/zig_corpus_discovery.zig -- --test-root=tmp/zig_ir/global_focus_sources --out-dir=tmp/zig_ir/call_arg_focus_check --mode=ReleaseFast --target=x86_64-linux-gnu --passes=verify --max=0 --progress-every=0

Normal gates:
  zig build test
  bash scripts/compare_opt.sh
  bash scripts/run_readiness_checks.sh
```

Before this cycle, focused `hello_world.zig` discovery stopped with
`verify-fail ... error: InvalidCharacter` from `parseValue` while parsing a
call argument. After this cycle it reports:

```text
final processed=1/1 compile-skip=0 emit-ok=1 local-ok=1 parse-fail=0 verify-fail=0 optimizer-fail=0
```

No next `hello_world.zig` blocker is exposed on the verifier path by this
cycle.
