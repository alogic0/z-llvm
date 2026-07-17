# INBOX-130 O2 scalar-arithmetic enumeration

Status: evidence-only inventory for review. No scalar action or production
wiring is designed or authorized by this document.

## Frozen basis and method

This audit is frozen against source commit
`78334569b9ace46a298efbfc2ef94e7f72d92214`, tree
`f3ef3820b6eb1844c2a23ed8f5a383ae5f3571a7`. The audited production file is
`src/codegen/x86_64/generic_cfg/composed_selector_scalar.zig`, SHA-256
`971533d068ae1c9767c2f1049076e8d9f8541d961cb61220a3305b1285654104`.

The current direct-resolution inventory is
`docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv`, SHA-256
`6e570be808d2aea9275809471f53846af7f54afdd908ab73e51218579ca8112d`;
it totals exactly **172** occurrences. The accepted-row textual cross-check is
`docs/evidence/inbox77_scalar_accepted_ir_occurrences.tsv`, SHA-256
`14614c6c33a431be2b30a3de12e3f68cfa7295a3cd9e76ee6c1d7635f878336b`.
The accepted 285-row owner set used to filter the frozen IR is
`tmp/inbox129_o2_r2/validation/owner_manifest.tsv`, SHA-256
`5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d`;
the IR is `tmp/inbox63_accepted_cohort.ll`, SHA-256
`d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4`.

The accepted-row lists below are IR-form observations. They prove that a row
contains a form, but do not pretend that textual IR reveals its run-time
`ValueLoc`. A row can occur in several groups and can contain several
occurrences of one group. Lowering remains fail-fast, so a first unsupported
operand shadows later occurrences. Source-home sets therefore come from the
accepted branch switches and focused selector tests, while cohort use comes
from the frozen IR/owner projection. This is the same conservative distinction
used by the accepted INBOX-77 scalar inventory.

## Notation and canonical home cross-product

The matrices use these abbreviations:

- `N32`: named integer with declared IR width at most 32; accepted homes are
  `arg32`, `scratch32`, `eax`, or a `spill64`/wider scalar binding whose
  canonical binding covers the semantic width and whose physical home exposes
  the low 32-bit view. Binding classes are `gpr32` or the explicitly compatible
  wider `gpr64`; the physical operation is 32-bit and defines EAX.
- `N64`: named i64 or exact-EI 33–63-bit integer; accepted homes are `arg64`,
  `scratch64`, `rax`, and `spill64`, with `gpr64` binding and 64 physical bits.
  Exact-EI results retain their logical width even though transport is 64-bit.
- `P128`: named i128 in `arg128`, `scratch128`, `stack128_value`, or
  `spill128`, with `gpr128`/pair binding and ordered 64-bit low/high limbs.
- `A32`/`A64`: EAX/RAX specifically. `S32`/`S64` and `G32`/`G64` mean
  scratch and argument homes of the stated physical width.
- `I`: typed integer literal carried as instruction semantics, not as a
  `ValueLoc`, binding, or durable relocation.
- `W`: every arithmetic instruction emitted through `emitArithmeticWrite`
  has an incidental EFLAGS `.write`; it defines no consumable condition.
  Amount-zero shift branches append no shift and therefore add no record.
- `D/U`: EFLAGS `.definition(.carry)` followed by `.use_and_clobber`;
  `C`: EFLAGS `.clobber`.

LLVM `nuw`, `nsw`, and `exact` flags do not create a separate machine carry or
overflow consumer in these scalar branches. They retain the same `W`
lifecycle as the underlying arithmetic. The only carry chain in the audited
branch family is the excluded i128 pair subtraction (`D/U`); division ends
with `C`.

For named operands the declared IR type in every row is the row width. The
binding may be physically wider only under the accepted low-bit compatibility
relation; that does not imply sign or zero extension. Pair limbs are read-only
views unless the result is itself one of the standing pair exclusions.

## Branch inventory: `lowerBinary`

| ID | IR form and accepted homes | Result / staging / first destructive write | Accumulator and EFLAGS lifecycle | Diagnostics and provenance | Cohort use, gateway disposition, action fit |
|---|---|---|---|---|---|
| B00 | Non-integer type, missing result, unadmitted width/op/form. No operands resolved. | No result and no write. | No transaction. | Missing result, non-int, width, then form/op diagnostics precede source failures. These are authority/form errors and have no request provenance. | No accepted composed row is claimed. Textual gateways unchanged because none are reached. Pure semantic pre-dispatch remains required. |
| B01 | i1 named/named `and` or `or`; lhs/rhs `N32` with semantic i1. Literals are rejected. | EAX i1. RHS→RCX, then prepare/materialize lhs→EAX; first write is RHS staging. Same named source legitimately targets RCX and EAX. | `.preserve` with direct-materialization/reuse-or-`spill_live`; binary is `W`; define `.zeroExtending(1)` after emission. | Form check, RHS failure, preparation, then LHS failure. Future mapping must use the matching rhs/lhs handle; authority errors stay unattributed. | `and`: 7 rows (`exp2.exp2`, `limb64.__mulo_limb64`, `log10.log10`, `log2.log2`, `mulo.__mulodi4`, `mulo.__muloti4`, `mulsc3.__mulsc3`). `or`: 14 rows in exp2/fixuns/floor/log/limb/sqrt. One RHS staging gateway disappears. Existing outer/subordinate mechanism fits, but a closed scalar-binary action is required. |
| B02 | i8 immediate `and` dispatches to IRHS; other i8 forms reject. | See IRHS. | See IRHS. | Width/op before source handling. | No distinct gateway here; semantic dispatch ownership changes only. |
| B03 | Width family i6/i7/i16/i32 and exact-EI i3/i4/i5/i13/i14/i26/i27 named/named `mul`. Both sources `N32`; same-source EAX/RCX use is legal. | EAX result. Prepare lhs first, then RHS→RCX, then lhs→EAX, `imul`; the preparation is intentionally before RHS staging. | `.preserve`, `scratch_preferred` or `reuse_source`; `imul` is `W`; zero-extending logical definition. | Width/form before preparation; transaction/preparation error before RHS; RHS before LHS materialization. Request attribution must preserve that ordering. | i32 multiply occurs in 9 accepted rows: `divsf3`, `int.__divmodsi4`, `int.__modsi3`, `int.__udivmoddi4`, `int.__udivmodsi4`, `int.__umodsi3`, `mulXi3.__muldi3`, `rem_pio2_large`, `sqrtf`. Named narrow forms share the accepted narrow family. One RHS gateway disappears. Needs the scalar binary action and subordinate session; no new multiply authority. |
| B04 | Named/named variable `shl/lshr/ashr`, widths i16/i32 and exact-EI below 32. lhs/rhs `N32`. | EAX result. RHS→RCX, prepare, lhs→EAX, shift by CL; RHS is first write. Same-source multi-destination is possible. | `.preserve`, direct reuse-or-`spill_live`; shift is `W`; zero-extending definition. | RHS staging failure precedes preparation/LHS. | i16 shifts occur in 49 accepted rows; i32 shifts in 114. Exact i13/i14/i26/i27 anchors are the float-ei rows. One RHS gateway disappears. Closed scalar shift action required. |
| B05 | Named/named variable `shl/lshr/ashr`, i64 and exact-EI i55/i56. lhs/rhs `N64`. | RAX/logical exact-EI result. RHS→RCX64, prepare, lhs→RAX, shift; RHS staging is first write. | `.preserve`, `spill_source` when a live accumulator exists, otherwise reuse/`spill_live`; shift `W`; `.fullRax()` or `.zeroExtendedRax(bits)`. | RHS failure precedes preparation/LHS; exact-EI diagnostics retain `ei-shift-rhs` then `ei-shift-lhs`. | i64 shifts occur in 164 accepted rows; i55 shl in `floatuneidf`; i56 shl/lshr in `floateidf` and lshr in `floatuneidf`. One RHS gateway disappears. Requires a 64-bit scalar shift action; no caller-selected scratch. |
| B06 | Exact-EI i55/i56 named/named non-shift machine binary. lhs/rhs `N64`. | RAX logical-width result; RHS→RCX, prepare, lhs→RAX, binary. | Same as B05; binary `W`. | Unsupported op precedes RHS; then `ei-binary-rhs`, preparation, `ei-binary-lhs`. | i55/i56 `or` rows are `floatuneidf`/`floateidf`. One RHS gateway disappears. Same closed 64-bit scalar-binary action fits. |
| B07 | General named/named scalar machine binary at admitted widths. Each operand may be `N32`/`N64`; current-home combinations are accumulator/accumulator, rhs-accumulator commutative, rhs-accumulator ordered, or neither. | EAX/RAX result. Legacy preamble preserves live accumulator and live lhs; then resolve lhs before rhs. Accumulator/accumulator stages rhs to RCX (relocating only if the names differ); commutative rhs-accumulator reuses rhs and consumes lhs at its current home; ordered rhs-accumulator stages rhs to RCX/RDX; otherwise prepare lhs, re-resolve rhs, reload spill→RCX if needed, then emit. First destructive write varies by home exactly as stated. | `.preserve`; operand-role-specific `reuse_source`/`spill_live`; binary `W`; typed definition. A same-source request may need accumulator plus scratch. A genuine physical cycle remains fail-closed. | Preamble errors, unresolved lhs, unresolved rhs, then branch-specific staging/width/home errors. Post-prepare rhs is canonically re-resolved. Future request attribution must not flatten lhs-before-rhs precedence. | Accepted named rows span i6/i7/i16/i32 and i64. The exact function sets and counts are frozen per width/op in `inbox77_scalar_accepted_ir_occurrences.tsv`; notable i64 row counts are add 74, and 84, or 58, sub 45, xor 31. All eight generic gateways (four resolves, two RHS scratch sites, relocate, and current-home binary) disappear. Needs a closed action with source-derived internal homes, same-source multi-destination, the accepted preamble, and one subordinate session. |
| B08 | i128 named/named pair `xor`, `or`, or `sub`; both operands `P128`. | Pair scratch result, owned by existing pair machinery. XOR/OR choose/materialize pair_a/pair_b and write both lanes. SUB materializes lhs→pair_b and rhs→pair_a, then overwrites lhs pair. Pair selection can expose overlap/cycles already governed by the existing chooser. | No accumulator result session. XOR/OR are existing lane writes with no semantic consumer. SUB is the exact low-limb `.definition(.carry)` followed by high-limb `sbb` `.use_and_clobber` (`D/U`). | Pair op validation, then legacy lhs/rhs materialization errors in branch-specific order. | Pair rows include compiler-rt i128 shift/multiply/overflow helpers. This is the standing pair-result exclusion; the dispatcher changes semantic ownership only, while all 12 `lowerPairBinary` bypasses remain. No O2 scalar action may absorb it. |
| B09 | i52 delegates to I52B; i64 mul delegates to M64; i32/i64 udiv/urem delegate to UD. | See subgroup. | See subgroup. | Dispatch precedes source handling. | Semantic transition only; textual deltas are charged to the leaf owner, never the dispatcher. |

`lowerBinary` therefore owns **13** current textual bypass occurrences and all
13 are ordinary named-use gateways in B01/B03–B07. A complete scalar action
migration can remove all 13. The i128 pair branch is protected by its separate
12-occurrence `lowerPairBinary` inventory and contributes no false delta here.

## Branch inventory: immediate operands

### `lowerBinaryImmediateRhs`

| ID | IR form and accepted homes | Result / staging / first destructive write | Accumulator and EFLAGS lifecycle | Diagnostics and provenance | Cohort use, gateway disposition, action fit |
|---|---|---|---|---|---|
| R00 | `sdiv i32 N32, 2` only. | EAX i32. Clobber RCX, prepare/materialize lhs, copy EAX→ECX, SHR sign, ADD bias, SAR. RCX clobber is first mutation. | `.preserve`, `scratch_preferred`/reuse; SHR, ADD, SAR are three successive `W` records. | Exact op/width/constant/named checks, RCX spill-envelope, preparation, lhs. | Focused accepted fixture; cohort named/named sdiv rows are not this branch. No counted direct gateway beyond transaction materialization. Needs an immediate semantic action; literal is metadata, not a request. |
| R01 | Constant `lshr`: i16/i32 lhs `N32`; i64 lhs `N64`; i128 lhs `P128`. | i16/i32: lhs→RCX and scratch result. i64: planned/reusable scratch, optional source spill, or final spill-through-RAX. i128: existing pair result. First write is the selected destination staging. | Scratch shifts are `W`; RAX fallback uses `.preserve/.spill_live`, `W`, and RAX definition. Pair path remains legacy pair ownership. | Amount validation is branch-local; lhs staging/home failure follows. The i64 fallback re-resolves only inside its parent helper. | Constant lshr appears in limb/count0bits/parity/rem/trunc and `__multi3`; i128 shift rows are pair exclusions. Two scratch gateways disappear. The helper `tryLowerLshr64SpillThroughRax/resolveValue` also collapses with this owner; pair semantics stay excluded. Requires one closed action that internally selects scratch versus RAX without exposing a location. |
| R02 | Constant `shl`: i1/i6/i7/i8/i16/i32/exact narrow lhs `N32`; i64 lhs `N64`; i128 lhs `P128`. | ≤32: existing `scratch32` source special case preserves EAX, stages through EAX, writes back to the same scratch; other homes use EAX result. i64 uses RAX. i128 is existing pair result. | Scalar shift `W`; `.preserve` with `scratch_preferred` (≤32) or preserve-current/`spill_live` (i64). Pair path excluded. | Amount then source/home; special scratch branch resolves before its first preservation. | Accepted constant shifts span limb/float/floor/rem and `__multi3`. One resolve plus one EAX gateway are removed by the complete action; i128 pair semantics remain without a counted direct gateway. Needs semantic immediate plus source-derived result-mode action. |
| R03 | Constant `ashr`: ≤32 lhs `N32`; i64 lhs `N64`; i128 only amount 127 with `P128`. | ≤32 EAX result; i64 lhs→RCX, shifts in place, binds and spills scratch result; i128 materializes sign mask pair. | Scalar shifts `W`; ≤32 subordinate session, i64 no accumulator result. Pair path excluded. | Width/amount precedes source staging. | Accepted ≤32 rows span float/int/rem/shift; i64 spans divmode/int/limb/rem/shift/udivmode. One scratch gateway disappears. Closed action must support both accumulator and durable scratch result without widening pair ownership. |
| R04 | Constant `and/or/add/sub/xor`, ≤32 lhs `N32`. | Usually EAX result after accepted preamble; the immediate is encoded or staged in RCX for xor. | `.preserve`, `scratch_preferred`/reuse; arithmetic `W`; typed EAX definition. | Op/width and immediate-range errors retain their current position relative to the preamble and source. | Exact per-width/op accepted rows are in the frozen TSV (examples: i16 add/and, i32 add/and, and narrow float-ei forms). No separate pair form. The generic immediate action removes no additional gateway beyond R02/R03/R05 because these branches materialize through the subordinate session already; named use still becomes transaction-owned. |
| R05 | Constant 64-bit `and/or/xor`, and large `add`; lhs `N64`. `and 0xffffffff` uses EAX write semantics while defining logical i64. | RAX result. Prepare/materialize lhs; general constants stage RCX then binary. Small signed add/sub below use scratch form R06. First mutation is preparation/preservation or RCX staging as audited. | preserve-current/reuse-or-`spill_live`; binary `W`; full-RAX definition. `and 0xffffffff` uses EAX zero-extension proof. | Branch-specific `*-64-lhs` precedes immediate conversion where it does today. | Structural anchors are `__multi3`, fma, float/fix, limb and rem rows; the accepted 5C failure inventory records the former and64/or64/add64/xor64 seams. No extra direct gateway beyond the common action-owned lhs. |
| R06 | i64 small signed `add` and `sub`; lhs `N64`. | lhs→RCX, arithmetic in place, bind scratch64. | No accumulator session; arithmetic is `W`. | Immediate i32-range check occurs before staging; lhs failure follows. | Accepted i64 immediate add/sub rows in limb/rem/address-like scalar helpers. Two scratch gateways disappear. Existing fixed-destination API is insufficient because the action must retain the legacy source-home/result choice internally. |
| R07 | All other immediate-right forms. | None. | None. | Exact legacy `binary-width`, shift-width/amount, or `binary-imm-rhs` error before any action. | No gateway delta. |

The function contains **7** counted occurrences: five
`emitValueIntoScratch`, one `emitValueIntoEax`, and one `resolveValue`. All
seven belong to ordinary named scalar uses and disappear when the complete
family migrates. The parent helper
`tryLowerLshr64SpillThroughRax/resolveValue` is a separate category-6
occurrence and disappears only with R01; it is accounted separately in the
terminal ratchet.

### `lowerBinaryImmediateLhs`

| ID | IR form and accepted homes | Result / staging / first destructive write | Accumulator and EFLAGS lifecycle | Diagnostics and provenance | Cohort use, gateway disposition, action fit |
|---|---|---|---|---|---|
| L00 | `sub i128 0, P128`. | Existing pair_b result: rhs→pair_a, zero pair_b, pair subtract. First write is rhs pair materialization. | Standing pair result. Low SUB `.definition(.carry)`, high SBB `.use_and_clobber`. | Exact form before rhs materialization; rhs error is legacy pair error. | Accepted negation/multiply-overflow i128 helpers. The sole `materializePairValue` gateway remains under future pair-result ownership. No O2 action. |
| L01 | `sub I, N64` or `sub I, N32` (admitted widths). | rhs→RCX; literal→RAX/EAX through subordinate materialization; subtract. Narrow result gets low-width mask. | `.preserve/.spill_live`; SUB `W`, optional AND `W`; typed definition. | rhs failure precedes preparation/literal materialization. | Immediate-left sub rows include i4/i5/i6/i7/i16 families in the frozen TSV and focused i64 coverage. Two scratch sites disappear. Needs closed semantic-literal action. |
| L02 | `shl I, N32` at i16/i32. | shift count rhs→RCX; literal→EAX; SHL; i16 mask. | `.preserve/.spill_live`; SHL `W`, optional AND `W`. | Width/form then rhs, preparation, literal. | Accepted i16/i32 immediate-left shifts include floor/limb focused cases. One scratch site disappears. |
| L03 | `lshr I, N32/N64` at ≤32 or i64. | rhs count→RCX; literal→EAX/RAX; SHR. | `.preserve/.spill_live`; SHR `W`; typed definition. | Op/width then rhs, preparation, literal. | Accepted parity/count0bits/rem rows and focused i64 case. Two scratch sites disappear. |
| L04 | Other op/width forms. | None. | None. | `composed-block-binary-imm-lhs` or variable-shift-width before action. | No gateway delta. |

The function contains **6** counted occurrences. Five scalar RHS staging sites
disappear; the one pair materializer in L00 remains. Scalar literals remain
semantic action metadata and never become fake requests.

## Branch inventory: casts

| ID | IR form and accepted homes | Result / staging / first destructive write | Accumulator and EFLAGS lifecycle | Diagnostics and provenance | Cohort use, gateway disposition, action fit |
|---|---|---|---|---|---|
| C00 | Missing result, non-int endpoints, source >128, or unsupported >64 result. | None. | None. | Result/type/width checks precede source access. | No delta; pure semantic dispatch. |
| C01 | `trunc`/integer `bitcast` from i128 to ≤64; source `P128`. | Scratch64 alias/copy of low lane; planned scratch, existing pair low register, or fresh scratch. First destructive write is low-limb staging when not already usable. | No accumulator result, no EFLAGS record. Pair is read-only input; result is scalar scratch, not pair ownership. | Width before pair resolution/materialization; unknown cast maps to source request. | Accepted textual anchors: i128→i64 in `__multi3` and the three i128 shift helpers; i128→i16 in `parityti2`. The `resolvePairValue` gateway disappears. Existing read-only pair request fits, but a closed cast action is required. |
| C02 | `trunc`/integer `bitcast` with source ≤64; source scalar `N32/N64`, including 64→≤32 low view. | **Alias-only** durable binding; no instruction. `arg64/scratch64/rax` become low `scratch32/eax`, spill stays spill. | No accumulator session or EFLAGS. | Resolve source, derive low view, bind, then reject non-scalar homes. | Accepted textual cast population is large (for example 74 occurrences of i64→i32 in 17 accepted rows). This exact `resolveValue` gateway remains with `bindValueLoc` under O4 alias/copy ownership. It must not be claimed by O2. |
| C03 | `zext i64 to i128`; source `N64`. | Existing pair result: source→chosen pair low limb, zero high limb, bind pair. | No scalar session; no EFLAGS. | Pair chooser/spill envelope precedes source staging. | 8 occurrences in 4 accepted rows: `__multi3` and the three i128 shift helpers. The one `emitValueIntoScratch` gateway remains under pair-result redesign. |
| C04 | Exact-EI `zext` from >32 to ≤64; source `N64`. | RAX logical result; prepare/materialize, RCX mask, AND. | `.clobber`, location-derived reuse/`spill_live`; AND `W`; full/zero-extended RAX definition. | Exact-EI/width check, source resolve, preparation, materialization. | i55/i56 and related exact rows in `floatuneidf`/`floateidf`. One scalar `resolveValue` gateway disappears. Requires exact-width cast action. |
| C05 | `zext` from ≤32 to ≤32/i64 or admitted exact-EI result; source `N32` or typed immediate supported by the subordinate materializer. | EAX result, optionally AND low source width; EAX proves physical zero extension to wider logical result. | `.clobber` for source <32, otherwise `.preserve`; AND is `W`; typed definition. | Width, canonical cast-source classification, preparation, materialization. | Accepted rows include i1→i32/i64, i16→i32/i64, i32→i64, and narrow exact-ei float rows. The `accumulatorCastSource` helper owns the named resolve rather than a function-local counted gateway; it disappears only after C05 and I52C1 have migrated. Needs a closed zext action with semantic immediate support. |
| C06 | `sext i32 to i64`; source only `G32/S32`, never accumulator/spill/wider class. | Scratch64 result in r8/r9/rcx selected from the input register; `movsxd` is the first and only write. | No accumulator session; no EFLAGS. | Exact width before source; unresolved source precedes rejected-home diagnostic. | 4 occurrences in `mulo.__mulosi4` and `mulvsi3.__mulvsi3`. One `resolveValue` gateway disappears. Action-specific validation must preserve this narrower home boundary rather than inherit generic low-view widening. |
| C07 | Other cast op/form. | None. | None. | Existing cast-op/width errors. | No delta. |

Of the five counted `lowerCast` gateways, **three disappear** (C01, C04,
C06). Two remain: the C02 alias-only `resolveValue` and the C03 pair-result
`emitValueIntoScratch`. This is the first place where subtracting the whole
classified population would be wrong.

### `lowerI52Cast`

| ID | Form / homes | Result, order, displacement, EFLAGS | Diagnostics / cohort / disposition |
|---|---|---|---|
| C52-0 | `trunc i64 N64 to i52`. | RAX i52: prepare `.clobber/.spill_live`, materialize full RAX, RCX mask, AND `W`, define `.zeroExtendedRax(52)`. | Named/form validation first; unknown cast after preparation. Three occurrences in `compiler_rt.fma.fma`. No local counted resolve; action required. |
| C52-1 | `zext i6 N32 to i52`. | EAX/RAX logical i52: canonical cast source, `.clobber` with source-derived displacement, materialize low 6, AND 63 `W`, define zero-extended i52. | Three occurrences in `fma.fma`. The shared `accumulatorCastSource/resolveValue` helper collapses after the cast subgroup completes. |
| C52-2 | `zext i52 N64 to i64`. | Prepare `.preserve` with location displacement, materialize zero-extended i52 in RAX, define full RAX; no arithmetic instruction and no new EFLAGS record. | Three occurrences in `fma.fma`. One local `resolveValue` disappears. |
| C52-3 | `trunc i52 N64 to i6/i32`. | Prepare `.clobber` for i6 or `.preserve` for i32, materialize low32; i6 AND 63 `W`; define EAX result. | fma/control-envelope rows. One local `resolveValue` disappears. |
| C52-4 | Any other form or non-named source. | No mutation. | `i52-cast-value/form`; no provenance. |

Both counted `lowerI52Cast/resolveValue` occurrences disappear. C52-0/C52-1
share no local gateway count but must still be semantically owned by the
complete cast action.

## Branch inventory: exact i52 binary

| ID | Form / homes | Result, order, displacement, EFLAGS | Diagnostics / cohort / disposition |
|---|---|---|---|
| I52B0 | Only the structurally proven `shl i52 N64, N64` whose named rhs is the exact ctlz→trunc i6→nuw add 1→zext i52 envelope. Both bindings are gpr64/52 logical bits in 64 physical bits. | RAX i52. Prepare lhs first with preserve-current reuse/`spill_live`; then rhs→RCX64; lhs→RAX; SHL `W`; RCX mask + AND `W`; typed definition/finalization. Same source can require RAX and RCX. | Missing function/provenance and structural form reject before mutation. Preparation precedes rhs failure, then lhs failure. Exact cohort row is `compiler_rt.fma.fma` (three textual i52 shift occurrences are shadowable within that row). The one RHS staging gateway disappears. Existing composition primitives fit; a closed i52 action must derive the ctlz envelope internally, never from a function predicate. |

## Branch inventory: multiply

### `lowerMul64`

| ID | Operand homes and result | Accepted order / first destructive write | EFLAGS, diagnostics, cohort, action fit |
|---|---|---|---|
| M64-0 | lhs `S64` reusable/planned, rhs `G64/S64/A64`; scratch64 result. | Resolve lhs first; select reusable/planned/free destination; stage lhs; resolve rhs. Emit register or RAX multiply. Lhs staging is first write. | `imul` is `W`. Lhs unresolved/home/destination errors precede rhs. The exact 19 accepted rows are `divdf3`, the eight divmode/udivmode rows, `divsf3`, `int.__udivmoddi4`, `limb64.__mulo_limb64`, `memmoveFast`, `__muldi3`, `__multi3`, `mulo.__mulosi4`, `mulsf3`, `mulvsi3`, and `sqrtf`; several contain multiple multiplies. Two lhs gateways and the rhs resolve disappear. |
| M64-1 | lhs `G64/A64` copied to planned/free scratch, rhs as above; scratch64 result. | Same order as M64-0. | Same action requirement; no accumulator result session. |
| M64-2 | rhs `spill64`, another scratch free. | After lhs staging and rhs resolution, rhs→second scratch, then `imul dst,src`. | The second `emitValueIntoScratch` is this branch and disappears. |
| M64-3 | rhs `spill64`, no second scratch. | Spill current accumulator, reload rhs→RAX, `imul dst,rax`. | Spill/reload order is part of the closed action and rollback. No new fixed-register authority is admitted. |
| M64-4 | lhs `spill64`, no result scratch. | Delegate to spill-through-RAX M64R. | Leaf delta charged to M64R. |
| M64-5 | Invalid width/home or no spill envelope. | No result. | Exact lhs-before-rhs diagnostics retained. |

All four counted `lowerMul64` gateways (two resolves and two scratch
materializations) disappear under a complete multiply action. Same-source
lhs/rhs and overlap with the chosen destination are planned before mutation;
a genuine cycle remains fail-closed.

### `lowerMul64SpillLhsThroughRax`

| ID | Form / homes | Result, order, displacement, EFLAGS | Diagnostics / cohort / disposition |
|---|---|---|---|
| M64R | lhs `spill64`; rhs `G64/S64` or `spill64`; no scratch destination. | Begin accumulator session; prepare `.preserve/.spill_live`; reload lhs→RAX; **re-resolve rhs after preparation**; `imul rax,reg` or `imul rax,[rsp+spill]`; define full RAX. | `imul` is `W`. Lhs materialization failure precedes unresolved rhs and rejected rhs home. The one local rhs `resolveValue` disappears. Focused spill-pressure and `__multi3` canary cover the stream; cohort attribution shares the M64 rows. Requires the multiply action’s RAX fallback, not a public phase/order hint. |

Multiply is deliberately scheduled after ordinary binary/cast actions because
its destination planning, spill-through-RAX fallback, and same-source
cross-product exercise the largest copy/overlap surface short of division.

## Branch inventory: `lowerUnsignedDivRem`

| ID | IR form and homes | Result / staging / first destructive write | Accumulator and EFLAGS lifecycle | Diagnostics and provenance | Cohort use, gateway disposition, action fit |
|---|---|---|---|---|---|
| UD0 | `udiv i32/i64` named/named. lhs `N32/N64`; rhs may be matching `A32/A64`, other GPR, or spill staged through RCX. | Quotient in EAX/RAX. Resolve rhs first. If rhs is accumulator, stage rhs→RCX before preparing/materializing lhs; otherwise prepare/materialize lhs first and stage rhs afterward. Then clobber RDX, XOR EDX, divide by RCX. Same-source requests need accumulator and RCX; cycles beyond current plan remain rejected. | `.preserve`, direct reuse-or-`spill_live`; XOR is `W`; DIV is `C`; quotient typed definition after DIV. No flag consumer may cross DIV. | Unresolved rhs is first. Then rhs-accumulator staging or lhs preparation/materialization, then non-accumulator rhs staging, RDX clobber, append. Future errors map only through the matching handle. | i32: 10 textual occurrences in 4 accepted rows (`__divmodsi4`, `__modsi3`, `__divsi3`, `__udivmoddi4`); i64: 9 accepted rows (the eight divmode/udivmode rows plus `udivmod.udivmod__anon_15304`). All three local gateways disappear. Requires a closed quotient action that wraps the **existing** fixed EAX/RAX/RDX sequence; no new fixed-register authority. |
| UR0 | `urem i32/i64` dispatch. | Existing result in RDX through `lowerUnsignedRem`; quotient is discarded. | Existing direct accumulator/scratch setup; XOR `W`, DIV `C`, bind RDX scratch. | Same legacy rhs-first classification. | i32: 7 textual occurrences in the accepted row `int.__udivmoddi4`; i64: 9 accepted rows (the eight divmode/udivmode rows plus `udivmod.udivmod__anon_15304`). This is a standing RDX-result exclusion. The five `lowerUnsignedRem` bypasses remain. The dispatch changes semantic ownership only and contributes zero textual delta inside `lowerUnsignedDivRem`. |

The three counted sites in `lowerUnsignedDivRem` are all after the early urem
dispatch and therefore belong only to UD0. They disappear in the quotient
slice. `lowerUnsignedRem` remains a separately guarded five-occurrence
exclusion. Fixed-register division is last because it combines same-source
multi-destination, RDX clobber, a flag-clobbering instruction, and exact
operand-order constraints.

## Accepted cohort coverage and shadowing

The frozen accepted scalar IR appendix is the exact function-set authority for
named/immediate binary forms. Its 80 data rows cover widths 1, 3, 4, 5, 6, 7,
8, 13, 14, 16, 26, 27, 32, 52, 55, 56, 64, and 128 as applicable. Rather than
copy hundreds of repeated names into this document, every matrix row above
names the exact TSV keys (width/op/lhs-kind/rhs-kind), gives the frozen row
count, or lists the small exact function set.

The following multi-occurrence facts are material to future fail-fast
validation:

- `compiler_rt.fma.fma` contains three i64→i52 truncs, three i6→i52 zexts,
  three i52→i64 zexts, and three structurally related i52 shifts. A first
  failure shadows later cast/shift occurrences in the same row.
- The eight divmode/udivmode rows each contain paired udiv/urem operations and
  many repeated casts. Migrating quotient use does not authorize the later RDX
  result, and a first quotient failure can shadow the remainder.
- `int.__udivmoddi4` contains ten accepted i32 udiv occurrences across the
  integer division rows and seven i32 urem occurrences in this row alone,
  interleaved with multiply and cast forms. It is a cross-subgroup shadowing
  anchor.
- `__multi3` and the i128 shift helpers contain both scalar i64 multiply/casts
  and pair-result zext/shift forms. A scalar success must not absorb the later
  pair exclusion.
- The large i32/i64 general binary sets reuse rows heavily. The exact list is
  the committed TSV; slice evidence must report both first failing request and
  later shadowed occurrences rather than treating row count as instruction
  count.

## Honest textual ratchet

The 42 category-3 occurrences in the scoped functions reconcile as follows:

| Function | Current | Ordinary textual removals | Required residual | Residual owner |
|---|---:|---:|---:|---|
| `lowerBinary` | 13 | 13 | 0 | pair dispatch is semantic-only; its 12 leaf sites are outside this 42 |
| `lowerBinaryImmediateRhs` | 7 | 7 | 0 | i128 helper branches have no counted site in this row |
| `lowerBinaryImmediateLhs` | 6 | 5 | 1 | i128 pair result / O4 pair-result |
| `lowerCast` | 5 | 3 | 2 | one alias-only binding / O4; one zext-to-i128 pair result / O4 |
| `lowerI52Binary` | 1 | 1 | 0 | — |
| `lowerI52Cast` | 2 | 2 | 0 | — |
| `lowerMul64` | 4 | 4 | 0 | — |
| `lowerMul64SpillLhsThroughRax` | 1 | 1 | 0 | — |
| `lowerUnsignedDivRem` | 3 | 3 | 0 | urem is semantic-only here; its five leaf sites remain elsewhere |
| **Total** | **42** | **39** | **3** | zero unclassified |

Four category-6 parent-helper occurrences also have an honest last-owner
collapse:

| Parent/helper occurrence | Removal point |
|---|---|
| `accumulatorCastSource/resolveValue` | after ordinary and i52 casts both migrate |
| `accumulatorArithmeticDisplacement/resolveValue` | after named and immediate scalar arithmetic both migrate |
| `accumulatorDirectMaterializationDisplacement/resolveValue` | after boolean/shift and quotient users both migrate |
| `tryLowerLshr64SpillThroughRax/resolveValue` | with the complete immediate-RHS lshr action |

`accumulatorPreserveCurrentDisplacement/resolveValue` does **not** disappear:
`composed_selector_calls.zig` still imports it for an O1-composed call form.
It remains one guarded occurrence until that separately reviewed owner moves.

The proposed complete scalar-group terminal is therefore:

```text
172
- 39 scoped ordinary gateway removals
-  4 last-owner helper collapses
= 129
```

This is a proposal, not a ratchet applied by INBOX-130. The current tracked
ratchet remains exactly **172**. Each production slice may claim only the
removals whose complete semantic owner lands in that slice; semantic-only
ownership changes never reduce the textual count.

Semantic-only transitions, recorded separately from the arithmetic, are:

1. `lowerBinary` continues to dispatch i128 pair results to
   `lowerPairBinary`; its 12 pair gateways remain.
2. Immediate-right i128 shifts/sign-mask remain pair results even though their
   scalar siblings migrate.
3. `lowerUnsignedDivRem` continues to dispatch urem to `lowerUnsignedRem`;
   its five RDX-result gateways remain.
4. The scalar read of an existing i128 pair in C01 may migrate as a read-only
   use; this grants no pair allocation/result ownership.
5. C02 alias creation and C03/L00 pair-result creation remain with O4 even
   when their sibling branches acquire O2 ownership.

## Proposed structural slices

Every action slice is dormant first, followed by a separately reviewed
production slice. No action may accept a consumer name, discovered home,
physical register, displacement policy, or sequencing hint.

| Order | Structural subgroup | Direct delta when wired | Helper delta when last owner moves | Proposed cumulative ratchet |
|---:|---|---:|---:|---:|
| 1 | Casts: C01/C04–C06 plus C52-0–C52-3; retain C02/C03 | 5 | `accumulatorCastSource` 1 | 166 |
| 2 | Immediate operands: R00–R06 and L01–L03; retain L00 | 12 | lshr spill-through helper 1 | 153 |
| 3 | Named scalar binary/shift plus exact i52: B01/B03–B07 and I52B0 | 14 | `accumulatorArithmeticDisplacement` 1 | 138 |
| 4 | Multiply: M64-0–M64-4 and M64R | 5 | 0 | 133 |
| 5 | Fixed-register quotient: UD0; retain UR0 | 3 | `accumulatorDirectMaterializationDisplacement` 1 | 129 |

The order deliberately leaves multiply and fixed-register division last.
Casts first exercise unary compatibility and alias/pair fencing. Immediate
forms then establish semantic literal intent without fake bindings. General
named binary forms prove same-source/multi-destination, canonical
re-resolution, source-derived internal homes, and the live-accumulator
preamble. Multiply adds destination planning and spill-through-RAX. Division
finally wraps the existing fixed-register sequence without widening RDX
ownership.

## Required dormant action boundaries

The current action set has no scalar arithmetic/cast/multiply/divide action.
The already accepted infrastructure supplies one outer `ValueUseTransaction`,
one snapshot, same-source nonconflicting multi-destination planning,
prefix-closed early materialization, narrow low-bit compatibility, closed
internal execution, failure provenance, and a snapshot-free subordinate
accumulator session. The dormant designs still need closed semantic actions
for:

1. scalar casts with action-specific home boundaries and explicit
   alias/pair-result exclusions;
2. semantic-immediate unary/binary forms, with the literal stored in the
   action and no request/binding;
3. named scalar binary/shift forms, including current-home commutation and the
   exact i52 classifier;
4. multiply with scratch-result and spill-through-RAX modes derived
   internally;
5. quotient-only udiv wrapping the existing EAX/RAX/RDX sequence.

No design may add pair result ownership, full-product RAX/RDX ownership, RDX
remainder ownership, a new fixed-register authority, or copy-cycle
resolution. If a complete branch requires any of those, it remains on its
accepted path and returns for architectural review.

## Delivery assertion

INBOX-130 changes documentation only. It does not change production, tests,
source guards, tools, build roots, the frozen bypass TSV, or the current
ratchet of 172. No performance gate and no Tier 3 were run. The next step is
architectural review of this inventory before any dormant scalar action is
designed.
