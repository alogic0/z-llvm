# INBOX-81 O2-0 frontier and value-use inventory

This is the read-only enumerate-first checkpoint for O2. It changes no
emitter, source guard, test gate, or mandatory runner. O2 is a frontier advance,
not a whole-report byte-identity exercise: only the twelve rows frozen below
may move in O2, while the 431-row non-target projection and the original
285-row object/owner projection remain immutable.

## Frozen identities and empirical method

The requested accepted O1 base is commit
`6437c89fae20a1b875f5fc33cc55ecc5f82ad415`, tree
`05857c3cc2f3b193725b1431f312009410a586b0`. Enumeration ran at the current
accepted documentation head `d834147b2241d46cadd440181b5dcc486a8a02c4`,
tree `142eea9f1ea18fea87ec513765c2173357a4262b`. The only paths changed between
those commits are `docs/evidence/inbox80_o1_closeout_7b.md` and
`docs/next_steps.md`; `git diff 6437c89f..d834147b -- src tools build.zig`
is empty. Thus the production tree inspected here is exactly the accepted O1
production state requested by INBOX-81.

The frozen compiler-rt source/capture identities are:

- Zig source pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`.
- Captured selector input:
  `tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll`.
- Capture SHA-256:
  `7be46e0b88c96fce0ce527407672843c43d3416ce56257d53a286603bd533e06`;
  pinned MD5: `b0eda7a6427c3084fdf096a68696f19c`.
- Original accepted-only 285-row input `tmp/inbox63_accepted_cohort.ll`,
  SHA-256
  `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4`.

The selector consumes the captured textual LLVM IR and constructs its internal
`ir.Function`; this gate has no separately serialized AIR artifact. Therefore
the capture hash plus each exact linkage name/signature below is the frozen
source/AIR-facing row identity. Debug metadata ties the rows to the compiler-rt
sources `floatuntidf.zig`, `floatuntisf.zig`, `floatuntihf.zig`,
`floattidf.zig`, `floattisf.zig`, `floattihf.zig`, `udivmod.zig`, and
`int.zig`.

The empirical diagnostic run used the existing report plumbing, without
instrumenting production code:

```text
zig-out/bin/z_llvm --emit=obj --target=x86_64-linux \
  --generic-cfg-selector --report-all-codegen-failures \
  --input-limit=67108864 <frozen-capture>
```

Its raw report is `tmp/inbox81_full_report.log`, SHA-256
`49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`:
443 selected / 285 emitted / 158 failed, first failure
`compiler_rt.trunc.truncl` / `UnsupportedLongDoubleAbi` /
`unsupported_type` / `unsupported-return-type`. The twelve records below are
the exact observed `lowerFunctionWithOptions` tag/detail records, not inferred
families.

## Six i128 compare-location rows

Every row begins with `%1 = icmp eq i128 %0, 0`. `bindParams` initially assigns
the sole i128 parameter `%0` to `ValueLoc.arg128 { lo = rdi, hi = rsi }`.
Because each function is multi-block and contains a wide compare,
`prepareStackFrame` reserves the spill envelope and
`stabilizeFramedParams` runs before the first instruction; the **actual
location observed by this compare is `ValueLoc.spill128`** (the two stabilized
limb slots), not the entry pair. The RHS is the IR integer immediate zero and
deliberately has no `ValueLoc`. Both operands
are listed here so the fail-fast LHS does not hide a supposed RHS location
problem: the empirical family is compare-location, not conversion, and the RHS
is already immediate.

| Exact function identity and signature | Current diagnostic / selector tag / detail | Actual operands and `ValueLoc`s | Honest next blocker after the intended O2 materialization |
|---|---|---|---|
| `compiler_rt.floatuntidf.__floatuntidf(i128 %0) -> double` | `UnsupportedCodegenControlFlow` / `no_emitter` / `composed-block-icmp-lhs-loc` | lhs `%0`: `.spill128` (stabilized from `{rdi,rsi}`); rhs `0`: immediate, no location | `llvm.ctlz.i128` -> `no_emitter/composed-block-llvm-intrinsic`; not closed by O2 |
| `compiler_rt.floatuntisf.__floatuntisf(i128 %0) -> float` | same | lhs `%0`: `.spill128` (stabilized from `{rdi,rsi}`); rhs `0`: immediate, no location | `llvm.ctlz.i128` -> `no_emitter/composed-block-llvm-intrinsic`; not closed by O2 |
| `compiler_rt.floatuntihf.__floatuntihf(i128 %0) -> half` | same | lhs `%0`: `.spill128` (stabilized from `{rdi,rsi}`); rhs `0`: immediate, no location | `llvm.ctlz.i128` -> `no_emitter/composed-block-llvm-intrinsic`; not closed by O2 |
| `compiler_rt.floattidf.__floattidf(i128 %0) -> double` | `UnsupportedCodegenControlFlow` / `no_emitter` / `composed-block-icmp-lhs-loc` | lhs `%0`: `.spill128` (stabilized from `{rdi,rsi}`); rhs `0`: immediate, no location | after supported `llvm.abs.i128`, `%3 = icmp slt i128 %0, 0` -> `no_emitter/composed-block-icmp-form`; not closed by O2 |
| `compiler_rt.floattisf.__floattisf(i128 %0) -> float` | same | lhs `%0`: `.spill128` (stabilized from `{rdi,rsi}`); rhs `0`: immediate, no location | signed i128 compare form as above; not closed by O2 |
| `compiler_rt.floattihf.__floattihf(i128 %0) -> half` | same | lhs `%0`: `.spill128` (stabilized from `{rdi,rsi}`); rhs `0`: immediate, no location | signed i128 compare form as above; not closed by O2 |

These predicted blockers follow the current instruction order and existing
dispatch fallthrough. They are genuinely different operations. A move merely
to `icmp-rhs-loc` would instead be an incomplete migration and is not an
authorized new frontier.

## Six pointer-call rows

Each failing call has exactly one pointer argument. The complete call-argument
walk found no later/shadowed pointer argument in any row. For i128/i128 calls,
the pointer target slot is `r8`; for i64/i64 calls it is `rdx`. A `.null_value`
is an immediate pointer constant and currently has no `ValueLoc`, which is why
five rows report `call-unknown-ptr-arg`. The non-null `%2` in
`__udivmodti4` is the fifth incoming GPR slot and is `.arg64 = r8`.

| Exact function identity | Callee and every pointer call argument | Current diagnostic / selector tag / detail | Other pointer values in the row | Honest next blocker / closure |
|---|---|---|---|---|
| `compiler_rt.udivmod.__udivmodti4(i128 %0, i128 %1, ptr %2) -> i128` | `udivmod__anon_15304(..., ptr %2)`; only pointer arg `%2`, `.arg64=r8`, staged to `r8` | `UnsupportedCodegenType` / `no_emitter` / `composed-block-call-ptr-arg` | same `%2` | call result `%3` is an excluded unbound i128/pair result; `ret i128 %3` -> `unsupported_value/composed-block-unknown-ret`; not closed |
| `compiler_rt.udivmod.__divti3(i128 %0, i128 %1) -> i128` | `udivmod__anon_15304(..., ptr null)`; only pointer arg `.null_value`, no location, target `r8` | `UnsupportedCodegenType` / `unsupported_value` / `composed-block-call-unknown-ptr-arg` | none | unbound i128 call result `%8` reaches `%10 = xor i128 %8, %9` -> `unsupported_value/composed-block-unknown-lhs`; not closed |
| `compiler_rt.udivmod.__udivti3(i128 %0, i128 %1) -> i128` | `udivmod__anon_15304(..., ptr null)`; only pointer arg `.null_value`, no location, target `r8` | same `UnsupportedCodegenType` / `unsupported_value` / `composed-block-call-unknown-ptr-arg` | none | unbound i128 call result `%2`; `ret i128 %2` -> `unsupported_value/composed-block-unknown-ret`; not closed |
| `compiler_rt.int.__divmodti4(i128 %0, i128 %1, ptr %2) -> i128` | `udivmod__anon_15304(..., ptr null)`; only pointer call arg `.null_value`, no location, target `r8` | same | function parameter `%2` enters in `r8` and is preserved for a later store; it is not passed to this call | unbound i128 result `%9` reaches `%11 = xor i128 %9, %10` -> `unsupported_value/composed-block-unknown-lhs`; not closed |
| `compiler_rt.int.__divdi3(i64 %0, i64 %1) -> i64` | `compiler_rt.int.__udivmoddi4(..., ptr null)`; only pointer arg `.null_value`, no location, target `rdx` | same | none | the i64 result already has accumulator-result authority and remaining xor/sub/ret forms are supported: predicted fully closed by O2 |
| `compiler_rt.int.__divmoddi4(i64 %0, i64 %1, ptr %2) -> i64` | `compiler_rt.int.__udivmoddi4(..., ptr null)`; only pointer call arg `.null_value`, no location, target `rdx` | same | function parameter `%2` enters in `rdx` and is preserved for the later store; it is not passed to this call | i64 result plus xor/sub/mul/store/ret are supported: predicted fully closed by O2 |

The next-blocker statements are static predictions because O2-0 is forbidden
to change emission. If a later slice observes a different first blocker, that
is the contract's unforeseen-target blocker and requires review rather than
automatic widening. Likewise, exposing the same unsupported pointer form on a
second argument would be incomplete, not an honest advance; the exhaustive
argument census above proves there is no such hidden second pointer today.

## Baseline projections for later O2 slices

The twelve names above form the exact target manifest. All later comparisons
must be keyed by full function identity, not report position.

### 431-row non-target report projection

The projection is 443 selected rows minus these 12 targets: the original 285
accepted rows plus 146 unchanged failing rows. The check is:

1. Run the full cumulative 443-row report and retain per-function
   tag/detail/diagnostic records before normalizing its changing summary.
2. Remove exactly the twelve target identities from both baseline and
   cumulative records. Compare the remaining 146 failure records byte for
   byte and verify their order and first failure remain unchanged.
3. Compare the selected identity set and status map for all 431 non-targets.
   The 285 successful identities are cross-checked by the accepted-object and
   owner projection below, preventing a success-to-failure movement from being
   hidden by the failure-only report format.
4. If `c` target rows close, require the unfiltered summary to be exactly
   `443/(285+c)/(158-c)`. Only target records may acquire new report identities.

The baseline report identity remains
`49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`.
It is a source for the projection, not the expected cumulative hash once a
target moves.

### Original 285-row object/owner projection

The immutable accepted-only projection is rebuilt from
`tmp/inbox63_accepted_cohort.ll` on every emitting O2 slice. It must retain:

- aggregate object SHA-256
  `061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be`;
- owner manifest SHA-256
  `5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d`;
- owners `composed_block=40`, `composed_cfg=127`, `legacy_envelope=17`,
  `structural_fallback=101`, hence ledger `167/17/101`, with zero unassigned.

In addition, filter the cumulative owner manifest back to the original 285
function identities and compare that canonical projection to the baseline.
Newly accepted target objects/owners receive separately recorded cumulative
identities; they never replace or renormalize the accepted-only baseline. Any
byte, owner, route, or counter change in an original accepted row is a hard
stop.

## Collateral-watch rows

The adjacent read-only-table frontier is not part of the twelve-row target
manifest. Both rows must remain byte-identical in the 431-row projection:

| Watch function | Current record | Why watched |
|---|---|---|
| `compiler_rt.exp.exp` | `UnsupportedCodegenControlFlow` / `no_emitter` / `composed-block-gep-readonly-table-global` | immediately adjacent to `readonly_table_ptr` materialization/admission |
| `compiler_rt.exp.expf` | same | symmetric float table row |

These are the complete current report rows at `gep-readonly-table-global`.
They watch the boundary near `stack_i32_ptr` / `readonly_table_ptr`; movement
is collateral and therefore a hard stop, not an O2 target success.

## Production resolution/materialization bypass inventory

The committed machine-readable inventory is
`docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv`. It contains
every current consumer function body that directly uses any of these
pre-transaction gateways:

```text
resolveValue, resolvePairValue, valueLoc,
materializeLocIntoLoc, materializeLocIntoLocWithBits, materializePairValue,
emitValueIntoAccumulator, emitValueIntoEax, emitValueIntoRax,
emitValueIntoScratch, emitValueIntoScratchAndRelocate,
emitValueIntoFpReturn, emitValueIntoI128Return,
emitBinaryLocIntoAccumulator
```

It also includes the local `ValueLoc`-bearing bypass chain:
`materializeF64Loc`, `materializeScalarPhiSnapshot`, `emitValueIntoLoc`,
`lowerHalfLocToFloatXmm0`, and `lowerStoreI64`, including the sole direct local
instruction materializer body `materializeF64Loc`. A Zig-tokenizer,
brace-aware function-body scan (the same boundary discipline used by the O1
source guard) found bypasses in **10 production consumer files, 91 enclosing
functions, 150 function/gateway entries, and 254 exact textual occurrences**.
The two other classified consumers, `composed_selector_eflags.zig` and
`composed_selector_frame.zig`, are recorded explicitly as zero-site files. The TSV
records file, enclosing function, gateway/materializer name, and occurrence
count; zero sites are unclassified.

Pure location predicates/metadata routines are not materialization bypasses.
`composed_selector_state.zig` is the existing state authority and
`composed_selector_state_data.zig` is lifecycle storage, so their internal
implementations are the allowlisted destination, not consumer bypasses.
Likewise, the O1 `AccumulatorDefinitionTransaction.materialize(ir.Value)`
path resolves after preparation and is already transactional; it is not a
direct `ValueLoc` bypass. O2-3 must close or explicitly guard every TSV entry
without silently converting these exclusions into consumer allowances.

## O2-0 scope and validation

This checkpoint only adds these two evidence files. It performs no producer
migration, emission change, source-guard change, canary promotion, or gate
change. No cohort, ABI, canary, Tier 2, or Tier 3 run is warranted for this
documentation-only slice. The frozen identities remain
`49a19f04 / 443-285-158-truncl / 061a64e4 / 5d91960e / 167-17-101`.
