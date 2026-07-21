# INBOX-206CA Registered-Worktree Descriptor Boundary

## 1. Scope and disposition

INBOX-206CA is an evidence/design-only stop. It records why the accepted
descriptor chain cannot advance from the held `/home/oleg/prog` directory
into the main registered worktree without new user authority. It implements
no traversal, materialization, publication, production wiring, or path API.

```text
slice=INBOX-206CA
document_kind=registered_worktree_descriptor_boundary
implementation_authority=none
execution_authority=none
production_authority=none
evidence_generation_authority=none
D01=withheld
D02=unauthorized
descriptor_identity_status=conditionally_supported
ratchet=131
```

## 2. Closed named-read ledger

The completed review used only this closed ledger:

1. `docs/worker_inbox.md`;
2. committed `docs/next_steps.md`;
3. committed `docs/evidence/inbox199_local_state_boundary.md`;
4. committed
   `docs/evidence/inbox206bk_zig_materialization_readiness_design.md`;
5. Git commit/tree/blob/status metadata for operating HEAD, accepted BZ
   source, the control repository, and this document;
6. exactly one `git worktree list --porcelain` invocation for registration
   metadata;
7. no-follow root metadata for the exact retained and absent cache roots,
   plus absence/non-symlink checks for BI evidence and continuation;
8. this document for creation and verification.

The accepted Zig source was not opened as an artifact target. No registered
worktree directory was entered, enumerated, resolved, statted, hashed, or
traversed for artifact discovery. Ordinary Git metadata and this explicitly
authorized document workflow are narrow workflow exceptions, not artifact
path authority.

## 3. Accepted identities and state

### 3.1 Operating and BZ source authority

```text
operating_head=f0075e12a5cb57ce3508d63171821420a40f4845
operating_parent=27100817652fa4f18db8fdd6f39874de2cb7b8fb
operating_tree=77e2dd10cbff8081b5a162f76f4780f68088a91d
operating_commit_changed_path=docs/next_steps.md
operating_commit_parent_count=1
main_preconstruction_status=clean

bz_commit=27100817652fa4f18db8fdd6f39874de2cb7b8fb
bz_parent=4a28d03a9c2ff6f28cad479b4e09705b1e54285b
bz_tree=4e2c66c0d2e177330fd9541d31c32f42bd5b89db
bz_source_path=tools/zllvm_inbox206_materialize.zig
bz_source_mode=100644
bz_source_blob=ab0281e4dbac00fcd2b4b9ba58e569c707eb8ef9
bz_source_binding=git_tree_and_blob_metadata_only
bz_source_opened_as_artifact_target=false
```

### 3.2 Control, watcher, build, stash, and registration authority

```text
control_head=9c55bda34088e1230b0b91a126d35795a3ac70b4
control_tree=756369ad4a89d806f463bd8094c5159d8c973d7e
control_branch=main
control_status=clean
control_remote_count=0

build_sha256=3ab852ee10a670fa076d478ab1b45f9c63dd585950597b6dcb13f2e01cea4a38
watcher_sha256=1221b00a6aacd7deaae9aab50bd2600be33a13b0ed645428f9475a2cb81a893d
watcher_pid=3206208
stash_head=7985c6d01040a6e47e4ce5b918866d0e89517ac7

registered_worktree_count=43
registered_worktree_distribution=33_repository_tmp,8_tmp,2_elsewhere
registered_worktree_path_list_sha256=f31d8542baafc7b64cd5ee6fe8cc4194842ca696b97a7ffc8df06ce12d553d7e
registered_worktree_topology_sha256=6c868e3b6d436cfba92a1e2b21dbd616391763961f1cba9b6670b1ed4a6ebb62
worktree_list_invocation_count=1
registered_worktree_directory_access=none
```

The watcher and build values above are the accepted identities recorded by
the operating authority; neither file was opened in this slice. The single
registration-metadata call proved the count and stable path/topology hashes
without entering a registered directory.

### 3.3 Cache and BI boundaries

Each of these exact roots is a retained, non-symlink directory; only its root
metadata was admitted:

```text
/home/oleg/.cache/zllvm-inbox206bp-local
/home/oleg/.cache/zllvm-inbox206bp-global
/home/oleg/.cache/zllvm-inbox206br-local
/home/oleg/.cache/zllvm-inbox206br-global
/home/oleg/.cache/zllvm-inbox206bt-local
/home/oleg/.cache/zllvm-inbox206bt-global
/home/oleg/.cache/zllvm-inbox206bu-local
/home/oleg/.cache/zllvm-inbox206bu-global
/home/oleg/.cache/zllvm-inbox206bw-local
/home/oleg/.cache/zllvm-inbox206bw-global
/home/oleg/.cache/zllvm-inbox206by-local
/home/oleg/.cache/zllvm-inbox206by-global
/home/oleg/.cache/zllvm-inbox206bz-local
/home/oleg/.cache/zllvm-inbox206bz-global
```

These exact roots remain absent and non-symlink:

```text
/home/oleg/.cache/zllvm-inbox206bs-local
/home/oleg/.cache/zllvm-inbox206bs-global
/home/oleg/.cache/zllvm-inbox206bv-local
/home/oleg/.cache/zllvm-inbox206bv-global
/home/oleg/.cache/zllvm-inbox206bx-local
/home/oleg/.cache/zllvm-inbox206bx-global
```

BI remains absent and non-symlink at both authorized checks:

```text
bi_evidence=/home/oleg/prog/z_llvm/docs/evidence/inbox206bi_phase3_wrapper_materialization_readiness.md
bi_evidence_state=absent_non_symlink
bi_continuation=/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206bi
bi_continuation_state=absent_non_symlink
```

## 4. Intended chain and standing protection

Accepted BK section 12.1 states the intended descriptor-relative chain:

> Open `/`, then `home`, `oleg`, `prog`, `z_llvm`, `docs`, and `evidence` one
> literal component at a time with `follow_symlinks=false`.

The standing operating rule states:

> All 43 registered Git worktrees and their complete directory trees are
> read-only exclusions from artifact treatment, traversal, hashing, totals,
> publication, resolution, materialization, migration, cleanup, and
> retirement.

It also makes explicit that no worktree or its directory may be modified or
traversed for these purposes without user permission naming the affected
path, and that Watcher/Reviewer agreement is insufficient.

The accepted private tests establish only this retained prefix in the current
mount namespace:

```text
root=/
component_1=home
component_2=oleg
component_3=prog
held_prefix=/home/oleg/prog
```

The first blocked transition is exactly:

```text
held /home/oleg/prog descriptor → relative literal z_llvm
```

That transition would enter the protected main registered worktree. Current
authority therefore admits no `TrustedZllvmChain`, no real-path probe, and no
descriptor-relative access to `z_llvm`, `docs`, or `evidence`.

## 5. Closed reviewed option matrix

The following matrix is exhaustive for this evidence slice and contains
exactly four options.

| Option | Required authority | Affected identities/contracts | Production/build implications | Rollback | Remaining blockers |
|---|---|---|---|---|---|
| 1. Retain the blocker | No new authority. Continue enforcing the standing worktree exclusion. | BZ commit/tree/blob, all 43 registration identities, the retained descriptor prefix, cache states, and BI absence remain unchanged. | None; no source, build edge, test, install, production path, or runtime behavior changes. | No action is taken, so no rollback is needed. | The transition from held `/home/oleg/prog` to literal `z_llvm` remains forbidden; specification consumption and publication remain unavailable. |
| 2. Future explicit user-named read-only traversal authority for the exact main-worktree chain | A new user directive must name the main-worktree path and authorize read-only descriptor traversal of exactly `z_llvm`, then `docs`, then `evidence`, including the threat model and stop conditions. Watcher/Reviewer agreement alone is insufficient. | Creates a narrow exception to standing worktree protection; must rebind registration path/topology, main commit/tree, each held descriptor identity, final specification identity, and no-follow role checks. | Could permit a later private Zig test or tool read path only under separate source/build/execution authority. It grants no production reachability, install, write, or publication authority. | Revoke the prospective traversal authority before any execution; because the option is read-only, no repository bytes require restoration. | Exact future identities, race/threat-model admission, specification schema validation, output-parent authority, publication, D01/D02, and all execution/build authority remain unresolved. |
| 3. Relocate/copy the specification and output protocol outside registered worktrees | A new user directive must name an exact external source and destination, define which copy is authoritative, authorize the copy/publication lifecycle, and bind provenance and retention. | Changes the canonical-location and provenance contracts; requires exact source commit/blob, external path/descriptor identity, byte hash, synchronization rule, retention pins, and non-authority labels for any copy. | A later private Zig tool could consume the external bytes only with separate implementation/build/execution authority. No production edge follows automatically. | Under separately granted cleanup authority, remove or retire only the named external copy and restore the prior canonical-location contract; never alter the registered worktree implicitly. | Copy freshness, split authority, trusted external-root admission, exclusive publication, BI destination policy, D01/D02, and execution authority remain unresolved. |
| 4. Supply committed specification bytes through a separately authorized trusted descriptor/blob/materialization boundary without runtime worktree traversal | A new user directive must authorize an exact Git object or trusted descriptor boundary, its pure-Zig acquisition/materialization protocol, byte identity, consumer, and one-shot lifecycle. | Keeps the committed specification bound to an exact commit/tree/blob while adding a separately reviewed transport boundary; must bind object format, byte hash, ownership, allocator limits, provenance, and absence of runtime worktree traversal. | This could be the smallest prospective route to a private Zig-only consumer, but still needs separate source/build/test/execution authority and creates no production or install reachability. | Disable the boundary before execution, or retire only a separately authorized external materialization; the committed source and registered worktrees remain untouched. | A reviewed pure-Zig blob/descriptor acquisition contract, trusted output parent, exclusive publication, materialization authority, D01/D02, and execution authority remain unresolved. |

## 6. Recommendation and terminal boundary

Option 1 is the only currently authorized state. If future work is desired,
option 4 is the smallest prospective design because it can preserve the
registered-worktree traversal prohibition while binding committed bytes.
This recommendation grants no authority and implements nothing. It does not
authorize blob extraction, materialization, source changes, a build edge,
execution, publication, BI creation, D01/D02 action, or ratchet movement.

```text
option_matrix_count=4
current_option=retain_the_blocker
prospective_recommendation=trusted_descriptor_or_blob_boundary
recommendation_grants_authority=false
implementation_performed=false
registered_worktree_traversal_performed=false
publication_performed=false
materialization_performed=false
main_preconstruction_status=clean
control_status=clean
descriptor_identity_status=conditionally_supported
D01=withheld
D02=unauthorized
ratchet=131
```
