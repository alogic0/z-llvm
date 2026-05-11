# Finish Criteria and Gap Burn-Down Table

This is the durable finish table for the current Zig-aligned LLVM replacement
experiment. It defines what this repository can honestly call finished and
links every remaining gap to source-backed evidence, an opt fixture, a
conservative accepted boundary, or an explicit non-goal.

## Finish Definition

The project finish line is not a full LLVM clone. The finish line is reached
when the measured Zig-emitted corpus selected in
`docs/fixtures/zig_ir/manifest.tsv` can parse, verify, print, and run through
the local pipeline selected by each accepted row, while every unsupported or
future row is either reduced into an accepted fixture or explicitly justified as
out of scope for this repository.

Required optimizer work is defined by accepted corpus rows and opt fixture
evidence, not by every LLVM pass in upstream PassBuilder. The required local
optimizer subset is the one exercised by the accepted ReleaseFast,
ReleaseSmall, ReleaseSafe, Debug, and target-independent AArch64 rows plus the
fixture table in `test/opt/fixtures.tsv`.

Conservative accepted boundaries are allowed for debug info, atomics, inline
asm, vectors, EH, TLS, module flags, sanitizer hooks, and LTO when the local
parser/verifier preserves or rejects the IR deliberately and the pass docs say
which LLVM behavior is deferred.

Native backend and AIR handoff work is sufficient for this repo when accepted
optimized IR has at least one scalar, memory, loop, and global handoff proof,
plus x86_64 text/object smoke coverage for the current backend subset. Broad
target backend parity is outside this finish definition.

Non-goals for this finish line:

- Full LLVM clone.
- Full MC/Object replacement.
- Full ThinLTO or bitcode summary implementation.
- Full debug variable-location salvage.
- Target-complete vectorization and cost modeling.
- Broad backend parity across targets and ABIs.

## Current Evidence

Readiness gate command:

```text
bash scripts/run_readiness_checks.sh
```

Latest recorded summary:

```text
ok manifest rows=37 optimizer_input=30
summary accepted=30 unsupported=0 future=4 debug-info-only=0
ok readiness checks
```

Opt fixture counts from `test/opt/fixtures.tsv`:

| Fixture kind | Count | Meaning |
| --- | ---: | --- |
| `opt-equivalent` | 115 | Normalized local output matches `opt-22` for the listed pass pipeline. |
| `local-conservative` | 42 | Local output is deliberately narrower or named differently while preserving a documented safety boundary. |
| `parse-preserve-only` | 7 | Fixture proves parser/verifier/printer preservation without transform parity. |
| Total | 164 | Current opt fixture table size. |

Pass status counts from the active pass pipeline inventory:

| Status | Count | Meaning |
| --- | ---: | --- |
| `placeholder` | 70 | Known upstream pass surface, no local algorithm implementation. |
| `LLVM-shaped subset` | 2 | Broad LLVM structure exists for accepted IR, but not fixture-equivalent pass behavior. |
| `fixture-equivalent` | 13 | Listed fixtures match or intentionally document local-only conservative behavior. |
| `algorithm-parity target` | 0 | No pass currently claims full LLVM algorithm parity for its supported surface. |

## Remaining Corpus Blockers

| Manifest row | Status | Evidence | Finish disposition |
| --- | --- | --- | --- |
| `tiny_scalar_debug` | `future,legacy-bootstrap` | Historical broad raw Debug IR is too large because it pulls in debug and std support. Reduced Debug rows already cover the accepted metadata boundary. | Later measured blocker; activate only by reducing an uncovered Debug construct. |
| `tiny_scalar_release_safe` | `future,legacy-bootstrap` | Historical broad raw ReleaseSafe IR is broad. Reduced ReleaseSafe safety and runtime-call rows already cover the accepted safety boundary. | Later measured blocker; activate only by reducing an uncovered safety or runtime-call construct. |
| `tiny_scalar_release_small` | `future,legacy-bootstrap` | Historical unstripped raw ReleaseSmall generation row predates the stripped captured ReleaseSmall row. | Closed by Cycle 02; retained as future evidence only, superseded by `tiny_scalar_release_small_captured`. |
| `vector_future_release_fast` | `parse,verify,future` | Reduced vector row parses and verifies fixed-vector syntax but is not optimizer-input until target-cost/vector transform policy exists. | Conservative accepted boundary; vectorizers and target-cost-driven transforms remain out of scope for this finish line. |

## Burn-Down Order

1. Corpus closure: remove, reduce, or explicitly justify the remaining
   `future` and `unsupported` manifest rows.
2. Verifier correctness: close only verifier gaps that appear in source-backed
   rows, starting with operand bundles, address spaces, malformed metadata, and
   EH boundary cases if they appear in the corpus.
3. Optimizer quality: choose one measured pass-specific parity gap at a time,
   preferring SROA slice rewriting, GVN PRE, or ADCE control dependence only
   when fixture deltas prove the need.
4. Debug boundary: add debug salvage only for transforms that remove or replace
   instructions carrying `!dbg`; keep `llvm.dbg.value` and
   `llvm.dbg.declare` conservative until variable-location salvage is modeled.
5. Handoff proof: add one non-trivial native backend or AIR handoff validation
   shape that proves accepted optimized IR can move toward Zig-owned codegen.

## Gap Status Table

| Gap | Current status | Evidence owner | Next action |
| --- | --- | --- | --- |
| Stale raw ReleaseSmall unsupported row | conservative accepted boundary | `docs/fixtures/zig_ir/manifest.tsv` | Closed by Cycle 02; accepted evidence is `tiny_scalar_release_small_captured`. |
| Raw Debug whole-program shape | later measured blocker | `tiny_scalar_debug` plus reduced Debug rows | Activation condition: reduce a concrete uncovered Debug construct from raw Zig output. |
| Raw ReleaseSafe whole-program shape | later measured blocker | `tiny_scalar_release_safe` plus reduced safety rows | Activation condition: reduce a concrete uncovered safety/runtime-call construct from raw Zig output. |
| Fixed-vector optimizer participation | conservative accepted boundary | `vector_future_release_fast`, vector opt fixtures | Preserve parser/verifier plus narrow lane folds; keep vectorizers out of scope. |
| Full debug variable-location salvage | out of scope for finish | debug intrinsic fixtures and debug docs | Preserve `llvm.dbg.value`/`llvm.dbg.declare`; do not transform them until salvage exists. |
| Full ThinLTO/bitcode summary behavior | out of scope for finish | bitcode/LTO docs | Keep compatibility decision and explicit unsupported diagnostics. |
| Broad MC/Object/backend parity | out of scope for finish | backend handoff docs and readiness checks | Keep current x86_64 scalar smoke proofs only. |
| LLVM algorithm parity for all passes | out of scope for finish | `docs/analysis/algorithm_parity_audit.md` | Continue fixture-equivalent slices only when source-backed evidence requires them. |

## Selected Next Slice

The stale `tiny_scalar_release_small` unsupported manifest row is closed. Broad
raw Debug and ReleaseSafe rows now have explicit future activation conditions.
The active implementation slice is recorded in `docs/next_steps.md`: close the
vector future boundary.
