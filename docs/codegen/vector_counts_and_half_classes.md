# Vector count facts and half classes

The integer-vector rewriter accepts the exact per-lane popcount return range
`[0, lane_bits + 1)`. It retains that validated fact on the scalar lane calls.
Other unsupported attributes stay closed. This lets existing mask, shuffle,
packed-lane and reduction operations compose in functions containing ranged
vector popcounts without changing their established transfer contracts.

Ordinary half `llvm.is.fpclass` lowers through exact representation bits. It
classifies signaling/quiet NaNs, signed infinities, normals, subnormals and zeros
with LLVM's ten class-mask bits. Valid constant masks are limited to 0..1023;
unsupported call/value envelopes remain closed. Source definitions and the
Source/UseForm interfaces remain immutable. No numerical conversion, NaN
quieting, helper call or floating arithmetic is introduced.

Two maintained Zig generators provide sixteen exhaustive half-mask functions
(1,048,576 observations per execution) and four vector functions (32,768).
LLVM references and independent scalar representation/count oracles validate
protected input boundaries, exact output stores, input preservation and live
values across real caller clobbers, in both routes/all modes with fault controls.
