# Zig LLVM Removal Roadmap

This document is the main roadmap entrypoint. The initial Zig LLVM removal
epics are complete and archived under `roadmap/historical/completed_epics/`.
The active roadmap is now the optimizer parity cycle plan. Completed cycle
entries mean the planned fixture-equivalent slice is closed, not that the full
LLVM pass is completely reproduced.

The purpose is to keep the project aligned with Zig's upstream LLVM-removal
path:

```text
completed foundation epics
  -> ADCE control-flow parity slice
  -> SCCP sparse lattice parity slice
  -> EarlyCSE memory-aware parity slice
  -> GVN value numbering parity slice
  -> SROA slice/partition model slice
  -> GlobalDCE/globals graph parity slice
  -> shared memory legality upgrade slice
```

## Completed Foundation Epics

- [x] [Epic 1: Zig LLVM Dependency Inventory](roadmap/historical/completed_epics/01_zig_llvm_dependency_inventory.md)
- [x] [Epic 2: Zig-Emitted IR Corpus](roadmap/historical/completed_epics/02_zig_emitted_ir_corpus.md)
- [x] [Epic 3: LLVM-Compatible IR Verifier Foundation](roadmap/historical/completed_epics/03_llvm_compatible_ir_verifier_foundation.md)
- [x] [Epic 4: Mandatory Canonicalization Passes](roadmap/historical/completed_epics/04_mandatory_canonicalization_passes.md)
- [x] [Epic 5: Memory And Side-Effect Semantics](roadmap/historical/completed_epics/05_memory_and_side_effect_semantics.md)
- [x] [Epic 6: Scalar Optimization Pipeline](roadmap/historical/completed_epics/06_scalar_optimization_pipeline.md)
- [x] [Epic 7: Loop Optimization Pipeline](roadmap/historical/completed_epics/07_loop_optimization_pipeline.md)
- [x] [Epic 8: Native Backend Handoff Study](roadmap/historical/completed_epics/08_native_backend_handoff_study.md)
- [x] [Epic 9: Optional LLVM Bitcode, Debug, And LTO Tracks](roadmap/historical/completed_epics/09_optional_bitcode_debug_lto_tracks.md)

## Completed Cycle Slices

- [x] [Cycle 1: ADCE Control-Flow Parity Slice](roadmap/01_adce_control_flow_parity_cycle.md)
- [x] [Cycle 2: SCCP Sparse Lattice Parity Slice](roadmap/02_sccp_sparse_lattice_parity_cycle.md)
- [x] [Cycle 3: EarlyCSE Memory-Aware Parity Slice](roadmap/03_earlycse_memory_aware_parity_cycle.md)
- [x] [Cycle 4: GVN Value Numbering Parity Slice](roadmap/04_gvn_value_numbering_parity_cycle.md)
- [x] [Cycle 5: SROA Model Slice](roadmap/05_sroa_real_model_cycle.md)
- [x] [Cycle 6: GlobalDCE And Globals Graph Parity Slice](roadmap/06_globaldce_globals_graph_parity_cycle.md)
- [x] [Cycle 7: Memory Legality Upgrade Slice](roadmap/07_memory_legality_upgrade_cycle.md)

## Operating Rule

Do not implement these as one giant milestone. Select one cycle, extract a
day-sized slice into `next_steps.md` or the active next-steps file,
then close that slice with fixtures, docs, and comparison notes.

## Optimizer Parity Rule

Optimizer cycles use `roadmap/llvm_algorithm_parity_gap_closure_plan.md` as a
quality rubric, not as a global blocker. A local pass should not be described
as reproduced just because a same-named pass exists.

Every optimizer pass should carry one status:

- `placeholder`: known pass, not implemented.
- `LLVM-shaped subset`: follows the broad LLVM pass structure for the local
      IR surface.
- `fixture-equivalent`: matches LLVM 22 for listed fixtures.
- `algorithm-parity target`: implements the same core LLVM data structures
      and algorithm flow for the supported IR surface.

For each pass, record LLVM source files, entry points/classes, required
analyses, core data structures, unsupported LLVM behavior, and exact fixtures
compared with `opt-22`.
