# Next Steps

## Active Cycle

Future checklist items must include upstream LLVM mapping before they can be marked complete. See [development_cycle.md](development_cycle.md).

No active cycle is currently open.

## Completed Cycles

### Cycle 12: Memory Legality Foundation

Goal: make memory operations explicit enough that future optimization passes can
reject unsafe transforms by default and later opt into proven-safe memory motion.
This is a bounded vertical slice: IR surface, legality API, pass integration,
docs, and fixture coverage should land together without trying to model full
LLVM memory optimization yet.

- [x] Parse, print, verify, and normalize `align N` and `volatile` for `load` and `store`, with upstream LLVM mapping.
- [x] Recognize narrow atomic memory forms only far enough to classify them as unsupported/atomic barriers or reject them with a clear parser error; do not model ordering, `syncscope`, `cmpxchg`, or `atomicrmw` yet.
- [x] Add a small memory-effect classification API for IR instructions: no memory access, readonly load, memory write, volatile/atomic barrier, and unknown/unsupported memory behavior.
- [x] Add an alias/mod-ref foundation document and code scaffold that can answer only conservative questions today: `no_alias`/`must_alias` for known stack slots, otherwise `may_alias`; `mod_ref` for loads/stores, otherwise unknown.
- [x] Wire LICM legality through the memory-effect API first, so pure scalar hoisting remains supported, loads remain rejected unless explicitly proven safe later, and stores/volatile/atomic/unknown memory always block hoisting.
- [x] Wire DCE/ADCE/GVN through the same memory-effect API only after the LICM integration proves the API shape, preserving existing behavior while centralizing the contract.
- [x] Add negative fixtures for unsafe memory optimization cases: aligned load not hoisted yet, volatile load rejected, store rejected, atomic/unsupported memory rejected, and unknown pointer aliasing rejected.
- [x] Add accepted fixtures showing that scalar-only LICM/GVN/DCE behavior still works in the presence of unrelated non-hoistable memory instructions.
- [x] Split fixture expectations into `opt-22` equivalent cases and local-only conservative cases.
- [x] Compare every fixture against `opt-22` where LLVM behavior is expected to match; for deliberate conservative differences, add local fixtures and document the upstream behavior gap.
- [x] Update docs for `ir_memory.md`, `analysis/alias.md`, `passes/licm.md`, `passes/gvn.md`, `passes/dce.md`, `passes/adce.md`, `testing.md`, `unsupported_ir.md`, and the inventory current-coverage section.
- [x] Run `zig build test` and `bash scripts/compare_opt.sh` before marking the cycle complete.

### Cycle 11: Loop Optimization Foundation 2

- [x] Make `LoopInfo` APIs explicit for loop `header`, `latch`, `preheader`, `exitingBlocks`, `exitBlocks`, and `contains`, with upstream LLVM mapping to `Loop`/`LoopInfo` query APIs.
- [x] Document canonical loop shape: preheader, header, latch, exiting blocks, exit blocks, dedicated exits, and the canonical forms this project currently requires.
- [x] Harden LICM legality so the implemented pass only hoists pure scalar `binary`, `icmp`, and `select` instructions, while documenting that loads, stores, calls, atomics, volatile operations, and unknown memory are not hoistable yet.
- [x] Add negative LICM fixtures for no preheader, variant operands, side-effecting store, memory load, and unsupported noncanonical loop shapes such as multi-latch loops if still unsupported.
- [x] Add an LICM SSA-validity fixture framed around preserving dominance of all uses after hoisting.
- [x] Compare accepted and rejected LICM behavior against `opt-22`.
- [x] Document the distinction needed by later loop passes: an exiting block is inside the loop with a successor outside the loop, while an exit block is outside the loop and receives control from the loop.

### Cycle 10: Documentation Freshness and IR Module Split

- [x] Update `unsupported_ir.md` so supported instructions, predicates, terminators, and next unsupported areas match the current IR implementation.
- [x] Update `testing.md` and `inventory/zig_llvm_api_inventory.md` so current fixtures and phase-zero optimizer coverage include the Cycle 6-9 work.
- [x] Confirm scratch documentation state and keep `docs/tmp` out of tracked project documentation unless it is classified deliberately.
- [x] Split `src/ir/core.zig` into core data structures plus parser, printer, and verifier modules while preserving the public `ir.Module` API.
- [x] Verify the split and docs refresh with `zig build test` and `bash scripts/compare_opt.sh`.

### Cycle 9: Scalar and Loop Optimizer Refinement

- [x] Extend `icmp` parsing and `instcombine` folding for signed and unsigned integer predicates, with upstream LLVM mapping and `opt-22` fixtures.
- [x] Add `instcombine` commutative binary canonicalization so constants move to the RHS for supported commutative operators, with upstream LLVM mapping and `opt-22` fixtures.
- [x] Extend `simplifycfg` to thread empty unconditional branch blocks without phi nodes, with upstream LLVM mapping and `opt-22` fixtures.
- [x] Extend LoopInfo with preheader and exit-block queries needed by loop passes, with upstream LLVM mapping and unit tests.
- [x] Add an LICM foundation pass that hoists pure loop-invariant instructions to an existing preheader, with upstream LLVM mapping and `opt-22` fixtures.

### Cycle 8: Optimization Pipeline Expansion

- [x] Add an SROA foundation slice for zero-offset alloca forwarding, with upstream LLVM mapping and `opt-22` fixtures.
- [x] Extend `instcombine` and IR parsing for simple bitwise and shift identities, with upstream LLVM mapping and `opt-22` fixtures.
- [x] Add a GVN-style cross-block expression elimination slice using dominator information, with upstream LLVM mapping and `opt-22` fixtures.
- [x] Add an ADCE foundation pass for aggressively removing unused side-effect-free instruction chains, with upstream LLVM mapping and `opt-22` fixtures.
- [x] Add LoopInfo-style natural loop analysis over dominator backedges, with upstream LLVM mapping and unit tests.

### Cycle 7: Zig LLVM API Inventory and IR Structure

- [x] Create `docs/inventory/zig_llvm_api_inventory.md` and map Zig's real LLVM backend entry points to replacement owner components.
- [x] Classify the current optimizer work as phase-zero infrastructure, with the largest missing LLVM dependencies called out explicitly.
- [x] Add the inventory-backed owner map for future `src/target/`, `src/codegen/`, `src/mc/`, `src/debug/`, and `src/bitcode/` work without creating empty implementation directories yet.
- [x] Start splitting the IR module by moving the implementation behind a compatibility facade at `src/ir.zig` and `src/ir/core.zig`.
- [x] Verify the refactor and inventory cycle with the existing Zig tests and `opt-22` comparison fixtures.

### Cycle 6: Select and Unreachable Control Flow

- [x] Add `unreachable` terminator parsing, printing, verification, CFG handling, and upstream LLVM mapping.
- [x] Add `select` instruction parsing, printing, verification, def-use tracking, and upstream LLVM mapping.
- [x] Extend `instcombine` to fold simple `select` forms: constant condition and identical arms.
- [x] Extend value replacement paths across `select` so `instcombine`, `simplifycfg`, and `mem2reg` keep select operands current.
- [x] Add `opt-22` comparison fixtures for `select` folding and `unreachable` CFG simplification.

### Cycle 5: Mem2Reg Completeness and Pointer IR Foundation

- [x] Add `undef` value parsing, printing, verification, normalization, and upstream mapping for LLVM `UndefValue`/poison-adjacent behavior.
- [x] Extend `mem2reg` to handle uninitialized loads with LLVM-compatible `undef` replacement, plus `opt-22` comparison fixtures.
- [x] Extend `mem2reg` to promote multiple independent stack slots in one pass run, preserving deterministic LLVM-compatible phi naming.
- [x] Add promotability checks and docs for rejected stack slots: escaped allocas, stores of the slot pointer, non-load/store users, and unsupported alloca forms.
- [x] Add basic `getelementptr` parsing, printing, verification, and upstream mapping needed for pointer-derived memory operations.
- [x] Extend alias analysis from distinct direct `alloca` pointers to simple `getelementptr`-derived stack objects, documenting the BasicAA mapping and known conservative fallbacks.
- [x] Add `opt-22` comparison fixtures for rejected mem2reg cases and simple GEP-backed memory IR normalization.

### Cycle 4: LLVM Comparison and Multi-Block Promotion

- [x] Add an `opt-22` comparison runner that executes `z_llvm`, executes LLVM `opt-22`, normalizes both outputs, and diffs each fixture.
- [x] Extend IR normalization to strip LLVM-only comparison noise: `ModuleID`, `source_filename`, simple inferred memory `align N`, and harmless trailing whitespace.
- [x] Add comparison docs and fixture metadata so every fixture records the LLVM pass name, `z_llvm` pass name, and known acceptable normalization differences.
- [x] Extend dominator analysis with immediate dominator or dominance-frontier support needed by LLVM `PromoteMemToReg` phi placement, with upstream mapping.
- [x] Implement multi-block `mem2reg` phi insertion for one promotable stack slot using CFG predecessors and dominance-frontier placement.
- [x] Implement the `mem2reg` rename pass over the dominator tree for promoted stack-slot values, including phi incoming updates.
- [x] Add LLVM `opt-22` comparison fixtures for multi-block `mem2reg` cases: if/else merge, loop-carried value, and unreachable predecessor cleanup.

### Cycle 3: Memory IR and Promotion Foundation

- [x] Add `alloca`, `load`, and `store` parsing, printing, verification, and upstream mapping.
- [x] Extend def-use and DCE side-effect handling for memory operations.
- [x] Add alias-analysis scaffolding for stack slots and document the LLVM BasicAA mapping.
- [x] Implement a first `mem2reg`/PromoteMemToReg subset for single-block stack slots.
- [x] Add `opt` comparison fixtures for the memory IR and `mem2reg` subset.

### Cycle 2: Branch, CFG, Dominators, and Early CSE

- [x] Add `icmp` instruction parsing, printing, verification, and tests.
- [x] Add `phi` instruction parsing, printing, verification, and tests.
- [x] Extend `simplifycfg` to update/remove trivial phi inputs.
- [x] Add an explicit CFG analysis helper for predecessors and successors.
- [x] Add dominator tree analysis for reachable blocks.
- [x] Implement an `early-cse` subset for repeated pure expressions.

### Cycle 1: Initial IR and Scalar Cleanup

- [x] Add LLVM IR normalization and golden-output comparison.
- [x] Expand the parser to support multiple functions and basic branches.
- [x] Implement `simplifycfg` for trivial branch and unreachable-block cleanup.
- [x] Add `opt` comparison fixtures for `instcombine`, `dce`, and `simplifycfg`.
- [x] Add def-use maintenance instead of recomputing usage ad hoc.
- [x] Document unsupported LLVM IR constructs and parser errors.

## Reproduced LLVM Algorithms

Track each reproduced LLVM algorithm here as it lands:

- `instcombine` subset: documented in [passes/instcombine.md](passes/instcombine.md).
- `dce` subset: documented in [passes/dce.md](passes/dce.md).
- `simplifycfg` subset: documented in [passes/simplifycfg.md](passes/simplifycfg.md).
- def-use use-count subset: documented in [analysis/def_use.md](analysis/def_use.md).
- CFG successor/predecessor subset: documented in [analysis/cfg.md](analysis/cfg.md).
- alias analysis stack-slot subset: documented in [analysis/alias.md](analysis/alias.md).
- dominator analysis subset: documented in [analysis/dominator.md](analysis/dominator.md).
- LoopInfo natural-loop subset: documented in [analysis/loop_info.md](analysis/loop_info.md).
- `early-cse` subset: documented in [passes/early_cse.md](passes/early_cse.md).
- `mem2reg` single-block subset: documented in [passes/mem2reg.md](passes/mem2reg.md).
- SROA zero-offset alloca forwarding subset: documented in [passes/sroa.md](passes/sroa.md).
- GVN dominating-expression subset: documented in [passes/gvn.md](passes/gvn.md).
- ADCE dead-chain subset: documented in [passes/adce.md](passes/adce.md).
- LICM pure-instruction hoisting subset: documented in [passes/licm.md](passes/licm.md).
- memory IR subset: documented in [ir_memory.md](ir_memory.md).

## Completed Step Notes

- LLVM IR normalization and golden-output comparison is infrastructure, not an optimization pass. It is now used to check the implemented `instcombine` and `dce` subsets against normalized expected LLVM-compatible IR.
- Parser support for multiple functions plus `br` and conditional `br` is infrastructure for reproducing LLVM's `simplifycfg` algorithm.
- `simplifycfg` now folds constant conditional branches and removes blocks unreachable from function entry.
- `opt` comparison fixtures now exist for `instcombine`, `dce`, and `simplifycfg`; `opt` was not available in this environment, so the committed verification covers the `z_llvm` side of each fixture.
- DCE now uses a shared def-use use-count analysis and decrements operand uses as instructions are removed.
- Unsupported LLVM IR constructs and current parser errors are tracked in [unsupported_ir.md](unsupported_ir.md).
- `icmp eq/ne` parsing, printing, verification, and constant folding are now supported.
- `phi` parsing, printing, verification, and def-use tracking are now supported for the current integer/value subset.
- `simplifycfg` now prunes phi incoming values from removed unreachable predecessors and replaces trivial phis.
- CFG analysis now provides successor/predecessor lists and entry-block reachability; `simplifycfg` uses it for unreachable block removal.
- Dominator analysis now computes reachable-block dominance queries over the CFG.
- `early-cse` now eliminates repeated pure binary and `icmp` expressions within one basic block.
- Memory IR now parses, prints, and verifies `alloca`, `load`, and `store` over opaque `ptr`.
- DCE now removes unused loads while preserving stores as memory writes, with def-use counts for load/store operands.
- Alias analysis now classifies identical stack-slot pointers as `must_alias`, distinct `alloca` results as `no_alias`, and unknown pointers as `may_alias`.
- `mem2reg` now promotes direct load/store users of a single-block `alloca` when every load is dominated by a prior store in the same block.
- `opt` comparison fixtures now cover memory-aware DCE and the single-block `mem2reg` subset.
- IR normalization now strips LLVM comparison noise such as `source_filename` and simple inferred memory alignment.
- `scripts/compare_opt.sh` now runs mapped fixtures through both `z_llvm` and `opt-22`, normalizes both outputs, and diffs the results.
- `test/opt/fixtures.tsv` now records each comparison fixture's `z_llvm` pass, LLVM pass, expected output, and normalization notes.
- Dominator analysis now exposes immediate dominators and dominance-frontier sets for mem2reg phi placement.
- `mem2reg` now promotes one multi-block stack slot with dominance-frontier phi insertion and a dominator-tree rename walk.
- `opt-22` comparison fixtures now cover multi-block `mem2reg` if/else, loop-carried, and unreachable-predecessor cases.
- `undef` values now parse, print, verify, and normalize as documented in [ir_values.md](ir_values.md).
- `mem2reg` now replaces promoted uninitialized loads with `undef` and compares that behavior against `opt-22`.
- `mem2reg` now keeps promoting independent stack slots until no promotable alloca remains, with `opt-22` coverage for two promoted slots.
- `mem2reg` promotability rejection is now tested and documented for escaped stack slots and stores of the stack-slot pointer.
- Memory IR now parses, prints, and verifies a first opaque-pointer `getelementptr` form.
- Alias analysis now traces simple `getelementptr` values back to stack-slot roots and distinguishes zero-offset must-alias from conservative same-root may-alias.
- `opt-22` comparison fixtures now cover escaped stack-slot rejection, stored stack-slot pointer rejection, and GEP-backed memory that remains unpromoted.
- Control-flow IR now supports the `unreachable` terminator, documented in [ir_control_flow.md](ir_control_flow.md).
- Select IR now parses, prints, verifies, tracks def-use, and participates in value replacement paths as documented in [ir_select.md](ir_select.md).
- `instcombine` now folds `select` with constant conditions and identical arms.
- `opt-22` comparison fixtures now cover `select` folding and constant-branch simplification to `unreachable`.
- Zig's real LLVM backend API surface is now inventoried in [inventory/zig_llvm_api_inventory.md](inventory/zig_llvm_api_inventory.md), with replacement owner components for IR, AIR lowering, target/ABI, codegen, MC/object, debug, bitcode, sanitizer/coverage, LTO, host CPU, and linker-adjacent bindings.
- The current optimizer is explicitly treated as phase-zero infrastructure rather than the whole LLVM replacement.
- `src/ir.zig` is now a compatibility facade over `src/ir/core.zig`, starting the move toward separate parser, printer, verifier, and core IR files.
- `icmp` now supports signed and unsigned relational predicates with InstCombine constant and same-operand folding.
- InstCombine now canonicalizes constants to the RHS for supported commutative binary operators.
- SimplifyCFG now threads phi-free empty branch blocks and re-runs terminator simplification to collapse same-target branches.
- LoopInfo now reports a unique unconditional preheader and loop exit blocks for natural loops.
- LICM now hoists pure loop-invariant binary, `icmp`, and `select` instructions to an existing preheader.
- `docs/unsupported_ir.md`, `docs/testing.md`, and `docs/inventory/zig_llvm_api_inventory.md` now reflect the Cycle 6-9 optimizer and IR coverage.
- `docs/tmp` is currently empty, so no scratch documentation needed classification or removal.
- `src/ir/core.zig` now keeps core IR data structures and delegates parser, printer, and verifier behavior to dedicated IR modules without changing the public `ir.Module` API.
- LoopInfo now exposes explicit header, latch, preheader, exiting-block, exit-block, and contains queries with upstream `Loop` query mapping.
- LoopInfo docs now define preheader, header, latch, exiting block, exit block, and dedicated exit terminology.
- LICM now skips multi-latch loop headers until the LoopInfo model represents them as one canonical loop.
- LICM legality docs now make the scalar-only boundary explicit: binary, `icmp`, and `select` can hoist; memory, calls, atomics, volatile operations, and unknown effects cannot.
- LICM fixtures now cover variant-operand rejection and dominance-preserving scalar-chain hoisting against `opt-22`.
- Local LICM tests now cover no-preheader, side-effecting store, memory-load, and multi-latch rejection cases that LLVM's fuller pipeline can transform through preheader creation, sinking, or MemorySSA promotion.
- Memory IR now parses, prints, verifies, and preserves load/store `align`, `volatile`, and narrow atomic load/store spelling.
- Unsupported atomic memory operations such as `atomicrmw` and `cmpxchg` now fail with a dedicated parser error.
- `analysis/memory_effect.zig` now centralizes instruction memory classification for scalar passes.
- Alias analysis now includes a conservative mod/ref scaffold for load/store instructions and known stack-slot alias facts.
- LICM, DCE, ADCE, and GVN now use the shared memory-effect classification instead of pass-local side-effect checks.
- `opt-22` memory legality fixtures now cover scalar LICM/GVN/DCE behavior beside volatile memory and volatile load preservation.
- Local conservative memory legality tests now cover aligned-load rejection, atomic-barrier preservation, and unknown pointer aliasing.
