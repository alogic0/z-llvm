# Current State

- Accepted baseline HEAD: `3ef5b07c00959b260d6b8ae6a886d9c91f0bfd82`.
- Accepted baseline tree: `c32a050427055a2b67de49fcee657dd33a014716`.
- Production counters for ReleaseFast, ReleaseSafe, and ReleaseSmall:
  `100/100/100/3/3`, `local_fail=0`.
- Bypass ratchet: `130`.
- CQ is an inert baseline decomposed through Store extraction. Its public facade
  remains 7,203 lines; it has no activation, authoritative receipt, real
  external-state, performance, or ratchet credit.
- All 43 registered worktrees and `local-state/control` remain protected.
- Current objective: reset the operating ledgers and retire
  `scripts/inbox_watch.sh`.
- Immediate successor: retire inactive Python tooling through a Zig-only
  replacement or deletion proof.
