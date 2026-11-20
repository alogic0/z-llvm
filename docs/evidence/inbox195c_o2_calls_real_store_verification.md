INBOX-195C read-only authoritative-store verification
======================================================

Disposition
-----------

PASS.  The sole pipeline-free closed-environment full verifier completed at
status 0 from operating-document commit
`6a08f43a394d835c261d021870a2f383738f8612`, whose exact parent is
`84324dfbd68836a9c772bc6c8b05666531c24d52`.

The accepted INBOX-195B AWK precheck was not rerun.  No artifact tool,
project code, compilation, plan, publication, resolution, materialization,
compatibility action, validation-v3 action, cleanup, production wiring,
performance, Tier work, checkpoint change, ratchet movement, or credit was
performed.

Operating identity and bounded carry-forward
---------------------------------------------

Before the fresh namespace was created, the dispatched 40-character commit
was compared byte-for-byte with `git rev-parse HEAD`, and `git rev-parse
HEAD^` was required to equal the parent above.  Both checks passed.

The frozen INBOX-195B full verifier was carried forward mechanically.  Its
only changes were:

- fresh namespace binding to
  `tmp/inbox195c_calls_real_store_verification/validation/`;
- exact operating HEAD and parent bindings;
- the operating-document delta base binding; and
- the frozen INBOX-195B 20-file record-ledger check.

All substantive checks remained unchanged, including the accepted
`repository_count` / `system_count` / `other_count` AWK identifiers, exact
33/8/2 worktree distribution, `.tar.zst` snapshot digest derivation, and
`application/octet-stream` snapshot-member rule.

The accepted INBOX-195B AWK precheck remained preserved in its prior
namespace and was not copied or invoked.

Frozen verifier
---------------

Exact command:

  env -i HOME=/home/oleg LANG=C LC_ALL=C PATH=/usr/bin:/bin TZ=UTC /bin/bash --noprofile --norc tmp/inbox195c_calls_real_store_verification/validation/verify.command.sh

Frozen identities:

  verify.command.sh
    0c14bd41a29783f48a9e0e3a4be4ae0a8931041acbcb042e08f1118e9f6d7d7a
  verify.launcher.sh
    6586ce66baafde3329791f66cbda0136005befc453afe16c7db9d7c24498549b

Static Bash syntax and pipeline checks passed before the invocation.  The
launcher used `env -i`, the exact environment above, separate stdout and
stderr, and a separately retained numeric status.  It was invoked exactly
once.

Retained result:

  status: 0
  stdout bytes: 29
  stdout SHA-256:
    71c8ee109607d0ce88acc654adb06cf00e90bba8fd2295a0f28ed027c1c7c8b5
  stderr bytes: 0
  stderr SHA-256:
    e3b0c44298fc1c149afbf4b8996fb92427ae41e4649b934ca495991b7852b855

The mechanically frozen stdout label remains
`INBOX-195A verification PASS`; the status, command identity, namespace, and
this evidence identify the accepted INBOX-195C invocation.

The fresh validation namespace contains 75 regular files.  Its virtual
LF-terminated, bytewise-basename-sorted
`sha256<TAB>bytes<TAB>mode<TAB>basename` ledger has SHA-256:

  e80b6a5f540451529bbed0612b60d53cae822ccf3d08a92159a522c9239293ae

Authoritative store and manifest
--------------------------------

The verifier recomputed the two frozen, ignore-independent serializations.

Exact no-follow inventory command shape:

  find -P ROOT -printf '%y\t%m\t%P\t%l\n'
  LC_ALL=C sort

Resulting inventory SHA-256:

  3234fb508d370878efe082cf1accb5af3b488372bf3f1ee7e9e87408a37a2d7c

The separate bytewise-relative-path-sorted regular-file ledger contains 21
LF-terminated `sha256<TAB>bytes<TAB>mode<TAB>relative-path` rows and has
SHA-256:

  a06c48e1549d16b9f924cc2b5f0404e60d7755a785bf3a4a23311c2383279a65

The sole INBOX-195 publication stdout, authoritative
`manifests/generation-00000001.tsv`, and tracked
`docs/evidence/artifact_manifest_v1.tsv` are byte-identical at:

  61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d

The authoritative store remains mode 0775 and contains exactly:

- 18 mode-0444 content-addressed objects;
- two mode-0444 content-addressed `.tar.zst` snapshots;
- one mode-0444 generation manifest;
- empty `snapshot-work` and `snapshot-proof` directories; and
- no partial, incoming, symlink, or other non-directory/non-regular entry.

Every object key matches its content SHA-256.  Each snapshot key has exactly
two lowercase hexadecimal directory characters, 62 lowercase hexadecimal
basename characters, and the exact `.tar.zst` suffix; removing only that
suffix reconstructs its exact 64-character content SHA-256.

Manifest transition and relationships
-------------------------------------

The verifier proved:

- all 35 proposed object/logical-reference identities exist with status
  changed exactly to `active`;
- the live manifest adds exactly two constituent objects, two snapshots, and
  16 snapshot members;
- all 55 live rows have 17 fields and active status;
- every object and snapshot manifest key matches the authoritative store;
- each snapshot member uses media `application/octet-stream`;
- each member's key equals its member path and exact target-object key;
- target ID, SHA-256, byte count, immutable mode, and snapshot relationship
  are exact; and
- each snapshot's constituent SHA-256 resolves to an immutable object.

Target object media was intentionally not compared with snapshot-member
media, preserving the reviewed source-media distinction.

Frozen boundary
---------------

The complete verification also passed for:

- all 19 canonical source rows, bytes, modes, hashes, and non-main-worktree
  exclusions;
- 43 registered worktrees with exact path/topology/non-main hashes and
  33/8/2 distribution;
- bidirectional authority/worktree disjointness and no-follow canonical
  authority ancestry;
- exact INBOX-194A/B/C retained-root inventories and the INBOX-194C
  20-file ledger;
- exact INBOX-194, 194A, 194B, 194C, 194D, 195, 195A, and 195B record
  ledgers;
- absent INBOX-194 and INBOX-194D roots;
- watcher Git blob
  `b64131cf60dd0ef638e815cd33db9ae8595a72cf`;
- stash object `7985c6d01040a6e47e4ce5b918866d0e89517ac7`;
- retention pins
  `1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3`;
- durability audit
  `5a7e019eb107e5b66947490a65fdf47444154fc4f1483ca30ab0fc6e381f33e6`;
- frozen tool, schema, specification, proposed-plan, calls-sequence,
  contract, and bypass-inventory identities;
- the direct bypass recount of 131;
- the mandatory future post-calls checkpoint; and
- complete validation-v3 root and external-prefix absence.

Fresh available capacity at verification was 96,692,563,968 bytes.

Final state
-----------

The authoritative store and all ignored validation records remain preserved.
Only the exact tracked live manifest and this evidence summary are committed.
Ratchet remains 131.  Validation-v3 remains blocked pending
Watcher/Reviewer publication acceptance.
