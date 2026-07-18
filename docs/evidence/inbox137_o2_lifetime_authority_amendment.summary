# INBOX-137 — value-use lifetime-authority amendment

Status: implementation complete; stopped for Supervisor/Reviewer review.
This is the single authorized semantic amendment. Production lowering and
dispatch are untouched, the bypass ratchet remains 166, the parked immediate
wiring was not applied, and no performance or Tier 3 command was run.

## Frozen basis and preservation boundary

```text
working_head=b294a200b5e4f9e6160e50fe996314f9571064f6
working_tree_before_amendment=abb0067f514c541dce021088db660c7adfbb26b4
accepted_INBOX_136=e7d740c4
ratchet=166 (unchanged)
scalar_arithmetic_lines=1561
scalar_arithmetic_ceiling=2000
original_wiring_patch_sha256=39aa6d5331a0d404bc1b8aca6372e3927314e1044c5b56788c01a1bd86c1dba5
second_stop_patch_sha256=8ab26a97f2337790338025fcee0c8f296430abdf7320ae03588ca6fdff60b9ef
third_stop_patch_sha256=3f3e46ff0fd9b92a40287840716853c1dda70a3f90220107d3301598051f035d
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7 (untouched)
performance_run=none
tier3=not_run
```

`composed_selector_scalar.zig` remains byte-for-byte unchanged at
`78452e32276f9968e22f938d52ea758f36845af08fa883c98ae78a509fff5c3c`.
The frozen bypass inventory remains byte-for-byte unchanged at
`5b3ac6b5a98184ed0562a2685c82ca8e1e7b5f33be0018b6d24255071c9f34ad`.

## Private lifetime context

The transaction now owns a private fixed-capacity `LifetimeContext`. A pin
stores only the request's copied semantic identity and virtual-register
generation. It never stores a `ValueLoc`, and no lifetime query is exposed by
the facade.

The three decisions are separate:

- `availabilityForConsumption` (Q1) requires a canonical binding, allocation
  plan, interval entry, and valid dependency metadata for every named source.
  Missing plan returns `ValueUseSourcePlanMissing`; missing interval returns
  `ValueUseSourceIntervalMissing`; only a valid interval before the current
  instruction returns `ValueUseExpiredSource`. End-at-current is available.
  Typed integers and typed null pointers have no binding lifetime and are
  exempt. Revalidation after action-managed preservation or session
  preparation compares identity/generation and re-resolves the canonical
  location.
- `mustSurviveInstruction` (Q2) first validates Q1, then uses the strict
  after-current boundary. It does not answer present availability.
- `occupantNeedsPreservation` (Q3) examines other canonical bindings occupying
  a destructive physical destination, validates their plan/dependency
  metadata, and preserves only occupants live strictly after the instruction.
  It does not manufacture source survival or inclusive displacement.

All request-boundary failures retain the first matching `RequestHandle`;
nested validation does not replace a more precise first failure. Automatic
rollback resets lifetime pins with the transaction state while retaining the
diagnostic-only failed-request provenance.

## Closed immediate displacement table

The plan table is frozen in the co-located Zig tests and guard. It is not a
generic wide/narrow policy.

| plan | exact displacement authority |
|---|---|
| R00 signed divide by two | Q2 strict-after, scratch-preferred fallback |
| R01 logical shift right | sessionless scratch; hard spill-live only for the spill-through-RAX fallback |
| R02 shift left | widths through 32 use Q2 strict-after; i64 uses inclusive preserve-current |
| R03 arithmetic shift right | narrow accumulator uses Q2 strict-after; i64 scratch is sessionless |
| R04 narrow immediate arithmetic | Q2 strict-after, scratch-preferred fallback |
| R05 wide immediate arithmetic | inclusive preserve-current, spill-live fallback |
| R06 wide scratch arithmetic | sessionless scratch |
| L01 reverse subtract | hard spill-live |
| L02 variable shift left | hard spill-live |
| L03 variable logical shift right | hard spill-live |

A2 source survival and A3 unrelated-occupant preservation remain independent.
The accepted `%11 = and %9, 0xffffffff` R05 stream comes directly from the
inclusive plan rule even though `%9` ends at the current instruction. The
production-faithful test has `%9` in RAX, `%10` already spilled and live, no
unrelated RAX alias, and proves the exact spill/reload/AND sequence. The
separate A3 fixture uses genuine multiple live aliases to prove Q3 preserves
one physical occupant exactly once.

## Focused proof and guards

The test suite now covers:

- missing plan, missing interval, expired interval, end-at-current, and
  survives-after-current;
- typed-null plan exemption;
- malformed dependency metadata with exact rollback;
- two registered requests retaining first-failure attribution;
- Q1 revalidation after Q3 preservation and after accumulator preparation;
- the real `__multi3` `%9/%10/%11` shape, plus genuine Q3/no-alias controls;
- source-live Q2 behavior, multiple aliases, EFLAGS preservation, and rollback
  after preservation and canonical refresh.

Dormant selector fixtures that register named sources now carry
production-faithful allocation-plan intervals. The source guard requires the
private identity/generation-only context, distinct missing-plan/missing-entry
errors, inclusive Q1 versus strict Q2 boundaries, dependency validation,
post-mutation Q1 revalidation, exact immediate-plan displacement assignments,
and the continued separation of cast and arithmetic displacement authorities.
Negative fixtures reject context exposure, a retained `ValueLoc`, collapsed
plan errors, an at-or-after Q2 boundary, old direct alias scanning, and plan
widening.

## Validation

Every retained log is paired with its exact command.

### Full unit gate

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox137_lifetime_authority/validation/full_unit.log
result=7/7_steps,1320/1320_tests
log_sha256=7e20addf142daaa7b676fe390aaf760c8a122121c0bc1bd002d786bf9cf1d484
```

### Required plain-path ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox137_lifetime_authority/validation/abi_differential.log
result=5/5_steps,60/60_cases,30/30_real_functions
log_sha256=c0556cd821461d59a8f104f65a0bccbcd5706dc0d03681a81218ef7f0357cebc
```

### Frozen report

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox137_lifetime_authority/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
```

### Accepted object and owner projection

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox137_lifetime_authority/validation/accepted.o 2> tmp/inbox137_lifetime_authority/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_bytes=0

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox137_lifetime_authority/validation/owner_manifest.tsv 2> tmp/inbox137_lifetime_authority/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
owner_ledger=167/17/101
stderr_bytes=0
```

No performance command and no Tier 3 command were run. B3 remains parked and
is not reauthorized by this change.
