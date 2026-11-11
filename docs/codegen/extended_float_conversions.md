# Extended floating-point conversions

The binary128 arithmetic view adds LLVM's standard half/binary128 and
i128/binary128 conversion helpers: `__extendhftf2`, `__trunctfhf2`, `__floattitf`,
`__floatuntitf`, `__fixtfti` and `__fixunstfti`. The existing payload view owns
raw binary128 transport. Ordinary typed calls preserve the numerical operation
and destination identity without changing source IR. Literal i128 operands
receive exact named pair carriers. Canonical identity prevents immediate
self-recursive outlining of a runtime helper.

Composed scalar-SSE calls may assign an i128 argument to two consecutive GPRs
when both are available. Integer and SSE register cursors remain independent;
simultaneous inputs receive durable homes before sequential argument placement.
A mixed call returning i128 binds the existing RAX/RDX product-result contract.
Whole stack pairs remain outside this call envelope. Structural call consumers
retain their preceding rejection behavior. Existing pointer, attribute,
calling-convention and tail-call checks remain authoritative.

The `extended_float_conversion` population contains ten functions. Numerical
oracles use integer significands, exponents and remainders, without C floating
arithmetic or conversion helpers. They check all half encodings, i128 rounding
boundaries, signed extrema, large literals, defined floating-to-integer inputs,
and binary16 underflow, midpoint and overflow cases. Inputs and scalar values
remain live across actual helper calls, with two incoming stack words and
guarded unaligned stores. NaN conversion results are compared by the class
permitted by LLVM; pure payload transport is compared bit for bit.

Two C providers also exercise alternating integer pairs and an XMM carrier,
integer-pair returns, and all caller-saved GPR/XMM clobbers. Their C floating
type carries bits across the ABI; it performs no numerical operations. The
unit tests reject immediate helper self-recursion and a whole pair after five
integer registers are occupied. Separate fault controls corrupt the return,
stored payload and suffix guard.
