# INBOX-121 O2-3I-A2b2 — dormant current-home sign-bit action

## Frozen scope

```text
accepted_production_commit=406955b4
accepted_production_tree=a4bc7d143e4a29d18d44d0ff6c50d51f975a599d
working_head_with_supervisor_docs=9591f79fdc635527600e52f4ac8140bf8ab1dd76
working_head_tree=ebce57cbe88aa66cc0c97f9b3251f221562d1e77
production_icmp_change=none
ratchet_before=176
ratchet_after=176
performance_run=not-run
authorized_or_acceptance_grade_tier3=not-run
stash_at_0=untouched
```

This slice adds one dormant `CurrentHomeSignBitAction`:

```text
{ result: ActionIdentity, operand_ty: ir.Type }
```

No predicate, RHS, physical register, shift count, source home, displacement
policy, or sequencing hint crosses the action API. The pure future-dispatch
classifier admits only `slt i32/i64 <named>, 0`; i128, other widths and
predicates, nonzero or non-immediate RHS forms, and non-named operands remain
outside the action.

The closed action derives i32 versus i64 from `operand_ty`, runs the global
live-accumulator preamble, invokes the matching current-EAX/current-RAX
preservation behavior, re-resolves the source canonically, and materializes it
without copying an already-resident dead operand. It then prepares the
subordinate accumulator session at the audited point and emits exactly:

```text
i32: shr eax, 31
i64: shr rax, 63
```

Both shifts pass through the EFLAGS emission authority with incidental
`.write`. The action emits no `.definition`, `.use`, or setcc relationship.
It owns the result identity with `ownActionIdentity`, defines the existing
`.zeroExtending(1)` result, finalizes the subordinate session, and leaves the
sole commit to the outer transaction.

Logical aliases sharing one live physical accumulator value are rebound to the
single preserved home without another copy. This is action-local dormant
behavior; the existing production actions and global preservation helper are
unchanged.

## Focused coverage and guard

Coverage includes:

- exact SHR streams for EAX/RAX, matching argument and scratch registers, and
  spill-backed homes;
- no copy/reload for an already-resident dead operand;
- one preservation plus canonical re-resolution for a live source;
- multiple live accumulator aliases preserved with one physical move;
- exactly one incidental EFLAGS `.write`;
- durable result lookup followed by a zext after transaction teardown;
- exact rollback after the global preamble, current-home preservation,
  materialization, session preparation, shift append, result definition, and
  finalization;
- distinct unresolved, width, and location provenance;
- authority errors remaining unattributed;
- pair and `.spill128` rejection without mutation.

The source guard enforces the two-field semantic intent, pure classifier,
width-derived EAX/RAX preservation, canonical refresh, SHR-only instruction
selection, incidental-write-only EFLAGS effect, durable identity ownership,
seven rollback boundaries, and dormant production status. Negative fixtures
reject physical API fields and any production action wiring. The production
`composed_selector_icmp.zig` file is unchanged.

```text
source_guard_result=30/30
value_use_source_sha256=42d9b472012577fc7a9769dc1664258e88a8d5dd8bee603d778279fe4a534b88
value_use_tests_sha256=9fb852e8abc912e5eb7cffb54d5935b9b40fb62de891dde7cdbdd262c260eedf
source_guard_tests_sha256=f74367b9c63e81becee9aa75ddb5721f56b9692dcef5eb9448a54b132a6b6a37
```

## Validation

Every gate log is paired with its exact command.

Focused source guard:

```text
zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox121_icmp_signbit/validation/source_guard.log 2>&1
result=30/30
log_sha256=725adf83905d661b661beafbf78107775d4f73ab5a877c61a2445840a6828f81
```

Full unit:

```text
zig build test --summary all > tmp/inbox121_icmp_signbit/validation/full_unit.log 2>&1
result=7/7 steps; 1259/1259 tests; pass
log_sha256=87a4bc488c3e8bc89b874fced37ee39bb1277a499fb0636b2416b2653fa71d0a
```

ABI differential:

```text
zig build abi-differential --summary all > tmp/inbox121_icmp_signbit/validation/abi_differential.log 2>&1
result=60/60 cases; 30/30 real functions; pass
log_sha256=f728d147d87cb19fa09f00b977f7d096656bec4ef1a1966ac11c6e144dfd61cb
```

Fresh frozen report (exit 1 is the accepted aggregate-failure status):

```text
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox121_icmp_signbit/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
```

Accepted object:

```text
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox121_icmp_signbit/validation/accepted.o 2> tmp/inbox121_icmp_signbit/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
```

Owner manifest:

```text
LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox121_icmp_signbit/validation/owner_manifest.tsv 2> tmp/inbox121_icmp_signbit/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

The frozen report, accepted object, and owner manifest are exact. No target
advanced. No performance command, `distribution-all`, or Tier-3 command ran.
