# INBOX-202E Local-State Snapshot-Verifier Diagnosis

## 1. Scope and disposition

This evidence-only diagnosis starts from operating commit
`6b39bca52076d03cf8c984fff4d898fd6b6865ad`, parent
`edf97754afa4dc99a99330417d78c6d49df93c89`.

INBOX-202D remains an accepted fail-stop only. Its one transaction published
all 20 finite payloads, then stopped before the first snapshot ledger row.
INBOX-202E reran neither that transaction nor the consumed ratchet recount.
It changed no source, destination, manifest, tool, control repository, pin,
registered worktree, or authority state.

The diagnosis harness completed with status `0`. It evaluated 157 stable
subject assertions and reported two false assertions. The first false
assertion is `S1-16-CONSTITUENT-HASH`. No correction was implemented.

## 2. Frozen retained state

The three retained transaction evidence roots were read-only verified:

```text
/tmp/zllvm-inbox202-local-state-copy-verify-evidence
/tmp/zllvm-inbox202b-local-state-copy-verify-evidence
/tmp/zllvm-inbox202d-local-state-copy-verify-evidence
```

The retained D-driver identity is:

```text
driver.command_sha256=ccd1c83ae3d9549e8132c1e73102932e041931ed4b56ff9e4a03299ded4b678c
```

Its nine record identities remain:

```text
capacity.tsv=d159bd2d90730f250b78ac7fbe162ff9bc6c07dc504b488ca60ac4eb41c7e9cf
driver.command=ccd1c83ae3d9549e8132c1e73102932e041931ed4b56ff9e4a03299ded4b678c
driver.environment=7783ea385f701ac9210ed0822981872516d8ed750e5cfbd566adace1aaf0ec89
driver.status=4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865
driver.stderr=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
driver.stdout=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
payload-table.tsv=7911a06f40adf5376020f81a1dc9b51bfcfbf2dfc7076360d852c956dd5198bf
snapshot-member-verification.tsv=1df7db2bbd8460340716be307cc6e0bd3a521ece7c443e1e94f35343a15cf7e2
transaction-ledger.tsv=8021f2c732e52ffd899a51b71338f4ea5902114f2a5520818f983ecc82cf19d5
```

The retained destination table still contains exactly 20 no-follow regular
files, 18 objects plus two snapshots:

```text
destination_files=20
destination_bytes=9970364
mode=0444
uid_gid=1000/1000
link_count=1
incoming_entries=0
destination_inode_byte_link_mode_ledger_sha256=ee3d24a7666e85ed08cb2f9ccf9cdb38f1f72c38a299836cd758df73af45914d
```

That ledger hash was identical immediately before and after diagnosis.

## 3. Read-only preflight

All preflight checks passed before the diagnosis root was created:

```text
main_status=clean
control_status=clean
control_head=a41690a4c47cf1040afe3d4dd3679a77015263ea
control_tree=67582eb6f4de0b3ab3a2ef2e7c3635c79349d00e
registered_worktrees=43+1
worktree_path_hash=f31d8542baafc7b64cd5ee6fe8cc4194842ca696b97a7ffc8df06ce12d553d7e
worktree_topology_hash=6c868e3b6d436cfba92a1e2b21dbd616391763961f1cba9b6670b1ed4a6ebb62
non_main_registration_hash=ebc30a376b3db4c6fbf788f49ea85f4ce792471e539c0a89308068efdf96ebbe
source_inventory_sha256=3234fb508d370878efe082cf1accb5af3b488372bf3f1ee7e9e87408a37a2d7c
source_file_ledger_sha256=a06c48e1549d16b9f924cc2b5f0404e60d7755a785bf3a4a23311c2383279a65
source_files=21
source_generation_tracked_manifest_cmp=equal
tracked_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
bypass_tsv_sha256=2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11
ratchet_recount_rerun=0
ratchet=131
```

The diagnosis root was absent, no-follow checked, and bidirectionally
disjoint from all registrations, repositories, stores, retained roots, and
superseded v3 roots before creation:

```text
/tmp/zllvm-inbox202e-local-state-snapshot-diagnosis-evidence
```

## 4. Frozen tools and commands

The only archive tools used were:

```text
tar_path=/usr/bin/tar
tar_version=tar (GNU tar) 1.35
tar_sha256=1effa935ebc606b859e3ab8ae0a3878be466c9b3690b665f6378479dd08571e9
zstd_path=/usr/bin/zstd
zstd_version=*** Zstandard CLI (64-bit) v1.5.5, by Yann Collet ***
zstd_sha256=7c5468b370f7c47eda07281e3437fafc568f95d10420051e3aa522709f9342c5
```

Each listing used this closed, pipeline-free shape:

```text
/usr/bin/env -i PATH=/usr/bin:/bin LC_ALL=C TZ=UTC \
  /usr/bin/tar --use-compress-program=/usr/bin/zstd \
  -tf <exact-manifest-snapshot>
```

Each finite member was independently streamed without extraction:

```text
/usr/bin/env -i PATH=/usr/bin:/bin LC_ALL=C TZ=UTC \
  /usr/bin/tar --use-compress-program=/usr/bin/zstd \
  -xf <exact-manifest-snapshot> --no-recursion \
  --to-command=/usr/bin/sha256sum -- <exact-manifest-member>
```

The harness created no extraction workspace and wrote no archive member to a
file. Both listing commands and all 16 finite member-stream commands returned
status `0`.

## 5. Stable assertion map

The retained map has 157 one-to-one assertion rows in original subject order:

1. snapshot-row selection, manifest order, and final count;
2. archive key, type, link, mode, bytes, SHA-256, and format;
3. finite member count and order;
4. listing command status and exact listing equality;
5. finite stream-command status and observed hash count;
6. constituent serialization hash and constituent-object identity; and
7. every member stream hash and destination key/type/link/mode/bytes/SHA-256.

Stable IDs are scoped by `S1` for `snapshot/calls-inputs/v1`, `S2` for
`snapshot/calls-validation-inputs/v1`, and `S3` for the final snapshot count.
Each member uses a stable `M01`…`M12` sub-identifier.

The complete map and expected/observed ledger are retained at:

```text
/tmp/zllvm-inbox202e-local-state-snapshot-diagnosis-evidence/assertion-map.tsv
/tmp/zllvm-inbox202e-local-state-snapshot-diagnosis-evidence/assertion-ledger.tsv
```

## 6. First false assertion and cascades

The calls-input snapshot produced the first false subject assertion:

```text
stable_id=S1-16-CONSTITUENT-HASH
snapshot=snapshot/calls-inputs/v1
expected=1d5aa3cc6a5aef1db6258861df4ed88cec917fd6e6e47a80ad728759c944b641
observed=99aa5a94013f85db7532c00339e5bdd39c747eec38483c2f521762f4a0d8b27c
command_status=0
cascade=no
```

The validation-input snapshot independently failed the same assertion:

```text
stable_id=S2-16-CONSTITUENT-HASH
snapshot=snapshot/calls-validation-inputs/v1
expected=e7e26c8785a9db007b7771da8a78b0dc1be9893b511b542e9a2ea6ffb892ce7a
observed=d6910107eae57ff32d040eaed26a6fe548efacfee44c0c8d8292389d52ab8915
command_status=0
cascade=no
```

The next assertion in each snapshot, `S1-17-CONSTITUENT-KEY` and
`S2-17-CONSTITUENT-KEY`, passed on its own values but is labeled cascading
because it depends on the failed serialization hash. No other assertion
failed. Thus:

```text
assertions_total=157
assertions_pass=155
assertions_fail=2
cascade_labels=2
first_false=S1-16-CONSTITUENT-HASH
```

## 7. Root cause and bounded prospective correction

The retained D driver initializes the reconstructed constituent bytes as:

```text
zllvm-snapshot-constituents-v1\n
```

It then appends member rows directly. The accepted constituent objects contain
an additional canonical column-header row:

```text
zllvm-snapshot-constituents-v1
key	sha256	bytes	mode
```

All member rows, orders, hashes, byte counts, and modes otherwise match. The
smallest prospective correction is therefore to include exactly:

```text
key\tsha256\tbytes\tmode\n
```

after the version line when initializing `constituent_text`. This prospective
correction was not implemented, retried, or tested in INBOX-202E.

## 8. Retained diagnosis records

The diagnosis root contains exactly 12 real regular files, all mode `0644`,
UID/GID `1000/1000`. Its LF-terminated
`sha256<TAB>bytes<TAB>mode<TAB>basename` ledger hashes to:

```text
diagnosis_record_count=12
diagnosis_record_ledger_sha256=dffdfc8eb29d68c45c1369692c2ef17a1c716efaf069b759751b86f985206c72
```

Individual identities:

```text
assertion-ledger.tsv=67e0c7442c1dc3b1c7e19772168164b71a4fcecab532e854208ab039bd787e9d
assertion-map.tsv=a9ab3c6c997c33fc95ff98b4a9f85705aa875a8838ebcc55894dc1b390e54a5c
diagnostic-summary.tsv=1e1f31f53a67f2fe245d372e355ddbcdf28378d92894efb8c68512aecd2a9f3a
driver.command=a2ec60e609bd4970e3b50625653c8dc965cbb3968f334f745aaf8e9f9c2d5be5
driver.environment=1e07b83f8530c985e5009b4f8991e33d9db5cf2623a46325a1bf7cd55bcb175b
driver.status=9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
driver.stderr=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
driver.stdout=74f9461f774674486e7623f6e341dcf8a1fb4f6cf4743c7c975afb2f0d8a431a
hashes-calls-inputs.tsv=04fa0d51abd5daee050829240f4a5bb1a5d23665ec7106d9e7bd36f2031c47e4
hashes-validation-inputs.tsv=d46a1ae3eb0c58e585e07e50227bfda45e4241ade919fc00d4ef3b87d61ac4c2
listing-calls-inputs.tsv=8434da04b1ceea82d634d128f7c41a9cf12c0d986af57b9c2030bc0cff870947
listing-validation-inputs.tsv=c40f9510242b5ea0636e6a79fe35de6889b702791f99d90294e5a21424bd4710
```

## 9. Final boundary

```text
diagnostic_harness_status=0
transaction_reruns=0
ratchet_recount_reruns=0
payload_publications=0
destination_mutations=0
authority_transition=none
source_authority=/home/oleg/prog/z_llvm-artifacts
ratchet=131
next=STOP_FOR_WATCHER_REVIEWER_DIAGNOSIS_REVIEW
```

