# INBOX-125 O2-3I-A3a — symmetric spill128 pair-action admission

## Frozen scope

```text
accepted_action_commit=72981e88a8de03438a04c0c05c8a0896deac4c5a
accepted_action_tree=d28be13786410cf1c20408d68083e6ebc4782c63
working_head_with_supervisor_docs=67d9cf88d1c9cf2d3588547b9268a73824b85973
working_head_tree=faa9b7875153f7dea4e6c787a4bb71bc45ca39e8
production_icmp_change=none
ratchet_before=174
ratchet_after=174
performance_run=not-run
authorized_or_acceptance_grade_tier3=not-run
stash_at_0=untouched
```

The preserved I-B3 production-wiring patch was not applied. It still applies
cleanly and its SHA-256 remains:

```text
patch=tmp/inbox124_icmp_pair_perf/inbox124_i_b3_hard_stop.patch
sha256=6c2b4fb2bdcd3c9af277b8e1f420da2ba1c253f967a26e44135b0bace36f542c
```

## Symmetric structural admission

The two closed actions now admit the canonical `.spill128` home for only their
existing exact semantic forms:

```text
I128EqMinAction   eq  i128 <named>, minInt(i128)
I128SignBitAction slt i128 <named>, 0
```

The shared canonical validator admits:

```text
arg128 | scratch128 | stack128_value | spill128
```

No action field, function name, family name, selector-state predicate, source
register, spill slot, pair choice, or sequencing hint was added. The pure
`isI128EqMinIcmp` and `isI128SignBitIcmp` classifiers are unchanged.

`I128EqMinAction` still calls the existing `resolvePairValue` legacy
nonoverlap chooser and `materializePairValue` helper exactly once.
`I128SignBitAction` still calls the existing `emitPairHighLaneIntoRax` helper
exactly once. There is no new pair allocation, ownership, durable rebinding,
or cycle scheduling.

Seal-time planning treats a spill-backed eq-min source like the existing
stack-backed source: it has no pre-existing register pair and therefore uses
the same legacy `pair_a` destination. The sign-bit helper declares only its
existing accumulator destination. The source guard now enforces both the
canonical spill admission and this planner case.

## Exact streams and rollback

Focused cases pin the accepted machine streams.

`compiler_rt.mulo.__muloti4` sign-bit comparison:

```text
reload_rsp_rax spill.hi
shr_rax_imm6 63                 EFLAGS .write
```

`compiler_rt.mulo.__muloti4` eq-min comparison:

```text
reload_arg64_rsp RCX, spill.lo
reload_arg64_rsp RDX, spill.hi
mov RDX -> RAX
mov minInt(i64) -> R8
xor R8, RAX                     EFLAGS .write
or RCX, RAX                     EFLAGS .write
mov RAX -> R8
cmp R8, 0                       EFLAGS .definition
sete EAX                        EFLAGS .use
```

The same eq-min spill stream is pinned for `compiler_rt.negv.__negvti2` and
the framed i128-negation test. The existing framed executable proof remains
green in the full unit suite.

All existing partial-stage rollback tables now use a `.spill128` source. Thus
every boundary following pair materialization/high-limb loading proves the
spill instructions are removed together with bindings, spills, counters,
accumulator state, EFLAGS and semantic records, dependencies, and durable
identities. A separate failing-allocator case gives the instruction list
capacity for exactly one reload, succeeds appending the low-limb reload, then
fails while growing for the high-limb reload. The outer transaction restores
the instruction length and complete selector state; inspection of retained
capacity confirms the rolled-back first instruction was the expected
low-limb reload. The legacy materializer itself is unchanged.

## Production dispatch and O2-6 boundary

The production test for `eq i128 <named>, 0` now asserts both pair classifiers
return false before calling the real `lowerIcmp`. The actual I13 dispatch
continues to return:

```text
selector_tag=no_emitter
selector_detail=composed-block-icmp-lhs-loc
instructions=0
```

Therefore eq-zero reaches neither pair action. All six frozen i128 target rows
remain byte-identical at that exact diagnostic:

```text
compiler_rt.floatuntidf.__floatuntidf
compiler_rt.floatuntisf.__floatuntisf
compiler_rt.floatuntihf.__floatuntihf
compiler_rt.floattidf.__floattidf
compiler_rt.floattisf.__floattisf
compiler_rt.floattihf.__floattihf
```

O2-6 is corrected to own **spill-backed i128 compare views**, not only the
eq-zero form. The current target rows do not move because eq-zero still
intercepts them. The old prediction that their next blocker is necessarily
slt-zero is conditionally superseded: once O2-6 admits eq-zero, the landed
sign-bit wrapper may carry a row past that later comparison. Before O2-6
production wiring, all twelve O2 targets must be re-enumerated with the pair
wrappers present and their new first blockers frozen. No multi-frontier
advance may be hidden behind a single fail-fast row.

## Guard and source identities

```text
source_guard_result=31/31
value_use_source_sha256=825abb19d5a24bfa2fc1ccc1c611a4ffc6c620c1d771ad3a026fa5bc866f52e1
value_use_tests_sha256=776a4edf2940cc640b5f2536b6cf4760a9eef9abc11fe21a282ea88786482dac
icmp_tests_sha256=46380ccb50803c0670e2b0cb6a71a2fa066352b6d125ec09da580592975ba27f
source_guard_tests_sha256=ae1059e4aea16f60cdc2b9d07d7336ae76d2fe7c00722a66b6eb73aa6c5e4f68
production_composed_selector_icmp_sha256=87d9e0c76c7fbe5e0e8437554c3b75c1681e6aed16d454426ded3986843c5f7c
accepted_production_composed_selector_icmp_sha256=87d9e0c76c7fbe5e0e8437554c3b75c1681e6aed16d454426ded3986843c5f7c
```

The guard retains the one-field semantic action intents, pure classifiers,
unchanged legacy helper calls, exact action/EFLAGS sequencing, durable result
ownership, dormant production status, and now requires exactly one
`.spill128` canonical-home admission plus the spill-backed eq-min planner
case.

## Validation

Every retained gate log is paired with its exact command.

Focused i128 transaction and selector tests:

```text
command=zig test src/tests.zig --test-filter i128 > tmp/inbox125_eqmin_spill/validation/focused_i128.log 2>&1
result=64/64 tests; pass
log_sha256=c53f8b4dede270310c27850d878aea35b45d5429958054e1ab1664db9ef99285
```

The log explicitly contains the combined spill-stream anchor, the failure
after the first eq-min spill reload, and complete eq-min/sign-bit partial-stage
rollback.

Production-dispatch focused suite:

```text
command=zig test src/tests.zig --test-filter generic_cfg > tmp/inbox125_eqmin_spill/validation/production_dispatch.log 2>&1
result=802/802 tests; pass
proof=I13 current-home eq-zero production path preserves dispatch precedence and diagnostics
log_sha256=06218d826fc0b845466c4bec07ba2f638fa36e56a8f7c6084494411e1aa5d506
```

Focused source guard:

```text
command=zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox125_eqmin_spill/validation/source_guard.log 2>&1
result=31/31 tests; pass
log_sha256=1e1c8a5fe0c8da773c6e66e732c3599542908e1624164ef24c024457679683fc
```

Full unit:

```text
command=zig build test --summary all > tmp/inbox125_eqmin_spill/validation/full_unit.log 2>&1
result=7/7 steps; 1273/1273 tests; pass
log_sha256=7839ab8767107632296d46f9a852ccf8e45a632afa51f972dac41da27ea23a6f
```

ABI differential:

```text
command=zig build abi-differential --summary all > tmp/inbox125_eqmin_spill/validation/abi_differential.log 2>&1
result=60/60 cases; 30/30 real functions; pass
log_sha256=64ca63da1e007b67958276179afa74cc7f86866c1dd34d11046b8b06c07d9ce8
```

Fresh frozen report (exit 1 is the accepted aggregate-failure status):

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox125_eqmin_spill/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
```

Accepted object:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox125_eqmin_spill/validation/accepted.o 2> tmp/inbox125_eqmin_spill/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

Owner manifest:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox125_eqmin_spill/validation/owner_manifest.tsv 2> tmp/inbox125_eqmin_spill/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
stderr_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

The frozen report, accepted object, and owner manifest are exact. No target
advanced. No performance, `distribution-all`, or Tier-3 command ran.
