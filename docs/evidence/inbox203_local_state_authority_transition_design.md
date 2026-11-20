# INBOX-203 Local-State Authority Transition Design

## 1. Scope, disposition, and frozen baseline

This is the documentation-only authority-transition design authorized by
operating-document commit
`04335015b3d1ea654d4dc58638f5037987709f02`, whose exact parent is accepted
INBOX-202I evidence commit
`e35cfaa6505e26f3c13a2a54a339f247817febdd`.

No authority was implemented or activated. No control, source, tool, manifest,
contract, pin, script, build, payload, compatibility, validation, or protected
worktree byte was changed. The current state remains:

```text
source_authority=/home/oleg/prog/z_llvm-artifacts
destination=/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1
destination_authority=non-authoritative
destination_payload_files=20
destination_payload_bytes=9970364
destination_objects=18
destination_snapshots=2
destination_manifest=absent
ratchet=131
validation_v3=absent_and_unauthorized
```

The design is closed but non-executing. Every commit, path creation, payload
write, manifest write, compatibility write, validation, activation, and
rollback described below requires a later explicit directive.

### 1.1 Frozen identities

The finite preflight completed before drafting and proved:

```text
main_head=04335015b3d1ea654d4dc58638f5037987709f02
main_parent=e35cfaa6505e26f3c13a2a54a339f247817febdd
main_tracked_status=clean
control_head=a41690a4c47cf1040afe3d4dd3679a77015263ea
control_tree=67582eb6f4de0b3ab3a2ef2e7c3635c79349d00e
control_branch=main
control_remote=none
control_status=clean
main_registered_worktrees=43
control_registered_worktrees=1
protected_union=44
worktree_path_list_sha256=f31d8542baafc7b64cd5ee6fe8cc4194842ca696b97a7ffc8df06ce12d553d7e
worktree_topology_sha256=6c868e3b6d436cfba92a1e2b21dbd616391763961f1cba9b6670b1ed4a6ebb62
non_main_worktree_records_sha256=ebc30a376b3db4c6fbf788f49ea85f4ce792471e539c0a89308068efdf96ebbe
watcher_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash_object=7985c6d01040a6e47e4ce5b918866d0e89517ac7
tracked_live_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
source_generation_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
source_store_inventory_sha256=3234fb508d370878efe082cf1accb5af3b488372bf3f1ee7e9e87408a37a2d7c
source_store_file_ledger_sha256=a06c48e1549d16b9f924cc2b5f0404e60d7755a785bf3a4a23311c2383279a65
source_destination_ledger_sha256=4c29709b9ef9242dd799ab52d346cdf302f5728d35e37e0d78063e892a6cf9e8
accepted_INBOX_202_evidence_sha256=4b532daabe33e7c6eaca7f0ab412d9c271b55b6b1de8235dd3d4f65d7ab6f7a6
artifact_tool_sha256=94dfc1fc27ffe1268eb02453bcac1a3634aa11af38d0c94fbaa3b43decd25859
v3_contract_sha256=d445f6a45f039415052cb0fb1efc71b1975f2ea68d28e3637aede503145fc387
durability_audit_sha256=5a7e019eb107e5b66947490a65fdf47444154fc4f1483ca30ab0fc6e381f33e6
pins_sha256=1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
bypass_tsv_sha256=2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11
ratchet=131
```

Both superseded validation roots remain absent:

```text
/home/oleg/prog/z_llvm-baseline-validation-v3
/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3
```

The protected local paths `.claude/`, `.claude/settings.local.json`, and
`/home/oleg/.config/git/ignore` were not inspected, statted, read, hashed,
traversed, or modified.

### 1.2 INBOX-203A correction provenance

INBOX-203 commit
`8f04b147a6012c0a3df00fbc0827bc854889938c` was accepted only as a
scope-compliant documentation stop. This exact correction starts from
operating-document commit
`61e94d6c6de7483f5d0a340cf51b405a5a135603`, whose parent is that INBOX-203
commit.

The current file and the committed `e35cfaa6505e26f3c13a2a54a339f247817febdd`
blob of `docs/evidence/inbox202_local_state_artifact_copy_verify.md` were
independently hashed. Both equal:

```text
4b532daabe33e7c6eaca7f0ab412d9c271b55b6b1de8235dd3d4f65d7ab6f7a6
```

Exactly the two incorrect INBOX-202 bindings in this document were replaced.
All prospective schema headers, paths, fields, the acyclic sequence,
candidate/active separation, validation matrix, and rollback model are
unchanged.

The correction-time read-only audit also reproduced:

```text
worktree_path_list_sha256=f31d8542baafc7b64cd5ee6fe8cc4194842ca696b97a7ffc8df06ce12d553d7e
worktree_topology_sha256=6c868e3b6d436cfba92a1e2b21dbd616391763961f1cba9b6670b1ed4a6ebb62
non_main_worktree_records_sha256=ebc30a376b3db4c6fbf788f49ea85f4ce792471e539c0a89308068efdf96ebbe
registration_distribution=43/33/8/2
control_head=a41690a4c47cf1040afe3d4dd3679a77015263ea
control_tree=67582eb6f4de0b3ab3a2ef2e7c3635c79349d00e
tracked_and_source_generation_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
artifact_tool_sha256=94dfc1fc27ffe1268eb02453bcac1a3634aa11af38d0c94fbaa3b43decd25859
v3_contract_sha256=d445f6a45f039415052cb0fb1efc71b1975f2ea68d28e3637aede503145fc387
durability_audit_sha256=5a7e019eb107e5b66947490a65fdf47444154fc4f1483ca30ab0fc6e381f33e6
pins_sha256=1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
bypass_tsv_sha256=2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11
watcher_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash_object=7985c6d01040a6e47e4ce5b918866d0e89517ac7
both_v3_roots=absent
ratchet=131
```

## 2. Finite current-authority inventory

The inventory used only tracked-file lookup and exact named control paths. It
did not discover or traverse a registered worktree, source store, destination
store, or ignored tree.

### 2.1 Active consumers and declarations

Every `tools/zllvm_artifact_store.zig` source anchor in the following table is
bound to exact source SHA-256
`94dfc1fc27ffe1268eb02453bcac1a3634aa11af38d0c94fbaa3b43decd25859`.
Symbols, not mutable line numbers, are the stable anchors.

| Tracked path | Symbol or anchor | Present behavior | Current authority role | Candidate behavior | Activation behavior | Fail-closed obligation |
|---|---|---|---|---|---|---|
| `tools/zllvm_artifact_store.zig` | `default_store` | Hard-codes `/home/oleg/prog/z_llvm-artifacts`, but exact uses are only `assertRetainedMaterializeBoundaries` and the `resolveAuthority` fallback test expectation. | Test/retained-boundary constant only; it is not the production default-selection input. | Remains byte-identical in the control-candidate phase. | It must not be promoted into a production fallback. | Any proposed production use is a new reviewed change; absence of the new authority never falls back through this constant. |
| `tools/zllvm_artifact_store.zig` | `main_git_common_dir` | Exact `/home/oleg/prog/z_llvm/.git`; passed by both production `main` resolver constructions and used by `captureRegistration` as `/usr/bin/git --git-dir=...`. | Production default derivation and registration-capture anchor. | Remains the production source-root derivation input while the candidate is inactive. | Remains the main-repository identity input, but active payload selection comes from the exact control declaration. | Invalid Git-common-dir shape, registration capture failure, or changed registration stops. |
| `tools/zllvm_artifact_store.zig` | `resolveAuthority` | A normalized absolute `ZLLVM_ARTIFACT_STORE` value wins; otherwise derives `/home/oleg/prog/z_llvm-artifacts` from `main_git_common_dir` by parent plus `<repository-basename>-artifacts`. It does not read `default_store` and does not consult a manifest. | Actual production path-selection function; path selection alone does not prove semantic authority. | Generic path behavior remains frozen until a dormant authority-binding implementation is reviewed. Candidate metadata cannot select production. | Unset selects the exact active declaration. Set is accepted only when its normalized value equals the active declaration’s payload root and every declaration/manifest/content check passes. | Relative, noncanonical, old, alternate, missing, ambiguous, stale, or advanced values fail without fallback. |
| `tools/zllvm_artifact_store.zig` | `main` / `resolve-authority` -> `resolveAuthority(allocator, environment_value, main_git_common_dir)` | Reads optional `ZLLVM_ARTIFACT_STORE`, constructs the production resolver with exact `main_git_common_dir`, and prints only the resolved path. | First production resolver consumer; it presently performs no `RegistrationGuard` or store-content validation. | Must remain current-authority-only until dormant implementation acceptance. | Must report a root only after exact control declaration, generation manifest, payload, and registration validation. | A path alone can never be returned as authority after activation. |
| `tools/zllvm_artifact_store.zig` | `main` / `materialize-spec publish` -> `resolveAuthority(allocator, environment_value, main_git_common_dir)` -> `publishCanonicalSourceSpec` | Requires `ZLLVM_ARTIFACT_STORE`, constructs the second production resolver, then passes its result into guarded publication. | Second production resolver consumer; accepted one-time source-store publication surface, not an authority-transition surface. | No invocation or semantic reuse in the transition. | Remains outside activation; future output publication uses a separately reviewed surface. | It must not create or replace control metadata, destination authority metadata, or activation receipts. |
| `tools/zllvm_artifact_store.zig` | `expected_path_hash`, `expected_topology_hash`, `expected_non_main_hash` -> `validateExpectedRegistration` | Freezes the exact 43-registration path, topology, and non-main identities; also requires count/distribution `43`, `33/8/2`. | Production registration admission boundary. | Exact values remain frozen. | Active resolution must continue to require these facts until a separately reviewed registration update. | Any count, distribution, path, topology, or non-main mismatch returns `UnexpectedRegistrationInventory`. |
| `tools/zllvm_artifact_store.zig` | `RegistrationGuard.init` -> `captureRegistration` -> `validateExpectedRegistration` | Captures `/usr/bin/git --git-dir=/home/oleg/prog/z_llvm/.git worktree list --porcelain`, owns the snapshot, and validates the expected registration boundary. | Production plan/publication and store-access guard construction. | Remains the sole existing registration-capture authority. | The active resolver must construct the same guard before store access. | Capture, parse, expected-identity, allocation, or command failure propagates; no Boolean fallback. |
| `tools/zllvm_artifact_store.zig` | `RegistrationGuard.assertCurrent` | Recaptures registration and requires exact frozen/current `full_hash`, path, topology, and non-main equality. | Mutation/access checkpoint used before and after store operations. | Remains unchanged. | Required before store access and again before successful authority resolution. | Drift returns `RegisteredWorktreeDrift`. |
| `tools/zllvm_artifact_store.zig` | `RegistrationGuard.assertStoreRoot` -> `assertDisjointFromEveryRegistration` | Requires normalized absolute root and bidirectional disjointness from every frozen registration. | Store-root admission check. | Applies to any dormant candidate verification without activating it. | Applies to the declared local-state payload root before any access. | Relative, noncanonical, equal, ancestor, or descendant overlap fails closed. |
| `tools/zllvm_artifact_store.zig` | `planCanonicalSourceSpec` -> `RegistrationGuard.init` / `verifyCanonicalSources` / `assertCurrent` | The `materialize-spec plan` production path freezes registration around bounded source verification, but opens no store. | Production non-mutating registration consumer. | Frozen; not an authority selector. | Remains outside activation. | Registration/source mismatch propagates. |
| `tools/zllvm_artifact_store.zig` | `publishCanonicalSourceSpec` -> `RegistrationGuard.init` / `assertStoreRoot` / `prepareStoreRoot` / `Store.open` / final `assertCurrent` | The publish production path validates registration and root before preparation, opens the root no-follow, and revalidates before success. | Production mutating store-access consumer. | Not used for candidate activation. | Remains outside authority activation. | Every root, ancestry, registration, capacity, publication, read-back, or final-current failure propagates. |
| `tools/zllvm_artifact_store.zig` | `Store.open` and `Store` methods | `Store.open` requires `assertCurrent` and `assertStoreRoot`, opens the exact absolute root with subpath access and `follow_symlinks=false`, and owns a duplicated root path; capacity, publish, manifest, snapshot, compatibility, and verification methods repeatedly call `assertCurrent`. | Existing guarded store access boundary. | Candidate verification may reuse only after separate dormant review. | Active read-only resolution must retain the same no-follow and current-registration boundary. | No unguarded open, borrowed root identity, symlink-following access, or post-drift success. |
| `tools/zllvm_artifact_store.zig` | `Store.publishManifest` | Publishes a read-only payload-store generation manifest. | The accepted source copy is currently byte-equal to the tracked manifest. | No destination manifest is created. | Any future payload-store copy is a non-authoritative mirror only. | A mirror cannot select authority or repair missing control metadata. |
| `docs/evidence/artifact_manifest_v1.tsv` | complete `zllvm-artifact-manifest-v1` document | Contains the accepted active 19 logical references, 18 objects, two snapshots, and 16 members; byte-equal to the source-store generation manifest. | Joint current main-tree side of the accepted source authority proof. | Frozen throughout candidate, dormant, and validation phases. | Becomes an immutable historical/source-generation mirror after main activation; runtime no longer treats it as live authority. | It cannot silently follow, replace, or supersede the control generation manifest. |
| `/home/oleg/prog/z_llvm-artifacts/manifests/generation-00000001.tsv` | exact named external file | Accepted source-store generation manifest, SHA-256 `61b7426b…`. | Current payload-side generation authority paired with the tracked manifest. | Frozen and retained. | Preserved as the source generation; not read as the new active generation. | Never rewrite, delete, normalize, or treat as a fallback. |
| `build.zig` | `artifact-store-test` | Builds and runs dormant synthetic tests rooted at `tools/zllvm_artifact_store.zig`. | Test entrypoint only; no runtime authority selection. | A later dormant slice may extend existing tests without changing production authority. | No activation semantics belong in the build graph. | A test step cannot activate a candidate or substitute synthetic authority for production. |
| `docs/evidence/inbox187_o2_compiler_rt_v1_baseline_validation_execution_contract.md` | future v3 contract, especially sections 7 and 19 | Names old `tmp` operational roots and the accepted source authority; v3 remains unauthorized. | Future executable contract, not a live consumer. | Must remain unexecuted until separately amended to the accepted local-state resolver and operational paths. | May execute only after control and main activation are accepted and its exact paths/commands are re-reviewed. | Any old authority, old operational root, absent compatibility, or unresolved logical ID stops before v3 creation. |
| `docs/evidence/inbox192_calls_artifact_durability_audit.md` | local-only durability model | Defines the four retention classes and local-only guarantees. | Normative evidence, not runtime authority. | Remains frozen historical design input. | A new retention contract may cite it but cannot inherit authority implicitly. | Conflicts are resolved by later explicit contract review, never by runtime guessing. |
| `docs/evidence/tmp_retention_pins.tsv` | live-pin table | Pins retained `tmp` evidence, including compiler-rt materialization roots. | Retention-only; it does not select artifact authority. | Frozen. | Remains retention-only after activation. | A pin cannot become a manifest row, resolver input, or fallback. |
| `docs/evidence/inbox194_calls_canonical_source_spec_v1.tsv` | canonical publication source spec | Describes the finite accepted source publication. | Frozen provenance input; not live authority. | Frozen. | Historical publication provenance only. | Never republish or infer authority from source paths. |
| `docs/evidence/inbox194_calls_proposed_live_manifest_v1.tsv` | prepublication plan | Frozen plan bytes, intentionally not the accepted live manifest. | Historical plan only. | Frozen. | Never read by runtime. | Plan/live inequality is expected; no normalization or promotion. |

There is no active artifact-authority consumer in a production source file
other than `tools/zllvm_artifact_store.zig`. No tracked script selects the
artifact authority. `build.zig` only exposes the dormant synthetic test step.

### 2.2 Required absent paths

The following exact tracked paths are absent now:

```text
docs/evidence/zllvm_artifact_manifest_v1.tsv
docs/zllvm_artifact_retention_contract.md
```

Their closed prospective roles are:

- `docs/evidence/zllvm_artifact_manifest_v1.tsv` is introduced only in the
  dormant main implementation as a byte-exact, non-authoritative review/test
  mirror of the candidate control generation manifest. Production runtime
  must not use it to select authority.
- `docs/zllvm_artifact_retention_contract.md` may be introduced only as the
  normative human-readable transition/retention contract. It cannot select a
  root, manifest, generation, or fallback, and it is not a replacement for
  control metadata.

Neither absence is permission to create the file in INBOX-203.

### 2.3 Immutable historical evidence

The following tracked files contain old-authority, old-v3-root, or transition
references but are immutable evidence/design, not active runtime consumers:

```text
docs/evidence/inbox193c_o2_artifact_store_dormant.summary.md
docs/evidence/inbox194d_o2_artifact_store_cli_dormant.summary.md
docs/evidence/inbox195c_o2_calls_real_store_verification.summary.md
docs/evidence/inbox197_v3_artifact_cli_surface_design.md
docs/evidence/inbox198_v3_operational_root_and_test_seam_design.md
docs/evidence/inbox199_local_state_boundary.md
docs/evidence/inbox200_local_state_v3_path_model.md
docs/evidence/inbox201_local_state_artifact_authority_bootstrap.md
docs/evidence/inbox202_local_state_artifact_copy_verify.md
docs/evidence/inbox202e_local_state_snapshot_verifier_diagnosis.md
```

`docs/next_steps.md` and `docs/worker_inbox.md` are operating records, not
runtime inputs. Their historical path statements remain evidence of the
authorization sequence. No historical file is rewritten to make the new
model appear retroactive.

## 3. Single future semantic authority

After activation, the **control repository generation manifest selected by
its accepted live declaration is the sole semantic authority**:

```text
control_repository=/home/oleg/prog/z_llvm/local-state/control
authority_root=authority/zllvm/v1
live_declaration=authority/zllvm/v1/manifests/live.tsv
generation_manifest=authority/zllvm/v1/manifests/generation-00000001.tsv
```

The immutable payload bytes remain at:

```text
/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1
```

The payload root is storage, not semantic authority. A payload-store manifest,
if a later directive creates one, is a byte-exact **non-authoritative mirror**.
The main-tree tracked manifest mirror, if later created, is also
non-authoritative. Neither can select a generation or repair missing control
metadata.

Exactly one authority owns each fact:

| Fact | Sole future authority |
|---|---|
| Which generation is live | control `manifests/live.tsv` |
| Logical IDs, relationships, identities, modes, media, retention classes | control `manifests/generation-00000001.tsv` |
| Generation ancestry | control `lineage/generation-00000001.tsv` |
| Payload bytes | exact immutable object/snapshot files named by the generation manifest |
| Copy completion | control payload-copy receipt |
| Validation acceptance | control validation receipt |
| Control activation event | control activation receipt |
| Main implementation state | exact main commit and its pinned control file hashes |
| Terminal human evidence | non-authoritative terminal receipt; never recursively published |

## 4. Exact prospective control paths

No path below exists today. Each requires a later explicit control-repository
directive.

```text
authority/zllvm/v1/manifests/candidate.tsv
authority/zllvm/v1/manifests/live.tsv
authority/zllvm/v1/manifests/generation-00000001.tsv
authority/zllvm/v1/lineage/generation-00000001.tsv
authority/zllvm/v1/receipts/publication/generation-00000001-payload-copy.tsv
authority/zllvm/v1/receipts/validation/generation-00000001.tsv
authority/zllvm/v1/receipts/activation/generation-00000001.tsv
authority/zllvm/v1/receipts/terminal/generation-00000001.tsv
```

All are small tracked metadata under the accepted 1 MiB per-file and 16 MiB
control-repository total limits. Their checked-out control-repository mode is
exactly `0644`; mode is validated independently of content. Payloads,
archives, binaries, build outputs, validation output, source payloads, and
caches remain prohibited.

### 4.1 Common canonical rules

Every file is UTF-8-compatible ASCII TSV with:

1. one exact magic line;
2. one exact tab-separated header;
3. bytewise key-sorted data rows;
4. exactly one LF after every line, including the final line;
5. no CR, NUL, empty row, duplicate key, unknown field, reordered field,
   leading/trailing whitespace, or noncanonical integer;
6. lowercase 64-hex SHA-256 values;
7. decimal byte counts without leading zeroes except `0`;
8. four-octal-digit modes;
9. safe relative keys only: no empty component, `.`, `..`, absolute path,
   backslash, repeated slash, or NUL;
10. exact parse/re-encode byte equality before acceptance.

Every schema below is versioned and closed. `-` is permitted only where the
field definition explicitly says it is.

### 4.2 Candidate declaration

Path and magic:

```text
authority/zllvm/v1/manifests/candidate.tsv
zllvm-authority-candidate-v1
```

Exact header:

```text
authority_id	generation	payload_root	generation_manifest_key	generation_manifest_sha256	generation_manifest_bytes	generation_manifest_mode	lineage_key	lineage_sha256	payload_copy_receipt_key	payload_copy_receipt_sha256	source_authority_root	source_generation_manifest_sha256	state
```

There is exactly one row:

- `authority_id` is `zllvm-local-state-v1`;
- `generation` is `00000001`;
- `payload_root` is the exact local-state destination;
- the three keys are the exact relative control paths above;
- manifest/lineage/receipt identities are exact;
- source root and source generation hash preserve provenance;
- `state` is exactly `candidate`.

The candidate declaration is never active and runtime must never consult it
as a fallback.

### 4.3 Generation manifest

Path:

```text
authority/zllvm/v1/manifests/generation-00000001.tsv
```

Its schema remains exactly the accepted `zllvm-artifact-manifest-v1` magic,
17-field header, row vocabulary, relationship rules, canonical serialization,
19 active logical references, 18 objects, two snapshots, and 16 members.
Generation 1 candidate bytes must be exactly SHA-256
`61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d`
with byte count `27823` and control-repository mode `0644`, and must be
byte-identical to the accepted source generation and tracked live manifest.
The source generation remains mode `0444`; the current main-tree tracked
manifest remains mode `0644`. Copying these small metadata bytes into control
does not make either source file the future authority.

### 4.4 Lineage

Path and magic:

```text
authority/zllvm/v1/lineage/generation-00000001.tsv
zllvm-artifact-lineage-v1
```

Exact header:

```text
generation	parent_generation	parent_manifest_sha256	generation_manifest_sha256	source_authority_root	source_generation_manifest_sha256	transition
```

Generation 1 has:

```text
parent_generation=-
parent_manifest_sha256=-
transition=non_destructive_verified_copy
```

The source root and source generation hash are mandatory. A later generation
must name its exact parent generation and parent manifest hash; no branching,
rewriting generation 1, or generation skipping is accepted.

### 4.5 Payload-copy receipt

Path and magic:

```text
authority/zllvm/v1/receipts/publication/generation-00000001-payload-copy.tsv
zllvm-payload-copy-receipt-v1
```

Exact header:

```text
receipt_id	generation	source_root	destination_root	source_inventory_sha256	source_file_ledger_sha256	source_destination_ledger_sha256	payload_files	payload_bytes	objects	snapshots	destination_modes	copy_evidence_path	copy_evidence_sha256	result
```

The one row binds the accepted INBOX-202I facts:

```text
payload_files=20
payload_bytes=9970364
objects=18
snapshots=2
destination_modes=0444
copy_evidence_path=docs/evidence/inbox202_local_state_artifact_copy_verify.md
copy_evidence_sha256=4b532daabe33e7c6eaca7f0ab412d9c271b55b6b1de8235dd3d4f65d7ab6f7a6
result=verified_non_authoritative_copy
```

It contains no candidate hash and no control commit hash, so the candidate
declaration may refer to it without a cycle.

### 4.6 Validation receipt

Path and magic:

```text
authority/zllvm/v1/receipts/validation/generation-00000001.tsv
zllvm-authority-validation-receipt-v1
```

Exact header:

```text
receipt_id	authority_id	generation	candidate_sha256	candidate_control_commit	dormant_main_commit	validation_evidence_path	validation_evidence_sha256	generation_manifest_sha256	payload_inventory_sha256	payload_file_ledger_sha256	result
```

This file cannot exist until the dormant main implementation and the complete
candidate-validation matrix are accepted. Its single result is
`accepted_for_control_activation`. It never includes its own hash or a future
control activation commit.

### 4.7 Live declaration

Path and magic:

```text
authority/zllvm/v1/manifests/live.tsv
zllvm-authority-live-v1
```

Exact header:

```text
authority_id	generation	payload_root	generation_manifest_key	generation_manifest_sha256	generation_manifest_bytes	generation_manifest_mode	lineage_key	lineage_sha256	candidate_sha256	validation_receipt_key	validation_receipt_sha256	state
```

There is exactly one row and `state` is exactly `active`. It refers to the
accepted candidate and validation receipt but not to the activation receipt or
control commit, avoiding a cycle.

### 4.8 Activation receipt

Path and magic:

```text
authority/zllvm/v1/receipts/activation/generation-00000001.tsv
zllvm-authority-activation-receipt-v1
```

Exact header:

```text
receipt_id	authority_id	generation	live_sha256	candidate_sha256	validation_receipt_sha256	payload_root	generation_manifest_sha256	state	main_activation_required
```

The one row has `state=active_in_control` and
`main_activation_required=true`. It may be committed alongside `live.tsv`
because it refers to the already finalized live bytes; `live.tsv` does not
refer back to it. The control Git commit itself supplies commit provenance and
is not embedded in either file.

### 4.9 Terminal receipt

Path and magic:

```text
authority/zllvm/v1/receipts/terminal/generation-00000001.tsv
zllvm-authority-terminal-receipt-v1
```

Exact header:

```text
receipt_id	authority_id	generation	control_activation_commit	main_activation_commit	live_sha256	generation_manifest_sha256	post_activation_evidence_path	post_activation_evidence_sha256	result
```

It can be created only after accepted main activation. It is finite terminal
evidence: no manifest, declaration, publication group, or later receipt may
include it as a member or publish it recursively. Nothing refers to its own
hash.

## 5. Acyclic transition sequence

The required sequence is:

### Phase 1: control candidate commit

Later control mutations, all in one reviewed commit:

```text
add authority/zllvm/v1/manifests/candidate.tsv
add authority/zllvm/v1/manifests/generation-00000001.tsv
add authority/zllvm/v1/lineage/generation-00000001.tsv
add authority/zllvm/v1/receipts/publication/generation-00000001-payload-copy.tsv
```

`live.tsv`, validation, activation, and terminal receipts remain absent.
Current main continues using the source authority.

### Phase 2: dormant main implementation

Exact prospective main tracked files:

```text
tools/zllvm_artifact_store.zig
build.zig
docs/evidence/zllvm_artifact_manifest_v1.tsv              non-authoritative test mirror
docs/zllvm_artifact_retention_contract.md                 normative only
docs/evidence/zllvm_artifact_authority_dormant_v1.md      test/evidence only
```

The tool may gain private declaration parsing, exact control-manifest
validation, destination verification, and synthetic tests. Production
selection and current call sites remain on the source authority. The
main-tree manifest mirror is never a production input. If an existing private
surface cannot implement this without public API, generic authority, or path
widening, the dormant slice stops structurally.

### Phase 3: validation and acceptance

Exact prospective main evidence path:

```text
docs/evidence/zllvm_artifact_authority_validation_v1.md
```

Validation covers the matrix in section 8 and produces no activation. Only
after accepted evidence may a later control directive add the validation
receipt.

### Phase 4: control activation commit

Later control mutations:

```text
add authority/zllvm/v1/receipts/validation/generation-00000001.tsv
add authority/zllvm/v1/manifests/live.tsv
add authority/zllvm/v1/receipts/activation/generation-00000001.tsv
```

The commit must be based on the exact accepted candidate control commit.
Current main still uses the source authority. Control activation alone never
changes main runtime behavior.

### Phase 5: main activation commit

Exact prospective main mutations:

```text
tools/zllvm_artifact_store.zig
docs/zllvm_artifact_retention_contract.md
docs/evidence/zllvm_artifact_authority_activation_v1.md
docs/evidence/inbox187_o2_compiler_rt_v1_baseline_validation_execution_contract.md
```

`build.zig` remains byte-identical to the accepted dormant slice. The
activation commit pins the exact control activation commit for provenance and
the exact hashes of `live.tsv`, generation manifest, lineage, validation
receipt, and activation receipt. Runtime validation is against those exact
file/content hashes and payload identities, **not against the moving control
HEAD**.

The v3 contract may be amended to use the accepted local-state paths and
resolver only after this activation is accepted. Validation-v3 execution
remains separately unauthorized.

### Phase 6: optional terminal evidence

After main activation acceptance, a later control directive may add only:

```text
authority/zllvm/v1/receipts/terminal/generation-00000001.tsv
```

A corresponding main evidence document may record its exact hash. The
terminal receipt has no consumer in the authority graph and cannot be
published as part of its own proof.

### 5.1 DAG proof

```text
accepted source manifest + INBOX-202I evidence
  -> control generation + lineage + payload-copy receipt
  -> control candidate
  -> dormant main implementation
  -> main validation evidence
  -> control validation receipt
  -> control live declaration
  -> control activation receipt
  -> main activation
  -> optional terminal receipt
```

Every edge points to bytes that already exist. No node contains its own hash.
No declaration and receipt refer to one another in both directions. No
publication group contains its publisher command, receipt, log, verification
result, or terminal receipt.

## 6. Runtime selection and failure semantics

### 6.1 Before main activation

- unset `ZLLVM_ARTIFACT_STORE`: current sibling-derived source authority;
- exact source-authority override: current accepted behavior;
- candidate control metadata: ignored by production;
- destination payload: non-authoritative and never selected;
- missing candidate metadata: irrelevant to current production.

### 6.2 After main activation

The production sequence is closed:

1. open the exact control `live.tsv` no-follow;
2. require exact expected mode, bytes, and SHA-256;
3. canonical parse/re-encode and require one active row;
4. require exact authority ID and generation;
5. open exact generation manifest, lineage, validation receipt, and activation
   receipt no-follow;
6. require their exact pinned hashes, schemas, and referential integrity;
7. resolve payload root only from `live.tsv`;
8. require root canonicality and bidirectional disjointness from all 43+1
   registrations;
9. verify exact store shape and every manifest-referenced object/snapshot;
10. revalidate registration and declaration facts before returning success.

`ZLLVM_ARTIFACT_STORE` is not a selector after activation. If unset, the
control declaration supplies the root. If set, its normalized absolute value
must exactly equal the declared payload root; it is a redundant assertion
only. Any other value fails `authority-override-mismatch`. There is no old
store fallback, candidate fallback, payload-mirror fallback, main-tree mirror
fallback, or environment-only authority.

### 6.3 Closed fail-closed table

| Condition | Required result |
|---|---|
| Candidate exists, live absent, old main | Source authority continues. |
| Candidate exists, live absent, dormant main | Source authority continues; candidate may be tested only through explicit dormant test configuration. |
| Live exists, old main | Source authority continues; old main does not discover control metadata. |
| Live exists, dormant main | Source authority continues; production candidate path remains disabled. |
| Active main and exact live/generation/payload | Local-state authority accepted. |
| Candidate missing or malformed during candidate validation | Stop candidate validation. |
| Live missing after active main | Hard stop; no source fallback. |
| Live state is `candidate`, unknown, or inactive | Hard stop. |
| Generation missing, mismatched, noncanonical, stale, or advanced | Hard stop. |
| Payload missing, partial, extra, wrong mode, wrong hash, or changed link/type | Hard stop. |
| Candidate, lineage, validation, or activation receipt mismatch | Hard stop. |
| `ZLLVM_ARTIFACT_STORE` names source, alternate, relative, or noncanonical path | Hard stop. |
| Registration set changed | Hard stop before payload access or output. |
| Control HEAD advanced but pinned files remain exact | Runtime remains valid; provenance records the newer HEAD separately. |
| Pinned control file changed under a new HEAD | Hard stop. |
| Tracked or payload-store mirror differs | Hard stop in validation/evidence; mirrors never override control. |
| Compatibility target absent/stale/unsafe | Fail the separately authorized compatibility operation; do not change authority. |

## 7. Validation-v3 path treatment

The accepted future operational paths remain those in INBOX-200:

```text
V3=/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3
CANONICAL_SOURCE=/home/oleg/prog/z_llvm/local-state/worktrees/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical-source
COVERAGE_SOURCE=/home/oleg/prog/z_llvm/local-state/worktrees/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage-source
```

The two source paths are protected Git control paths, outside artifact rows
and resolution. Creation, modification, or removal of each requires separate
explicit user authorization naming that exact path. Artifact wrappers may
never enter, stat recursively, hash, publish, copy, materialize, migrate,
clean, or remove either source tree.

Every other v3 input must resolve from one of the 19 active logical references
in the control generation manifest. Existing equal `tmp` files remain
non-authoritative compatibility candidates. Every v3 output family remains
future-required/absent until separately defined and authorized. The current
contract’s old `tmp/.../baseline_validation_v3` paths are not executable after
activation and must be amended before v3 is authorized.

### 7.1 Exact 19 input consumers

The complete logical-ID set that a future v3 pre-wrapper may resolve is:

```text
calls/input/accepted-cohort-ac285/v1
calls/input/compiler-rt-v1/raw/adoption-final/v1
calls/input/compiler-rt-v1/raw/adoption-manifest/v1
calls/input/compiler-rt-v1/raw/module/v1
calls/input/validation-v3/coverage-bundle/manifests/baseline-source.sha256/v1
calls/input/validation-v3/coverage-bundle/manifests/bundle-files.sha256/v1
calls/input/validation-v3/coverage-bundle/manifests/bundled-source.sha256/v1
calls/input/validation-v3/coverage-bundle/manifests/combined-apply-source.sha256/v1
calls/input/validation-v3/coverage-bundle/manifests/future-tool-identities.sha256/v1
calls/input/validation-v3/coverage-bundle/manifests/patch-manifest.tsv/v1
calls/input/validation-v3/coverage-bundle/manifests/payload-final-modes.tsv/v1
calls/input/validation-v3/coverage-bundle/manifests/preflight-and-apply-proof.txt/v1
calls/input/validation-v3/coverage-bundle/manifests/restored-source.sha256/v1
calls/input/validation-v3/coverage-bundle/manifests/sequential-apply-source.sha256/v1
calls/input/validation-v3/coverage-bundle/manifests/touched-paths.txt/v1
calls/input/validation-v3/coverage-bundle/patches/01-aggregate-consumer.patch/v1
calls/input/validation-v3/coverage-bundle/patches/02-fixed-observer.patch/v1
calls/input/validation-v3/coverage-bundle/patches/03-exact-combined-guard.patch/v1
calls/input/validation-v3/coverage-bundle/patches/aggregate-consumer-observer-guard.patch/v1
```

The compiler-rt raw module is the canonical raw-report input. The four core
input references supply AC285 and compiler-rt provenance. The remaining 15
references supply the finite coverage bundle. No object key, snapshot member,
source `tmp` path, or compatibility path may replace a logical ID.

### 7.2 Exact 27 future path families

The accepted local-state operational constants are:

```text
V3=/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3
BOOTSTRAP=$V3/bootstrap
CANONICAL=$V3/canonical
COVERAGE=$V3/coverage
COMPAT=$V3/compatibility
DURABILITY=$V3/durability
CANONICAL_CACHE=/home/oleg/prog/z_llvm/local-state/caches/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical
COVERAGE_CACHE=/home/oleg/prog/z_llvm/local-state/caches/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage
```

All 27 families remain absent and unauthorized:

| # | Exact family | Current authority/consumer classification | Transition rule |
|---:|---|---|---|
| 1 | `$BOOTSTRAP/<preflight-or-driver>/<one-of-nine-record-names>` | Future external launcher records | Finite post-wrapper publication only; no directory publication. |
| 2 | `$V3/{bootstrap,canonical,coverage,compatibility,durability}` and exact closed children | Namespace containers | Never artifact rows or recursive publication sources. |
| 3 | `$CANONICAL_CACHE/{cache,install}/<finite-producer-path>` | Reproducible canonical build state | Only enumerated final regular files may cross into a publication group. |
| 4 | `$CANONICAL/repetition-<1..3>/{home,tmp}/<finite-working-path>` | Ephemeral canonical working state | Never implicit publisher input. |
| 5 | `$CANONICAL/artifact/z_llvm` | Future canonical tool artifact | Finite validation output; not input authority. |
| 6 | `$CANONICAL/artifact/artifact.identity.tsv` | Future artifact identity record | Produced after artifact; never selects store authority. |
| 7 | `$CANONICAL/{status/<step>,records/<step>.<part>}` | Canonical step statuses/records | One producer per exact path. |
| 8 | `$CANONICAL/build/{stdout.raw,stderr.raw,status}` | Canonical build records | Exact three-file set. |
| 9 | `$CANONICAL/repetition-<1..3>/{report.raw,report.status,report.summary.tsv}` | Canonical raw-report family | Consumes only the resolved compiler-rt raw module. |
| 10 | `$CANONICAL/repetition-1/accepted.ll` | Canonical accepted subset | Produced once; later canonical/coverage phases consume read-only. |
| 11 | `$CANONICAL/repetition-1/{accepted.extract.*,accepted.freeze.*,accepted.identity.*}` | Accepted-subset proof | Closed exact proof paths only. |
| 12 | `$CANONICAL/repetition-<1..3>/{accepted.o,owner.tsv,objdump.txt,readelf.txt,text.bin,functions.manifest,owner.ledger.tsv}` | Successful-subset artifacts | Finite outputs, never live input authority. |
| 13 | `$CANONICAL/repetition-<1..3>/functions/<manifest-function-id>/{bytes,disassembly,identity}` | Canonical per-function proof | Function IDs only from the exact sorted manifest. |
| 14 | `$CANONICAL/comparisons/<closed-comparison-name>` | Canonical comparison records | Generated evidence, no recursive publication. |
| 15 | `$CANONICAL/manifests/canonical-identities.tsv` | Canonical identity result | Future output logical ID only after accepted validation. |
| 16 | `$CANONICAL/repetition-<1..3>/final-manifest.tsv` and `$CANONICAL/manifests/canonical-final.tsv` | Canonical terminal manifests | Exclude their own publisher/receipts. |
| 17 | `$COVERAGE_CACHE/{cache,install}/<finite-producer-path>` | Reproducible coverage build state | Excluded from performance; finite final crossings only. |
| 18 | `$COVERAGE/artifact/{z_llvm,artifact.identity.tsv}` | Coverage artifact family | Coverage-only and excluded from performance. |
| 19 | `$COVERAGE/observation-off/{status,records,semantic,functions}/<closed-path>` | Observation-off records | No coverage channel exists before or after this phase. |
| 20 | `$COVERAGE/reference/<closed-canonical-reference-name>` | Canonical read-only reference copies | Exact equality to canonical products; non-authoritative. |
| 21 | `$COVERAGE/observation-on/channels/{report.coverage.tsv,object.coverage.tsv,owner.coverage.tsv}` | Three observation channels | Each absent before its sole producer. |
| 22 | `$COVERAGE/observation-on/{status,records,semantic}/<closed-path>` | Observation-on records | One producer; semantic outputs equal canonical identities. |
| 23 | `$COVERAGE/observation-{off,on}/functions/<manifest-function-id>/{bytes,disassembly,identity}` | Coverage per-function proof | IDs from the canonical sorted manifest only. |
| 24 | `$COVERAGE/comparisons/<closed-comparison-name>` | Coverage comparisons | Generated evidence; never authority. |
| 25 | `$COVERAGE/observation-{off,on}/final/{files.sha256,phase.final.tsv}` and `$COVERAGE/manifests/{final-manifests.sha256,coverage-final.tsv}` | Coverage final manifests | Finite terminal phase evidence, excluding publication evidence. |
| 26 | `$DURABILITY/publication/<group-id>/{command,environment,stdin,stdout,stderr,status,receipt,verification}` | Publication evidence | Group excludes its own publication evidence. |
| 27 | `$DURABILITY/terminal/terminal-ledger.tsv` | V3 terminal evidence | Non-publishable and has no compatibility target. |

The exact finite domains remain: repetitions `1`, `2`, `3`; channels
`report`, `object`, `owner`; record parts `command`, `environment`, `cwd`,
`start`, `end`, `stdout`, `stderr`; and step/comparison/function identifiers
only from their accepted closed manifests. None of these paths is created by
an authority transition.

## 8. Complete validation matrix

Every row requires exact command/environment/status/output records in a later
directive. No row is executed here.

| State | Main behavior | Expected authority result | Required proof |
|---|---|---|---|
| Baseline | Current main, no control authority files | Source authority | Exact current identities and source manifest pair |
| Candidate | Control candidate files, current main | Source authority | Candidate never read by production |
| Candidate mismatch | One candidate fact changed | Source authority; candidate validation fails | Distinct canonical/hash/referential failure |
| Dormant | Candidate + dormant main | Source authority | Production output byte-identical; private candidate test succeeds |
| Dormant missing candidate | Dormant main, candidate path absent | Source authority | No production dependency on candidate |
| Validated | Accepted dormant validation, live absent | Source authority | Validation receipt not yet active |
| Control active / main old | Exact live and receipts, old main | Source authority | No discovery by old main |
| Control active / main dormant | Exact live and receipts, dormant main | Source authority | Production activation remains disabled |
| Fully active | Active main + exact live + exact payload | Local-state authority | Exact declaration, generation, payload, registration, identities |
| Environment unset | Fully active | Local-state authority | Root comes only from live declaration |
| Environment exact new root | Fully active | Local-state authority | Override is redundant exact assertion |
| Environment old source root | Fully active | Hard stop | No fallback |
| Environment alternate/relative/noncanonical | Fully active | Hard stop | Closed override error |
| Missing live | Active main | Hard stop | No candidate/source/mirror fallback |
| Missing generation | Active main | Hard stop | No payload-store mirror fallback |
| Partial destination | Active main | Hard stop | First missing/mismatched identity attributed |
| Stale generation | Active main expects newer than live | Hard stop | No downgrade |
| Advanced generation | Live names unpinned successor | Hard stop | No implicit advance |
| Changed registration | Any candidate/active validation | Hard stop | Pre-access and pre-success revalidation |
| Tracked mirror mismatch | Candidate/active validation | Hard stop in evidence | Mirror cannot become authority |
| Existing exact compatibility file | Separately authorized materializer | Verify, allocate/write nothing | Exact bytes/mode and authority resolution |
| Missing compatibility file | Separately authorized materializer | Atomic no-overwrite create only | Path-specific authority and capacity |
| Stale/unsafe compatibility node | Separately authorized materializer | Hard stop, unchanged | No overwrite/repair |
| Roll back dormant main | Candidate retained | Current main/source authority | Revert only dormant main commit |
| Roll back control activation before main activation | Remove/revert live activation commit only | Source authority | Candidate and both payload stores retained |
| Roll back active main | Revert main activation commit | Source authority | Control live and both stores retained; no deletion |
| Roll forward after rollback | Fresh review of exact commits/hashes | No automatic action | Repeat validation and activation authorization |

## 9. Rollback and preservation

Rollback is Git/configuration-only and phase-specific:

- never delete, rewrite, repair, normalize, or clean either payload store;
- never mutate the accepted source generation or tracked manifest;
- never remove the copied destination payload;
- never rewrite control history;
- never make a candidate active by deleting a newer declaration;
- never use environment override as rollback;
- never change compatibility paths as part of authority rollback.

Before main activation, reverting a control activation commit returns control
to candidate-only state while main remains on the source authority. After main
activation, revert the main activation first; this restores the source
authority without requiring any payload or control mutation. A later control
revert is a separate explicit action. Both stores and all manifests remain for
audit and renewed review.

## 10. Structural blockers and later review gates

The frozen tool does **not** currently provide the required
control-declaration parser, control-manifest resolver, exact active binding,
or post-activation no-fallback semantics. Its existing `resolve-authority`
surface resolves only a path, and `materialize-spec` is not an authority
transition API. Therefore:

1. authority activation is structurally blocked until a separate dormant
   implementation is designed, implemented, and accepted;
2. no existing CLI may be repurposed by invented arguments or undocumented
   environment variables;
3. the control candidate commit must precede dormant implementation;
4. candidate validation must precede control activation;
5. control activation must precede main activation;
6. v3 contract amendment and execution remain later, separate directives.

Every later mutation additionally requires fresh capacity, frozen 43+1
registration, exact no-follow ancestry, path-specific authorization, clean
main/control state, exact manifest and payload hashes, and a fail-closed
single-attempt protocol.

## 11. Static closure

The design closes with:

```text
current_authority=source
destination_authority=none
future_semantic_authority=control_live_selected_control_generation_manifest
future_payload_authority=exact_manifest_named_local_state_payload_bytes
payload_store_manifest=non_authoritative_mirror_only
main_tree_manifest=non_authoritative_mirror_only
candidate_is_never_active=true
fallback_to_source_after_activation=false
authority_fact_owners=unique
control_dag=acyclic
terminal_evidence=finite_nonrecursive
protected_source_paths=outside_artifact_resolution
validation_v3=unauthorized
ratchet=131
next=STOP_FOR_WATCHER_REVIEWER_AUTHORITY_TRANSITION_DESIGN_REVIEW
```
