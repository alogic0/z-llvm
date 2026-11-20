# Distribution-All After INBOX-48 Bit-Permutation Leaves

schema_version: 1
directive: `INBOX-48 successor cumulative acceptance`
target: `x86_64-linux-gnu`
validation_tier: 3
status: pass

Implementation identity before the run: committed baseline
`bfbcdf1236229852bcc7e1ed41482aaf0459785a`, with clean committed tree
`23bf5cbdba0d9296c15f9baf7121527022c68a86`.

Changed subsystem: exact x86_64 bit-permutation intrinsic selection, existing
pair-spill frame reservation for the i128 leaves, the `bit_reverse_rax`
machine instruction and its encoding/assembly, and verifier result tracking.
The admitted calls remain exactly `llvm.bswap.i128`, `llvm.bitreverse.i64`,
and `llvm.bitreverse.i128`.

Tier-3 trigger: `docs/validation_tiers.md` requires Tier 3 for selector,
frame, machine-encoding, and verifier shared surfaces. INBOX-48's successor
contract requires one cumulative Tier 3 at the bit-permutation pipeline end.

Exact command and evidence log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox48_bit_permutation.log 2>&1
```

Prior evidence could not be reused because the INBOX-48 PHI result predates
all three exact intrinsic forms, the i128 pair-spill reservation, the new RAX
machine operation, and its encoding/assembly/verifier coverage. The preface
was recorded before the single invocation in
`tmp/inbox48_bit_permutation_tier3_preface.txt`, sha256
`030c330035052c6a654a528801cdf2b9ece729bb7b01903134787f43fb4ccbc0`.

The invocation passed all 17 subgates. Selected native-link inspection and
probes remain 45/45. Integrated objects remain 146/146 for postopt, preopt,
and IR-writer pipelines. Release-source-owned integrated objects remain
100/100. Strict real rows remain 100/100/100 in ReleaseFast, ReleaseSafe, and
ReleaseSmall. Integrated executables remain 6/6. Release-source object
inspection, native linking, and native probes remain 100/100 each. Boundary
gates are green.

This cumulative result accepts the three exact native-proven compiler_rt
closures from the focused evidence:

- `compiler_rt.bswap.__bswapti2`;
- `compiler_rt.bitreverse.__bitreversedi2`;
- `compiler_rt.bitreverse.__bitreverseti2`.

The accepted compiler_rt report state is now 443 selected / 264 emitting /
179 failing. Focused evidence proves that these are exactly the three report
changes, with no collateral emission or new failure:
`docs/evidence/std_debug_hello_inbox48_bit_permutation.summary.md`.

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
summary distribution-all-timing subgates=17 total_duration_ms=2281518 cache_hit_subgates=3 cache_none_subgates=14 fresh_real_rows=false local_fail=0
ok distribution all gates
```

The reported total is 2,270 ms (0.10%) below the INBOX-48 PHI total of
2,283,788 ms. This is not a material runtime change. The slowest uncached
subgate remains integrated preopt at 548,039 ms; all three strict real-row
subgates reported cache hits.

Log: `tmp/distribution_all_after_inbox48_bit_permutation.log`, sha256
`459aee06fb1a2b5ad0b04aaa91b69327aefcb3bc1cf171f9d55083a194a0e533`.
