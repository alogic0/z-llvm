# Cycle 05: Optimizer Quality Burn-Down

## Goal

Close exactly one measured optimizer-quality gap from the finish table, using
source-backed or opt fixture evidence rather than broad pass parity.

## Evidence

The finish table names SROA slice rewriting, GVN PRE, and ADCE control
dependence as preferred quality candidates. No pass currently claims full LLVM
algorithm parity.

## Plan

- [x] Pick one pass-specific gap from measured fixture deltas:
      SROA slice rewriting, GVN PRE, or ADCE control dependence.
- [x] Record LLVM source mapping, entry points, required analyses, and local
      unsupported behavior before implementation.
- [x] Add accepted and rejected fixtures for the selected gap.
- [x] Compare equivalent fixtures against `opt-22`.
- [x] Document local-only conservative differences when LLVM is broader.
- [x] Update the selected pass doc, analysis docs, fixture table, and finish
      table.
- [x] Run `bash scripts/run_readiness_checks.sh` and record the summary.

## Exit Criteria

- [x] One optimizer-quality gap is smaller and measured.
- [x] The pass status is not overstated beyond fixture evidence.
- [x] The next optimizer-quality candidate remains separate from this cycle.

## Completed Slice

Cycle 05 selected SROA pointer-field scalarization for simple aggregate allocas
when module DataLayout provides pointer size and alignment. The accepted
fixture `sroa_struct_ptr_field` compares with `opt-22`; the rejected
`sroa_struct_ptr_field_no_layout_reject` fixture documents the local
conservative no-DataLayout boundary.

Readiness summary:

```text
ok manifest rows=37 optimizer_input=30
summary accepted=30 unsupported=0 future=4 debug-info-only=0
ok readiness checks
```
