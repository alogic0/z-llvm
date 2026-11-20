# Distribution-All After INBOX-45 Pipeline A

schema_version: 1
directive: `INBOX-45 cumulative pipeline acceptance`
target: `x86_64-linux-gnu`
validation_tier: 3
status: pass

Implementation identity before the run: committed baseline
`5d8bf43612948c6c26f3855804378fd1d1bb8f0e`, with clean staged/committed tree
`1d90ef75d73149eaa8aeb062e8640daee8330a3b`. The current-source ReleaseFast
z_llvm has sha256
`d3b8953cf696577340abd065268f36a3f34865becfd8e4e5a866f6c1a14db218`.

Changed subsystem: x86_64 composed-selector narrow integer comparisons and
exact intrinsic call lowering, with permanent selector and executable
coverage. The two-step pipeline adds exact normalized i6/i7 `samesign ult` /
`ugt` immediate comparisons and exact `llvm.cttz.i64(i64, i1 immarg)`.

Tier-3 trigger: the `validation_tiers.md` row-closure batching amendment and
INBOX-45 require one cumulative Tier 3 at the end of this two-step pipeline to
accept its eight Tier-2/native-proven provisional closures.

Exact command and evidence log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox45_narrow_cmp_cttz_i64.log 2>&1
```

Prior evidence cannot be reused because every earlier Tier 3 predates exact
i6/i7 samesign unsigned-immediate normalization, exact i64 count-trailing-zero
lowering, their permanent executable cases, and the resulting two i32-to-half
plus six i64-to-FP row emissions. The preface was recorded before the single
invocation in `tmp/inbox45_pipeline_tier3_preface.txt`, sha256
`4e02825faf56c3de15e9f108af8dbbf48474eda896dd42185801f58be49b87c2`.

The invocation passed all 17 subgates. Selected native-link inspection and
probes remain 45/45. Integrated objects remain 146/146 for postopt, preopt,
and IR-writer pipelines. Release-source-owned integrated objects remain
100/100. Strict real rows remain 100/100/100 in ReleaseFast, ReleaseSafe, and
ReleaseSmall. Integrated executables remain 6/6. Release-source object
inspection, native linking, and native probes remain 100/100 each. Boundary
gates are green.

This cumulative result accepts all eight provisional pipeline closures:

- `__floatunsihf` and `__floatsihf` from Part 1;
- `__floatundidf`, `__floatundisf`, `__floatundihf`, `__floatdidf`,
  `__floatdisf`, and `__floatdihf` from Part 2.

The accepted compiler_rt report state is now 443 selected / 256 emitting /
187 failing. Part 1 exact native evidence is
`docs/evidence/std_debug_hello_inbox45_narrow_icmp.summary.md`; Part 2 exact
native evidence is `docs/evidence/std_debug_hello_inbox45_cttz_i64.summary.md`.

```text
summary native-link-object-inspection inventory=selected-native-link inspected=45 elf64_rel=45 unsupported_relocation_rows=0 local_fail=0
summary native-link-probe target=x86_64-unknown-linux-gnu accepted=45 failed=0
summary zig-integrated-object pipeline=postopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=6 build_ok=6 run_ok=6 stdout_ok=6 exit_ok=6 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_object_codegen_failures=0 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 local_object_codegen_failures=0 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2268761 cache_hit_subgates=3 cache_none_subgates=14 fresh_real_rows=false local_fail=0
ok distribution all gates
```

The reported total is 81,004 ms (3.4%) below the prior INBOX-43 Tier-3 total
of 2,349,765 ms despite the larger permanent test surface. This does not show
a material runtime regression. The slowest uncached subgate remains integrated
preopt at 548,717 ms; the three strict real-row subgates reported cache hits.

Log: `tmp/distribution_all_after_inbox45_narrow_cmp_cttz_i64.log`, sha256
`96509e8f46ed4f6eb0b80d4c95ba430d7094f2413968648058bfb3ae5db42e43`.
