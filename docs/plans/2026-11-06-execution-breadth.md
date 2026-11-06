# Execution breadth after Fibonacci

Status: next milestone after the accepted Fibonacci completion checkpoint.
The [completion plan](2026-11-05-fibonacci-completion.md) closes steps 1–6;
this plan develops step 7. Keep the fixed 100-row emission population and its
five executed functions distinct from unchanged programs and native fixtures.

## Unchanged programs

Add a manifest-driven regression for several substantially different programs
from the same pinned Zig source. Preserve every source byte, check the source
hash, and compare exit status, stdout and stderr with LLVM in Fast, Safe and
Small. Report each program and mode separately, including failures.

The exploratory reports under
`local-state/validations/fibonacci-completion-20261105/` identify useful starting
cases; they are diagnostics, not accepted integration coverage:

| Program | Exploratory result | Purpose |
| --- | --- | --- |
| `optionals` | Three modes match | Optional values and branching |
| `taking_pointer_of_global_tagged_union` | Safe matches; Fast and Small fail emission | Global tagged storage, pointers and assertion runtime |
| `array_in_anon_struct` | Safe matches; Fast and Small fail emission | Aggregate initialization and addressing |

Include a further unchanged program with a runtime loop or memory traversal so
the new population does more than exercise shared startup and assertion helpers.
Do not change assertions, remove runtime dependencies, or replace these programs
with semantic recipes to obtain a pass.

## Shared repairs

The retained tagged-union Fast frontier selects 1,484 functions and emits 1,469.
`next-execution-frontier.json` records 15 rejected functions: nine copy-cycle
rejections, four immediate-left binary forms, one call pointer argument, and one
GEP value. Reproduce these against the accepted compiler before implementation.

1. Extend the common value-use transfer planner to schedule parallel-copy cycles.
   Save a source into a proven free scratch register or an owned spill slot;
   preserve every live alias and width. Use the same scheduling contract for
   calls and CFG transfers. Keep unsupported register classes and unproved
   scratch/storage cases rejected, and preserve transactional rollback.
2. Route immediate-left scalar forms through the existing scalar transaction.
   Preserve operand order for subtraction, division, remainder and shifts.
3. Trace the pointer argument in `Io.Reader.defaultRebase` and the address in
   `Progress.Node.storageByIndex` to shared address/ABI rules. Admit only the
   demonstrated layouts and value representations.
4. Add native differential combinations of two- and three-register cycles,
   fan-out, live aliases, narrow and full-width values, PHIs, calls and pressure.
   Check final values and protected memory against LLVM. Add rejection and
   rollback controls for unsupported transfer envelopes.

Keep mandatory semantic normalization before generic selection. Additional
optional legalizers must consume checked normalized input. New machine
instructions must expose operand, register and control-flow effects. Avoid
adding whole-program or symbol-specific matchers for these failures.

## Compiler-core execution

Expand the versioned execution cohort with authenticated definitions already
inside the fixed 100-row prefix. Initial candidates are
`bit_set.Dynamic.maskIndex` for index arithmetic,
`atomic.Mutex.tryLock` for observable atomic state transitions, and
`hash_map.Custom(...).Metadata.isFree` / `isTombstone` for packed state predicates.
Confirm their exact exported identities, signatures and ABI before admission.

Generate independent reference and local-call harnesses. Exercise boundary
indexes, every relevant byte state, and successful/repeated lock attempts;
check return values and memory effects. Retain object identity/linkage checks
and wrong-result, wrong-symbol and clobber controls. Update the cohort schema,
parser and counters together. Never infer execution from a successful link.

## Acceptance

Run focused native regressions and route tests after each shared repair. Then
freeze the combined source and run unit tests in Debug and ReleaseSafe,
structural checks, ABI comparisons, policy checks and the full 17-gate suite.
The permanent three-mode Fibonacci regression remains mandatory. Promote the
new program and function counts only when every required mode passes.

Retain small reports and provenance, the original 13 scratch probes and the
diagnostic worktree. Create no archives. Keep the existing 32,949,672,960-byte
start threshold and 24,359,738,368-byte execution reserve. Performance work uses
the separate fixed workload matrix; passing more programs does not establish
release optimization quality.
