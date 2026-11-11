# Freezing two-word records

The existing flat-record transport pass supports `freeze` for `{ptr,i64}`,
`{i64,ptr}`, `{ptr,ptr}` and `{i64,i64}`. It emits one typed scalar freeze per
field and routes every later use to those same definitions. Defined fields
retain every bit. Undefined or poison fields receive one permitted stable
choice independently; the private view materializes zero/null for explicit
undefined operands. Constants and global pointer values receive named carriers
before freezing.

The pass continues to use its existing field layout, memory accesses and
RAX/RDX return handling. Aggregate parameters and unsupported use envelopes
remain subject to the existing checks. The source record and its operands are
immutable; only the private selector view is split into scalar SSA fields.

Executable unit tests cover all four layouts with complete and partially
defined records. The generated `word_pair_freeze` native canary also covers
poison, undef and zero initialization. A C provider actually clobbers every
caller-saved integer register between the freeze and its uses. Repeated
unaligned stores must agree field by field, every defined field must match the
independent C expectation, and surrounding guards must remain intact. Fault
controls corrupt the return, a stored field and a suffix guard.
