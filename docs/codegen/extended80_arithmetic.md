# Extended80 numerical operators

Ordinary extended80 addition, subtraction, multiplication, division and square
root use native x87 instructions. The payload rewrite constructs private i128
carriers with an explicit numerical marker. Original IR types and instructions
remain unchanged. The marker is unavailable in the source parser and validates
exact operand types before lowering; ordinary integer IR gains no floating ops.

Both operands first enter shared canonical pair spills. Fixed RAX/RDX transfers
load the exact low eighty bits into x87. Binary operations compute ST1 op ST0
and pop once. Each result is immediately captured through the existing ST0
transfer into zero-padded owned pair storage. No x87 value survives a call or
control-flow edge. Shared register clobber handling preserves live values;
existing payload memory views retain ten-byte accesses and sixteen-byte stride.
Plain bitwise sign-return shapes retain their established structural owner.

The x87 verifier checks unary and binary operand depths, balanced pops, call
boundaries and path joins. Machine encoding and printed assembly agree with
LLVM22 assembler bytes, including noncommutative subtraction/division ordering.
Square root uses FSQRT and preserves errno, matching LLVM's ordinary lowering.

The maintained Zig generator creates fifteen functions covering all five
operations with named operands and literal sides. Independent LLVM objects and
C/hardware oracles check 61,440 observations per execution, signed zero,
subnormal and extreme values, infinities and NaNs. Protected ten-byte input
boundaries, exact stores, input preservation, x87 TOP, errno and real caller
clobbers remain part of both routes/all-mode validation with injected faults.
