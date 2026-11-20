# INBOX-132 — dormant scalar-cast placement

Status: complete; stopped for Supervisor/Reviewer review. This slice is a
mechanical placement only. The dormant cast action implementations and their
co-located tests moved from `actions/control_compare.zig` to
`actions/scalar_arithmetic.zig`; no production lowering or dispatch was
wired.

## Frozen basis and tested state

```text
accepted_cast_action_commit=211efdcc
supervisor_dispatch_head=5bca9d0b
tested_implementation_index_tree=a2bb7f2280c278645fa52dcb9e641e1b4fe11922
production_wiring=none
ratchet=172
performance_run=none
tier3=not_run
stash_at_0=untouched
stash_at_0_oid=7985c6d01040a6e47e4ce5b918866d0e89517ac7
```

The new scalar-arithmetic leaf is 373 lines. The remaining control/compare
leaf is 1,409 lines. Both are below their 2,000-line hard ceilings. Within
the value-use graph, the scalar leaf imports `model` and `composition` only;
it has no `core`, `planning`, action-leaf, or `Authority.planning`
dependency. Semantic payloads remain in `value_use/model.zig`.

Core remains the sole exhaustive action dispatcher. Its three cast
registration and execution cases now name the scalar leaf in their original
positions. The transaction facade wrappers forward the three pure
classifiers to the relocated implementation without changing their
signatures or the facade surface.

## Mechanical move provenance

The machine-readable proof is
`docs/evidence/inbox132_o2_scalar_cast_placement_provenance.tsv`.

```text
command=python3 tmp/inbox132_o2_scalar_cast_placement/generate_provenance.py
frozen_action_blob=src/codegen/x86_64/generic_cfg/value_use/actions/control_compare.zig
frozen_action_blob_sha256=6bfc78507d401484067b20eff15c374fd5f8d7723378b7925838ff5886db2cfb
frozen_test_blob=src/codegen/x86_64/generic_cfg/value_use/actions/control_compare_scalar_cast_tests.zig
frozen_test_blob_sha256=733a1600237890e11103965ae98ebc71347398da7cdc279db495b0d82a9eb0d7
action_declarations=18
test_helper_declarations=5
test_declarations=12
exact_block_matches=35/35
provenance_manifest_sha256=75f440f7a1db3245b97ac52a5b966d2ae2819dccb396d9cbc6f935f597da8b45
```

Every moved function and test block was parsed from the frozen `211efdcc`
blob. Each old/new body and signature hash is identical. The complete
645-line test module is also byte-identical:

```text
old_test_blob_sha256=733a1600237890e11103965ae98ebc71347398da7cdc279db495b0d82a9eb0d7
new_test_file_sha256=733a1600237890e11103965ae98ebc71347398da7cdc279db495b0d82a9eb0d7
```

## Frozen contracts

The verification normalizes only the required owner qualifier
(`scalar_arithmetic` back to `control_compare`) and removes the new core
import/implementation alias. After that mechanical normalization, the
complete model and core files equal their accepted `211efdcc` blobs.
Therefore semantic payloads, action/use tags, error surfaces, facade
signatures, registration order, and exhaustive dispatch order are exact.

```text
command=python3 tmp/inbox132_o2_scalar_cast_placement/verify_contracts.py | tee tmp/inbox132_o2_scalar_cast_placement/validation/contract_verification.log
normalized_model_sha256=525fede838154d0bdd8d7f0c31b0c7141ce805ae502d7b1a066861e0dfc97707
frozen_model_sha256=525fede838154d0bdd8d7f0c31b0c7141ce805ae502d7b1a066861e0dfc97707
normalized_core_sha256=d0deb90f8e56de92717ab84d625c5e012b97ffc758b76d70c2e0d9c8045ee5b2
frozen_core_sha256=d0deb90f8e56de92717ab84d625c5e012b97ffc758b76d70c2e0d9c8045ee5b2
facade_manifest_sha256=51527db981eb4da7844856a21e6000fd35caa693b5176685bc40e6a278fe0b1b
contract_log_sha256=4f5f7dae7b1002f797e8473d5258579dc627230675bfdc7a3f985964606f1ae5
```

The split guard now:

- classifies the scalar-arithmetic leaf and enforces its exact eight-name
  technically-public budget;
- rejects reverse `core`, `planning`, sibling-action, and
  `Authority.planning` dependencies;
- rejects growth beyond 2,000 lines;
- retains the existing facade-only production import rule.

Focused negatives cover reverse imports, planning authority access,
line-budget growth, and public-name-budget drift.

## Dormancy and ratchet

The only changed `composed_selector*.zig` path relative to `211efdcc` is
the transaction test aggregator import. Production lowerers are unchanged.

```text
production_lowering_diff=none
composed_selector_scalar_sha256=971533d068ae1c9767c2f1049076e8d9f8541d961cb61220a3305b1285654104
baseline_composed_selector_scalar_sha256=971533d068ae1c9767c2f1049076e8d9f8541d961cb61220a3305b1285654104
composed_selector_impl_sha256=630e58e31798fdd6fc27859aeaba19724a9919d10909862997d7be3a8cbc0dae
baseline_composed_selector_impl_sha256=630e58e31798fdd6fc27859aeaba19724a9919d10909862997d7be3a8cbc0dae
bypass_inventory=docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv
bypass_inventory_sha256=6e570be808d2aea9275809471f53846af7f54afdd908ab73e51218579ca8112d
bypass_occurrences=172
```

No bypass row, ownership classification, production diagnostic, or frontier
row changed.

## Immutable validation

Every retained gate log is paired with its exact command.

### Focused source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig > tmp/inbox132_o2_scalar_cast_placement/validation/source_guard.log 2>&1
result=36/36
log_sha256=57bf111090020783465778a22207a67d4097db67fc65aaf1a3fb9d2598b1f035
```

### Full unit gate

```text
command=/home/oleg/bin/zig build test --summary all > tmp/inbox132_o2_scalar_cast_placement/validation/full_unit.log 2>&1
result=7/7_steps,1292/1292_tests
log_sha256=b9d51359aaaf094f106c830d9c8b004969e54983b184967af0338ce7bfafd48f
```

### Required plain-path ABI differential

```text
command=/home/oleg/bin/zig build abi-differential > tmp/inbox132_o2_scalar_cast_placement/validation/abi_differential.log 2>&1
result=60/60_cases,30/30_real_functions
log_sha256=5828ecc62f1aa1795bbab8c14fecf8c5d0d319722cdf4c29d7b790617f8254b9
```

### Frozen report

The accepted aggregate report exit status remains `1`.

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox132_o2_scalar_cast_placement/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
```

### Accepted object and owner projection

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox132_o2_scalar_cast_placement/validation/accepted.o 2> tmp/inbox132_o2_scalar_cast_placement/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_bytes=0

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox132_o2_scalar_cast_placement/validation/owner_manifest.tsv 2> tmp/inbox132_o2_scalar_cast_placement/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
owner_ledger=167/17/101
stderr_bytes=0
```

The frozen report, accepted object, owner projection, and ratchet are exact.
No performance command and no Tier 3 command were run.
