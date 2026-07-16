# INBOX-77 pre-repair scalar-arithmetic producer inventory

This inventory was frozen before any INBOX-77 repair.  It describes the exact
reconstruction commit `8156c1e91c562bdb5a26e63a18c5f5e4738561bd` (tree
`9931dd8990b09b4f470cff758d54fb80b006452a`), based directly on accepted 5B
`f78eeed4`.  The preserved intermixed input is
`tmp/inbox74_intermixed_reslice_base.patch`, SHA-256
`bfc0a2a3fe25290d543077852213d3b0f1c962cc7eed131321c01bc42c06b888`;
the original preserved commit/tree are
`466be30cb2190e1b0683dc3244ea0b8ded56a968` /
`ecc5e0653a7151eaccab67686a90b8a1ff4afe4d`.

The accepted-row observations below use the frozen 443-function IR
`tmp/inbox63_accepted_cohort.ll` and subtract the 158 baseline failures in the
accepted-5B report.  They therefore name only rows in the accepted 285.  A row
can occur in several form groups.  “Observed rows” is an IR-form inventory, not
a claim that every textual occurrence reaches the same physical-location arm.
Focused selector tests cover the physical-location arms that the cohort does
not make independently observable.  The exhaustive operation/width/operand
shape to accepted-row expansion is committed alongside this file as
`inbox77_scalar_accepted_ir_occurrences.tsv`.

## Common old and new authorities

Before this reconstruction, accumulator-producing scalar arms used
`emitValueIntoEax`, `emitValueIntoRax`, or `emitValueIntoAccumulator`, followed
by `bindEax`, `bindRax`, or `bindAccumulator`.  Scratch-result arms used
`emitValueIntoScratch` plus `bindScratch`.  The migrated arms instead execute
`AccumulatorDefinitionTransaction.begin` → explicit `prepare(effect,
displacement)` → `materialize(ir.Value, typed definition)` → arithmetic through
the emission-time EFLAGS authority → `define` → `commit`.  There is no default
displacement policy.

For an EAX definition, transaction materialization accepts named values in
`arg32`, `scratch32`, `arg64`, `scratch64`, `spill64`, `eax`, or `rax`, plus a
32-bit immediate.  For an RAX definition it accepts `arg64`, `scratch64`,
`spill64`, `eax`, or `rax`, plus a 64-bit immediate.  Unsupported aggregate,
pair, vector, FP, pointer-stack, and 128-bit locations still fail closed.  A
non-accumulator RHS is accepted from width-correct argument/scratch registers;
the general named/named arm can reload a `spill64` RHS through RCX.  Named
accumulator RHS values are copied/relocated to a scratch register before the
new definition.

Policy meanings used below are exact: `reuse_source(name)` when the operand is
already resident and dead after the producer; `scratch_preferred` when the old
path preserved a live accumulator in a register where possible; `spill_live`
when the accepted arm used the spill envelope; and `spill_source(name)` when
the current accumulator operand must first become a named spill so the
post-prepare materialization performs the accepted exact reload.

## Static producer matrix

| Producer form | Widths and operand shapes | Accepted old path | Reconstructed transaction / explicit policy | Supported source locations | Accepted-cohort rows using the form |
|---|---|---|---|---|---|
| Boolean named/named `and`/`or` | EAX i1 | RHS→RCX; LHS→EAX; bind EAX | LHS transaction, `accumulatorArithmeticDisplacement(..., spill_live)` | common EAX set; named RHS→RCX | i1 `and`: 7 rows (`exp2.exp2`, `limb64.__mulo_limb64`, `log10.log10`, `log2.log2`, `mulo.__mulodi4`, `mulo.__muloti4`, `mulsc3.__mulsc3`); i1 `or`: 14 rows (the exp2/fixuns/floor/log/limb/sqrt families) |
| Narrow immediate `and` | EAX i8 | accepted immediate-RHS EAX materialize/bind | `scratch_preferred` or `reuse_source` through the transaction | common EAX set | no accepted i8 immediate occurrence; named/named i8 arithmetic occurs in 13 accepted rows and is deliberately rejected by this producer form |
| General narrow named/named binary | EAX i6, i7, i16, i32 and exact-EI i3/i4/i5/i13/i14/i26/i27 | preserve live accumulator; materialize LHS into EAX; emit op; bind EAX | `accumulatorArithmeticDisplacement(lhs, spill_live)`; same-physical aliases copy or relocate RHS first | common EAX LHS set; RHS arg/scratch/spill32-compatible; same EAX alias via RCX | i6: `fma.fma`, floatei/floatunei and the divmode/udivmode families; i7: adddf/divdf/subdf, rem_pio2l, ldexp and floatdi/floatundi; i16: 63 accepted rows across half, limb64, parity, shifts and ldexp; i32: 170 accepted rows across the compiler-rt scalar cohort. Swapped same-register alias and live-after cases are focused fixtures. |
| General RAX named/named binary | i64 | preserve live accumulator, resolve operands, LHS→RAX, emit, bind RAX | operand-role-specific `reuse_source`/`spill_live`; commutative accumulator RHS may be swapped; noncommutative RHS is copied to scratch | common RAX LHS set; RHS arg64/scratch64/spill64; accumulator alias via RCX/RDX | accepted occurrences: add 74 rows, and 84, or 58, sub 45, xor 31. Anchors include `fma.fma`, `fma.add_and_denorm`, `mulXi3.__multi3`, div/float/fix/limb64/shift rows. |
| Exact-EI named/named binary | exact i55/i56 (`or`; other machine binary ops admitted structurally) | RHS→RCX64; LHS→RAX; emit; bind logical-width RAX | transaction with `spill_live` in the frozen reconstruction; logical definition is `zeroExtendedRax(bits)` | common RAX LHS set; RHS arg64/scratch64/spill64 | i55 `or`: `floatuneidf.__floatuneidf`; i56 `or`: `floateidf.__floateidf` |
| Named/named variable shift | i16/i32 and exact-EI below 32 | RHS→RCX; LHS→EAX; shift; bind EAX | `accumulatorArithmeticDisplacement(lhs, spill_live)` | common EAX LHS; named RHS→RCX | i16 shl/lshr/ashr in 49 accepted rows (half/limb/shift/ldexp families); i32 shl/lshr/ashr in 114 accepted rows |
| Named/named variable shift | i64 and exact i55/i56 | RHS→RCX64; LHS→RAX; shift; bind RAX | transaction with `spill_live` in the frozen reconstruction | common RAX LHS; named RHS→RCX | i64 shl/lshr/ashr in 164 accepted rows; i55 shl `floatuneidf.__floatuneidf`; i56 shl/lshr `floateidf.__floateidf`, plus i56 lshr `floatuneidf.__floatuneidf` |
| Exact i52 variable shift | i52 `shl`, named/named, ctlz-derived count only | count→RCX64; LHS→RAX; shift and low-52 mask; bind RAX | `accumulatorSpillSourceDisplacement(rhs, spill_live)`; transaction defines `zeroExtendedRax(52)` | common RAX LHS; proven named count→RCX | `compiler_rt.fma.fma` |
| Named/named multiply | i32 (and any admitted width ≤32) | RHS→RCX; LHS→EAX; `imul`; bind EAX | `accumulatorArithmeticDisplacement(lhs, scratch_preferred)` | common EAX LHS; named RHS→RCX | 9 i32 rows: `divsf3`, `int.__divmodsi4`, `int.__modsi3`, `int.__udivmoddi4`, `int.__udivmodsi4`, `int.__umodsi3`, `mulXi3.__muldi3`, `rem_pio2_large`, `sqrtf` |
| Named/named multiply with scratch result | i64, ordinary/planned scratch/in-place | LHS stays or moves to planned/reusable scratch; RHS arg/scratch/RAX/spill; bind scratch | result remains on its accepted scratch path; every `imul` is routed through EFLAGS `.write` only | LHS scratch64/arg64/RAX/spill64; RHS scratch64/arg64/RAX/spill64 | 19 rows: divdf/divsf, divmode/udivmode, `int.__udivmoddi4`, `limb64.__mulo_limb64`, `memmoveFast`, `mulXi3.__muldi3`, `mulXi3.__multi3`, `mulo.__mulosi4`, `mulsf3`, `mulvsi3`, `sqrtf` |
| Multiply spill-through-RAX fallback | i64 named/named when no scratch destination exists and LHS is spilled | accepted direct LHS→RAX; `imul rax,reg/mem`; bind RAX | transaction `spill_live`, materialize full RAX, define/commit | LHS spill64; RHS arg64/scratch64/spill64 | exercised by focused spill-pressure fixtures and `mulXi3.__multi3` canary; cohort text shares the i64 multiply rows above |
| Immediate RHS signed divide-by-two | i32 `sdiv x, 2` | LHS→EAX, copy/sign-bias/shift, bind EAX | `accumulatorArithmeticDisplacement(lhs, scratch_preferred)` | common EAX LHS | no admitted accepted-cohort row with the exact constant-2 form; focused fixture only (cohort has named/named sdiv in powi rows, which this arm rejects) |
| Immediate RHS logical shift | i16/i32 constant `lshr` | LHS→RCX scratch, shift in place, bind scratch | result deliberately remains on accepted scratch path; EFLAGS `.write` annotation only | common EAX-compatible value convertible to RCX | accepted i16 constant shifts in limb/parity/floor rows and i32 constant shifts in count0bits/trunc rows |
| Immediate RHS logical shift, planned/scratch/spill fallback | i64 constant `lshr` | planned/reusable scratch first; spill a scratch source if needed; final fallback LHS→RAX and bind RAX | scratch arms unchanged; spill-through-RAX transaction uses `spill_live` | arg64/scratch64/spill64/RAX; fallback requires spill64 | accepted occurrences in limb64, count0bits, parity, rem_pio2_large, trunc and `mulXi3.__multi3`; spill-through fallback covered by pressure fixture/canary |
| Immediate RHS left shift | i1/i6/i7/i8/i16/i32 and exact narrow ≤32; i64 | ≤32 LHS→EAX (special reusable scratch32 destination retained); i64 LHS→RAX; shift; bind | ≤32 `accumulatorArithmeticDisplacement(lhs, scratch_preferred)` except existing scratch32 result arm; i64 `accumulatorSpillSourceDisplacement(lhs, spill_live)` | common EAX/RAX sets by width | accepted constant-shift rows across limb64/float/floor/rem_pio2; i64 includes `mulXi3.__multi3` |
| Immediate RHS arithmetic right shift | ≤32; i64 | ≤32 LHS→EAX/bind; i64 LHS→RCX scratch, shift, bind/spill scratch | ≤32 transaction with `spill_live`; i64 result deliberately remains accepted scratch | common EAX set; common 64-bit scratch materialization set | accepted ≤32 rows across float/int/rem_pio2/shift; i64 across divmode/int/limb/rem_pio2/shift/udivmode |
| Immediate RHS `and` | ≤32; i64 general; i64 mask `0xffffffff` | ≤32 LHS→EAX; general i64 LHS→RAX plus RCX immediate; max-u32 uses EAX mask; bind accumulator | ≤32 `scratch_preferred`; general i64 frozen reconstruction `spill_live`; max-u32 `accumulatorSpillSourceDisplacement(lhs, spill_live)` | common EAX/RAX sets | ≤32 half/single/limb/rem rows; i64 named/immediate rows in divmode/udivmode and rem_pio2; max-u32 is the permanent `mulXi3.__multi3` structural canary seam |
| Immediate RHS `or` | ≤32; i64 | ≤32 LHS→EAX; i64 LHS→RAX plus RCX immediate; bind | ≤32 `scratch_preferred`; i64 `accumulatorSpillSourceDisplacement(lhs, spill_live)` | common EAX/RAX sets | accepted immediate-or occurrences are sparse; structural i64 seam is covered by focused fixtures and shares float/limb/multi3 pipelines |
| Immediate RHS add/sub/xor | ≤32; i64 | ≤32 LHS→EAX/bind; fitting i64 add/sub stays scratch; large i64 add and i64 xor use RAX | ≤32 `scratch_preferred`; large i64 add and xor frozen reconstruction `spill_live`; fitting add/sub scratch arms unchanged | common EAX set; common RAX set for large immediates; arg/scratch for fitting i64 | accepted i16/i32/i64 immediate rows in limb64, rem_pio2 and float families; dynamic anchors include extend/float/fix rows for add64 and float rows for xor64 |
| Immediate LHS subtraction | i1/i6/i7/i8/i16/i32; i64 | RHS→RCX; immediate→EAX/RAX; subtract; narrow mask; bind | transaction `spill_live`, immediate materialization, define/commit | RHS named materializable to RCX; immediate EAX/RAX definition | 16 i6 rows, 6 i7 rows, 21 i16 rows, broad i32 rows, and 22 i64 rows including neg/fix/float/memory/rem; i64 anchors `__negdi2`, `negv.__negvdi2` |
| Immediate LHS variable shifts | i16/i32 `shl`; ≤32/i64 `lshr` | amount→RCX; immediate→EAX/RAX; shift; bind | transaction `spill_live`, immediate materialization | named amount materializable to RCX | accepted i16/i32/i64 occurrences in parity/floor/count0bits/rem rows; focused fixtures cover every width arm |
| Quotient-producing unsigned divide | i32/i64 named/named `udiv` | RHS→RCX (before/after LHS according to accumulator residency); LHS→EAX/RAX; zero EDX; `div`; bind accumulator quotient | transaction with `accumulatorArithmeticDisplacement(lhs, spill_live)`; division is EFLAGS `.clobber`; define/commit quotient | common EAX/RAX LHS; RHS accumulator or arg/scratch/spill via RCX; fixed RDX is clobbered but never owned as result | i64: 9 divmode/udivmode/udivmod rows; i32 quotient rows in `int.__udivmodsi4`, `int.__udivsi3` and related composed integer helpers |
| Arithmetic call result: `llvm.usub.sat.i64` | named LHS, nonnegative immediate RHS | accepted LHS→RAX, immediate→RCX, subtract/branch/zero, bind RAX | full-RAX transaction, frozen reconstruction policy `spill_live`; carry `.definition` then branch `.use` | common RAX LHS; immediate RHS | `floateidf`, `floateihf`, `floateisf`, `floatuneidf`, `floatuneihf`, `floatuneisf` |
| Overflow calls `uadd/usub.with.overflow.i32` | two i32 operands, aggregate result | direct EAX value plus carry consumer; aggregate value/overflow locations retained | no accumulator-result transaction in this slice; arithmetic/compare instructions only gain EFLAGS definition/use authority | lhs/rhs EAX-compatible plus scratch; aggregate remains scratch32+EAX | limb64 add/sub and compiler-rt overflow helper rows |
| Signed multiply-overflow calls | i64 and i128 aggregate forms | fixed full-product and pair/spill machinery | existing full-product/pair ownership is unchanged and excluded; only contained arithmetic and compare instructions gain EFLAGS annotations | existing fixed RAX/RDX and pair spill envelope | `mulo.__mulodi4`, `mulo.__muloti4`, `limb64.__mulo_limb64` and related overflow rows |
| Other arithmetic call producers | `fabs` masks; ctlz i16/i52 adjustments; ctpop i128 limb add; `zig.target.intByteSize` mask; direct-call stack-pointer add | existing scratch/accumulator/call-result paths | no result migration where not accumulator-producing; only emission-time `.write` classification | existing call-specific locations | accepted fma/fp, float-ei, limb64/count0bits, `zig.target.intByteSize`, and direct-call rows |

The exact-EI admission list is i3/i4/i5/i13/i14/i26/i27/i55/i56, plus the
separate proven i52 shift family.  Thus the exact 33–63-bit families migrated
here are i52, i55, and i56; all other 33–63-bit widths remain fail-closed rather
than being silently widened.

## Residual direct-producer inventory at the frozen reconstruction

These are exclusions, not INBOX-77 deferrals: `urem` remains an RDX-result
producer; full-product RAX/RDX paths remain direct; i128 pair-result arithmetic
and pair-result overflow machinery remain direct; and no producer requiring a
new pair, RDX, location, allocator, CFG-aware-EFLAGS, or block-state authority
is migrated.  Scratch-result scalar forms listed above also remain direct by
design because they do not define the accumulator.

At this pre-repair point there are **no recorded deferrals** of an ordinary
accumulator-producing scalar form.  Any later deferral must be appended here
with its exact form and reason before 5C can be reviewed.

## Predicted structural seams before repair

The static comparison predicts exactly four accumulator-source reload seams:
`composed-block-and64-lhs` (with the already reconstructed max-u32 repair), its
`or64-lhs` sibling, large-immediate `add64`/`xor64` using the same RAX
materialization pattern, exact-EI `binary-lhs`/`shift-lhs`, and the arithmetic
call `usub-sat-lhs`.  They all replace accepted `emitValueIntoRax/Eax`
materialization with `transaction.materialize(...)` and therefore must choose
the typed source-spill policy before preparation.  No pair/RDX/allocator/CFG
authority is predicted.

## Post-repair residual audit

The completed structural batch stayed inside the forms enumerated above.  The
RAX seams now use one typed preservation policy that reproduces the accepted
`preserveRaxForDestructiveAccumulatorUse` behavior: a current-use/live
accumulator is spilled before destructive materialization, while an expired
operand already in RAX is reused without a spill/reload pair.  The EAX direct
materialization forms (boolean named/named, named variable shifts, and the
quotient-producing `udiv` path) likewise reuse an accumulator-resident source
without changing its accepted stream.  The enumerated named i32 multiply form
prepares/preserves the accumulator before materializing its RHS, preserving the
accepted operand order.

Focused tests were committed on the reconstruction branch before each repair:
the original source-reload seam tests (`771b24f2`), accumulator-resident direct
materialization tests (`55807699`), current-use RAX preservation test
(`ce1aafb2` plus fixture-syntax correction `dac83f2a`), and multiply-order test
(`a30b2cac`).  The repaired scratch branch ends at `b0873b5b087c9e0e54342ba0715a4345a311f6d2`
(tree `984457ba469e05158ea6d2a29cb09dfffb1e27f8`).

There are **zero INBOX-77 deferrals**.  The residual direct-producer inventory
is therefore exactly the predeclared exclusions above: `urem`'s RDX result,
full-product RAX/RDX, pair-result arithmetic/overflow, and non-accumulator
scratch-result forms.  No new pair/RDX ownership, location authority,
allocator widening, CFG-aware EFLAGS authority, or block-state authority was
added.
