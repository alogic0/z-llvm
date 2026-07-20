# INBOX-206C Real-Candidate Four-Root Safety Diagnosis

## 1. Scope and disposition

This is the evidence/design-only diagnosis authorized by operating commit
`e94165f09b9e5e994f0e0215ae4ffe0303eb5d3f`, whose parent is the accepted
INBOX-206B operating commit
`cc1ee36cc1017c5b093952ae61e244b7ef438233`.

INBOX-206B's corrected structural guard is accepted. Its sole filtered test
then failed compliantly, so Phase-3 candidate acceptance remains withheld.
This document does not remediate the validator or authorize another
validation attempt.

No source, contract, build, test, control, store, manifest, path, mode,
registration, worktree, pin, stash, watcher, or retained-evidence byte is
changed. No preflight, structural guard, Zig command, test, validator, state
guard, project command, or ratchet recount was run. The only tracked change
is this document.

The authority state remains:

```text
source_authority=/home/oleg/prog/z_llvm-artifacts
destination=/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1
destination_authority=non-authoritative
control_candidate=inert
phase_3_candidate_acceptance=withheld
ratchet=131
```

## 2. Frozen evidence

### 2.1 Accepted dormant implementation

The accepted technical baseline is
`b71d2d5068fba68fbf1b71785339febb69e49485`. Its private validator remains
production-unreachable. The accepted source evidence freezes:

```text
tool_sha256=306b3b21c182ae5031d71d82a38744c05161f0519ea80ff2cc20784e21a21f15
control_commit=9c55bda34088e1230b0b91a126d35795a3ac70b4
control_tree=756369ad4a89d806f463bd8094c5159d8c973d7e
control_branch=main
control_remote_count=0
control_status=clean
main_registered_worktrees=43
supplemental_control_worktrees=1
protected_union=44
main_path_list_sha256=f31d8542baafc7b64cd5ee6fe8cc4194842ca696b97a7ffc8df06ce12d553d7e
main_topology_sha256=6c868e3b6d436cfba92a1e2b21dbd616391763961f1cba9b6670b1ed4a6ebb62
main_non_main_sha256=ebc30a376b3db4c6fbf788f49ea85f4ce792471e539c0a89308068efdf96ebbe
```

The exact four admitted control files are:

| Relative path | Bytes | Mode | SHA-256 |
|---|---:|---:|---|
| `authority/zllvm/v1/manifests/candidate.tsv` | 899 | `0644` | `7c0aa46fb6c0cb2b93034bbb6b520b6d4831fedea333983002622197a74c832b` |
| `authority/zllvm/v1/manifests/generation-00000001.tsv` | 27,823 | `0644` | `61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d` |
| `authority/zllvm/v1/lineage/generation-00000001.tsv` | 378 | `0644` | `f8b22b687f3d3cb727ba82e92c3a346c7025958387f3a45d4143fb42936c6a3a` |
| `authority/zllvm/v1/receipts/publication/generation-00000001-payload-copy.tsv` | 792 | `0644` | `9c6748234292c963c9716504a1451c4da0cdb0fe2ce1642d1c5fa83264aa19a3` |

The source/copy identities supplied to the retained private harness are:

```text
source_generation_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
source_inventory_sha256=3234fb508d370878efe082cf1accb5af3b488372bf3f1ee7e9e87408a37a2d7c
source_file_ledger_sha256=a06c48e1549d16b9f924cc2b5f0404e60d7755a785bf3a4a23311c2383279a65
source_destination_ledger_sha256=4c29709b9ef9242dd799ab52d346cdf302f5728d35e37e0d78063e892a6cf9e8
copy_evidence_path=docs/evidence/inbox202_local_state_artifact_copy_verify.md
copy_evidence_sha256=4b532daabe33e7c6eaca7f0ab412d9c271b55b6b1de8235dd3d4f65d7ab6f7a6
```

### 2.2 Retained INBOX-206A/B evidence

All 28 INBOX-206A files remain frozen at inventory `787512bf...` and
absolute-path ledger `8d5440bc...`. All INBOX-206B records and all 824
isolated-cache files remain frozen beneath:

```text
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206b
```

Relevant retained identities are:

```text
B_structural_guard_command=83345f962fd069911d5608a664904e18faa3c13159de598b99c559485025c12d
B_structural_guard_environment=c77bf0e66837bef718aa910bf9f4c63725b7f280596d9b21ab9371a78d657128
B_structural_guard_invocation=07ec00430529cf1f44079f0eadddc7abeaf958cc5f1a9ad6af996ff554fc35df
B_structural_guard_status=0
B_structural_guard_stdout=61fee1261eaf98703d5c6e76bf5ae6c7306aee679d172dd4513ac68f678d9960
B_structural_guard_stderr=empty
B_harness_sha256=91ae649a2872df606b2b2711d4eb3ddbc9eac3d677626b2cde95b1fadc1f196e
B_test_command_and_invocation_sha256=145e2904cb07b734603dfc172f2596a1b5a952d8484af8dbe72accc58c63aa44
B_test_status=1
B_test_stdout_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
B_test_stderr_sha256=fdd68bcb11dd35f48873e73dd75087de52556abf6786d62895df89dafd595e84
B_call_graph_sha256=9cee6e2d8bfe95483f6c967422ee3977619ed3b065c09ea0e0144a12d13a2396
```

The retained stderr proves exactly one executed test and the first failure:

```text
1/1 ... FAIL (DormantUnsafeRoot)
RegistrationGuard.assertDisjointFromEveryRegistration
  -> RegistrationGuard.assertStoreRoot
  -> validateDormantRoots
  -> validateDormantAuthorityCandidate
0 passed; 0 skipped; 1 failed
```

The success-only state guard was not run.

## 3. Root-cause attribution

`validateDormantRoots` currently loops over `control_root`,
`authority_root`, `payload_root`, and `source_root` and applies the same
three rules to each:

1. normalized absolute path;
2. `RegistrationGuard.assertStoreRoot`, which requires bidirectional
   disjointness from all 43 main-repository registrations; and
3. existing no-follow directory with mode exactly `0755`.

Those rules are valid for a generic external store root but not for the
accepted four-role boundary:

- `control_root` is an independent protected repository intentionally
  located under the registered main path;
- `authority_root` is exact metadata beneath that protected control
  repository;
- `payload_root` is the exact reviewed payload tree beneath anchored
  main-local `/local-state/`; and
- `source_root` is the external legacy authority and is mode `0775`.

The first failure occurs before control metadata or payload bytes are read.
`assertDisjointFromEveryRegistration` sees the accepted `control_root` below
the main registered path and rejects it. Even if that single conflict did
not exist, the uniform `0755` check would reject the accepted `control_root`
and `source_root`, both mode `0775`.

The defect is therefore the root-role model in the private dormant
validator. It is not a candidate-schema, manifest, payload, receipt, source
identity, or production-selection failure. A one-path exception or mode
normalization would conceal rather than correct that model.

## 4. Closed four-root matrix

| Root | Exact accepted path and mode | Semantic/authority owner | Git containment and protection | Exact permitted read scope | Forbidden scope | Prospective admission and owning private function | Current/prospective errors |
|---|---|---|---|---|---|---|---|
| `control_root` | `/home/oleg/prog/z_llvm/local-state/control`, `0775` | Independent supplemental control repository; inert candidate metadata only | Below the registered main path and itself a separately protected repository; protection union is 43 main plus one control | Exact repository identity (`9c55bda3…`, tree `756369ad…`, branch `main`, clean, no remote); no-follow directory identity; and only the four exact `0644` files listed in §2.1 | Recursive enumeration, generic subtree reads, payload reads, writes, Git mutation, alternate metadata, live/validation/activation/terminal records | `validateDormantControlRoot` plus the existing exact-key `readDormantControlFile`; exact byte equality must precede the intentional main-containment allowance | Root/identity/ancestry failure remains `DormantUnsafeRoot`; exact file failures retain `Dormant{Candidate,Generation,Lineage,Receipt}{Missing,Malformed,Mismatched,Unsafe}` |
| `authority_root` | `/home/oleg/prog/z_llvm/local-state/control/authority/zllvm/v1`, `0755` | Fixed metadata namespace inside the control repository; not a payload store | Exact descendant of `control_root` and main; overlap with the control repository is required, not an exception inferred from topology | No-follow checks of the exact `authority/zllvm/v1` chain solely to reach the four admitted files | Listing/discovery, any sibling/unknown descendant, payload treatment, mutation, escape from exact control root | `validateDormantAuthorityRoot`; require exact path construction from the already admitted `control_root`, exact `0755`, and disjointness from every non-main registration | Path, ancestry, mode, role escape, or registration drift fails `DormantUnsafeRoot`/`DormantRegistrationStale`; component files retain their specific errors |
| `payload_root` | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1`, `0755` | Non-authoritative verified payload copy; source remains authoritative | Exact reviewed descendant of anchored `/home/oleg/prog/z_llvm/local-state/artifacts`; below main only, disjoint from every non-main registration and from the supplemental control repository | No-follow exact-root/ancestry checks, followed by the existing manifest-bounded closed-tree inspection of `incoming`, `objects/sha256`, `snapshots/sha256`, and declared immutable files | Access outside the exact tree, unknown entries, symlinks, writes, repair, normalization, compatibility materialization, control/source traversal | `validateDormantPayloadRoot` gates existing `verifyDormantDestination`; only this byte-exact root may bypass disjointness from the main registration | Missing expected state is `DormantDestinationPartial`; extra, mismatched, or unsafe state retains `DormantDestination{Extra,Mismatched,Unsafe}`; root/role escape is `DormantUnsafeRoot` |
| `source_root` | `/home/oleg/prog/z_llvm-artifacts`, `0775` | Current authoritative legacy source | External to main and control; must remain bidirectionally disjoint from all 43+1 protected worktrees and from authority/payload | No-follow ancestry/root identity and mode only; compare the exact path and already frozen manifest/inventory/ledger identities carried by candidate/lineage/receipt validation | Source-tree enumeration, payload reads, mutation, normalization, copying, publication, fallback selection, or deriving a new identity | `validateDormantSourceRoot`; exact path equality first, then existing generic registration disjointness, accepted `0775`, and source identity-only checks | Unsafe path/ancestry/mode is `DormantUnsafeRoot`; changed registration is `DormantRegistrationStale`; candidate/lineage/receipt source bindings retain their specific mismatch errors |

### 4.1 Ownership distinctions

Three different ownership concepts must not be conflated:

| Concept | Closed owner |
|---|---|
| Current semantic authority | exact legacy source plus accepted generation manifest |
| Candidate metadata | four exact files committed in the supplemental control repository |
| Candidate payload bytes | exact non-authoritative local-state payload tree |
| In-memory path and expected identities | allocator-owned fields of private `DormantAuthorityConfig` |
| Registration snapshot | owned `RegistrationGuard.frozen`, revalidated before and after candidate validation |
| Production selection | unchanged `resolveAuthority`/`main`; candidate metadata has no caller |

No root path, file bytes, or identity may be borrowed from transaction-like
temporary storage. The existing owned configuration model remains the right
lifetime boundary.

## 5. Role-specific admission policies

### 5.1 Exact-file control admission

Control admission is not store admission.

The prospective private validator must first require byte equality with:

```text
/home/oleg/prog/z_llvm/local-state/control
```

It then requires the frozen supplemental-repository facts:

```text
commit=9c55bda34088e1230b0b91a126d35795a3ac70b4
tree=756369ad4a89d806f463bd8094c5159d8c973d7e
branch=main
status=clean
remote_count=0
root_mode=0775
```

Repository identity checking is a bounded, read-only control-repository
operation. It is not permission to recursively walk the filesystem. Content
access is limited to the four exact paths in §2.1, opened no-follow and
required to be regular mode-`0644` files. Their exact ancestor chain may be
opened no-follow; no directory may be listed to discover inputs.

The known four-file allowlist must be enforced before
`readDormantControlFile` opens a path. A syntactically safe but unlisted key
is still rejected. Missing live/validation/activation/terminal files remain
expected and are not read.

### 5.2 Narrow authority-root admission

`authority_root` is accepted only when constructed from the exact admitted
`control_root` plus the literal components:

```text
authority/zllvm/v1
```

The exact result must be mode `0755`. Its containment within both main and
control is intentional. The allowance is therefore:

```text
role == authority_root
AND path == exact reviewed authority path
AND control_root == exact admitted control root
AND path is the literal authority/zllvm/v1 descendant
```

It is not “any main descendant,” “any control descendant,” or a
function/caller-name exception. Any alternate generation root, sibling,
symlinked component, relative spelling, normalized difference, or overlap
with a non-main registration fails closed.

### 5.3 Narrow payload-root admission

`payload_root` is accepted only at:

```text
/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1
```

The complete predicate requires:

- normalized absolute byte equality;
- exact anchored components beneath `/local-state/artifacts`;
- mode `0755`;
- no symlink/non-directory ancestry;
- no intersection with any non-main registration;
- no intersection with the supplemental control repository;
- no intersection with `authority_root` or `source_root`; and
- the existing closed payload-tree verification.

Only the exact main-registration overlap implied by this one path is
admitted. No generic main-descendant helper or caller-based bypass is
acceptable.

### 5.4 Exact external-source admission

`source_root` remains exactly:

```text
/home/oleg/prog/z_llvm-artifacts
```

It must be normalized, no-follow, mode `0775`, external to every registration,
and disjoint from control, authority, and payload. The dormant validator
does not enumerate or hash source descendants. It validates only the exact
root role and the already frozen source identities bound by candidate,
lineage, and receipt metadata.

The source is not a fallback selected after candidate failure. Candidate
validation failure returns its attributed error while production remains
independently and unchanged on the old source.

### 5.5 Role-specific modes

The closed root-mode table is:

```text
control_root=0775
authority_root=0755
payload_root=0755
source_root=0775
control_metadata_files=0644
payload_objects_and_snapshots=0444
payload_internal_directories=0755
```

No `chmod`, normalization, repair, or mode inheritance is proposed. A mode
outside the exact role value fails closed.

## 6. Registration and containment policy

The main registration snapshot remains owned by `RegistrationGuard` and
retains its existing 43-worktree checks. The supplemental control repository
is an additional exact protected root, not an entry to silently append to
the generic main snapshot.

Prospective role checks are:

| Role | Main registration | Non-main registrations | Supplemental control |
|---|---|---|---|
| control | exact reviewed containment required | disjoint | exact equality required |
| authority | exact reviewed containment required | disjoint | exact reviewed containment required |
| payload | exact reviewed containment required | disjoint | disjoint |
| source | disjoint | disjoint | disjoint |

Every check is bidirectional where disjointness is required. Registration
identity must be frozen before access and revalidated before successful
return. A changed main registration yields `DormantRegistrationStale`.
A changed supplemental control identity, registration, clean state, branch,
remote set, or exact file set is a control-root failure; it never downgrades
to source fallback.

This design does not weaken the standing protection of any other registered
worktree. It defines only exact reviewed reads for the four candidate roles.

## 7. Smallest prospective private change map

No change below is authorized by INBOX-206C. This is the bounded ownership
map for a later remediation review.

| Private owner | Current behavior | Smallest prospective change | Explicitly frozen |
|---|---|---|---|
| `DormantAuthorityConfig` | Owns four paths, source/copy identities, and main registration facts | Own exact expected control commit/tree/branch/clean/no-remote facts and the four-file allowlist identities; no borrowed storage | Visibility, production reachability, CLI/environment, public API |
| `validateDormantRoots` | Uniform loop calling `assertStoreRoot` and requiring `0755` | Remain sole root orchestrator, but call four closed role validators in fixed order: control, authority, payload, source; then apply exact inter-role relations | Candidate parsing/materialization order and pre/post registration checks |
| private control-root validator | Absent | Exact root/repository identity and mode `0775`; no generic store check | `RegistrationGuard.assertStoreRoot` |
| private authority-root validator | Absent | Exact literal descendant of admitted control, mode `0755`, non-main disjointness | No general control/main-descendant permission |
| private payload-root validator | Absent | Exact pinned local-state payload path, mode `0755`, non-main/control disjointness | Existing closed payload schema and verification |
| private source-root validator | Absent | Exact external root, mode `0775`, generic 43-registration disjointness, identity-only access | Source bytes and production authority |
| `readDormantControlFile` | Safe relative key, no-follow component walk, but root mode hard-coded `0755` and an iterable root handle | Admit only the four literal keys; require control root `0775`, authority directories `0755`, files `0644`; open exact components without discovery | Parsers, hashes, size limits, component-specific errors |
| `verifyDormantDestination` / `inspectDormantTree` | Enumerates the manifest-closed payload shape and verifies immutable files | No semantic change; invoke only after exact payload-root admission | Relationships, counts, hashes, modes, extra/partial/unsafe errors |
| `validateDormantAuthorityCandidate` | Registration, roots, four metadata inputs, payload, registration | Preserve exact statement order and first attribution | Entire parse/re-encode and referential model |
| `RegistrationGuard` generic methods | Generic normalized registration disjointness | Remain byte-for-byte behaviorally unchanged; dormant role logic must be private and separate | Production plan/publish/store callers |
| `docs/zllvm_artifact_retention_contract.md` | Incorrectly states all configured roots are disjoint and `0755` | Replace only that uniform statement with the accepted four-role matrix and negative policy | Frozen production-boundary and candidate-inert sections |

No public symbol, production caller, CLI verb, environment variable,
selector, callback, generic role API, or build edge is required or allowed.
If private same-file code cannot express the matrix, that is a structural
stop rather than authority to widen the surface.

## 8. Fail-closed negative matrix

| Negative | Required first result |
|---|---|
| Any root differs from its exact reviewed absolute spelling | `DormantUnsafeRoot` |
| Relative, non-normalized, empty-component, `.`/`..`, or symlinked ancestry | `DormantUnsafeRoot` |
| Control/source not `0775`; authority/payload not `0755` | `DormantUnsafeRoot` |
| Control commit/tree/branch/clean/no-remote identity differs | control-root hard stop; no candidate parsing |
| Control exact tracked/input file set differs | component-specific missing/unsafe/mismatch or control-root hard stop |
| A fifth control metadata path is requested | component unsafe; no open |
| Authority root escapes exact `control/authority/zllvm/v1` | `DormantUnsafeRoot` |
| Payload root is any other main descendant | `DormantUnsafeRoot` |
| Source root is any other external directory | `DormantUnsafeRoot` |
| Main or supplemental registration changes | `DormantRegistrationStale` before success |
| Authority/payload intersects a non-main registration | `DormantUnsafeRoot` |
| Payload intersects control; source intersects any registration/root | `DormantUnsafeRoot` |
| Payload expected entry missing | `DormantDestinationPartial` |
| Payload has undeclared entry | `DormantDestinationExtra` |
| Payload file hash/bytes/mode differs | `DormantDestinationMismatched` |
| Payload component is symlink or wrong type | `DormantDestinationUnsafe` |
| Candidate/lineage/receipt source identity differs | existing component-specific `Mismatched` error |
| Any attempted write, repair, normalization, retry, or fallback | prohibited operation; validation must not begin/continue |

Errors remain explicit. There is no Boolean fallback and no retry against
the old source, a mirror, another root, or a different metadata generation.

## 9. Reconciliation with prior contracts

- `inbox199_local_state_boundary.md` establishes the independent control
  repository and 43+1 protection union. Exact control-file admission is a
  narrow protected-repository read, not recursive artifact traversal.
- `inbox200_local_state_v3_path_model.md` assigns exact closed roles beneath
  anchored `/local-state/` and rejects role inference from containment. The
  authority/payload predicates above follow that rule.
- `inbox201_local_state_artifact_authority_bootstrap.md` freezes the payload
  root and its internal directories at `0755` while leaving it
  non-authoritative.
- `inbox203_local_state_authority_transition_design.md` keeps source
  authoritative through dormant validation, assigns candidate metadata to
  control, and requires an acyclic later activation sequence.
- `zllvm_artifact_authority_dormant_v1.md` freezes the private owned
  validator, exact four inputs, destination reconciliation, first-attributed
  errors, and production non-reachability.
- `docs/zllvm_artifact_retention_contract.md` correctly freezes production
  selection and candidate inertness, but its uniform root/disjointness/mode
  paragraph is the specific prospective documentation correction identified
  here.
- The retained B call graph proves the validator is read-only and private;
  the retained test stack proves root admission fails before metadata or
  payload validation.

## 10. Structural blockers

Phase-3 remains blocked until a later directive explicitly resolves all of
the following:

1. The current source has no role-specific root admission; it has only the
   uniform `validateDormantRoots` loop.
2. `RegistrationGuard` captures only the main 43-worktree inventory. Exact
   supplemental-control commit/tree/branch/clean/no-remote validation is not
   represented in `DormantAuthorityConfig`.
3. `readDormantControlFile` still requires control-root mode `0755` and does
   not itself enforce the closed four-key allowlist.
4. The retention contract still states the rejected uniform-disjointness and
   uniform-`0755` model.
5. Any future implementation directive must expressly authorize the exact
   protected control-file reads and exact payload-tree inspection described
   here. This document grants no worktree traversal or mutation authority.
6. If exact control cleanliness cannot be established without broad
   filesystem discovery, the implementation must stop for a narrower
   reviewed control-identity mechanism rather than weaken protection.
7. If the role split requires a public helper, production callsite, generic
   main-descendant exception, or altered production resolver, it is outside
   the bounded remediation and is a structural stop.

No blocker is resolved by changing a path, changing a mode, broadening
`assertStoreRoot`, or treating the candidate as active.

## 11. Closure

```text
diagnosis=uniform_store_root_policy_applied_to_four_distinct_roles
control_admission=exact_repository_plus_four_files_only
authority_admission=exact_control_descendant_only
payload_admission=exact_pinned_main_local_state_payload_only
source_admission=exact_external_identity_only
generic_registration_guard=unchanged
production_authority_selection=unchanged
candidate=inert
source=authoritative
phase_3=withheld
source_changes=0
external_changes=0
commands_rerun=0
ratchet=131
next=STOP_FOR_WATCHER_REVIEWER_ROOT_SAFETY_DESIGN_REVIEW
```
