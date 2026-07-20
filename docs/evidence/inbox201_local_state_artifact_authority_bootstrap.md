# INBOX-201 Empty Artifact-Authority Destination Bootstrap

## 1. Scope and disposition

This bounded bootstrap starts from exact operating commit
`936bbc4d21cd827fb5022f4a505cf2f28769ab20`, parent
`b82bf29f05dd2a4a82eaa4e2ba1b9186523d2462`.

It created exactly seven empty directories for a prospective local-state
artifact payload authority. It copied no payload, inspected no current-store
descendant, modified no control-repository byte, and created no validation,
cache, worktree, repository, marker, symlink, or compatibility path.

The empty destination is not authoritative. The current authority remains
`/home/oleg/prog/z_llvm-artifacts` until a later separately authorized and
accepted non-destructive copy-and-verify migration.

## 2. Frozen preflight

All preflight conditions passed before the first creation:

```text
main_head=936bbc4d21cd827fb5022f4a505cf2f28769ab20
main_parent=b82bf29f05dd2a4a82eaa4e2ba1b9186523d2462
main_status=clean
control_head=a41690a4c47cf1040afe3d4dd3679a77015263ea
control_tree=67582eb6f4de0b3ab3a2ef2e7c3635c79349d00e
control_status=clean
main_registered_worktrees=43
control_registered_worktrees=1
protected_union=44
effective_uid=1000
effective_gid=1000
ratchet=131
```

Each of the seven authorized paths was absent in every node form, including
symlink, before creation. The following also remained absent:

```text
/home/oleg/prog/z_llvm/local-state/validations
/home/oleg/prog/z_llvm/local-state/worktrees
/home/oleg/prog/z_llvm/local-state/caches
/home/oleg/prog/z_llvm-baseline-validation-v3
/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3
```

The anchored ignore proof before creation was:

```text
command=git -C /home/oleg/prog/z_llvm check-ignore -v local-state/artifacts/zllvm-authority-v1/objects/sha256/probe
output=.gitignore:30:/local-state/	local-state/artifacts/zllvm-authority-v1/objects/sha256/probe
```

Frozen named-file identities were:

```text
tracked_live_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
artifact_tool_sha256=94dfc1fc27ffe1268eb02453bcac1a3634aa11af38d0c94fbaa3b43decd25859
contract_sha256=d445f6a45f039415052cb0fb1efc71b1975f2ea68d28e3637aede503145fc387
pins_sha256=1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
audit_sha256=5a7e019eb107e5b66947490a65fdf47444154fc4f1483ca30ab0fc6e381f33e6
watcher_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash_object=7985c6d01040a6e47e4ce5b918866d0e89517ac7
```

The authoritative `/home/oleg/prog/z_llvm-artifacts` was not enumerated,
entered, traversed, descendant-statted, or rehashed.

## 3. Exact one-pass creation order

Each command created one previously absent directory with explicit mode
`0755`. Every creation was immediately checked for real no-follow directory
type, mode `0755`, UID `1000`, and GID `1000` before the next command.

| Order | Exact path |
|---:|---|
| 1 | `/home/oleg/prog/z_llvm/local-state/artifacts` |
| 2 | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1` |
| 3 | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1/objects` |
| 4 | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1/objects/sha256` |
| 5 | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1/snapshots` |
| 6 | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1/snapshots/sha256` |
| 7 | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1/incoming` |

There was no retry, repair, `chmod`, `chown`, cleanup, alternate path, or
second creation attempt.

## 4. No-follow filesystem identities

All seven targets are real directories, not symlinks:

| Order | Exact path | Type | Mode | UID | GID | Device | Inode |
|---:|---|---|---:|---:|---:|---:|---:|
| 1 | `/home/oleg/prog/z_llvm/local-state/artifacts` | directory | `0755` | 1000 | 1000 | 66306 | 53514285 |
| 2 | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1` | directory | `0755` | 1000 | 1000 | 66306 | 53514326 |
| 3 | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1/objects` | directory | `0755` | 1000 | 1000 | 66306 | 53514329 |
| 4 | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1/objects/sha256` | directory | `0755` | 1000 | 1000 | 66306 | 53514341 |
| 5 | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1/snapshots` | directory | `0755` | 1000 | 1000 | 66306 | 53514342 |
| 6 | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1/snapshots/sha256` | directory | `0755` | 1000 | 1000 | 66306 | 53514358 |
| 7 | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1/incoming` | directory | `0755` | 1000 | 1000 | 66306 | 53514359 |

The exact named ancestry was no-follow verified:

| Ancestor | Type | Mode | UID | GID | Device | Inode |
|---|---|---:|---:|---:|---:|---:|
| `/home` | directory | `0755` | 0 | 0 | 66306 | 50331649 |
| `/home/oleg` | directory | `0750` | 1000 | 1000 | 66306 | 50462721 |
| `/home/oleg/prog` | directory | `0775` | 1000 | 1000 | 66306 | 50760518 |
| `/home/oleg/prog/z_llvm` | directory | `0775` | 1000 | 1000 | 66306 | 53517090 |
| `/home/oleg/prog/z_llvm/local-state` | directory | `0775` | 1000 | 1000 | 66306 | 53513919 |

No ancestor or target was a symlink.

## 5. Exact bounded shape

Enumeration was limited to the seven newly created directories. The observed
shape was exactly:

```text
artifacts_children=zllvm-authority-v1
authority_children=incoming,objects,snapshots
objects_children=sha256
snapshots_children=sha256
objects/sha256=empty
snapshots/sha256=empty
incoming=empty
```

No file, marker, payload, repository, symlink, object-prefix directory,
snapshot archive, incoming file, or unknown descendant exists in the shape.

## 6. Anchored-ignore proof

Every created path is owned by the same anchored main-repository rule:

```text
.gitignore:30:/local-state/	local-state/artifacts
.gitignore:30:/local-state/	local-state/artifacts/zllvm-authority-v1
.gitignore:30:/local-state/	local-state/artifacts/zllvm-authority-v1/objects
.gitignore:30:/local-state/	local-state/artifacts/zllvm-authority-v1/objects/sha256
.gitignore:30:/local-state/	local-state/artifacts/zllvm-authority-v1/snapshots
.gitignore:30:/local-state/	local-state/artifacts/zllvm-authority-v1/snapshots/sha256
.gitignore:30:/local-state/	local-state/artifacts/zllvm-authority-v1/incoming
```

The rule grants no authority to traverse, populate, migrate, clean, repair,
remove, or repurpose the ignored shape.

## 7. Repository and protection state

After bounded verification and before this evidence commit:

```text
main_tracked_status=clean
control_status=clean
control_head=a41690a4c47cf1040afe3d4dd3679a77015263ea
control_tree=67582eb6f4de0b3ab3a2ef2e7c3635c79349d00e
main_registered_worktrees=43
control_registered_worktrees=1
protected_union=44
```

The control repository was not modified. No registered worktree was entered,
traversed, hashed, mutated, repaired, relocated, or cleaned.

## 8. Remaining absences and unchanged authority

The following remain absent:

```text
/home/oleg/prog/z_llvm/local-state/validations
/home/oleg/prog/z_llvm/local-state/worktrees
/home/oleg/prog/z_llvm/local-state/caches
/home/oleg/prog/z_llvm-baseline-validation-v3
/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3
```

The current authoritative store and manifest remain unchanged:

```text
authoritative_store=/home/oleg/prog/z_llvm-artifacts
authoritative_store_state=UNCHANGED_NOT_INSPECTED
tracked_live_manifest=/home/oleg/prog/z_llvm/docs/evidence/artifact_manifest_v1.tsv
tracked_live_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
empty_destination=/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1
empty_destination_authority=NONE
```

No authority transition, copy, migration, compatibility materialization,
manifest/control update, or validation is implied by empty-directory
existence.

## 9. Action ledger

```text
authorized_directories_created=7
unauthorized_directories_created=0
files_created_inside_destination=0
payloads_copied=0
current_store_descendants_inspected=0
control_repository_mutations=0
registered_worktree_operations=0
validation_cache_worktree_paths_created=0
project_or_artifact_commands=0
cleanup_or_repair_commands=0
production_changes=0
ratchet=131
next=STOP_FOR_WATCHER_REVIEWER_EMPTY_DESTINATION_REVIEW
```
