# Floating remainder and half subtraction

Ordinary scalar frem uses the same GNU libm names as LLVM22's baseline x86-64
lowering: fmodf for float, fmod for double, fmodl for extended80 and fmodf128 for
binary128. Half operands widen exactly to float, call fmodf and round back to
half. Private rewriting retains immutable source instructions and shared typed
ABI transfers. Canonical helper identity and the module alias chain prevent
recursive outlining, including quoted names and cycles.

Ordinary half subtraction uses the existing exact-promotion path alongside
half multiplication and division. Negation retains its earlier bitwise path.
No constrained floating behavior or new source/value-use interface is admitted.

The maintained Zig generator creates eighteen functions: all five remainder
formats and half subtraction, each with named operands and two literal sides.
The 442,368 observations per execution include exhaustive half inputs and
independent integer widening/rounding, LLVM references, GNU math oracles, errno,
x87 stack balance, exact output guards, protected input boundaries, unchanged
inputs and live values across real caller clobbers. Both routes/all modes and
injected faults remain required before acceptance.

Native comparison also exposed a shared SSE-call bug: constructing a later
binary128/vector literal used XMM0 scratch and overwrote an earlier ABI argument.
The caller now captures such later literals in owned frame storage before
loading ABI registers, then reloads each exact vector. An executable raw-payload
regression verifies both arguments through an independent provider. Existing
first-argument literal materialization retains its prior instruction sequence.
