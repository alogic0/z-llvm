# INBOX-205 dormant private authority reader/validator

Status: INBOX-205D guard-only completion passed. The dormant implementation,
accepted `9/9` focused suite, and corrected source guard are complete.

## Retained attempt provenance

The original INBOX-205 final suite ran exactly once and failed status `1`
with `7/9` tests passing. Its retained stderr SHA-256 is
`3066ad9b617cfb6c79e123fa846c5dbf0b94e544265c3dc229292a4d5d6ca0dc`.
The first failure was the strict test-private replacement helper returning
`FileNotFound` after an explicit negative had already removed a fixture. The
second was the established artifact-store test correctly requiring
`ZLLVM_ARTIFACT_STORE`, which the original invocation omitted. The source
guard was not run.

The complete failed fixture root
`/tmp/zllvm-inbox205-authority-dormant-synthetic` and every original record
under `tmp/inbox205_o2_authority_dormant/validation/` remain immutable. They
were not reused by any continuation.

INBOX-205A ran its focused suite exactly once. It passed the dormant
validator, including all five receipt-binding negatives, but finished status
`1` with `8/9` tests because the retained-boundary fixture still required the
now-accepted real store to be absent. Its complete 848-file records/cache
tree remains immutable at inventory SHA-256
`9415fb8f370e9937d8ad44aefb39da1dbc34b8c850bb5c96a35ca2e4bf9955fb`
and file-ledger SHA-256
`24e4ce7f3a35727a2734333d2e7bf415629ca99ae03c97ae909b0ee01a7d0ec6`.
Its stderr SHA-256 is
`361201ac0c9eca6d4ae810991d0a7976a9095d27b891f08277704727e9a1610b`.

INBOX-205B changed only the test-private retained-boundary assertion to
no-follow `statFile` of the exact real-store root as a directory of mode
`0775`, and moved the dormant fixture identity to its fresh B root. Format
and compile-only passed. The sole focused suite passed status `0`, `3/3`
build steps and `9/9` tests; stderr SHA-256 is
`40ae720630910be4865c9adae4dcd6dd7b3354953d3943724e2f9e504d87580f`.
The first strengthened guard then failed status `1` with empty stdout and
stderr because a line-oriented filter could not associate a permitted
multiline `openDirAbsolute` argument with its call.

INBOX-205C replaced that filter with one exact brace-balanced extraction of
`assertRetainedMaterializeBoundaries`. Its sole guard reached the ratchet
recount, then failed status `2`: the AWK program used reserved built-in name
`index` as its loop variable. Its five syntax diagnostics have stderr
SHA-256
`c07748fd61c2e3c439414dc1990ce85b7df659c7323a6f093eeebb9aa8315a5c`.
The complete 19-file C record tree remains immutable at inventory SHA-256
`d602312d3417da6500decad1e6b97489d36b2e94d5919e925eacb1dee3d4e50a`
and ledger SHA-256
`5f21a89bba26e1901e1e335bdc637007670ee6c7e3c524f0f39ab4a7ac53a4cb`.

INBOX-205D changed exactly the four ratchet-loop uses from `index` to
`site_index`, plus the mechanical D namespace/current-operating-identity
bindings and the mandated C preservation checks. The corrected guard ran
exactly once and passed status `0`. Its command SHA-256 is
`1c9b9ba05a0364fdca62952aa43d4433b76bf57af5483764d7eefd5924fe1dcb`;
stdout SHA-256 is
`1664bbed16a34b16e99386ef6665751d735f2c72273a42be48c27b78226d1e95`;
stderr is empty; and the final ratchet record is exactly
`direct_occurrence_recount=131`.

## Frozen authorization boundary

- Main operating baseline:
  `036269cf3b67096fcff67658a853c8476ee832ad`
- Accepted inert control commit:
  `9c55bda34088e1230b0b91a126d35795a3ac70b4`
- Accepted inert control tree:
  `756369ad4a89d806f463bd8094c5159d8c973d7e`
- Ratchet: `131`, unchanged

The exact four real control files were inspected read-only and no control
root traversal was performed:

| Relative path | Bytes | Mode | SHA-256 |
|---|---:|---:|---|
| `authority/zllvm/v1/manifests/generation-00000001.tsv` | 27,823 | 0644 | `61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d` |
| `authority/zllvm/v1/lineage/generation-00000001.tsv` | 378 | 0644 | `f8b22b687f3d3cb727ba82e92c3a346c7025958387f3a45d4143fb42936c6a3a` |
| `authority/zllvm/v1/receipts/publication/generation-00000001-payload-copy.tsv` | 792 | 0644 | `9c6748234292c963c9716504a1451c4da0cdb0fe2ce1642d1c5fa83264aa19a3` |
| `authority/zllvm/v1/manifests/candidate.tsv` | 899 | 0644 | `7c0aa46fb6c0cb2b93034bbb6b520b6d4831fedea333983002622197a74c832b` |

The source store remains authoritative. The destination remains
non-authoritative and the candidate remains inert.

## Actual implementation scope

Changed:

- `tools/zllvm_artifact_store.zig`
- `docs/zllvm_artifact_retention_contract.md`
- this evidence file

Unchanged and therefore omitted:

- `build.zig` — the existing `artifact-store-test` registration exercises the
  private test path.
- `docs/evidence/zllvm_artifact_manifest_v1.tsv` — synthetic in-memory
  fixtures eliminate the optional mirror.

The implementation adds a private owned configuration, closed owned
single-row parsers, existing v1 manifest parsing/re-encoding, exact
referential checks, registered-worktree identity revalidation, no-follow
root/control/payload inspection, and closed destination reconciliation.
There is no public symbol, production caller, CLI verb, environment variable,
selector, or authority fallback.

## Synthetic proof matrix

The accepted focused test uses only
`/tmp/zllvm-inbox205b-authority-dormant-synthetic/{control,payload,source}`.
The dormant validator is never invoked with the real control repository,
source store, or local-state payload store.

| Boundary | Proof |
|---|---|
| positive | canonical owned parse/re-encode, reference closure, exact tree, identities, modes, counts |
| candidate | missing, malformed, semantic mismatch, symlink unsafe |
| generation | missing, hash mismatch, hash-matched malformed manifest, symlink unsafe |
| lineage | missing, hash mismatch, hash-matched malformed row, symlink unsafe |
| receipt | missing, hash mismatch, hash-matched malformed row, symlink unsafe |
| receipt owned identities | isolated mismatches for source inventory, source file ledger, source/destination ledger, copy-evidence path, and copy-evidence SHA-256 |
| replacement helper | replacement after an explicit delete tolerates only `FileNotFound`; explicit deletes remain strict |
| registration | frozen path identity mutation produces `DormantRegistrationStale` |
| destination | missing object, changed bytes, undeclared file, symlink object |
| completion | a second complete positive validation, then exact synthetic-root removal |

Every negative is asserted by its stable first-attributed error. Each
temporary mutation is restored before the following case. Unexpected failure
retains the synthetic root.

## Frozen Zig identity and exact gate commands

- Zig executable:
  `/home/oleg/.zig/0.16.0/files/zig`
- Executable SHA-256:
  `2317bbb91798556d9d0f38aabdac23db83f0979b25f767259ae474546724087c`
- Version: `0.16.0`
- Library:
  `/home/oleg/.zig/0.16.0/files/lib`
- Standard library:
  `/home/oleg/.zig/0.16.0/files/lib/std`
- Isolated global cache:
  `/home/oleg/prog/z_llvm/tmp/inbox205b_o2_authority_dormant/validation/cache/global`
- Isolated local cache:
  `/home/oleg/prog/z_llvm/tmp/inbox205b_o2_authority_dormant/validation/cache/local`
- Target:
  `x86_64-linux.6.17...6.17-gnu.2.39`

Exact commands:

```text
env -i HOME=/home/oleg PATH=/home/oleg/bin:/usr/local/bin:/usr/bin:/bin LC_ALL=C.UTF-8 NO_COLOR=1 /home/oleg/bin/zig fmt tools/zllvm_artifact_store.zig
env -i HOME=/home/oleg PATH=/home/oleg/bin:/usr/local/bin:/usr/bin:/bin LC_ALL=C.UTF-8 NO_COLOR=1 ZIG_GLOBAL_CACHE_DIR=/home/oleg/prog/z_llvm/tmp/inbox205b_o2_authority_dormant/validation/cache/global ZIG_LOCAL_CACHE_DIR=/home/oleg/prog/z_llvm/tmp/inbox205b_o2_authority_dormant/validation/cache/local /home/oleg/bin/zig test tools/zllvm_artifact_store.zig -fno-emit-bin
env -i HOME=/home/oleg PATH=/home/oleg/bin:/usr/local/bin:/usr/bin:/bin LC_ALL=C.UTF-8 NO_COLOR=1 ZIG_GLOBAL_CACHE_DIR=/home/oleg/prog/z_llvm/tmp/inbox205b_o2_authority_dormant/validation/cache/global ZIG_LOCAL_CACHE_DIR=/home/oleg/prog/z_llvm/tmp/inbox205b_o2_authority_dormant/validation/cache/local ZLLVM_ARTIFACT_STORE=/home/oleg/prog/z_llvm-inbox194d-artifact-store-synthetic /home/oleg/bin/zig build artifact-store-test --summary all
env -i HOME=/home/oleg PATH=/usr/local/bin:/usr/bin:/bin LC_ALL=C.UTF-8 /bin/bash tmp/inbox205d_o2_authority_dormant/validation/source_guard.command
```

## Retained gate records

| Gate | Result | Retained stdout SHA-256 | Retained stderr SHA-256 | Status-file SHA-256 |
|---|---|---|---|---|
| format (B) | pass, status 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | `9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa` |
| compile-only (B) | pass, status 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | `9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa` |
| focused suite (B) | pass, 3/3 and 9/9, status 0 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | `40ae720630910be4865c9adae4dcd6dd7b3354953d3943724e2f9e504d87580f` | `9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa` |
| corrected source guard (D) | pass, status 0 | `1664bbed16a34b16e99386ef6665751d735f2c72273a42be48c27b78226d1e95` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | `9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa` |

## Frozen-state postflight

The accepted guard independently proved:

- tool `306b3b21c182ae5031d71d82a38744c05161f0519ea80ff2cc20784e21a21f15`;
- build `a0c923499cd4515326fb287d729c53ae6d68bb465a4b4a033a737a19466ce466`;
- production `main` / `resolveAuthority` / public surface
  `2c4697e9…` / `86600533…` / `02bb7f87…`;
- raw and normalized retained-boundary function
  `53bd7f4b…` / `a47e16b6…`;
- exactly three test-only `default_store` references and lstat-only
  directory/mode-`0775` handling;
- dormant validator, fixture helpers, replacement/mismatch helper, and all
  five receipt bindings private and production-unreachable;
- exact INBOX-205/205A/205B/205C provenance, all 43 registrations, watcher,
  stash, control, optional-mirror absence, fresh-root absence, and ratchet
  `131`.

The two retained test-only failure diagnostics still say `INBOX-205A`.
They are documentation-label debt only; changing them was deliberately
outside this guard-only slice.

The source store remains authoritative, the destination remains
non-authoritative, and the control candidate remains inert. No real
candidate validation, activation, compatibility, v3 execution, compiler
gate, performance run, cleanup, ratchet movement, or credit occurred.
