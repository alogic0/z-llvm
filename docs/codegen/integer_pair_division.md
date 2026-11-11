# Native full-width integer division

The private pair-arithmetic view lowers ordinary `udiv`, `urem`, `sdiv` and
`srem` on i128 values through the standard LLVM compiler-rt entry points
`__udivti3`, `__umodti3`, `__divti3` and `__modti3`. LLVM 22 declares these
implementations for the corresponding i128 operations in `RuntimeLibcalls.td`.
The existing typed SysV pair-call path passes two words per operand and receives
the result in RAX/RDX. The original IR and its flags remain unchanged.

The existing scalar expansion for nonzero constant divisors with magnitude at
most `UINT32_MAX` retains priority. Other literal operands are split into exact
64-bit words and assembled into a named pair before entering the call ABI.
The rewrite preserves argument order and the result identity. A canonical
identifier comparison prevents outlining a runtime helper's implementation into
an immediate call to itself. Zero literal divisors, unsupported operands and
other widths retain their existing rejection behavior. The optional rewrite
retains the original-form retry.

The generated `integer_pair_division` canary covers all four operations with
named and large constant divisors. An independent unsigned restoring-division
C oracle handles quotient, remainder and signed magnitudes without C i128
division or modulo. Its object is checked for division-helper references.
Inputs cover full high words, signed extrema and unsigned bit patterns; invalid
zero divisors and signed `MIN/-1` inputs are excluded. Both operands and four
scalar values remain live across actual runtime-helper calls, with two incoming
stack arguments. Fault controls independently corrupt low, high and boundary
result bits.
