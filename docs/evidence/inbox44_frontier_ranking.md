# INBOX-44 Frontier Ranking

INBOX-44 is acknowledged by this read-only evidence cycle.

## Baseline And Method

- Accepted implementation commits: `078812c2`, `1aede958`
- Accepted report: `tmp/inbox43_f32x4_report.log`
- Report summary: 443 selected, 248 emitting, 195 failing
- Report sha256:
  `5f8ae3358d64ac18bca667d5dc79178c0462e3f52129f3488c0b657774d0d274`
- Captured IR:
  `tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll`
- Captured-IR md5: `b0eda7a6427c3084fdf096a68696f19c`
- Stage4 Zig pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`

This inventory changes no implementation and runs no gate. It derives the
ranking from the accepted report, captured IR, and current selector admission.
`Observed` means the accepted report names the diagnostic. `Predicted` means a
later operation is present in captured IR after the observed first failure; it
is not an emission or closure claim.

Under the 2026-07-14 row-closure batching amendment, future routine closures
below are provisional on focused Tier 2 plus exact native row evidence. One
cumulative Tier 3 accepts each completed pipeline. A read-only inventory does
not trigger Tier 3.

## Ten Icmp-Form Rows

The ten observed `composed-block-icmp-form` rows do **not** share one exact
typed form. They separate into three populations.

| Population | Rows | Observed missing form | Later frontier | Honest immediate effect |
| --- | --- | --- | --- | --- |
| i64-to-FP normalization | `__floatundidf`, `__floatundisf`, `__floatundihf`, `__floatdidf`, `__floatdisf`, `__floatdihf` | `icmp samesign ult i7 %normalized_shift, immediate`; half results later use `samesign ugt i7 ..., 15` | All six later call `llvm.cttz.i64`; the half rows also need the i7 `ugt` form | zero closures from i7 comparison alone; six advances |
| i32-to-half normalization | `__floatunsihf`, `__floatsihf` | The existing i6 `samesign ult` clears; the first missing form is `icmp samesign ugt i6 ..., 15` | `cttz.i32`, equality, narrow shifts, and half construction are already admitted | two expected provisional closures |
| Half bit-pattern comparison | `__gehf2`, `__cmphf2` | Named i16 signed `slt` first, followed by named `sgt` and `ne` on the same two bit patterns | Existing i16 immediate comparisons, scalar selects, zext, and i32 return PHI | two expected provisional closures only if the full three-predicate matrix lands |

The first coherent capability is a width-normalized narrow unsigned-immediate
comparison:

- integer widths exactly i6 and i7;
- predicates exactly `samesign ult` and `samesign ugt`;
- named lhs and in-range immediate rhs;
- mask the source to its declared width before unsigned comparison;
- preserve existing i6 behavior and reject other predicates, widths, named
  rhs values, and out-of-range immediates.

Coverage must exercise 0, maximum, and both sides of every captured threshold:
11, 15, 24, and 53. This capability is reusable across all eight conversion
rows but closes only the two i32-to-half rows immediately. A refreshed report
should then expose exact `llvm.cttz.i64` in the six i64 rows. The current
machine and verifier already own an i64 count-trailing-zero form, so a second
typed intrinsic cycle is predicted to close up to six rows; that count remains
conditional until the first cycle refresh confirms no intervening diagnostic.

The half wrappers require a separate named-i16 comparison capability:

- exact predicates `slt`, `sgt`, and `ne`;
- two named i16 operands;
- ordinary signed ordering for `slt`/`sgt` and bitwise inequality for `ne`;
- no widening to floating semantics and no name-specific admission.

Executable proof must compare raw half bit patterns, including both zeros,
subnormals, normals of both signs, infinities, and quiet/signaling NaNs. The
wrapper semantics use integer bit-pattern ordering after explicit NaN/sign
handling, so host FP comparison is not a valid oracle.

## Seven Switch-Phi Rows

The seven `stage2-switch-phi-edge` rows are two populations, not one bounded
implementation slice.

### Six EI Conversion Rows

`__floatuneidf`, `__floatuneisf`, `__floatuneihf`, `__floateidf`,
`__floateisf`, and `__floateihf` share one entry shape:

- `switch i16` with cases 0 through 4 plus a default loop;
- case edges eventually enter one six-incoming FP return PHI;
- the Entry-to-case-0 edge supplies positive zero directly;
- the result widths are double, float, and half for both signed and unsigned
  families.

This is one exact typed switch-edge population: stabilize and emit each
successor PHI incoming before the compare-chain jump without changing the
existing switch range proof or general PHI authority. It does not close the
rows. Cases 3 and 4 contain i96/i128 loads and `sitofp`/`uitofp`, beyond the
current scalar conversion slice, and the default bodies contain additional
wide/narrow integer and pointer-loop work. Honest expected closures are zero;
all six should advance to their next typed boundary.

### Fma

`compiler_rt.fma.fma` is a separate population. It contains three i11 frexp
switches, each joining paired i32/i64 PHIs, and a later i32 ilogb switch with
an i32 PHI. It also has a seven-incoming double return PHI outside those
switches. Later captured operations include `llvm.ctlz.i52`, scalar
`llvm.copysign.f64`, and packed f64x2 arithmetic. A switch-edge change is
therefore an advance with zero expected closure.

The bounded implementation order, if later authorized, is the six EI entry
switches first. Fma requires a separate review after that result; admitting a
generic switch-PHI mechanism merely because the diagnostic text matches would
hide materially different edge and value populations.

## Complete Divsc3 Remainder

The observed frontier is the first of two vector selects:

```llvm
%58 = select <2 x i1> %46, <2 x float> splat (float 1.0),
             <2 x float> zeroinitializer
%59 = call <2 x float> @llvm.copysign.v2f32(<2 x float> %58,
                                            <2 x float> %44)
```

The second fallback branch repeats the same pair as `%79`/`%80`. After those
operations, the full remaining body uses only already admitted forms:

- four lane-0/lane-1 f32x2 constructions;
- four packed multiplies;
- four exact `[1, poison]` lane shifts;
- packed add/subtract and constant lane-0 extraction;
- scalar multiply by infinity or zero;
- existing scalar FP stores through the aggregate-object pointers.

The bounded closing contract is therefore:

1. `<2 x i1>` condition in a fully defined canonical 32-bit-lane XMM mask;
2. `<2 x float>` true and false operands, both fully defined, selected by
   bitwise canonical-mask blending; no scalarized or GPR-canonical condition;
3. `llvm.copysign.v2f32` on two fully defined f32x2 values, preserving every
   magnitude bit and taking only each corresponding sign bit from operand 2;
4. alias-safe register/spill materialization through the existing XMM value
   map and pair-slot spill authority;
5. fail closed for f64, other lane counts, partial definedness, noncanonical
   masks, dynamic lanes, vector PHIs, and unrelated vector selects/calls.

Permanent execution must cover all four mask patterns and alias permutations.
Raw-bit copysign cases include both zeros, subnormals, finite normals,
infinities, and quiet/signaling NaN payloads. Exact extracted-row proof uses a
pinned-Zig `callconv(.c)` caller with precomputed normal, signed-zero,
infinite, and NaN-path results. Expected provisional closure is exactly
`compiler_rt.divsc3.__divsc3`.

## Divdc3 Vector-Phi Boundary

`__divdc3` remains a separate reviewed CFG/planner capability. Its current
frontier is a five-incoming, fully defined `<2 x double>` return-join PHI:

```llvm
%18 = phi <2 x double> [ %59, %Block12 ], [ %76, %Then10 ],
                       [ %96, %Then15 ], [ %43, %Else10 ],
                       [ %43, %Block2 ]
```

The bounded capability would assign one f64x2 vector PHI destination through
the existing value map, use the existing pair spill slots when needed,
stabilize each named incoming value, emit overlap-safe edge copies, preserve
the intersection of static defined-lane masks, and restore the destination at
block entry. It must not change aggregate ABI classification or add another
frame allocator.

Expected closures from the PHI capability alone are zero. Later captured
forms still outside the current selector include `llvm.fabs.v2f64`, scalar and
packed f64 copysign, canonical-mask f64x2 selects, and exact `[1,0]`/`[1,1]`
f64x2 shuffles. Those operation forms require a refreshed, separately bounded
cycle after the PHI capability. Do not merge this planner change into the
f32x2 `__divsc3` operation cycle.

## I128 Leaf Candidates

The leaf wrappers are stronger than the switch-PHI populations but do not form
one intrinsic capability.

| Capability | Exact rows | Contract | Expected provisional closures |
| --- | --- | --- | ---: |
| Pair compare | `__ucmpti2`, `__cmpti2` | `llvm.ucmp.i32.i128` and `llvm.scmp.i32.i128` over existing SysV i128 pairs; lexicographic high/low comparison, scalar -1/0/1 result followed by the captured add-one | 2 |
| Pair byte swap | `__bswapti2` | `llvm.bswap.i128`; bswap each existing 64-bit limb and exchange limb positions, preserving `rdx:rax` return ownership | 1 |

Bit-reverse and population-count wrappers are later operation-specific
capabilities, not justification for broad intrinsic admission. `__muldc3`
remains excluded at its 256-bit `<4 x double>`/AVX checkpoint.

## Ranking And Two Pipelines

The immediate capability ranking is:

1. normalized i6/i7 unsigned-immediate comparisons: two closures and six
   advances;
2. exact `llvm.cttz.i64`, conditional on the refreshed six-row frontier: up to
   six closures;
3. named i16 `slt`/`sgt`/`ne`: two closures;
4. i128 signed/unsigned pair compare: two closures;
5. bounded f32x2 vector select/copysign: exactly one closure, with greater
   shared-surface cost;
6. i128 pair byte swap: one closure;
7. EI switch-PHI edges: six advances, zero closures;
8. `__divdc3` vector PHI: zero closures and an explicit review boundary;
9. fma switch-PHI edges: one advance, zero closures.

After the authorized Phase 0-1 infrastructure interlude, use these next two
pipelines:

### Pipeline 1: Scalar Conversion Frontier

1. Land normalized i6/i7 `samesign ult`/`ugt` with Tier 2 and exact native
   proof; record the two half conversion closures as provisional.
2. Refresh the six i64 rows. If all expose `llvm.cttz.i64` as predicted, land
   the exact typed intrinsic with Tier 2/native proof and record up to six more
   provisional closures. If any row exposes another form, stop and rerank
   instead of widening the cycle.
3. Run one cumulative Tier 3 and accept the pipeline batch.

### Pipeline 2: Scalar Leaf Frontier

1. Land the named-i16 three-predicate matrix with Tier 2/native proof; record
   two provisional half-wrapper closures.
2. Land exact i128 signed/unsigned pair comparison with Tier 2/native proof;
   record two provisional leaf closures.
3. Land i128 byte swap only if the refreshed leaf frontier remains the exact
   one-instruction wrapper; record one provisional closure.
4. Run one cumulative Tier 3 at the scalar-leaf checkpoint.

The f32x2 `__divsc3` closing cycle ranks immediately after these two pipelines.
Its vector surface should batch with a compatible subsequent vector operation
cycle, not with the separately reviewed `__divdc3` PHI planner change.

## Immediate Next Contract

Before either capability pipeline, perform only the user-authorized Phase 0-1
infrastructure interlude from
`docs/roadmap/distribution_all_optimization_plan.md`: finish the same-state
fresh/cached timing and input inventory, define normalized output equivalence,
and identify why 14 of 17 subgates remain uncached. Do not begin Phase 2,
concurrency, broader cache design, or any capability implementation in that
interlude.
