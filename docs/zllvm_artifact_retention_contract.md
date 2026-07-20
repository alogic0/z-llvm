# Dormant artifact authority validation contract

This document defines the private Phase-2 validation boundary added by
INBOX-205. It is normative design documentation, not a production input.
The production artifact-store command line, environment, authority
derivation, and call graph do not read this file.

## Status and authority

The accepted source store remains authoritative. The local-state payload is
non-authoritative and control generation `00000001` remains an inert
candidate. Successful synthetic validation does not select that candidate,
activate an authority, create live metadata, or authorize real-candidate
validation.

The validator is private and dormant. Its only current caller is a test in
`tools/zllvm_artifact_store.zig`. It accepts an owned configuration containing
canonical absolute synthetic control, payload, and source roots plus the
expected source-manifest and registered-worktree identities. It owns every
path and identity retained beyond initialization. It exposes no public type,
function, CLI verb, environment variable, selector, callback, or generic
authority API.

## Closed metadata

The following four relative paths are the complete candidate input:

```text
authority/zllvm/v1/manifests/candidate.tsv
authority/zllvm/v1/manifests/generation-00000001.tsv
authority/zllvm/v1/lineage/generation-00000001.tsv
authority/zllvm/v1/receipts/publication/generation-00000001-payload-copy.tsv
```

Each control file must be a no-follow regular file with mode `0644`. The
candidate, lineage, and receipt formats have one exact magic line, one exact
ordered header, one exact field-count row, ASCII-safe canonical fields, LF
termination, and parse/re-encode byte equality. The generation manifest uses
the existing closed v1 manifest parser, relationship validator, and encoder,
and must re-encode byte-for-byte.

The candidate must name generation `00000001`, state `candidate`, the three
exact relative keys, the configured payload and source roots, and exact
hash/size/mode identities. Lineage and receipt identities must match the
candidate before their contents are accepted. Lineage must bind the same
generation manifest and source identity. The receipt must bind the same
source and destination, immutable `0444` payload mode, the verified-copy
result, and payload counts that exactly reconcile to the manifest. The owned
configuration also closes these five receipt identities independently:

```text
source_inventory_sha256
source_file_ledger_sha256
source_destination_ledger_sha256
copy_evidence_path
copy_evidence_sha256
```

The four SHA-256 values are copied into fixed-size owned storage and the
evidence path is allocator-owned. A syntactically valid receipt with any one
of these five fields changed fails as `DormantReceiptMismatched`.

## Root, registration, and destination checks

Dormant admission validates four private roles in fixed order: control,
authority, payload, then source. The exact real-candidate policy owns the
literal paths, role modes, inter-role relations, registered-worktree
snapshot, and control identities for its lifetime:

| Role | Exact path | Mode | Admission |
|---|---|---:|---|
| control | `/home/oleg/prog/z_llvm/local-state/control` | `0775` | exact clean supplemental Git repository; only the four named `0644` files |
| authority | `control/authority/zllvm/v1` | `0755` | intentional containment within control and main; disjoint from every non-main registration |
| payload | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1` | `0755` | the sole reviewed main-contained payload path; disjoint from non-main registrations and supplemental control |
| source | `/home/oleg/prog/z_llvm-artifacts` | `0775` | external identity-only root; disjoint from every main and supplemental registration and every other role |

Before any control-file open, bounded closed-environment `/usr/bin/git`
observations prove the exact control commit, tree, `main` branch, empty
status, empty remotes, and the four-entry NUL-delimited
`authority/zllvm/v1` tree allowlist. Each later control read matches one
allowlisted component and is no-follow with its exact Git mode and accepted
SHA-256/byte/mode identity. No directory discovery supplies an admitted
control key.

Every role requires normalized absolute equality, no-follow ancestry, its
exact mode, and the narrow containment or disjointness rule above. There is
no generic main-descendant exception. Synthetic tests use a distinct
allocator-owned, `builtin.is_test`-closed policy with injected owned control
observations; it cannot select real control, authority, payload, or source
paths. Its negative matrix closes wrong roles and escapes, every root mode,
symlinked ancestry, an unlisted fifth control key, injected non-main or
supplemental-control intersections, and commit/tree/branch/status/remotes/
tree-entry drift. Failures never write, chmod, repair, normalize, discover,
or fall back. Registration full, path, topology, and non-main identities are
captured at configuration creation and revalidated before and after
validation.

The payload root is a closed tree consisting only of:

```text
incoming/
objects/sha256/<two-hex>/<62-hex>
snapshots/sha256/<two-hex>/<62-hex>.tar.zst
```

`incoming/` must be empty. Every directory is no-follow mode `0755`. Every
manifest object and snapshot is present exactly once as a no-follow regular
file with mode `0444`, exact SHA-256, exact byte count, and a traversal-safe
key bound to its digest. Missing entries are partial state; undeclared entries
are extra state; symlinks and non-regular entries are unsafe; identity or mode
differences are mismatches.

## Failure and rollback policy

Validation is read-only. A failure never falls back to another candidate,
mirror, destination, source, or production authority. Errors preserve first
attribution:

```text
DormantCandidate{Missing,Malformed,Mismatched,Unsafe}
DormantGeneration{Missing,Malformed,Mismatched,Unsafe}
DormantLineage{Missing,Malformed,Mismatched,Unsafe}
DormantReceipt{Missing,Malformed,Mismatched,Unsafe}
DormantRegistrationStale
DormantDestination{Partial,Extra,Mismatched,Unsafe}
DormantUnsafeRoot
```

The INBOX-205A synthetic proof deliberately mutates only its fresh private
test root `/tmp/zllvm-inbox205a-authority-dormant-synthetic` and restores each
case before the next assertion. The test-private replacement helper treats
only `FileNotFound` from its replacement-delete as an absent old fixture;
every other deletion error propagates. Explicit deletion remains strict. On
an unexpected test failure, the fresh synthetic roots are retained for
review. On complete success, only roots created by that successful suite are
removed. The retained failed INBOX-205 root and records are never touched.

## Frozen production boundary

`resolveAuthority`, `main`, the `resolve-authority` and `materialize-spec`
command set, `ZLLVM_ARTIFACT_STORE`, the production store selector, all
production callsites, and `build.zig` remain unchanged. No tracked manifest
mirror is required: tests construct a canonical in-memory generation and
synthetic payload tree. Real control and store paths are never passed to the
dormant validator.
