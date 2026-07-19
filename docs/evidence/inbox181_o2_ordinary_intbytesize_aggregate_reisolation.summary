# INBOX-181 — ordinary + intByteSize aggregate re-isolation

Status: **ALL FOUR BLOCKING BARS PASS.** The accepted ordinary GPR/pointer
direct-call lifecycle and the accepted `zig.target.intByteSize` lifecycle are
byte-identical when activated together. The aggregate reproduces the exact
accepted object, owner projection, all 285 function bodies/disassemblies, and
the six frozen pointer-frontier rows/proofs.

This is aggregate isolation evidence only. Every temporary consumer, guard,
and guard-test change was restored to the accepted dormant tree. Production
remains dormant, no bypass credit is claimed, and the ratchet remains **131**.

## Frozen basis

```text
composite_operating_head=c0b9402587043d352969c0106b56cd153c93a317
accepted_intbytesize_isolation=a34815ba
accepted_ordinary_isolation=262f4880
accepted_dormant_implementation=c0f43aea3e9edde4dd16c548067d86aee7520fb6
accepted_dormant_source_tree=4da207e66f407e0ab0f6575ea0aa4b7c9324a4a1
authorized_infrastructure_commit=5e1cb6f174f788aec458806855576079a05edd45
watcher_git_blob=8f3be1dd08dadc6f42ede169ca05e84daae773ab
stash_at_0=7985c6d (INBOX-93 preservation)
ratchet=131
```

The individually accepted evidence remains:

```text
ordinary_evidence=docs/evidence/inbox179_o2_ordinary_call_reisolation.summary
ordinary_evidence_sha256=b02acd4a61e35d9c60ce602b47aae2c44b3fb4138c076503916db26ec52aab09
intbytesize_evidence=docs/evidence/inbox180a_o2_intbytesize_bypass_transition_reisolation.summary
intbytesize_evidence_sha256=15ffc41e343d025daa156ab5c194abbbe84b85669f49d361e8f5c224df249199
ordinary_retained_patch_sha256=4632e70cea5700413c15b458a10a0058234cd7d3d1b41d9770210e14e48ae21b
intbytesize_retained_patch_sha256=5735b92ff84298954e8f65409daeb08f2208a5aa7e1b6f73cfcf1c1fe47944e7
```

The accepted dormant sources and frozen surfaces before temporary work were:

```text
composed_selector_calls.zig=f1046632d670d61439df7252ba12a1ea474829a4b479ed7758ea4e223866cf2d
source_guard/core.zig=2b03554266798dd7b89819eb4c440d4dbaa7bfd0eae5f2d2a825645636b2682e
source_guard/consumer_policy.zig=f7076f86ee49705daf25bb762f1f244728e1c0a1bedb850494ee704ec33ac3d9
source_guard/authority_policy_tests.zig=5075af61097c194b5c00da12dbd68cecf9226584abab81ca6f147cede4970232
source_guard/consumer_policy_tests.zig=8d7b40254eee99fbc1881312e699cf22cb1a785dc257dd7b26d8bd56722e6c61
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

Complete pre-isolation and restored manifests are retained at:

```text
tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/results/baseline/source_hashes.sha256
tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/results/aggregate/restored_source_hashes.sha256
restored_manifest_sha256=7a2e1aa75360de61e0198dfa9830ce970907ad0b3a1fff456a76298099579bf2
baseline_vs_restored_manifest=identical
```

## Fresh combined patch and exact guard mode

The aggregate patch was authored freshly against the accepted dormant tree.
The retained individual patches were provenance references only; they were
not concatenated, stacked, or applied. The aggregate patch is:

```text
patch=tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/patches/aggregate.patch
patch_sha256=b00536c214fcd2ba2c3e6dceabcce5851124d706c890f63edb843e67f298676c
guard_patch=tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/patches/combined_guard.patch
guard_patch_sha256=9263f132b7bc30d6c17c26c58f61c8cfe9874ee0abdc453d730951130f089e3e
diff=5_files,497_insertions,19_deletions
post_restore_git_apply_check=pass
```

Only these temporary files changed:

```text
src/codegen/x86_64/generic_cfg/composed_selector_calls.zig
src/codegen/x86_64/generic_cfg/source_guard/core.zig
src/codegen/x86_64/generic_cfg/source_guard/consumer_policy.zig
src/codegen/x86_64/generic_cfg/source_guard/authority_policy_tests.zig
src/codegen/x86_64/generic_cfg/source_guard/consumer_policy_tests.zig
```

The combined consumer activates exactly:

```text
ordinary GPR/pointer:
  pure semantic classifier after all frozen intrinsic/call-form/SSE/signature checks
  register every named operand in source order
  attach exactly one copied DirectCallAction while registering
  seal -> prepare -> materializeAll -> commit

zig.target.intByteSize:
  frozen result/call-form/tail/signature/type validation order
  register one semantic i16 operand
  attach exactly one copied IntByteSizeCallAction while registering
  seal -> prepare -> materializeAll -> commit
```

Every scalar-SSE, indirect, i128/pair, pointer-frontier, stack/aggregate,
immediate, copy-cycle, tail, non-`intByteSize` intrinsic, and other call form
continues through its exact legacy path before transaction creation. The
temporary consumer performs no home/liveness query, attempt-then-fallback,
action/model/Q1/lifetime/materialization/facade/import change, or diagnostic
normalization.

The separate temporary aggregate guard mode is fail-closed. It activates only
when both reviewed lifecycles are complete in
`lowerOrdinaryDirectCallValueUse` and `lowerIntByteSizeCall`. It permits only:

```text
source=composed_selector_calls.zig
function=lowerIntByteSizeCall
operation=emitValueIntoScratch
expected=1
actual=0
```

It requires two exact action attachments, one `DirectCallAction`, one
`IntByteSizeCallAction`, both dispatches in `lowerCall`, zero specialized
legacy occurrences, and the complete function-scoped mapper/lifecycle
shapes. Existing guard leaves prove:

```text
complete aggregate lifecycle=accepted
partial ordinary lifecycle=rejected
partial specialized lifecycle=rejected
ordinary-only activation=rejected
specialized-only activation=rejected
cross-family marker=rejected
action outside approved functions=rejected
unrelated inventory mismatch=rejected
specialized-plus-legacy coexistence=rejected
```

No dead/comment token, general opcode exemption, duplicate legacy
occurrence, public API, action/model/facade extension, or canonical inventory
edit was used. Temporary source hashes and full patch provenance are retained
at:

```text
tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/results/aggregate/temporary_source_hashes.sha256
tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/results/aggregate/patch_hashes.sha256
```

Immutable artifacts were built before and after the combined temporary
change:

```text
command=/home/oleg/bin/zig build --summary all
baseline_artifact=tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/artifacts/baseline/z_llvm
baseline_artifact_sha256=351340dba6aecf8fc1d82c03c9737a97a6c281fb7ff6e3119ac9b6d37340d9e3
baseline_build_log_sha256=4c8cde212f9eb9490515f21384e0a8eb2eb281fb819dc37512b117a32c04f578
aggregate_artifact=tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/artifacts/aggregate/z_llvm
aggregate_artifact_sha256=a79659648131d563ca782cb625f3c8caaef7c671f93134dbe19c7ea800b1610a
aggregate_build_log_sha256=19ed557c3c5577237daf39ead20322c202aa6f89d1d7e75437218b98bcde5b71
artifact_modes=0555
```

## Bar 1 — identities, 285 functions, and frontier: PASS

Exact commands, once per immutable artifact:

```text
LC_ALL=C <artifact>/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > <result>/accepted.o 2> <result>/accepted.stderr
LC_ALL=C <artifact>/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > <result>/owner.tsv 2> <result>/owner.stderr
(cd <result> && LC_ALL=C /usr/bin/objdump -d accepted.o > accepted.objdump)
cmp -s <baseline>/accepted.o <aggregate>/accepted.o
cmp -s <baseline>/owner.tsv <aggregate>/owner.tsv
cmp -s <baseline>/accepted.objdump <aggregate>/accepted.objdump
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
is immutable reference only.

Its six frozen pointer-frontier rows were extracted from the retained
historical reference:

```text
frontier_reference=tmp/inbox170_o2_uq32_fixture_alignment/validation/fresh_full_report.log
frontier_reference_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
frontier_rows=tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/results/aggregate/frontier_reference_rows.txt
frontier_rows_count=6
frontier_rows_sha256=bc1b36bfc72d0d9430ba1d3c74035dc405218b19ec648c0413214aee6728b26b
```

Fresh dispatch/classifier source proofs show that the specialized route
precedes ordinary classification, while the four i128-return frontier rows
fail the ordinary `ret_bits == 128` admission and the two i64 frontier rows
fail its named-argument requirement before transaction creation. With exact
objects and 285 identical function disassemblies, the frontier is unchanged.
Proof hashes are retained in `frontier_provenance.sha256`.

## Bar 2 — full unit and standalone guard: PASS

Full unit:

```text
command=/home/oleg/bin/zig build test --summary all
result=7/7_steps,1399/1399_tests,pass
log=tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/logs/aggregate/full_unit.log
log_sha256=33ba9be2a6565b42eeac8b290931c6b8b5b8de7dd4bf77380f7f2353d22f84d3
```

Standalone source guard:

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig
result=63/63_tests,pass
log=tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/logs/aggregate/source_guard.log
log_sha256=d87cf7907afb37f9d9363399edb279d90884a3a518b855d90a24322fcae4944d
```

## Bar 3 — focused canaries: PASS

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all
result=2/2_steps,35/35_execution_cases,__multi3_green,fma_green,pass
log=tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/logs/aggregate/focused_canaries.log
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

## Bar 4 — standalone ABI: PASS

```text
command=/home/oleg/bin/zig build abi-differential --summary all
result=5/5_steps,60/60_cases,30/30_real_functions,pass
log=tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/logs/aggregate/abi_differential.log
log_sha256=5fd663144940c681ce5a845bc7bb93f5c4c6bb7a7f539d7022f0c9339158ae34
```

All commands, artifacts, outputs, temporary sources, patches, and logs are
covered by:

```text
manifest=tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/results/aggregate/complete_provenance.sha256
manifest_sha256=302ff79d115498a141aca94b71301170ad38cf3d4cb8e28cd985a87d8c4e134f
```

## Restoration and disposition

All five temporary consumer/guard/test files were restored with scoped
`git checkout -- <files>`. The complete retained patch applies cleanly to the
restored tree. The baseline and restored source manifests compare exactly.
Production/action/model/guard/tool/build/facade/bypass/retention/watcher
sources match the accepted dormant tree. The canonical bypass TSV remains
`2d6c8c88...`, the watcher Git blob remains `8f3be1dd...`, and `stash@{0}`
remains `7985c6d`.

No production wiring, ratchet credit, performance, integrated executable,
strengthened Tier 2, distribution-all, Tier 3, cleanup, deletion,
`clean_tmp`, or substitute-report command ran. No retained artifact was
removed or normalized.

Aggregate verdict:

```text
ordinary_gpr_pointer_direct_call=INDIVIDUALLY_ACCEPTED_AND_AGGREGATE_PASS
intByteSize=INDIVIDUALLY_ACCEPTED_AND_AGGREGATE_PASS
aggregate=PASS_ALL_FOUR_BLOCKING_BARS
production_wiring=NOT_AUTHORIZED
direct_credit=0
helper_collapse_credit=0
ratchet_before=131
ratchet_after=131
```

STOP for Watcher/Reviewer acceptance before production wiring or ratchet
credit.
