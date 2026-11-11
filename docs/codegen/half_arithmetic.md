# Private binary16 arithmetic and storage

The optional arithmetic view widens half-precision multiplication and division
to binary32, then rounds the result to binary16 through the existing native
conversion. Named operands receive exact extensions; literals receive their
exact wider bit encodings. Source instructions, flags and result identities
remain unchanged, and the original-form retry remains available.

A finite binary16 product has at most 22 significant bits and exponent range
[-48,31], so binary32 represents it exactly. For division, both significands are
integers below 2,048. A quotient that is not exactly a binary16 midpoint stays
at least 1/4,096 of a binary16 ULP away from it. Binary32 rounding contributes
at most 1/16,384 of that ULP. It cannot cross the destination midpoint, including
subnormal rounding. All finite nonzero quotients remain normal in binary32.

Half negation flips the sign bit through typed integer bitcasts and XOR.
It preserves every other bit, including signaling NaNs and signed zeros, as
required by [LLVM's representation operations](https://llvm.org/docs/LangRef.html#behavior-of-floating-point-nan-values).
The frozen legacy floating-point handler remains unchanged.

Ordinary half memory uses exact two-byte integer storage only when the target
layout gives half and i16 the same storage size, allocation stride and ABI
alignment. The private view maps direct allocations, GEPs, stores and loads
together. Loaded i16 bits are reinterpreted as the original half SSA value.
Volatile, atomic, synchronization-scope and address-space envelopes remain
closed. Pointer provenance and access extents retain their existing contracts.
Store-only graphs use the same view in the final optional stage. That stage
tries the existing composed form first, retaining successful selection owners
and object bytes before opening half stores into larger owned objects.

The `half_product` native population covers multiplication, division and
negation with 41 functions. Independent integer oracles implement exact
significand products, rational division and ties-to-even rounding. Every 16-bit
input is tested against selected edge operands; both literal operand positions,
unaligned loads/stores, live values across helpers, incoming stack arguments
and guards are checked. Negation checks exact NaN representations. Separate
controls corrupt the returned bits, stored bits and suffix guard.
