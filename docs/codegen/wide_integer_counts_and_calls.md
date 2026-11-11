# Wide integer counts and literal call operands

Private optional legalization promotes integer absolute value and bit counts
for widths 65 through 127 to the existing exact i128 pair operations. Leading
zero count subtracts the added high bits. Trailing zero count uses two i64
counts and explicitly returns the original width for a zero operand. Population
count uses the i128 count; absolute value sign extends the original width before
applying its sign mask and truncating the result. Existing intrinsic attribute
and poison checks remain in force.

Ordinary calls with literal i128 arguments first construct named pair operands
through the existing integer literal builder. Argument order, calling convention
and supported ABI attributes are preserved. LLVM intrinsics, inline assembly,
raw argument envelopes and operand bundles do not enter that rewrite.

The `wide_values` native canary checks 65-, 80-, 113- and 127-bit absolute value
and counts with named and literal operands. It also checks literal i128 values
in either or both ordinary call argument positions. Independent C bit loops and
LLVM execution cover zero, sign bits, all ones, single bits and randomized upper
bits. Results remain live across caller register clobbers and are written into
guarded, unaligned sixteen-byte outputs. Injected result, payload and guard
corruption must all be detected.
