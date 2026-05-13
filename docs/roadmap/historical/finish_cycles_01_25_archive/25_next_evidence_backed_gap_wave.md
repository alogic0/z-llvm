# Cycle 25: Evidence-Backed Gap Wave

## Goal

Use the Cycle 24 finish audit to select the next bounded implementation work
from measured gaps instead of broad LLVM parity claims.

## Candidate Slices

- Correctness: tighten remaining verifier gaps for operand bundles, address
  spaces, EH pads, and malformed metadata that appear in source rows.
- Optimizer quality: choose one pass-specific parity gap from the current
  fixture table, preferably ADCE control dependence, GVN PRE, or SROA slice
  rewriting.
- Debug: add a bounded debug-info salvage slice only where transforms remove or
  replace instructions carrying `!dbg`.
- Target/backend: extend handoff validation for one non-leaf x86_64 or AArch64
  codegen shape.
- Concurrency: keep atomics, TLS, syncscope, and inline asm as barriers unless a
  source-backed optimization requires precise semantics.
- Vector/FP: activate vector FP or vector-condition select only after APFloat
  lane semantics and target-cost policy are ready.
- Module/LTO: keep bitcode and ThinLTO deferred unless a concrete handoff
  fixture activates `docs/bitcode/lto_compatibility_decision.md`.

## Activation Rule

Pull exactly one candidate into the next active roadmap cycle, add fixtures or
source-backed evidence first, then implement and commit that slice.
