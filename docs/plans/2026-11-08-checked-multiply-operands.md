# Checked multiply operands

Status: complete and accepted at `29e034a7`.
Baseline: `bf2c844d`, with accepted compiler selection 7,657/8,928 and
runtime selection 284/455 at `a9e9c0f1`.

The 59 observed `composed-block-smulo-i64-rhs` failures all contain an unsigned
`llvm.umul.with.overflow.i64` call with a spilled left operand and constant right
operand. Argument range facts prevent the existing optional literal rewrite
from admitting these calls. Preserve those facts and support the operand at the
shared transfer boundary.

1. Completed: extend checked scalar literal transfers to scratch registers, reusing the
   existing bit-pattern validation and register preservation rules.
2. Completed: cover full-width constants, signed and unsigned overflow, spills, aliases,
   neighboring live values, surrounding calls and failed-selection rollback.
   Register an independent native population and exercise direct/release routes
   in Fast/Safe/Small.
3. Completed: replay the original complete compiler and runtime inputs. Preserve every
   prior selection and report actual additions and later rejections.
4. Completed: freeze source and compiler identities, run units and structural checks in
   Debug/ReleaseSafe and the required cumulative integration gate, then publish
   evidence. Keep the twelve-function cohort, ratchet 130 and all prior native
   populations unchanged.

Tier-3 trigger: this changes shared operand materialization and preservation
around the fixed RAX/RDX multiply sequence. Existing integration results predate
this behavior and cannot validate it. Use the authenticated quoted-symbol AIR
cache; no fresh/cache pair is required for this code-only change.

Evidence root: `local-state/validations/checked-multiply-20261108/`.
The exact serial command and trigger are retained in `tier3-command.txt`.
Prior evidence, compiler snapshots, original inputs, AIR payloads and all
thirteen scratch files are preserved; no manual cache retirement or archives
were performed.

Upstream mapping: Zig `src/codegen/llvm/FuncGen.zig` dispatches
`.mul_with_overflow` through `airOverflow` to signed/unsigned overflow intrinsics.
Unsigned overflow is a nonzero upper half of the full-width product; signed
overflow compares that upper half with the low half's sign extension. The
existing arithmetic implementation and typed call envelope remain authoritative.
See [the upstream mapping and transfer contract](../codegen/checked_multiply_operands.md).

All 1,983 units and 23 structural checks pass in Debug and ReleaseSafe. The
eight-function native population passes all three modes and both routes with
frozen Debug and ReleaseFast builds: 12,288 local observations and 6,144 LLVM
references per build. All nine readiness commands pass.

Compiler selection is 7,713/8,928, with 56 additions and no lost successes;
runtime remains 284/455. All 59 targeted operand failures advance: 56 functions
select, two reach freeze-width limits and one reaches a PHI destination limit.
Production replays match both complete censuses and pass complete event audits.

The full serial run passes all 17 gates and 63 native populations. All 62 prior
native records and all 36 core selected-object/descriptor/observation records
are preserved. All five fixed programs, both input corpora and all 54 core fault
controls pass. The source snapshot and all compiler/frontend/input/scratch
hashes verify. The retained manifest authenticates 461 artifacts.
See the [evidence](../evidence/checked_multiply_operands.md) and
[acceptance record](../evidence/checked_multiply_operands_acceptance_20261108.json).

The first native development invocation exposed the existing
literal-accumulator boundary in an additional constant-left test. Its report is
retained. That fixture was corrected to exercise a spilled/select left value and
a high-bit right literal, matching this slice; accumulator admission is unchanged.
