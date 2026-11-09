# Checked multiply operands

Status: implementation in progress, authorized by the current user request.
Baseline: `bf2c844d`, with accepted compiler selection 7,657/8,928 and
runtime selection 284/455 at `a9e9c0f1`.

The 59 observed `composed-block-smulo-i64-rhs` failures all contain an unsigned
`llvm.umul.with.overflow.i64` call with a spilled left operand and constant right
operand. Argument range facts prevent the existing optional literal rewrite
from admitting these calls. Preserve those facts and support the operand at the
shared transfer boundary.

1. Extend checked scalar literal transfers to scratch registers, reusing the
   existing bit-pattern validation and register preservation rules.
2. Cover full-width constants, signed and unsigned overflow, spills, aliases,
   neighboring live values, surrounding calls and failed-selection rollback.
   Register an independent native population and exercise direct/release routes
   in Fast/Safe/Small.
3. Replay the original complete compiler and runtime inputs. Preserve every
   prior selection and report actual additions and later rejections.
4. Freeze source and compiler identities, run units and structural checks in
   Debug/ReleaseSafe and the required cumulative integration gate, then publish
   evidence. Keep the twelve-function cohort, ratchet 130 and all prior native
   populations unchanged.

Tier-3 trigger: this changes shared operand materialization and preservation
around the fixed RAX/RDX multiply sequence. Existing integration results predate
this behavior and cannot validate it. Use the authenticated quoted-symbol AIR
cache; no fresh/cache pair is required for this code-only change.

Evidence root: `local-state/validations/checked-multiply-20261108/`.
Record the exact serial command there before launching it. Preserve prior
evidence, compiler snapshots, original inputs, AIR payloads and scratch files.
The historical worker inbox concerns an earlier cohort objective; the current
user request and current handoff authorize this slice and its validation.

Upstream mapping: Zig `src/codegen/llvm/FuncGen.zig` dispatches
`.mul_with_overflow` through `airOverflow` to signed/unsigned overflow intrinsics.
Unsigned overflow is a nonzero upper half of the full-width product; signed
overflow compares that upper half with the low half's sign extension. The
existing arithmetic implementation and typed call envelope remain authoritative.
See [the upstream mapping and transfer contract](../codegen/checked_multiply_operands.md).

Development results: all 1,983 units and 23 structural checks pass in Debug and
ReleaseSafe. The
new eight-function native population passes all three modes on both direct and
release routes with the Debug compiler (12,288 local observations and 6,144
LLVM reference observations). The runtime census preserves all 284 selections.
The ReleaseFast compiler, readiness and the complete compiler census are in
progress; cumulative integration is still pending.

The first native development invocation deliberately exposed the existing
literal-accumulator boundary in an additional constant-left test. Its report is
retained. That fixture was corrected to exercise a spilled/select left value and
a high-bit right literal, matching this slice; accumulator admission is unchanged.
