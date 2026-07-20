INBOX-194D generated snapshot-member key correction
====================================================

Disposition
-----------

PASS.  The bounded generator correction completed under operating-document
commit 8ff34a9d41eda668bcc385efa089a3e06f872cbc.  The sole closed-environment
orchestration returned status 0 without retry or component substitution.
The exact INBOX-194D synthetic root was reverified, removed, and its parent
was synchronized.  INBOX-194A, INBOX-194B, INBOX-194C, every earlier record,
the real-store absence, validation-v3 absence, registered worktrees, pins,
watcher, and stash remain unchanged.  Ratchet remains 131.

Bounded change
--------------

The sole production correction is in appendPublishedSnapshot:

  snapshot-member .key = object.key

The existing `.member_path = object.key`, target_id, SHA-256, bytes, immutable
0444 mode, source_mode/logical-reference behavior, schema, source
specification, proposed rows, snapshot behavior, store/authority behavior,
validateRelationships, duplicate-key policy, and sameIdentity are unchanged.

The private focused test constructs one production-generated snapshot
manifest from two distinct immutable objects.  It proves:

- canonical parse and re-encode byte equality;
- two generated members, each with key == member_path == target object key;
- exact shared-key SHA-256, byte-count, and mode identity;
- the original two-member "-" key pattern fails with
  ConflictingManifestKey;
- a cross-object member key fails with ConflictingManifestKey;
- shared-key hash and byte mismatches fail with ConflictingManifestKey; and
- a non-0444 member mode fails with InvalidSnapshotMemberRow.

The pre-existing general conflicting-key negative remains unchanged.

Frozen input identities
-----------------------

Pre-edit retained dirty identities:

  tools/zllvm_artifact_store.zig
    ee2969c2d8b46b6cb8e2fa1cbd86270c64971630d659f3449ec6ca1e0af274d9
  docs/evidence/inbox194_calls_canonical_source_spec_v1.tsv
    0dd908eed246b09fbea8fd87241ce899b100823b8d83c7223d4e48928e7c599b
  docs/evidence/inbox194_calls_proposed_live_manifest_v1.tsv
    ced7f4e13e1ce646e114460805162aa27fcd8c20c75c4d325c6bd762ce0b6263

Post-change bounded tool identity:

  tools/zllvm_artifact_store.zig
    94dfc1fc27ffe1268eb02453bcac1a3634aa11af38d0c94fbaa3b43decd25859
    4237 lines, 166515 bytes

The canonical specification and proposed fragment retain their exact
pre-edit SHA-256 values above.  The specification remains 19 data rows with
16 fields.  The proposed fragment remains 35 data rows with 17 fields.
No non-tool identity moved.

Pre-orchestration checks
------------------------

Exact commands:

  /home/oleg/bin/zig fmt tools/zllvm_artifact_store.zig
  git diff --check
  /home/oleg/bin/zig test tools/zllvm_artifact_store.zig -fno-emit-bin
  /home/oleg/bin/zig build-exe tools/zllvm_artifact_store.zig -OReleaseSafe -fno-emit-bin

All formatting, diff/static, test-root compile-only, and ReleaseSafe CLI
compile-only checks passed before the INBOX-194D root or validation namespace
was used by the orchestration.

Sole orchestration
------------------

Retained records:

  command
    tmp/inbox194d_o2_artifact_store_cli_dormant/validation/full-gate.command.txt
    sha256 2a46672fddef879667f00feae54f11d346430828e108dab6a2c4a11ee076f092
  environment
    tmp/inbox194d_o2_artifact_store_cli_dormant/validation/full-gate.environment.txt
    sha256 9b93a3fa4f6d66572f57b389a338303c3cdf229a8a0f07d86ad6ee7992e308c0
  launcher
    tmp/inbox194d_o2_artifact_store_cli_dormant/validation/full-gate.launcher.txt
    sha256 72e595464fd14174c5ad50d4d28bb65f478a981fae24d83653dcac7e1120b236
  stdout
    sha256 e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
    bytes 0
  stderr
    sha256 ea4109b958edcc39ce893547dff23524337bc895a0101dbac132d4dfb77027b3
    bytes 184
  status
    sha256 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
    value 0

The launcher used `env -i`, separate stdout/stderr, and a separately written
numeric status.  The command and launcher contain no shell pipeline.  There
was exactly one invocation.

Results:

  artifact-store-test: 8/8 passed
  resolve-authority: exact INBOX-194D root
  materialize-spec plan: byte-identical to tracked proposed fragment
  proposed.actual.tsv:
    ced7f4e13e1ce646e114460805162aa27fcd8c20c75c4d325c6bd762ce0b6263
  first publish: success
  second publish: success and byte-identical idempotent output
  published manifest:
    61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
  generation-00000001.tsv:
    61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
  immutable primary/constituent objects: 18
  immutable snapshots: 2
  generated snapshot members checked: 16
  manifest files: 1
  artifact-identities.sha256:
    50e236fdb38f2ae98e0f20cab62a6cc7384f1ff65da34763c2321526a897bd12

Every generated member in the published manifest has key == member_path ==
the referenced object key, with exact SHA-256, bytes, and 0444 mode.

Retained attempt ledgers
------------------------

All inventory discovery used ignore-independent `find -P`.

INBOX-194:

  root state: absent
  validation record count: 6
  validation record ledger:
    732f2dbd137811b691f0ba88fbff8154aae9413abe3a6242685312e76e723b79

INBOX-194A:

  root inventory:
    a5beb98c4e8784571667007564386481f833b0424237a43d97464f201d6ecb76
  retained root: mode 0775, exact authority-symlink -> .
  validation record count: 7
  validation record ledger:
    be8a5a2e41fa09562a6876dc362ed29029a55852c18bc1107498c9c2aadb3d8f

INBOX-194B:

  root inventory:
    afc512463fb1763f812f943ff1d48535d858369ae724ec82a49af7f0eab39710
  validation record count: 14
  validation record ledger:
    5b030639065528952e446281b8ba0167a65b387b10de34aa12fe79baa03e1080

INBOX-194C:

  root inventory:
    8296a00b5ad29f4f5fdb3cbe232e788ec9ebbae60d5472c30862246300ee5ddd
  regular-file count: 20
  regular-file identity ledger:
    472f30bc4d3319086c0a8d48c6e1210013dd668d951591114793f13356cd464e
  validation record count: 74
  validation record ledger:
    50a3deacf44c49ebfee47ded1d0ed5975c4731eee5235f878123b72587891238

INBOX-194D before authorized success cleanup:

  root mode: 0775
  root inventory:
    3234fb508d370878efe082cf1accb5af3b488372bf3f1ee7e9e87408a37a2d7c
  regular-file count: 21
  regular-file identity ledger:
    a06c48e1549d16b9f924cc2b5f0404e60d7755a785bf3a4a23311c2383279a65

INBOX-194D final validation records:

  record count: 200
  four-field basename-ordered record ledger:
    ace4a5271954f81a1a9cabe996ea248cc46fba939a69b3ef68a552d9f6559232

Success cleanup
---------------

The cleanup preflight rechecked the exact D inventory and regular-file ledger,
required a canonical non-symlink mode-0775 root, and proved disjointness
against the frozen registration metadata before removal.

  success-cleanup.command.txt:
    70c31d885d5796940779bea73c83375fe4649430c5d3ea9f6a23b2438d89562f
  success-cleanup.environment.txt:
    4f7fbcaea059e1ea7c60e3e88a4a535796b22394897554a5f3e5578599aeb52c
  success-cleanup.launcher.txt:
    f1e0e308e56d72caec8cc29a7733ec0f51836bd6aa2677904fa5c85d5252943e
  cleanup stdout:
    e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
  cleanup stderr:
    e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
  cleanup status:
    0

Only `/home/oleg/prog/z_llvm-inbox194d-artifact-store-synthetic` was removed;
its parent was synchronized.  The final D-root state is absent.

Frozen postflight
-----------------

  registration.initial.txt == final.registration.txt
  registration SHA-256:
    421bb2dd6f840dfe46065ce2a6bc59ed5e19819b5e973eae55366821d3fb3ce7
  registered-worktree path-list SHA-256:
    f31d8542baafc7b64cd5ee6fe8cc4194842ca696b97a7ffc8df06ce12d553d7e
  watcher Git blob:
    b64131cf60dd0ef638e815cd33db9ae8595a72cf
  stash object:
    7985c6d01040a6e47e4ce5b918866d0e89517ac7
  retention pins:
    1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
  durability audit:
    5a7e019eb107e5b66947490a65fdf47444154fc4f1483ca30ab0fc6e381f33e6

The INBOX-194 root, real store, validation-v3 namespace, and INBOX-194D root
are absent.  INBOX-194A/B/C and every earlier retained root/record remain
unchanged.  No live row, compatibility copy, pin/contract amendment,
validation-v3 execution, selector validation, production wiring, performance,
Tier work, checkpoint change, cleanup integration, ratchet movement, or
credit was performed.
