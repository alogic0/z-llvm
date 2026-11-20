# INBOX-63 Selection-Atomicity Repair

schema_version: 1
directive: `INBOX-63`
target: `x86_64-linux-gnu`
status: provisional-accepted; review requested
baseline: `eb1d77fdf1a1faaa3c539d8334476dc1b4e6a505`

## Repair

`generic_cfg_selector.zig` now has one `SelectionTransaction` authority for
both composed-block and composed-CFG speculation. It snapshots the instruction
and owned-label lengths, the complete `MachineFunction` value, and transaction
state before selection. Rollback truncates speculative instructions, frees
only labels appended after the snapshot, truncates the label list, and restores
`name`, `ret_ty`, `codegen_path`, and the complete
`entry_xmm_defined_bits`. A compile-time field audit rejects an unclassified
future `MachineFunction` field; a future `selection_owner` is explicitly
classified and restored without adding that field in this slice.

The wrappers defer rollback for unsupported and mapped-error results, use
`errdefer` for propagated errors, and commit only for `.selected`. The old
instruction-only outer rollback was removed, leaving the transaction as the
single rollback authority. No owner field or manifest, capability admission,
row movement, ratchet, or mandatory summary changed.

## Permanent Negatives

Two public-selector tests seed an existing `.ud2`, two allocator-owned labels,
`.generic_cfg`, all eight XMM entry-definedness values, and the function
identity/type. They then prove exact seeded-state restoration, including
pointer identity for retained labels:

- an unsupported-after-mutation case binds a `double`, prepares a frame and
  owned epilogue label, then stops at `composed-block-select-width`;
- a mapped-error case performs the same ABI/frame mutations, raises
  `UnsupportedCodegenValue`, maps it to `stage2-unsupported-value`, and rolls
  back before returning the diagnostic.

Both use `std.testing.allocator`; final `MachineFunction.deinit` therefore
turns any speculative-label leak or retained-label double-free into a test
failure.

## Strengthened Tier 2 And Frozen Cohort

The strengthened Tier-2 command passed 24/24 build steps and 1034/1034 tests,
covering full unit tests, structural smoke, assembly/objdump/readelf
comparisons, object/executable/debug/ReleaseSafe distributions, permanent
canaries, and the seven-case real executable boundary including fma:

```text
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump
  compare-codegen-readelf distribution-object distribution-executable
  distribution-debug-object distribution-debug-executable
  distribution-releasesafe-object distribution-zig-integrated-exe --summary all
```

The fresh whole-capture report is unchanged and exact:

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=285 failed_functions=158 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```

For byte identity, the 158 exact failing alias targets from the accepted report
were removed from the frozen capture, leaving the complete 285-row accepted
selection cohort. The accepted pre-repair executable and repaired executable
each independently reported 285/285/0 and emitted an aggregate ELF object.
Both objects have SHA-256
`061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be`
and compare byte-for-byte.

Artifacts:

- Tier 2 `tmp/inbox63_tier2.log`, SHA-256
  `d9f2f7110c9dc0e2a1951647b2816796d330938d504b75afe45649b0514e5553`;
- report `tmp/inbox63_report.log`, SHA-256
  `49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`;
- accepted objects `tmp/inbox63_accepted_before.o` and
  `tmp/inbox63_accepted_after.o`, identical SHA-256 as above.

The required one serial Tier 3 is recorded separately in
`distribution_all_after_inbox63_selection_atomicity_repair.md`.

INBOX-63 is acknowledged. Stop after provisional acceptance and request
review; O0 has not restarted and O1, other slices, and sharding remain
unauthorized.
