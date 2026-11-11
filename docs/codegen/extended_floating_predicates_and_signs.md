# Extended floating predicates and sign operations

All sixteen extended80 comparison predicates lower through exact integer
payload classification. Sign, magnitude, explicit integer bit and exponent
determine ordering and unordered status. Signed zeros compare equal.
Pseudo-denormal encodings compare like their equivalent normal value;
nonzero-exponent encodings without an explicit integer bit are unordered.
NaN classification includes signaling representations without changing bits.
Half comparisons widen exactly to binary32 and use the existing comparison
authority. Source flags and result identities remain immutable.

Extended80 and binary128 negation, `llvm.fabs` and `llvm.copysign` change only
the representation sign bit through private integer bitcasts and logical
operations. NaN payloads, signaling bits and every magnitude bit are preserved.
Undefined and poison operands receive a stable permitted representation.
Unsupported call envelopes and attributes remain closed.
The existing single-argument extended negation return shape retains its
structural owner through a matcher shared with the structural emitter.

The maintained predicate generator exercises every half input, edge-pair
truth tables, raw extended80 encodings and all predicates together. Its oracle
executes independent hardware floating comparisons. The sign generator uses
integer bit oracles over arbitrary representations. Both populations check
protected input boundaries, exact unaligned stores, input preservation and
live results across providers that clobber nine GPRs and sixteen XMM registers.
