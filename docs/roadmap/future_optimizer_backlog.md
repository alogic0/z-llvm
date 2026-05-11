# Future Optimizer Backlog

This file holds follow-up optimizer work that is outside the completed active
cycles in `docs/README.md`.

## Value Numbering

- [ ] Replace linear expression scans with full scoped hash buckets once
      expression keys can include all alias-sensitive memory facts without
      missing must-alias equivalents.

## Source-Backed Next Wave

These are not active cycles yet. Promote one item at a time only after selecting
a concrete Zig-emitted fixture or reduced source-backed fixture.

- [ ] Add inline asm and `atomicrmw` IR representation with verifier fail-closed
      rules.
- [ ] Bootstrap vector IR parser/verifier support with explicit target-cost
      boundaries.
- [ ] Split AArch64 optimizer-input policy into target-independent and
      DataLayout-sensitive pass gates.
- [ ] Reduce large Debug-mode Zig IR rows into smaller verifier/metadata
      fixtures.
- [ ] Implement path-aware MemorySSA only when a source-backed fixture shows the
      current conservative scan blocks a required transform.
