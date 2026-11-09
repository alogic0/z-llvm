# Checked multiply operand transfers

The shared `emitValueIntoScratchExcept` path accepts scalar integer literals
for 32- and 64-bit transfers. It validates the signed/unsigned bit-pattern
range before any preservation or instruction mutation, preserves live aliases
of the destination through the existing register-clobber authority, and emits
MOV directly to that register. A 32-bit transfer clears the upper bits. The
transfer preserves RAX and EFLAGS, including a simultaneous accumulator input.

This admits the observed `llvm.umul.with.overflow.i64` calls whose left value
is spilled and whose right value is constant. Argument facts remain on the
source call; no new literal rewrite or name-specific selector is introduced.
The existing fixed-product preservation protects RAX, RDX and RCX operands
before multiplication. Existing selection transactions restore speculative
instructions, owned labels, metadata and dependency state after rejection.

## Upstream mapping

- LLVM `llvm/docs/LangRef.rst`, signed and unsigned multiply-with-overflow
  intrinsic sections: return the wrapped product and an independent `i1`
  overflow result. The [LLVM 22 reference](https://releases.llvm.org/22.1.0/docs/LangRef.html#llvm-umul-with-overflow-intrinsics)
  specifies the unsigned contract.
- LLVM `llvm/lib/Target/X86/X86ISelLowering.cpp`, `LowerMULO` and `LowerXALUO`:
  scalar checked multiplication has fixed-register/result and overflow-flag
  effects. The local full-product implementation tests the unsigned upper
  half, or compares it with the low half's sign extension for signed overflow.
- Zig `src/codegen/llvm/FuncGen.zig`, `.mul_with_overflow` and `airOverflow`:
  Zig chooses `smul.with.overflow` or `umul.with.overflow` from integer
  signedness. The unchanged compiler IR contains 59 first failures at this
  shared scalar transfer boundary, mostly after selects.

Only admitted scalar scratch transfers change. Literal accumulator operands,
unsupported widths, undefined/poison values, general vector arithmetic and
unsupported intrinsic/ABI envelopes retain their existing boundaries.

## Checks

`checked_multiply_tests.zig` executes every argument register with full/narrow
aliases and live accumulator values, checks literal bounds before mutation,
executes attributed signed/unsigned products with high-bit inputs and guarded
outputs, repeats selection against unchanged source IR, and checks late
rejection rollback.

The `checked_multiply` native population has eight functions and 2,048
observations per executable. An independent C oracle uses 128-bit arithmetic
to check products and overflow, plus live neighboring values, 32-bit aliases,
calls that clobber caller-saved registers, PHIs and memory guards. The real
range-fact/select shape uses operands that satisfy its range. Direct and
accepted-release routes are compared against LLVM in all three release modes.
See the [implementation plan](../plans/2026-11-08-checked-multiply-operands.md)
for replay and cumulative acceptance requirements.
