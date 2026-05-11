# Cycle 11: DSE Partial-Overwrite and MemorySSA Parity

## Goal

Make DSE precise enough for common Zig stack-memory patterns while preserving
partial-overwrite correctness.

## Plan

- [ ] Study LLVM DSE behavior for complete overwrite, partial overwrite,
      lifetime markers, and read-clobber boundaries.
- [ ] Add byte-range reasoning for supported memory locations.
- [ ] Use MemorySSA clobber walks to find killing stores.
- [ ] Add fixtures for complete overwrite, partial overwrite reject, disjoint
      fields, intervening load, unknown call, lifetime start/end, and volatile
      or atomic stores.
- [ ] Keep shortening stores or splitting stores deferred unless the byte model
      proves it safe.
- [ ] Compare accepted and rejected cases against `opt-22` where behavior is
      expected to match.
- [ ] Update DSE and memory-location docs.

## Exit Criteria

- [ ] DSE removes at least one source-backed dead stack store.
- [ ] Partial-overwrite cases are represented by byte ranges and tested.
- [ ] Volatile, atomic, and unknown-call barriers remain safe.
