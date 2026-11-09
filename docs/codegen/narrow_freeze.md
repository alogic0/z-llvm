# Integer and pointer freeze contract

`lowerFreeze` aliases a named scalar integer or pointer's existing location. Defined input
bits are unchanged, repeated uses share that location, and the operation emits
no machine instruction or flag write.

Logical widths i1 through i32 use the existing 32-bit argument, scratch or EAX
carrier, or a scalar spill slot. The carrier may contain unrelated upper bits;
consumers retain their existing width interpretation. In particular, freeze
does not mask the carrier and damage a wider live alias. Existing i32/i64/i128
admission and their physical location checks are preserved. Pointer aliases
also retain compatible 64-bit registers, spills, frame and derived addresses,
and readonly-table locations. Named null pointers retain their zero bits.
Other integer widths, incompatible locations, FP values and unresolved values still reject.
Explicit undef/poison literals require a separate semantics decision.
Literal null and global addresses remain outside the named-alias contract.

The pinned Zig-produced compiler input demonstrates i1, i3, i8, i10 and i16
freezes. The LLVM 22 primary sources map this behavior as follows:

- `llvm/docs/LangRef.rst`, “freeze” instruction: a defined input is unchanged;
  undef/poison require one arbitrary but stable value for each freeze.
- `llvm/lib/CodeGen/SelectionDAG/SelectionDAGBuilder.cpp`, `visitFreeze`:
  compute the original value types, apply `ISD::FREEZE`, and merge the parts.

The source checkout is `../llvm-project-22/`; validation retains its revision
and hashes of these files. Freeze can be introduced by LLVM optimization, so
the actual pinned compiler module is the width evidence rather than a
one-to-one Zig AIR opcode mapping.

The rejection observer copies the final private freeze type, result and
operand origin/location into the diagnostic census before speculative state
is freed. It changes no selection outcome. The diagnostic CLI accepts a JSON
list of canonical function names prefixed by `@`; it rejects empty, invalid,
duplicate or missing names instead of silently reporting a partial group.

Executable units cover dirty upper bits, wider aliases, repeated freezes,
boolean branches and rollback. The mandatory native `narrow_freeze` population
adds loads, PHIs, spills, parameters and values crossing clobbering calls,
compared with an independent C oracle and LLVM in all release modes through
both routes. The [plan](../plans/2026-11-08-narrow-freeze.md) records acceptance.

The [pointer extension](../evidence/scalar_comparisons_pointer_freeze.md) adds
seven native functions covering parameters, GEPs, PHIs, calls, frame storage,
arrays and readonly tables. The alias operation still emits no instruction
or flag write; consumers retain their typed address and width interpretation.
