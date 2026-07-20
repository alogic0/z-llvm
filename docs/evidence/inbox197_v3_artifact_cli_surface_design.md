# INBOX-197 v3 Artifact CLI Surface Design

## 1. Scope and disposition

This is a documentation-only design from exact operating commit
`a5cc229863364fb957fb66dc7f0085f286e5382e`, parent
`df907d336ffb13e84ecf2b0bc1966d1fb847c834`. It implements and executes
nothing.

The accepted INBOX-196 durability mapping remains authoritative. This design
closes the intended machine interface for its four missing capabilities:

1. read-only logical-ID resolution;
2. read-only standalone verification;
3. exact one-target atomic compatibility materialization; and
4. finite immutable output-group publication.

The first two surfaces have no filesystem mutation authority. The third may
write exactly one separately authorized compatibility target but may not
modify the artifact store or a manifest. The fourth may publish immutable
store objects, snapshots, and one append-only successor generation but may
not create a compatibility path. No surface may create, modify, enter,
traverse, hash, publish, resolve into, materialize over, or remove a
registered worktree.

The frozen boundary is:

```text
accepted_INBOX_196_commit=df907d336ffb13e84ecf2b0bc1966d1fb847c834
accepted_contract_sha256=d445f6a45f039415052cb0fb1efc71b1975f2ea68d28e3637aede503145fc387
tracked_live_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
artifact_tool_sha256=94dfc1fc27ffe1268eb02453bcac1a3634aa11af38d0c94fbaa3b43decd25859
real_store_inventory_sha256=3234fb508d370878efe082cf1accb5af3b488372bf3f1ee7e9e87408a37a2d7c
real_store_file_ledger_sha256=a06c48e1549d16b9f924cc2b5f0404e60d7755a785bf3a4a23311c2383279a65
watcher_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash_object=7985c6d01040a6e47e4ce5b918866d0e89517ac7
pins_sha256=1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
audit_sha256=5a7e019eb107e5b66947490a65fdf47444154fc4f1483ca30ab0fc6e381f33e6
worktree_path_sha256=f31d8542baafc7b64cd5ee6fe8cc4194842ca696b97a7ffc8df06ce12d553d7e
worktree_topology_sha256=6c868e3b6d436cfba92a1e2b21dbd616391763961f1cba9b6670b1ed4a6ebb62
worktree_non_main_sha256=ebc30a376b3db4c6fbf788f49ea85f4ce792471e539c0a89308068efdf96ebbe
worktree_distribution=33_repository_tmp_8_system_tmp_2_elsewhere
validation_v3=absent_and_unauthorized
ratchet=131
```

The Watcher's stopped broad traversal is not evidence and is not used here.
This design relies only on the accepted identities above and narrow static
inspection of named tracked files in the main worktree.

## 2. Common command contract

### 2.1 Executable and closed environment

`zllvm-artifact-store` below denotes one later-built, immutable executable
whose absolute path, SHA-256, bytes, mode, compiler identity, and build
provenance must be frozen by the separately authorized implementation slice.
No PATH lookup is permitted by an acceptance launcher. The token is used here
to define `argv[1..]` exactly; it does not claim that such an executable
currently exists.

Every invocation has:

```text
cwd=/home/oleg/prog/z_llvm
environment_key_count=5
PATH=/usr/bin:/bin
LC_ALL=C
TZ=UTC
SOURCE_DATE_EPOCH=0
ZLLVM_ARTIFACT_STORE=/home/oleg/prog/z_llvm-artifacts
```

No inherited variable is allowed. `ZLLVM_ARTIFACT_STORE` must be an exact
normalized absolute path, must equal the separately authorized authority, and
must be bidirectionally disjoint from all 43 frozen registrations. The
executable must use absolute `/usr/bin/git`, `/usr/bin/tar`, and
`/usr/bin/zstd` paths where the frozen implementation already does.

The tracked authority path is fixed, not caller-selectable:

```text
/home/oleg/prog/z_llvm/docs/evidence/artifact_manifest_v1.tsv
```

The generation argument is exactly eight ASCII decimal digits. The generation
manifest path is derived, never accepted from a caller:

```text
$ZLLVM_ARTIFACT_STORE/manifests/generation-<8digits>.tsv
```

The expected generation-manifest SHA-256 is always an explicit 64-lowercase-
hex argument. Before any operation, the command:

1. captures and validates the frozen registration metadata without traversing
   a registered worktree;
2. validates authority ancestry no-follow and store/worktree disjointness;
3. opens the tracked and derived generation manifests as no-follow regular
   files;
4. requires their bytes, mode, and SHA-256 to be exact and byte-identical;
5. parses and re-encodes the applicable canonical manifest schema;
6. validates generation lineage; and
7. rechecks registration immediately before emitting success or crossing a
   mutation boundary.

Generation 1 remains the exact accepted v1 manifest. Direct object-key
authority, direct snapshot-key authority, caller-supplied generation paths,
ad hoc manifest parsing, and a caller-selected tracked manifest are rejected.

### 2.2 Canonical I/O

All schemas are UTF-8-compatible ASCII TSV. Every document:

- begins with its exact magic line;
- has one exact tab-separated header;
- uses LF only and ends with exactly one LF;
- has no empty row;
- uses lowercase external enum spelling;
- writes integers in canonical unsigned decimal, except modes which are four
  octal digits;
- uses 64 lowercase hexadecimal SHA-256 values;
- uses `-` for a field explicitly declared absent; and
- percent-encodes unsafe field bytes using the existing uppercase `%HH`
  canonical-field rules.

For `resolve-logical-v1` and `materialize-compatibility-v1`, stdin must be
exactly zero bytes and the launcher must attach `/dev/null`. For `verify-v1`
and `publish-group-v1`, stdin is exactly one canonical specification document
defined below. The tool reads it to EOF once. No surface reads an additional
specification path.

On success:

- exit status is `0`;
- stderr is exactly zero bytes;
- stdout is exactly one canonical result or receipt document;
- no warning, progress, timing, diagnostic, or external-tool output is
  inherited; and
- empty stdout is an error.

On failure:

- stdout is exactly zero bytes;
- stderr is exactly one canonical `zllvm-artifact-cli-error-v1` document;
- the nonzero status is the one assigned below;
- no partial success document is emitted; and
- a signal, crash, noncanonical stderr, unlisted status, or output on the wrong
  channel is an unexpected failure requiring retain-and-stop.

The caller, not the semantic group, retains the exact argv, closed
environment, cwd, stdin bytes/hash, stdout, stderr, numeric status, and
start/end timestamps. A producer group cannot include these publication or
verification records when they describe publication of that same group.

### 2.3 Closed error schema and statuses

```text
zllvm-artifact-cli-error-v1
operation	code	phase	subject
<operation>	<closed-code>	<closed-phase>	<canonical-subject-or-dash>
```

There is exactly one data row. The closed phases are `argv`, `stdin`,
`authority`, `registration`, `schema`, `resolution`, `verification`,
`capacity`, `path`, `mutation`, `commit`, and `output`.

| Exit | Closed codes | Meaning |
|---|---|---|
| 64 | `invalid-argv`, `stdin-required`, `stdin-not-empty` | Invocation is not the exact surface. |
| 65 | `unknown-schema`, `noncanonical-schema`, `invalid-specification`, `duplicate-request`, `duplicate-group-member`, `evidence-cycle` | Input schema or finite set is invalid. |
| 66 | `authority-root-invalid`, `tracked-manifest-missing`, `generation-manifest-missing`, `authority-manifest-mismatch`, `generation-lineage-invalid`, `generation-one-rewrite` | Sole authority or generation relationship failed. |
| 67 | `registration-inventory-invalid`, `registration-drift`, `protected-worktree-intersection` | Frozen registration boundary failed. |
| 68 | `unsafe-key`, `unsafe-source`, `unsafe-target`, `nonregular-source`, `symlink-source`, `nonregular-target`, `symlink-target`, `directory-target` | No-follow/path/node policy failed. |
| 69 | `logical-id-missing`, `logical-id-duplicate`, `logical-id-inactive`, `target-missing`, `target-ambiguous`, `group-missing`, `group-ambiguous` | Manifest lookup did not yield one admitted active identity. |
| 70 | `object-missing`, `object-mismatch`, `snapshot-missing`, `snapshot-mismatch`, `constituent-mismatch`, `member-mismatch`, `manifest-relationship-mismatch`, `compatibility-mismatch`, `store-shape-mismatch` | Immutable verification failed. |
| 71 | `target-exists-unequal`, `target-appeared`, `target-outside-authorized-root`, `target-not-authorized` | Exact one-target compatibility contract failed. |
| 72 | `insufficient-bytes`, `insufficient-inodes`, `capacity-observation-invalid` | Fresh capacity preflight failed. |
| 73 | `parent-mismatch`, `successor-not-next`, `generation-exists`, `group-not-finite`, `publication-interrupted`, `publication-readback-mismatch` | Append-only publication failed. |
| 74 | `external-tool-identity`, `external-tool-failed` | A frozen deterministic snapshot tool failed. |
| 75 | `io-failure`, `allocation-failure`, `output-failure`, `internal-invariant` | Closed implementation failure. |

Each implementation must catch its complete reachable Zig error set and map
it to exactly one row above. It may not expose an inferred `anyerror`, OS error
name, stack trace, or unstable allocator/path text.

## 3. Capability 1: read-only logical-ID resolution

### 3.1 Exact argv and authority

```text
argv[0]=zllvm-artifact-store
argv[1]=resolve-logical-v1
argv[2]=<generation-8digits>
argv[3]=<expected-generation-manifest-sha256>
argv[4]=<logical-id>
argc=5
stdin_bytes=0
```

The surface accepts one manifest logical ID, including an object, logical
reference, snapshot, or snapshot-member ID. A snapshot-member resolution
verifies its target object and complete owning-snapshot relationship; it never
makes the member path independent source authority. Resolution is read-only:
it creates no directory, incoming file, compatibility path, receipt path,
cache, or store object.

After common authority checks, it requires one exact active row, validates all
row and relationship constraints, and verifies the complete referenced
immutable identity before success:

- an object resolves and verifies that object;
- a logical reference resolves its unique target object and verifies both
  rows and the object;
- a snapshot resolves its archive, constituent object, complete finite member
  set, every member target, and deterministic archive proof; and
- a snapshot member resolves its target and verifies that same complete
  owning-snapshot proof.

### 3.2 Resolution output

```text
zllvm-artifact-resolution-v1
generation	parent_manifest_sha256	generation_manifest_sha256	tracked_manifest_sha256	logical_id	kind	target_id	key	sha256	bytes	mode	media_type	retention_class	status	snapshot_id	constituent_sha256	member_count	registration_path_sha256	registration_topology_sha256	registration_non_main_sha256
<one exact row>
```

For generation 1, `parent_manifest_sha256` is `-`. Object/logical-ref results
use `-`, `-`, and `0` for the last snapshot-specific fields. Snapshot and
snapshot-member results report the owning snapshot ID, constituent SHA-256,
and exact member count. The result is a verified identity record, not
permission to read by key or create a compatibility path.

### 3.3 Mutation, rollback, and receipt

Mutation boundary: none. Rollback consists only of closing descriptors and
freeing transaction-local allocations. The canonical resolution stdout plus
the caller-retained invocation records are the receipt. A failed resolution
has no success receipt.

## 4. Capability 2: read-only standalone verification

### 4.1 Exact argv and verification specification

```text
argv[0]=zllvm-artifact-store
argv[1]=verify-v1
argv[2]=<generation-8digits>
argv[3]=<expected-generation-manifest-sha256>
argc=4
stdin=zllvm-artifact-verification-spec-v1
```

Canonical stdin is:

```text
zllvm-artifact-verification-spec-v1
request_id	kind	logical_id	compatibility_root	relative_target
<one through 1024 bytewise request_id-sorted unique rows>
```

Closed `kind` values and field rules are:

| Kind | `logical_id` | Compatibility fields | Exact scope |
|---|---|---|---|
| `store` | `-` | `-`, `-` | complete manifest verification below plus bounded store shape |
| `manifest` | `-` | `-`, `-` | tracked/generation byte equality, canonical parse/re-encode, lineage, every active referenced object/snapshot/member byte, and every relationship |
| `object` | exact object logical ID | `-`, `-` | one manifest-declared immutable object |
| `logical-ref` | exact logical-ref ID | `-`, `-` | reference, target row, and target object |
| `snapshot` | exact snapshot ID | `-`, `-` | archive and constituent identities |
| `group` | exact snapshot ID | `-`, `-` | snapshot plus complete declared finite member set and relationships |
| `compatibility` | exact logical-ref ID | normalized absolute root, safe relative path | read-only equality of one existing regular compatibility target |

The specification cannot name an object key or snapshot key directly.
`compatibility` never creates or changes its target. A `store` request may
iterate only the bounded authority-store namespace; it never enters a
registered worktree or performs general filesystem discovery.

### 4.2 Verification output

```text
zllvm-artifact-verification-result-v1
generation	parent_manifest_sha256	generation_manifest_sha256	tracked_manifest_sha256	specification_sha256	request_count	object_count	snapshot_count	member_count	compatibility_count	registration_path_sha256	registration_topology_sha256	registration_non_main_sha256	result
<one exact row ending in verified>
```

All requests must succeed before the one result row is emitted. Counts are
deduplicated physical identities verified, not request-row counts. Empty
specifications and partial result streams are invalid.

### 4.3 Mutation, rollback, and receipt

Mutation boundary: none. The read-only verifier may not create even a
temporary proof workspace. Snapshot verification must list the finite archive
and stream each exact declared member to the verifier without extraction,
hashing the stream against its declared identity. It may reuse the frozen
listing, relationship, tool-identity, and hashing rules, but not the
workspace-creating body of `Store.verifySnapshotArchive`. Rollback consists
only of closing processes/descriptors and freeing transaction-local memory.
The canonical stdout and caller records form the verification receipt.

## 5. Capability 3: exact one-target compatibility materialization

### 5.1 Exact argv

```text
argv[0]=zllvm-artifact-store
argv[1]=materialize-compatibility-v1
argv[2]=<generation-8digits>
argv[3]=<expected-generation-manifest-sha256>
argv[4]=<logical-ref-id>
argv[5]=<separately-authorized-normalized-absolute-compatibility-root>
argv[6]=<safe-relative-target>
argc=7
stdin_bytes=0
```

The path-specific later directive must name the exact joined target and root.
The root is not inferred from the logical-ref key. One invocation admits
exactly one active logical reference whose target is a regular immutable
object. Snapshot extraction is not a compatibility operation.

Before any write, the command performs the common authority proof, resolves
and verifies the object, freezes registration, proves root/target
normalization and bidirectional disjointness from every registered worktree,
opens every existing ancestor no-follow, rejects unsafe traversal, and takes a
fresh capacity/inode observation including the full incoming-file peak.

### 5.2 Compatibility behavior

- Existing equal regular file with the separately reviewed compatibility mode:
  verify exact SHA-256, bytes, and mode; allocate/write nothing; return
  `existing-equal`.
- Absent target: create one incoming file in the same opened parent
  directory, stream from the verified immutable object descriptor, sync,
  chmod to the reviewed compatibility mode, sync, verify incoming identity,
  atomically link no-replace, sync ancestry, re-open no-follow, and verify the
  final; return `created`.
- Existing unequal bytes/mode, symlink, directory, other nonregular node,
  unsafe ancestor, protected-worktree intersection, registration drift,
  target race, ambiguity, or missing authority: leave the destination
  unchanged and fail closed.

No overwrite, rename-over-existing, chmod of an existing target,
normalization, retry, fallback target, or store mutation is permitted.

### 5.3 Compatibility result

```text
zllvm-artifact-compatibility-result-v1
generation	generation_manifest_sha256	logical_id	target_id	object_key	sha256	bytes	object_mode	compatibility_mode	compatibility_root	relative_target	disposition	registration_path_sha256	registration_topology_sha256	registration_non_main_sha256
<one exact row; disposition is existing-equal or created>
```

The result is not an artifact authority row and does not make the compatibility
path authoritative.

### 5.4 Mutation boundary and rollback

The mutation boundary begins only after all authority, registration, path,
capacity, and object verification. Before the atomic no-replace link, all
errors remove only the invocation-created incoming file. If the link succeeds
but final readback fails, the implementation may remove only that
invocation-created final and must sync the parent; it never removes an
existing node. After a verified final link, stdout failure is a retained
post-commit stop: the target remains and no retry occurs.

The compatibility result stdout and caller records form the retained receipt.

## 6. Capability 4: finite immutable output-group publication

### 6.1 Exact argv and finite group specification

```text
argv[0]=zllvm-artifact-store
argv[1]=publish-group-v1
argv[2]=<parent-generation-8digits>
argv[3]=<expected-parent-manifest-sha256>
argv[4]=<successor-generation-8digits>
argc=5
stdin=zllvm-artifact-output-group-spec-v1
```

Canonical stdin has two headers:

```text
zllvm-artifact-output-group-spec-v1
group_id	parent_generation	parent_manifest_sha256	successor_generation	retention_class
<one metadata row>
kind	logical_id	bounded_source_root	source_path	sha256	bytes	source_mode	media_type	target_id	snapshot_id
<one through 1024 finite rows>
```

The metadata row must equal argv. `successor_generation` is exactly parent + 1.
One retention class applies to the group. Data rows are sorted by closed kind
order then bytewise logical ID. Closed kinds are:

| Kind | Required fields | Meaning |
|---|---|---|
| `object-source` | logical ID, normalized bounded root and exact absolute source path, SHA-256, bytes, source mode, media | one finite no-follow regular source; published object mode is `0444` |
| `logical-ref` | logical ID, SHA-256, bytes, source mode, media, target object logical ID | one active reference to an object in the parent or this group |
| `snapshot` | logical ID and snapshot ID equal; other identity fields `-`/`0` as specified | one finite snapshot declaration |
| `snapshot-member` | logical ID, target object logical ID, snapshot ID | one exact member; member path is derived as the target object key |

All unused text fields are `-`; unused numeric fields are `0`. The group must
contain at least one new active logical reference or snapshot and the complete
object/member closure required by those rows. Sources come only from these
finite rows—no directory walk, glob, recursion, implicit member, manifest
search, or accepted-output discovery is permitted.

The parser rejects:

- duplicate logical IDs, sources, object identities, or snapshot members;
- any attempt to change, reorder, supersede, or delete a parent row;
- publication evidence under
  `calls/validation-v3/publication/` or
  `calls/validation-v3/durability-terminal/`;
- a source or logical ID for the group's own command, environment, stdin,
  stdout, stderr, status, receipt, verification result, or terminal ledger;
- an edge from a member to the group publication result;
- a source inside any registered worktree; and
- a cycle in the finite logical-reference/snapshot relationship graph.

### 6.2 Publication result

```text
zllvm-artifact-publication-receipt-v1
group_id	group_spec_sha256	parent_generation	parent_manifest_sha256	successor_generation	successor_manifest_sha256	successor_manifest_bytes	object_count	new_object_count	reused_object_count	snapshot_count	member_count	prior_row_count	new_row_count	registration_path_sha256	registration_topology_sha256	registration_non_main_sha256	commit
<one exact row ending in committed>
```

The receipt is computed before the generation-manifest commit point except for
its final `committed` disposition, emitted only after exact readback and
lineage verification. It is not a member of the group or successor manifest.
The caller-retained invocation records and stdout receipt belong to the
separate publication-evidence group accepted by INBOX-196.

Publication does not edit the tracked live manifest. The newly committed
successor is a durable candidate, not current authority, until a separate
later directive verifies it, installs an exact tracked copy, and accepts the
new tracked/generation byte-equal pair. Resolver, verifier, and compatibility
commands must continue using the parent pair until that transition is
accepted.

### 6.3 Mutation, atomicity, and rollback

The publisher:

1. completes authority, parent, registration, source, finite-graph, and fresh
   capacity checks;
2. verifies every parent object/snapshot referenced by the group;
3. streams finite sources into immutable content-addressed objects using
   atomic no-replace publication and exact readback;
4. constructs and verifies deterministic snapshots;
5. deterministically builds the successor manifest;
6. verifies that every parent row is preserved byte-for-byte and in order and
   that only the finite group rows were appended;
7. atomically publishes the successor generation manifest as the final commit
   point; and
8. re-opens and verifies the complete successor and parent relationship before
   emitting the receipt.

Before the generation commit point, invocation-created incoming files and
snapshot workspaces are removed on error. Successfully linked immutable
content-addressed objects/snapshots may remain as safe unreferenced objects;
they are never deleted, rewritten, or treated as active without a generation
manifest. The parent and generation 1 never change.

The successor manifest is created no-replace. If it exists, even byte-equal,
the invocation fails `generation-exists`; there is no idempotence rerun.
After the commit point, no automatic rollback removes the successor. A
readback or stdout failure retains the complete store and stops for review.

## 7. Deterministic successor-generation schema

### 7.1 Existing v1 schema is insufficient

The current `zllvm-artifact-manifest-v1` has exactly the 17 row fields:

```text
kind logical_id sha256 bytes mode media_type provenance reconstruction
retention_class status key target_id snapshot_id member_path snapshot_format
recipe_sha256 constituent_sha256
```

It has no generation number, parent generation, parent-manifest SHA-256,
parent byte count, group-spec SHA-256, prior-row count, or appended-row count.
The generation number exists only in the filename produced by
`Store.publishManifest`. That function accepts an arbitrary caller generation
and canonical v1 text; it does not require the next number, load a parent,
prove an append-only row prefix, or bind a finite group specification.
`parseManifest` is strict and cannot parse an added metadata line.

Encoding parentage into `provenance`, `reconstruction`, a logical reference,
or a filename would not be a structurally validated content-addressed
relationship. Therefore the existing schema cannot represent the required
successor lineage.

This is an additional structural blocker:

```text
blocker=successor-generation-schema
missing_surface=zllvm-artifact-manifest-v2 parser/encoder/lineage validator
repair_authorized=false
```

### 7.2 Required v2 schema

A future implementation must add this exact canonical schema while preserving
v1 parsing for immutable generation 1:

```text
zllvm-artifact-manifest-v2
generation	parent_generation	parent_manifest_sha256	parent_manifest_bytes	group_spec_sha256	prior_row_count	new_row_count
<8digits>	<8digits>	<64hex>	<decimal>	<64hex>	<decimal>	<decimal>
kind	logical_id	sha256	bytes	mode	media_type	provenance	reconstruction	retention_class	status	key	target_id	snapshot_id	member_path	snapshot_format	recipe_sha256	constituent_sha256
<canonical cumulative rows>
```

Rules:

1. v2 is valid only for generation `00000002` or later.
2. `parent_generation` is exactly generation minus one.
3. `parent_manifest_sha256` and bytes identify the exact immediate predecessor
   generation file after canonical verification.
4. `group_spec_sha256` identifies the exact canonical stdin that alone
   supplied the appended rows.
5. `prior_row_count` equals the parent's row count.
6. The first `prior_row_count` rows encode byte-for-byte identically, in the
   same order, to the parent rows. No status or field changes are allowed.
7. Exactly `new_row_count` rows follow and equal the deterministic expansion of
   the finite group specification.
8. The complete v2 file is content-addressed by the publication receipt and
   tracked live copy. Its own hash is not embedded in itself.
9. The accepted tracked live manifest may advance only by a separate later
   directive to become byte-identical to the accepted successor file.
10. Generation 1 remains v1 and immutable forever.

The successor file name remains
`manifests/generation-<8digits>.tsv`. The content-bound parent hash, not the
filename, proves lineage.

## 8. Schema inventory

| Schema | Producer | Consumer | Authority effect | Empty rule |
|---|---|---|---|---|
| `zllvm-artifact-resolution-v1` | resolver | later input pre-wrapper | none; verified identity receipt | exactly one row |
| `zllvm-artifact-verification-spec-v1` | separately reviewed contract launcher | verifier | none | 1..1024 rows |
| `zllvm-artifact-verification-result-v1` | verifier | later validation/review | none | exactly one row |
| `zllvm-artifact-compatibility-result-v1` | compatibility materializer | later consumer preflight/review | none | exactly one row |
| `zllvm-artifact-output-group-spec-v1` | closed semantic-group finalizer | publisher | proposes finite append only | 1 metadata + 1..1024 rows |
| `zllvm-artifact-publication-receipt-v1` | publisher after commit | terminal durability ledger/review | records, but is not part of, successor authority | exactly one row |
| `zllvm-artifact-cli-error-v1` | any failed surface | retain-and-stop reviewer | none | exactly one row |
| `zllvm-artifact-manifest-v2` | publisher | resolver/verifier/later publisher | successor authority after separate tracked-copy acceptance | metadata + cumulative nonempty rows |

Every schema parser must parse, re-encode, and byte-compare before use.
Unknown/reordered fields, duplicate IDs, excess rows, missing LF, extra LF,
noncanonical numeric or percent encoding, and trailing bytes fail closed.

## 9. Existing Store-function reuse and missing implementation

| Surface | Reusable frozen implementation | Missing bounded implementation |
|---|---|---|
| Common authority | `resolveAuthority`; `RegistrationGuard.init`, `assertCurrent`, `assertStoreRoot`; `Store.open`; `parseManifest`; `encodeManifest`; `validateRelationships` | tracked/generation pair loader, byte-equality proof, generation v1/v2 dispatcher, lineage validator, closed error mapper, canonical I/O driver |
| Resolver | `findRow` internally; `Store.verifyObject`; `sortedObjectGroup`; constituent/listing/relationship validation from snapshot verification | public CLI dispatch, active-row uniqueness policy, manifest-to-owned identity construction, no-write streaming snapshot verifier, deterministic resolution encoder |
| Verifier | resolver functions; `Store.verifyNoPartialObjects` for bounded store request; existing no-follow file verification | verification-spec parser, request dispatcher/deduplication, no-write streaming snapshot verifier, read-only compatibility verifier, deterministic count/result encoder |
| Compatibility | `validateRelativeKey`; `openPathNoFollow`; `publishVerifiedFile`; exact existing-file identity logic in `Store.resolveCompatibility` | authoritative resolver integration, external separately authorized root policy, one-target API, no store mutation, compatibility result encoder |
| Publisher | `Store.preflightCapacity`; `publishFile`; `publishBytes`; `publishSnapshot`; `verifyObject`; `verifySnapshot`; `publishManifest`; atomic verified file helpers | output-group parser, evidence-cycle guard, v2 parser/encoder, parent/append validator, next-generation enforcement, publication transaction/receipt, CLI dispatch |

`Store.resolveCompatibility` is not directly sufficient: it requires the
compatibility root to be inside the synthetic store, requires caller-supplied
object/snapshot identities, and binds the manifest logical-ref key to the
relative destination. The future surface needs a private authority-resolved,
path-authorized one-target operation without weakening store-write
protection.

`Store.verifySnapshot` is not directly sufficient for the two read-only
surfaces because `verifySnapshotArchive` creates and deletes a proof workspace
inside the store. Its deterministic member ordering, constituent checks,
archive listing validation, tool identity checks, and object identity rules
are reusable; a new private streaming member verifier is required so the
read-only commands perform zero filesystem mutation.

`Store.publishManifest` is not directly sufficient for successors because it
does not validate parentage or append-only rows. It may remain the atomic
low-level file publisher only after a new higher-level lineage transaction
has constructed and verified v2 bytes.

No existing CLI dispatch exposes any of these four capabilities. All four
remain implementation blockers; the schema blocker in section 7 is a fifth
structural prerequisite for publication.

## 10. Finite acyclic publication evidence

For semantic group `G`:

```text
semantic producer G
  -> semantic verifier V(G)
  -> output-group specification S(G)
  -> publisher P(G)
  -> publication receipt R(G)
  -> standalone verification Q(G)
  -> finite terminal ledger T
```

`G` contains none of `S(G)`, `P(G)`, `R(G)`, `Q(G)`, or `T`. `S(G)` rejects
all self-publication/evidence prefixes. `P(G)` consumes `S(G)` but does not
publish `S(G)` or its own invocation records. `R(G)` and `Q(G)` are retained
in a distinct publication-evidence group. `T` lists the finite expected
publication groups and their receipts/verifications, has no publisher, and is
never an artifact candidate. Thus no group contains its own publication or
verification evidence and the chain terminates without recursion.

The finite group specification and manifest-derived function member sets are
the only member sources. No directory enumeration may discover publication
members.

## 11. Frozen later synthetic and negative proofs

All tests are future-only and require separate implementation authority. They
must use a new synthetic authority disjoint from every registered worktree and
must never read or modify the real store.

### 11.1 Common authority and schema

- tracked/generation exact equality success;
- tracked missing, generation missing, byte mismatch, mode mismatch, and
  noncanonical manifest;
- invalid/relative/aliased authority root;
- registration drift and every protected-worktree intersection direction;
- unexpected argv, nonempty forbidden stdin, missing required stdin,
  malformed LF/header/field/order/encoding, excess row, and unknown enum;
- exact error code/status/channel and no partial success output.

### 11.2 Resolver and verifier

- current object, logical reference, and both snapshot/group successes;
- missing, duplicate, ambiguous, inactive, and wrong-kind logical IDs;
- corrupt/missing/mode-wrong object;
- corrupt/missing snapshot, constituent, member, member relationship, or
  archive member;
- direct object/snapshot key as caller authority rejected;
- finite mixed verification spec, duplicate request, empty spec, and >1024
  requests;
- compatibility verification equal success plus stale, nonregular, symlink,
  directory, unsafe, and protected targets;
- registration mutation between authority load, object verification, snapshot
  verification, and result emission fails before success.

### 11.3 Compatibility materializer

- existing-equal produces no allocation/write;
- absent target creates exactly one file with exact bytes/mode/result;
- unequal bytes, unequal mode, symlink, directory, FIFO/other nonregular,
  unsafe component, root escape, protected intersection, target race, absent
  authority, ambiguity, changed registration, and insufficient capacity;
- interruption before incoming write, after write, after sync/chmod, before
  link, after collision, after link before readback, and during result output;
- only invocation-created incoming/final cleanup, no overwrite, no retry, and
  no store mutation.

### 11.4 Finite publisher

- one-object and two-object/multi-snapshot deterministic groups;
- reused parent object plus new object;
- source identity/mode mismatch, symlink/nonregular source, unsafe bounded
  root, protected source, duplicate object/ref/member, missing target, and
  >1024 rows;
- publication-command, receipt, verification, terminal-ledger, self-edge, and
  multi-group cycle rejection;
- capacity byte/inode failure;
- interruption before/after each object, constituent, snapshot, v2 render,
  incoming generation write, commit link, readback, and receipt output;
- parent hash/bytes/number mismatch, non-next successor, existing generation,
  generation-1 rewrite attempt, changed parent row/status/order, and group-spec
  hash mismatch;
- exact v1 generation-1 to v2 generation-2 lineage, v2 to v2 lineage, and
  cumulative append-only proof;
- unreferenced immutable objects may remain after pre-commit failure, but no
  successor manifest or success receipt exists;
- post-commit output failure retains the committed successor for review and
  performs no retry or rollback.

## 12. Bounded implementation and review order

Each item requires a separate directive and stop:

1. **Read-only resolver and verifier.** Add v1/v2 read-only parsing and lineage
   validation, common authority loading, closed errors/I/O, resolution and
   verification specs/results, and synthetic proofs. No compatibility or
   publication mutation.
2. **Compatibility materializer.** Add only the exact one-target external
   authorization boundary and result, reusing the accepted atomic helper.
   Resolver/verifier behavior is frozen.
3. **Future-output publisher.** Add the finite group spec, v2 successor schema,
   append-only lineage transaction, receipt, and publication proofs.
   Generation 1 and prior surfaces are frozen.
4. **Contract re-amendment and re-review.** Replace the INBOX-196 structural
   blockers with exact accepted executable paths/hashes, wrapper commands,
   schemas, and composed-stream hashes. Validation-v3 remains unauthorized
   until that amended contract is separately accepted.

No combined implementation, automatic fix-forward, contract execution, store
mutation, compatibility creation, or v3 run is implied.

## 13. Static closure

The design closes:

```text
machine_oriented_capabilities=4
read_only_capabilities=2
one_target_mutating_capabilities=1
store_generation_mutating_capabilities=1
versioned_result_and_spec_schemas=8
accepted_generation_1=IMMUTABLE_V1
successor_schema=V2_REQUIRED
additional_structural_blocker=successor-generation-schema
publication_DAG=FINITE_ACYCLIC
terminal_evidence=FINITE_NONRECURSIVE_NOT_PUBLISHED
registered_worktree_traversal=PROHIBITED
implementation=NOT_AUTHORIZED_OR_PERFORMED
validation_v3=ABSENT_UNAUTHORIZED
production=UNCHANGED_DORMANT
ratchet=131
next=STOP_FOR_WATCHER_REVIEWER_CLI_SURFACE_DESIGN_REVIEW
```

Only narrow static/read-only inspection of the named operating documents,
accepted contract/audit/manifest, build root, and frozen artifact-tool source
in the main worktree informed this document. No project code, artifact-tool
command, build, test, gate, resolver, verifier, publisher, compatibility
writer, store/manifest/path/pin/contract mutation, registered-worktree
operation or traversal, cleanup, v3 execution, wiring, performance, Tier
work, checkpoint action, ratchet movement, or credit action ran.

The static closure record is:

```text
operating_head=a5cc229863364fb957fb66dc7f0085f286e5382e
operating_parent=df907d336ffb13e84ecf2b0bc1966d1fb847c834
starting_tracked_status=clean
authorized_document_count=1
capability_sections=4
exact_argv_surface_definitions=4
versioned_schema_definitions=8
closed_exit_statuses=12
successor_schema_adequacy=INSUFFICIENT_V2_REQUIRED
contract_sha256=d445f6a45f039415052cb0fb1efc71b1975f2ea68d28e3637aede503145fc387
manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
tool_sha256=94dfc1fc27ffe1268eb02453bcac1a3634aa11af38d0c94fbaa3b43decd25859
watcher_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
pins_sha256=1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
stash_at_0=7985c6d01040a6e47e4ce5b918866d0e89517ac7
exact_named_v3_root=absent
registered_inventory_recomputed=false
real_store_rehashed_or_traversed=false
```
