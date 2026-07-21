# INBOX-206CG Real-Byte Supply Boundary

## 1. Scope and disposition

This document is an evidence/design checkpoint only. It does not implement, select, provision, invoke, validate, publish, or authorize a real-byte ingress mechanism.

```text
slice=INBOX-206CG
document_kind=real_byte_supply_boundary
cf_scope=private_synthetic_ingress_only
selected_variant=none
implementation_authority=none
real_byte_supply_authority=none
execution_authority=none
production_authority=none
descriptor_status=conditionally_supported
D01=withheld
D02=unauthorized
ratchet=131
```

CF is accepted for its private synthetic-ingress scope: bounded snapshot construction, exact-length/digest/EOF checks over synthetic bytes, and atomic single-use admission. That acceptance supplies no real committed bytes and grants no execution beyond the named synthetic test.

## 2. Static authority identities

The following identities are administrative bindings. They identify reviewed repository objects and documents; they are not runtime proof that a future byte producer supplied those objects' contents.

| Subject | Administrative identity |
| --- | --- |
| CG operating commit | `13777280dbae581e1dbba8eded0149656cf33217` |
| Accepted CF commit | `86e16bf3bb173d3d72ae1b17b6e64f9e9a3b4e2b` |
| Accepted CF tree | `da1045a183412d5d0a957e0563ec1c85331e0a6f` |
| Accepted CF source blob | `77809d948ef6ee630f17c721cb071f7353feb3a8` |
| Accepted CF source raw SHA-256 | `f7adf9f37bf7b64b80ef4fe1077562a0a32390e2c07e4db9ddb6f55e4f7cbcef` |
| CA evidence commit | `44b2c2b2fe6b0dfc9eb894a96e99d38b5ecb4227` |
| CC evidence commit | `f5c560015ce639f94faf75655f4b503bca848e2d` |
| BK specification path | `docs/evidence/inbox206bk_zig_materialization_readiness_design.md` |
| BK specification commit | `f9b2f30a154e5422c53d04bc21cc1e92e667300b` |
| BK specification tree | `174923e4bfd78f6ae003556a9ed17ddf950d74fd` |
| BK specification blob | `573e128bb999d8aba15ae5ac6dc69a52ac3e8812` |
| BK specification raw SHA-256 | `66b0dfdff5c61b00a16e815994bb9c06e3596260d611a2e35cb83cbe99b9e187` |
| BK specification raw bytes | `29834` |

Git blob identity and raw-content SHA-256 are different identity domains. Administrative commit/tree/blob/path/length/hash binding must remain separate from runtime evidence about the producer, supplied object, acquisition interval, and returned snapshot.

The accepted CA state retains Option 1 as the only authorized implementation state. CA Option 4 and every CC ingress variant remain prospective.

## 3. Security-property trace and non-downgrade rule

BK requires exact specification admission and a trusted chain while preserving registered-worktree protection. CC then separates snapshot integrity from acquisition-time immutability: descriptor identity alone does not prove immutable contents; mutation after acquisition cannot affect an owned snapshot; mutation during acquisition must be detected or remain blocked unless the selected mechanism guarantees immutability for the full acquisition interval. CF closes bounded final-snapshot verification and atomic single-use admission only for synthetic input.

The required properties therefore remain distinct:

```text
required_property_event_freedom=no_mutation_event_during_acquisition
required_property_final_bytes=exact_length_sha256_and_eof
property_relationship=distinct_noninterchangeable
selected_variant=none
```

Verified final bytes do not prove that no mutation event occurred while those bytes were acquired. Conversely, acquisition-time immutability does not prove that the producer supplied the administratively bound BK bytes. Neither property may be weakened into, inferred from, or substituted for the other.

## 4. Independent property evaluation

| Property | Administrative binding | Required runtime proof | Current state | Blocking gap |
| --- | --- | --- | --- | --- |
| Producer provenance | BK path, commit, tree, blob, raw length, and raw SHA-256 are recorded | The selected trusted producer must bind the supplied runtime object/stream to those exact administrative identities without hidden extraction or transformation | blocked | No producer or provenance-transfer protocol is selected or authorized |
| Acquisition-time immutability/event-freedom | CC records the requirement | Evidence must establish no mutation event during the complete acquisition interval, or a selected mechanism must guarantee that property | blocked | No selected descriptor/seal/stream mechanism proves interval-wide event-freedom |
| Returned-snapshot identity | Expected raw length `29834` and SHA-256 are recorded | Pure Zig copies identical bytes while hashing, requires exact length and immediate EOF, and admits parsing only from the verified owned snapshot | closed only for CF synthetic input | No authorized real-byte producer connects the administrative identity to CF's consumer |
| Single-use lifecycle | CF source identity and reviewed atomic contract are recorded | Exactly one claimant transitions the token from unused to in-progress; every admitted exit publishes consumed; all competing/repeated claims fail without allocation or callback | closed for CF private synthetic mechanism | Single-use admission proves neither producer provenance nor acquisition-time immutability |

These four determinations are independent. A pass in one row cannot be borrowed by another row.

## 5. Non-conflation rules

| Evidence or mechanism | What it may prove | What it does not prove |
| --- | --- | --- |
| Descriptor identity | A held descriptor's reviewed object identity and expected role at an observation point | Content immutability, absence of mutation events, Git provenance, or raw-content equality |
| Immutable/sealed state | Only the immutability guarantees established for a specifically audited API, platform, seal set, and lifetime | Git commit/tree/blob provenance or exact BK raw bytes by itself |
| Exact raw SHA-256 and length | Equality of the completed owned snapshot to the expected final bytes, when computed by the trusted Zig consumer | Absence of mutation events during acquisition or identity of the producer |
| Atomic one-shot token | Unique admission and terminal lifecycle for one token object | Source identity, source immutability, byte correctness, or administrative provenance |

The token object's identity is the lifecycle uniqueness boundary. It cannot be promoted into an identity for the supplied bytes.

## 6. Closed CC variant matrix

All three variants remain unselected. Each row records a complete prospective contract and the exact unresolved authority boundary.

| Variant | Producer and provenance inputs | Consumer and ownership | Offset and EOF contract | Immutability/event-freedom evidence | Identity verifier | Decision and blocker |
| --- | --- | --- | --- | --- | --- | --- |
| 1. Caller-supplied held regular-file descriptor | Producer is an unspecified external provisioner; inputs would include BK path/commit/tree/blob/raw length/raw SHA-256 plus a binding from those identities to the held descriptor | Future private pure-Zig consumer borrows the descriptor; caller retains close responsibility; returned snapshot is owned and deinitialized once by its caller | Start at an explicitly established offset zero, consume exactly `29834` bytes, then perform the required one-byte read and accept only canonical EOF; no duplicate or second supply | An ordinary held regular-file descriptor supplies no interval-wide immutability guarantee; descriptor identity is insufficient | Administrative reviewer binds Git identities; future Zig consumer verifies descriptor role and final snapshot length/hash/EOF; no trusted runtime bridge currently joins them | blocked: producer/provenance protocol and acquisition-time event-freedom are unspecified |
| 2. Caller-supplied immutable/sealed descriptor | Producer is an unspecified trusted Zig provisioner; inputs would include the same BK identities plus audited immutable/seal evidence tied to the supplied descriptor | A future contract must state transfer or borrowing explicitly; if transferred, the Zig consumer owns and closes the descriptor exactly once; snapshot ownership remains separate | Establish offset zero before acquisition, consume exactly `29834` bytes, require immediate EOF, and reject reuse or a second supply | Potentially supportable only after an exact platform/API audit proves the required immutable/sealed state before reading and throughout acquisition; support is not presently established | Administrative reviewer verifies Git identities; audited Zig code verifies descriptor role, seal/immutability state, and final snapshot identity | blocked: exact producer, provenance handoff, supported immutable API, seal set, and lifetime proof are absent |
| 3. Bounded one-shot byte stream | Producer is an unspecified pure-Zig adapter; provenance inputs would need to bind that adapter's source object to the BK identities | Future private Zig consumer borrows the callback context synchronously; producer retains backing-resource close responsibility; consumer owns only the verified snapshot | Logical stream begins at zero, permits no seek/replay/duplicate supply, returns nonempty chunks or canonical EOF, supplies exactly `29834` bytes, then EOF on the one-byte probe | CF's atomic token proves one admitted lifecycle, not event-freedom of the backing producer; no interval-wide immutability evidence exists | Administrative reviewer verifies expected identities; Zig consumer verifies lifecycle and final length/hash/EOF; producer identity remains unverified | blocked: producer provenance and acquisition-time event-freedom are unspecified despite closed synthetic lifecycle behavior |

Unspecified provisioning is fail-closed. No variant may inherit a producer, ownership rule, offset rule, EOF rule, immutability claim, or verifier from another row.

## 7. Forbidden provisioning shortcuts

The following mechanisms remain explicitly rejected as real-byte supply authority:

- `@embedFile` of a registered-worktree path;
- a build-time worktree read;
- pathname reopen or real-path traversal to the specification;
- Git CLI, Git plumbing, or Git-object extraction as a runtime producer;
- a subprocess or shell producer;
- internal-agent transport carrying project bytes or project algorithms;
- JavaScript, ECMAScript, TypeScript, Python, Perl, AWK, or another-language helper;
- generated, transformed, or sourced executable producer logic;
- mutable supply whose interval-wide event-freedom is not proved;
- a supply whose final length, SHA-256, and immediate EOF are not checked by the pure-Zig consumer.

External provisioning remains unauthorized and cannot hide extraction, transformation, validation, hashing, or provenance logic in orchestration.

## 8. Decision matrix

| Variant | Producer provenance | Acquisition event-freedom | Returned snapshot identity | Single-use lifecycle | Selection |
| --- | --- | --- | --- | --- | --- |
| 1. Held regular-file descriptor | blocked | blocked | prospectively verifiable | requires explicit one-shot integration | not selected |
| 2. Immutable/sealed descriptor | blocked | blocked pending exact API evidence | prospectively verifiable | requires explicit one-shot integration | not selected |
| 3. Bounded one-shot byte stream | blocked | blocked | closed only for synthetic CF input | closed only for CF token object | not selected |

No row closes both the threat model and an exact producer contract. Therefore:

```text
selected_variant=none
```

## 9. Recommendation without authority

The smallest prospective next step is a Zig-only evidence/API audit for Variant 2's producer boundary. That audit must jointly establish:

1. the exact native Zig API and supported runtime contract for creating or receiving an immutable/sealed descriptor;
2. the exact seal or immutability predicates, failure taxonomy, ownership transfer, offset state, close responsibility, and lifetime that guarantee no mutation event during the full acquisition interval;
3. a trusted administrative-to-runtime provenance handoff tying that descriptor to the recorded BK commit/tree/blob/raw-length/raw-SHA identities; and
4. compatibility with CF's bounded one-shot snapshot consumer without worktree traversal, Git plumbing, shell production, or foreign-language logic.

This recommendation grants no authority to implement, provision, select, invoke, validate, publish, materialize, install, or supply real bytes. If the audit cannot prove both exact producer provenance and interval-wide event-freedom, Variant 2 remains blocked and `selected_variant=none` remains binding.

## 10. Terminal authority boundary

CG records design evidence only. It creates no dormant or live production slice, no real-byte receipt, no cache, no continuation, and no change to the accepted source. Main/control, stash, watcher, retained cache roots, BI absence, recorded 43-worktree identities, D01/D02 disposition, and ratchet 131 remain protected.

```text
design_complete=true
implementation_ready=false
real_byte_provisioning_ready=false
selected_variant=none
execution_authority=none
production_authority=none
D01=withheld
D02=unauthorized
ratchet=131
```
