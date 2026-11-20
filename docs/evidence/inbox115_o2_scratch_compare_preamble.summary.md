# INBOX-115 O2-3I-A1b — dormant scratch-compare preservation preamble

## Frozen base and scope

```text
accepted_code_commit=d6d9efc8
working_head_with_supervisor_docs=dffb2f1568d165c923f22d6cfcd779a70425cff3
working_head_tree=2c568f90fc80fc07d81ea5df2e4da65968cb17a5
ratchet_before=216
ratchet_after=216
production_icmp_change=none
performance_run=not-run
tier3=not-run
```

The primary and wiring-only preserved I-B1 patches remain byte-identical and
unapplied in the delivered tree:

```text
tmp/inbox112_icmp_scratch_perf/inbox112_i_b1_hard_stop.patch
tmp/inbox114_icmp_scratch_perf/inbox114_preserved_wiring_only.patch
sha256=78f75c9c2696885621a3e57ca363891fc5b7d739beaefb9efe19a41768c3a3b9
git_apply_check=pass
stash_at_0=untouched
```

## Dormant mechanism

The closed scratch-compare action now reproduces the legacy two-phase
accumulator sequence internally:

1. Before staging either operand, it loops through
   `liveAccumulatorNameAfterCurrent` and
   `preserveLiveAccumulatorValue`.
2. It then rebuilds the lhs and any named-rhs prepared records from canonical
   selector state. The pre-relocation lhs view received by the action is never
   inspected or used.
3. It stages lhs and rhs in the existing audited order.
4. It leaves the existing
   `session.prepare(.preserve, .spill_live)` point after staging, followed by
   normalization, compare, setcc, definition, and finalization.

The preservation preamble snapshots and validates EFLAGS and the semantic
record length around the move-only loop. The source guard enforces the
preamble/refresh/stage/session-prepare ordering, canonical record rebuilding,
single use of the legacy liveness/preservation loop, and the absence of
consumer-visible preserve/early/phase intent.

## Focused proofs

The transaction tests cover:

- the exact two-compare `or_branch` prefix:
  lhs staging, test/setne, prior EAX result to the accepted RDI scratch home,
  then rhs staging and test/setne;
- an operand initially resident in EAX being preserved, canonically
  re-resolved, and staged from its new home;
- the no-live-accumulator path retaining its existing stream with no
  preservation;
- multiple live logical aliases each preserved once, without a duplicate
  accumulator spill;
- rollback after the first preservation and after canonical-view refresh;
- EFLAGS and semantic-record identity across preservation;
- the later accumulator session not duplicating the preamble preservation.

The ten legacy direct-lowering tests whose newly migrated requests require
liveness metadata now install minimal current-instruction allocation plans.
The lhs-before-rhs provenance regression is also retained as a dormant test.
These are test-harness corrections only.

To prove the previously failing I-B1 paths without retaining production
wiring, the hash-verified wiring-only patch was applied temporarily, the full
unit suite was run, and `composed_selector_icmp.zig` was restored. The probe
result was:

```text
functional_tests=1228/1228
expected_guard_rejection=1
expected_guard_error=FrozenBypassOccurrenceMismatch
probe_log=tmp/inbox115_wired_full_unit_probe_final.log
probe_log_sha256=694e80a8310f4ccf66a7b8dce29aa9fa69d6a4a75f273f0ba13a3537f232334e
```

The expected guard rejection proves that the temporary I-B1 production
wiring was not admissible in this dormant slice. The twelve previously
failing functional paths, including the two-compare live-accumulator case and
lhs/rhs provenance case, all pass.

## Clean-tree validation

```text
source_guard=27/27
source_guard_log=tmp/inbox115_source_guard_final.log
source_guard_log_sha256=06db90a4266c5078a421c66e22c479c475df15c91f4fb51061f1f59e68a570fb

full_unit=1229/1229
full_unit_log=tmp/inbox115_full_unit_final.log
full_unit_log_sha256=9cd751448df7188ae7159105f5ccd2bb29dd0fe7a6478d9274524431c1570c2b

abi_differential=60/60 cases; 30/30 real functions; result=pass
abi_log=tmp/inbox115_scratch_compare_preamble/abi_differential.log
abi_log_sha256=9c618e186bf4b5b5511a7b8a42ffc8f1b1cff87b6f9c724f4046feba9dd9be4c
```

## Frozen identities

The fresh report input remains
`tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll`, SHA-256
`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`.

```text
fresh_report=tmp/inbox115_scratch_compare_preamble/fresh_full_report.log
fresh_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
first_selector=unsupported_type/unsupported-return-type
```

The accepted-only input remains `tmp/inbox63_accepted_cohort.ll`, SHA-256
`d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4`.

```text
accepted_object=tmp/inbox115_scratch_compare_preamble/accepted.o
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest=tmp/inbox115_scratch_compare_preamble/owner_manifest.tsv
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owners=composed_block:40 composed_cfg:127 legacy_envelope:17 structural_fallback:101
ledger=167/17/101
```

The exact report, object, and owner identities prove that the amendment is
dormant and advances none of the twelve O2 target rows. INBOX-115 stops here
before the I-B1 resume.
