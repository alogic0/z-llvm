# Cycle 4: Target Features And Function Attributes Normalization

## Goal

Normalize the function attributes and target-feature strings present in
Zig-emitted IR enough that they no longer block source-backed corpus acceptance,
without turning target modeling into a broad CPU database project.

## Source Anchors

- Captured IR attributes: `"target-cpu"`, `"target-features"`,
      `"frame-pointer"`, `memory(...)`, `uwtable`
- Corpus rows: FP and current ReleaseFast captures
- Local docs: `docs/unsupported_ir.md`, `docs/target_datalayout.md`
- Local code: parser/printer attribute preservation and verifier rules

## Plan

- [x] Inventory raw function and module attributes in accepted and unsupported
      Zig captures.
- [x] Preserve target feature strings textually where semantic interpretation is
      not required.
- [x] Verify only attributes that affect local optimizer correctness, such as
      memory effects and call purity.
- [x] Add parser tests for accepted textual preservation and fail-closed tests
      for attributes that require unsupported semantics.
- [x] Update target and unsupported docs with the exact accepted attribute
      subset.
- [x] Avoid target-specific cost modeling, vector feature decisions, and CPU
      scheduling claims.

## Exit Criteria

- [x] Existing source-backed captures are not blocked by harmless target-feature
      spelling.
- [x] Optimizer-relevant attributes are either interpreted conservatively or
      rejected.
- [x] Attribute docs distinguish textual preservation from semantic support.
