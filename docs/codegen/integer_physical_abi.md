# Physical integer argument locations

The composed selector shares one integer location calculation between parameter
capture, outgoing calls and frame reservation. The observed compiler boundaries
include the eighteen pointer/integer arguments of
`codegen.llvm.runZllvmIrWriterCommand` and wide integer arguments in the AArch64
and LoongArch selectors. These are ordinary x86-64 calls in the captured compiler
IR, even when their source-level operation targets another architecture.

The layout accepts up to 32 direct integer/pointer arguments. The first six
physical words use RDI, RSI, RDX, RCX, R8 and R9. A native i128 argument requires
two consecutive registers or complete 16-byte-aligned stack storage. A pair put
on the stack leaves a remaining scalar register available to a following word.
Other integers above 64 bits are separate ABI words: their low word can use R9
while their high word and following scalar arguments occupy the stack. Such
words do not acquire i128's alignment requirement.

Private legalization uses i128 SSA carriers for integer widths 65 through 127.
The `abi_split_integer` field on parameters and call arguments preserves their
source ABI classification after widening. Parsing never sets it, and it is not
an LLVM attribute. The original function, declarations, attributes and operand
types stay immutable. Every incoming carrier and original-width definition is
masked at its logical width; signed operations first recover the original sign.
Validated range promises refer to the original width and are removed from the
private widened carrier. This integer payload support does not add x87 or
floating i80 arithmetic.

The existing register-binding routine remains byte-for-byte unchanged. A private
view passes it only complete register arguments. Stack and split pairs are read
immediately through typed accumulator definitions and stored in owned callee
homes, preserving register parameters needed by the first IR instruction. The
temporary word definitions have separate virtual-register identities from the
128-bit parameter. Reservation covers every incoming physical word even when
some parameters are unused.

Call preparation preserves simultaneous sources before staging outgoing words.
All stack values are captured before changing RSP. Reverse pushes account for
alignment holes, the initial call-alignment pad and the changing displacement of
each retained frame home. A split carrier's low word is placed in R9 through the
existing low-limb transfer. Both constant and named stack pairs are supported.
Indirect calls retain the preceding sixteen-scalar or six-register-word limits;
variadic, SSE, explicit extension and other ABI envelopes keep their own checks.

When a pair-low cast has no free scalar home, its existing action chooses a
preserved home and spills every overlapping current operand and alias before
loading the limb. Previously available-home choices remain unchanged. Failure
injection checks restore bindings, spills, virtual identities, derived physical
counts and the current-position preservation flag.

Upstream mapping, pinned LLVM 22 sources:

- `llvm-project-22/llvm/lib/Target/X86/X86ISelLoweringCall.cpp`,
  `X86TargetLowering::functionArgumentNeedsConsecutiveRegisters`, marks native
  i128 for consecutive registers; other integer widths are not marked.
- `llvm-project-22/llvm/lib/Target/X86/X86CallingConv.cpp`, `CC_X86_64_I128`,
  allocates two registers as a block or a 16-byte stack slot without consuming
  a remaining register.
- `llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td`, `CC_X86_64_C`,
  supplies the six integer registers and stack rules used here. Default and
  fastcc integer placement is checked independently with LLVM assembly probes.
- `llvm-project-22/llvm/docs/LangRef.rst`, integer, call, cast and `range`
  contracts. In particular, `range(0, 0)` is empty and cannot be used as a
  full-range native test input promise.

`tools/generate_integer_physical_abi_canary.zig` generates the maintained LLVM
fixture and independent C oracle. Its forty functions cover eighteen and
thirty-two scalars, widths 65/66/80/96/127/128, split and aligned stack positions,
default/fastcc, constants, nested calls, returned upper bits, clobbers and guards.
Each execution checks 20,480 observations. Seven injected faults calibrate the
return, four output fields and both guards through the maintained Zig runner.
Whole-input counts are accepted separately by the compiler-selection plan.
