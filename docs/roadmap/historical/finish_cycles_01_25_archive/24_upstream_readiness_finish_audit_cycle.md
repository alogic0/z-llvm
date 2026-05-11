# Cycle 24: Upstream Readiness Finish Audit

## Goal

Refresh the full project state after Cycles 01-23 and decide the next smallest
set of finish work from measured gaps.

## Plan

- [x] Rebuild the current Zig stage compiler policy check and record emitter
      provenance.
- [x] Refresh representative Debug, ReleaseSafe, ReleaseFast, ReleaseSmall,
      x86_64, and AArch64 corpus rows.
- [x] Run the full readiness gate, opt comparison suite, corpus runner, handoff
      validation, and generated scalar diff.
- [x] Count accepted, unsupported, future, debug-info-only, and
      optimizer-input manifest rows.
- [x] Audit every pass doc status against implemented code and fixtures.
- [x] Audit every analysis doc status against implemented code and fixtures.
- [x] Produce a remaining-gap table grouped by correctness, optimizer quality,
      debug, target/backend, concurrency, vector, module/LTO, and upstream
      integration.
- [x] Archive completed active cycles and create the next numbered wave only
      from measured gaps.

## Exit Criteria

- [x] Readiness gates pass or failures are documented as explicit blockers.
- [x] The roadmap reflects actual implementation state.
- [x] The next wave is evidence-backed rather than speculative.

## Completed Audit

Emitter provenance:

```text
ok stage4 emitter 0.17.0-dev.304+9787df942 matches ../ziglang HEAD 9787df942
```

Representative refresh checks wrote temporary IR under `tmp/zig_ir/raw`:

```text
tiny_scalar Debug x86_64
tiny_scalar ReleaseSafe x86_64
integers ReleaseFast x86_64
integers ReleaseSmall AArch64
```

Readiness gates:

```text
zig build test: pass
bash scripts/compare_opt.sh: pass
scripts/lint_zig_ir_manifest.sh: pass
scripts/run_zig_corpus.sh: pass
bash scripts/run_handoff_validation.sh: pass
bash scripts/run_generated_scalar_diff.sh: pass
```

Manifest count:

```text
total=37
accepted optimizer-input=30
unsupported=1
future=3
debug-info-only=0
```

Doc audit:

```text
pass docs match current fixture claims for the implemented local subset
analysis docs match current legality boundaries for MemorySSA, alias,
memory-effect, CFG, debug, vector, atomic, TLS, and LTO behavior
remaining unchecked roadmap boxes are confined to the future backlog and the
new Cycle 25 candidate wave
```

Remaining gap table:

| Area | Remaining measured gap | Next action |
| --- | --- | --- |
| Correctness | Operand bundles, address spaces, broader metadata, and EH pads remain fail-closed. | Add verifier slices only when source rows need them. |
| Optimizer quality | ADCE, GVN PRE, SROA, InstCombine, SimplifyCFG, and LICM are still fixture-equivalent subsets. | Pick one pass-specific parity slice with opt-22 fixtures. |
| Debug | Debug salvage is conservative; removed folded instructions may drop locations. | Add salvage only for transforms with source-backed `!dbg` loss. |
| Target/backend | Native handoff covers small x86_64 codegen and object smoke tests only. | Add one bounded backend shape per cycle. |
| Concurrency | Atomics, TLS, syncscope, and inline asm are preserved as barriers, not optimized semantically. | Keep as barriers unless a source-backed optimization requires more. |
| Vector/FP | Vector FP, vector conditions, and target-cost-driven transforms are deferred. | Require APFloat lane semantics and cost policy first. |
| Module/LTO | Bitcode, ThinLTO summaries, import/export, WPD, CFI, and post-link LTO are deferred. | Activate only through the bitcode/LTO decision criteria. |
| Upstream integration | The project is a source-backed replacement experiment, not an LLVM replacement. | Keep inventories, fixtures, and readiness scripts as the integration artifact. |

Archive and next wave:

```text
docs/roadmap/historical/completed_finish_cycles_01_24_audit.md
docs/roadmap/historical/finish_cycles_01_25_archive/25_next_evidence_backed_gap_wave.md
```
