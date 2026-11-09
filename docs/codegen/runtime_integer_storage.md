# Private runtime storage and exact integer memory

General storage legalization presents bounded arrays, structs and named objects
through private byte addresses. Ordinary `memcpy` retains its runtime SSA length
and the original object extent. Known negative or oversized copies still reject;
specialized padded frames and `llvm.memcpy.inline` still require a known valid
length. Private carrier padding grants no additional source bytes. Source IR,
public signatures and attributes remain unchanged.

Non-native integer loads and stores through i128 access exactly `ceil(N/8)` bytes
using 8/4/2/1-byte chunks with alignment one. Wider 32/64/128-bit carriers exist
only in registers; the declared loaded result width is restored. The form keeps
volatile/atomic barriers, syncscope, address spaces and unsupported layouts
outside its envelope. Type-specific load metadata remains on the immutable
source instruction and is conservatively omitted from smaller private accesses.

Non-byte integer padding bits are unspecified. Defined source executions must
still satisfy LLVM's same-type-store rule for non-byte-sized loads. The i65
native fixture performs a defined typed store before its load; comparisons ignore
only the last byte's padding bits and check every adjacent guard byte.

Mandatory semantic normalization chooses zero for an explicit integer i1 through
i128 undef/poison select arm, or null for a pointer arm. It retains the condition,
every defined arm, source widths and public ABI. Floating and aggregate selects
remain separate boundaries. Native tests observe defined results by ignoring
an undefined arm through an outer select.

Pair arithmetic reuses a known low word for redundant truncations. Unused pure
private i128 binaries/casts can be removed after complete operand coverage;
opaque references disable cleanup. Canonical LLVM identifier equality counts
uses, and owned instruction arrays preserve source ownership. Calls and memory
effects are never removed. The existing untyped bypass inventory is unchanged.

The mandatory `runtime_storage`, `integer_memory` and `undefined_selects`
populations check initialized storage and padding, exact page ends, full defined
bits, pointer identity, live values, clobbering calls and output guards. Both
routes in all three release modes pass with frozen Debug and ReleaseFast
compilers. See the [accepted evidence](../evidence/runtime_integer_storage.md).
