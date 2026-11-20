# Serial Distribution-All After INBOX-63 Atomicity Repair

schema_version: 1
directive: `INBOX-63`
target: `x86_64-linux-gnu`
status: pass

Changed subsystem: fail-closed generic-CFG selection transaction and its two
permanent negative tests.

Tier-3 trigger: repair of a confirmed shared selector correctness invariant.
Earlier Tier-3 evidence is not reusable because selection rollback source and
observable unsupported/error behavior changed.

The stock runner overlaps the three real-row modes. To satisfy the revised
serial policy, `tmp/inbox63_serial_tier3.sh` invoked the same 17 commands in
the same order, but one child at a time, with a shared release-source bundle
and a reserve check before every child. No sharding, fresh AIR export, or
concurrent cache producer ran.

All 17 subgates have a matching successful `gate-end` record. Highlights:

```text
summary zig-integrated-object pipeline=postopt ir_writer=false total=146 executable_ok=146 link_only_ok=0 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=false total=146 executable_ok=146 link_only_ok=0 local_fail=0
summary zig-integrated-object pipeline=preopt ir_writer=true total=146 executable_ok=146 link_only_ok=0 local_fail=0
summary release-source-object-bundle status=produced rows=100 identity=a5dcce564ade761f3cf47c9767f69615cdadbe0d6c2cc88419efaaf52e9518fa atomic_publication=true local_fail=0
summary distribution-real-rows mode=ReleaseFast limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSafe limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary distribution-real-rows mode=ReleaseSmall limit=100 real_functions_lowered=100 real_objects_emitted=100 real_native_linked=100 local_fail=0
summary zig-integrated-exe total=7 build_ok=7 run_ok=7 stdout_ok=7 exit_ok=7 compiler_rt_fma_rows=1 local_fail=0
summary native-link-object-inspection inventory=release-source-owned inspected=100 elf64_rel=100 undefined_import_rows=0 local_fail=0
summary distribution-native-link inventory=release-source-owned total=100 executable_abi_proof_rows=100 local_fail=0
summary native-link-probe inventory=release-source-owned accepted=100 failed=0
ok inbox63 serial tier3
```

## Headroom Samples

Bytes free immediately before each child:

| Index | Subgate | Free bytes |
| ---: | --- | ---: |
| 1 | `selected-object-suite` | 119978582016 |
| 2 | `selected-object-inspection` | 119918383104 |
| 3 | `selected-native-link` | 119906742272 |
| 4 | `selected-native-probe` | 119895203840 |
| 5 | `zig-source-native-link` | 119883653120 |
| 6 | `integrated-object-postopt` | 119872847872 |
| 7 | `integrated-object-preopt` | 119854436352 |
| 8 | `integrated-object-ir-writer` | 120342151168 |
| 9 | `integrated-object-release` | 120341491712 |
| 10 | `real-rows-release-fast` | 120340717568 |
| 11 | `real-rows-release-safe` | 120284225536 |
| 12 | `real-rows-release-small` | 120282861568 |
| 13 | `integrated-executable` | 120281559040 |
| 14 | `release-object-inspection` | 120281559040 |
| 15 | `release-native-link` | 120281542656 |
| 16 | `release-native-probe` | 120281530368 |
| 17 | `boundary-gates` | 120281546752 |

Final free space was `120229638144` bytes. Authoritative reconstruction over
the 17 pre-child records plus the final record gives starting free
`119978582016`, minimum sampled free `119854436352`, and sampled peak
`124145664` bytes. The policy formula refines the projected serial incremental
peak to `4419112960` bytes.

The raw log's terminal `summary inbox63-serial-tier3` minimum/peak fields are
invalid and non-authoritative: the wrapper initialized its shell minimum with
an unsigned-64 maximum that overflowed Bash's signed arithmetic. Every source
sample above is intact, all gate results precede that aggregation, and the
reproducible wrapper now initializes the minimum from its first sample. The
gate was not rerun. Raw log `tmp/inbox63_serial_tier3.log` is preserved
byte-for-byte at SHA-256
`05076492c34230e1485dccbcdc79cf291c9154a6633717d48f9ebf22ef9c5b21`.

INBOX-63 is acknowledged. This is the directive's one serial Tier 3. Parallel
sharding was not started.
