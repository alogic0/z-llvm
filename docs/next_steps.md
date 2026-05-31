# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [ReleaseFast x86_64 Object Milestone 1](roadmap/releasefast_x86_64_object_milestone_1.md#milestone-2)

Replacement goal:
Reduce the next Milestone 2 ReleaseFast x86_64 asm/object blocker: selected
public Zig aliases are not emitted into the local ELF object symbol table.

Zig evidence:
The Milestone 1 fixtures under
`test/distribution/releasefast_x86_64/inputs/` all expose public aliases such as
`@add`, `@add_wrap`, `@branch_mix`, `@call_chain`, `@comptime_const`,
`@optional_ptr_value`, and `@dense_switch`. Local object generation succeeds for
the selected subset, but the validation-only object writer emits only function
symbols such as `switch_control.dense_switch`.

LLVM fallback removed or reduced:
Add ELF symbol-table alias coverage for selected aliases whose targets are
locally emitted functions. This reduces the ReleaseFast x86_64 asm/object
fallback enough to start executable callable ABI checks for the named Milestone
1 subset only; it does not claim relocatable aliases, weak aliases, COMDAT,
global data, linker behavior, or broad export policy.

Mode/target/stage row:
`mode=ReleaseFast`, `target=x86_64-linux-gnu`, `stage=asm/object`,
`status=conservative boundary for selected subset`.

Upstream mapping:
Use LLVM object emission and symbol handling as the reference boundary:
`llvm-project-22/llvm/lib/MC/ELFObjectWriter.cpp`,
`llvm-project-22/llvm/lib/MC/MCELFStreamer.cpp`, and
`llvm-project-22/llvm/lib/CodeGen/AsmPrinter/AsmPrinter.cpp`.

Known boundary:
Implement only selected aliases that target functions emitted in the same local
object. Do not generalize to data aliases, aliases requiring relocations, weak
aliases, COMDAT, visibility policy, or target-complete symbol binding.

Validation gate:
Run `bash scripts/run_distribution_object_m1.sh` and
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
