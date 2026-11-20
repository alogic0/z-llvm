# Distribution-All After INBOX-53 Phase 3

schema_version: 1
directive: `INBOX-53 continuation, phase 3 shared-CFG acceptance`
target: `x86_64-linux-gnu`
status: pass

Committed implementation: `0d0fdb596892571d5d829f622e3fc6035583cc80`.
Committed tree identity before and after the run:
`81b43c4f67e4ba9b029f9fb8203b3287a6157da1`.

Changed subsystem: x86_64 generic-CFG typed switch admission and shared PHI
edge planning/materialization.

Tier-3 trigger: Phase 3 adds a new value path through shared CFG planning and
the parallel PHI-copy authority. The frozen Phase 3 contract requires exactly
one Tier 3 at the phase boundary.

Exact accepted command and log:

```text
zig build distribution-all --summary all > tmp/distribution_all_after_inbox53_phase3.log 2>&1
```

Prior evidence cannot be reused because Phase 2 predates the exact EI switch
admission, six owned switch-edge stubs, and the new three-type executable and
negative canaries. The single run passes all 17 subgates.

```text
Build Summary: 2/2 steps succeeded
distribution-all success
gate-end selected-object-suite exit_status=0 duration_ms=53448
gate-end selected-object-inspection exit_status=0 duration_ms=2218
gate-end selected-native-link exit_status=0 duration_ms=3665
gate-end selected-native-probe exit_status=0 duration_ms=3590
gate-end zig-source-native-link exit_status=0 duration_ms=26715
gate-end integrated-object-postopt exit_status=0 duration_ms=130898
gate-end integrated-object-preopt exit_status=0 duration_ms=545647
gate-end integrated-object-ir-writer exit_status=0 duration_ms=79182
gate-end integrated-object-release exit_status=0 duration_ms=90252
gate-end real-rows-release-fast exit_status=0 duration_ms=359014 cache_status=hit
gate-end real-rows-release-safe exit_status=0 duration_ms=384291 cache_status=hit
gate-end real-rows-release-small exit_status=0 duration_ms=318105 cache_status=hit
gate-end integrated-executable exit_status=0 duration_ms=1955
gate-end release-object-inspection exit_status=0 duration_ms=444
gate-end release-native-link exit_status=0 duration_ms=1040
gate-end release-native-probe exit_status=0 duration_ms=966
gate-end boundary-gates exit_status=0 duration_ms=694
summary distribution-all-gate-inventory schema_version=1 subgates=17 local_fail=0
summary distribution-all-timing subgates=17 total_duration_ms=2002124 cache_hit_subgates=3 cache_none_subgates=14 fresh_real_rows=false local_fail=0
ok distribution all gates
```

The report remains 443 selected / 278 emitting / 165 failing. This accepts
the bounded exact EI entry-switch-edge capability with zero closures, exactly
six honest advances, zero collateral emissions, and zero new failures. Four
f32/f64 EI rows now stop at `composed-block-load-ptr-width`; two half EI rows
now stop at `composed-int-fp-to-type`. Fma remains at its separate switch-PHI
frontier, and x87/fp128 siblings remain at the wall.

The run started at approximately 2026-07-14 20:28:36 -0500 and completed at
20:50:56 -0500. Actual wall time was approximately 1,340 seconds (22m20s).
The separately reported summed child duration was 2,002.124 seconds and
includes concurrent work; it is not wall time.

Artifacts:

- preface `tmp/inbox53_phase3_tier3_preface.txt`, sha256
  `b550cd8440a8a703e6713f4a4921f4d25299f2321bddbfe05a96ec204a489bf5`;
- accepted full log `tmp/distribution_all_after_inbox53_phase3.log`, sha256
  `fb22583cc71eadcc16facbe63de18adf77c7f451c9423e9525b1b3084c1deef5`;
- focused evidence
  `docs/evidence/std_debug_hello_inbox53_phase3_ei_switch_phi.md`.

INBOX-53 continuation Phase 3 is complete and accepted. Stop for review of
the frozen Phase 4 EI loop and narrow-integer-PHI contract. Phase 4
implementation, fma widening, and preopt sharding remain unauthorized.
