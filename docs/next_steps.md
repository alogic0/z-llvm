# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 22: Target Matrix DataLayout Queries

Source epic: [Target DataLayout and AIR-to-IR Bridge Epic](roadmap/target_datalayout_air_bridge_epic.md)
Epic sections: 1, 7, 8

- [x] Add explicit supported-target recognition for `x86_64-linux-gnu`, `x86_64-linux-musl`, `aarch64-linux-gnu`, and `wasm32-wasi`, with upstream LLVM mapping.
- [x] Preserve LLVM-compatible triples while accepting compact Zig-style `wasm32-wasi` input.
- [x] Add DataLayout query tests for pointer size/alignment and representative integer ABI alignments from `clang-22` emitted LLVM IR.
- [x] Update target docs, inventory coverage, testing notes, unsupported IR notes, and target bridge epic progress.
- [x] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
