# INBOX-129 O2-R2 tests and source-guard split

Status: complete. The implementation, manifests, performance-omission
contract, and draft summary were frozen at commit
`255cae0f4cbd8fc493784191dd10449845ec00e5`, tree
`927235c366d4906c5af2067b8aa1a8e1b2c13e73`, before any acceptance
artifact was generated. This follow-up changes only the tracked summary.

Date: 2026-07-17

## Accepted baseline and scope

R2 starts from the accepted R1 production source commit
`80198d402f5ce0168b6b2db366d93e22c534e688`, tree
`376fe433fde1bc719bb8fa392734af6420006290`, plus its accepted evidence and
Supervisor documentation commits.

This slice changes test and source-guard organization only:

- no production source, tool, build configuration/root, or facade byte moves;
- no facade or internal production API widens;
- `PreparedView` is not exposed through the facade or a production consumer;
- the direct-materialization ratchet remains exactly 172;
- `stash@{0}` remains untouched;
- Tier 3 is not authorized and was not invoked.

The stable build-visible entrypoints remain:

```text
src/codegen/x86_64/generic_cfg/composed_selector_value_use_transaction_tests.zig
src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig
```

Both are thin `comptime` import aggregators, so they add no anonymous test and
retain the accepted 1278-test full-unit count.

## Transaction-test split and exact provenance

The accepted R1 file contains 128 pre-R1 semantic transaction tests and two
R1 architecture-proof tests. R2 keeps those populations distinct:

```text
semantic_manifest=docs/evidence/inbox129_o2_r2_transaction_test_manifest.tsv
semantic_rows=128_plus_header
semantic_manifest_sha256=3652c44e09d28035caea0957a8fc1cf0fa224fff701769a5e59c317117c0ac41
sorted_name_set=docs/evidence/inbox129_o2_r2_transaction_test_names.sorted
sorted_name_set_rows=128
sorted_name_set_sha256=c8042bd2869004e40d21fd273d6a7f3cfc3eefb2512fd2af87958761eb93de3f
r1_proof_manifest=docs/evidence/inbox129_o2_r2_r1_proof_test_manifest.tsv
r1_proof_rows=2_plus_header
r1_proof_manifest_sha256=b0cf0b3a97022549837cc6146772cfd3d822a2b306e851f8e5d1a478cc7ed83a
```

The procedural comparison command is:

```text
python3 tmp/inbox129_validate_manifests.py
```

It proves:

```text
transaction_semantic_tests=128 exact_order=true unique=true body_hashes=true
transaction_r1_proof_tests=2 exact_order=true unique=true body_hashes=true
```

Every row records the accepted ordinal/name/line, semantic owner, destination
file, and exact test-block SHA-256. Concatenating the leaf modules in
aggregator import order reproduces all 130 accepted-R1 names in exact order.
The 128-row sorted name set is identical and duplicate-free.

Test-only shared setup is in `value_use/test_support.zig`. Its technically
public declarations are confined to the test import graph; production still
imports only the frozen facade. Semantic ownership is split across:

```text
core: contract, owned-label, and R1 architecture proofs
core/planning: cross-module lifecycle and rollback behavior
planning: early/prefix-closed planning
materialization: supported, prepared, and capability tests
composition: subordinate accumulator lifecycle
actions/address_memory: store, GEP, and load groups
actions/control_compare: branch/switch, scratch, eq-zero, setcc, sign-bit, i128
actions/calls: inline memcpy and failure provenance
```

No generated transaction-test leaf exceeds 862 lines; the shared test support
is 848 lines. The former 7,826-line entrypoint is 21 lines.

## Source-guard split and exact policy provenance

The former 4,775-line guard is split by concern:

```text
source_guard/model.zig                 473 lines
source_guard/core.zig                  234 lines
source_guard/residual_policy.zig       416 lines
source_guard/authority_policy.zig      819 lines
source_guard/consumer_policy.zig      1297 lines
source_guard/split_policy.zig          370 lines
source_guard/test_support.zig          106 lines
```

Negative/positive fixtures are separately grouped as residual-structural,
dependency/value-use-authority, consumer-action, compare-action, and
tree/split tests. The stable guard aggregator is seven lines. No guard
implementation or fixture leaf exceeds 1,297 lines.

```text
guard_manifest=docs/evidence/inbox129_o2_r2_guard_policy_manifest.tsv
guard_rows=34_plus_header
guard_manifest_sha256=58686f06f73a1efd1acf75e6aae00e83777a6eacd708738d0e5dc8c6147315ab
```

For each accepted policy test, the manifest records exact ordinal/name/line,
concern, policy entrypoint(s), new policy source file(s), normalized policy
declaration SHA-256, fixture provenance, new fixture file, and exact fixture
block SHA-256. The same procedural comparison proves:

```text
guard_policy_tests=34 exact_order=true unique=true fixture_hashes=true policy_hashes=true
```

The project guard still rejects additions, removals, relocations,
reclassifications, authority escapes, unreviewed consumer action wiring,
facade widening, internal production imports, runtime dispatch, extra generic
instantiations, reverse leaf dependencies, and the control-compare production
line-budget violation.

## Performance-omission contract

The complete tracked byte comparison is:

```text
contract=docs/evidence/inbox129_o2_r2_r1_hash_contract.tsv
contract_rows=412_plus_header
contract_sha256=088cd0358ea6a685c675e37bd1b4c761e30fae4264418f533d5af384f3e51bda
accepted_r1_commit=80198d402f5ce0168b6b2db366d93e22c534e688
production=301/301_identical
tools=72/72_identical
build_configuration=1/1_identical
build_roots=37/37_identical
facade=1/1_identical
total=412/412_identical
```

Generation/verification command:

```text
python3 tmp/inbox129_hash_contract.py
```

The script compares SHA-256 over file bytes, rejects class file-set additions
or removals, includes untracked candidates in the current file-set check, and
fails on any non-identical row. New files are confined to the test/guard and
evidence populations. Therefore R2 satisfies the Reviewer’s exact condition
for omitting the counterbalanced performance run.

## Acceptance validation

Every acceptance command below ran only after commit `255cae0f` was frozen.

### Mechanical provenance and R1 byte contract

```text
command=python3 tmp/inbox129_validate_manifests.py > tmp/inbox129_o2_r2/validation/manifest_validation.log 2>&1
result=128_semantic_tests_exact+2_r1_proofs_exact+34_guard_policies_exact
log_sha256=5347336fe732732c7c07684adf4c0259002a4fa63842404670e52baa147af3ad

command=python3 tmp/inbox129_hash_contract.py > tmp/inbox129_o2_r2/validation/r1_hash_contract.log 2>&1
result=412_rows/5_classes/all_identical
log_sha256=308d6dbb07a36ae31299f654f7b1933e9a2079b8cd7a218e3bf65b1fa1e27cbb
```

The post-commit hash-contract run reproduced the committed TSV byte for byte.
Performance is therefore omitted under the accepted Reviewer rule.

### Source guard and full unit suite

```text
command=zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox129_o2_r2/validation/source_guard.log 2>&1
result=34/34
log_sha256=0a6081972722a903875d745d1fe497a665c7621d7c7aeb4b73b9281685a7bf29

command=zig build test --summary all > tmp/inbox129_o2_r2/validation/full_unit.log 2>&1
result=7/7_steps,1278/1278_tests
log_sha256=179a9e357b04c944fe96643ef1c47bad45232cc1dc21aa582fd6489494780c32
```

The accepted full-unit count is unchanged.

### Frozen report, object, and owner identities

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox129_o2_r2/validation/fresh_full_report.log
expected_exit_status=1
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi

command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox129_o2_r2/validation/accepted.o 2> tmp/inbox129_o2_r2/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_bytes=0

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox129_o2_r2/validation/owner_manifest.tsv 2> tmp/inbox129_o2_r2/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=167/17/101
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
stderr_bytes=0
```

No report row, object byte, owner, counter, or target frontier moved. The
direct-materialization ratchet remains 172.

### ABI, focused canaries, integrated executable, and Tier 2

```text
command=zig build abi-differential --summary all > tmp/inbox129_o2_r2/validation/abi_differential.log 2>&1
result=60/60_cases+30/30_real_functions
log_sha256=139beff480d39d182360446442b1f3171a42cae38a733c952daca6a87c6a882e

command=zig build focused-codegen-canaries --summary all > tmp/inbox129_o2_r2/validation/focused_canaries.log 2>&1
result=fma+__multi3/35_execution_cases/local_fail=0
log_sha256=2bf6f68ae7cec068253218a52e4d89d17d0b193396c31e3bca2feb72744e40f8

command=zig build distribution-zig-integrated-exe --summary all > tmp/inbox129_o2_r2/validation/integrated_exe.log 2>&1
result=7/7
log_sha256=cb1541032237fc55394ab3fd02285b62125044dfcdac27f5b76ee8cb50f64fcd

command=zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all > tmp/inbox129_o2_r2/validation/strengthened_tier2.log 2>&1
result=29/29_steps,1286/1286_tests
log_sha256=b83467edcf591d46844632b7b243c0f183396a32ea7164e885d2bbcfe3cb7857
```

No Tier 3 command was run. `stash@{0}` remained untouched throughout R2.
