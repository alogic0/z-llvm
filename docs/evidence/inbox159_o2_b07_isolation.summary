# INBOX-159 — fresh B07 isolation

Status: complete and stopped for review. B07 passes the fresh isolated
production wiring. This commit is evidence only: accepted production,
tests, guards, tools, and build roots are restored unchanged, and the
landed direct-resolution ratchet remains 148.

## Verdict

The temporary build wires exactly the complete B07 family through the
accepted `NamedScalarBinaryAction`. B01, I52B0, and B03–B06 remain wired
as already landed; R03 and R04 remain on their accepted legacy owners.
The frozen action, model, lifetime-admission, and forward-Q1
implementations were not edited.

The B07 isolation meets every acceptance condition:

```text
six_b07_rows=6/6 restored
report=443 selected / 285 emitted / 158 failed
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object=exact
owner=exact
owner_ledger=167 composed / 17 legacy / 101 structural
per_function=285 compared / 0 divergent / 0 missing
full_unit=1356/1356
focused_canaries=2/2 canaries / 35 executable cases
```

Therefore B07 is individually ready for a separately reviewed production
wiring slice. The arithmetic is only a conditional projection:

```text
landed_ratchet=148
B07_direct_credit=8
conditional_projection_after_separate_wiring=140
```

This evidence does not move the ratchet and does not authorize or perform
the final wiring.

## Frozen baseline and source provenance

The accepted amendment is commit
`17bfa6d77cf5546440a6775bda06d8927fad3033`, tree
`705064312a91c91dd83b5dcde499693a981fd06f`. The isolation was dispatched
and executed from authorization HEAD
`a28a0aa43d792232d2f11b89ca2ed84a27292c31`, tree
`8590d9b65d627ade5ac0e8ca55ff2b1ae7cf0307`. The only tracked delta
between those trees is `docs/next_steps.md`; production sources, tests,
guards, tools, and build roots are identical.

Accepted source hashes:

| Source | SHA-256 |
|---|---|
| `composed_selector_scalar.zig` | `c9069ce43fcebad595ee997164e6791728d3f18e1cffefa6b876e566b8f93bb0` |
| `source_guard/consumer_policy.zig` | `4baa8213c328bc7dca1f410c95ac7b31d058b2748144a8776df6309b75adddaa` |
| `source_guard/consumer_policy_tests.zig` | `6dc360598a58c0ba647cb8d1cf2c6816cf1dfa697731d35679c40e4474573de9` |
| `value_use/actions/scalar_named.zig` | `8ca8e37e93513f2e40c5dd08e0b389ff743ea07944d033b6ec18fcdbeafe48c1` |
| `value_use/model.zig` | `eb989e6cb6e8aa9645387751a1839ab751741f96484b6fc3f3cb6dd0d3fdb649` |
| `value_use/planning/lifetime_admission.zig` | `35bb4d9f12bd372063692aa9cb55333ce06b47b39d0964d13be7bd121e20b1b6` |

Frozen inputs and comparator:

| Input | SHA-256 |
|---|---|
| `tmp/inbox63_accepted_cohort.ll` | `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4` |
| `tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll` | `7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b` |
| `tmp/inbox142_family_isolation/compare_elf_functions.zig` | `34b5d400b47a9e861e5f6e7082f54ad57d6bc9b3e5e772d60420074b4dd4ce8f` |

## Temporary wiring provenance

The temporary patch changes only:

1. The final B07 dispatch in `lowerBinary`, routing it to the already
   landed `lowerNamedScalarBinary` transaction helper with diagnostic
   kind `.b07`.
2. The private diagnostic kind and its exhaustive legacy diagnostic
   mapping.
3. A procedural source-guard marker/exemption so the complete unit suite
   can exercise the intentionally temporary wiring.

It does not modify an action, model, lifetime/admission authority,
request surface, physical-home authority, or any other family dispatch.
It contains no retry, fallback, consumer-side resolution, or home
inspection.

```text
temporary_patch=tmp/inbox159_o2_b07_isolation/patches/b07.patch
temporary_patch_sha256=7ffd3da042514ad6d9d666711ed2e58f1ddc1c63bf75009b2c010a81d10ec61f
temporary_scalar_source_sha256=c5e92de9507d7ac7ba465292c6d26ef6606bc624c1e0c0fa5230f995a047cfb2
temporary_consumer_guard_sha256=9d27a0b57f9eb4955737977cf0b52252878dcff13b458f27a64883f41db80462
temporary_consumer_guard_tests_sha256=fd36c7c1e8c399072a9035ef90288f4fef36ac7393db6221674087860182e04e
baseline_artifact_sha256=9eb70df60ce58973ec66506d8b0622ae0b2fb735ba4e17b09dee375334b1ba25
b07_artifact_sha256=02f96a24fd5bc103a84779ced88637974ff7682916ed7f8fad474bf5ecfc76ea
```

Both compiler artifacts were copied immediately after their respective
builds and made immutable mode `0555`. There were no rebuilds during the
cohort comparisons. After the isolation, the three temporary source
files were restored with scoped `git checkout -- <files>`. The frozen
patch then passed `git apply --check` against the restored accepted tree,
and every restored source hash matches the baseline table above.

The complete sorted 29-file artifact/log manifest is:

```text
path=tmp/inbox159_o2_b07_isolation/hashes.sha256
sha256=581869fe5bdb5ddf7d8aa1d6f0163fc8c176f5b3aff0b9ffa7fc72bfc32f5cd2
```

## Six mandatory B07 rows

All six functions are present in the isolated accepted object with the
same symbol address and size as the frozen baseline:

| Function | Address | Size |
|---|---:|---:|
| `compiler_rt.floatuneidf.__floatuneidf` | `0x25f10` | 2003 |
| `compiler_rt.floatuneisf.__floatuneisf` | `0x266e3` | 1869 |
| `compiler_rt.floatuneihf.__floatuneihf` | `0x26e30` | 1935 |
| `compiler_rt.floateidf.__floateidf` | `0x28058` | 2026 |
| `compiler_rt.floateisf.__floateisf` | `0x28842` | 2032 |
| `compiler_rt.floateihf.__floateihf` | `0x29032` | 2030 |

The sorted six-symbol manifests compare byte-for-byte:

```text
baseline_six_symbols_sha256=53512669d3702b826ce4c6678748479228132e8e02b62cdcc6104794ea7169ac
b07_six_symbols_sha256=53512669d3702b826ce4c6678748479228132e8e02b62cdcc6104794ea7169ac
cmp=equal
```

The exact whole-object identity plus the `285/0/0` function comparison
proves their complete function bytes and disassembly are unchanged, not
only their symbol metadata.

## Cohort and per-function commands

Baseline and isolated artifacts each used these exact command shapes:

```text
command=LC_ALL=C <artifact> --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> <report.log>

command=LC_ALL=C <artifact> --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > <accepted.o> 2> <accepted.stderr>

command=LC_ALL=C <artifact> --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > <owner.tsv> 2> <owner.stderr>

command=/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- tmp/inbox159_o2_b07_isolation/results/baseline/accepted.o tmp/inbox159_o2_b07_isolation/results/b07/accepted.o > tmp/inbox159_o2_b07_isolation/results/b07/function_diff.tsv
```

Results:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report_counts=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=40 composed_block + 127 composed_cfg / 17 legacy / 101 structural
per_function=285/0/0
per_function_log_sha256=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
accepted_stderr_bytes=0
owner_stderr_bytes=0
baseline_report_cmp=equal
baseline_object_cmp=equal
baseline_owner_cmp=equal
```

## Mandatory gates

### Full unit suite

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox159_o2_b07_isolation/logs/b07_full_unit.log
result=7/7 steps; 1356/1356 tests
log_sha256=ba648cbf26c192f93df3510b4b337104c5a1950e9283bb420c80eaa510eadd32
```

### Focused codegen canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox159_o2_b07_isolation/logs/b07_canaries.log
result=2/2 canaries; 35 executable cases; fma and __multi3 exact
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

No performance, `distribution-all`, or Tier 3 command was run.

## Closeout

The tracked worktree was clean after restoring the temporary files and
before adding this evidence document. `stash@{0}` remains:

```text
On x86_64-codegen-expanded-frontier:
INBOX-93 preserve B2B wiring plus five diagnosis tests
```

All preserved patches remain untouched. B07 production wiring is not
present in this commit.
