# INBOX-180 — intByteSize-only call re-isolation stop

Status: **STOPPED at blocking bar 2.** The `zig.target.intByteSize`-only
temporary build passed exact object/owner/per-function/frontier bar 1, then
full unit failed at 1397/1398 with
`FrozenBypassOccurrenceMismatch`. Per the directive, standalone source guard,
canaries, and standalone ABI were not run; no diagnosis or fix-forward was
attempted. The complete `intByteSize` family is retained wholesale.
Production routing remains dormant and the O2 bypass ratchet remains **131**.

## Frozen basis

```text
composite_operating_head=1dd925c6384b8c77b947f4f1f0109a18c8cce61c
accepted_inbox179_evidence=262f48802bb36d54c7cd9133f7adfddaab12324f
accepted_dormant_source_tree=42eaef5936ff1b1978ee266859a41536fb3110e6
accepted_dormant_implementation=c0f43aea3e9edde4dd16c548067d86aee7520fb6
authorized_infrastructure_commit=5e1cb6f174f788aec458806855576079a05edd45
watcher_git_blob=8f3be1dd08dadc6f42ede169ca05e84daae773ab
stash_at_0=7985c6d (INBOX-93 preservation)
ratchet=131
```

The accepted dormant source and frozen surfaces before temporary work were:

```text
composed_selector_calls.zig=f1046632d670d61439df7252ba12a1ea474829a4b479ed7758ea4e223866cf2d
source_guard/consumer_policy.zig=f7076f86ee49705daf25bb762f1f244728e1c0a1bedb850494ee704ec33ac3d9
value_use/actions/calls.zig=ee5e8d740a42ed1165461cbf2357d63e68347534988915c7f92625cc88032ed0
value_use/model.zig=3bd22867b20587918132090143f407e042f32d44a3948ad3d7dc23a4cd02dfd7
value_use_facade=4f5887e9d2bce0943df26c1e08e8360053440da64eefd19ddfd9d53225dddd7a
facade_manifest=2adcd99ee3bfbe0e9f09673f1df02ab305b5ddb2c1b461023152d5d03a079c26
facade_manifest=126_symbols_plus_header
bypass_tsv=2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11
retention_policy=a31e3fbf7aa03c8544fc5f9921e350c25e4e470cc3c779dfb356136634e052dd
retention_pins=f4374187d77ec6b7c42ee1b64538ead1a2d599697595a7f59c28b23dae5c6614
clean_tmp_tool=8e0c54ad6fed9e46326049dbe64bff743daddcc2527c1dc4d5e02be15fba2d5e
watcher_sha256=ac1d08eed3aadc8ed9ccf7afb5df93889630c95a68e7fe594aba67a760a89dd7
```

Complete pre- and post-isolation source hash manifests are retained at:

```text
tmp/inbox180_o2_intbytesize_reisolation/results/baseline/source_hashes.sha256
tmp/inbox180_o2_intbytesize_reisolation/results/intbytesize/restored_source_hashes.sha256
```

## Fresh temporary patch

The temporary patch was generated from the accepted tree and touches only:

```text
src/codegen/x86_64/generic_cfg/composed_selector_calls.zig
src/codegen/x86_64/generic_cfg/source_guard/consumer_policy.zig
```

Provenance:

```text
patch=tmp/inbox180_o2_intbytesize_reisolation/patches/intbytesize.patch
patch_sha256=34695ac30f8d25ac5d59351943cbfeb84df309162d056996bd18d597979a05a7
temporary_calls_sha256=8e27ae22a89db5246ea34ded85b776ab50141c7d682accdaae8dad3225147989
temporary_guard_sha256=4c058d81c25957c80a2a966ebf62da3df7abada7a5a444c5d4d66cbf9be4cff8
diff_stat=152_insertions,13_deletions
post_restore_git_apply_check=pass
```

The temporary consumer retains the legacy validation order before
transaction creation:

```text
required result
call form
tail kind
i16 return and one-argument signature
i16 argument type
```

Only after those checks does it register one semantic i16 request, attach one
copied `IntByteSizeCallAction` while registering, then seal, prepare,
materialize, and commit. The temporary guard accounting is confined to
`lowerIntByteSizeCall` and its one request-provenance mapper. The accepted
ordinary family remains entirely legacy-routed; there is no aggregate route,
fallback, consumer home/liveness query, or action/model/Q1/facade/import
change.

Immutable artifacts:

```text
command=/home/oleg/bin/zig build --summary all
baseline_artifact=tmp/inbox180_o2_intbytesize_reisolation/artifacts/baseline/z_llvm
baseline_artifact_sha256=784fe1ac77435d1e410a6b44d36cfdd71fc8c569ba1d668183e5aaea1f56959d
baseline_build_log_sha256=d59a3b6e76cb0d515fb26709f1f288403b556b22c6157788973738eb2f8daf05
intbytesize_artifact=tmp/inbox180_o2_intbytesize_reisolation/artifacts/intbytesize/z_llvm
intbytesize_artifact_sha256=3739f295652630c0f305e1527937fcc1f8d4ecb778515b9cb456d166fbe441fb
intbytesize_build_log_sha256=d59a3b6e76cb0d515fb26709f1f288403b556b22c6157788973738eb2f8daf05
artifact_modes=0555
```

## Bar 1 — identities, 285 functions, and frontier: PASS

Exact commands, once per immutable artifact:

```text
LC_ALL=C <artifact>/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > <result>/accepted.o 2> <result>/accepted.stderr
LC_ALL=C <artifact>/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > <result>/owner.tsv 2> <result>/owner.stderr
```

Both sides reproduce:

```text
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
object_stderr_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_stderr_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
owner_ledger=167/17/101
baseline_vs_intbytesize_object_cmp=identical
baseline_vs_intbytesize_owner_cmp=identical
```

Complete function bytes and disassembly were compared with:

```text
(cd <result> && LC_ALL=C objdump -d accepted.o > accepted.objdump)
cmp -s <baseline>/accepted.objdump <intbytesize>/accepted.objdump
rg -c '^[0-9a-f]+ <[^>]+>:$' <result>/accepted.objdump
```

Result:

```text
per_function=285 compared / 0 divergent / 0 missing
baseline_disassembly_sha256=43663485089e1d1ef3f7cd7195c747e23e44366e700b733294fe14ad7bafa919
intbytesize_disassembly_sha256=43663485089e1d1ef3f7cd7195c747e23e44366e700b733294fe14ad7bafa919
first_semantic_instruction_divergence=none
downstream_branch_offset_divergence=none
```

The canonical 443-row source remains absent. No fresh or substitute report
was attempted or claimed. Historical report
`49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`
is reference-only.

Its six frozen frontier rows were extracted from that immutable reference:

```text
frontier_reference=tmp/inbox170_o2_uq32_fixture_alignment/validation/fresh_full_report.log
frontier_reference_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
frontier_rows=tmp/inbox180_o2_intbytesize_reisolation/results/intbytesize/frontier_reference_rows.txt
frontier_rows_count=6
frontier_rows_sha256=bc1b36bfc72d0d9430ba1d3c74035dc405218b19ec648c0413214aee6728b26b
```

Fresh source proof shows the temporary route remains behind the exact
`call.callee == "zig.target.intByteSize"` dispatch. None of the six frozen
compiler-rt callees can enter it, and no ordinary classifier/consumer exists
in the temporary tree. The captured proof SHA-256 is
`1f7d12afe3c78f445da1a40a7d2fc3cc7a0f43c96e6b575ba2b630950fda600b`.

## Bar 2 — full unit: FAIL

Exact command:

```text
command=/home/oleg/bin/zig build test --summary all
result=5/7_steps,1397/1398_tests,fail
log=tmp/inbox180_o2_intbytesize_reisolation/logs/intbytesize/full_unit.log
log_sha256=5fb7f5f26edc460656e4a9c3c3514c372e0c6f5851896420edf20e1631a619cb
```

The sole failure, retained verbatim in the log, is:

```text
test=codegen.x86_64.generic_cfg.source_guard.split_policy_tests.test.composed selector source guard accepts the fully classified current tree
error=FrozenBypassOccurrenceMismatch
origin=source_guard/core.zig:239 validateFrozenBypassInventoryForSource
summary=1397 pass / 1 fail / 1398 total
```

This evidence records the exact failure only. Per the no-fix-forward rule,
no diagnosis, instrumentation, guard-policy change, or second attempt was
made.

The full-unit command's existing transitive ABI step printed a passing
60/60 + 30/30 summary before the unit failure. It is retained as part of the
failed unit log only; it is not claimed as the separately ordered standalone
ABI bar.

## Later bars — NOT RUN

The bar-2 failure prohibited every remaining command:

```text
standalone_source_guard=NOT_RUN
focused_canaries=NOT_RUN
standalone_abi=NOT_RUN
ordinary_isolation=NOT_RUN
aggregate_isolation=NOT_RUN
production_wiring=NOT_RUN
performance=NOT_RUN
integrated_executable=NOT_RUN
strengthened_tier2=NOT_RUN
distribution_all=NOT_RUN
tier3=NOT_RUN
clean_tmp=NOT_RUN
```

## Restoration and disposition

Both temporary files were restored with scoped
`git checkout -- <files>`. The retained patch applies cleanly to the restored
tree. Production/action/model/guard/tool/build/facade/bypass/retention/
watcher sources match the accepted dormant tree exactly; `stash@{0}` remains
`7985c6d`. No retained artifact was removed or normalized.

Disposition:

```text
intByteSize=RETAIN_WHOLESALE
ordinary=UNCHANGED_ACCEPTED_ISOLATION
aggregate=NOT_RUN
direct_credit=0
helper_collapse_credit=0
ratchet_before=131
ratchet_after=131
```

STOP for Watcher/Reviewer review before aggregate isolation or production
wiring.
