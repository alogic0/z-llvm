# INBOX-155 — dormant forward-Q1 structural admission

Status: complete for review. This slice adds the private forward-source
admission path and its exact structural staleness proof. It does not wire a
production consumer: B03–B07 remain routed to their accepted legacy paths,
the direct-resolution ratchet remains **152**, and no performance or Tier 3
command was run.

## Baseline and scope

The accepted INBOX-154 code is
`cbb532acde85b046c661619ea55f44650107b8a8`, tree
`b003f7fa693b2ce2b22c899d415e68f9f901cdd9`. Work was completed from the
tracked amended authorization HEAD
`76c1562cbcaf4cdaf9c6eadb921169af95047710`, tree
`65c42e0d43cf83e9cb22256b3d96a1bf8f89673f`.

The implementation changes only the selector-owned forward resolver, the
private value-use transaction model/planning/materialization path, tests, and
source guards. No composed scalar lowering or dispatch file changed. In
particular, no B03–B07 consumer opens the new path.

## Closed authority

Current bindings retain the pre-INBOX-155 Q1 path exactly:

```text
binding + no allocation plan       -> ValueUseSourcePlanMissing
binding + plan but no interval     -> ValueUseSourceIntervalMissing
valid interval ending at current   -> available for consumption
valid interval ending before now   -> ValueUseExpiredSource
```

Only a named request with no current binding enters forward admission.
Typed integers and typed null pointers remain binding-lifetime exempt.
Admission requires a canonical `ForwardValuePlan` and validates:

- request/forward-entry identity;
- allocation-plan identity;
- current, definition, and interval positions;
- virtual class and defined width;
- physical assignment tag/payload and spill frame extent;
- the selector-owned forward resolver's result;
- the complete canonical address-dependency facts consulted by liveness.

The request-attributable error table is closed:

| Condition | Error |
|---|---|
| no canonical plan, entry, or interval | `ValueUseForwardPlanMissing` |
| malformed definition or dependency metadata | `ValueUseForwardPlanMalformed` |
| plan replacement, entry removal, or any captured-fact change | `ValueUseForwardPlanStale` |
| valid interval not covering current | `ValueUseForwardIntervalExpired` |
| class, defined-width, or assignment-class mismatch | `ValueUseForwardTypeMismatch` |
| missing physical assignment | `ValueUseForwardAssignmentMissing` |
| bounded dependency proof exceeds capacity | `ValueUseForwardSnapshotCapacityExceeded` |

There is no forward-path fallback to `ValueUseUnresolvedSource`.
`failedRequestIs` retains the first precise request at every admission and
materialization boundary; authority-level failures remain unattributed.

## Exact structural snapshot

`ForwardAdmissionSnapshot` is private transaction state. It contains copied
fixed-size identities and scalar/enum facts only:

```text
plan identity
request/forward identity
admission position
definition position
interval end
virtual class
defined width
assignment tag and payload
spill frame extent when applicable
canonical dependency owners, edges, roles, types, intervals, and binding facts
```

The transaction owns inline storage for all 16 request slots. The dependency
proof has an explicit four-owner capacity, with up to the canonical
three dependencies per owner; overflow fails before mutation. The snapshot
contains no borrowed slice, `ValueLoc`, mutable plan-entry pointer, digest,
planner generation, runtime callback, or heap allocation.

One canonical capture function is used at both boundaries. Admission captures
and stores the snapshot. Every later request validation re-fetches the
canonical plan entry, captures the same structure again, and requires exact
field equality before the selector-owned forward resolver can return a
current home. No binding or assignment is created at seal. Materialization
always re-resolves from canonical selector state and never carries a
pre-mutation `ValueLoc`.

The source guard freezes:

- the exact snapshot field set, inline capacity, and closed error table;
- the one canonical capture function and the capture/equality/store sequence;
- the sole selector-owned error-bearing forward resolver;
- absence of borrowed locations, hashes, or invented generations;
- absence of raw forward-resolution calls in production consumers.

## Coverage

The focused tests prove:

- valid register- and spill-assigned forward requests, with no selector
  binding created at seal, materialization, rollback, or teardown;
- all six frozen B07 shapes, including three register and three spill
  assignments;
- current-binding missing-plan/missing-interval behavior is unchanged;
- the complete closed error table and exact first-request provenance;
- independent changes to request identity, current position, definition
  position, interval, class, width, assignment tag, assignment payload,
  spill frame extent, entry presence, and allocation-plan pointer;
- unchanged dependency metadata succeeds, while an admitted dependency
  edge/binding change is stale and malformed dependency metadata is closed;
- explicit dependency-snapshot capacity overflow;
- duplicate requests for one forward identity;
- rollback before and after materialization, snapshot restoration, and
  transaction teardown without borrowed identity/location state.

The production-path diagnostic fixtures that formerly expected the generic
unresolved error now pin the distinct no-forward-plan error. This is a test
expectation update only; the corresponding production consumers remain
legacy-routed.

## Decisive identities

Commands:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox155_o2_forward_q1_dormant/validation/fresh_full_report.log

command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox155_o2_forward_q1_dormant/validation/accepted.o 2> tmp/inbox155_o2_forward_q1_dormant/validation/accepted.stderr

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox155_o2_forward_q1_dormant/validation/owner_manifest.tsv 2> tmp/inbox155_o2_forward_q1_dormant/validation/owner_manifest.stderr

command=/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- tmp/inbox151_o2_family_isolation/results/baseline/accepted.o tmp/inbox155_o2_forward_q1_dormant/validation/accepted.o > tmp/inbox155_o2_forward_q1_dormant/validation/function_diff.tsv
```

Results:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report=443 selected / 285 emitted / 158 failed
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=167 composed / 17 legacy / 101 structural
accepted_stderr_bytes=0
owner_stderr_bytes=0
per_function=285 compared / 0 divergent / 0 missing
per_function_log_sha256=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
```

## Correctness gates

Every command below ran after the final code and test change. Logs are
retained under `tmp/inbox155_o2_forward_q1_dormant/validation/`.

### Source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig 2>&1 | tee tmp/inbox155_o2_forward_q1_dormant/validation/source_guard.log
result=52/52 passed
log_sha256=afce097d11ff32508e741aee845e294343961217ea1b11461acb71d5acdac818
```

### Full unit

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox155_o2_forward_q1_dormant/validation/full_unit.log
result=7/7 steps; 1353/1353 tests
log_sha256=0ce4a3b5b49da655ed726198c2492b0e1941bebec677a87088cec289e5b5c69e
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox155_o2_forward_q1_dormant/validation/abi_differential.log
result=5/5 steps; 60/60 cases; 30/30 real functions
log_sha256=9578093ba2d96ef5bd81d29e31b106ecefdc11a6ea352028d1ef0b0ca5c86626
```

### Focused codegen canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox155_o2_forward_q1_dormant/validation/focused_canaries.log
result=2/2 canaries; 35 executable cases; fma and __multi3 object/stream/symbol/helper checks exact
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

### Integrated executable

```text
command=/home/oleg/bin/zig build distribution-zig-integrated-exe --summary all 2>&1 | tee tmp/inbox155_o2_forward_q1_dormant/validation/integrated_exe.log
result=2/2 steps; 7/7 build/run/stdout/exit
log_sha256=0b9a00b84979e9e442c87470f353de361e92b336d3e447cbed35dc7ea1d89a92
```

### Strengthened Tier 2

```text
command=/home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all 2>&1 | tee tmp/inbox155_o2_forward_q1_dormant/validation/strengthened_tier2.log
result=29/29 steps; 1361/1361 tests
log_sha256=a3392e13a402527ce494a10da9bd93b4f7527ea6b3d8db270efec061b016ebcb
```

No performance command, `distribution-all`, or Tier 3 command was run.
`stash@{0}` and all preserved carriers/patches remain untouched.
