# INBOX-179 — ordinary direct-call re-isolation

Status: **ALL FOUR BLOCKING BARS PASS.** The admitted ordinary GPR/pointer
direct-call family is byte-identical under the accepted dormant
`DirectCallAction` contract. This is isolation evidence only: production
routing is restored to the accepted dormant tree, no ratchet credit is
claimed, and `zig.target.intByteSize` plus every other call family remain
unisolated and legacy-owned. The O2 bypass ratchet remains **131**.

## Frozen basis

```text
composite_operating_head=ed327bf257d196af8eaf2234da68a3f78482256b
accepted_dormant_implementation=c0f43aea3e9edde4dd16c548067d86aee7520fb6
accepted_dormant_tree=4da207e66f407e0ab0f6575ea0aa4b7c9324a4a1
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
tmp/inbox179_o2_ordinary_call_reisolation/results/baseline/source_hashes.sha256
tmp/inbox179_o2_ordinary_call_reisolation/results/ordinary/restored_source_hashes.sha256
```

## Fresh temporary patch

The stale INBOX-175 patch was inspected only as historical evidence and was
not applied. A new patch was generated from the accepted tree. It touches
only `composed_selector_calls.zig`, adding 103 lines:

```text
patch=tmp/inbox179_o2_ordinary_call_reisolation/patches/ordinary.patch
patch_sha256=4632e70cea5700413c15b458a10a0058234cd7d3d1b41d9770210e14e48ae21b
temporary_calls_sha256=6b07b0bb7bc346610ce25737ce8478b082af839714d2fc7eff4ba079eaa6dbe8
temporary_guard_sha256=f7076f86ee49705daf25bb762f1f244728e1c0a1bedb850494ee704ec33ac3d9
post_restore_git_apply_check=pass
```

The temporary pure classifier runs only after every existing intrinsic,
indirect-call, call-form, scalar-SSE, envelope, signature, and return-width
decision. It admits only named i32/i64/pointer operands, at most six ABI
slots, non-tail calls, and void/i32/i64/pointer results. All other forms
remain on the exact legacy path before transaction creation.

The temporary consumer performs exactly:

```text
register every operand in source order
attach exactly one copied DirectCallAction while registering
seal
prepare
materializeAll
commit
```

It performs no home/liveness query, attempt-then-fallback, action/model/Q1
change, import/facade widening, or diagnostic normalization. The accepted
function/API-scoped guard already conditionally validates this exact wiring
shape and provenance mapper; therefore the smallest patch needed no guard
edit.

Immutable artifacts were built before and after temporary wiring:

```text
command=/home/oleg/bin/zig build --summary all
baseline_artifact=tmp/inbox179_o2_ordinary_call_reisolation/artifacts/baseline/z_llvm
baseline_artifact_sha256=0964924e37908ab81f838ce9a2b99c5328aa8f45f86a9750e0e179973354cbf3
baseline_build_log_sha256=1f67977ce5e27ce62b752ef0dbddf817921b3f31d95e78fb928a799528ca58db
ordinary_artifact=tmp/inbox179_o2_ordinary_call_reisolation/artifacts/ordinary/z_llvm
ordinary_artifact_sha256=a021667eddb177a7a80750b46ef3c104190083ad0bb2528fcffbbb19486c9ee3
ordinary_build_log_sha256=93eafdb6371eb1a36b4c54ee9ec2152fff78a123a4fbe8c02a389ad3e6cbd82c
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
baseline_vs_ordinary_object_cmp=identical
baseline_vs_ordinary_owner_cmp=identical
```

Complete function bytes and disassembly were compared with:

```text
(cd <result> && LC_ALL=C objdump -d accepted.o > accepted.objdump)
cmp -s <baseline>/accepted.objdump <ordinary>/accepted.objdump
rg -c '^[0-9a-f]+ <[^>]+>:$' <result>/accepted.objdump
```

Result:

```text
per_function=285 compared / 0 divergent / 0 missing
baseline_disassembly_sha256=43663485089e1d1ef3f7cd7195c747e23e44366e700b733294fe14ad7bafa919
ordinary_disassembly_sha256=43663485089e1d1ef3f7cd7195c747e23e44366e700b733294fe14ad7bafa919
first_semantic_instruction_divergence=none
downstream_branch_offset_divergence=none
```

The canonical 443-row source remains absent, so no fresh or substitute report
was attempted or claimed. Historical report
`49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`
is reference-only. Its six frozen pointer-frontier rows were extracted
without regeneration:

```text
frontier_reference=tmp/inbox170_o2_uq32_fixture_alignment/validation/fresh_full_report.log
frontier_reference_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
frontier_rows=tmp/inbox179_o2_ordinary_call_reisolation/results/ordinary/frontier_reference_rows.txt
frontier_rows_count=6
frontier_rows_sha256=bc1b36bfc72d0d9430ba1d3c74035dc405218b19ec648c0413214aee6728b26b
```

Fresh source proof confirms their routing cannot move: the four i128-return
rows fail the classifier's `ret_bits == 128` exclusion, and the two i64
rows' null-pointer arguments fail `arg.value != .named` before transaction
creation. The captured classifier proof SHA-256 is
`7fc2986adcf0a3b355918747e6135a403a51c479fdab84215a922cd1d18ccc05`.
Thus the diagnostics remain the historical frozen rows without pretending a
fresh report was possible.

The first combined selector command returned status 1 only after all four
fresh selector outputs were complete and exact: an evidence-only owner-count
regex expected an obsolete `owner=` field. The current manifest is a
two-column TSV. Corrected post-processing counted 40/127/17/101 without
rerunning either selector artifact.

## Bar 2 — full unit and standalone guard: PASS

Full unit:

```text
command=/home/oleg/bin/zig build test --summary all
result=7/7_steps,1398/1398_tests,pass
log=tmp/inbox179_o2_ordinary_call_reisolation/logs/ordinary/full_unit.log
log_sha256=9e06f32ad7e901098ca7deb227013e1a323f8613a497f30dd9440c03f65c0403
```

Standalone source guard:

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig
result=62/62_tests,pass
log=tmp/inbox179_o2_ordinary_call_reisolation/logs/ordinary/source_guard.log
log_sha256=9aaf7c9a3fa9dde6476a2401d1b0b2b32961d0245dd8cc64ba3997f9a6954692
```

## Bar 3 — focused canaries: PASS

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all
result=2/2_steps,35/35_execution_cases,__multi3_green,fma_green,pass
log=tmp/inbox179_o2_ordinary_call_reisolation/logs/ordinary/focused_canaries.log
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

## Bar 4 — standalone ABI: PASS

```text
command=/home/oleg/bin/zig build abi-differential --summary all
result=5/5_steps,60/60_cases,30/30_real_functions,pass
log=tmp/inbox179_o2_ordinary_call_reisolation/logs/ordinary/abi_differential.log
log_sha256=824e8dd6581ef8797fb71bfc43f3507003ee073e2386c1830f067f46f8baa873
```

## Restoration and disposition

The sole temporary consumer file was restored with scoped
`git checkout -- <file>`. The retained patch applies cleanly to the restored
tree, and the production/action/model/guard/tool/build/facade/bypass/
retention/watcher diff against `c0f43aea` is empty. `stash@{0}` remains
`7985c6d`.

No `intByteSize` or aggregate isolation, production wiring, ratchet credit,
performance, integrated executable, strengthened Tier 2, distribution-all,
Tier 3, cleanup, deletion, or `clean_tmp` command was run. No retained
artifact was removed.

Isolation verdict:

```text
ordinary_gpr_pointer_direct_call=PASS_ALL_BARS
intByteSize=NOT_RUN
aggregate=NOT_RUN
production_wiring=NOT_AUTHORIZED
ratchet_before=131
ratchet_after=131
```

STOP for Watcher/Reviewer review before any next family or wiring.
