# INBOX-131 — dormant scalar-cast actions

Status: complete; stopped for Supervisor/Reviewer review. This slice adds
only the three authorized dormant scalar-cast authorities, their tests, the
split source-guard extension, and this evidence. No scalar production
consumer instantiates or dispatches an action.

## Frozen basis and implementation state

```text
authorization_commit=2b6a502bbd64306a26c99e5bbf6d042f0a784dd5
production_byte_identity_baseline=9eda8080
tested_implementation_tree=325aed6bf2ce1345b2fb2bd3c9ba2fb9b591e140
stash_at_0=untouched
performance_run=none
tier3=not_run
```

The transaction model now has three closed action forms:

- `PairLowScalarCastAction` accepts only the structural C01
  i128-to-low-scalar cast family. It uses the existing read-only pair
  resolver/low-lane materializer and the accepted planned/existing/fresh
  scratch choice. It creates a sessionless scalar binding and does not
  allocate, bind, or own a pair.
- `AccumulatorScalarCastAction` covers C04, C05, and C52-0 through C52-3.
  Operation, source/result widths, typed immediate, and exact-EI structure
  are transaction-owned action data. The action internally derives the
  preparation effect, displacement, materialization definition, mask, and
  incidental EFLAGS `.write`; one subordinate accumulator session owns the
  result transition.
- `SignExtendScratchAction` is exactly named `sext i32 to i64`. It accepts
  only canonical `arg32`/`scratch32` homes, emits the accepted `movsxd`, and
  produces a sessionless durable scratch binding. It does not inherit
  accumulator, spill, pair, or wider-class admission.

All request identities and result identities use fixed transaction-owned
storage before seal. Typed immediates are copied into both the request and
the semantic action; they are never represented by a binding. C01 and C06
durable result identities are copied with `ownActionIdentity` immediately
before binding. Rollback owns and frees those copies exactly once.

The three pure classifiers inspect only cast IR semantics. Focused negatives
retain C02 scalar alias creation and C03 pair-result creation outside these
actions. The exact-EI boolean is semantic input to the C04/C05 classifier;
this dormant slice does not add or move production dispatch.

## Focused proof surface

`control_compare_scalar_cast_tests.zig` contains 12 focused tests covering:

- accepted C01 arg/scratch/stack/spill pair homes and exact low-limb streams;
- ordinary C05 named/immediate casts, exact-EI C04, and all four admitted
  i52 structural forms with exact masks and EFLAGS records;
- exact C06 durable `movsxd` result lookup after transaction teardown;
- unresolved, width, and location diagnostic precedence with request
  provenance;
- C02/C03 classifier rejection and rejected C06 accumulator/spill/wider
  homes;
- rollback after scratch selection, pair staging, accumulator preparation,
  accumulator materialization, mask materialization/write, sign extension,
  result ownership/definition, and finalization;
- forced identity-allocation failures and exactly-once identity release for
  both sessionless actions.

The split source guard adds two focused policy fixtures. It enforces:

- semantic-only action descriptors with no physical home, register,
  displacement, staging, or family hint;
- pure classifiers with no selector state or home inspection;
- the existing pair-low helper, subordinate-session ordering, exact C06
  home/`movsxd` boundary, durable identity ownership, and no pair-result
  authority;
- complete dormancy: all three use forms, prepared actions, and classifier
  calls are rejected from every production consumer.

The nested facade/action manifest was versioned in place:

```text
facade_manifest=docs/evidence/inbox128_o2_r1_facade_manifest.tsv
facade_manifest_sha256=51527db981eb4da7844856a21e6000fd35caa693b5176685bc40e6a278fe0b1b
control_compare_lines=1766
control_compare_budget=under_2000
```

## Dormant production and ratchet proof

The complete production-lowering/dispatch comparison against `9eda8080`
is empty. The only changed `composed_selector*.zig` file is the transaction
test aggregator.

```text
composed_selector_scalar_sha256=971533d068ae1c9767c2f1049076e8d9f8541d961cb61220a3305b1285654104
baseline_composed_selector_scalar_sha256=971533d068ae1c9767c2f1049076e8d9f8541d961cb61220a3305b1285654104
composed_selector_impl_sha256=630e58e31798fdd6fc27859aeaba19724a9919d10909862997d7be3a8cbc0dae
baseline_composed_selector_impl_sha256=630e58e31798fdd6fc27859aeaba19724a9919d10909862997d7be3a8cbc0dae
bypass_inventory=docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv
bypass_inventory_sha256=6e570be808d2aea9275809471f53846af7f54afdd908ab73e51218579ca8112d
bypass_occurrences=172
```

No bypass row or classification changed.

## Immutable validation

Every retained gate log is paired with its exact command.

### Source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox131_o2_scalar_cast_dormant/validation/source_guard.log 2>&1
result=36/36
log_sha256=57bf111090020783465778a22207a67d4097db67fc65aaf1a3fb9d2598b1f035
```

### Full unit gate

```text
command=/home/oleg/bin/zig build test --summary all > tmp/inbox131_o2_scalar_cast_dormant/validation/full_unit.log 2>&1
result=7/7_steps,1292/1292_tests
log_sha256=3e6869bc35d1df6b9394b97eedd660ed00d78937e50773c84b9d664d78e87f78
```

### Required plain-path ABI differential

```text
command=/home/oleg/bin/zig build abi-differential > tmp/inbox131_o2_scalar_cast_dormant/validation/abi_differential.log 2>&1
result=60/60_cases,30/30_real_functions
log_sha256=e809d75ccb74de060c13ddc581a41dbbea6fea957910c1e6ed54b1be3977464d
```

### Frozen report

The aggregate exit status is the accepted failure-report status `1`.

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox131_o2_scalar_cast_dormant/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
```

### Accepted object and owner projection

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox131_o2_scalar_cast_dormant/validation/accepted.o 2> tmp/inbox131_o2_scalar_cast_dormant/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_bytes=0

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox131_o2_scalar_cast_dormant/validation/owner_manifest.tsv 2> tmp/inbox131_o2_scalar_cast_dormant/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
owner_ledger=167/17/101
stderr_bytes=0
```

The frozen report, accepted object, owner projection, and ratchet are exact.
No performance command and no Tier 3 command were run.
