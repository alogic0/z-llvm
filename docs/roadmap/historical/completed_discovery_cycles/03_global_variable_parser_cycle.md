# Cycle 03: Global Variable Parser Closure

## Goal

Close the next measured source-backed parser blocker after Cycle 02:
Zig-emitted top-level global variables now parse far enough to reach the
global parser, then fail with `UnsupportedGlobalVariable`.

This is a parser, verifier, and printer preservation cycle. It should accept
the concrete global-variable spellings emitted by the current `../ziglang`
stage4 compiler for the focused `hello_world.zig` case, without claiming full
LLVM global-variable semantics or object/linker behavior.

## Source-Backed Evidence

Focused post-Cycle-02 discovery:

```text
zig run tools/zig_corpus_discovery.zig -- \
  --test-root=tmp/zig_ir/named_type_focus_sources \
  --out-dir=tmp/zig_ir/named_type_focus_check \
  --mode=ReleaseFast \
  --target=x86_64-linux-gnu \
  --passes=verify \
  --max=0 \
  --progress-every=0
```

Current result:

```text
parse-fail hello_world.zig ... error: UnsupportedGlobalVariable
```

Representative emitted IR:

```llvm
@__init_array_start = extern_weak constant ptr, align 8
@__init_array_end = extern_weak constant ptr, align 8
@os.linux.tls.area_desc.0 = internal unnamed_addr global i64 undef, align 8
@os.linux.tls.area_desc.4 = internal unnamed_addr global ptr undef, align 8
@os.linux.tls.main_thread_area_buffer = private unnamed_addr global [4096 x i8] undef, align 4096
@__anon_3154 = private unnamed_addr constant [13 x i8] c"hello world!\00", align 1
@Thread.maybeAttachSignalStack.global.signal_stack = private thread_local unnamed_addr global [262144 x i8] undef, align 1
```

Representative failure:

```text
tmp/zig_ir/named_type_focus_check/logs/hello_world.zig.parse-fail.stderr.txt
error: UnsupportedGlobalVariable
src/ir/parser.zig:297:54: const kind = core.GlobalKind.parse(token) orelse return error.UnsupportedGlobalVariable;
```

The first visible parser gap is `extern_weak` linkage. The same source-backed
module also contains initializerless external declarations, `unnamed_addr`,
`thread_local`, aggregate `undef` globals, and C string constants.

## LLVM Source Mapping

- `llvm-project-22/llvm/docs/LangRef.rst`: global variables, linkage types,
  runtime preemption, unnamed address, thread-local storage models, and
  constant data.
- `llvm-project-22/llvm/lib/AsmParser/LLParser.cpp`: top-level global variable
  parsing and `parseGlobal`.
- `llvm-project-22/llvm/lib/IR/Globals.cpp`: `GlobalVariable` and global
  linkage/initializer invariants.
- `llvm-project-22/llvm/lib/IR/AsmWriter.cpp`: textual printing of global
  variables and global declarations.

## Plan

- [x] Add a reduced source-backed fixture for `hello_world.zig` global
      declarations and definitions, separate from the large full emitted IR.
- [x] Extend global linkage parsing to accept `extern_weak` for the observed
      global-variable spelling.
- [x] Represent initializerless external global declarations explicitly instead
      of forcing every global to have a scalar or array initializer.
- [x] Preserve and verify declaration-style pointer constants such as
      `extern_weak constant ptr, align 8` conservatively.
- [x] Preserve `unnamed_addr`, `local_unnamed_addr`, `thread_local`, and known
      TLS model address attributes through parse, verify, and print.
- [x] Accept source-backed scalar `undef` globals for `i64` and `ptr` without
      adding broader constant-expression support.
- [x] Accept source-backed aggregate `undef` globals for fixed array types such
      as `[4096 x i8] undef` and `[262144 x i8] undef`.
- [x] Accept source-backed C string constants for fixed `i8` arrays, preserving
      the escaped spelling opaquely unless a later pass needs byte-level
      decoding.
- [x] Keep verifier rules conservative:
      - duplicate global names are still rejected;
      - declaration-style globals cannot have internal/private linkage;
      - initialized globals still require initializer/type compatibility;
      - aggregate layout and object emission semantics remain out of scope.
- [x] Print accepted global declarations and definitions in module order without
      losing address attributes, alignment attributes, or initializer spelling.
- [x] Add an opt fixture proving verifier-only preservation for the reduced
      global-variable fixture.
- [x] Rerun focused discovery for `hello_world.zig` and record whether it moves
      to the next blocker.
- [x] Rerun the normal gates before closing the cycle.

## Acceptance Criteria

- [x] The reduced global-variable fixture parses, verifies, and prints without
      losing source-backed global records.
- [x] `zig build run -- --passes=verify --trace <global fixture>` succeeds.
- [x] `zig build run -- --passes=zig-release-fast-accepted <global fixture>`
      succeeds or documents the next pass-specific blocker explicitly.
- [x] Focused `hello_world.zig` discovery no longer fails at the first
      source-backed global-variable declarations listed above.
- [x] Existing global fixtures still pass, including scalar globals, weak
      globals, COMDAT references, TLS roots, and switch-table constants.
- [x] No full LLVM constant-expression, relocation, linker, TLS lowering, or
      object-emission behavior is claimed.

## Non-Goals

- Full LLVM global-variable grammar.
- Full `GlobalVariable` semantic parity.
- Lowering globals to MC/Object records.
- Resolving linker-visible behavior for `extern_weak`, `init_array`, TLS, or
  aliases.
- General constant-expression parsing such as `inttoptr`, `getelementptr`
  constants, or pointer arithmetic.
- Recursive aggregate initializer decoding beyond source-backed C string and
  aggregate `undef` fixtures.
- Making the full `hello_world.zig` module optimizer-ready if later function,
  call, intrinsic, or control-flow blockers appear after globals parse.

## Follow-Up Candidates

- Pointer constant expressions such as
  `ptr inttoptr (i64 536870912 to ptr)`.
- Pointer-typed global constants such as `constant ptr @external_variable`.
- Global variable use edges in additional passes if new source-backed rows need
  them beyond the existing GlobalDCE coverage.
- TLS lowering and linker/object semantics in a separate backend/handoff cycle.

## Close-Out Notes

- [x] Record final fixture path.
- [x] Record opt fixture name.
- [x] Record focused discovery command and before/after result.
- [x] Record the next blocker exposed by `hello_world.zig`, if any.
- [x] Archive this cycle after implementation and verification.

## Completed Slice

```text
Final fixture:
  test/zig/expected/global_variables.reduced.ll

Opt fixture:
  global_variables_verify_preserve

Focused commands:
  zig build run -- --passes=verify --trace test/zig/expected/global_variables.reduced.ll
  zig build run -- --passes=zig-release-fast-accepted test/zig/expected/global_variables.reduced.ll
  zig run tools/zig_corpus_discovery.zig -- --test-root=tmp/zig_ir/global_focus_sources --out-dir=tmp/zig_ir/global_focus --mode=ReleaseFast --target=x86_64-linux-gnu --passes=verify --max=0 --progress-every=0

Normal gates:
  zig build test
  bash scripts/compare_opt.sh
  bash scripts/run_readiness_checks.sh
```

Before this cycle, focused `hello_world.zig` discovery stopped with
`parse-fail ... error: UnsupportedGlobalVariable`. After this cycle it reports
no parse failure and advances to:

```text
verify-fail hello_world.zig ... error: InvalidCharacter
```

The new blocker comes from a full-module call argument shape in
`src/ir/parser.zig` call parsing, not from the source-backed global-variable
records covered by this cycle.
