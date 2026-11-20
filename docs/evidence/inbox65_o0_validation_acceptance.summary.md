# INBOX-65 O0 Validation-Only Acceptance

schema_version: 1
directive: `INBOX-65`
target: `x86_64-linux-gnu`
status: accepted; review requested
validated_head: `a72ca77d` (docs-only authorization above O0 code state
`6ee8bd4e`)

INBOX-65 is acknowledged by id. This continuation made no implementation,
selector, test, manifest, or fix-forward change. It ran the strengthened Tier
2 and reconfirmed the frozen report, accepted object, and owner manifest. No
Tier 3 was run, as required.

## Strengthened Tier 2

The accepted command passed 24/24 build steps and 1034/1034 tests:

```text
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump
  compare-codegen-readelf distribution-object distribution-executable
  distribution-debug-object distribution-debug-executable
  distribution-releasesafe-object distribution-zig-integrated-exe --summary all
```

This includes the complete unit and structural suites, assembly/objdump/readelf
comparisons, object and executable distributions, permanent executable
canaries, and the seven-case real executable boundary. The real boundary
reported 7/7 build, run, stdout, and exit matches, including the compiler-rt
i128, fma, setcc, aggregate-SSE-return, and three syscall rows.

- log: `tmp/inbox65_tier2.log`
- log SHA-256:
  `328e797985a5fdb26a4d8747f2ee11f73e8194c70f5ec5f455f5f3893b1baffd`

## Complete Captured Cohort And Diagnostics

The fresh whole-capture report over all 443 selected rows is exact:

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=285 failed_functions=158 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```

The 159-line report is byte-identical to the accepted INBOX-63 report.

- report: `tmp/inbox65_report.log`
- report SHA-256:
  `49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`

The frozen complete accepted cohort has input SHA-256
`d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4`
and independently reported 285 selected / 285 emitted / 0 failed. Its newly
emitted aggregate ELF object is byte-identical to both accepted INBOX-63
objects:

- object: `tmp/inbox65_accepted.o`
- accepted-object SHA-256:
  `061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be`

## Owner Manifest And Corrected Ledger

The fresh manifest is byte-identical to the frozen INBOX-64 manifest:

- fresh manifest: `tmp/inbox65_selection_owner_manifest.tsv`
- frozen manifest:
  [`inbox64_selection_owner_manifest.tsv`](inbox64_selection_owner_manifest.tsv)
- SHA-256:
  `5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d`

| Owner | Rows |
| --- | ---: |
| `composed_block` | 40 |
| `composed_cfg` | 127 |
| `legacy_envelope` | 17 |
| `structural_fallback` | 101 |
| `unassigned` | 0 |
| **Successful total** | **285** |

O0 is accepted. The aggregate **167 composed / 17 legacy / 101 fallback** is
the corrected canonical live owner ledger and supersedes the historical
165 / 17 / 103 estimate.

Stop after this validation-only acceptance and request review. O1, other
O-slices, harness promotion, X1 stages, preopt sharding, and Tier 3 remain
unauthorized.
