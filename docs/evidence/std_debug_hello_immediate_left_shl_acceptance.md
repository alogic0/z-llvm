# Immediate-Left I32 Shift Acceptance

schema_version: 1
directive: `INBOX-34 pre-authorized successor`
target: `x86_64-linux-gnu`
validation_tier: 3
result: pass

Immediate-left variable `shl` now lowers for exactly i32 through the existing
CL-count shift form. The selector materializes the named count in RCX, the
immediate payload in EAX, executes `shl eax, cl`, and binds the i32 result to
EAX. Equivalent i16 and i64 immediate-left forms remain fail-closed at
`composed-block-binary-imm-lhs`; existing immediate-left `lshr` behavior is
unchanged.

Permanent executable coverage checks counts 0, 1, 15, 30, and 31 for the
captured `shl nsw i32 -1, %amount` shape. The exact captured
`compiler_rt.floor_ceil.ceilf` and `compiler_rt.floor_ceil.floorf` bodies emit
into one relocation-free ELF64 object and native-link with `-fno-lld`. A
normal Zig `_start` invokes 52 precomputed-bit checks from `main` and traps on
any mismatch. Inputs cover both zero signs, signed subnormals, values on both
sides of integral boundaries, the f32 mantissa integral boundary, finite
extrema, infinities, and quiet/signaling NaN payloads.

Fresh report-all advances from 443 selected / 230 emitting / 213 failing to
443 selected / 232 emitting / 211 failing. `ceilf` and `floorf` are the only
new emissions.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=232 failed_functions=211 local_fail=1
focused tests: unit=930/930 shift_runtime_calls=5/5 fail_closed_near_misses=2/2 native_floor_ceil_calls=52/52
tier2: pass; steps=24/24 tests=938/938 structural=8/8 assembly/encoding/object inspection=pass integrated_executable=5/5
```

Logs and artifacts:

- `tmp/inbox34_immediate_left_shl_report.log`, sha256
  `8ddc015eb2c587c04694698c5285ffcab50a0e737130650492c4d3f1b0419bf4`;
- `tmp/inbox34_immediate_left_shl_tier2.log`, sha256
  `1ad3cfc11ad60e138b9126f86bd1e87cbf8532c26fb1342a9c8285ee4041229a`;
- `tmp/inbox34_floor_ceil_reference.log`, sha256
  `6e2b63fa3598ca3b09f90929c1259c5f3b9a375c80b2406e49f0d6c4c2e3c96c`;
- `tmp/inbox34_floor_ceil_rows.ll`, sha256
  `16ac2095748c5c2893da83ee412746ed457add2895c4f9d3a444990103396b0d`;
- `tmp/inbox34_floor_ceil_rows.o`, sha256
  `1dec780d4aee8a0690bf84bc7c4358d5f56d5cc701a37f9a8bc7b1761bc69dec`;
- `tmp/inbox34_floor_ceil_rows_readelf.log`, sha256
  `41d940e4b1aa92b0bd9f3ad4e0fc9c1e5f04390cb2cde36fe3ba729c172b7b0e`;
- `tmp/inbox34_floor_ceil_rows_acceptance`, sha256
  `5fcac1d98c1c21d22c7189c71e350c19224fa32b1731582dea306fd03a63fd33`.

Tier 3 acceptance is recorded separately in
`docs/evidence/distribution_all_after_inbox34_immediate_left_shl.md`.
