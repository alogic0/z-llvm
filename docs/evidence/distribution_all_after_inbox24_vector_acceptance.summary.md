# Distribution-All After INBOX-24 Vector Acceptance

schema_version: 1
directive: `INBOX-24 acceptance correction`
implementation_commit: `445c03f8`
validation_tier: 3
result: pass

## Pre-Run Record

This is the dedicated, review-visible copy of the Tier-3 preface recorded in
`docs/evidence/std_debug_hello_vector_f64x2_acceptance.summary.md` before the
single INBOX-24 distribution run:

- changed subsystems: composed-selector XMM value representation and register
  allocation, private pair-slot vector spill/reload, machine verifier,
  assembly, and x86_64 encoding;
- Tier-3 trigger: INBOX-24 introduces a new value shape through shared
  selector/register-allocation and verifier/encoder surfaces, and item 7 binds
  one final acceptance run;
- exact command: `zig build distribution-all > tmp/inbox24_distribution_all.log 2>&1`;
- intended log: `tmp/inbox24_distribution_all.log`;
- prior-evidence decision: the previously accepted Tier-3 result predates the
  INBOX-24 implementation and cannot cover the packed XMM location, static
  defined-lane masks, or atomic pair-slot vector spill path.

The run was performed against the complete INBOX-24 implementation tree that
was committed as `445c03f8`; only the evidence result text was finalized after
the run. The saved log SHA-256 is
`590ad907d97a2658ff7c4da84e65c5c5af5c6ef0e53d1c2a395a065787def12d`.

## Result

All 17 subgates passed. The strict 100-row real-row gate passed in
ReleaseFast, ReleaseSafe, and ReleaseSmall. Integrated-object populations
passed postopt 146/146, preopt 146/146, IR-writer 146/146, and
release-source-owned IR-writer 100/100. Native-link probes passed 45/45 and
100/100, and the boundary gates passed.

```text
summary distribution-all-timing subgates=17 total_duration_ms=2300140 cache_hit_subgates=3 cache_miss_subgates=0 cache_mixed_subgates=0 cache_none_subgates=14 slowest_reported=5 fresh_real_rows=false local_fail=0
ok distribution all gates
```

No second run was launched during this correction. The existing log proves
the required result against unchanged relevant inputs, so rerunning would
violate both INBOX-24's one-run bound and the no-rerun rule in
`docs/validation_tiers.md`.
