# Extended80 numerical conversions

Private casts use standard LLVM runtime helpers through the shared SysV
transfer contracts. Integer-to-extended80 casts for widths one through 128
extend the integer exactly to i128, then call `__floattixf` or `__floatuntixf`.
Conversions back use `__fixxfti` or `__fixunsxfti`, followed by exact narrowing
for each defined source result. Results below 64 bits first pass through an
i64 carrier so existing narrow-integer actions retain ownership.

Half/extended80 conversions use `__extendhfxf2` and `__truncxfhf2`.
Quad/extended80 conversions use `__extendxftf2` and `__trunctfxf2`. Float and
double conversions use an exact binary128 extension followed by one narrowing
helper. Binary128 represents every finite source value exactly, including
subnormals, so this composition performs only the requested rounding.
Double-to-half conversion uses `__truncdfhf2` directly. Half-to-double retains
the existing exact native widening path.

Canonical helper identities prevent outlining a helper into an immediate call
to itself. Literal integer arguments are materialized as exact named pairs.
Source IR, original result identities and flags remain immutable. Constrained
operations and unsupported ABI forms keep their existing boundaries.

The shared physical layout assigns integer, SSE and aligned extended80 memory
locations independently. Mixed calls stage complete memory arguments, use the
existing GPR/SSE planner for register arguments and capture ST0 into an integer
pair when required. Shared staging retains alignment holes and later stack
arguments. Indirect extended80 calls, split integer words in the mixed path,
SSE stack overflow, `musttail` and unsupported attributes remain closed.

The Zig generators for `extended80_integer` and `extended80_float` produce
integer rounding and truncation oracles, exact access guards, protected input
pages, complete half-input coverage and mixed ABI providers. Providers clobber
nine GPRs and sixteen XMM registers. C floating types carry ABI bits; integer
operations provide numerical expected values. NaN conversion checks allow
LLVM's documented payload choices while requiring a NaN result. Payload
transport separately preserves every defined representation bit exactly.
