# INBOX-139 — durable spill-key ownership amendment

Status: implementation and required validation complete; stopped for
Supervisor/Reviewer review. The change is dormant: no production lowering,
dispatch, diagnostic, or bypass inventory changed. The residual ratchet remains
166. No performance, Tier 2, or Tier 3 command was run.

## Frozen basis and preservation boundary

```text
working_head=92e560c587a4ee74c7867fbf0da56c8db9bf1d80
working_tree_before_amendment=4d6326050442adc3ee281ec666220b1644a106a3
accepted_unwired_B4_pre=068f586b
ratchet=166 (unchanged)
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7 (untouched)
original_wiring_patch_sha256=39aa6d5331a0d404bc1b8aca6372e3927314e1044c5b56788c01a1bd86c1dba5
second_stop_patch_sha256=8ab26a97f2337790338025fcee0c8f296430abdf7320ae03588ca6fdff60b9ef
third_stop_patch_sha256=3f3e46ff0fd9b92a40287840716853c1dda70a3f90220107d3301598051f035d
B4_stop_patch_sha256=f2b29a6064cd864a717952e73b0f573ac96516a8f701e6ed26527664f6e7a7a6
performance_run=none
tier2=not_run
tier3=not_run
```

All four patch carriers and `stash@{0}` remained untouched and unapplied.

## Durable spill-slot boundary

`allocateSpillSlot` and `allocatePairSpillSlots` now share one private
`insertOwnedSpillSlot` boundary. The incoming slice is used for lookup only.
An existing entry returns its existing assignment without capacity growth or
allocation. For a new entry, both maps reserve capacity, the selector allocator
duplicates the identity, and only that owned slice is installed as the
`spill_slots` key. The same slice is registered in
`owned_spill_slot_keys`, whose value is the sole allocation owner.

Both the standalone accumulator rollback and the outer value-use rollback call
`restoreSpillSlots`. It first finds selector-owned keys absent from the
pre-transaction snapshot, removes the speculative spill entry, removes its
ownership record, and frees the owned slice exactly once. It then restores the
snapshot assignments using their still-live original backing. Commit performs
no ownership transfer or cleanup; committed keys remain selector-owned until
selector teardown, which frees every ownership-record value exactly once.

Relevant post-change source hashes:

| source | SHA-256 |
|---|---|
| `composed_selector_state_data.zig` | `6172eb7a8af7ccb9177cbf2c5d41e4822a44db0963e9956c6822fb57706cc7b7` |
| `composed_selector_state.zig` | `6133798fd12668f41ebe4b8c7cfe73d1ed86f3824ffa624b65174538b7d0dd1f` |
| `value_use/core.zig` | `8d4221bdde74f697d5c16f819c2458511f7663bb550da67fa747d964386cedf1` |
| `scalar_arithmetic_immediate_tests.zig` | `aa7d9a3c722aa6cf7d13393469e96ef8ac8cad39cdb774dc809a7eb93ca06df7` |
| `source_guard/residual_policy.zig` | `2d2f5bb6f33a4ae5ad181d0be8712e490047d59aaa6eeb498012abc02654cc26` |

## Selector durable identity-map audit

This is a classification audit, not a blanket-copy rule.

| container | insertion sites | backing lifetime and owner | duplicate/replacement behavior | rollback | commit / teardown | classification |
|---|---|---|---|---|---|---|
| `values` | `putValueBinding`; O1 and O2 snapshot restoration | Function parameters, instruction results, and PHI names borrow immutable parsed-IR storage, which outlives selection. Internal/action results first pass through `ownedInternalValueName`, `ownActionIdentity`, or `ownRegisteredOperandName`; their allocator-owned slices are retained in `MachineFunction.owned_labels`. Alias/preservation updates reuse an existing map key. | `putValueBinding` updates an existing binding without replacing its key backing; a new action identity is owned before insertion. | O1/O2 snapshots contain borrowed references to the same IR- or machine-owned backing; restoration does not free keys. Speculative owned action identities are freed by the existing owned-label rollback after instructions are truncated. | IR keys outlive the selector; owned action/internal names are freed by machine teardown. | safe mixed borrowed/explicitly-owned |
| `abi_pointer_params` | `bindParams` | `ir.Param.name`, immutable IR-owned | duplicate is idempotent; no replacement payload | no speculative production insertion | map storage deinit only; key backing remains IR-owned | safe borrowed |
| `readonly_pointer_params` | `bindParams`; successful readonly GEP propagation | Parameter or instruction-result name from immutable IR | duplicate idempotent | the admitted propagation occurs on completed lowering; no transaction-local name is accepted | map storage deinit only; IR owns key | safe borrowed |
| `phi_results` | PHI preallocation in `composed_selector_impl.zig` | PHI result identity from immutable IR | duplicate idempotent | created before instruction lowering transactions | map storage deinit only; IR owns key | safe borrowed |
| `phi_destinations` | PHI preallocation; preservation destination refresh | PHI/result name from immutable IR; refresh iterates an existing `values` key | replacement updates the location and retains key backing | outer value-use snapshot restores the same IR-owned key references | map storage deinit only; IR owns key | safe borrowed |
| `overflow_results` | accepted overflow call lowerers | Aggregate call-result name from immutable IR | duplicate form is rejected by lowering semantics; extraction mutates value state and removes after both lanes | these residual O1 paths are outside the value-use action population; no transaction-local identity is inserted | removal drops only the map entry; IR owns key; remaining entries disappear at selector deinit | safe borrowed |
| `spill_slots` | only `insertOwnedSpillSlot`, reached by scalar and pair allocation | selector-owned duplicated slice registered before map insertion | lookup happens first; duplicate allocates nothing and retains existing backing/assignment | `restoreSpillSlots` removes speculative entry and ownership record, then frees exactly once before restoring snapshot | committed entry retained; selector teardown frees owned key through owner registry | fixed: selector-owned |
| `owned_spill_slot_keys` | only `insertOwnedSpillSlot`, immediately before the spill-map insertion | its value is the sole selector-side owner of the same durable slice used by both maps | duplicate path never reaches insertion; no replacement | `fetchRemove` returns the sole owned value, which is freed once | value iterator frees every committed key once, then registry/map storage deinit | new ownership registry |
| `address_dependencies` | `replaceAddress` through `putValueBinding` | not a hash map: owner/base/index/addend identities are copied into fixed inline `Identity.bytes` storage | atomic copy/replace; duplicate/cycle/role errors fail closed | whole-domain snapshot value restores inline storage atomically | embedded selector state; no borrowed identity lifetime | safe inline-owned |

No other selector-side identity-keyed durable container exists. Allocation-plan
maps are plan-owned immutable inputs whose lifetime encloses selector use;
`MachineFunction.owned_labels` is an owning sequence rather than an
identity-keyed container and already supplies rollback/teardown ownership for
action/internal names.

## Guard and focused regressions

The guard enforces the insertion boundary structurally:

- raw `spill_slots.put`/`putAssumeCapacity` is rejected in every other
  production file;
- the state authority must perform lookup, reserve both maps, duplicate the
  incoming name, register ownership, and insert the owned key in that order;
- both scalar and pair allocators must call the boundary exactly once;
- rollback must remove the spill entry, remove ownership, free once, then
  restore the snapshot;
- selector state-data must contain the matching owner-map init/free/deinit
  lifecycle.

Negative fixtures reject a borrowed incoming slice installed at the boundary,
a direct insertion outside the authority, and rollback with the key free
removed.

The 1,325-test unit suite adds focused proofs for:

- a transient stack key whose caller bytes are overwritten immediately after
  insertion;
- allocator churn plus 64 later insertions forcing map growth/rehash, followed
  by successful old-key lookup and a later insertion;
- duplicate lookup with exactly zero allocations;
- rollback before insertion with no ownership activity;
- standalone rollback after insertion with exactly one allocation/free;
- an outer value-use rollback after a subordinate accumulator spill with
  exactly one allocation/free and full state restoration;
- commit, transaction teardown, churn, rehash, and a later transaction while
  the committed key remains valid.

The focused production canaries provide the required real `__multi3` and `fma`
shapes: both object/stream/symbol validation and all 35 executable cases pass.

## Validation

Every retained log is paired with its exact command.

### Full unit and source guard

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox139_durable_spill_key/validation/full_unit.log
result=7/7_steps,1325/1325_tests
log_sha256=d61c3991262e9ba59c19c734badcb3b5b421666fdacb6c99d8f0aa8ec5d99c71
```

### Required plain-path ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox139_durable_spill_key/validation/abi_differential.log
result=5/5_steps,60/60_cases,30/30_real_functions
log_sha256=8ed8d411fc4ce4dd187a87ffeb8d5148682c40d0d7107d314266b376a58511e0
```

### Standing focused canary gate

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox139_durable_spill_key/validation/focused_canaries.log
result=2/2_canaries,35/35_execution_cases,__multi3_object_stream_symbol_green,fma_object_stream_symbol_helpers_green,no_host_libc_substitution
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

### Frozen report

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox139_durable_spill_key/validation/fresh_full_report.log
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
```

### Accepted object and owner projection

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox139_durable_spill_key/validation/accepted.o 2> tmp/inbox139_durable_spill_key/validation/accepted.stderr
accepted_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
stderr_bytes=0

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox139_durable_spill_key/validation/owner_manifest.tsv 2> tmp/inbox139_durable_spill_key/validation/owner_manifest.stderr
owner_manifest_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_breakdown=composed_block:40,composed_cfg:127,legacy_envelope:17,structural_fallback:101
owner_ledger=167/17/101
stderr_bytes=0
```

No performance, strengthened Tier 2, or Tier 3 command was run. B4/B5 remains
parked and is not authorized by this amendment.
