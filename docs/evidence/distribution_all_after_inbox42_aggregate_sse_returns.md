# Distribution-All After Exact SSE Aggregate Returns

schema_version: 1
directive: `INBOX-42`
cycle: `exact-sse-aggregate-returns`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `e24702a8` plus
implementation-only staged tree
`f0c0dfd5c70bc5d1feca429d505acbfbaa59d207`.

Changed subsystem: authoritative x86_64 SysV return classification, composed-
selector value locations and terminal aggregate construction, SSE return-
register materialization, machine entry-XMM metadata, verifier return-
definedness, and the pinned-Zig integrated executable ABI canary.

Tier-3 trigger: INBOX-42 explicitly requires one acceptance run because the
exact `{ <2 x float> }` and `{ double, double }` value shapes cross shared ABI,
selector, allocation-planning, machine, verifier, and executable-caller
surfaces.

Exact command and intended log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox42_aggregate_sse_returns.log 2>&1
```

Prior evidence cannot be reused because the accepted INBOX-41 run predates
the aggregate return classifier, typed aggregate leaves, terminal
`insertvalue`, alias-safe XMM0/XMM1 materialization, aggregate verifier checks,
and pinned-Zig `callconv(.c)` execution.

The single invocation passed all 17 subgates. All three 146-row integrated-
object pipelines, the 100-row release-source-owned pipeline, and strict real-
row gates in ReleaseFast, ReleaseSafe, and ReleaseSmall remain green. The
integrated executable suite advances from 5/5 to 6/6 solely because the new
aggregate-return ABI canary is now permanent.

```text
summary zig-integrated-object pipeline=postopt ir_writer=false total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=false total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=6 build_ok=6 run_ok=6 stdout_ok=6 exit_ok=6 aggregate_sse_return_rows=1 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 unsupported_relocation_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_object_codegen_failures=0 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 local_object_codegen_failures=0 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=2311993 cache_hit_subgates=3 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

The previous accepted run took 2,322,249 ms. This run took 2,311,993 ms, a
decrease of 10,256 ms (about 0.4%), so runtime has not changed materially.

Log: `tmp/distribution_all_after_inbox42_aggregate_sse_returns.log`, sha256
`dcaab9443211605c05d54096b596c55b6dfe377d507cd8a35995bd6d0b69dbb5`.
