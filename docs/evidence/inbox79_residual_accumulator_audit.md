# INBOX-79 residual accumulator audit

This audit is frozen at the accepted commit-6 code state `324fa993` and the
docs-only INBOX-79 dispatch HEAD `627de956` (tree
`a3a0f7ce2a415ca9bb3d2faee4902f43889b0de3`). It covers every production
consumer call to `bindEax`, `bindRax`, `bindAccumulator`,
`clobberAccumulator`, and `bindValueLoc` in `composed_selector_*.zig`.
Definitions and internal implementation calls inside the sole state authority,
`composed_selector_state.zig`, are authority implementation rather than
producer bypasses and remain governed by the existing raw-state boundary.
White-box `_tests.zig` sources are fixtures, not production sites.

The executable canonical inventory is
`residual_accumulator_allowlist` in
`composed_selector_source_guard_tests.zig`. Every entry records source file,
enclosing function, operation, structural role, classification, owning future
slice, and exact expected count. The hardened validator uses Zig tokenization
and balanced braces to discover the actual body containing each occurrence;
it does not retain a last-seen function declaration. An operation outside all
closed function bodies fails closed.

The normalized `residual_function_fingerprints` table adds 46 enforced
SHA-256 anchors for the exact function bodies containing the 48 residual
groups and 8 architectural-exclusion groups. Every allowlist entry must resolve
to one of these anchors. Moving an operation to another semantic branch within
the same function changes the body fingerprint even if its function-level
operation count is unchanged. Missing, duplicate, malformed, mismatched, and
orphaned fingerprints fail closed.

## Result

There are 48 function/operation groups and 72 exact occurrences, with zero
unclassified sites:

| Classification | Groups | Occurrences | Future slice |
| --- | ---: | ---: | --- |
| `internal_temporary` | 18 | 26 | none |
| `alias_only_binding` | 15 | 19 | none |
| `approved_pair_rdx_exclusion` | 4 | 4 | `pair_rdx_authority` |
| `non_accumulator_result_path` | 11 | 23 | none |
| **Total** | **48** | **72** | |

No ordinary EAX/RAX result producer remains outside
`AccumulatorDefinitionTransaction`. The direct bind operations below only
record an already-produced specialized result or a no-emission alias. Direct
clobbers are internal transport/materialization temporaries, specialized
non-ordinary paths, or an approved pair/RDX exclusion.

## Exact function-scoped residuals

| File | Function | Operation (count) | Structural role | Classification | Future slice |
| --- | --- | --- | --- | --- | --- |
| aggregate | `lowerInsertValue` | `bindValueLoc` (3) | fixed aggregate-SSE result | `non_accumulator_result_path` | none |
| calls | `lowerFpAbs` | `clobber_accumulator` (1) | GPR mask temporary for XMM result | `internal_temporary` | none |
| calls | `lowerUnsignedOverflowI32` | `clobber_accumulator` (1) | aggregate overflow flag after value relocation to RDX | `approved_pair_rdx_exclusion` | `pair_rdx_authority` |
| calls | `lowerSmulOverflowI64` | `clobber_accumulator` (1) | full-product RAX/RDX overflow flag | `approved_pair_rdx_exclusion` | `pair_rdx_authority` |
| calls | `lowerCtpop` | `clobber_accumulator` (1) | i128 pair limb accumulation | `approved_pair_rdx_exclusion` | `pair_rdx_authority` |
| calls | `lowerBitPermutation` | `clobber_accumulator` (1) | i128 pair limb permutation | `approved_pair_rdx_exclusion` | `pair_rdx_authority` |
| cfg | `lowerSelect` | `bind_accumulator` (1) | post-arm select alias | `alias_only_binding` | none |
| cfg | `emitScalarSelectValue` | `clobber_accumulator` (1) | select immediate-arm materialization | `internal_temporary` | none |
| cfg | `restoreDisplacedPhiDestinations` | `bindValueLoc` (1) | computed PHI destination restoration | `alias_only_binding` | none |
| cfg | `emitPhiEdgeMoves` | `bindValueLoc` (1) | computed PHI edge destination | `alias_only_binding` | none |
| cfg | `materializeScalarPhiSnapshot` | `clobber_accumulator` (3) | copy-through-accumulator PHI snapshot | `internal_temporary` | none |
| cfg | `emitValueIntoLoc` | `clobber_accumulator` (4) | PHI scratch/spill materialization | `internal_temporary` | none |
| conversion | `lowerUnsignedI64` | `clobber_accumulator` (1) | integer-to-FP XMM-result temporary | `internal_temporary` | none |
| conversion | `lowerWideInteger` | `clobber_accumulator` (1) | wide-integer-to-FP XMM-result temporary | `internal_temporary` | none |
| fp | `lowerHalfFadd` | `bindValueLoc` (1) | fixed XMM0 half result | `non_accumulator_result_path` | none |
| fp | `lowerCopySign` | `clobber_accumulator` (1) | GPR mask temporary for XMM result | `internal_temporary` | none |
| fp | `materializeFpValue` | `clobber_accumulator` (1) | FP immediate transport | `internal_temporary` | none |
| fp | `lowerFcmp` | `clobber_accumulator` (2) | specialized FP compare preparation | `internal_temporary` | none |
| fp | `lowerFcmp` | `bind_eax` (1) | alias after specialized FP setcc | `alias_only_binding` | none |
| fp | `lowerHalfOeqZero` | `clobber_accumulator` (1) | specialized half-zero compare preparation | `internal_temporary` | none |
| fp | `lowerHalfOeqZero` | `bind_eax` (1) | alias after specialized half-zero setcc | `alias_only_binding` | none |
| fp | `lowerHalfFcmp` | `clobber_accumulator` (2) | specialized half conversion/compare | `internal_temporary` | none |
| fp | `lowerHalfFcmp` | `bind_eax` (1) | alias after specialized half setcc | `alias_only_binding` | none |
| fp | `lowerFpIntBitcast` | `clobber_accumulator` (1) | FP-to-integer transfer preparation | `internal_temporary` | none |
| fp | `lowerFpIntBitcast` | `bind_eax` (1) | EAX alias after FP bit transfer | `alias_only_binding` | none |
| fp | `lowerFpIntBitcast` | `bind_rax` (1) | RAX alias after FP bit transfer | `alias_only_binding` | none |
| fp | `lowerFloatToHalf` | `bindValueLoc` (1) | fixed XMM0 half conversion result | `non_accumulator_result_path` | none |
| fp | `lowerHalfExtension` | `bindValueLoc` (1) | fixed XMM0 extension result | `non_accumulator_result_path` | none |
| frame | `prepareStackFrame` | `bindValueLoc` (4) | fixed stack object/pointer bindings | `non_accumulator_result_path` | none |
| impl | `bindParams` | `bindValueLoc` (5) | fixed incoming ABI bindings | `non_accumulator_result_path` | none |
| impl | `bindPhiResults` | `bindValueLoc` (3) | computed planned PHI destinations | `alias_only_binding` | none |
| impl | `stabilizeFramedPhiDestinations` | `bindValueLoc` (1) | computed stabilized PHI destination | `alias_only_binding` | none |
| impl | `enterBlock` | `bindValueLoc` (1) | computed predecessor PHI location | `alias_only_binding` | none |
| memory | `lowerLoad` | `bindValueLoc` (1) | fixed stack128 aggregate load | `non_accumulator_result_path` | none |
| memory | `lowerStoreFp` | `clobber_accumulator` (2) | FP store address/value transport | `internal_temporary` | none |
| memory | `lowerGep` | `bindValueLoc` (1) | fixed stack i32 pointer | `non_accumulator_result_path` | none |
| memory | `lowerI32ElementPointerGep` | `bindValueLoc` (2) | fixed stack element pointers | `non_accumulator_result_path` | none |
| memory | `lowerBytePointerGep` | `bindValueLoc` (3) | fixed stack/readonly byte pointers | `non_accumulator_result_path` | none |
| memory | `lowerReadOnlyTableGep` | `bindValueLoc` (1) | fixed readonly-table pointer | `non_accumulator_result_path` | none |
| memory | `loadStackU64IntoRax` | `clobber_accumulator` (1) | stack-to-RAX helper with no result bind | `internal_temporary` | none |
| scalar | `lowerCast` | `bindValueLoc` (1) | computed no-emission cast alias | `alias_only_binding` | none |
| scalar | `lowerFreeze` | `bindValueLoc` (1) | computed no-emission freeze alias | `alias_only_binding` | none |
| vector | `lowerMask4ToI4` | `clobber_accumulator` (1) | specialized mask extraction preparation | `internal_temporary` | none |
| vector | `lowerI64x2ExtractElement` | `clobber_accumulator` (1) | specialized lane extraction preparation | `internal_temporary` | none |
| vector | `lowerI64x2ExtractElement` | `bind_rax` (1) | alias after vector lane transfer | `alias_only_binding` | none |
| vector | `lowerMaskExtractElement` | `clobber_accumulator` (1) | specialized mask-lane preparation | `internal_temporary` | none |
| vector | `bindMaskScalarResult` | `bind_accumulator` (3) | alias-only mask scalar result | `alias_only_binding` | none |
| vector | `materializeLaneBits` | `clobber_accumulator` (1) | lane immediate transport for XMM result | `internal_temporary` | none |

## Generic computed-location capability

All 32 production `bindValueLoc` occurrences are included in the table. The
sites capable of receiving a computed EAX/RAX location are exactly the
alias-only rows in:

- `cfg.restoreDisplacedPhiDestinations` and `cfg.emitPhiEdgeMoves`;
- `impl.bindPhiResults`, `impl.stabilizeFramedPhiDestinations`, and
  `impl.enterBlock`;
- `scalar.lowerCast` and `scalar.lowerFreeze`.

The remaining generic sites construct fixed XMM, stack, pointer, aggregate, or
incoming ABI locations and are classified `non_accumulator_result_path`.

## Explicit architectural exclusions

The source guard has a second exact function-scoped allowlist for the
predeclared non-ordinary result APIs. These 8 groups / 11 occurrences all belong
to the not-yet-authorized `pair_rdx_authority` slice:

| File | Function | Exclusion operation (count) | Structural role |
| --- | --- | --- | --- |
| scalar | `lowerUnsignedRem` | `urem_rdx_result` (1) | unsigned remainder result bound in RDX |
| calls | `lowerSmulOverflowI64` | `full_product_rax_rdx` (1) | fixed signed full product in RAX/RDX |
| calls | `lowerCtpop` | `pair_result` (1) | i128 population count |
| calls | `lowerBitPermutation` | `pair_result` (1) | i128 bit permutation |
| calls | `lowerAbsI128` | `pair_result` (1) | i128 absolute value |
| scalar | `lowerBinaryImmediateLhs` | `pair_result` (1) | i128 immediate-LHS arithmetic |
| scalar | `lowerPairBinary` | `pair_result` (4) | i128 binary arithmetic variants |
| scalar | `lowerCast` | `pair_result` (1) | integer-to-i128 cast |

This makes the urem RDX result, full-product RAX/RDX, and every current direct
pair-result binding explicit and relocation-sensitive rather than relying on a
comment or a file-wide count. These exclusion functions use the same enforced
body fingerprints as the residual accumulator inventory.

## Enforcement fixtures

White-box tests prove:

- adding a second residual operation to an otherwise allowlisted function is
  rejected with `ResidualAccumulatorOccurrenceMismatch`;
- removing an allowlisted operation is rejected with
  `ResidualAccumulatorOccurrenceMismatch`;
- relocating an allowlisted `bindValueLoc` operation to another function is
  rejected with `UnallowlistedResidualAccumulatorOperation`;
- relocating an operation to a different branch within the same function,
  while preserving its count, is rejected with
  `ResidualFunctionFingerprintMismatch`;
- placing an operation after the prior function's closing brace is rejected
  with `ResidualAccumulatorOperationOutsideFunction` rather than attributed to
  the prior declaration;
- reclassifying an allowlisted clobber into a bind operation is rejected with
  `UnallowlistedResidualAccumulatorOperation`;
- approving a pair/RDX exclusion without `pair_rdx_authority` ownership is
  rejected with `ResidualExclusionMissingFutureSlice`;
- the fully classified production tree passes the exact allowlists with zero
  unclassified sites.

## INBOX-79 enforcement-hardening follow-up

The focused guard validation passed all 13 source-guard tests, including the
same-function semantic-branch relocation and outside-closed-body regressions:

```text
zig test src/inbox79_source_guard_focused.zig --test-filter 'composed selector source guard'
All 13 tests passed.
```

`src/inbox79_source_guard_focused.zig` was a temporary project-root test shim
used only to preserve the normal `src/` module boundary; it was removed before
the final diff. The full unit root then passed without invoking the build
step's ABI dependency:

```text
zig test src/tests.zig
All 1091 tests passed.
```

The follow-up changes only
`composed_selector_source_guard_tests.zig` and documentation. No production
emitter, mandatory runner, canary, ABI, cohort, Tier-2, or Tier-3 path changed
or ran. The accepted emission evidence therefore remains valid by
construction, with frozen identities `49a19f04` / `443-285-158-truncl` /
`061a64e4` / `5d91960e` / `167-17-101`.
