# Epic 8: Native Backend Handoff Study

## Goal

Document where this repository's LLVM-compatible IR and optimizer work can help
Zig's native backends without becoming a competing full backend project.

## Inputs

- `zig_upstream_llvm_removal_path.md`
- `zig_aligned_llvm_removal_plan.md`
- Zig native backend architecture notes from local source analysis
- Existing bounded codegen and MC/object epics

## Plan

- [ ] Identify Zig-owned backend boundaries relevant to this project:
      LLVM IR emission, AIR, Liveness, codegen, object emission, debug info,
      and linker handoff.
- [ ] Document which local IR facts are useful before handoff:
      verified CFG, dominance, canonical allocas, simplified branches, memory
      effects, loop structure, and target data layout.
- [ ] Map each local optimizer output to a possible Zig-native consumer or
      validation use.
- [ ] Mark codegen/MC/object work as:
      validation-only, handoff study, debug-info study, or out of scope.
- [ ] Add comparison examples where optimized IR changes would need equivalent
      AIR/native-backend behavior.
- [ ] Define when a local backend experiment is justified:
      it validates semantics, object/debug boundaries, or target layout
      assumptions needed by optimizer work.

## Deliverables

- [ ] Native backend handoff doc.
- [ ] Table mapping local IR facts to Zig backend responsibilities.
- [ ] Updated links from existing codegen/MC epics.
- [ ] Out-of-scope table for full backend replacement work.

## Exit Criteria

- [ ] The repo has a clear role beside Zig's native backends.
- [ ] Backend experiments are bounded and justified.
- [ ] Optimizer work can explain how it helps Zig's LLVM-removal path.
