# Next Steps

## Active Cycle

Future checklist items must include upstream LLVM mapping before they can be marked complete. See [development_cycle.md](development_cycle.md).

### Cycle 4: LLVM Comparison and Multi-Block Promotion

- [x] Add an `opt-22` comparison runner that executes `z_llvm`, executes LLVM `opt-22`, normalizes both outputs, and diffs each fixture.
- [x] Extend IR normalization to strip LLVM-only comparison noise: `ModuleID`, `source_filename`, simple inferred memory `align N`, and harmless trailing whitespace.
- [x] Add comparison docs and fixture metadata so every fixture records the LLVM pass name, `z_llvm` pass name, and known acceptable normalization differences.
- [x] Extend dominator analysis with immediate dominator or dominance-frontier support needed by LLVM `PromoteMemToReg` phi placement, with upstream mapping.
- [ ] Implement multi-block `mem2reg` phi insertion for one promotable stack slot using CFG predecessors and dominance-frontier placement.
- [ ] Implement the `mem2reg` rename pass over the dominator tree for promoted stack-slot values, including phi incoming updates.
- [ ] Add LLVM `opt-22` comparison fixtures for multi-block `mem2reg` cases: if/else merge, loop-carried value, and unreachable predecessor cleanup.

## Completed Cycles

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
- `early-cse` subset: documented in [passes/early_cse.md](passes/early_cse.md).
- `mem2reg` single-block subset: documented in [passes/mem2reg.md](passes/mem2reg.md).
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
