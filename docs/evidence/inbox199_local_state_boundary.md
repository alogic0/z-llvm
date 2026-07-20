# INBOX-199L Local-State Boundary

## 1. Scope and disposition

INBOX-199L replaced the withdrawn INBOX-199 sibling-root design before any
INBOX-199 target edit. This bounded slice creates one ignored local-state
boundary, one independent control repository, and this main-repository
evidence record.

The withdrawn target remains exact:

```text
withdrawn_inbox=INBOX-199
withdrawn_state=WITHDRAWN_BEFORE_EDIT
withdrawn_target=docs/evidence/inbox197_v3_artifact_cli_surface_design.md
withdrawn_target_lines=759
withdrawn_target_sha256=3717cc34f8e3d6c6841b679c1c2e70354d6a7cdef7d6f5e7ce9e48431b9a9bac
withdrawn_target_state=UNCHANGED
abandoned_sibling_root=/home/oleg/prog/z_llvm-baseline-validation-v3
abandoned_sibling_root_state=absent_and_unauthorized
```

No sibling-root reconciliation, payload, migration, artifact operation,
validation, source worktree, project command, cleanup, or production action
was performed.

## 2. Main repository

```text
root=/home/oleg/prog/z_llvm
branch=x86_64-codegen-expanded-frontier
operating_head=5b6d8510893dad5639c525a2b894e08a3693eded
operating_parent=e297a36c8c0885386486ca906a3aa08dbd8d6bc9
operating_head_tree=19b470639238acd864e73ca8c8b1a22033d39b79
preflight_tracked_status=clean
required_postcommit_tracked_status=clean
authorized_tracked_paths=2
```

The main index after staging the sole ignore edit and before creating this
evidence document had exact tree:

```text
ignore_only_staged_tree=e60c79d6314378034bf5a6fa9d6736da85fdc4d3
```

The final staged tree necessarily includes this evidence file, so embedding
that final tree identity in this file would change the tree recursively. Its
exact identity is retained with the resulting main commit in the Worker stop
report and Watcher review. No second self-referential commit is permitted.

The main commit contains changes to exactly:

```text
.gitignore
docs/evidence/inbox199_local_state_boundary.md
```

## 3. Anchored main ignore rule

Exactly one rule was appended without changing any existing rule:

```gitignore
/local-state/
```

The main ignore file identity after the edit is:

```text
path=/home/oleg/prog/z_llvm/.gitignore
sha256=c24426396c4968524cfbfec4b33d58cccd8a951b10a8e2b5dd8453f8058e7b2d
git_blob=361e57dc5628ccc98d4c163ecccd2cadcaa5d3f4
filesystem_mode=0664
git_mode=100644
bytes=517
```

The exact proof command and output were:

```text
command=git -C /home/oleg/prog/z_llvm check-ignore -v local-state/control/README.md
output=.gitignore:30:/local-state/	local-state/control/README.md
result=ignored_by_anchored_main_repository_rule
global_ignore_used=false
```

The anchored rule makes the main repository intentionally unaware of
operational-state descendants. It does not authorize traversal, cleanup,
artifact treatment, repository creation, or any later mutation.

## 4. Exact local-state boundary

The only created boundary paths are:

```text
/home/oleg/prog/z_llvm/local-state/
/home/oleg/prog/z_llvm/local-state/control/
```

The following sibling roles are reserved and absent:

```text
/home/oleg/prog/z_llvm/local-state/artifacts/
/home/oleg/prog/z_llvm/local-state/validations/
/home/oleg/prog/z_llvm/local-state/worktrees/
/home/oleg/prog/z_llvm/local-state/caches/
```

`local-state` is a non-authoritative operational-state boundary. A later
directive must name an exact path before creating or mutating any reserved
role or other descendant. No broad discovery, recursive walk, glob, cleanup,
or implicit child authority follows from the boundary.

## 5. Independent control repository

```text
root=/home/oleg/prog/z_llvm/local-state/control
repository_kind=independent
branch=main
initial_commit=a41690a4c47cf1040afe3d4dd3679a77015263ea
initial_tree=67582eb6f4de0b3ab3a2ef2e7c3635c79349d00e
remote_count=0
tracked_path_count=3
untracked_path_count=0
status=clean
```

Its exact tracked paths are:

```text
.gitignore
POLICY.md
README.md
```

The one-entry control worktree inventory is:

```text
worktree /home/oleg/prog/z_llvm/local-state/control
HEAD a41690a4c47cf1040afe3d4dd3679a77015263ea
branch refs/heads/main
```

The control files are:

| Path | SHA-256 | Git blob | Filesystem mode | Git mode | Bytes |
|---|---|---|---:|---:|---:|
| `.gitignore` | `7143a2d180c36dd2af8ac50ae6d0aa5f3b3bcd3564bada925018dc9f2ab828a8` | `01dc89cacd748287e2c03128fe67f6c82a4a52f3` | `0664` | `100644` | 471 |
| `POLICY.md` | `a6d4317d0ff4b2c02f515a540ad85f8ffbeb737bde697479d7796165cb5c55da` | `94bea7275c020a6523950feb1a4eaec345ee1ac5` | `0664` | `100644` | 1497 |
| `README.md` | `4d3026adc26a39830f017bb03e825a866053854b91ed8abaf2c38b601d222cc9` | `b2c0a07a3b482c5c0bf8fe8b6376895791a5e6cf` | `0664` | `100644` | 778 |

All three files are below the 1 MiB per-file limit. Their total tracked
payload is 2,746 bytes, below the 16 MiB repository limit.

The control repository admits only small operational manifests, policies,
and receipts. It prohibits secrets, credentials, private keys, tokens,
payload objects, source payloads, caches, build outputs, generated artifacts,
archives, binaries, core dumps, and large files. Its `.gitignore` narrowly
rejects common instances of those classes without hiding the three admitted
initial files.

The roles `artifacts/`, `validations/`, `worktrees/`, and `caches/` are
siblings outside the control repository. Any additional supplemental
repository requires later authority naming its exact path and purpose.

After initial commit, this control repository is a protected supplemental
worktree. Every later modification, removal, repair, relocation, cleanup,
normalization, or mutating Git operation requires later authority naming
`/home/oleg/prog/z_llvm/local-state/control`. Read-only status, identity, and
registration checks remain permitted.

## 6. Union protection model

The two Git roots remain separate:

```text
main_git_root=/home/oleg/prog/z_llvm
control_git_root=/home/oleg/prog/z_llvm/local-state/control
git_operation_rule=every Git command uses explicit git -C with one exact root
```

The main repository registration inventory remains:

```text
main_registration_count=43
main_path_list_sha256=f31d8542baafc7b64cd5ee6fe8cc4194842ca696b97a7ffc8df06ce12d553d7e
main_path_topology_sha256=6c868e3b6d436cfba92a1e2b21dbd616391763961f1cba9b6670b1ed4a6ebb62
main_non_main_records_sha256=ebc30a376b3db4c6fbf788f49ea85f4ce792471e539c0a89308068efdf96ebbe
main_distribution=33_repository_tmp_8_system_tmp_2_elsewhere
```

The control repository contributes one separately inventoried protected
worktree. The protection union is therefore:

```text
main_registered_worktrees=43
supplemental_control_worktrees=1
protected_union_count=44
```

The intentional containment of the independent control repository beneath
the main-ignored `local-state` boundary grants no traversal or mutation
authority. Future protection is the union of the main inventory and every
explicitly authorized supplemental repository's own inventory.

## 7. Permanent cleanup and traversal prohibitions

The following are permanently prohibited:

- broad `git clean -x`;
- broad `git clean -fdx`;
- recursive cleanup;
- cleanup or traversal from the main root into `local-state`;
- implicit repository discovery beneath `local-state`;
- modifying a registered or supplemental worktree without exact user
  authority; and
- treating the main ignore rule as permission to delete, normalize, repair,
  relocate, or recreate ignored content.

Every Git operation must name the main or control root explicitly with
`git -C`.

## 8. Frozen artifact authority and absent paths

The artifact authority remains outside both repositories:

```text
authoritative_store=/home/oleg/prog/z_llvm-artifacts
store_inventory_sha256=3234fb508d370878efe082cf1accb5af3b488372bf3f1ee7e9e87408a37a2d7c
store_file_ledger_sha256=a06c48e1549d16b9f924cc2b5f0404e60d7755a785bf3a4a23311c2383279a65
tracked_live_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
artifact_tool_sha256=94dfc1fc27ffe1268eb02453bcac1a3634aa11af38d0c94fbaa3b43decd25859
pins_sha256=1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
audit_sha256=5a7e019eb107e5b66947490a65fdf47444154fc4f1483ca30ab0fc6e381f33e6
watcher_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash_object=7985c6d01040a6e47e4ce5b918866d0e89517ac7
ratchet=131
```

No store traversal or rehash was performed. The following remain absent:

```text
/home/oleg/prog/z_llvm-baseline-validation-v3
/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3
/home/oleg/prog/z_llvm/local-state/artifacts
/home/oleg/prog/z_llvm/local-state/validations
/home/oleg/prog/z_llvm/local-state/worktrees
/home/oleg/prog/z_llvm/local-state/caches
```

The authoritative store remains `/home/oleg/prog/z_llvm-artifacts` until a
later separately authorized copy-and-verify authority migration.

## 9. Action ledger

```text
main_ignore_rules_added=1
main_evidence_documents_added=1
control_repositories_created=1
control_commits_created=1
control_tracked_files=3
supplemental_repositories_created=1
reserved_siblings_created=0
artifact_payloads_created_or_moved=0
compatibility_paths_created=0
validations_run=0
project_or_artifact_commands_run=0
source_worktrees_created=0
migrations_run=0
cleanup_commands_run=0
production_changes=0
ratchet=131
next=STOP_FOR_WATCHER_REVIEWER_LOCAL_STATE_BOUNDARY_REVIEW
```
