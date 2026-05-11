# Cycle 23: Native Backend And AIR Handoff Mapping

## Goal

Map optimizer results back toward Zig-owned AIR/native-backend concepts, so this
project remains aligned with Zig's LLVM-removal path instead of becoming a
standalone LLVM clone.

## Source Anchors

- Docs: Zig-aligned LLVM removal plan, native backend handoff notes
- Local code: `src/air_bridge.zig`, codegen handoff validation
- Zig upstream: AIR, Liveness, native backend MIR concepts
- Accepted optimizer fixtures

## Plan

- [x] Inventory local optimizer results that could be represented in Zig-owned
      IR or AIR-adjacent facts.
- [x] Map scalar simplification, mem2reg/SROA facts, branch simplification, and
      loop scalar facts to handoff concepts.
- [x] Identify results that should not be handed off because they are
      LLVM-IR-specific.
- [x] Add docs for the boundary between comparison IR and future Zig-owned IR.
- [x] Keep production Zig integration out of scope unless requested upstream.
- [x] Add validation examples that show optimized semantics are backend-neutral.

## Exit Criteria

- [x] Handoff docs list concrete optimizer facts and their Zig-owned equivalents.
- [x] LLVM-only assumptions are marked.
- [x] The next roadmap wave can prioritize Zig-aligned integration work.

## Completed Slice

- Expanded the AIR/Liveness handoff map for scalar folds, mem2reg, SROA,
  branch pruning, DCE/ADCE, DSE, GVN/EarlyCSE, LICM, and LoopInfo.
- Marked PHI spelling, alloca promotion mechanics, GEP slicing, metadata graph
  legality, pass names, and MemorySSA storage as LLVM-only comparison details.
- Kept production Zig integration out of scope and validated the current
  backend-neutral smoke set through the handoff validation script.
