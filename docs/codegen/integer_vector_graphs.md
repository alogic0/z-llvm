# Private integer vector graphs

The integer-vector form expands bounded internal vectors into ordinary scalar
SSA lanes. It preserves the source function, public signatures and attributes.
Up to sixteen integer lanes of widths i1 through i128, and pointer lanes, can
participate in supported internal graphs. Existing native 128-bit vector ABI
admission stays separate from internal lane bounds.

Exact integer/vector bitcasts use little-endian lane order, with lane zero in
the low bits. Scalar carriers are limited to 128 total bits. Wider vector/vector
bitcasts splice overlapping bit ranges between bounded scalar lanes rather
than constructing a giant scalar integer. Typed pointer/integer casts retain
pointer semantics and matching lane counts; the verifier rejects mismatched
lanes, element kinds and scalar/vector combinations.

Every vector producer receives stable private lane identities before traversal.
PHIs clone incoming lists per lane, preserving forward references, backedges,
parallel copies and edge multiplicity. Named freeze operands retain scalar
freeze instructions; explicit undefined or poison lanes can be refined to
zero or null. Native checks observe defined values and freeze consistency,
then overwrite unspecified lanes before equality comparisons.

Byte-addressable lanes use exact scalar memory extents. Packed masks retain
the existing admitted word extents. Volatile/atomic barriers, syncscope,
address spaces, unsupported vector ABI forms and partially unsupported graphs
remain explicit rejection boundaries. Shape admission does not promise that
every scalar operation or memory width already has an emitter.

Closed lane-wise intrinsic expansion covers `fshl`, `bswap`, `ctpop` and unsigned
saturating subtraction. It validates the call envelope and clones scalar
argument lists. Reductions retain their existing typed scalar expansion.

Two supporting scalar fixes avoid unnecessary register pressure. Pair arithmetic
reuses known scalar words for a high-word projection by 64. The typed R01
logical-right-shift action can use its existing accumulator session when all
six scratch GPRs are occupied. It preserves live aliases and spills/refreshes
a source already in RAX before preparing that session. No bypass is added.

The mandatory `vector_masks` and `vector_graphs` populations exercise exact mask
bits, both bitcast directions, widened lanes and carries, repacking, parallel
PHI loops, pointer lanes and round trips, freeze consistency, intrinsic lanes,
clobbering calls, protected page ends and output guards. Frozen Debug and
ReleaseFast compilers each pass both routes in all three release modes.
Independent driver controls reject wrong lane order, PHI copies and carry shifts.
See the [accepted evidence](../evidence/integer_vector_graphs.md).
