# INBOX-172 — unsigned quotient production wiring

Status: complete. Production commit
`dc96b63d7ef25e651f0dc16d9df3309c9371871f` wires UQ32 and UQ64 together
through `ValueUseTransaction`; the `urem` dispatch and `lowerUnsignedRem`
remainder path are unchanged. The post-final-tree counterbalanced performance
gate passed on its single prescribed batch.

No Tier 3 command was run.

## Baseline and scope

Work began from authorization commit
`7af7f0700d0abf976f1e63ead29217b095f11934`, tree
`d2bbc1592ad825fb2626ec149641491c95711f07`. The accepted aligned quotient
baseline is `390945be`; the accepted three-build re-isolation result is
`c532fe82`.

Production changes are confined to:

```text
src/codegen/x86_64/generic_cfg/composed_selector_scalar.zig
src/codegen/x86_64/generic_cfg/source_guard/consumer_policy.zig
src/codegen/x86_64/generic_cfg/source_guard/consumer_policy_tests.zig
src/codegen/x86_64/generic_cfg/source_guard/model.zig
docs/evidence/inbox81_o2_resolution_materialization_bypasses.tsv
```

The frozen action, lifetime/Q1, and central model remain byte-identical:

```text
value_use/actions/scalar_multiply_divide.zig=fd2ce0f67a2983544c139edd1d0188e8b8a3cd1057d3ce3f4382b4137cc7a0db
value_use/planning/lifetime_admission.zig=09a3df3cd84c4243409ec064edafdf93ed39df5e882854fd36a4027010ce17cb
value_use/model.zig=32f3086a8fc714245ee9a211e16ce8eb90a32496a2d0f87f1f2e3e5ac27ea3ef
```

No action, planning, lifetime, Q1, request, error, physical-home, pair,
cycle, or fallback capability changed.

## Complete consumer migration

`lowerUnsignedDivRem` retains the accepted pre-transaction remainder
dispatch:

```text
if (binary.op == .urem) return lowerUnsignedRem(selector, result_name, binary, bits);
```

The remaining named `udiv i32/i64` branch is classified semantically and
opens exactly one outer `ValueUseTransaction`. It:

1. registers RHS first as the prepared source;
2. registers LHS second as the prepared view;
3. attaches the frozen semantic `UnsignedQuotientAction`;
4. seals all requests before mutation;
5. prepares and materializes through the transaction authority;
6. executes the closed action internally; and
7. commits exactly once after complete result definition.

The consumer performs no current-home inspection, raw resolution, scratch
selection, accumulator transaction, retry, or attempt-then-fallback.
Request-specific failures map only through the matching retained RHS/LHS
handles; authority failures propagate unchanged.

The action continues to derive UQ32/UQ64 width and RHS accumulator versus
non-accumulator staging internally from semantic type and canonical
transaction state.

## Remainder and retained-owner proof

`lowerUnsignedRem` is textually unchanged. It retains:

- RHS classification through the legacy resolver;
- the accepted accumulator/non-accumulator staging split;
- the exact RAX/RDX/RCX fixed-register sequence;
- the EFLAGS clobber;
- the RDX remainder result binding; and
- all five retained bypass occurrences.

R03, R04, pair/full-product, and all other retained scalar owners are
unchanged. There is no quotient transaction around the remainder path.

## Honest ratchet and final production-owner recount

The accepted ratchet was 135. The inventory removes exactly these two rows:

```text
composed_selector_scalar.zig/lowerUnsignedDivRem:
  resolveValue×1 + emitValueIntoScratch×2 = 3 direct credits

composed_selector_scalar.zig/accumulatorDirectMaterializationDisplacement:
  resolveValue×1 = 1 last-owner credit
```

The final production source contains neither a declaration nor a call of
`accumulatorDirectMaterializationDisplacement`. Its two production callers
were both in the replaced quotient branch. The sole surviving textual name
is the source-guard assertion that rejects reintroduction; historical
evidence/docs references neither create production ownership nor block the
collapse.

```text
ratchet_before=135
direct_quotient_credit=3
production_owner_count_after=0
last_owner_credit=1
other_credit=0
ratchet_after=131
owner_recount_log=tmp/inbox172_o2_quotient_wiring/validation/owner_recount.log
owner_recount_log_sha256=112d6dad37fa7cfb35e8d18f973444a43142e4639ba27807b14d2b011d45e536
```

The bypass TSV SHA-256 moves only because those two proven rows were
removed:

```text
before=3928114a0fcc55d5f18a367b29865925396c80c3a2589e02c87f4e0a73b23537
after=2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11
```

No helper-collapse or direct credit beyond these four occurrences is
claimed.

## Structural guard

The guard now admits the quotient action only inside
`composed_selector_scalar.zig` and requires:

- the unchanged `urem` dispatch before the transaction;
- the single pure unsigned-quotient classifier;
- one complete quotient action authority;
- exactly two named requests;
- exactly one seal, prepare, materialize, prepared-view execution, and
  commit;
- zero raw resolution/materialization or independent accumulator authority;
- exactly two provenance queries in the quotient diagnostic mapper; and
- absence of `accumulatorDirectMaterializationDisplacement`.

Negative fixtures reject quotient use in another production file, raw
resolution in the transaction consumer, and movement of the remainder
dispatch. The shared named-form and provenance budgets move from 8/6 to
10/8 solely for the two quotient requests and two mapper queries.

Final changed-source hashes:

```text
composed_selector_scalar.zig=2ea3b3c40785e65b9cfc692f884b1676bac3cf4eb420936be8ff7c39cb85bde8
source_guard/consumer_policy.zig=fb13926be765ad574c6dcf0e60de9d5517e3ef365ccd750bc006792366b2da5c
source_guard/consumer_policy_tests.zig=a578be236a3f28ee404ad4cb14e305c3cd106fcfcd10a04415567b2a4a593bd4
source_guard/model.zig=559c74435ebb225e1e0da06401b277f64515aa753414cdcb0bce620cf7a6b012
```

## Decisive identities

Commands:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll >/dev/null 2>tmp/inbox172_o2_quotient_wiring/validation/fresh_full_report.log

command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll >tmp/inbox172_o2_quotient_wiring/validation/accepted.o 2>tmp/inbox172_o2_quotient_wiring/validation/accepted.stderr

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll >tmp/inbox172_o2_quotient_wiring/validation/owner_manifest.tsv 2>tmp/inbox172_o2_quotient_wiring/validation/owner_manifest.stderr

command=/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- tmp/inbox171_o2_quotient_reisolation/results/baseline/accepted.o tmp/inbox172_o2_quotient_wiring/validation/accepted.o >tmp/inbox172_o2_quotient_wiring/validation/function_diff.tsv

command=rg 'composed-block-icmp-lhs-loc' tmp/inbox172_o2_quotient_wiring/validation/fresh_full_report.log >tmp/inbox172_o2_quotient_wiring/validation/frontier_rows.log
```

Results:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report=443 selected / 285 emitted / 158 failed
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=40 composed_block + 127 composed_cfg / 17 legacy / 101 structural
per_function=285 compared / 0 divergent / 0 missing
per_function_log_sha256=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
accepted_stderr_bytes=0
owner_stderr_bytes=0
frontier_rows=6
frontier_rows_sha256=87c35d64c6f8b8742b3f8449ad3b5bb1701d84cddbbc0624d6b7315a1047855f
baseline_frontier_cmp=equal
```

The full report, accepted object, owner manifest, and all 285 function
objects are byte-identical to the accepted baseline. The six
`composed-block-icmp-lhs-loc` frontier rows are also byte-identical.

## Correctness gates

Every command ran against the final production source state. Logs are
retained under `tmp/inbox172_o2_quotient_wiring/validation/`.

### Full unit

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox172_o2_quotient_wiring/validation/full_unit.log >/dev/null
result=7/7 steps; 1375/1375 tests passed
log_sha256=b3efbd4efa83b4d0f4574aa9ab643c2ee352c29b903f6e5b5bb3975d3caa7c98
```

### Source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig 2>&1 | tee tmp/inbox172_o2_quotient_wiring/validation/source_guard.log >/dev/null
result=57/57 tests passed
log_sha256=4e8eb71ee77970fef0f77a9a8431b4b4cc62cc9394aac53a0173ddcc0272e84a
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox172_o2_quotient_wiring/validation/abi_differential.log >/dev/null
result=5/5 steps; 60/60 cases and 30/30 real functions matched
log_sha256=0882332b83d9e9c6285bf60d94e2724549ad29958e533a78a12e5f2439b038d0
```

### Focused canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox172_o2_quotient_wiring/validation/focused_canaries.log >/dev/null
result=2/2 canaries; 35/35 execution cases; fma and __multi3 exact
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

### Integrated executable

```text
command=/home/oleg/bin/zig build distribution-zig-integrated-exe --summary all 2>&1 | tee tmp/inbox172_o2_quotient_wiring/validation/integrated_exe.log >/dev/null
result=2/2 steps; 7/7 build/run/stdout/exit
log_sha256=f8c34c34a40b819df8ae2be09bac5760e018b05cf211a3db261acb848632fd1d
```

### Strengthened Tier 2

```text
command=/home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all 2>&1 | tee tmp/inbox172_o2_quotient_wiring/validation/strengthened_tier2.log >/dev/null
result=29/29 steps; 1383/1383 tests; structural 8/8; integrated executable 7/7; ABI 60/60+30/30
log_sha256=781d819ab0005812b4241bcb5ffc9802e739b05643d0f0179e2030bcbe48bcef
```

No `distribution-all` command and no Tier 3 command was run.

## Counterbalanced performance

PASS. The artifacts were built only after the complete production source,
guard, inventory, and initial evidence tree had been committed. A and B were
built in detached worktrees and frozen `0555` before timing; neither was
rebuilt between samples.

Frozen sources and artifacts:

```text
A_commit=7af7f0700d0abf976f1e63ead29217b095f11934
A_tree=d2bbc1592ad825fb2626ec149641491c95711f07
A_artifact_sha256=a46eaf36ef26f1889e2ffe560d63a5e90834f6d2c6d3aed522936fe3d21c6fb2
A_artifact_mode=0555
A_artifact_bytes=104352248

B_commit=dc96b63d7ef25e651f0dc16d9df3309c9371871f
B_tree=81e3e46a3c5fbbbe0b2c3d33e08dbed90bce338f
B_artifact_sha256=f8a0742e901ee1be38039105f04fe10c6323db2f5447b8685e1139b3ca1c9697
B_artifact_mode=0555
B_artifact_bytes=103888546
```

Build commands:

```text
workdir=tmp/inbox172_o2_quotient_wiring/perf/worktree_A
command=/home/oleg/bin/zig build 2>&1 | tee /home/oleg/prog/z_llvm/tmp/inbox172_o2_quotient_wiring/perf/build_A.log
result=PASS
log_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

workdir=tmp/inbox172_o2_quotient_wiring/perf/worktree_B
command=/home/oleg/bin/zig build 2>&1 | tee /home/oleg/prog/z_llvm/tmp/inbox172_o2_quotient_wiring/perf/build_B.log
result=PASS
log_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

The preflight was captured at `2026-07-19T01:27:59-05:00`. CPU 0 averaged
98.34% idle over three one-second samples, with zero iowait and zero steal.

```text
command={ date --iso-8601=seconds; uptime; ps -eo pid,psr,stat,comm,args --sort=-%cpu | sed -n '1,30p'; mpstat -P 0 1 3; } > tmp/inbox172_o2_quotient_wiring/perf/idle_preflight.txt
idle_preflight_sha256=34c3b9d61b426a51fb82196a01ec20567738e23628b02d56bba297110cf0f985
```

The Zig runner pinned every selector invocation to CPU 0, set `LC_ALL=C`,
used the same frozen compiler-rt input and selector arguments, discarded
exactly two warmups per artifact, and retained six counterbalanced pairs in
the required order `AB, BA, AB, BA, AB, BA`.

```text
command=/home/oleg/bin/zig run tmp/inbox172_o2_quotient_wiring/run_counterbalanced.zig 2>&1 | tee tmp/inbox172_o2_quotient_wiring/perf/run_counterbalanced.log
runner_sha256=d6f94cc620317ab434578fed94df704bdf0d9018bbf3b07b1a5ad7fbb87b8715
run_log_sha256=d142895d36a766f2de28ff939881c1ca0671ca8a7635c0f9224c7c14f74ff6ec
result=16/16 samples completed
```

Every retained sample:

```text
pair  order  A_seconds  A_RSS_KiB  B_seconds  B_RSS_KiB  B/A
1     AB     48.88      89372      49.12      89316      1.004909984
2     BA     48.97      89384      49.48      89304      1.010414540
3     AB     49.07      89376      49.48      89308      1.008355411
4     BA     48.97      89372      49.29      89316      1.006534613
5     AB     49.03      89364      49.23      89324      1.004079135
6     BA     49.28      89368      49.58      89316      1.006087662
```

Discarded warmups, retained without entering the decision:

```text
warmup1_A=49.17s/89376KiB
warmup1_B=49.36s/89312KiB
warmup2_A=49.91s/89376KiB
warmup2_B=49.89s/89312KiB
```

The Zig analyzer verified all sixteen generated selector reports before
computing the gates:

```text
command=/home/oleg/bin/zig run tmp/inbox172_o2_quotient_wiring/analyze_counterbalanced.zig 2>&1 | tee tmp/inbox172_o2_quotient_wiring/perf/paired_metrics.tsv
analyzer_sha256=2709a36bfd843028d45eb615671981eadf0ca7dbe38c9c9d8ae3eb302ed3054d
metrics_sha256=4dc11268a797db8d426568a3631ad85d8433b5b414fa5304e776f6621d3d72c8
reports_exact=16/16
median_A_seconds=49.000
median_B_seconds=49.385
median_delta_seconds=0.385
allowed_delta_seconds=max(2.450,0.100)=2.450
aggregate_median_pass=true
median_paired_ratio=1.006311138
paired_ratio_limit=1.05
paired_ratio_pass=true
A_max_RSS_KiB=89384
B_max_RSS_KiB=89324
RSS_delta_KiB=-60
RSS_limit_KiB=16384
RSS_pass=true
overall=PASS
```

All raw samples and reports are retained:

```text
raw_files=16
raw_manifest_sha256=a5cd0d1d77f36a3b6c94aef19311ba1835f3c79f3a7fc0fe89a6ef1627da3e1b
report_files=16
report_manifest_sha256=a16a44b8fe06793a7524f241dd4da47f2865cdef7973cbb6b23e91ad77519145
every_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
```

There was no discretionary rerun. No Tier 3 command was run.
