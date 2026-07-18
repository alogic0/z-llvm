# INBOX-158 — dormant B07 named-RHS action amendment

Status: complete and stopped for review. This slice changes only the private
named-scalar action implementation, its co-located tests, and the source
guard. `scalar_named_b07_rhs_admission` remains the production owner, the
direct-resolution ratchet remains 148, and no B07 production consumer was
wired.

## Amendment

The accepted forward-Q1 authority already captures semantic named requests
without a current binding and creates a prepared record from either:

- the current binding and its generation; or
- the canonical transaction-owned forward-admission snapshot.

The remaining B07 gap was a private action-layer check in
`validateNamedSource`: after Q1 had admitted and prepared the request, it
read `selector.values` again. That second lookup incorrectly required a
current binding and rejected a canonical forward RHS.

The action now validates the Q1-produced prepared record's virtual class
and defined width. It still validates the named semantic identity, expected
integer width, canonical prepared home, and closed B07 plan. It does not
retain or expose a `ValueLoc`, inspect a consumer-selected home, invoke a
forward resolver, retry, or fall back.

The source guard rejects both recurrence paths inside
`actions/scalar_named.zig`:

```text
transaction.selector.values.get(...)
resolveForwardValueForUse(...)
```

Thus transaction Q1 remains the sole current-binding-versus-forward
admission authority. There is no public request/facade change:

```text
facade_manifest_sha256=9c38e682ff462204ba63a0ab30a9e7f56927ed51ba577dffd710c4222e01a0f8
value_use_model_sha256=eb989e6cb6e8aa9645387751a1839ab751741f96484b6fc3f3cb6dd0d3fdb649
lifetime_admission_sha256=35bb4d9f12bd372063692aa9cb55333ce06b47b39d0964d13be7bd121e20b1b6
composed_selector_scalar_sha256=c9069ce43fcebad595ee997164e6791728d3f18e1cffefa6b876e566b8f93bb0
```

The action leaf is 752 lines, below its 2,000-line hard ceiling.

## Focused coverage

The co-located scalar-named tests prove:

1. All six frozen B07 cohort shapes by exact function identity:
   - `compiler_rt.floatuneidf.__floatuneidf`;
   - `compiler_rt.floatuneisf.__floatuneisf`;
   - `compiler_rt.floatuneihf.__floatuneihf`;
   - `compiler_rt.floateidf.__floateidf`;
   - `compiler_rt.floateisf.__floateisf`;
   - `compiler_rt.floateihf.__floateihf`.
2. The three unsigned shapes use the canonical register-assigned forward
   RHS and retain the exact `sub rax,r9` stream.
3. The three signed shapes use the canonical spill-assigned forward RHS
   and retain the exact spill reload followed by `sub rax,rcx`.
4. No forward RHS acquires a `selector.values` binding at seal,
   materialization, commit, or teardown.
5. Existing current-binding B07 accumulator topology cases remain exact.
6. Malformed forward metadata fails at seal with RHS provenance.
7. A changed forward assignment after seal fails stale before emission
   with RHS provenance.
8. Failure after the arithmetic write rolls back instructions, bindings,
   result ownership, and EFLAGS records exactly.
9. The two-request lhs/rhs case retains first-request attribution: the
   valid lhs is not blamed for an invalid or stale RHS.
10. The existing B03, B04, B05, and B06 closed-family table still checks
    their exact instruction streams. The fresh accepted-cohort object
    identity below re-proves every landed production occurrence.

The guard negative proves a scalar action cannot restore either direct map
admission or a private forward-resolution channel.

## Production boundary and ratchet

`lowerBinary` still dispatches B07 directly to:

```text
scalar_named_b07_rhs_admission
```

No transaction is opened on that production route. The frozen bypass row
is unchanged:

```text
composed_selector_scalar.zig scalar_named_b07_rhs_admission
  emitBinaryLocIntoAccumulator×1
  emitValueIntoScratch×2
  emitValueIntoScratchAndRelocate×1
  resolveValue×4
```

The bypass inventory SHA-256 remains
`e588e8087a61f934fef863dc6ae1b2e3062d1ed118ba13ae5188114c3cda95b2`.
No helper-collapse credit is claimed:

```text
ratchet_before=148
direct_removals=0
helper_collapses=0
ratchet_after=148
```

Fresh B07 isolation is required by a later directive before any production
wiring.

## Exact production identities

Commands:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox158_o2_b07_action_dormant/validation/fresh_full_report.log

command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox158_o2_b07_action_dormant/validation/accepted.o 2> tmp/inbox158_o2_b07_action_dormant/validation/accepted.stderr

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox158_o2_b07_action_dormant/validation/owner_manifest.tsv 2> tmp/inbox158_o2_b07_action_dormant/validation/owner_manifest.stderr
```

Results:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report=443 selected / 285 emitted / 158 failed
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=167 composed / 17 legacy / 101 structural
frontier_rows=6
accepted_stderr_bytes=0
owner_stderr_bytes=0
```

Because production B07 remains legacy-routed, the exact whole report,
accepted object, and owner manifest also re-prove that B03-B06 and every
previously accepted production stream remain byte-identical.

## Required gates

All logs are retained under
`tmp/inbox158_o2_b07_action_dormant/validation/`.

### Full unit

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox158_o2_b07_action_dormant/validation/full_unit.log
result=7/7 steps; 1356/1356 tests
log_sha256=bfcea0d85cc86b10e102e198aa3db4eb7c0e3457c9ecd09b41079fce2c24cd2a
```

### Source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig 2>&1 | tee tmp/inbox158_o2_b07_action_dormant/validation/source_guard.log
result=53/53 tests
log_sha256=9c553d8756d84d0f14fe3c65c35f4aa1dc3430c056bf497d77ca3adc32d69895
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox158_o2_b07_action_dormant/validation/abi_differential.log
result=5/5 steps; 60/60 cases; 30/30 real functions
log_sha256=2ee4e1b0ff068642559975e6254049637c1a9e63de0ef455735f0f3597672b3c
```

### Focused codegen canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox158_o2_b07_action_dormant/validation/focused_canaries.log
result=2/2 canaries; 35 executable cases; fma and __multi3 exact
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

No performance command, `distribution-all`, or Tier 3 command was run.
