# INBOX-123 O2-3I-A3 — dormant i128 pair-wrapper actions

## Frozen scope

```text
accepted_production_commit=715485756d44bb9648ee0729bd2625d4baecaca4
accepted_production_tree=10468d74619d7bdc2a5cb309853181dffc7ed1f5
working_head_with_supervisor_docs=fe4e8a2b3ec8f6c8de0e4a1d6994233d53e8b5c6
working_head_tree=81797d5714130ca0fb69bf4ae588321e7afd4c9c
tested_code_tree=6441a739ae581fe4957f9c6054722e8e7b46c62e
production_icmp_change=none
ratchet_before=174
ratchet_after=174
performance_run=not-run
authorized_or_acceptance_grade_tier3=not-run
stash_at_0=untouched
```

This dormant slice adds two separate closed semantic actions:

```text
I128EqMinAction { result: ActionIdentity }
I128SignBitAction { result: ActionIdentity }
```

They share an action-only read-only i128 request form. The request exposes no
pair, register, source home, predicate, constant, staging order, or
displacement policy. It admits only the existing `arg128`, `scratch128`, and
`stack128_value` homes. `.spill128` is rejected before mutation and remains
owned by O2-6. Neither action allocates, re-owns, durably rebinds, or schedules
a pair.

The future-dispatch classifiers are pure IR-semantic checks for exactly:

```text
eq  i128 <named>, minInt(i128)
slt i128 <named>, 0
```

Wrong predicates, constants, types, and source forms remain outside those
classifiers. The classifiers inspect no selector state or physical home.

## Closed action behavior

Both actions run the established live-accumulator preamble and re-resolve the
read-only i128 source from canonical state. They require one subordinate
accumulator session, durably own the i1 result identity with
`ownActionIdentity`, define `.zeroExtending(1)`, finalize the subordinate
session, and leave the sole commit to the outer transaction.

`I128EqMinAction` wraps the existing `resolvePairValue` and
`materializePairValue` helpers. It uses the legacy nonoverlap chooser:

```text
source overlaps pair_a -> pair_b
otherwise              -> pair_a
```

After materialization it preserves the accepted sequence exactly:

```text
prepare accumulator
clobber temp
pair.high -> RAX
minInt(i64) -> temp
XOR temp into RAX       EFLAGS .write
OR pair.low into RAX    EFLAGS .write
RAX -> temp
CMP temp, 0             EFLAGS .definition
SETE                     EFLAGS .use
```

`I128SignBitAction` wraps `emitPairHighLaneIntoRax`, prepares at the accepted
point, and emits logical `shr rax, 63` as one incidental EFLAGS `.write`.
It emits no `.definition`, `.use`, or setcc lifecycle.

## Focused coverage and guard

Coverage includes:

- `arg128`, `scratch128`, and `stack128_value` for both actions;
- both `pair_a` and `pair_b` chooser outcomes and exact instruction order;
- exact EQ `.write/.write/.definition/.use` records and sign-bit `.write`;
- `.spill128`, scalar/stack-object homes, malformed types, wrong predicates,
  and wrong constants rejected without mutation;
- an actual `materializePairValue` failure attributed to the source handle and
  recovered as `composed-block-icmp-lhs`;
- missing subordinate-session authority failure remaining unattributed;
- one unrelated live-accumulator preservation before canonical refresh;
- stable source ownership and no pair result binding after commit;
- durable result lookup plus a following zext after transaction teardown;
- exact rollback after every EQ partial stage: preamble, refresh, chooser,
  materialization, preparation, temp clobber, high-limb copy, immediate,
  XOR, OR, temp copy, CMP, SETE, identity ownership, result definition, and
  finalization;
- exact rollback after every sign-bit partial stage: preamble, refresh,
  high-limb load, preparation, SHR, identity ownership, definition, and
  finalization.

Rollback checks instructions, source/live bindings, spill maps and counters,
accumulator domain, address dependencies, EFLAGS and semantic records,
durable owned identities, and result absence. Testing-allocator teardown
provides leak/double-free detection.

The source guard enforces the one-field semantic intent of each action, pure
classifiers, exact wrapper sequencing and EFLAGS roles, strict
`arg128|scratch128|stack128_value` admission with no `.spill128`, durable
identity ownership, and dormant production status. A negative fixture rejects
physical pair intent and another rejects production wiring. The production
`composed_selector_icmp.zig` file is unchanged.

```text
source_guard_result=31/31
value_use_source_sha256=d67ae7b5b757677f10de69c5490728c4898968857bc927e2074d066c85ba3255
value_use_tests_sha256=b09003c6846dec10f06627d32a496a3e7d47d771aaf56fdf58e47c27c181687b
source_guard_tests_sha256=436c757726b07ea9eb2c51538a95b1b29d32348ea500f03121f7299fe848c773
```

## Validation

Every gate log is paired with its exact command.

Focused source guard:

```text
command=zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox123_icmp_pair/validation/source_guard.log 2>&1
result=31/31 tests; pass
log_sha256=85db1b19f2c6717f08c581b792cf413f8f62472c8d4f8683b1399962e0adca8c
```

Full unit:

```text
command=zig build test --summary all > tmp/inbox123_icmp_pair/validation/full_unit.log 2>&1
result=7/7 steps; 1271/1271 tests; pass
log_sha256=02b8ce0ef4f7557342c98b8ee8a5201edba3f491b1a64cad7e646472a2864197
```

ABI differential:

```text
command=zig build abi-differential --summary all > tmp/inbox123_icmp_pair/validation/abi_differential.log 2>&1
result=60/60 cases; 30/30 real functions; pass
log_sha256=2104b02a92db8f852534f9401528af07a5f30df17b1d6439f04a84063d9fa915
```

Fresh frozen report (exit 1 is the accepted aggregate-failure status):

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox123_icmp_pair/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
```

All six O2 `.spill128` targets remain exactly:

```text
compiler_rt.floatuntidf.__floatuntidf  no_emitter/composed-block-icmp-lhs-loc
compiler_rt.floatuntisf.__floatuntisf  no_emitter/composed-block-icmp-lhs-loc
compiler_rt.floatuntihf.__floatuntihf  no_emitter/composed-block-icmp-lhs-loc
compiler_rt.floattidf.__floattidf      no_emitter/composed-block-icmp-lhs-loc
compiler_rt.floattisf.__floattisf      no_emitter/composed-block-icmp-lhs-loc
compiler_rt.floattihf.__floattihf      no_emitter/composed-block-icmp-lhs-loc
```

Accepted object:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox123_icmp_pair/validation/accepted.o 2> tmp/inbox123_icmp_pair/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

Owner manifest:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox123_icmp_pair/validation/owner_manifest.tsv 2> tmp/inbox123_icmp_pair/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
stderr_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

The frozen report, accepted object, and owner manifest are exact. No target
advanced. No performance, `distribution-all`, or Tier-3 command ran.
