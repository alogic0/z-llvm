# INBOX-53 Switch-PHI/EI Census And Contract Freeze

INBOX-53 is acknowledged by this read-only evidence cycle.

## Baseline And Method

- Accepted implementation baseline: `18cd28c4`, `7c860974`, and `6d5d3ad6`
- Accepted compiler_rt report: 443 selected / 278 emitting / 165 failing
- Report log: `tmp/inbox51_select_post_p0_report.log`
- Report sha256:
  `8c4cb026b209e70db98638999a7b71dc75de668e688199fcfd1f39b30f990a6b`
- Captured IR:
  `tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll`
- Captured-IR md5: `b0eda7a6427c3084fdf096a68696f19c`
- Stage4 Zig pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`

This cycle changes no implementation and runs no gate. `Observed` below means
the accepted report names the diagnostic. `Predicted` means a later shape is
present in the frozen captured IR but is hidden by an earlier observed
failure. A predicted shape is not an emission or closure claim.

## Census Accounting

The 29 rows are one `fma` row plus 28 conversion rows. The conversion
population contains the six immediately exposed EI-to-scalar-FP rows, their
four x87/fp128 return siblings, and three six-row latent scalar/i128
conversion families.

| Population | Count | Rows | Accepted-report state |
| --- | ---: | --- | --- |
| Multiway scalar-PHI `fma` | 1 | `compiler_rt.fma.fma` | Observed `stage2-switch-phi-edge` |
| EI pointer to scalar FP | 6 | `__floatuneidf`, `__floatuneisf`, `__floatuneihf`, `__floateidf`, `__floateisf`, `__floateihf` | Observed `stage2-switch-phi-edge` |
| EI pointer to boundary FP | 4 | `__floatuneixf`, `__floatuneitf`, `__floateixf`, `__floateitf` | Observed `unsupported-return-type` |
| i128 to scalar FP | 6 | `__floatuntidf`, `__floatuntisf`, `__floatuntihf`, `__floattidf`, `__floattisf`, `__floattihf` | Observed `composed-block-icmp-lhs-loc` |
| Scalar FP to EI pointer | 6 | `__fixunsdfei`, `__fixunssfei`, `__fixunshfei`, `__fixdfei`, `__fixsfei`, `__fixhfei` | Observed `composed-block-cast-from-not-int` |
| Scalar FP to i128 | 6 | `__fixunsdfti`, `__fixunssfti`, `__fixunshfti`, `__fixdfti`, `__fixsfti`, `__fixhfti` | Observed `stage2-phi-src` |

The four boundary-FP rows are counted because they are exact source-family
siblings of the six EI entry-switch rows. They remain outside implementation
admission: x87 and fp128 are explicit ABI/type walls.

## Population A: Fma

`compiler_rt.fma.fma` is acyclic and contains four switches plus independent
scalar joins:

- Three `switch i11` terminators use cases `0` and `-1` plus a default. Each
  corresponding frexp exit has four predecessors and two parallel PHIs, one
  `i32` and one `i64`.
- One `switch i32` terminator uses cases `0` and `2047` plus a default. Its
  ilogb exit has four predecessors and one `i32` PHI.
- The function return join has seven predecessors and one `double` PHI.
- Other captured joins are two-incoming `double` PHIs and one three-incoming
  `double` PHI.

The accepted failure is the first switch edge that targets a block with an
incoming PHI. The current switch compare-chain deliberately rejects every
such edge before emission. This is not the last body blocker: captured IR
after the switches includes `llvm.ctlz.i52`, scalar `llvm.copysign.f64`, and
packed f64x2 work. Therefore no phase below may claim an `fma` closure from
multiway PHI or switch-edge support alone.

## Population B: Conversion Rows

### Six Exposed EI-To-FP Rows

All six functions take a read-only EI limb pointer and a byte-size value. The
entry shape is identical:

- condition: `i16` limb count derived by shifting the byte size by two;
- cases: exactly `0`, `1`, `2`, `3`, and `4`;
- default: the arbitrary-width limb path;
- return join: exactly six predecessors, with case 0 supplying positive zero,
  cases 1 through 4 supplying conversions from `i32`, `i64`, `i96`, and
  `i128`, and the default supplying the packed-limb result;
- return-PHI types: `half`, `float`, and `double` for both signednesses.

The default paths have two loop regions. The first is a self-loop with two
parallel `i64` PHIs that scans 32-bit limbs and accumulates position/leading-
zero state. The second is a self-loop with one `i64` PHI that scans discarded
limbs for rounding state. A two-predecessor `i1` PHI joins the rounding flag.
The f32 variants also have a two-predecessor `i32` exponent/offset PHI.

The final packed-read PHIs are exact and result-width dependent:

| Result | Unsigned narrow PHI | Signed narrow PHI |
| --- | ---: | ---: |
| `double` | two-incoming `i55` | two-incoming `i56` |
| `float` | two-incoming `i26` | two-incoming `i27` |
| `half` | two-incoming `i13` | two-incoming `i14` |

The loops and narrow PHIs are predicted because the accepted report stops at
the entry switch edge. Cases 3 and 4 also prove that i96/i128 loads and
integer-to-FP conversion are later typed requirements.

### Four Boundary-FP Siblings

The two x87 and two fp128 siblings have the same entry `switch i16` case set
`0..4` plus default, but they do not have the six-way scalar return shape:

- x87 returns use ten-incoming `x86_fp80` joins and packed narrow PHIs of
  `i66` unsigned or `i67` signed;
- fp128 returns use ten-incoming `fp128` joins and packed narrow PHIs of
  `i115` unsigned or `i116` signed;
- both retain the two `i64`-PHI limb scan, the one-`i64`-PHI rounding scan,
  and a two-incoming `i1` rounding join.

These shapes are recorded for census completeness only. They must continue to
fail at the existing return-type boundary.

### Six I128-To-FP Rows

These rows have no switch and no loop. Their joins are:

- f64/f32: one two-incoming integer PHI (`i64` or `i32`) and one
  two-incoming FP return PHI;
- unsigned f16: one two-incoming `i16` PHI and one three-incoming `half`
  return PHI, including zero and infinity paths;
- signed forms have the same width-parametric branch/merge structure.

All six are observed earlier at an i128 comparison-location form. Their PHIs
are predicted and do not authorize i128 compare, `ctlz.i128`, `cttz.i128`, or
wide-shift work.

### Six FP-To-EI Rows

These void-returning pointer-output rows use an entry `switch i16` with exact
cases `0..4` plus default. The common exit has six predecessors but no return
PHI. Cases 1 through 4 perform FP-to-`i32`/`i64`/`i96`/`i128` conversion and
store through the output pointer.

The default paths contain four-predecessor scalar joins, pointer loop PHIs,
and byte-fill loops. The signed variants additionally contain a frexp switch:
`i11 {0,-1,default}` for double, `i8 {0,-1,default}` for float, and
`i5 {0,-1,default}` for half, each with paired four-predecessor integer PHIs.
These CFG shapes are predicted because the accepted report stops earlier at
FP-to-integer cast admission.

### Six FP-To-I128 Rows

These rows have no switch and no loop. The unsigned forms end in one
four-predecessor `i128` PHI with incoming `-1`, `0`, and two named values. The
signed forms use one three-predecessor `i128` return PHI and one nested
two-predecessor `i128` PHI. All six are observed at `stage2-phi-src`; the
captured rejected source is an exact i128 literal or named pair, not a new
destination class.

## Frozen Phase Contracts

### Phase 2: Captured Scalar Multiway PHIs

Extend only the existing stage-two PHI destination map and parallel edge-copy
authority. Admit these captured source/destination forms:

1. two-, three-, four-, six-, and seven-predecessor full-defined scalar PHIs;
2. paired `i32`/`i64` PHIs in one block, with all sources stabilized before
   any destination move;
3. existing GPR/spill scalar classes, scalar `half`/`float`/`double` XMM or
   FP-spill classes, and the existing i128 pair-spill class;
4. named scalar sources plus exact integer literals, and positive FP zero only
   where it is an actual captured incoming value;
5. overlap-safe parallel copies through the current value map and frame
   allocator, without a second PHI allocator or edge-copy path.

Fail closed for pointer PHIs, vectors, aggregates, poison/undef, nonzero FP
constants, x87/fp128, dynamic predecessor discovery, and any destination class
not already owned by the value map. The phase must include crossed-source
microcanaries for paired PHIs and i128 literal/named sources.

Honest expectation: up to the six FP-to-i128 rows may close provisionally if
their refresh confirms no later form; the six exposed EI rows and `fma` only
gain foundation and remain blocked at switch edges. A phase-2 implementation
requires its own shared-CFG review and acceptance evidence before phase 3.

### Phase 3: Exact EI Entry Switch Edges

Admit switch-owned edge stubs only for the six scalar EI-to-FP entry switches:

- condition type exactly `i16`;
- case set exactly `0`, `1`, `2`, `3`, `4`, plus one default;
- one six-predecessor return PHI of exactly `half`, `float`, or `double`;
- case-0 incoming exactly positive zero;
- every case/default edge stabilizes all sources and invokes the existing
  parallel PHI-copy authority before jumping to the real successor;
- the compare chain retains operand masking, duplicate-case rejection, and
  existing switch ownership checks.

Fail closed for arbitrary case sets, multiple PHI-bearing successors outside
this shape, pointer/vector/aggregate PHIs, x87/fp128 results, indirect
branches, jump tables, and the fma `i11`/`i32` switches. The fma switches need
a separately reviewed admission after the EI result is known.

Honest expectation: zero closures. The six rows should advance into their
wide-conversion/default-loop bodies. A refreshed exact diagnostic inventory is
the mandatory phase-3 stop state.

### Phase 4: Exact EI Loop And Narrow-PHI Bodies

Only after the phase-3 refresh, admit the six scalar EI default bodies as the
captured typed family:

- first loop: exactly two full-defined `i64` PHIs, one preheader and one
  backedge, scanning `i32` limbs with the existing `ctlz.i32` semantics;
- second loop: exactly one full-defined `i64` PHI, one preheader and one
  backedge, scanning discarded `i32` limbs;
- two-way rounding-state PHIs of `i1`, plus the captured f32-only two-way
  `i32` merge;
- two-way packed-result PHIs exactly `i55`/`i56`, `i26`/`i27`, or
  `i13`/`i14`, normalized through the existing GPR width authority;
- exact read-only limb GEP/load forms and exact i96/i128 case loads and
  signed/unsigned conversions required by the refreshed six bodies.

Fail closed for runtime-sized PHI types, irreducible or multi-backedge loops,
pointer loop PHIs, writable EI inputs, other limb widths, x87/fp128, and any
wide conversion not present in these six captured bodies.

Honest expectation: the six scalar EI-to-FP rows are the strongest closure
set, but closure remains conditional on the phase-3 refresh proving the
enumerated forms are complete. `fma` has zero expected closure in this phase.

## Order And Review Boundaries

The review #13 order is confirmed with one tightening: fma switch admission
must not ride along with the EI switch cycle because this census proves its
multiway PHIs are not its last blocker.

1. Phase 1: this census and contract freeze. Stop for architectural review.
2. Phase 2: scalar multiway-PHI source/copy foundation. Stop after its
   shared-CFG acceptance and refreshed report.
3. Phase 3: exact six-row EI entry-switch edges. Stop with the newly exposed
   diagnostics; review any contract mismatch before entering loops.
4. Phase 4: exact EI loops, narrow PHIs, and refreshed supporting forms.
   Accept closures only through row-exact native semantics and the validation
   tier authorized for that phase.
5. Re-rank fma after phase 4. Its separate switch forms and later
   `ctlz.i52`/copysign/vector work require routine typed cycles or another
   bounded review; no closure is pre-authorized here.

Preopt sharding remains unauthorized and unrelated to this program.

## Stop State

Phase 1 is complete. Request architectural review of the frozen phase-2
multiway scalar-PHI contract before any implementation. No phase-2 code,
switch-edge work, EI-loop work, fma widening, or preopt sharding is authorized
by this evidence commit.
