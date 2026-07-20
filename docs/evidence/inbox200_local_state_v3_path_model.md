# INBOX-200 Local-State v3 Path Model

## 1. Scope and authority

This documentation-only reconciliation starts from exact operating commit
`cf518a8d62b23e5ebdc088b75ec512e382a2a30f`, parent
`84a52011cc810d46c852d1226c254a05a3a5f4c4`.

INBOX-199L is accepted at:

```text
main_commit=84a52011cc810d46c852d1226c254a05a3a5f4c4
main_tree=f0edde6f5b5344f3fbd2cb33d62f3334bf2a3784
control_commit=a41690a4c47cf1040afe3d4dd3679a77015263ea
control_tree=67582eb6f4de0b3ab3a2ef2e7c3635c79349d00e
```

This document is authoritative over only the sibling-root portions of
INBOX-198. Every earlier evidence byte remains unchanged. INBOX-199 remains
withdrawn before edit and is not resumed.

No prospective path defined here exists merely because it is named. Creation,
registration, migration, materialization, publication, execution, cleanup,
and mutation all require later exact-path authority.

## 2. Frozen current boundary

The current repositories and authority remain:

```text
main_repository=/home/oleg/prog/z_llvm
main_branch=x86_64-codegen-expanded-frontier
control_repository=/home/oleg/prog/z_llvm/local-state/control
control_branch=main
control_remote_count=0
main_registered_worktrees=43
control_registered_worktrees=1
protected_union_count=44
authoritative_artifact_store=/home/oleg/prog/z_llvm-artifacts
tracked_live_manifest=/home/oleg/prog/z_llvm/docs/evidence/artifact_manifest_v1.tsv
tracked_live_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
artifact_tool_sha256=94dfc1fc27ffe1268eb02453bcac1a3634aa11af38d0c94fbaa3b43decd25859
watcher_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash_object=7985c6d01040a6e47e4ce5b918866d0e89517ac7
pins_sha256=1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
audit_sha256=5a7e019eb107e5b66947490a65fdf47444154fc4f1483ca30ab0fc6e381f33e6
ratchet=131
validation_v3=absent_and_unauthorized
```

The main registration identities remain:

```text
path_list_sha256=f31d8542baafc7b64cd5ee6fe8cc4194842ca696b97a7ffc8df06ce12d553d7e
path_topology_sha256=6c868e3b6d436cfba92a1e2b21dbd616391763961f1cba9b6670b1ed4a6ebb62
non_main_records_sha256=ebc30a376b3db4c6fbf788f49ea85f4ce792471e539c0a89308068efdf96ebbe
distribution=33_repository_tmp_8_system_tmp_2_elsewhere
```

The protected control repository is byte-identical to its accepted initial
commit and remains clean. Nothing in this document authorizes a control
commit.

## 3. Closed prospective role roots

The exact local-state boundary is:

```text
LOCAL=/home/oleg/prog/z_llvm/local-state
```

Its closed prospective roles are:

```text
ARTIFACTS=/home/oleg/prog/z_llvm/local-state/artifacts
VALIDATIONS=/home/oleg/prog/z_llvm/local-state/validations
WORKTREES=/home/oleg/prog/z_llvm/local-state/worktrees
CACHES=/home/oleg/prog/z_llvm/local-state/caches
CONTROL=/home/oleg/prog/z_llvm/local-state/control
```

`CONTROL` alone exists. The other four roots are reserved and absent.
Containment beneath `LOCAL` supplies no role or authority. A path is admitted
only by an exact role-specific family below.

### 3.1 Prospective artifact payload authority

```text
PAYLOAD_AUTHORITY=/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1
PAYLOAD_OBJECTS=/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1/objects/sha256
PAYLOAD_SNAPSHOTS=/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1/snapshots/sha256
PAYLOAD_INCOMING=/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1/incoming
```

Prospective immutable object paths have exactly:

```text
$PAYLOAD_OBJECTS/<first-two-lowercase-sha256>/<remaining-62-lowercase-sha256>
```

Prospective immutable snapshot paths have exactly:

```text
$PAYLOAD_SNAPSHOTS/<first-two-lowercase-sha256>/<remaining-62-lowercase-sha256>.tar.zst
```

`PAYLOAD_INCOMING` may later hold only transaction-scoped, no-follow,
same-authority incoming files under a separately authorized mutation. It is
not authority, discovery input, or retained metadata.

Only payload bytes belong beneath `ARTIFACTS`. Manifests, lineage records,
receipts, source worktrees, validation records, compatibility targets,
build/install state, and caches do not.

### 3.2 Prospective v3 operational root

```text
V3=/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3
BOOTSTRAP=/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/bootstrap
CANONICAL=/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical
COVERAGE=/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage
COMPAT=/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility
DURABILITY=/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/durability
```

All v3 operational outputs, records, comparisons, channels, accepted subsets,
finite publisher sources, compatibility targets, and finalizers belong to an
exact family beneath `V3`. No operational output belongs in `CONTROL`, a
source worktree, or the payload authority.

### 3.3 Prospective protected source repositories

```text
CANONICAL_SOURCE=/home/oleg/prog/z_llvm/local-state/worktrees/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical-source
COVERAGE_SOURCE=/home/oleg/prog/z_llvm/local-state/worktrees/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage-source
```

These are two distinct future supplemental repositories. Creating either
requires explicit user authority naming that exact path. Every later
modification or removal also requires explicit path-naming authority.

Once created, each repository and its complete tree is excluded from artifact
discovery, hashing, publication, resolution, materialization, migration,
cleanup, and mutation except for separately authorized Git/source operations.
Neither path is an artifact row or a publisher source.

### 3.4 Prospective producer cache and install roots

```text
CANONICAL_CACHE=/home/oleg/prog/z_llvm/local-state/caches/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/cache
CANONICAL_INSTALL=/home/oleg/prog/z_llvm/local-state/caches/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/install
COVERAGE_CACHE=/home/oleg/prog/z_llvm/local-state/caches/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage/cache
COVERAGE_INSTALL=/home/oleg/prog/z_llvm/local-state/caches/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage/install
```

Every descendant is producer-owned and must be named by a finite producer
plan before creation. No cache/install directory may be recursively
discovered, globbed, published, treated as authoritative, or used as an
implicit final-output set. Only separately enumerated final no-follow regular
files may cross from a producer install area into a finite publisher-source
list.

### 3.5 Prospective protected metadata paths

```text
CONTROL_AUTHORITY=/home/oleg/prog/z_llvm/local-state/control/authority/zllvm/v1
CONTROL_LIVE_MANIFEST=/home/oleg/prog/z_llvm/local-state/control/authority/zllvm/v1/manifests/live.tsv
CONTROL_GENERATION_MANIFEST=/home/oleg/prog/z_llvm/local-state/control/authority/zllvm/v1/manifests/generation-<8digits>.tsv
CONTROL_LINEAGE=/home/oleg/prog/z_llvm/local-state/control/authority/zllvm/v1/lineage/generation-<8digits>.tsv
CONTROL_PUBLICATION_RECEIPT=/home/oleg/prog/z_llvm/local-state/control/authority/zllvm/v1/receipts/publication/<group-id>.tsv
CONTROL_TERMINAL_RECEIPT=/home/oleg/prog/z_llvm/local-state/control/authority/zllvm/v1/receipts/terminal/terminal-ledger.tsv
```

These are metadata-only paths in the protected control repository. Every file
must remain within the 1 MiB per-file and 16 MiB total tracked-payload limits
unless a later directive explicitly changes them. Payload objects, snapshots,
archives, binaries, source payloads, caches, build outputs, validation output,
and generated large files are prohibited.

Operational publication commands, stdout/stderr/status records, verification
results, and candidate receipts are first finite outputs under `DURABILITY`.
Only a later exact-path control commit may accept the small canonical
manifest, lineage, or receipt metadata above.

## 4. Nineteen active logical-reference compatibility mappings

Each active logical reference has exactly one operational role:
`validation-compatibility-target`. Its one prospective absolute path is
listed below. The authoritative logical-reference row remains in the current
tracked/live manifest until migration; its target payload remains in the
current authoritative store. Thus the mapping does not assign a second
authority role to the logical reference.

| Logical ID | Role | Exact prospective path | Mode |
|---|---|---|---:|
| `calls/input/accepted-cohort-ac285/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/accepted-cohort-ac285/v1/payload` | `0664` |
| `calls/input/compiler-rt-v1/raw/adoption-final/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/compiler-rt-v1/raw/adoption-final/v1/payload` | `0444` |
| `calls/input/compiler-rt-v1/raw/adoption-manifest/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/compiler-rt-v1/raw/adoption-manifest/v1/payload` | `0444` |
| `calls/input/compiler-rt-v1/raw/module/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/compiler-rt-v1/raw/module/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/baseline-source.sha256/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/manifests/baseline-source.sha256/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/bundle-files.sha256/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/manifests/bundle-files.sha256/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/bundled-source.sha256/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/manifests/bundled-source.sha256/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/combined-apply-source.sha256/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/manifests/combined-apply-source.sha256/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/future-tool-identities.sha256/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/manifests/future-tool-identities.sha256/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/patch-manifest.tsv/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/manifests/patch-manifest.tsv/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/payload-final-modes.tsv/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/manifests/payload-final-modes.tsv/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/preflight-and-apply-proof.txt/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/manifests/preflight-and-apply-proof.txt/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/restored-source.sha256/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/manifests/restored-source.sha256/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/sequential-apply-source.sha256/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/manifests/sequential-apply-source.sha256/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/touched-paths.txt/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/manifests/touched-paths.txt/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/patches/01-aggregate-consumer.patch/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/patches/01-aggregate-consumer.patch/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/patches/02-fixed-observer.patch/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/patches/02-fixed-observer.patch/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/patches/03-exact-combined-guard.patch/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/patches/03-exact-combined-guard.patch/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/patches/aggregate-consumer-observer-guard.patch/v1` | validation compatibility target | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/compatibility/inputs/calls/input/validation-v3/coverage-bundle/patches/aggregate-consumer-observer-guard.patch/v1/payload` | `0444` |

Each target requires a later exact-path directive, authoritative logical-ID
resolution, exact payload verification, frozen union registration, no-follow
ancestor checks, capacity proof, and atomic no-overwrite materialization.
None exists now.

## 5. Complete 27-family future mapping

The finite domains remain those accepted by INBOX-196/198: `<N>` is `1`, `2`,
or `3`; step sets are closed; record parts are closed; channels are `report`,
`object`, or `owner`; and function IDs come only from the corresponding
sorted generated manifest.

Every family has exactly one primary role and one prospective absolute
path/family. A producer/consumer entry never grants creation or publication.

| # | Family | Primary role | Exact prospective path/family | Producer and consumers | Publication rule |
|---:|---|---|---|---|---|
| 1 | external preflight/driver records | validation record | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/bootstrap/<external-kind>/<external-name>` | sole launcher; bootstrap review; terminal evidence | each enumerated regular file may be a finite source; directory never is |
| 2 | namespace parents | validation namespace | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3` with the exact `bootstrap`, `canonical`, `coverage`, `compatibility`, and `durability` children | separately authorized bootstrap; all phase producers | namespace paths are never sources |
| 3 | canonical build cache/install descendants | producer cache/install | `/home/oleg/prog/z_llvm/local-state/caches/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/{cache,install}/<finite-producer-path>` | canonical builder; canonical artifact finalizer | no recursion; only enumerated final regular files may cross roles |
| 4 | canonical repetition home/tmp | validation working record | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/repetition-<N>/{home,tmp}/<finite-working-path>` | one repetition report producer | ephemeral and never implicit source |
| 5 | canonical z_llvm artifact | validation output | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/artifact/z_llvm` | canonical install finalizer; canonical and coverage producers | one enumerated no-follow regular source |
| 6 | canonical artifact identity | validation output | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/artifact/artifact.identity.tsv` | identity producer; canonical/coverage preflight and review | one enumerated regular source |
| 7 | canonical step status/records | validation record | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/{status/<canonical-step>,records/<canonical-step>.<record-part>}` | one step runner; canonical finalizer/review | closed enumerated set excluding publication records |
| 8 | canonical build raw/status | validation record | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/build/{stdout.raw,stderr.raw,status}` | sole canonical builder; identity/review | exact three files only |
| 9 | repetition raw-report family | validation output | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/repetition-<N>/{report.stdout,report.stderr,report.status,report.summary,failures.ordered,failures.sorted,frontier.tsv,frontier.grouped.tsv}` | report producer/parsers; accepted subset/comparisons | exact closed set only |
| 10 | canonical accepted.ll | validation accepted subset | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/repetition-1/accepted.ll` | repetition-1 extractor; all object/owner producers | exact read-only regular source |
| 11 | accepted.ll proof family | validation record | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/repetition-1/{accepted.extract.*,accepted.freeze.*,accepted.identity.*}` limited to the accepted exact proof names | accepted-subset finalizer; phase preflight | exact named files only; `*` is notation, never glob authority |
| 12 | repetition successful subset | validation output | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/repetition-<N>/{accepted.o,owner.tsv,objdump.txt,readelf.txt,text.bin,functions.manifest,owner.ledger.tsv}` | exact producers; identity/comparison finalizers | exact closed files only |
| 13 | canonical per-function family | validation output | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/repetition-<N>/functions/<function-id>/{bytes,disassembly,identity}` | manifest-bounded extractor; 285/0/0 comparisons | finite manifest-derived members only |
| 14 | canonical comparison family | validation record | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/comparisons/<accepted-name>` | exact comparator; canonical finalizer/review | exact generated comparison only |
| 15 | canonical identities | validation manifest | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/manifests/canonical-identities.tsv` | equality finalizer; coverage reference/off/on | exact regular source |
| 16 | canonical repetition/final manifests | validation manifest | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/canonical/{repetition-<N>/final-manifest.tsv,manifests/canonical-final.tsv}` | repetition/canonical finalizers; coverage/review | exact manifests; never publication receipts |
| 17 | coverage build cache/install descendants | producer cache/install | `/home/oleg/prog/z_llvm/local-state/caches/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage/{cache,install}/<finite-producer-path>` | coverage builder; coverage artifact finalizer | no recursion; enumerated finals only |
| 18 | coverage artifact family | validation output | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage/artifact/{z_llvm,artifact.identity.tsv}` | coverage finalizer; observation off/on | exact two files; excluded from performance |
| 19 | coverage reference family | validation record | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage/reference/<accepted-name>` | coverage bootstrap; off/on validators | exact closed references |
| 20 | observation-off family | validation output/record | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage/observation-off/{status/<coverage-step>,records/<coverage-step>.<record-part>,semantic/<accepted-name>}` | sole off producers; on comparator/finalizer | exact closed off group; channels absent |
| 21 | observation-on channels | validation channel | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage/observation-on/channels/{report.coverage.tsv,object.coverage.tsv,owner.coverage.tsv}` | exactly one matching producer; counter validators | exact three channels, absent before producer |
| 22 | remaining observation-on family | validation output/record | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage/observation-on/{status/<coverage-step>,records/<coverage-step>.<record-part>,semantic/<accepted-name>}` | sole on producers; equality/counter/finalizer | exact closed group excluding publication |
| 23 | coverage per-function family | validation output | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage/observation-{off,on}/functions/<function-id>/{bytes,disassembly,identity}` | phase extractor; canonical/off/on equality | finite canonical-manifest-derived members |
| 24 | coverage comparisons | validation record | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage/comparisons/<accepted-name>` | comparators/counter validators; finalizer | exact generated files |
| 25 | coverage phase/final manifests | validation manifest | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/coverage/{observation-{off,on}/final/{files.sha256,phase.final.tsv},manifests/{final-manifests.sha256,coverage-final.tsv}}` | phase/coverage finalizers; review | finite files excluding publication evidence |
| 26 | publication evidence family | validation durability record | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/durability/publication/<group-id>/{command,environment,stdin,stdout,stderr,status,receipt,verification}` | separately authorized post-wrapper; terminal finalizer | never included in the semantic group it describes |
| 27 | durability terminal | validation terminal record | `/home/oleg/prog/z_llvm/local-state/validations/o2-calls/compiler-rt-v1/baseline-validation-v3/durability/terminal/terminal-ledger.tsv` | finite ledger finalizer; human/Reviewer | never publishable and has no compatibility target |

The canonical and coverage source repositories are deliberately not one of
the 27 artifact/output families. They are protected Git control inputs at the
two exact `WORKTREES` paths in section 3.3.

## 6. Producer, consumer, and role-crossing rules

### 6.1 Source and cache inputs

A producer may read source only from the exact separately registered
`CANONICAL_SOURCE` or `COVERAGE_SOURCE` under a later source-operation
directive. Source paths never become payload objects merely by being read.

Each build gets one finite plan listing its exact descendants under the
matching cache/install root. The plan is not directory discovery. Build and
install roots remain non-authoritative and cannot be publication inputs.

### 6.2 Final validation outputs

A producer writes only its row-5 or row-18 final regular artifact and the
finite row-specific records beneath `V3`. A later publisher may receive only
an explicitly enumerated list of final no-follow regular files from rows
5–16 or 18–25. It never receives a root, directory, glob, cache, install tree,
source repository, or common ancestor.

### 6.3 Payload publication

A later finite publisher may transform an enumerated validation source into
an immutable object/snapshot beneath `PAYLOAD_AUTHORITY`. That operation
requires separate authority for:

1. exact validation source paths;
2. exact payload authority;
3. a finite canonical group specification;
4. fresh capacity and registration checks;
5. no-follow and atomic no-overwrite publication; and
6. retained operational evidence under row 26.

No payload is active merely because its bytes exist. Authority changes only
after the separately accepted manifest/lineage transition.

### 6.4 Metadata acceptance

Small candidate metadata is first produced beneath `DURABILITY`. A separate
later control-repository directive must name every exact destination beneath
`CONTROL_AUTHORITY`, verify canonical bytes and size limits, and commit the
metadata. The control commit may not contain payload bytes or generated
operational logs.

The current tracked main manifest remains authoritative until the complete
non-destructive migration and control transition is separately accepted.

## 7. Protection union

Protection is the union of independently obtained inventories:

```text
current_main_inventory=43
current_control_inventory=1
current_union=44
future_union=43 + every explicitly authorized supplemental repository worktree
```

The control repository and both future source repositories are fail-closed
exclusions from artifact traversal and mutation. A future inventory operation
reads registration metadata from each explicitly known Git root; it does not
discover repositories by walking `LOCAL`.

The main ignore rule does not weaken protection. Intentional containment
beneath `LOCAL` is not permission to stat, hash, enter, copy, materialize,
clean, repair, normalize, relocate, or remove a protected repository.

No current registered-worktree authority changes in this design.

## 8. Prospective fail-closed local-state guard

The later guard accepts only one exact role plus an exact path matching that
role's closed family. It performs:

1. normalized absolute byte equality;
2. rejection of `.`/`..`, empty components, alternate separators, and unsafe
   percent/path encoding;
3. no-follow validation of each exact named ancestor;
4. exact role-root and family matching;
5. union-registration capture and bidirectional intersection rejection;
6. control-repository rejection for every payload/build/validation/cache
   operation;
7. source-worktree rejection for every artifact operation;
8. cross-role and unknown-descendant rejection;
9. target ambiguity and duplicate-role rejection; and
10. registration revalidation before mutation, commit, and result emission.

It fails closed for:

- any registered worktree or descendant;
- payload access beneath `CONTROL`;
- metadata writes beneath `ARTIFACTS`, `VALIDATIONS`, `WORKTREES`, or
  `CACHES`;
- a cache, install, validation, compatibility, or payload path supplied for a
  different role;
- an unknown child beneath any role root;
- symlink or non-directory ancestry;
- traversal or normalization differences;
- ambiguous targets or duplicate logical identities;
- an inferred role based only on common-ancestor containment; and
- changed registration or missing path-specific authority.

Exact no-follow read-only access to one named metadata file beneath
`CONTROL_AUTHORITY` is a metadata-control operation, not artifact traversal.
It grants no directory listing, glob, recursive access, payload authority,
publisher-source status, compatibility destination, or cleanup authority.

## 9. Current authority and non-destructive migration boundary

The following pair remains authoritative:

```text
current_payload_authority=/home/oleg/prog/z_llvm-artifacts
current_tracked_manifest=/home/oleg/prog/z_llvm/docs/evidence/artifact_manifest_v1.tsv
current_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
```

The prospective local-state paths are not aliases or fallbacks. Before any
authority transition, a later directive must:

1. authorize exact reserved-path creation;
2. copy without deleting or changing the current store;
3. verify every immutable payload byte, mode, relationship, snapshot, and
   manifest identity at both authorities;
4. retain complete source/destination inventory and equality evidence;
5. authorize and commit exact canonical metadata in the protected control
   repository;
6. amend and re-review tool/manifest/contract authority bindings; and
7. explicitly accept the new authority.

Failure at any point leaves the current authority unchanged. No cleanup or
retirement follows automatically.

## 10. Superseded roots

Both earlier v3 roots are absent, superseded, and unauthorized:

```text
/home/oleg/prog/z_llvm-baseline-validation-v3
/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3
```

Neither is an alias, fallback, source, destination, compatibility target,
migration input, cleanup target, or operational path. This directive does not
create, delete, repurpose, enter, or materialize either.

## 11. Frozen later sequence

The only accepted order is:

1. review and accept this local-state path model;
2. separately authorize creation of each exact required reserved path;
3. separately perform and accept a non-destructive copy-and-verify migration;
4. separately authorize the exact control metadata commit and the required
   manifest/tool/contract amendment;
5. re-review and accept the amended authority and path contract; and
6. only then consider a separate validation-v3 execution directive.

No step is preauthorized by this document. A failure or withheld acceptance at
one step blocks every later step.

## 12. Static closure

```text
operating_head=cf518a8d62b23e5ebdc088b75ec512e382a2a30f
operating_parent=84a52011cc810d46c852d1226c254a05a3a5f4c4
authorized_document_count=1
active_logical_reference_mappings=19
future_family_mappings=27
current_protected_union=44
prospective_role_roots=5
prospective_reserved_roots_created=0
control_repository_mutations=0
registered_worktree_operations=0
store_traversals_or_copies=0
project_or_artifact_commands=0
source_tool_contract_manifest_pin_edits=0
compatibility_materializations=0
validation_v3=absent_and_unauthorized
production=unchanged_dormant
ratchet=131
next=STOP_FOR_WATCHER_REVIEWER_PATH_MODEL_REVIEW
```

Only exact named paths, explicit-root Git metadata/status, and named tracked
files informed this design. No reserved path or repository was created; no
control file changed; no registered worktree or store was traversed; and no
project, artifact, validation, cleanup, migration, compatibility, wiring,
performance, Tier, checkpoint, ratchet, or credit action ran.
