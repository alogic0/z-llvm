# Named Integer Inequality Acceptance

schema_version: 1
directive: `INBOX-34`
target: `x86_64-linux-gnu`
validation_tier: 3
result: pass

Plain named `icmp ne` now lowers for exactly i32 and i64 through the existing
typed scratch-register, compare, and `setne` paths. Named i16 and `samesign`
forms remain fail-closed at `composed-block-icmp-form`.

Permanent executable coverage consumes each width through both branch and
select forms. Four equal/unequal extrema pairs at each width cover both operand
orders. The select results remain i32 so the canary does not broaden the
existing fail-closed i64 immediate-select surface.

The exact captured bodies for `compiler_rt.gedf2.__gedf2`,
`compiler_rt.gesf2.__gesf2`, `compiler_rt.cmpdf2.__cmpdf2`, and
`compiler_rt.comparef.__cmpsf2` emit into one relocation-free ELF64 object,
native-link with `-fno-lld`, and pass 80 calls against precomputed pinned-Zig
results. The matrix covers both zero signs, subnormals, finite ordering in both
directions and equality, finite extrema, infinities, and quiet/signaling NaNs
in both operand positions.

Fix-forward note: the first recorded executable placed `canary_main` directly
in the ELF entry field, so its final `ret` had no startup return address and
segfaulted independently of row semantics. The corrected harness uses Zig's
normal `_start`, calls the same 80 checks from `main`, and traps on any
mismatch. It native-links with `-fno-lld` and exits successfully. The object,
expected-result matrix, Tier 2, and Tier 3 inputs are unchanged; no gate rerun
is required for this evidence-only harness correction.

Fresh report-all advances from the corrected prerequisite baseline 443
selected / 226 emitting / 217 failing to 443 selected / 230 emitting / 213
failing. The four directed rows are the only new emissions.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=230 failed_functions=213 local_fail=1
focused tests: unit=928/928 named_ne_runtime_calls=32/32 fail_closed_near_misses=2/2 native_wrapper_calls=80/80
tier2: pass; steps=24/24 tests=936/936 structural=8/8 assembly/encoding/object inspection=pass integrated_executable=5/5
```

Logs and artifacts:

- `tmp/inbox34_named_ne_corrected_report.log`, sha256
  `12c0ce4fcf0715ff5d468c18e7f11b4c15765d0688a8352020ef3d0a16fe3839`;
- `tmp/inbox34_named_ne_tier2.log`, sha256
  `37d2391ea0125e80c43a0cf8c31a757567772176ae20873bc33ab50dcfcd390e`;
- `tmp/inbox34_compare_reference.log`, sha256
  `1330d03d337fe3e07d658d5a302c8263c3ec48992df862c2fe3edc59d612ae74`;
- `tmp/inbox34_compare_rows.ll`, sha256
  `24692319c87d4b2bc6665334cf6e8dbc05053d41d15567af7826ca158a1ca23a`;
- `tmp/inbox34_compare_rows.o`, sha256
  `00e590b4ee59ef4a12ad855cb2b78dabc05d712007bf27827955627fda2047d1`;
- `tmp/inbox34_compare_rows_readelf.log`, sha256
  `605023554a0eab522eb75d009ebdc5aaeb827bf01cc47c7dda7ca7826ed4dd23`;
- `tmp/inbox34_compare_rows_acceptance`, sha256
  `aae6c1bc2ce816ea088309e5f23759ca30451562abeae5c7f08cc149cd9132dc`.

Tier 3 acceptance is recorded separately in
`docs/evidence/distribution_all_after_inbox34_named_integer_inequality.md`.
