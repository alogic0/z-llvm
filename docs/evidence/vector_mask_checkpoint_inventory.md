# Vector-Mask Checkpoint Inventory

INBOX-36 is acknowledged by this read-only evidence cycle.

## Baseline And Method

- Accepted implementation commits: `60f6fad4`, `ac122f64`, `0a5bc7e5`
- Accepted report: `tmp/inbox35_half_store_report.log`
- Report summary: 443 selected, 233 emitted, 210 failed
- Captured IR:
  `tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll`
- Captured-IR MD5: `b0eda7a6427c3084fdf096a68696f19c`
- Stage4 Zig pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`

This inventory changes no code and runs no gate. It derives the census from
the accepted report and pinned captured IR only. `Observed` below means the
accepted report contains that first diagnostic. `Predicted` means an operation
is present later in the captured body; it is not a claim that selection has
reached that operation or that the row will emit after one capability lands.

The scan found eight functions and 45 relevant operations. The only predicate
widths are `<2 x i1>` and `<4 x i1>`; no runtime lane index or runtime shuffle
mask occurs in these bodies.

## Demand Census

| Operation family | Instances | Unique functions |
| --- | ---: | ---: |
| Packed `fabs` | 9 | 7 |
| Vector `fcmp` | 8 | 6 |
| Constant mask-lane extraction | 8 | 3 |
| FP-vector to integer-vector bitcast | 5 | 4 |
| Packed `copysign` | 4 | 2 |
| Mask-conditioned vector `select` | 4 | 2 |
| `<4 x i1>` bitcast to scalar `i4` | 4 | 4 |
| Vector `icmp` | 2 | 2 |
| Integer-vector to FP-vector bitcast | 1 | 1 |

| Function | Predicate/data shapes | Captured operations | Observed first diagnostic |
| --- | --- | --- | --- |
| `compiler_rt.comparef.__unordsf2` | `<2 x float>`, `<2 x i32>`, `<2 x i1>` | packed `fabs`; FP-to-int bitcast; unsigned vector `icmp`; extracts lanes 0 and 1 | `unsupported_type / call-ret` on the vector-return `llvm.fabs.v2f32` call |
| `compiler_rt.divdc3.__divdc3` | `<2 x double>`, `<2 x i64>`, `<2 x i1>` | two packed `fabs`; two `fcmp oeq`; two mask extracts; two vector selects; two packed `copysign`; two FP-to-int bitcasts | `unsupported_type / unsupported-return-type` |
| `compiler_rt.divsc3.__divsc3` | `<2 x float>`, `<2 x i32>`, `<2 x i1>` | two packed `fabs`; two `fcmp oeq`; one unsigned vector `icmp`; four mask extracts; two vector selects; two packed `copysign`; one FP-to-int bitcast | `unsupported_type / unsupported-return-type` |
| `compiler_rt.mulsc3.__mulsc3` | `<4 x float>`, `<4 x i1>` | packed `fabs`; `fcmp oeq`; mask bitcast to `i4` | `unsupported_type / unsupported-return-type` |
| `compiler_rt.muldc3.__muldc3` | `<4 x double>`, `<4 x i1>` | packed `fabs`; `fcmp oeq`; mask bitcast to `i4` | `unsupported_type / unsupported-return-type` |
| `compiler_rt.mulhc3.__mulhc3` | `<4 x half>`, `<4 x i1>` | packed `fabs`; `fcmp oeq`; mask bitcast to `i4` | `unsupported_type / alloca` |
| `compiler_rt.multc3.__multc3` | `<4 x fp128>`, `<4 x i1>` | packed `fabs`; `fcmp oeq`; mask bitcast to `i4` | `unsupported_type / unsupported-param-type` |
| `compiler_rt.tan.tan` | `<2 x double>`, `<2 x i64>` | FP-to-int and int-to-FP bitcasts; no predicate value | `unsupported_type / alloca` |

`tan` is included because the requested vector-bitcast census reaches it, but
it does not create mask demand. The remaining seven functions are the complete
captured vector-mask population.

### Immediate Candidate

`__unordsf2` is the only mask row whose observed boundary is the mask-producing
expression itself rather than an earlier ABI, frame, half, fp128, or wider-
vector boundary:

```llvm
%2 = insertelement <2 x float> poison, float %1, i64 0
%3 = insertelement <2 x float> %2, float %0, i64 1
%4 = tail call <2 x float> @llvm.fabs.v2f32(<2 x float> %3)
%5 = bitcast <2 x float> %4 to <2 x i32>
%6 = icmp samesign ugt <2 x i32> %5, splat (i32 2139095040)
%7 = extractelement <2 x i1> %6, i64 0
%8 = extractelement <2 x i1> %6, i64 1
%9 = select i1 %8, i1 true, i1 %7
%10 = zext i1 %9 to i32
ret i32 %10
```

Both lanes are statically defined. The mask has only scalar consumers: extract
two constant lanes, combine them through the existing scalar predicate model,
and return 0 or 1. The accepted report's `call-ret` diagnostic is the inspection
boundary for `llvm.fabs.v2f32`; the packed `fabs`, bitcast, vector compare, and
mask extracts are predicted in sequence from the body.

### Mixed Scalar And Vector Consumers

`__divdc3` and `__divsc3` are the representation-defining counterexamples to
making a GPR bitset canonical. Their `<2 x i1>` values have two kinds of
consumer in the same body:

- constant lane extraction feeding scalar branches or scalar predicate logic;
- vector `select` choosing full-width floating-point lanes.

For example, `__divdc3` extracts both lanes from the result of `fcmp oeq`, then
later uses that same SSA mask in a `<2 x double>` select. `__divsc3` does the
same for one `fcmp` mask and separately extracts both lanes from an integer-
vector comparison. These rows remain observed at aggregate-return boundaries;
the consumption analysis is predictive and does not claim near-term closure.

### Scalar-Bitset Consumers

The four multiply-complex bodies compare four packed lanes and immediately
bitcast `<4 x i1>` to `i4`. They do not use a mask-conditioned vector select:

- `<4 x float>` can physically fit in one XMM register and maps naturally to
  `movmskps`, but the row is first blocked by aggregate return.
- `<4 x double>` requires a 256-bit data representation and is outside the
  current XMM-only vector authority.
- `<4 x half>` has no admitted baseline packed-half comparison and is first
  blocked by frame ownership.
- `<4 x fp128>` is beyond both the current scalar fp128 and vector boundaries.

These scalar-bitset consumers justify a `movmsk` conversion operation, not a
GPR-canonical mask representation for every producer.

## Representation Decision

### Full-Width Lane Masks In XMM

The recommended canonical representation is an XMM value whose logical mask
shape records:

- lane count;
- source lane width (32 or 64 bits in the first architecture);
- static defined-lane bits;
- the invariant that a defined false lane is all zero bits and a defined true
  lane is all one bits at the source lane width.

This is the native result shape of SSE packed comparisons. A scalar consumer
converts at its use site with `movmskps` or `movmskpd`, then tests the requested
constant bit. A vector `select` can consume the XMM mask directly through
packed logical operations without rebuilding lane masks.

For `<2 x float>`, the logical lanes occupy the low two 32-bit XMM lanes and
`movmskps` exposes the low two bits. For `<2 x double>`, both 64-bit XMM lanes
are used and `movmskpd` exposes two bits. A later `<4 x float>` shape can use
four 32-bit lanes and produce an `i4` with `movmskps` without changing the
canonical rule.

### Why A GPR-Canonical Bitmask Is Rejected

A GPR bitmask is locally cheaper for `__unordsf2` and for the four captured
`<4 x i1> -> i4` consumers. It is not the right shared authority because
`__divdc3` and `__divsc3` require the same SSA mask as packed vector-select
input. Making the GPR form canonical would require either:

- a GPR-to-XMM all-ones/all-zeros lane expansion before each vector select; or
- a hidden dual representation whose synchronization and spill ownership are
  not represented in the value-location model.

Both choices create more state and make mask-definedness harder to verify. A
one-way, explicit XMM-mask-to-GPR extraction at scalar consumers preserves one
authority and matches the captured mixed-consumer bodies.

The verifier should check the physical mask shape and defined-lane requirement
at every mask consumer. Static definedness remains part of the value location;
the verifier does not infer poison facts independently from machine opcodes.

## First Bounded Mask Slice

The smallest architecture-valid implementation slice closes only
`compiler_rt.comparef.__unordsf2`:

1. Admit a full-lane `<2 x i1>` mask shape for 32-bit source lanes in XMM, with
   static defined-lane propagation.
2. Admit packed `<2 x float>` `fabs` as a typed sign-bit clear. Preserve every
   non-sign bit, including signaling/quiet NaN payloads.
3. Admit the no-data-movement `<2 x float>` to `<2 x i32>` bitcast as an exact
   shape retag on the same XMM payload.
4. Admit typed unsigned `<2 x i32>` greater-than against an exact splat,
   producing full-width lane masks. SSE2 signed comparison cannot silently
   stand in for unsigned comparison; use a type-correct sign-bit bias or an
   equivalent proven sequence.
5. Admit constant lane 0/1 extraction through `movmskps` and the existing GPR
   scalar predicate paths.
6. Keep f64 masks, `<4 x i1>`, vector mask `select`, packed `copysign`, wider
   vectors, dynamic lanes, and all other vector compare forms fail-closed.

The executable canary should compile the exact row body and cover ordered
finite pairs, both signed zeros, subnormals, infinities, one-NaN and two-NaN
pairs in both operand orders, and quiet/signaling NaNs with varied payloads.
Expected results are precomputed 0/1 values. Bit-preservation checks around
packed `fabs` must be included rather than deriving expected results from host
floating-point comparisons.

Expected closure: exactly one row, `__unordsf2`. The slice crosses shared value
shape, selector, machine encoding, and verifier surfaces, so it requires an
architectural authorization and Tier 3 at row closure. It does not authorize
aggregate ABI work merely because later complex rows reuse the representation.

## Remaining Scalar Frontier

The 210 current failures cluster as follows. The dominant 122 rows are already
at unsupported return or parameter types and are mostly aggregate, vector ABI,
x87, or fp128 boundaries rather than routine scalar work.

| Diagnostic detail | Rows | Interpretation |
| --- | ---: | --- |
| `unsupported-return-type` | 87 | Primarily aggregate, extended FP, or vector-bearing return boundaries |
| `unsupported-param-type` | 35 | Primarily extended FP, aggregate, or vector-bearing parameter boundaries |
| `composed-block-llvm-intrinsic` | 17 | Scalar intrinsic frontier detailed below |
| `composed-block-icmp-form` | 8 | Half bit-pattern compare/conversion bodies with several predicates, not one proven form |
| `stage2-switch-phi-edge` | 7 | Control-flow edge representation |
| `composed-block-icmp-lhs-loc` / `cast-from-not-int` | 6 each | Scalar location/cast work |
| `alloca` | 6 | Frame or earlier type boundary; includes latent vector rows |
| `composed-block-spill-frame` | 5 | Scalar frame pressure |
| Other details | 33 | No single detail exceeds four rows |

There is no current `composed-block-call-form` row. The call-related cluster is
three i128/pointer-ABI rows: `__udivmodti4` at `call-ptr-arg`, plus `__udivti3`
and `__divmodti4` at `call-unknown-ptr-arg`. `__unordsf2` at `call-ret` is the
vector-return intrinsic inspection boundary, not an ordinary direct-call ABI
frontier.

### Zero-Count Rows

The two rows advanced by INBOX-35 now have a concrete immediate frontier:

- `compiler_rt.floatunsisf.__floatunsisf`: `llvm.cttz.i32`
- `compiler_rt.floatsisf.__floatsisf`: `llvm.cttz.i32`

Both bodies already pass `llvm.ctlz.i32`, the i6 normalization comparison, and
their earlier scalar forms. The machine and verifier already own
`ctz_i32_edi_eax`; the missing work is composed-selector intrinsic admission
with named-value/location safety and executable conversion rounding coverage.
This is the strongest routine scalar candidate: two expected closures for a
smaller ownership change than the first mask slice.

Eight additional scalar soft-float rows contain `llvm.ctlz.i64`; four integer-
to-FP conversion rows later contain `llvm.cttz.i64`. Existing machine forms
include `clz_i64_rdi_eax` and `ctz_i64_rdi_eax`, but the accepted report only
identifies the general intrinsic boundary, so these must be sequenced with a
fresh diagnostic after each admitted operation. They promise broader row
advance, not an honest immediate closure count.

The remaining seven intrinsic rows are exact i64/i128 compare, byte-swap,
bit-reverse, and population-count wrappers. They are typed scalar candidates,
but several require new i64/i128 machine forms or pair handling; they do not
form one smaller shared slice than `cttz.i32`.

The eight half `icmp` failures split between two full comparison bodies and six
half-to-integer conversion bodies. Captured predicates include signed sign-bit
tests, unsigned exponent bounds, equality/inequality, and named comparisons.
They may provide a useful later half-bit-pattern family, but the accepted
diagnostic does not support claiming one predicate capability will close all
eight.

## Closure-Per-Effort And Review Request

Recommended ordering from the accepted frontier:

1. Typed composed `llvm.cttz.i32`: two expected scalar closures, reusing an
   existing machine/verifier operation.
2. Bounded i64 zero-count admission: advance up to eight rows, refreshing the
   frontier before claiming the four conversion closures that also need cttz.
3. The first canonical XMM mask slice: one immediate closure, but establishes
   the reusable representation required by the two complex divide bodies and
   the later `<4 x float>` scalar-bitset consumer.
4. Predicate-by-predicate half bit-pattern work after a dedicated row grouping;
   do not treat the current eight-row diagnostic cluster as one capability.

The scalar ranking does not remove the mask checkpoint. Mask work changes a
shared value shape and its verifier semantics, and the choice between XMM lane
masks and GPR bitsets must be settled before implementation. The inventory
recommends full-width XMM masks with explicit `movmsk` scalar extraction and
the six-operation `__unordsf2` slice above. No vector-mask implementation is
authorized or included. Request architectural review of that representation,
slice boundary, and its position relative to the two-row `cttz.i32` cycle.
