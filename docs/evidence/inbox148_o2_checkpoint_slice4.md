# INBOX-148 O2 checkpoint slice 4 — planning test split

Status: complete. The test-only structural change is commit
`3beffdfbc361c6e22258086e3d4a4fcb2a31c22c`, tree
`779772107f4c9ad8dbbdb000f6320f9a2db04786`. All acceptance commands
ran from that committed source tree. This follow-up changes only this
evidence summary.

```text
accepted_slice3_commit=be334bccc2980e124cc0b7c988c35f3cafa4ff57
accepted_slice3_tree=4f2a75d90d401ccd81639cca491adf0c6659a14e
authorization_commit=e43cfc65062912ee1823555fb48abbf2582acfcf
split_commit=3beffdfbc361c6e22258086e3d4a4fcb2a31c22c
split_tree=779772107f4c9ad8dbbdb000f6320f9a2db04786
ratchet=154
semantic_change=none
performance=omitted_by_complete_hash_proof
tier3=not_run
stash_at_0=untouched
stash_at_0_oid=7985c6d01040a6e47e4ce5b918866d0e89517ac7
```

## Stable entrypoint and exact test provenance

The build-visible entrypoint remains:

```text
src/codegen/x86_64/generic_cfg/composed_selector_value_use_transaction_tests.zig
```

`build.zig` still uses the unchanged `src/tests.zig` root. The entrypoint
replaces its two prior planning imports with the single stable
`value_use/planning_tests.zig` aggregator. The aggregator contains only
four `comptime` imports:

```text
planning_lifetime_admission_tests.zig
planning_compatibility_tests.zig
planning_physical_mapping_tests.zig
planning_semantic_ordering_tests.zig
```

The split follows checkpoint plan section 8:

```text
planning_lifetime_admission_tests.zig=2 tests,189 lines,sha256=0f25ede1a02cfad7672f5d0e848a466690295a8d811f7f7e9578f1aa05c7b974
planning_compatibility_tests.zig=1 test,119 lines,sha256=d6386c1ab027775d4fe865fdcb28be97e150645c3cd9c302fae56713188fa279
planning_physical_mapping_tests.zig=3 tests,227 lines,sha256=85fa07165b8af597ba1b472cfe1fbcc212a30934c5c1a86c653d0120c822d68c
planning_semantic_ordering_tests.zig=8 tests,538 lines,sha256=3d294e88c70408b2020f0a0af94a4fdf20b14721939a9d46f65f9be95cae2910
planning_tests.zig=6 lines,sha256=229b56c6acd3c7a1a8cb5321dd971d98cab08b34cf75593c8e1f3e000900aee0
root_test_aggregator=21 lines,sha256=8b909974711eb15db09cc4e2beca3a5adaf08dab0683f7c9af2d3390e769d01d
build_zig_sha256=7dc0609438a3b560ab0ee96cd2ec72329ba8327368cd8b177fb6a2f0fa6120a0
src_tests_zig_sha256=14b3abe011810946fb9c93685f41cd79d847c98d19d7f72cd442d4824049ea15
```

The Zig provenance verifier parses complete brace-balanced test blocks,
matches each old test by name to exactly one new leaf, rejects missing or
duplicate names, and compares every complete old/new body byte for byte.

```text
manifest=docs/evidence/inbox148_o2_checkpoint_slice4_test_manifest.tsv
manifest_rows=14_plus_header
manifest_sha256=61878f484aa308649c4927f69cba4ba8873c8770cffab99897419101d3997c4d
sorted_names=docs/evidence/inbox148_o2_checkpoint_slice4_test_names.txt
sorted_names_rows=14
sorted_names_sha256=85d127cc6f0815abb7edf425d944da512fa876a26ee69430751fb68fc5dfd11f
one_to_one=true
unique=true
body_hashes=14/14_exact
```

The sorted-name hash exactly matches checkpoint plan section 8. No test
is missing, duplicated, renamed, or semantically edited. No production
file changed, so no internal declaration was exported for testing.

## Complete performance-omission proof

The independent complete file-set/hash contract compares the accepted
Slice-3 evidence commit to the committed Slice-4 tree. It rejects an
addition, removal, or byte change in every covered class, including
untracked candidates.

```text
contract=docs/evidence/inbox148_o2_performance_omission_hash_contract.tsv
contract_rows=422_plus_header
contract_sha256=640650909afc020385e2456d1161c38e0be320b695568efa875f21b146f9803d
production=309/309_identical
tools=72/72_identical
build_configuration=1/1_identical
build_roots=37/37_identical
facades=3/3_identical
total=422/422_identical
```

The three separately classified facades are the public value-use facade,
the planning facade, and the scalar-arithmetic facade. The post-commit
verifier reproduced the tracked contract byte for byte. Performance is
therefore omitted under INBOX-148 requirement 5.

## Frozen identities

The fresh report retained expected selector exit status 1.

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=167/17/101
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
frontier_rows=composed-block-icmp-lhs-loc:6
```

## Acceptance gates

Every retained gate log is paired with its exact command.

### Test manifest

```text
command=/home/oleg/bin/zig run tmp/inbox148_o2_checkpoint_slice4/planning_test_manifest.zig -- tmp/inbox148_o2_checkpoint_slice4/baseline/core_planning_tests.zig tmp/inbox148_o2_checkpoint_slice4/baseline/planning_early_tests.zig src/codegen/x86_64/generic_cfg/value_use/planning_lifetime_admission_tests.zig src/codegen/x86_64/generic_cfg/value_use/planning_compatibility_tests.zig src/codegen/x86_64/generic_cfg/value_use/planning_physical_mapping_tests.zig src/codegen/x86_64/generic_cfg/value_use/planning_semantic_ordering_tests.zig tmp/inbox148_o2_checkpoint_slice4/validation/postcommit_test_manifest.tsv tmp/inbox148_o2_checkpoint_slice4/validation/postcommit_test_names.txt
result=14/14_exact,one_to_one=true,unique=true,sorted_name_hash_exact
log_sha256=a8ee2d5197a02f4daa5f803fd7b8d658da3271118df8eff39929b560f8bd1428
```

### Performance-omission hash contract

```text
command=/home/oleg/bin/zig run tmp/inbox148_o2_checkpoint_slice4/hash_contract.zig -- be334bcc tmp/inbox148_o2_checkpoint_slice4/validation/postcommit_hash_contract.tsv
result=422/422_identical
log_sha256=fdd307bcd5607d21b821155cb9ca3b4a1e746b3029525e4b78765ee33abd6a28
```

Both procedural programs are Zig; no Python program was used.

### Source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig
result=47/47
log_sha256=2aa27eab17e13f7745d1b538823fa8c7084c9a446e06461859d9950a0a43e8b8
```

### Full unit

```text
command=/home/oleg/bin/zig build test --summary all
result=7/7_steps,1329/1329_tests
log_sha256=d31fa2f178ea666a63064f8f1400b93598edf95ed0091aeb4988f7d59916a0e2
```

### Fresh whole-cohort report

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox148_o2_checkpoint_slice4/validation/fresh_full_report.log
result=expected_exit_1,443_selected,285_emitted,158_failed,first_fail=compiler_rt.trunc.truncl
log_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
```

### Accepted-cohort object

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox148_o2_checkpoint_slice4/validation/accepted.o 2> tmp/inbox148_o2_checkpoint_slice4/validation/accepted.stderr
result=285/285_accepted,object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
log_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

### Owner manifest

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox148_o2_checkpoint_slice4/validation/owner_manifest.tsv 2> tmp/inbox148_o2_checkpoint_slice4/validation/owner_manifest.stderr
result=285_rows,ledger=167/17/101,manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
log_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
stderr_log_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all
result=5/5_steps,60/60_cases,30/30_real_functions
log_sha256=aabd6cc08224fb5be2dbf2b82c20dd170c47264cbadc491e2eed5a93399f8223
```

### Focused codegen canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all
result=2/2_steps,2/2_canaries,35_execution_cases
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

### Standard integrated executable

```text
command=/home/oleg/bin/zig build distribution-zig-integrated-exe --summary all
result=2/2_steps,7/7_cases
log_sha256=0b9a00b84979e9e442c87470f353de361e92b336d3e447cbed35dc7ea1d89a92
```

### Strengthened Tier 2

```text
command=/home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all
result=29/29_steps,1337/1337_tests
log_sha256=173683e19b5a79a69f337df194df3eb6eae75a1a2baeeff1bfecdeaa8712af1a
```

No Tier 3 or `distribution-all` command was run.
