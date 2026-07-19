# INBOX-180a — intByteSize bypass-transition re-isolation

Status: **ALL FOUR BLOCKING BARS PASS.** The temporary
`zig.target.intByteSize` consumer reproduces the accepted cohort object,
owner projection, and all 285 function bodies exactly. The temporary
fail-closed inventory overlay accounts for only the reviewed
`composed_selector_calls.zig/lowerIntByteSizeCall/emitValueIntoScratch`
transition, and its positive and negative guard proofs pass.

This is isolation evidence only. Every temporary consumer, guard, and test
change was restored. Production remains dormant, no bypass credit is claimed,
and the accepted ratchet remains **131**. Aggregate isolation and production
wiring remain outside this slice.

## Frozen basis and preserved first attempt

```text
composite_operating_head=25fb434987b833328052b448f50f535fc1a6039e
accepted_inbox180_stop=81644889a5931a499a732dce40a3370ac259f14e
accepted_inbox179_evidence=262f48802bb36d54c7cd9133f7adfddaab12324f
accepted_dormant_source_tree=42eaef5936ff1b1978ee266859a41536fb3110e6
accepted_dormant_implementation=c0f43aea3e9edde4dd16c548067d86aee7520fb6
authorized_infrastructure_commit=5e1cb6f174f788aec458806855576079a05edd45
watcher_git_blob=8f3be1dd08dadc6f42ede169ca05e84daae773ab
stash_at_0=7985c6d (INBOX-93 preservation)
ratchet=131
```

The complete first attempt remains unchanged:

```text
evidence=docs/evidence/inbox180_o2_intbytesize_call_reisolation.summary
evidence_sha256=a3c38695cc75c897659b330fc97568ef98e4127047f4b272589f74401088b676
patch=tmp/inbox180_o2_intbytesize_reisolation/patches/intbytesize.patch
patch_sha256=34695ac30f8d25ac5d59351943cbfeb84df309162d056996bd18d597979a05a7
failed_unit_log=tmp/inbox180_o2_intbytesize_reisolation/logs/intbytesize/full_unit.log
failed_unit_log_sha256=5fb7f5f26edc460656e4a9c3c3514c372e0c6f5851896420edf20e1631a619cb
baseline_artifact_sha256=784fe1ac77435d1e410a6b44d36cfdd71fc8c569ba1d668183e5aaea1f56959d
intbytesize_artifact_sha256=3739f295652630c0f305e1527937fcc1f8d4ecb778515b9cb456d166fbe441fb
```

Attempt-1 hashes are retained together at:

```text
tmp/inbox180a_o2_intbytesize_bypass_transition_reisolation/results/baseline/attempt1_provenance.sha256
```

The accepted dormant sources and frozen surfaces before temporary work were:

```text
composed_selector_calls.zig=f1046632d670d61439df7252ba12a1ea474829a4b479ed7758ea4e223866cf2d
source_guard/core.zig=2b03554266798dd7b89819eb4c440d4dbaa7bfd0eae5f2d2a825645636b2682e
source_guard/consumer_policy.zig=f7076f86ee49705daf25bb762f1f244728e1c0a1bedb850494ee704ec33ac3d9
source_guard/authority_policy_tests.zig=5075af61097c194b5c00da12dbd68cecf9226584abab81ca6f147cede4970232
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

Complete pre-isolation and restored hash manifests are retained at:

```text
tmp/inbox180a_o2_intbytesize_bypass_transition_reisolation/results/baseline/source_hashes.sha256
tmp/inbox180a_o2_intbytesize_bypass_transition_reisolation/results/intbytesize/restored_source_hashes.sha256
```

They compare exactly.

## Temporary consumer and guard overlay

The attempt-1 patch was hash-verified and applied cleanly. Its consumer and
consumer-policy results are byte-identical to attempt 1:

```text
temporary_calls_sha256=8e27ae22a89db5246ea34ded85b776ab50141c7d682accdaae8dad3225147989
temporary_consumer_policy_sha256=4c058d81c25957c80a2a966ebf62da3df7abada7a5a444c5d4d66cbf9be4cff8
```

The unchanged consumer preserves the reviewed validation and lifecycle:

```text
required result
call form
tail kind
i16 return and one-argument signature
i16 argument type
register one semantic i16 request
attach exactly one copied IntByteSizeCallAction while registering
seal
prepare
materializeAll
commit
```

The temporary guard overlay is private and exact-tuple scoped. It accepts
canonical expected count one as actual zero only when all of these hold:

```text
source=composed_selector_calls.zig
function=lowerIntByteSizeCall
operation=emitValueIntoScratch
expected=1
actual=0
complete reviewed specialized lifecycle=present
specialized action and attachment counts=exact
legacy occurrence in lowerIntByteSizeCall=zero
ordinary classifier/helper/action=absent
```

It delegates complete lifecycle validation to the existing function-scoped
call-action policy. It does not alter the canonical TSV/hash or permanent
policy and adds no public API, facade symbol, action tag, import, or general
inventory exemption.

The existing authority-policy test leaf adds one positive and six
fail-closed negatives:

```text
complete specialized transition=accepted
missing materializeAll stage=rejected
missing specialized wiring=rejected
ordinary-only activation=rejected
ordinary+specialized aggregate activation=rejected
unrelated inventory mismatch=rejected
specialized+legacy coexistence=rejected
```

No dead, unreachable, comment-only, duplicate legacy token, or canonical
inventory edit is used.

Retained patch provenance:

```text
complete_patch=tmp/inbox180a_o2_intbytesize_bypass_transition_reisolation/patches/intbytesize_with_overlay.patch
complete_patch_sha256=5735b92ff84298954e8f65409daeb08f2208a5aa7e1b6f73cfcf1c1fe47944e7
overlay_patch=tmp/inbox180a_o2_intbytesize_bypass_transition_reisolation/patches/guard_overlay.patch
overlay_patch_sha256=4349738efd39a04e75b206b003f3bcd66206235b404e82fc4304e4bb2cdec72c
temporary_core_sha256=a6ae6af28c6ee5105186840a36c5b1b0c0c894041c653413bbbb82ea78a748c7
temporary_authority_tests_sha256=29ad4f3d3eba0e529497519b3819d1b0b448dac067a8a2ea6bb23783efb9744d
diff=4_files,327_insertions,14_deletions
post_restore_git_apply_check=pass
```

Immutable artifacts were built before and after temporary wiring:

```text
command=/home/oleg/bin/zig build --summary all
baseline_artifact=tmp/inbox180a_o2_intbytesize_bypass_transition_reisolation/artifacts/baseline/z_llvm
baseline_artifact_sha256=af3dfb2e28e4c3a322fcc724190b1be53f8fbe1a2eebc5974f56d9d1ab526f40
baseline_build_log_sha256=25c28ebabfc68db259b2d5e402bbe5b8e8c255261dd5e9e522684d0766d754ec
intbytesize_artifact=tmp/inbox180a_o2_intbytesize_bypass_transition_reisolation/artifacts/intbytesize/z_llvm
intbytesize_artifact_sha256=a7a9321506f8783f567236869bc8bbb40b6ac14b95e077f43927f8bb87498dd9
intbytesize_build_log_sha256=94f3f41c8bce9a8704feb7a19f48c4128744d5168cad5ccd4f3b77e75a75f0bf
artifact_modes=0555
```

## Bar 1 — identities, 285 functions, and frontier: PASS

Exact commands, once per immutable artifact:

```text
LC_ALL=C <artifact>/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > <result>/accepted.o 2> <result>/accepted.stderr
LC_ALL=C <artifact>/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > <result>/owner.tsv 2> <result>/owner.stderr
(cd <result> && LC_ALL=C objdump -d accepted.o > accepted.objdump)
cmp -s <baseline>/accepted.o <intbytesize>/accepted.o
cmp -s <baseline>/owner.tsv <intbytesize>/owner.tsv
cmp -s <baseline>/accepted.objdump <intbytesize>/accepted.objdump
```

Both sides reproduce:

```text
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
object_stderr_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_stderr_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
owner_ledger=167/17/101
per_function=285 compared / 0 divergent / 0 missing
disassembly_sha256=43663485089e1d1ef3f7cd7195c747e23e44366e700b733294fe14ad7bafa919
first_semantic_instruction_divergence=none
downstream_branch_offset_divergence=none
```

The canonical 443-row input remains absent. No fresh or substitute report
was attempted or claimed. Historical report
`49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`
is reference-only.

Its six frozen frontier rows were freshly extracted from the immutable
reference:

```text
frontier_reference=tmp/inbox170_o2_uq32_fixture_alignment/validation/fresh_full_report.log
frontier_reference_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
frontier_rows=tmp/inbox180a_o2_intbytesize_bypass_transition_reisolation/results/intbytesize/frontier_reference_rows.txt
frontier_rows_count=6
frontier_rows_sha256=bc1b36bfc72d0d9430ba1d3c74035dc405218b19ec648c0413214aee6728b26b
```

Fresh source proof records the exact `zig.target.intByteSize` dispatch and
zero ordinary-family classifier/helper occurrences. Combined with identical
objects and all 285 identical function disassemblies, the six frontier rows
cannot move.

## Bar 2 — full unit and standalone guard: PASS

Full unit:

```text
command=/home/oleg/bin/zig build test --summary all
result=7/7_steps,1399/1399_tests,pass
log=tmp/inbox180a_o2_intbytesize_bypass_transition_reisolation/logs/intbytesize/full_unit.log
log_sha256=9b9504398d4974f3ea7d0a0b81fc586192f4761be94e08da411bbdc7bd880212
```

Standalone source guard:

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig
result=63/63_tests,pass
log=tmp/inbox180a_o2_intbytesize_bypass_transition_reisolation/logs/intbytesize/source_guard.log
log_sha256=31c83238dd81adf9d835b548a0b5b8038a0f42a452a74a98d26579b85f2d9912
```

## Bar 3 — focused canaries: PASS

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all
result=2/2_steps,35/35_execution_cases,__multi3_green,fma_green,pass
log=tmp/inbox180a_o2_intbytesize_bypass_transition_reisolation/logs/intbytesize/focused_canaries.log
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

## Bar 4 — standalone ABI: PASS

```text
command=/home/oleg/bin/zig build abi-differential --summary all
result=5/5_steps,60/60_cases,30/30_real_functions,pass
log=tmp/inbox180a_o2_intbytesize_bypass_transition_reisolation/logs/intbytesize/abi_differential.log
log_sha256=b09c2a1dda70d753b3ef88df307a50b520397d9c7e4304604dadab8f6b003e59
```

The complete attempt-2 provenance manifest is retained at:

```text
tmp/inbox180a_o2_intbytesize_bypass_transition_reisolation/results/intbytesize/complete_provenance.sha256
```

## Restoration and disposition

All four temporary files were restored with scoped
`git checkout -- <files>`. The complete retained patch applies cleanly to
the restored tree. The baseline and restored source-hash manifests compare
exactly. Production/action/model/guard/tool/build/facade/bypass/retention/
watcher sources match the accepted dormant tree; the canonical bypass TSV
remains at `2d6c8c88...`, and `stash@{0}` remains `7985c6d`.

No ordinary or aggregate isolation, production wiring, ratchet credit,
performance, integrated executable, strengthened Tier 2, distribution-all,
Tier 3, cleanup, deletion, `clean_tmp`, or substitute-report command ran.
No retained artifact was removed or normalized.

Isolation verdict:

```text
ordinary_gpr_pointer_direct_call=UNCHANGED_ACCEPTED_ISOLATION
intByteSize=PASS_ALL_FOUR_BARS
aggregate=NOT_RUN
production_wiring=NOT_AUTHORIZED
direct_credit=0
helper_collapse_credit=0
ratchet_before=131
ratchet_after=131
```

STOP for Watcher/Reviewer acceptance before aggregate isolation or production
wiring.
