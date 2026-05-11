# Cycle 01: Finish Criteria and Gap Burn-Down

## Goal

Make "finished" concrete for this project, then burn down the remaining gaps
from measured corpus, optimizer, verifier, debug, and handoff evidence instead
of adding broad LLVM-parity work.

This cycle does not mean the project is a full LLVM clone. It defines the
finish line for the Zig-aligned replacement experiment this repository can
honestly complete.

## Finish Definition

- [x] Define the minimum Zig-emitted LLVM IR surface that must parse, verify,
      print, and survive the local pipeline.
- [x] Define the required optimizer subset by Zig mode and by accepted corpus
      rows, not by every LLVM pass that exists upstream.
- [x] Define conservative boundaries for debug info, atomics, inline asm,
      vectors, EH, TLS, module flags, and LTO.
- [x] Define the native backend or AIR handoff evidence required before codegen
      work is considered sufficient for this repo.
- [x] Define explicit non-goals: full LLVM clone, full MC/Object replacement,
      full ThinLTO, full debug salvage, target-complete vectorization, and
      broad backend parity.

## Current Evidence Table

- [x] Refresh readiness counts from `bash scripts/run_readiness_checks.sh`.
- [x] Record manifest counts:
      accepted, unsupported, future, debug-info-only, optimizer-input.
- [x] Record opt fixture counts:
      `opt-equivalent`, `local-conservative`, `parse-preserve-only`, and
      unsupported/future.
- [x] Record pass status counts:
      `placeholder`, `LLVM-shaped subset`, `fixture-equivalent`, and
      `algorithm-parity target`.
- [x] Record source-backed corpus rows that still block "finished" status.

## Burn-Down Order

- [x] Corpus closure:
      remove, reduce, or explicitly justify every remaining `future` and
      `unsupported` manifest row.
- [x] Verifier correctness:
      close only the remaining verifier gaps that appear in source-backed rows,
      starting with operand bundles, address spaces, malformed metadata, and EH
      boundary cases.
- [x] Optimizer quality:
      choose exactly one pass-specific parity gap from measured fixture deltas,
      with preference for SROA slice rewriting, GVN PRE, or ADCE control
      dependence.
- [x] Debug boundary:
      add debug salvage only for transforms that remove or replace instructions
      carrying `!dbg`; keep `llvm.dbg.value` and `llvm.dbg.declare`
      conservative until variable-location salvage is represented.
- [x] Handoff proof:
      add one non-trivial native backend or AIR handoff validation shape that
      proves optimized accepted IR can move toward Zig-owned codegen.

## Required Artifacts

- [x] Add a durable finish table under `docs/roadmap/` or `docs/analysis/` that
      links every remaining gap to a source-backed row, opt fixture, or explicit
      non-goal.
- [x] Update `docs/next_steps.md` with the first day-sized slice selected from
      the burn-down order.
- [x] Update `docs/unsupported_ir.md` so unsupported constructs are either
      future work with evidence or declared out of scope.
- [x] Update pass and analysis docs whose status is overstated relative to code
      and fixtures.
- [x] Run the readiness gate and record the exact command output summary.

## Exit Criteria

- [x] The project has a written finish definition that separates required work
      from non-goals.
- [x] Every remaining gap has one of these statuses:
      active next step, later measured blocker, conservative accepted boundary,
      or out of scope.
- [x] `docs/next_steps.md` contains exactly one selected implementation slice
      from this finish burn-down.
- [x] The README points to this active cycle as the current roadmap item.

## Completed Slice

Cycle 01 created
[`finish_gap_burndown_table.md`](finish_gap_burndown_table.md), which defines
the project finish line, records the readiness evidence, lists the remaining
corpus blockers, and assigns every open gap one of the required statuses:
active next step, later measured blocker, conservative accepted boundary, or
out of scope.

The active next implementation slice is corpus closure for the stale
`tiny_scalar_release_small` unsupported row, recorded in `docs/next_steps.md`.
