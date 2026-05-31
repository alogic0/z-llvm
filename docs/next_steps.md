# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Active Cycle

Source roadmap: [ReleaseFast x86_64 Object Milestone 1](roadmap/releasefast_x86_64_object_milestone_1.md#milestone-2)

Replacement goal:
Reduce the next Milestone 2 ReleaseFast x86_64 asm/object blocker: the selected
object gate checks ELF metadata and symbols only, not executable callable ABI
behavior.

Zig evidence:
The Milestone 1 fixtures under
`test/distribution/releasefast_x86_64/inputs/` all expose public aliases such as
`@add`, `@add_wrap`, `@branch_mix`, `@call_chain`, `@comptime_const`,
`@optional_ptr_value`, and `@dense_switch`. Local object generation and selected
alias symbol emission succeed for the subset. The next concrete validation gap
is a link-and-run check for one stable scalar alias, starting with `@add_wrap`
from `integers_add_wrap.ll`.

LLVM fallback removed or reduced:
Add the smallest executable validation harness for `@add_wrap`: emit the local
object, link it with a tiny host harness, and validate deterministic return
values. This reduces the ReleaseFast x86_64 asm/object fallback for the named
Milestone 1 subset only; it does not claim broad linker ownership, startup
runtime, libc replacement, cross-target execution, or exhaustive ABI coverage.

Mode/target/stage row:
`mode=ReleaseFast`, `target=x86_64-linux-gnu`, `stage=asm/object`,
`status=conservative boundary for selected subset`.

Upstream mapping:
Use LLVM object emission, target calling convention lowering, and link-time
handoff as the reference boundary:
`llvm-project-22/llvm/lib/MC/ELFObjectWriter.cpp`,
`llvm-project-22/llvm/lib/CodeGen/AsmPrinter/AsmPrinter.cpp`, and
`llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td`.

Known boundary:
Implement only an `@add_wrap` executable check for the selected ReleaseFast
x86_64 object. Do not generalize to pointer arguments, calls, switch behavior,
global data, cross-compilation execution, or target-complete ABI validation in
this slice.

Validation gate:
Run `bash scripts/run_distribution_object_m1.sh` and
`bash scripts/run_handoff_validation.sh`.

Commit:
Use the commit policy after the lowering, fixture classification, docs, and
validation gate are complete.
