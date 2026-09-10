# Local artifact storage

The artifact store is a local data-integrity component. The user and local tools
are trusted. Its contract covers partial writes, corruption, concurrent storage
operations, and accidental filesystem escapes. Historical INBOX authority,
worktree-topology, system-binary-hash, permission-bit, and supplemental-control
repository requirements are retired by the 2026-09-10 simplification.

## Layout and commands

The default root is `local-state/artifacts`; `ZLLVM_ARTIFACT_STORE` overrides it.
Paths are resolved from the invoking working directory. The root contains:

```text
objects/<sha256>
manifests/<run-id>.json
incoming/
store.lock
```

Use the pinned project compiler:

```sh
zig build artifact-store -- publish manifest.json source-directory
zig build artifact-store -- pin manifest.json  # restore a manifest for existing objects
zig build artifact-store -- verify
zig build artifact-store -- get SHA256 output-file
zig build artifact-store -- gc --pins docs/evidence/artifacts
zig build artifact-store -- gc --delete --pins docs/evidence/artifacts
zig build artifact-store-test
```

`get` never overwrites an existing output. The former `resolve-authority` and
`materialize-spec` commands are retired. Existing snapshots are retained
as ordinary immutable objects; storing new artifacts does not require tar/zstd.

## Manifest

A version-1 JSON manifest contains `schema`, `run_id`, `command` (an argv array),
`source_revision`, `compiler`, `result`, and `artifacts`. Optional `inputs`
contains unique named input identities (source pins, target, mode, corpus or
encoding versions); old manifests omit it. Every artifact has a
relative `name`, lowercase SHA-256, and byte count. Names identify source files
under the publication source directory and allow reconstruction of retained runs.
Duplicate JSON fields, duplicate artifact names, conflicting sizes, unknown
fields, invalid identities, and traversal paths are errors.

All local manifests pin their referenced objects. Preserve accepted manifests
in `docs/evidence/artifacts/` as well; the store copy and tracked copy use the
same schema. Pass `--pins docs/evidence/artifacts` during collection to protect tracked
manifests even if a local manifest was accidentally removed. The pins directory
is opened explicitly and checked under the same lock; it may contain non-JSON
evidence files. Missing or corrupt pinned objects abort collection. Without
`--pins`, only local manifests protect objects. Removing the last referencing
manifest from both locations makes an object collectible.

## Integrity and collection

A nonblocking exclusive OS lock serializes publication, verification, retrieval,
and collection. A busy store reports `WouldBlock`; no stale lock-file removal is
needed after a crashed process. The lock is released by closing its file handle.

Objects are streamed into atomic files, checked against their expected content,
synchronized, and published without replacement. Existing objects must verify.
A manifest is published only after all referenced objects verify. Published
objects are read-only to discourage accidental changes; exact ancestor modes
are not part of identity. Directory traversal uses no-follow component opens.

Collection first validates all manifests and pinned objects and constructs its
complete candidate list. Malformed state aborts before deletion. Extra
unreferenced objects and abandoned regular files in `incoming/` are candidates;
symlinks and unexpected entries are errors. Dry-run is the default. Application
uses the same store lock and synchronizes changed directories.

Only the store's owned object/incoming directories are collected. Project
worktrees, source files, validation directories, and unrelated caches are not
recursively discovered or deleted by the store.

## Migration record

The original 20 objects/snapshots and generation ledger were imported and
content-verified under `legacy-generation-00000001`. The tracked JSON manifest
preserves their original source-relative names. Legacy Git control history and
old development worktrees are retained on `preserved/cleanup-20260910/*` refs.
The cleanup evidence report records removed roots and remaining consumers.
Historical evidence documents describe old operations and do not reinstate the
retired authority protocol.

Source snapshots already reachable through ordinary Git refs are listed in
`docs/evidence/artifacts/git-backed-sources-20260910.tsv`. Retrieve those with
`git cat-file blob GIT_BLOB_ID`; the map retains the original name, SHA-256 and
byte count. The two `retained-*-minimal` manifests supersede the initial retention
manifests and pin only payloads that still need object storage. No supplemental
Git repository or duplicate archive is involved.
