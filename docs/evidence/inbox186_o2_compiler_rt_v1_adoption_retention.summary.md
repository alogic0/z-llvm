# INBOX-186 compiler-rt v1 exact adoption and retention

## Disposition

INBOX-186 completed successfully. Generation 1 was installed exactly once
with the frozen command, the adopted input is byte-identical to all three
accepted generation outputs, and the complete adoption manifest is
read-only:

```text
artifact_id=o2-calls-compiler-rt-v1-releasefast-x86_64-linux-gnu-baseline-zig-bdee02bc-sha256-9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1
adopted_path=tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll
adopted_regular_file=yes
adopted_bytes=1897410
adopted_mode=444
adopted_sha256=9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1
adopted_cmp_gen1=0
adopted_cmp_gen2=0
adopted_cmp_gen3=0
```

Exactly two ordered live-pin rows were appended. The existing reporter ran
once in report-only/no-delete mode and reported both top-level roots as
protected by `explicit-live-pin`.

This accepts exact adoption and explicit retention protection only. No
workload or baseline validation, protocol adoption, `z_llvm`, selector,
coverage, performance, production wiring, cleanup, or ratchet credit ran or
changed. The ratchet remains **131**.

## Authorization boundary

The active INBOX-186 entry was read and acknowledged before work.

```text
authorization_HEAD=06c100b79a0fdc4deb383f65fb219b2d3883dd78
authorization_tree=3dc6b89085a1f5182ff0e9ec581e05be619d56cb
authorization_parent=b1567ace8ac380cb380cc70d5a86e033a9d895a5
accepted_contract_commit=1c343ec879e46eb488a737e6da8db4ebdc6038f5
accepted_contract_sha256=a5c1d3f97b35d1815cc933cebf1a5261fd7fa9fde1277beb97a694a987bf02da
accepted_reproduction_commit=b1567ace8ac380cb380cc70d5a86e033a9d895a5
accepted_reproduction_evidence_sha256=27eed58063ec1ae512a159fbab028498250fec33050737c200d0c6422ed0a17b
starting_tracked_status=clean
branch=x86_64-codegen-expanded-frontier
ratchet=131
```

Frozen infrastructure at entry:

```text
watcher_HEAD_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
watcher_index_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
watcher_worktree_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash@{0}=7985c6d01040a6e47e4ce5b918866d0e89517ac7
stash_subject=On x86_64-codegen-expanded-frontier: INBOX-93 preserve B2B wiring plus five diagnosis tests
```

## Preflight completed before adoption mutation

Preflight ran from
`2026-07-19T21:34:35,643626247+00:00` through
`2026-07-19T21:34:52,149720500+00:00`. No adoption root or pin mutation
occurred until every check below passed.

### Cleanliness and absence

```text
zllvm_HEAD=06c100b79a0fdc4deb383f65fb219b2d3883dd78
zllvm_tree=3dc6b89085a1f5182ff0e9ec581e05be619d56cb
zllvm_tracked_status=clean
reproduction_root=tmp/inbox184_o2_compiler_rt_v1/materialize
reproduction_root=present
adoption_root=tmp/o2_calls_perf
adoption_root_before=absent
adoption_path=tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll
adoption_path_before=absent
```

The required contract and reproduction evidence were exact:

```text
contract_document=docs/evidence/inbox184_o2_reproducible_compiler_rt_corpus_contract.md
contract_document_sha256=a5c1d3f97b35d1815cc933cebf1a5261fd7fa9fde1277beb97a694a987bf02da
reproduction_evidence=docs/evidence/inbox185_o2_compiler_rt_v1_three_generation_materialization.summary.md
reproduction_evidence_sha256=27eed58063ec1ae512a159fbab028498250fec33050737c200d0c6422ed0a17b
```

### Complete retained-bundle verification

The reproduction bundle's final manifest and every one of its records were
revalidated before adoption:

```text
bundle_manifest=tmp/inbox184_o2_compiler_rt_v1/materialize/comparison/retained-files-final.tsv
bundle_manifest_entries=2542
bundle_manifest_sha256=885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e
bundle_self_hash_check=PASS
record_path_check=PASS
record_mode_check=PASS
record_owner_group_check=PASS
record_byte_count_check=PASS
record_sha256_check=PASS
```

The three one-shot generation outputs were reconfirmed as nonempty regular
mode-`0664` files:

| Output | Bytes | SHA-256 |
|---|---:|---|
| `tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/output/compiler_rt_v1.ll` | 1,897,410 | `9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1` |
| `tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/output/compiler_rt_v1.ll` | 1,897,410 | `9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1` |
| `tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/output/compiler_rt_v1.ll` | 1,897,410 | `9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1` |

Fresh raw comparisons all returned status zero:

```text
cmp_gen1_gen2=0
cmp_gen1_gen3=0
cmp_gen2_gen3=0
```

### Source, tool, retention, and frozen identities

```text
zig_HEAD=bdee02bc0c7f227c0f11bc9a449df673fe803540
zig_tree=aa032b2b82a48a4684657f909e6e270a6c925e33
zig_status=clean
compiler_rt_root_sha256=388ce4e0ac6dd5a285a19c66d193d088d3515f5dd726cafc475d222cdd8b4fa0
stage4_sha256=dcea3478273d7ffe3895709c8eed4ccc0724548869cdb86183fc7356164410b7
stage4_dependencies_before_after_cmp=0
retention_policy_sha256=a31e3fbf7aa03c8544fc5f9921e350c25e4e470cc3c779dfb356136634e052dd
retention_pins_before_sha256=f4374187d77ec6b7c42ee1b64538ead1a2d599697595a7f59c28b23dae5c6614
clean_tmp_source_sha256=8e0c54ad6fed9e46326049dbe64bff743daddcc2527c1dc4d5e02be15fba2d5e
reporter_path=tmp/clean_tmp_inbox59
reporter_bytes=17515576
reporter_mode=775
reporter_sha256=13b2f4f57b05630c71c3b30873bf178b9d7d231ceed106639c04edb4a6567abb
parallel_policy_sha256=cecab78d6fbc148d3726823934291631f86cbf0ae93c02225925267387a11cfe
parallel_peak_bytes=17179869184
frozen_surface_manifest_check=PASS
candidate_report_manifest_check=PASS
watcher_check=PASS
stash_check=PASS
ratchet=131
```

### Capacity

The adoption envelope conservatively reserved the 64-MiB local allowance
plus one complete input:

```text
filesystem_total_bytes=982240026624
filesystem_free_bytes=97771704320
capacity_required_bytes=69006274
capacity_headroom_bytes=97702698046
capacity=PASS
```

## Exact one-shot adoption

The following command ran exactly once and returned status 0:

```text
/usr/bin/install -D -m 0444 tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/output/compiler_rt_v1.ll tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll
```

No alternate source, destination, command, tool, mode, or retry was used.
The install executable identity recorded in the adoption manifest is:

```text
install_path=/usr/bin/install
install_bytes=145944
install_mode=755
install_sha256=0e328ae109217200da3207ece12514b867d44fb90b444958b4d64b6007736f33
```

The installed file was verified at
`2026-07-19T21:35:16,162995401+00:00`:

```text
install_status=0
regular_file=yes
bytes=1897410
mode=444
sha256=9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1
cmp_gen1=0
cmp_gen2=0
cmp_gen3=0
```

## Adoption manifest and final modes

The complete manifest is:

```text
path=tmp/o2_calls_perf/compiler_rt_v1/adoption_manifest.tsv
bytes=4394
mode=444
sha256=500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf
```

It records the full artifact ID; contract and reproduction commits and
evidence hashes; pinned Zig commit/tree; raw tree, compiler-rt root, stage4,
dynamic-dependency, host-tool, pre-generation, retained-bundle,
output-comparison, and reproduction-result identities; exact install
tool/command/status; adopted file identity; and all three generation
identities/comparison statuses.

The adopted input and manifest were hashed after reaching final mode `0444`.
The read-only companion record is:

```text
path=tmp/o2_calls_perf/compiler_rt_v1/adoption_final.sha256
bytes=238
mode=444
sha256=00cee290bd079618f2125ab51c9efb3ff936cf69394080f7242d07594b7579ea
```

Its contents are:

```text
9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1  tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll
500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf  tmp/o2_calls_perf/compiler_rt_v1/adoption_manifest.tsv
```

## Exact live-pin append

The original retention TSV contained 18 lines and had SHA-256
`f4374187d77ec6b7c42ee1b64538ead1a2d599697595a7f59c28b23dae5c6614`.
Its first 18 lines remain byte-identical and in the same order. Exactly these
two rows were appended, in order:

```text
tmp/inbox184_o2_compiler_rt_v1	compiler-rt-v1-reproduction	INBOX-186/o2-calls-compiler-rt-v1-releasefast-x86_64-linux-gnu-baseline-zig-bdee02bc-sha256-9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1	complete three-generation reproduction bundle retained through baseline validation
tmp/o2_calls_perf	compiler-rt-v1-adopted-input	INBOX-186/o2-calls-compiler-rt-v1-releasefast-x86_64-linux-gnu-baseline-zig-bdee02bc-sha256-9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1	read-only adopted compiler-rt v1 input and manifest retained through baseline validation
```

```text
retention_pins_after_lines=20
retention_pins_after_sha256=1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
existing_rows_changed=0
rows_appended=2
```

The retention policy and reporter source/binary were not changed.

## One-shot retention report

Fresh observations:

```text
observed_at_unix=1784497039
filesystem_total_bytes=982240026624
filesystem_free_bytes=97837420544
sharding_peak_bytes=17179869184
accepted_through_inbox=185
active_inbox=186
reporter_sha256=13b2f4f57b05630c71c3b30873bf178b9d7d231ceed106639c04edb4a6567abb
retention_manifest_sha256=1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
```

The existing reporter ran exactly once from
`2026-07-19T21:37:19,592171707+00:00` through
`2026-07-19T21:37:49,057841727+00:00`:

```text
tmp/clean_tmp_inbox59 --retention-report --tmp-dir=tmp --pin-file=docs/evidence/ziglang_pin.txt --retention-manifest=docs/evidence/tmp_retention_pins.tsv --patched-zig-cache=../ziglang/.zig-cache --accepted-through-inbox=185 --active-inbox=186 --now-seconds=1784497039 --filesystem-total-bytes=982240026624 --filesystem-free-bytes=97837420544 --sharding-peak-bytes=17179869184
```

No `--delete` option was present.

```text
exit_status=0
stdout_bytes=12999
stdout_sha256=ab60b2d351b5e49b3e53f64b54a0a8f1d4f41f40587d1eba071b665031d63f2b
stderr_bytes=0
stderr_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

The required report rows are:

```text
tmp/inbox184_o2_compiler_rt_v1	per-inbox-tmp	176777399	933	INBOX-186/o2-calls-compiler-rt-v1-releasefast-x86_64-linux-gnu-baseline-zig-bdee02bc-sha256-9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1	protected	explicit-live-pin	focused-rebuild-or-reprobe	0
tmp/o2_calls_perf	unclassified-tmp	1910993	0	INBOX-186/o2-calls-compiler-rt-v1-releasefast-x86_64-linux-gnu-baseline-zig-bdee02bc-sha256-9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1	protected	explicit-live-pin	unknown-review-required	0
```

Each exact path appears once with the full key, `protected`, and
`explicit-live-pin`. The report total is:

```text
entries=76
protected=53
candidates=23
total_reclaimable_bytes=12841965669
projected_free_after_cleanup=110679386213
projected_free_after_sharding_peak=93499517029
projected_ready_after_cleanup=false
deleted=0
```

The report is an inventory and protection proof only; its readiness field
does not authorize cleanup, sharding, validation, or performance.

Command, observation, timestamps, raw stdout/stderr, and status are retained
read-only beneath the adopted root. Their read-only hash record is:

```text
path=tmp/o2_calls_perf/compiler_rt_v1/retention_report.final.sha256
mode=444
sha256=ec2a3121518ece96a01de8a0252d223ef189e885217c0dc3d295ff7063030c9f
```

## Postflight

Postflight ran from
`2026-07-19T21:39:16,162237709+00:00` through
`2026-07-19T21:39:32,344359861+00:00`.

```text
adopted_input_mode=444
adopted_input_bytes=1897410
adopted_input_sha256=9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1
adoption_manifest_mode=444
adoption_manifest_bytes=4394
adoption_manifest_sha256=500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf
adopted_cmp_gen1=0
adopted_cmp_gen2=0
adopted_cmp_gen3=0
reproduction_bundle_entries_verified=2542
reproduction_bundle_manifest_sha256=885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e
retention_pins_exact_appends=2
retention_report_explicit_live_pin_counts=1,1
retention_report_deleted=0
```

Every frozen surface except the explicitly authorized pin TSV was
byte-identical to preflight:

```text
zig_HEAD=bdee02bc0c7f227c0f11bc9a449df673fe803540
zig_tree=aa032b2b82a48a4684657f909e6e270a6c925e33
zig_status=clean
stage4_sha256=dcea3478273d7ffe3895709c8eed4ccc0724548869cdb86183fc7356164410b7
stage4_dependencies_cmp=0
watcher_HEAD_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
watcher_index_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
watcher_worktree_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash@{0}=7985c6d01040a6e47e4ce5b918866d0e89517ac7
retention_policy_sha256=a31e3fbf7aa03c8544fc5f9921e350c25e4e470cc3c779dfb356136634e052dd
clean_tmp_source_sha256=8e0c54ad6fed9e46326049dbe64bff743daddcc2527c1dc4d5e02be15fba2d5e
reporter_sha256=13b2f4f57b05630c71c3b30873bf178b9d7d231ceed106639c04edb4a6567abb
frozen_source_tool_bypass_facade_surfaces=exact
frozen_candidate_report_surfaces=exact
ratchet=131
```

No postflight discrepancy occurred.

## Explicit exclusions and stop

This slice did not run:

- workload or ratchet-131 baseline validation;
- protocol adoption or execution;
- `z_llvm`, selector/report, object/owner/per-function generation, or
  dynamic coverage;
- correctness gates, Zig project build/test, ABI, canaries, integrated
  executable, strengthened Tier 2, distribution-all, or Tier 3;
- performance samples or A/B artifact construction;
- production source/tool/test/guard/build/inventory/facade/bypass changes;
- production wiring, helper collapse, or ratchet credit;
- cleanup, deletion, `clean_tmp`, Git maintenance, replacement, repair,
  fallback, or retry.

The reproduction bundle, all three generated outputs, adopted root, raw
retention evidence, watcher, stash, and frozen surfaces remain retained.

STOP after this evidence commit for Watcher/Reviewer review. Baseline
validation, protocol adoption, production wiring, performance, and credit
remain separately unauthorized.
