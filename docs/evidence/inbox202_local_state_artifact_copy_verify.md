# INBOX-202 Local-State Artifact Copy and Verification

## 1. Final disposition

INBOX-202I completed the bounded non-destructive copy-and-verify sequence
from operating-document commit
`1fde36076d42f9cdbf509366c7dc4f9fc56c5562`, whose parent is
`a3de1a9013cf2884fcf0022333c7c9827c47c6d5`.

The final accepted state is:

```text
source_authority=/home/oleg/prog/z_llvm-artifacts
destination=/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1
destination_authority=non-authoritative
copied_payload_files=20
copied_payload_bytes=9970364
objects=18
snapshots=2
snapshot_members=16
canonical_evidence_roles=25
canonical_evidence_split=22F+3G
ratchet=131
authority_transition=none
```

No verifier, archive stream, payload transaction/publication driver, or
ratchet recount was rerun during INBOX-202G/H/I. No project or Zig command
was run. No source, destination, retained root, control repository,
manifest, tool, contract, pin, registered worktree, or protected local
configuration path was modified.

## 2. Attempt history

The sequence remained fail-closed throughout:

1. INBOX-202/202A established the finite copy contract and retained the
   original pre-payload failure evidence.
2. INBOX-202B/202C corrected preflight-only defects without spending the
   payload transaction. The retained B root contains the accepted four
   prelaunch records.
3. INBOX-202D made the sole 20-file transaction attempt. All 20 rows were
   published and recorded as pass, but the driver stopped before completing
   snapshot verification because its reconstructed constituent bytes omitted
   the canonical column header.
4. INBOX-202E diagnosed that exact omission without retrying the transaction.
   Its status-zero harness evaluated 157 independently named assertions:
   155 passed and only the two constituent-hash assertions were false.
5. INBOX-202F added only the accepted canonical header to the verifier-only
   reconstruction. Its sole read-only verifier attempt passed all payload,
   snapshot, member, constituent, relationship, inventory, registration, and
   frozen-identity checks. The postflight then stopped because its three
   launcher-created result files inherited mode `0664`.
6. INBOX-202G stopped during read-only preflight because it expected eight
   lines in `verification-summary.tsv`; the accepted file has nine lines
   (one header and eight facts). G remained absent.
7. INBOX-202H corrected only that count, then stopped before `mkdir` because
   sanitized Git status intentionally lacked the normal global ignore
   environment. G again remained absent.
8. INBOX-202I changed only the sanitized clean predicate to tracked-only
   status, repeated every named preflight, copied the three launcher results
   into fresh G with mode `0644`, and closed the 25-role canonical record
   set.

No failed phase was retried in place, and no retained evidence root was
repaired, normalized, or cleaned.

## 3. Frozen source and destination

The authoritative generation manifest remains byte-equal to the tracked
manifest:

```text
manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
source_inventory_sha256=3234fb508d370878efe082cf1accb5af3b488372bf3f1ee7e9e87408a37a2d7c
source_file_ledger_sha256=a06c48e1549d16b9f924cc2b5f0404e60d7755a785bf3a4a23311c2383279a65
source_files=21
```

The finite current source/destination ledger remained byte-identical before
and after verification and mode remediation:

```text
source_destination_ledger_sha256=4c29709b9ef9242dd799ab52d346cdf302f5728d35e37e0d78063e892a6cf9e8
payload_rows=20
payload_bytes=9970364
destination_files=20
destination_objects=18
destination_snapshots=2
destination_modes=0444
destination_uid_gid=1000/1000
destination_link_count=1
incoming_entries=0
destination_manifest=absent
```

The destination remains a verified non-authoritative copy. No compatibility
path or authority switch was created.

## 4. Retained roots and decisive identities

The retained roots are:

```text
A=/tmp/zllvm-inbox202-local-state-copy-verify-evidence
B=/tmp/zllvm-inbox202b-local-state-copy-verify-evidence
D=/tmp/zllvm-inbox202d-local-state-copy-verify-evidence
E=/tmp/zllvm-inbox202e-local-state-snapshot-diagnosis-evidence
F=/tmp/zllvm-inbox202f-local-state-copy-verification-evidence
G=/tmp/zllvm-inbox202g-local-state-record-mode-remediation-evidence
```

Important retained identities:

```text
D_driver_sha256=ccd1c83ae3d9549e8132c1e73102932e041931ed4b56ff9e4a03299ded4b678c
D_transaction_ledger_sha256=8021f2c732e52ffd899a51b71338f4ea5902114f2a5520818f983ecc82cf19d5
E_record_count=12
E_record_ledger_sha256=dffdfc8eb29d68c45c1369692c2ef17a1c716efaf069b759751b86f985206c72
F_record_count=25
F_record_ledger_sha256=5d9379b36e8e07feac19ed12c57e1b42d6737457b1ab99625c87c2b8392b1b11
F_inode_hash_mode_ledger_sha256=96786fc3714742642b5c5459e5458f9eb7b8ac1b0dae0d4bfbc4900cd68439a2
G_record_count=7
G_record_ledger_sha256=7283799412a64e42e7c99e62e485e261601211cba5172825be0588bd8374d9c6
```

F remains immutable evidence of the original launcher-mode defect: 22 files
are mode `0644`, while exactly these three files are mode `0664`:

```text
driver.stdout bytes=102 sha256=4ccf392da3c6d206a50a6cd3ef0a531819104136e4281e5be2cede33888f3fef
driver.stderr bytes=0 sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
driver.status bytes=2 sha256=9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa
```

The F verifier result was:

```text
status=0
stderr=empty
stdout=verification=pass files=20 bytes=9970364 snapshots=2 members=16 authority_transition=none ratchet=131
source_destination_lines=21
snapshot_member_lines=17
final_inventory_lines=46
verification_summary_lines=9
```

The corrected constituent serializations matched both authoritative source
objects and destination objects exactly:

```text
snapshot/calls-inputs/v1
  members=4
  bytes=678
  sha256=1d5aa3cc6a5aef1db6258861df4ed88cec917fd6e6e47a80ad728759c944b641

snapshot/calls-validation-inputs/v1
  members=12
  bytes=1912
  sha256=e7e26c8785a9db007b7771da8a78b0dc1be9893b511b542e9a2ea6ffb892ce7a
```

The retained-D and F snapshot blocks are byte-equal after normalizing the
single constituent initialization line. Their sole raw semantic difference
is insertion of:

```text
key<TAB>sha256<TAB>bytes<TAB>mode<LF>
```

after the canonical version line.

## 5. INBOX-202I clean predicate boundary

Before the sanitized shell, normal:

```text
git status --porcelain=v1 --untracked-files=all
```

was empty. Inside the closed shell, the sole corrected check was:

```text
git status --porcelain=v1 --untracked-files=no
```

and it was empty. The shell received no `HOME`, XDG configuration, or global
Git configuration.

The only recorded explanation is that the pre-existing local setting is
excluded in the normal environment by the normal default global Git ignore.
The protected literal paths are:

```text
.claude/
.claude/settings.local.json
/home/oleg/.config/git/ignore
```

They were not read, copied, hashed, statted, traversed, normalized, staged,
edited, removed, or otherwise modified, and remain outside artifact and
evidence scope.

## 6. Exact three-copy remediation

The accepted GNU `dd` identity remained:

```text
path=/usr/bin/dd
sha256=dd07a1b0f236f221f71fac70103765286d1ccf29b747cbb24345d0c57a0311b6
help_sha256=803ccdec96d19e3721989e1a31497684d7188cf9c6ed9b4587bd006a9a4c3457
version=dd (coreutils) 9.4
```

Under a closed environment and `umask 0022`, each of the three named files
was copied exactly once with:

```text
/usr/bin/dd \
  if="$source" \
  of="$destination" \
  bs=1048576 \
  iflag=fullblock,nofollow \
  oflag=nofollow \
  conv=excl,fsync \
  status=none
```

Each destination was absent before its copy and became a real no-follow
regular file, mode `0644`, UID/GID `1000/1000`, with exact byte and SHA-256
equality to its F source. All three statuses were `0`.

## 7. Exact seven-file G root

G contains only:

```text
canonical-record-set.tsv
driver.status
driver.stderr
driver.stdout
f-record-ledger.tsv
mode-remediation.tsv
postflight-summary.tsv
```

All seven are real regular files, mode `0644`, UID/GID `1000/1000`:

```text
canonical-record-set.tsv
  bytes=5421
  sha256=b9bb4642b064526784383f54fd881ba2f17cb19a29137ca4b9da1c746c621d95

driver.status
  bytes=2
  sha256=9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa

driver.stderr
  bytes=0
  sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855

driver.stdout
  bytes=102
  sha256=4ccf392da3c6d206a50a6cd3ef0a531819104136e4281e5be2cede33888f3fef

f-record-ledger.tsv
  bytes=2433
  sha256=f7d26b62b0697c2f92b67d126e31fdddff4287137e3bc8116036272d1ba30b60

mode-remediation.tsv
  bytes=13312
  sha256=d668a48710754a539ae6ecc638577219b42c9869ab904de9160ffc18d49331d0

postflight-summary.tsv
  bytes=462
  sha256=b6852779b28980f26decd9fba0586b8e33a2373470e6b83806b58b02412e3336
```

`mode-remediation.tsv` has 91 lines and carries the finite named preflight,
scope, transaction-command/environment/status, copy-identity, and postflight
assertions. `canonical-record-set.tsv` has one header plus 25 unique roles.
`postflight-summary.tsv` has one header plus eight final facts.

## 8. Split-root canonical record set

The canonical set is exactly:

```text
F_original_mode_0644_roles=22
G_mode_corrected_roles=3
canonical_roles=25
duplicate_roles=0
missing_roles=0
non_regular_roles=0
non_0644_roles=0
wrong_owner_roles=0
identity_mismatches=0
```

The G copies resolve the three launcher-result roles. Every other role
resolves to its original immutable F record. Each role resolves exactly once
with an exact path, root, regular type, UID/GID, mode, byte count, and
SHA-256.

## 9. Frozen repository boundary

The following remained exact:

```text
control_head=a41690a4c47cf1040afe3d4dd3679a77015263ea
control_tree=67582eb6f4de0b3ab3a2ef2e7c3635c79349d00e
control_remote=none
worktrees=43+1
worktree_path_hash=f31d8542baafc7b64cd5ee6fe8cc4194842ca696b97a7ffc8df06ce12d553d7e
worktree_topology_hash=6c868e3b6d436cfba92a1e2b21dbd616391763961f1cba9b6670b1ed4a6ebb62
non_main_registration_hash=ebc30a376b3db4c6fbf788f49ea85f4ce792471e539c0a89308068efdf96ebbe
watcher_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
stash=7985c6d01040a6e47e4ce5b918866d0e89517ac7
tool_sha256=94dfc1fc27ffe1268eb02453bcac1a3634aa11af38d0c94fbaa3b43decd25859
bypass_tsv_sha256=2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11
pins_sha256=1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3
audit_sha256=5a7e019eb107e5b66947490a65fdf47444154fc4f1483ca30ab0fc6e381f33e6
contract_sha256=d445f6a45f039415052cb0fb1efc71b1975f2ea68d28e3637aede503145fc387
superseded_v3_roots=absent
ratchet=131
```

All registered worktrees remain protected. No authority transition,
compatibility write, validation, wiring, performance, cleanup, ratchet
movement, or credit occurred.

## 10. Stop

```text
result=pass
source_authority=/home/oleg/prog/z_llvm-artifacts
destination_authority=non-authoritative
authority_transition=none
ratchet=131
next=STOP_FOR_WATCHER_REVIEWER_REVIEW
```
