# INBOX-175 — call-family isolation stop

Status: **STOPPED on the ordinary-family full-unit bar.** The ordinary-only
temporary build passed the complete cohort/object/owner/per-function bar
byte-for-byte, then failed the required full unit suite at `1386/1389`.
Per the no-fix-forward rule, `zig.target.intByteSize`, the aggregate, and
focused canaries were not run. No family is accepted by this incomplete
matrix, no production wiring or credit is claimed, and the O2 bypass ratchet
remains **131**.

## Frozen basis

```text
operating_docs_commit=1169a383911aa21b1174e2f5b48bca70a538c8e4
amended_source_baseline=c1ffd1cc0940b8dd1354c14f3bb7ca53c4709532
amended_source_tree=e2f83da62a261381db314c6d02b6945600a4e868
current_docs_tree=bb74d927e5fdcc6be6028ecf64df4654cf778206
source_state_beneath_docs_commit=byte-identical to c1ffd1cc
stash_at_0=INBOX-93 preserve B2B wiring plus five diagnosis tests (untouched)
```

The frozen production source hashes were:

```text
composed_selector_calls.zig=f1046632d670d61439df7252ba12a1ea474829a4b479ed7758ea4e223866cf2d
source_guard/consumer_policy.zig=3085a1963faccc6e3d3453fffc6369e6f3936e38738d2a70a8685946f098683e
value_use/actions/calls.zig=90990dd80a6f31c085a7b09e286e8b52674fcf03f29be492c661239a8483cb4c
value_use/model.zig=50f0596186c4deec9fbcd89e52beb45b32567f1c175467bbd42759f43e9dbd7c
source_hash_manifest=f1f24cad91f85cb13ea594e26fe1509685fdffe704f758a4aaccaf437cbf263f
```

The baseline artifact was built before temporary wiring:

```text
command=/home/oleg/bin/zig build --summary all
artifact=tmp/inbox175_o2_call_isolation/artifacts/baseline/z_llvm
artifact_sha256=7b50ea3cc7c8afa26b3f455912aa44f23b575e57681f406e98a1c7ac22fea6fe
build_log=tmp/inbox175_o2_call_isolation/logs/baseline/build.log
build_log_sha256=c07882100de5c3398f8859a3308ca0172bb4173d7b02cf2e298b239ae4ca4517
artifact_mode=0555
```

Baseline decisive artifacts:

```text
command=LC_ALL=C <baseline>/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll >/dev/null 2>report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report_summary=443 selected / 285 emitted / 158 failed / compiler_rt.trunc.truncl first

command=LC_ALL=C <baseline>/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll >accepted.o 2>accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
accepted_stderr_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

command=LC_ALL=C <baseline>/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll >owner.tsv 2>owner.stderr
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_breakdown=composed_block:40 / composed_cfg:127 / legacy_envelope:17 / structural_fallback:101
owner_ledger=167 composed / 17 legacy / 101 structural
owner_stderr_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

## Ordinary-only temporary build

The temporary patch touched only:

```text
src/codegen/x86_64/generic_cfg/composed_selector_calls.zig
src/codegen/x86_64/generic_cfg/source_guard/consumer_policy.zig
```

It added the ordinary semantic classifier/consumer wiring and the associated
function-scoped temporary guard accounting. It did not touch the action,
model, planning, lifetime/Q1, materialization, facade, bypass TSV, dormant
tests, or any capability surface.

```text
patch=tmp/inbox175_o2_call_isolation/patches/ordinary.patch
patch_sha256=b337761f6944b689b631a13dc60c8ba58e5226ee623a655329aff1d9205b3834
git_apply_check_after_restore=pass
temporary_calls_source_sha256=9f0c12fd613947d39a494ddd64e36d93f295910679d4b639b7229a8ddb9ee99f
temporary_guard_source_sha256=4fd0e926aae7458ddcdc9da451f003431f45b7617a688b940bf48e04e260a55b
```

Temporary artifact provenance:

```text
command=/home/oleg/bin/zig build --summary all
artifact=tmp/inbox175_o2_call_isolation/artifacts/ordinary/z_llvm
artifact_sha256=7fae3f980dc50e62bd2415a1f0a043aa6f57216e9cacb783c74e3cd5a31490fc
build_log=tmp/inbox175_o2_call_isolation/logs/ordinary_build.log
build_log_sha256=418515512c088a75ee5e1c5b28e38200149f52a4855bc4a6611b5c5af3dc5979
artifact_mode=0555
```

### Bar 1 — complete cohort identity: PASS

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report_cmp_baseline=identical
report_summary=443/285/158, compiler_rt.trunc.truncl first
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
accepted_object_cmp_baseline=identical
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_cmp_baseline=identical
owner_breakdown=composed_block:40 / composed_cfg:127 / legacy_envelope:17 / structural_fallback:101
owner_ledger=167/17/101
```

Per-function comparison:

```text
command=/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- <baseline>/accepted.o <ordinary>/accepted.o >function_diff.tsv
comparison_tool_sha256=34b5d400b47a9e861e5f6e7082f54ad57d6bc9b3e5e772d60420074b4dd4ce8f
function_diff_sha256=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
result=compared 285 / divergent 0 / missing 0
first_semantic_instruction_divergence=none
```

All six pointer-frontier report rows remained byte-identical:

```text
compiler_rt.udivmod.__udivmodti4  composed-block-call-ptr-arg
compiler_rt.udivmod.__divti3      composed-block-call-unknown-ptr-arg
compiler_rt.udivmod.__udivti3     composed-block-call-unknown-ptr-arg
compiler_rt.int.__divmodti4       composed-block-call-unknown-ptr-arg
compiler_rt.int.__divdi3          composed-block-call-unknown-ptr-arg
compiler_rt.int.__divmoddi4       composed-block-call-unknown-ptr-arg
```

### Bar 2 — full unit 1389/1389 with source guard 60/60: FAIL

```text
command=/home/oleg/bin/zig build test --summary all
log=tmp/inbox175_o2_call_isolation/logs/ordinary/full_unit.log
log_sha256=6f2f925521ac71778b58bbfb49e7311765a923cf7576425a512282e35c0ba7e5
result=1386 pass / 3 fail / 1389 total
source_guard_60_of_60=not achieved
```

The three failures retained verbatim in the log are:

1. `composed selector stages a dead accumulator argument before dropping its binding`
   — the transactional path returned a diagnostic where the accepted legacy
   path succeeds. The observable failure occurs after transaction admission
   on the dies-at-current accumulator-argument shape; no instrumentation or
   fix-forward was added after the bar failed.
2. `composed selector source guard confines failure provenance to the memcpy mapper`
   — the temporary provenance-accounting validator rejected the retained
   focused fixture.
3. `composed selector source guard accepts the fully classified current tree`
   — the temporary call-action accounting rejected the complete source tree.

This is a failing established bar, not an accepted partial result. The
ordinary family is therefore retained wholesale for this review point.

### Bar 3 — focused canaries 35: NOT RUN

The directive requires an immediate stop after a failed bar. Focused canaries
were not run. No standalone ABI or source-guard command was run; the output
visible in the failed full-unit log is only the normal transitive work of the
authorized `zig build test` command.

## Unrun builds and disposition

```text
ordinary_only=RETAIN WHOLESALE (full-unit bar failed)
intByteSize_only=NOT RUN
aggregate=NOT RUN
minimal_interaction_isolation=NOT APPLICABLE
ratchet_before=131
ratchet_after=131
direct_credit=0
helper_collapse_credit=0
```

Because the ordinary family did not clear all three bars, no conclusion is
drawn about `intByteSize` or aggregate compatibility. No production wiring,
isolation credit, guard-policy relaxation, or action/model amendment is
included in this evidence commit.

## Cleanup and prohibited-work record

The temporary consumer and guard-accounting changes were removed with scoped
`git checkout -- <files>`. Their restored hashes are exactly:

```text
composed_selector_calls.zig=f1046632d670d61439df7252ba12a1ea474829a4b479ed7758ea4e223866cf2d
source_guard/consumer_policy.zig=3085a1963faccc6e3d3453fffc6369e6f3936e38738d2a70a8685946f098683e
git_diff_c1ffd1cc_src_tools_build=empty
stash_at_0=unchanged
```

No performance, standalone ABI, standalone source guard, integrated-exe,
strengthened Tier 2, distribution-all, or Tier 3 command was run. The tracked
change for INBOX-175 is this evidence file only. STOP for Watcher/Reviewer
review; production wiring is not started.
