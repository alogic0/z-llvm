# INBOX-119 O2-3I-A2b1 — dormant setcc-producing EAX compare actions

## Frozen base and scope

```text
accepted_code_commit=d90d185955b7c86413ddfa028b793af79a78710d
accepted_code_tree=41e6bac04ead7f08cb71f8dbc3c89e60033ba875
working_head_with_supervisor_docs=92f3d51d9592f39eaf21a217b0cc2cc36474008c
working_head_tree=e3d4034c3710344f5127f464b57ab2304f6c41c3
production_wiring=none
production_icmp_change=none
ratchet_before=186
ratchet_after=186
performance_run=not-run
authorized_or_acceptance_grade_tier3=not-run
stash_at_0=untouched
```

This slice adds one dormant, closed semantic action for the ten
setcc-producing EAX forms. It does not design or admit the two
sign-extraction forms, any RAX-result form, a pair result/source view,
`.spill128`, CFG labels, or a production consumer.

## Audited form closure

| Form | Semantic admission | Action-owned instruction shape |
| --- | --- | --- |
| exact-EI narrow | existing exact width set only; immediate; six accepted predicates | low-bit AND, optional signed shl/sar, cmp, setcc |
| integer eq nonzero immediate | width at most 32 | cmp, sete |
| signed-gt i6 -1 | exact width/immediate | prepare, sign-bit AND definition, sete |
| signed-gt i16 -1 | exact width/immediate | prepare, sign-bit AND definition, sete |
| signed-gt i32 -1 | exact width/immediate | prepare, sign-bit AND definition, sete |
| signed-gt i32 immediate | exact width | cmp, setg |
| signed-lt i32 nonzero immediate | non-samesign, exact width, nonzero | cmp, setl |
| samesign unsigned i6/i7 immediate | ult/ugt and audited range | mask, cmp, setb/seta |
| non-samesign unsigned i6 special immediate | low six bits equal 51 | mask, cmp 51, setb |
| unsigned-lt i32 immediate | exact width | cmp, setb |

`SetccEaxCompareAction` carries only result identity, semantic operand type,
predicate, `samesign`, the semantic immediate, and the ordinary/exact-EI
structure. It has no home, register, displacement, preservation, or
sequencing field. The future exact-EI production classifier remains
responsible for the already accepted structural-family predicate; the action
itself additionally accepts only the frozen exact width set. Consequently
this dormant API does not broaden exact-EI admission.

The named operand is registered before sealing. Execution runs the accepted
live-accumulator preservation preamble, rebuilds the prepared record from
canonical state, validates the refreshed binding/home, and materializes the
semantic low EAX view internally. No prepared location escapes.

The two audited preparation shapes remain distinct:

- sign-bit AND forms call subordinate `prepare(.preserve, .spill_live)`
  before the AND becomes the EFLAGS definition;
- compare/mask forms emit normalization writes and the compare definition,
  preserve that definition through preparation, then emit setcc as the
  EFLAGS use.

Immediate validation retains legacy timing. After the accepted accumulator
preamble and canonical refresh, checks historically preceding operand
staging (including exact-EI width and bounded i6/i7 range checks) still run
before materialization. An ordinary i32 immediate that cannot be encoded is
rejected only after source materialization, then the outer authority rolls
the complete instruction mutation back. Exact-EI unsupported predicates
remain an authority-level failure after the compare definition, rather than
becoming lhs request provenance.

The result identity is copied with `ownActionIdentity` immediately before
the `.zeroExtending(1)` subordinate definition. A committed transaction can
deinitialize and the following zext instruction still resolves and consumes
the result. No transaction-local `ActionIdentity.slice()` becomes a durable
selector-map key.

## Focused tests and guard

The focused transaction tests cover:

- byte-exact representative streams and EFLAGS records for all ten forms;
- the established preamble relocating a live EAX operand, followed by
  canonical re-resolution and staging from the accepted scratch home;
- spill reload and wider scalar-binding low-EAX views;
- exact-EI width closure, sign-extraction exclusion, semantic i64/RAX-result
  exclusion, and explicit pair/`.spill128` location rejection;
- unresolved, width, and location request provenance, with semantic and
  authority failures remaining unattributed;
- post-materialization immediate failure timing and exact rollback;
- cross-instruction durable result lookup after transaction teardown;
- rollback after each of the eight required boundaries: preamble,
  materialization, normalization/mask, EFLAGS definition, accumulator
  preparation, setcc, result ownership/definition, and finalization.

The source guard enforces the semantic-only public intent, canonical
preamble/materialization/preparation/setcc/durable-definition order, two
distinct preparation points, absence of raw prepared-location access, and
owned result identity. Its dormant-production guard rejects the new form,
action, and diagnostic mapping markers from every composed-selector
production consumer. `composed_selector_icmp.zig` is byte-identical to the
accepted working head.

## Frozen report, object, and owner identities

Fresh report input:
`tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll`
(`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`).

Exact command (exit 1 is the frozen report's expected aggregate failure
status):

```text
zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox119_icmp_setcc_eax/fresh_full_report.log
```

```text
fresh_report=tmp/inbox119_icmp_setcc_eax/fresh_full_report.log
fresh_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

Accepted-only input:
`tmp/inbox63_accepted_cohort.ll`
(`d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4`).

Exact object command:

```text
zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox119_icmp_setcc_eax/accepted.o 2> tmp/inbox119_icmp_setcc_eax/accepted.stderr
```

Exact owner command:

```text
zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox119_icmp_setcc_eax/owner_manifest.tsv 2> tmp/inbox119_icmp_setcc_eax/owner_manifest.stderr
```

```text
accepted_object=tmp/inbox119_icmp_setcc_eax/accepted.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox119_icmp_setcc_eax/owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
target_advance=none
```

The exact cumulative report identity proves that all six `.spill128` target
rows remain at `composed-block-icmp-lhs-loc` and that no non-target row
moved.

## Validation

Focused source guard exact command:

```text
zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox119_icmp_setcc_eax/source_guard.log 2>&1
```

```text
source_guard=29/29
source_guard_log=tmp/inbox119_icmp_setcc_eax/source_guard.log
source_guard_log_sha256=7ec5db6bbbaa3b7adc6a0bfc8d6afe0c0c3113b3e47f99c0abff63aea9bd30e0
```

Full-unit exact command:

```text
zig build test --summary all > tmp/inbox119_icmp_setcc_eax/full_unit.log 2>&1
```

```text
full_unit=1249/1249
full_unit_log=tmp/inbox119_icmp_setcc_eax/full_unit.log
full_unit_log_sha256=6767fc7c516d9d52cee024265e432708739fe7c7aa62bd3d23086e3962d596c7
```

ABI exact command:

```text
zig build abi-differential --summary all > tmp/inbox119_icmp_setcc_eax/abi_differential.log 2>&1
```

```text
abi_differential=60/60 cases; 30/30 real functions; result=pass
abi_log=tmp/inbox119_icmp_setcc_eax/abi_differential.log
abi_log_sha256=e45ca29aa7f77661bc24b22df3c282b18a804983bc2a5bc7691052003f792cfd
git_diff_check=pass
production_icmp_diff=none
ratchet=186
performance_run=not-run
authorized_or_acceptance_grade_tier3=not-run
```

INBOX-119 stops here before production wiring and before the separate
sign-extraction I-A2b2 design.
