# INBOX-66 Serial Tier-3 Stop Evidence

Directive: `INBOX-66`

Status: **implementation and mandatory Tier 2 pass; unaccepted serial Tier-3 stop**

Implementation commit: `193dea9c1d48120e92a79309e25c4aacc39f5d14`

Date: 2026-07-15

## Outcome

The promoted audited compiler-rt ABI gate and its mandatory Tier-2 integration
passed. The one authorized serial Tier-3 run then passed subgates 1 through 16
and stopped in subgate 17, `boundary-gates`, because
`tools/run_distribution_linker_boundary.zig` still requires the pre-O0 CLI
usage string. No second Tier 3, focused boundary rerun, fix-forward, O1 work,
or other unauthorized slice was started.

This is not an object, report, owner, or route-identity movement. Commit
`6ee8bd4e` added the accepted O0 emit mode `selection-owner-manifest` to the
real help line, but did not update the older boundary assertion. The actual
and expected prefixes are:

```text
actual:   usage: z_llvm [--emit=ir|asm|obj|ir-writer|semantic-descriptor|selection-owner-manifest]
expected: usage: z_llvm [--emit=ir|asm|obj|ir-writer|semantic-descriptor]
```

The stale expectation is `tools/run_distribution_linker_boundary.zig:25`
(introduced by `258c2e5b`); the accepted O0 help change is
`src/main_flow.zig:26` at `6ee8bd4e`. The boundary gate failed closed before
printing `gate-end index=17`. Changing that assertion is deliberately absent
from this stop commit and requires review before any acceptance continuation.

## Mandatory Tier 2

The strengthened Tier-2 command completed at the clean implementation commit:

```text
Build Summary: 28/28 steps succeeded; 1034/1034 tests passed
```

The mandatory `abi-diff-v2` summaries were:

| Mode | Cases attempted | Cases matched | Real functions matched |
| --- | ---: | ---: | ---: |
| ReleaseFast | 20 | 20 | 10 |
| ReleaseSafe | 20 | 20 | 10 |
| ReleaseSmall | 20 | 20 | 10 |
| **Total** | **60** | **60** | **30** |

The controlled ReleaseSafe panic and all seven negative controls passed. The
ten real compiler-rt functions remain the only ABI cohort; none of these
counters is presented as execution of the separate 100 compiler-core rows.
The integrated real-program boundary remained 7/7.

Tier-2 log:

```text
tmp/inbox66_tier2.log
sha256 f79d6ce661ceb8b516bbc04f5c38f00a21c48c86f75ddb51fd486b718660f55f
```

## Frozen identities

All pre-Tier-3 movement guards passed:

| Evidence | Result | SHA-256 |
| --- | --- | --- |
| compiler-rt report | 443 selected / 285 emitted / 158 failed; first failure `compiler_rt.trunc.truncl`, `UnsupportedLongDoubleAbi`, `unsupported-return-type` | `49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681` |
| complete accepted object | byte-identical | `061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be` |
| owner manifest | composed_block 40 / composed_cfg 127 / legacy_envelope 17 / structural_fallback 101 / unassigned 0 / total 285 | `5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d` |

The accepted live aggregate owner ledger therefore remains 167 / 17 / 101.

## Headroom preflight

The fresh `df` sample reported 119,283,638,272 bytes free. The report-only
retention inventory reported `deleted=0` and 119,283,634,176 bytes free. The
refined serial-start requirement was 53,531,114,292 bytes, including the
49,112,001,332-byte reserve.

```text
df evidence sha256        bede580e074754ee117947944e021352a2952eb335364a9bdfc49af60a279959
retention report sha256   bfb3f9a63bbd7e855c4fa3ebca4eb8af15c10f9b1f13a9ecdf30a010951c45af
```

## Serial Tier-3 evidence

Subgates 1 through 16 passed. This includes all three
`distribution-real-rows-v2` modes with the separate compiler-core population
at exactly:

```text
candidate_rows=100
real_functions_lowered=100
real_objects_emitted=100
real_native_linked=100
real_executed=0
real_programs_ok=0
local_fail=0
```

The integrated executable remained 7/7. The release-source bundle was produced
once with 100 rows and identity
`a5dcce564ade761f3cf47c9767f69615cdadbe0d6c2cc88419efaaf52e9518fa`,
then reused by inspection, native link, and native probe; inspection and probe
both accepted all 100 rows.

The 17 per-subgate headroom checks ranged from 119,283,535,872 bytes at the
first sample to 115,209,342,976 bytes before the failed boundary subgate. The
observed decrease was 4,074,192,896 bytes and every sample remained above the
49,112,001,332-byte reserve.

```text
tmp/inbox66_serial_tier3.log
sha256 24c31b28553eef9b9aea56e22e326a9b9f86049348c1765f4679363921c57e03
clean gate-end records: 16
failed subgate: 17 boundary-gates
```

## Stop State

`INBOX-66` is acknowledged in commit `193dea9c`, but it is **not accepted**
because its required serial Tier 3 did not complete 17/17. The implementation,
mandatory Tier 2, frozen identities, population separation, versioned counters,
headroom preflight, and first 16 Tier-3 subgates are green. The only observed
failure is the stale pre-INBOX-64 help-string assertion described above.

Review is requested before any boundary-test correction or validation
continuation. O1, O2-O6, X1 implementation, preopt sharding, and every other
slice remain unauthorized and unstarted.
