# Distribution-All After Accumulator Alias P0 Repair

schema_version: 1
directive: `self-declared P0 while executing INBOX-45`
target: `x86_64-linux-gnu`
status: pass

Implementation identity before the run: committed baseline `7c76c391` plus
staged production and permanent-test tree
`c42c91a6a607455e72166a38fa59a82eaf579b37`; the staged diff has sha256
`3693312fd90563946b627753217273b9bebddf0b85dd68ff348b620592910427`.

Changed subsystem: x86_64 composed-selector scalar immediate-binary lowering
and accumulator value-location liveness.

Tier-3 trigger: confirmed wrong-code repairs require immediate Tier 3 under
`docs/validation_tiers.md`.

Exact accepted command and log:

```text
zig build distribution-all > tmp/distribution_all_after_inbox45_accumulator_alias_p0_retry.log 2>&1
```

Prior evidence cannot be reused because every accepted Tier 3 predates the
repair that preserves every live accumulator alias across destructive
immediate integer operations. The executable regression proves that the
accepted baseline silently changed a still-live truncation source value.

The first invocation used an isolated worktree under `/tmp` and failed before
codegen at strict-row AIR export because tracked candidate paths are relative
to a repository beside `../ziglang`. It is retained as failed environmental
evidence, not relabeled. The unchanged staged tree was moved to the correct
sibling layout. A narrow ReleaseFast retry then passed 100/100 lower, object,
and native-link rows with 1,373,715,837 descriptor bytes. The full retry passed
all 17 subgates.

```text
summary zig-integrated-object pipeline=postopt total=146 executable_ok=146 local_fail=0
summary zig-integrated-object pipeline=preopt total=146 executable_ok=146 local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 failed=0
summary distribution-all-timing subgates=17 total_duration_ms=3305701 cache_hit_subgates=1 cache_miss_subgates=2 cache_none_subgates=14 local_fail=0
ok distribution all gates
```

Artifacts:

- preface `tmp/inbox45_accumulator_alias_p0_tier3_preface.txt`, sha256
  `35b5e4b633557e99b51467f707d40009b14250b8e01527fe1ec277af3f35d836`;
- failed environmental invocation
  `tmp/distribution_all_after_inbox45_accumulator_alias_p0.log`, sha256
  `c8d766b0fc77f11ce682ec906e703dc5a7e79e04ca0bad18f6b787ebc7935b73`;
- narrow recovery
  `tmp/inbox45_accumulator_alias_p0_real_rows_retry.log`, sha256
  `dda84d005dba4b6767228742ea6b63da97276fa23ee7d2e1665fe1ccae570efc`;
- accepted full retry
  `tmp/distribution_all_after_inbox45_accumulator_alias_p0_retry.log`, sha256
  `e6489ad79d6d8f753d92122afba8aded493313c1e87d73446855d01e374e8b06`.
