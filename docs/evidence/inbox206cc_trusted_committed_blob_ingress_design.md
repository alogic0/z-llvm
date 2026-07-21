# INBOX-206CC Trusted Committed-Blob Ingress Design

## 1. Scope and disposition

INBOX-206CC is an evidence/design-only checkpoint. It defines a prospective
pure-Zig ingress boundary for supplying already committed specification bytes
without runtime traversal of a registered worktree. It implements, selects,
builds, tests, executes, provisions, publishes, or installs nothing.

CA Option 1, retain the blocker, remains the only authorized implementation
state. CA Option 4 remains prospective only. None of the three ingress variants
in this document is selected, authorized for implementation, or authorized to
receive real committed bytes.

```text
slice=INBOX-206CC
document_kind=trusted_committed_blob_ingress_design
design_authority=documentation_only
current_implementation_option=retain_the_blocker
selected_ingress_variant=none
generic_implementation_authority=none
synthetic_test_authority=none
real_byte_provisioning_authority=none
descriptor_status=conditionally_supported
execution_authority=none
production_authority=none
D01=withheld
D02=unauthorized
ratchet=131
```

## 2. Closed authority and identity domains

### 2.1 Operating and accepted evidence authority

```text
operating_head=e06ed773f64697fa4a496ad95ffd868554be1c26
operating_parent=44b2c2b2fe6b0dfc9eb894a96e99d38b5ecb4227
operating_tree=3591cd5cd6a5d4d76ca32814f6a92b6f4d68d6fa
operating_changed_path=docs/next_steps.md
operating_parent_count=1

ca_commit=44b2c2b2fe6b0dfc9eb894a96e99d38b5ecb4227
ca_tree=9f9f670bba2734dbe7872120d7f7c7e57112761c
ca_path=docs/evidence/inbox206ca_registered_worktree_descriptor_boundary.md
ca_blob=5958b0c72caad9f704710352ac4874a6da4a383d
ca_raw_sha256=a816695372c214d90a893f2da82d84801df72979606b67e64dc8c06e363491d3

bz_commit=27100817652fa4f18db8fdd6f39874de2cb7b8fb
bz_tree=4e2c66c0d2e177330fd9541d31c32f42bd5b89db
bz_source_path=tools/zllvm_inbox206_materialize.zig
bz_source_blob=ab0281e4dbac00fcd2b4b9ba58e569c707eb8ef9
bz_source_binding=git_tree_and_blob_metadata_only
```

### 2.2 Accepted specification identity

The prospective input is bound in distinct identity domains:

```text
spec_path=docs/evidence/inbox206bk_zig_materialization_readiness_design.md
spec_commit=f9b2f30a154e5422c53d04bc21cc1e92e667300b
spec_tree=174923e4bfd78f6ae003556a9ed17ddf950d74fd
spec_blob=573e128bb999d8aba15ae5ac6dc69a52ac3e8812
spec_raw_sha256=66b0dfdff5c61b00a16e815994bb9c06e3596260d611a2e35cb83cbe99b9e187
spec_raw_bytes=29834
```

Git blob identity and raw-content SHA-256 are different domains. The Git blob
OID identifies Git's typed and length-framed blob object under Git's object
hash algorithm. `spec_raw_sha256` identifies exactly the 29,834 raw payload
bytes supplied to the future consumer. Neither value may be substituted for,
derived from, or compared as though it were the other. A future real supply
must independently bind both the committed Git metadata provenance and the
raw byte length/SHA-256 contract.

No Git-object contents were extracted for this design. The working-tree copy
was admitted only as the exact named BK document read authorized by CC; it is
not authority for runtime traversal.

## 3. Common prospective pure-Zig ingress contract

All variants share one private, test-root-only generic shape, provisionally
named `acquireVerifiedSnapshot`. The name is descriptive, not an API or
implementation commitment. It accepts one already-authorized supply adapter,
one caller-owned allocator, and this frozen expectation:

```text
expected_raw_bytes=29834
maximum_accepted_bytes=29834
expected_raw_sha256=66b0dfdff5c61b00a16e815994bb9c06e3596260d611a2e35cb83cbe99b9e187
accepted_supply_count=1
```

The future implementation must use Zig and the Zig standard library only. It
must allocate one owned 29,834-byte snapshot, initialize the standard-library
SHA-256 state, copy each accepted byte into that allocation while feeding the
same byte sequence to SHA-256, and retain no borrowed input slice after the
call. Allocation failure, integer overflow, read failure, or contract failure
unwinds all owned memory exactly once.

The state machine is fail closed:

```text
unused -> consuming -> verified
unused -> consuming -> failed
verified -> second_supply_rejected
failed -> retry_rejected
```

Only `verified` returns the owned snapshot. The consumer must:

1. start at the variant's defined logical offset zero;
2. read exactly 29,834 real bytes, never padding or normalizing input;
3. reject EOF before byte 29,834 as partial input;
4. reject any byte beyond byte 29,834 as trailing input;
5. require immediate EOF through the variant-specific EOF probe;
6. finalize SHA-256 and require the exact expected raw digest;
7. reject duplicate callbacks, replay, retry, or a second supply;
8. parse only the returned immutable owned-memory snapshot.

No parser, canonical-region scanner, token validator, fixture renderer, or
publisher may observe the source adapter directly. Parsing begins only after
length, EOF, and digest verification all succeed.

## 4. Variant 1 — caller-supplied held regular-file descriptor

```text
variant_id=held_regular_file_descriptor
selection_state=unselected
maximum_accepted_bytes=29834
exact_real_byte_count=29834
ownership=borrowed
```

### 4.1 Provenance inputs

The caller would have to supply a held read-only regular-file descriptor plus
an independently authorized provenance record containing the specification
path, commit, tree, blob OID, expected raw byte count, expected raw SHA-256,
descriptor role, and the descriptor identity tuple required by the accepted
descriptor primitive. The consumer may verify type and identity, but may not
infer committed provenance from descriptor identity.

### 4.2 Ownership, offset, and close contract

The descriptor is borrowed for the duration of one call. The consumer never
closes it and never transfers it into the returned snapshot. The caller
retains sole close responsibility after the call returns.

The supply must be seekable. Reads use explicit positions beginning at byte
offset zero rather than inheriting or mutating a shared current offset. The
consumer must obtain bytes `[0, 29834)` exactly once, then perform a positioned
one-byte probe at offset 29,834 and require EOF. If the future reviewed Zig API
cannot establish positioned-read behavior without changing caller-visible
offset state, this variant remains blocked.

### 4.3 Fail-closed behavior

Wrong role/type, identity drift, inability to establish offset zero, a
non-seekable descriptor, early EOF, trailing data, digest mismatch, duplicate
supply, read failure, or ownership ambiguity rejects the supply without
parsing. Because an ordinary regular file can change while held, this variant
also remains blocked for real bytes until mutation during acquisition is
provably detected or a later authority supplies an immutability guarantee.

## 5. Variant 2 — caller-supplied immutable or sealed descriptor

```text
variant_id=immutable_or_sealed_descriptor
selection_state=unselected
maximum_accepted_bytes=29834
exact_real_byte_count=29834
ownership=transferred
support_requirement=platform_and_zig_api_established
```

### 5.1 Provenance inputs

The caller would have to supply the same committed provenance and raw-content
expectations as Variant 1, plus a separately reviewed proof that the exact
descriptor kind and platform expose an immutable/sealed-content guarantee.
The proof must name the Zig API, supported runtime, required seal or immutable
state, admission query, and failure taxonomy. A claim, pathname, read-only
open flag, inode identity, or filesystem permission is not such a proof.

### 5.2 Ownership, offset, and close contract

Successful call entry transfers sole descriptor ownership to the consumer.
The consumer installs immediate cleanup and closes the descriptor exactly once
on success or failure after snapshot acquisition. The caller must not close,
seek, read, or reuse it after transfer.

The admitted immutable descriptor must support explicit reads from logical
offset zero. The consumer reads `[0, 29834)`, then probes at offset 29,834 and
requires EOF. Shared-offset-only or stateful replay behavior is rejected.

### 5.3 Fail-closed behavior

Unsupported platform/API, absent or incomplete immutability state, inability
to query the state, seal/identity drift, wrong role/type, offset ambiguity,
partial or trailing input, digest mismatch, duplicate supply, or any read or
close-ownership ambiguity rejects the supply. No fallback to ordinary mutable
descriptor behavior is allowed. This variant cannot be selected until its
immutability support is separately established.

## 6. Variant 3 — bounded one-shot byte stream

```text
variant_id=bounded_one_shot_byte_stream
selection_state=unselected
maximum_accepted_bytes=29834
exact_real_byte_count=29834
ownership=borrowed_for_one_call
seek_behavior=forbidden
```

### 6.1 Provenance inputs

The caller would supply a one-shot Zig byte-stream adapter, the committed
path/commit/tree/blob provenance record, the exact raw length and SHA-256, and
a unique unconsumed supply token. The stream itself does not prove Git
provenance. External Git plumbing, shell output, internal-agent transport, or
foreign-language producers are not admitted by this design.

### 6.2 Ownership, offset, and close contract

The adapter is borrowed only during one synchronous call; the caller retains
and closes any backing resource. The logical stream begins at offset zero on
the first read. Seeking, rewinding, replay, duplicated callback registration,
and a second call with the same supply token are forbidden.

The consumer reads at most 29,834 bytes into its owned snapshot, then performs
one further read and requires the stream's canonical EOF result immediately.
Any data from that probe is trailing input. The supply token becomes consumed
whether verification succeeds or fails.

### 6.3 Fail-closed behavior

Missing provenance, already-consumed token, reentrant callback, early EOF,
trailing byte, delayed extra chunk, digest mismatch, read error, ambiguous EOF,
or backing-resource ownership ambiguity rejects the supply. Because a generic
producer can change its source while streaming, real use remains blocked
unless the selected future stream contract guarantees immutability throughout
acquisition or supplies a separately reviewed mutation-detection guarantee.

## 7. TOCTOU closure

Descriptor identity alone does not prove immutable contents. A stable
descriptor identity can name a mutable regular file, and stable device/inode
or mount/inode fields do not show that bytes remained unchanged during reads.
Likewise, Git commit/tree/blob metadata proves the accepted repository object
relationship but does not prove that an arbitrary supplied descriptor or
stream emitted those raw bytes.

The owned snapshot closes the post-acquisition race: after the final byte,
EOF, exact length, and raw SHA-256 have been verified, later mutation of the
source descriptor, file, stream backing store, repository, or namespace cannot
alter the owned allocation. All parsing and later synthetic validation borrow
only from that allocation.

Mutation during acquisition is a separate boundary. A final digest mismatch,
length change, EOF change, read error, or independently proven metadata drift
detects and rejects some mutations, but the digest result alone is not a claim
that no mutation event occurred. For mutable regular descriptors and generic
streams, complete mutation-during-read detection remains a blocker unless a
later selected supply mechanism proves immutability for the entire acquisition
or introduces a separately reviewed detection protocol. Variant 2 may close
that blocker only after its exact immutable/sealed guarantee is established.

No retry, double read, pathname re-open, canonicalization, Git extraction, or
fallback source is permitted as a substitute for this proof.

## 8. Prospective private Zig implementation and tests

A later authority may map the common contract to private Zig types owned by a
private test root. The generic ingress may expose only mechanism-neutral
`readAt`/`readNext` and EOF behavior needed by the selected adapter, a bounded
allocator-owned snapshot result, and distinct errors for type, ownership,
offset, partial, trailing, duplicate, digest, immutability, and I/O failures.
It may not accept a pathname, invoke Git, spawn a process, traverse a worktree,
select a supply variant, publish output, or gain production reachability.

Prospective synthetic/frozen tests may cover:

- exact 29,834-byte success using inert frozen bytes and a matching expected
  standard-library SHA-256;
- every early-EOF boundary and one-byte/multi-byte trailing input;
- digest mismatch at each synthetic mutation position;
- duplicate callback, second supply, retry-after-failure, and reentrancy;
- positioned-offset and shared-offset negatives for descriptor adapters;
- immutable-state absent, query failure, and drift negatives;
- allocation failure and exact ownership/close behavior;
- proof that parsing receives only a verified owned snapshot.

These are test designs only. They do not authorize source edits, build wiring,
compilation, test execution, real descriptors, committed-byte provisioning,
or evidence generation. Real committed specification bytes may not appear in
fixtures without separate authority.

## 9. Provisioning boundary

External provisioning is unauthorized. A future supply authority must be a
separately reviewed boundary that names exactly one variant, provenance
producer, ownership transition, expected identities, and one-shot lifecycle.
It may not conceal extraction, transformation, validation, normalization, or
hashing logic in Bash, Git plumbing, internal-agent transport, JavaScript,
ECMAScript, TypeScript, Python, Perl, AWK, or any other language.

The generic pure-Zig ingress, synthetic tests, real-byte provisioning, and
execution are four separate authority edges. Authorization of any earlier edge
does not imply a later one. In particular, this design neither supplies the
BK bytes nor authorizes a Git blob extraction or a runtime worktree read.

## 10. Authority matrix

| Scope | Current authority | Prospective boundary required | Result in CC |
|---|---|---|---|
| Evidence/design | Authorized only for this document. | None beyond successful CC closure. | Complete design record only. |
| Generic Zig ingress implementation | None. | Separate sole-file/private-test-root source authority with exact API, allocator, error, and reachability review. | Not implemented. |
| Synthetic/frozen tests | None. | Separate test-source and focused build/test authority; fixtures must be inert and must not contain real committed bytes without authority. | Specified only. |
| Real-byte provisioning | None. | Separate selection of exactly one variant and exact producer/provenance/ownership/immutability authority. | No supply selected or created. |
| Execution | None. | Separate one-shot execution authority after implementation, tests, provisioning, and protected-state gates. | `execution_authority=none`. |
| Publication | None. | Separate trusted output-parent, exclusive no-replace, durability, read-back, and lifecycle authority. | No output or marker. |
| Production | None. | Separate public/API/build/install/reachability review and explicit authorization. | `production_authority=none`. |
| D01 | Withheld. | Separate evidence acceptance after authorized real execution. | `D01=withheld`. |
| D02 | Unauthorized. | Separate explicit authority; no implication from D01 or this design. | `D02=unauthorized`. |
| Ratchet | Frozen at 131. | Separate explicit ratchet movement authority. | `ratchet=131`. |

## 11. Protected-state boundary

The registered-worktree exclusion remains absolute. No worktree list was
replayed and no registered directory was entered or treated as an artifact
source. The retained registration authority remains:

```text
registered_worktree_count=43
registered_worktree_path_list_sha256=f31d8542baafc7b64cd5ee6fe8cc4194842ca696b97a7ffc8df06ce12d553d7e
registered_worktree_topology_sha256=6c868e3b6d436cfba92a1e2b21dbd616391763961f1cba9b6670b1ed4a6ebb62
registered_worktree_directory_access=none
worktree_list_invocation_count=0
```

The accepted protected identities remain:

```text
build_sha256=3ab852ee10a670fa076d478ab1b45f9c63dd585950597b6dcb13f2e01cea4a38
watcher_sha256=1221b00a6aacd7deaae9aab50bd2600be33a13b0ed645428f9475a2cb81a893d
watcher_pid=3206208
stash_head=7985c6d01040a6e47e4ce5b918866d0e89517ac7
control_head=9c55bda34088e1230b0b91a126d35795a3ac70b4
control_tree=756369ad4a89d806f463bd8094c5159d8c973d7e
control_branch=main
control_status=clean
control_remote_count=0
retained_cache_slices=BP,BR,BT,BU,BW,BY,BZ
absent_cache_slices=BS,BV,BX
bi_evidence_state=absent_non_symlink
bi_continuation_state=absent_non_symlink
```

## 12. Terminal disposition

This design does not resolve CA's blocker and does not select CA Option 4.
It makes the prospective ingress choices and their ownership, byte, EOF,
hash, and TOCTOU obligations reviewable while retaining Option 1.

```text
design_complete_for_cc=true
implementation_performed=false
synthetic_tests_created=false
real_bytes_supplied=false
git_object_extracted=false
registered_worktree_traversal_performed=false
publication_performed=false
materialization_performed=false
installation_performed=false
descriptor_status=conditionally_supported
execution_authority=none
production_authority=none
D01=withheld
D02=unauthorized
ratchet=131
```
