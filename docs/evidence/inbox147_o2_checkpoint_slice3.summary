# INBOX-147 O2 checkpoint slice 3 — scalar test split

Status: complete. The test-only structural change is commit
`b7b176ed3b82dd628277798b2db999cecf2e91d1`, tree
`9b2f6bdad850c85dbbfc49d533cde9ee0bafbba9`. Acceptance commands ran
from tracked head `9c74cd5f7083fa1a1e5dd8fc3ac7921fcb76a890`, whose only intervening
change is the Supervisor-owned `docs/next_steps.md` verification record.
This follow-up changes only this evidence summary.

```text
accepted_slice2_commit=ff4dc23d609b69fda650a2659109f8dc737a4e0e
accepted_slice2_tree=38d5180c4246252da47840a4e83d973e83912c2e
split_commit=b7b176ed3b82dd628277798b2db999cecf2e91d1
split_tree=9b2f6bdad850c85dbbfc49d533cde9ee0bafbba9
tested_commit=9c74cd5f7083fa1a1e5dd8fc3ac7921fcb76a890
tested_tree=827ff1f0b989ea0eb2d9f1f1261858a653db2cf0
ratchet=154
semantic_change=none
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
replaces its two prior scalar imports with the single stable
`value_use/actions/scalar_arithmetic_tests.zig` aggregator. That aggregator
contains only two `comptime` imports:

```text
scalar_cast_tests.zig
scalar_immediate_tests.zig
```

The two leaves are 100%-similar Git renames and are byte-for-byte equal to
their accepted Slice-2 sources.

```text
file=src/codegen/x86_64/generic_cfg/value_use/actions/scalar_arithmetic_tests.zig lines=4 bytes=102 sha256=00075c74bac51d2d78b74cbce5edd26a3428b571cad56a836c03019df15ca8cc
file=src/codegen/x86_64/generic_cfg/value_use/actions/scalar_cast_tests.zig lines=854 bytes=34364 sha256=f111dcf1f9d9a556f850e4a3fa45cbc6730f5fbb158493e018239b23c2ee05f5
file=src/codegen/x86_64/generic_cfg/value_use/actions/scalar_immediate_tests.zig lines=1250 bytes=53622 sha256=aa7d9a3c722aa6cf7d13393469e96ef8ac8cad39cdb774dc809a7eb93ca06df7
file=src/codegen/x86_64/generic_cfg/composed_selector_value_use_transaction_tests.zig lines=22 bytes=1305 sha256=1cf8a37bd6785296f5281f280e375cb21e97418ea82491aa1e60eaebe31a4c7c
build_zig_sha256=7dc0609438a3b560ab0ee96cd2ec72329ba8327368cd8b177fb6a2f0fa6120a0
src_tests_zig_sha256=14b3abe011810946fb9c93685f41cd79d847c98d19d7f72cd442d4824049ea15
```

The Zig provenance verifier parses complete brace-balanced test blocks,
rejects duplicate or reordered names, and compares every old/new block
byte for byte.

```text
manifest=docs/evidence/inbox147_o2_scalar_test_manifest.tsv
manifest_rows=33_plus_header
manifest_sha256=85eee180d0e27be0ddc6da0547a19f12f3c77fb7beca35a00a87013b4742a6fb
sorted_names=docs/evidence/inbox147_o2_scalar_test_names.sorted
sorted_names_rows=33
sorted_names_sha256=ca5ccf5816f893fbdbf2875f5522d6b4f69e49f7bcfdfaf4985e8d5c6e976d0c
exact_order=true
unique=true
body_hashes=33/33_exact
```

The sorted-name hash exactly matches plan section 7. No test is missing,
duplicated, renamed, reordered, or semantically edited. Production files
are byte-identical, so no private implementation was exported for test
access.

## Complete performance-omission proof

The complete file-set/hash contract compares the accepted Slice-2 commit
to the committed Slice-3 tree. It rejects additions, removals, or byte
changes in every covered class, including untracked candidates.

```text
contract=docs/evidence/inbox147_o2_performance_omission_hash_contract.tsv
contract_rows=422_plus_header
contract_sha256=640650909afc020385e2456d1161c38e0be320b695568efa875f21b146f9803d
production=309/309_identical
tools=72/72_identical
build_configuration=1/1_identical
build_roots=37/37_identical
facades=3/3_identical
total=422/422_identical
```

The three separately classified production facades are the public value-use
facade, the reviewed planning facade, and the scalar-arithmetic facade.
The post-commit verifier reproduced the tracked contract byte for byte.
Performance is therefore omitted under INBOX-147 requirement 6.

## Frozen identities

The report retained expected selector status 1.

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

### Test manifest and hash contract

```text
command=/home/oleg/bin/zig run tmp/inbox147_o2_checkpoint_slice3/test_manifest.zig -- tmp/inbox147_o2_checkpoint_slice3/baseline/scalar_arithmetic_cast_tests.zig tmp/inbox147_o2_checkpoint_slice3/baseline/scalar_arithmetic_immediate_tests.zig src/codegen/x86_64/generic_cfg/value_use/actions/scalar_cast_tests.zig src/codegen/x86_64/generic_cfg/value_use/actions/scalar_immediate_tests.zig tmp/inbox147_o2_checkpoint_slice3/validation/postcommit_scalar_test_manifest.tsv tmp/inbox147_o2_checkpoint_slice3/validation/postcommit_scalar_test_names.sorted
result=33/33_exact,unique=true,sorted_name_hash_exact
log_sha256=0bf99ebde8450f8b00092fe8e4a0949b3137b8e0e65125616977c225239521fc

command=/home/oleg/bin/zig run tmp/inbox147_o2_checkpoint_slice3/hash_contract.zig -- ff4dc23d609b69fda650a2659109f8dc737a4e0e tmp/inbox147_o2_checkpoint_slice3/validation/postcommit_hash_contract.tsv
result=422/422_identical
log_sha256=fdd307bcd5607d21b821155cb9ca3b4a1e746b3029525e4b78765ee33abd6a28
```

Both procedural programs are Zig; no Python program was used.

### Source guard and full unit

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig
result=47/47
log_sha256=2aa27eab17e13f7745d1b538823fa8c7084c9a446e06461859d9950a0a43e8b8

command=/home/oleg/bin/zig build test --summary all
result=7/7_steps,1329/1329_tests
log_sha256=fd962b43e05150e94a1b937dda307c9cc8851089084edbfc50d7756f0742cf1e
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all
result=60/60_cases,30/30_real_functions
log_sha256=312d97ba1c92723842200c3d53795394226845152b85c9a04c805ef3d788e032
```

### Focused canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all
result=2/2_canaries,35_execution_cases
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

### Integrated executable

```text
command=/home/oleg/bin/zig build distribution-zig-integrated-exe --summary all
result=7/7
log_sha256=0b9a00b84979e9e442c87470f353de361e92b336d3e447cbed35dc7ea1d89a92
```

### Strengthened Tier 2

```text
command=/home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all
result=29/29_steps,1337/1337_tests
log_sha256=875bb19de693f9e1d5779e4af44ee5203d917267f4ca2835805d3475968544c0
```

No Tier 3 or `distribution-all` command was run.
