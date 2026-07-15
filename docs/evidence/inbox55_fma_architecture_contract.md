# INBOX-55 Fma Architecture Contract Review

INBOX-55 is acknowledged by this read-only evidence cycle.

## Baseline And Method

- Accepted implementation baseline: `21aaf111`
- Accepted compiler_rt report: 443 selected / 284 emitting / 159 failing
- Report log: `tmp/inbox54_report.log`
- Captured IR:
  `tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll`
- Captured-IR md5: `b0eda7a6427c3084fdf096a68696f19c`
- Stage4 Zig pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`

This cycle changes no selector or gate implementation and runs no gate.
`Observed` below means the accepted report names the diagnostic. `Predicted`
means the form occurs later in the frozen captured body and has been checked
against the accepted selector implementation, but remains hidden by an earlier
failure. Predicted forms are not emission or closure claims.

## Observed Frontier

The accepted report records:

```text
zllvm-codegen-failure function=compiler_rt.fma.fma diagnostic=UnsupportedCodegenControlFlow selector_tag=no_emitter selector_detail=stage2-switch-phi-edge
```

The exact rejection is in `composed_selector_cfg.lowerSwitch`. The generic
compare-chain accepts integer switch conditions up to 32 bits, normalizes
narrow conditions in EAX, and rejects duplicate cases. When any direct switch
target has a PHI incoming from the switch predecessor, it currently admits
only the exact EI entry-switch shape. The first fma `i11` switch has such a
direct PHI edge and therefore reaches `stage2-switch-phi-edge` before machine
emission.

The seven-incoming `double` return PHI, the three-incoming adjusted-result
`double` PHI, the four-incoming ilogb `i32` PHI, and the three pairs of
four-incoming frexp `i32`/`i64` PHIs are already admitted by the accepted
multiway scalar-PHI foundation. No new PHI destination or value-location
class is required.

## Complete Switch Inventory

### Frexp Switch 1

- Condition: named `i11 %24`, produced by truncating `lshr i64 %21, 52`;
  `%21` is the bitcast of fma argument 0.
- Cases: `i11 0 -> Case.i`, `i11 -1 -> frexp.exit`.
- Default: `Default.i`.
- Direct switch-to-PHI edge: only case `-1` jumps directly to `frexp.exit`.
- Join: four predecessors with two simultaneous PHIs:
  - `i32`: named default result, named subnormal result, zero from `Case.i`,
    zero from the switch predecessor;
  - `i64`: named default bits, named subnormal bits, `%21` from `Case.i`, and
    `%21` from the switch predecessor.
- Required direct-edge parallel copy: stabilize exact i32 zero and named i64
  `%21`, then materialize both through the existing parallel PHI-copy
  authority before entering the join.

### Frexp Switches 2 And 3

The switches on `%47` and `%70` repeat the first shape exactly for arguments 1
and 2. Their conditions are named `i11`, their case sets are `{0,-1}`, and
their `-1` cases directly enter paired four-incoming `i32`/`i64` joins. The
switch-predecessor sources are respectively `(i32 0, i64 %44)` and
`(i32 0, i64 %67)`.

These are three uses of one structural capability, not three admissions.

### Ilogb Switch

- Condition: named `i32 %142` from the exponent bits of `fabs(%111)`.
- Cases: `0 -> Then.i.i`, `2047 -> Then2.i.i`.
- Default: `Else2.i.i`.
- Join: a four-incoming `i32` PHI at `math.ilogb...exit`.
- Direct switch-to-PHI edge: none. Each switch target performs work or a
  branch before entering the join.
- Parallel-copy requirement on a switch edge: none.

This switch is already inside the generic compare-chain authority. The same
captured shape occurs in accepted `compiler_rt.divdc3.__divdc3`; it must not
be widened or reimplemented as part of fma.

## Post-Switch Blocker Sequence

The accepted report observes only `stage2-switch-phi-edge`. The sequence below
is predicted from the frozen body and current selector admission.

### Missing I52 Normalization Surface

Each of the three frexp subnormal paths contains the same operations:

1. `icmp eq i52 %fraction, 0`;
2. `llvm.ctlz.i52(i52 %fraction, i1 true)`, result range `[0,53)`;
3. `trunc i52 -> i6`, then `add i6 1`;
4. unsigned `icmp ult i6 %count, -13`, where `-13` is the modulo-i6 pattern
   51;
5. `zext i6 -> i52`;
6. variable `shl i52`;
7. `zext i52 -> i64`;
8. select between the widened shifted value and i64 zero;
9. `trunc i52 -> i32` for the exponent correction.

The current selector has dedicated ctlz lowering only for i16, i32, and i64.
Its general equality path admits named operands at widths up to 32 or exactly
64, and its scalar cast/binary paths do not expose a general 52-bit surface.
Therefore the likely first diagnostic after switch admission is the i52
zero comparison, not yet `ctlz.i52`. The complete sequence must be treated as
one typed normalization family; adding only ctlz would reveal one adjacent
width rejection at a time.

The required representation is not new: an i52 value remains a normalized
low-52-bit scalar in the existing 64-bit GPR/spill location class. Every i52
definition must mask or otherwise prove the upper 12 bits zero before later
unsigned operations. No new register class, value map, spill allocator, or
frame object is needed.

### Existing Scalar And Vector Ownership

After the frexp paths, the body uses:

- scalar f64 add, subtract, multiply, comparisons, select, fabs, and
  bitcasts;
- two direct internal fastcc callees across four call sites, using the
  existing f64/i32 scalar call ABI;
- one f64x2 construction from lane-0/lane-1 inserts, one packed multiply by
  a splat constant, packed subtract and add, and constant lane extraction;
- scalar `llvm.copysign.f64`;
- the generic i32 `{0,2047}` switch, existing `llvm.ctlz.i64`, and existing
  scalar multiway PHIs.

All of these forms have accepted owners. In particular,
`composed_selector_vector` already admits full-defined f64x2 insert/extract,
splat constants, and packed fadd/fsub/fmul, while
`composed_selector_fp.lowerCopySignF64` owns scalar copysign. They remain
predicted until a refreshed fma attempt reaches them, but this review finds no
new operation or location class in that tail.

Hidden register pressure, internal-call source stabilization, or an
unrecognized attribute may still become the next observed frontier. The
contract therefore permits one closure only conditionally after executable
proof; static inventory is not acceptance.

## Collateral Census

| Proposed or reused capability | Captured users | Consequence |
| --- | --- | --- |
| Exact `i11 {0,-1,default}` switch with direct paired i32/i64 PHI edge | Three switches in `compiler_rt.fma.fma`; one in failing `compiler_rt.fixdfei.__fixdfei` | The switch cycle should advance fma and may advance fixdfei only after that row clears its earlier observed FP-to-int cast blocker. No collateral closure is expected. |
| Typed i52 normalization operations and `ctlz.i52(true)` | Three sequences in fma; one in failing `__fixdfei` | Fma is the only immediately exposed user. `__fixdfei` remains blocked earlier and is not a closure claim. No accepted row uses ctlz.i52. |
| Scalar `copysign.f64` | Two calls in the accepted double ldexp helper, one in fma, one in accepted `__divdc3`, and twelve in deferred `__muldc3` | This is accepted shared functionality. Fma adds coverage but no capability. Reimplementation would create mixed ownership. |
| Full-defined f64x2 insert/splat/fmul/fsub/fadd/extract | Seven operations in fma and broad captured use in accepted div/log/trig rows | Existing vector ownership is sufficient. Preserve its register/spill and defined-lane rules. |
| Generic i32 `{0,2047}` compare-chain switch | Fma and accepted `__divdc3` | Existing behavior only; include it in whole-row execution, not in the new switch admission. |
| Multiway scalar PHIs and parallel edge copies | Fma plus the accepted EI and aggregate work that established the authority | Extend only switch-edge routing into that authority. Do not add a second PHI planner or copy engine. |

The float and half FP-to-EI siblings contain related `i8` and `i5` frexp
switches. They are explicitly outside this contract. The x87/fp128 fma
siblings remain at their existing return-type wall.

## Proposed Implementation Contract

### Phase 1: Exact Frexp Switch Edge

Admit a switch edge only when all of the following are structurally true:

1. condition is a named `i11` value;
2. case values are exactly modulo-i11 `0` and `-1`, with distinct targets and
   one distinct default;
3. exactly the `-1` case directly targets one block containing exactly two
   full-defined PHIs, i32 and i64, each with the same four predecessors;
4. the switch predecessor contributes exact i32 zero and a named i64 value;
5. the other direct targets have no incoming from the switch predecessor;
6. duplicate cases, missing targets, or ambiguous predecessor names remain
   rejected.

Lower the PHI-bearing case through an owned edge stub. Stabilize both incoming
sources before materializing the switch condition, then call the existing
`emitPhiEdgeMoves` parallel-copy authority and jump to the real join. Reuse or
factor the EI edge-stub machinery; do not duplicate source stabilization,
spill handling, or copy ordering.

Keep fail-closed: other condition widths or case sets; more than one direct
PHI target; other PHI counts/types/predecessor populations; pointer, vector,
aggregate, x87, or fp128 PHIs; poison/undef edge sources; indirect branches;
jump tables; duplicate cases; and any unproven default rewrite.

Expected report movement: zero closures. Fma should advance from the observed
`stage2-switch-phi-edge` to the first i52 form. `__fixdfei` is expected to stay
at its earlier `composed-block-cast-from-not-int` frontier.

Executable coverage:

- a synthetic frexp-shaped canary exercises default, zero, subnormal, and
  all-ones exponent paths and compares both PHI results exactly;
- a crossed/pressured variant keeps the named i64 edge source live while the
  i11 condition is materialized and forces register/spill edge copies;
- structural negatives reject altered widths, cases, PHI types/counts,
  poison sources, and a second PHI-bearing switch target.

Because this changes switch handling through shared CFG/parallel-copy
surfaces, Phase 1 ends with one Tier 3 and a refreshed exact fma diagnostic.
Do not begin Phase 2 if the observed frontier differs from this inventory.

### Phase 2: Type-Driven I52 Normalization

Add the narrow operation set, not a generic arbitrary-width integer backend:

- normalized `trunc i64 -> i52`, `zext i6 -> i52`, `zext i52 -> i64`, and
  `trunc i52 -> i6|i32`;
- named i52 equality with zero;
- `llvm.ctlz.i52` only with its second immarg exactly true, producing
  normalized i52 in range `[0,53)`;
- variable i52 left shift with a normalized in-range shift count and a
  normalized low-52-bit result;
- plain unsigned i6 comparison against the exact modulo pattern 51;
- existing i6 add and i64 select consumption without a parallel odd-width
  location authority.

Admission is operation- and type-driven. It may be reused by the one captured
`__fixdfei` sequence when that row reaches it, but it must not key on a
function name. Keep fail-closed: ctlz with a false or nonliteral second
argument, other odd widths, arbitrary i52 binary operations, signed i52
comparisons, i52 memory objects, i52 parameters/returns, unknown shift-count
provenance, and any form requiring a new register, value-map, or frame class.

Executable coverage must compare the complete normalization sequence against
precomputed integer results for fraction zero (guard path), each single-bit
position, dense patterns, minimum/maximum normalized i52 values, and ctlz
counts 50, 51, and 52 around the modulo-i6 comparison boundary. Upper-bit
garbage must be made observable so missing normalization fails. Separate
negative tests retain all excluded forms.

Then run a pinned-Zig callconv(.c) executable against the emitted fma symbol
with precomputed exact result bits. The matrix must cover ordinary exact and
inexact products, cancellation where fused and separate multiply/add differ,
rounding ties on both sides, normal/subnormal boundaries, underflow and
overflow, both signed zeros, infinities, and quiet/signaling NaN inputs. NaN
expectations must follow the frozen compiler_rt implementation and compare the
required payload/sign bits rather than accepting any NaN. Cases must exercise
all three frexp populations and both post-frexp scaling branches. Object
inspection must also reject a recursive or external fma libcall.

Expected report movement: at most one provisional closure,
`compiler_rt.fma.fma`, moving 443 / 284 / 159 to 443 / 285 / 158. That closure
is conditional on the refreshed selector, native link, and executable matrix;
any newly observed pressure, call, vector, or attribute diagnostic is reported
honestly instead. `fmal`, `fmaq`, `__fixdfei`, and all x87/fp128 rows remain
outside the closure claim.

Closing the fma row is a milestone and the typed surface touches shared scalar
selection, so Phase 2 ends with one cumulative Tier 3. The complete program
therefore requires two Tier-3 runs absent a P0 correction: one at the shared
CFG Phase-1 boundary and one at final fma acceptance.

## Preopt-Sharding Recommendation

Run the separately reviewed preopt-sharding interlude before fma
implementation, if the user authorizes it as its own commit sequence. The
accepted gate wall is about 1,338 seconds and the 146-case preopt child now
accounts for about 562 seconds, roughly 41 percent. The fma contract has two
unavoidable Tier-3 boundaries, so leaving the dominant child serial pays that
cost twice, and the optimization would also apply to later endgame gates.

The interlude must remain bounded to deterministic isolated shards of the
146-case preopt gate, preserve manifest-order reporting, execute every case,
and compare sequential/concurrency-1 and bounded-parallel semantic summaries
on the same implementation state. It should retain the standing ten-percent
go/no-go for full-gate wall time. If a reviewed design cannot credibly meet
that threshold without changing compiler semantics or shared artifact
ownership, skip it and proceed with fma. Do not combine sharding and fma in
one commit or one acceptance claim.

This recommendation is scheduling evidence, not authorization. No sharding
or fma implementation was started here.

## Stop State

INBOX-55 is complete as a proposed contract. Request architectural review of
the two-phase fma program and separate user direction on the preopt-sharding
interlude. Switch-edge implementation, i52 widening, fma implementation, and
distribution optimization remain unauthorized by this evidence commit.
