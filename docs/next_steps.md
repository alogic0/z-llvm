# Active Direction

Baseline authority is HEAD
`3ef5b07c00959b260d6b8ae6a886d9c91f0bfd82`, tree
`c32a050427055a2b67de49fcee657dd33a014716`.

## Standing boundaries

- All substantive project implementation, generators, validators, codecs,
  hashing, tests, harnesses, process handling, and tooling must be pure Zig
  0.16. Bash is limited to tiny transparent fixed-command orchestration.
- All 43 registered worktrees and `local-state/control` are protected from
  traversal, mutation, cleanup, publication, or use as project state without
  exact user authority.
- DEVELOPMENT remains unstaged. ACCEPTANCE stages and commits only its exact
  reviewed path scope after identity and closure checks.

## Current housekeeping

Replace the two operating ledgers and retire `scripts/inbox_watch.sh`. Stop
after the exact three-path commit and clean tracked-worktree verification.

## Ordered successors

1. Retire inactive Python tooling with a Zig-only replacement or deletion
   proof.
2. Finish cohesive CQ decomposition.
3. Port active ABI shell, C, and assembly project logic to Zig.
4. Review exact inactive roots for bounded cleanup.
