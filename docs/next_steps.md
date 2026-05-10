# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md).

Keep unchecked items as `[ ]`. If an epic item is active, mark it in the epic
with text such as `(in progress: Cycle N in docs/next_steps.md)`.

## Active Cycle

### Cycle 18: MC Assembly Bootstrap

Source epic: [MC/Object Bootstrap Epic](roadmap/mc_object_bootstrap_epic.md)
Epic sections: 1, 2, 3, 4, 5, 8, 9, 10, 11

- [x] Add minimal x86_64 SysV Machine IR for straight-line i32 leaf functions: return constant, return first/second parameter, and add first two parameters.
- [x] Add an assembly printer for that Machine IR with `.text`, `.globl`, function labels, register operands, immediates, and `retq`.
- [x] Add `--emit=asm` and `--target=` CLI support while keeping optimizer IR output as the default path.
- [x] Add unit tests for lowering, unsupported codegen diagnostics, and assembly text output.
- [x] Update MC/codegen docs, `unsupported_ir.md`, `testing.md`, and inventory coverage.
- [x] Run `zig fmt` on touched Zig files, `zig build test`, and `bash scripts/compare_opt.sh`.
