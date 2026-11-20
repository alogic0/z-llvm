# Distribution-All After INBOX-51 Select Pipeline

schema_version: 1
directive: `INBOX-51 select-value cumulative acceptance`
target: `x86_64-linux-gnu`
status: pass

Committed implementation tree identity before the run:
`02b0100c022ded30fe2c2b90e9d4159b2e12a49e` (commit `18cd28c4`).

Changed subsystem: x86_64 scalar select lowering for exact i64 literal arms,
plus its permanent executable selector coverage. The conditional named-i64
bitcast-select successor was not implemented because the refreshed captured
bodies already clear that form.

Tier-3 trigger: cumulative row-closure pipeline acceptance under
`docs/validation_tiers.md` for `__floatsidf`, `__fixdfdi`, `__fixsfdi`,
`__fixhfdi`, `__adddf3`, and `__subdf3`.

Exact accepted command and log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox51_select_pipeline.log 2>&1
```

Prior evidence cannot be reused because the immediate scalar-fneg P0 gate
predates committed select-owned i64 literal materialization and all six
provisional native row proofs. The cumulative run passes all 17 subgates.

```text
Build Summary: 2/2 steps succeeded
distribution-all success
summary zig-integrated-object pipeline=postopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=6 build_ok=6 run_ok=6 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 failed=0
summary distribution-all-gate-inventory schema_version=1 subgates=17 local_fail=0
summary distribution-all-timing subgates=17 total_duration_ms=2363022 cache_hit_subgates=3 cache_none_subgates=14 fresh_real_rows=false local_fail=0
```

This accepts the exact i64 scalar-select capability and all six bit-exact
native row proofs from `18cd28c4`. The compiler_rt report is now 443 selected /
278 emitting / 165 failing, six accepted closures over the prior 443 / 272 /
171 state, with no collateral emission or new failure. The 75/75 pinned-Zig
row checks include conversion boundaries, signed zeros, subnormals,
infinities, rounding and saturation boundaries, and quiet/signaling NaN
payloads. The add/sub cases also revalidate the standalone scalar-fneg P0
repair.

The gate started at 2026-07-14 17:36:19.403770890 -0500 and completed at
18:03:57.227002926 -0500. Actual wall time was 1,657.823 seconds (27m37.823s).
The separately reported summed child duration was 2,363.022 seconds and
double-counts the three concurrent strict real-row gates; it is not wall
time.

Artifacts:

- preface `tmp/inbox51_select_pipeline_tier3_preface.txt`, sha256
  `6c91169dbf7d9754c22d2878f92d045fe6d66264142780b50be14bc3ddf0b276`;
- accepted full log
  `tmp/distribution_all_after_inbox51_select_pipeline.log`, sha256
  `8bafa7d89f8337ff78176832045c498964ad3f67f327aebe86becd709ecf31b0`;
- focused and native evidence
  `docs/evidence/std_debug_hello_inbox51_select_immediate.md`.

INBOX-51 is complete and accepted. Stop for periodic review #13, which is
also the architectural design discussion for the switch-PHI/EI-conversion
program. INBOX-52 remains queued and is not started in this acceptance cycle.
