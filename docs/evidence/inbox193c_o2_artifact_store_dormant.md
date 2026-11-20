INBOX-193C — dormant artifact-store snapshot-proof ownership correction
Date: 2026-07-19
Result: PASS; bounded implementation ready for review
Ratchet: unchanged at 131

Authorization and starting boundary
-----------------------------------

The repository-verified operating commit was
f4eb305e69252f7868c63090243a5f1a9df824e4. This is the authoritative
full identity; the earlier Watcher expansion ending in 38079c6 was a
transcription error and was not used by any check or edit.

The retained dirty composite matched the frozen INBOX-193B ledger:

  build.zig
    state: modified, 12 insertions
    sha256: a0c923499cd4515326fb287d729c53ae6d68bb465a4b4a033a737a19466ce466
  tools/zllvm_artifact_store.zig
    state: untracked, 2743 lines
    sha256: f2cc68858ddc095eb89a1db391a87cec61271c93f4f827056f238125838584ee
  docs/evidence/zllvm_artifact_manifest_v1.template.tsv
    state: untracked, 2 lines
    sha256: 32ec98e06916ec885435187f263ee3408fce001d6275f6ee3a8e7c1330b5784f

The new root
/home/oleg/prog/z_llvm-inbox193c-artifact-store-synthetic was absent and
its normalized path was neither equal to, inside, nor an ancestor of any
registered worktree. The real store and validation-v3 root were absent.

Ownership correction
--------------------

SnapshotProofFault, verifySnapshotArchiveWithFault, its parameter and
conditional branch, the injected error path, and the direct test call were
removed completely. Production snapshot ordering, listing validation,
extraction, constituent verification, and all callers remain unchanged.

The private SnapshotProofWorkspace now owns both proof-parent and workspace
directory handles. Explicit booleans record parent ownership, workspace
ownership, and workspace existence. The production success path calls the
fallible finish operation, which closes the workspace once, deletes it once,
marks it absent before syncing, and closes the parent once. The deferred
error cleanup observes the updated state and therefore cannot close or
delete again. Error cleanup closes each owned handle and performs one
best-effort delete/sync. No invalid-handle sentinel is used.

The private test-only helper acquires the same resource and deliberately
returns TestSnapshotProofEarlyFailure. The exact error is preserved and the
snapshot-proof parent is asserted empty afterward. Normal publication and
verification success paths retain their empty-parent assertions. The
bounded close/deinit/defer/errdefer audit found no additional defect in this
ownership class.

Four-attempt ledger
-------------------

INBOX-193:

  root: /home/oleg/prog/z_llvm-inbox193-artifact-store-synthetic
  final state: preserved empty directory, mode 0775
  suite: 5 pass, 1 fail
  failure: InvalidCapacityObservation before publication
  retained log:
    tmp/inbox193_o2_artifact_store_dormant/validation/artifact-store-test.log
    sha256: fc8c550de125f5e31de9ad13288ad7d08f579759731c90b4a86b98a1c4cff51f

INBOX-193A:

  root: /home/oleg/prog/z_llvm-inbox193a-artifact-store-synthetic
  final state: preserved populated directory, mode 0775
  suite: 5 pass, 1 crash
  failure: verifySnapshotArchive double close/use-after-close
  execution record: Worker pane transcript only
  standalone suite log: none

INBOX-193B:

  root: /home/oleg/prog/z_llvm-inbox193b-artifact-store-synthetic
  final state: preserved populated directory, mode 0775
  snapshot-proof: preserved empty directory, mode 0775
  snapshot-work: preserved empty directory, mode 0775
  suite: 5 pass, 1 fail, status 1
  failure: unsorted direct test input was rejected with
    UnsafeOrUnexpectedSnapshotMember before fault-workspace acquisition
  command sha256:
    150857d63321824b56f7eabf4459e8ac7f70ea96a79b80adc14dbc6568dc9790
  environment sha256:
    8c9e573613e1ab44ea770f0b2e10416a5fd01fb68d774e81cc50fb0c064e959c
  stdout sha256:
    e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
  stderr sha256:
    decb2e79f69d0ecb21ed5a414de24dd96501601bce7ea2af0173671b3005cec3
  status sha256:
    4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865

INBOX-193C:

  root: /home/oleg/prog/z_llvm-inbox193c-artifact-store-synthetic
  initial state: absent
  suite: 6 pass, 0 fail, status 0; invoked exactly once
  success cleanup: normalized exact root revalidated through the frozen
    registration guard, opened without following symlinks, removed, and
    parent synchronized
  final state: absent
  command record:
    tmp/inbox193c_o2_artifact_store_dormant/validation/artifact-store-test.command.txt
    sha256: b27c726ec711e19c7099d2c7e906da46665b5409692d1b970dc881017d02407d
  environment record:
    tmp/inbox193c_o2_artifact_store_dormant/validation/artifact-store-test.environment.txt
    sha256: 951131b7ca570a8be042139974c45ba355b56d6f6e1d46e3d6c06802884221ff
  stdout record:
    tmp/inbox193c_o2_artifact_store_dormant/validation/artifact-store-test.stdout.log
    sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
  stderr record:
    tmp/inbox193c_o2_artifact_store_dormant/validation/artifact-store-test.stderr.log
    sha256: 02db5b2ac04377c8ed0edcfd10991c812373848cd17a7d2d987364d18be390fe
  status record:
    tmp/inbox193c_o2_artifact_store_dormant/validation/artifact-store-test.status.txt
    sha256: 9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa

The exact suite command was:

  env -i HOME=/home/oleg LANG=C LC_ALL=C PATH=/home/oleg/bin:/usr/bin:/bin SOURCE_DATE_EPOCH=0 TMPDIR=/tmp TZ=UTC ZIG_GLOBAL_CACHE_DIR=/home/oleg/.cache/zig ZIG_LOCAL_CACHE_DIR=/home/oleg/prog/z_llvm/.zig-cache ZLLVM_ARTIFACT_STORE=/home/oleg/prog/z_llvm-inbox193c-artifact-store-synthetic /home/oleg/bin/zig build artifact-store-test --summary all

Pre-suite validation
--------------------

Commands, in order:

  /home/oleg/bin/zig fmt tools/zllvm_artifact_store.zig build.zig
  git diff --check
  rg -n "SnapshotProofFault|verifySnapshotArchiveWithFault|after_workspace_open|\\.handle = -1" tools/zllvm_artifact_store.zig
  /home/oleg/bin/zig test tools/zllvm_artifact_store.zig --test-no-exec
  /home/oleg/bin/zig build-exe tools/zllvm_artifact_store.zig -fno-emit-bin
  /home/oleg/bin/zig build --help | rg -n '^  artifact-store-test'

Formatting, diff/static checks, both compile-only checks, and build-step
discovery passed. The forbidden-hook search produced no match. The 193C root
remained absent after every pre-suite stage.

Final bounded file identities
-----------------------------

  build.zig
    lines: 436
    sha256: a0c923499cd4515326fb287d729c53ae6d68bb465a4b4a033a737a19466ce466
  tools/zllvm_artifact_store.zig
    lines: 2813
    sha256: dc0e5ccbec6adc33480fb4e4d7e2c56745253707e3d7f093f4064f6affa39081
  docs/evidence/zllvm_artifact_manifest_v1.template.tsv
    lines: 2
    sha256: 32ec98e06916ec885435187f263ee3408fce001d6275f6ee3a8e7c1330b5784f

Frozen postflight
-----------------

  registered worktrees: 43
  distribution: 33 / 8 / 2
  path-list sha256:
    f31d8542baafc7b64cd5ee6fe8cc4194842ca696b97a7ffc8df06ce12d553d7e
  topology sha256:
    6c868e3b6d436cfba92a1e2b21dbd616391763961f1cba9b6670b1ed4a6ebb62
  non-main records sha256:
    ebc30a376b3db4c6fbf788f49ea85f4ce792471e539c0a89308068efdf96ebbe
  watcher blob:
    b64131cf60dd0ef638e815cd33db9ae8595a72cf
  stash@{0}:
    7985c6d01040a6e47e4ce5b918866d0e89517ac7
  durability audit sha256:
    5a7e019eb107e5b66947490a65fdf47444154fc4f1483ca30ab0fc6e381f33e6
  retention pins sha256:
    1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
  bypass inventory sha256:
    2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11
  real store: absent
  validation-v3: absent
  production routing/checkpoint: unchanged
  ratchet: 131

No authoritative artifact access, protected-worktree traversal, live-row,
pin, contract, validation, wiring, performance, Tier, cleanup-integration,
checkpoint, ratchet, or credit action was performed.
