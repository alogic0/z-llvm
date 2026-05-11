# Cycle 11: DSE Partial-Overwrite and MemorySSA Parity

## Goal

Make DSE precise enough for common Zig stack-memory patterns while preserving
partial-overwrite correctness.

## Plan

- [x] Study LLVM DSE behavior for complete overwrite, partial overwrite,
      lifetime markers, and read-clobber boundaries.
- [x] Add byte-range reasoning for supported memory locations.
- [x] Use MemorySSA clobber walks to find killing stores.
- [x] Add fixtures for complete overwrite, partial overwrite reject, disjoint
      fields, intervening load, unknown call, lifetime start/end, and volatile
      or atomic stores.
- [x] Keep shortening stores or splitting stores deferred unless the byte model
      proves it safe.
- [x] Compare accepted and rejected cases against `opt-22` where behavior is
      expected to match.
- [x] Update DSE and memory-location docs.

## Exit Criteria

- [x] DSE removes at least one source-backed dead stack store.
- [x] Partial-overwrite cases are represented by byte ranges and tested.
- [x] Volatile, atomic, and unknown-call barriers remain safe.

## Completed Slice

Cycle 11 extends DSE fixture coverage around the existing byte-range model:

- complete overwrites still remove the earlier store;
- disjoint field stores do not block same-field overwrite elimination;
- partial-overwrite, intervening load, unknown call, volatile, and atomic
  barriers remain preserving cases.

Store shortening, splitting, lifetime intrinsic handling, and cross-block DSE
remain deferred.
