# Wide bytes and scalar vector choices

Byte swaps for 80-, 96-, 112- and 128-bit integers extend exactly to a private
128-bit pair. Two existing native 64-bit byte swaps exchange the word order;
a final shift and narrowing retain the original logical bytes. Literal inputs
are split exactly into native words. No runtime helper is introduced.

A scalar i1 condition may choose either complete two-lane FP vector. Private
extraction, integer-bit selection and reconstruction preserve every lane bit,
including NaNs. This also handles binary128 values represented by the existing
two-double carrier. An undefined or poison condition may refine to one stable
choice. The final optional stage tries the original composed form first,
preserving existing successful owners and object bytes. Vector-mask conditions
keep their existing selection authority.

Maintained Zig generators supply byte reversal and whole-payload selection
oracles. Native tests cover literals, dirty upper input bits, exact unaligned
stores and live results across real GPR/XMM clobbers; vector inputs additionally
end at protected-page boundaries.
