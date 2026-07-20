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

## INBOX-206D through INBOX-206G four-role remediation

Status: complete. The private dormant authority validator now implements the
accepted four-role design from INBOX-206C. The retained synthetic suite
passed `9/9`; the final INBOX-206G structural guard passed status `0`.
The candidate remains inert, the old source remains authoritative, and no
real candidate validation occurred.

### Closed role and observation model

The validator admits roles in the fixed order `control -> authority ->
payload -> source`:

| Role | Exact real path | Required mode | Closed relationship |
|---|---|---:|---|
| control | `/home/oleg/prog/z_llvm/local-state/control` | `0775` | exact supplemental Git repository and four-key pre-open allowlist |
| authority | `/home/oleg/prog/z_llvm/local-state/control/authority/zllvm/v1` | `0755` | narrow intentional containment in control and main |
| payload | `/home/oleg/prog/z_llvm/local-state/artifacts/zllvm-authority-v1` | `0755` | narrow main-contained payload; disjoint from supplemental control and non-main registrations |
| source | `/home/oleg/prog/z_llvm-artifacts` | `0775` | external identity-only source, disjoint from main, supplemental control, and every other role |

The exact-real policy owns the paths, modes, relations, registration
snapshot, four control-file identities, and expected control Git
observation. Acquisition and validation are separate. Acquisition uses only
frozen `/usr/bin/git` under a closed environment with exact `-C` control-root
arguments and bounded output/status for:

- `rev-parse --verify HEAD`
- `rev-parse --verify HEAD^{tree}`
- `symbolic-ref --short HEAD`
- `status --porcelain=v1 --untracked-files=all`
- `remote`
- `ls-tree -rz --full-tree HEAD -- authority/zllvm/v1`

Validation requires commit
`9c55bda34088e1230b0b91a126d35795a3ac70b4`, tree
`756369ad4a89d806f463bd8094c5159d8c973d7e`, branch `main`, empty status and
remotes, and exactly the four tracked `100644 blob` entries before any
control-file open. Each open is then bound to its allowlisted component and
exact hash, bytes, and mode. There is no directory-derived key, fallback,
write, chmod, repair, or normalization.

The synthetic policy is allocator-owned and `builtin.is_test`-closed. It
injects owned observations into the same validation logic and rejects all
real role paths. Its accepted negative matrix covers role swaps and escapes,
each role-mode mismatch, symlinked ancestry, an unlisted fifth control key,
non-main and supplemental-control intersections, and independent
commit/tree/branch/status/remotes/tree-entry drift. The generic
`RegistrationGuard`, payload verification, production entrypoints, public
surface, CLI/environment, selector, build registration, statement order,
and production call graph remain unchanged.

### Executed gates and retained records

No D/E/F/G command was retried. INBOX-206D completed format, compile-only,
and the focused synthetic suite before its structural guard. The exact gate
record identities are:

| Gate | Command SHA-256 | Environment SHA-256 | stdout SHA-256 | stderr SHA-256 | Result |
|---|---|---|---|---|---|
| D format | `5847d2ba231f2108187b313edd95a6e7b38bd97cea9c1c51884e366f0a6ea38b` | `a4bc38f17c97e91d04330f8e6a74a8febec081cb977e029eb3b807c9b3f35f7e` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | status `0` |
| D compile-only | `bc31e53d3d4f1bd672e0d37699e1755275bacc5ccc43d350721c2f8fa4e1670e` | `24c270d80f832d523d158892df872f021f7aa83eb18463d9fdaaa8b0d699917f` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | status `0` |
| D focused suite | `2dad169fc0bf6f061d83471c0045a029d8afee7e38c488e64be7fc0ad8ce3b5a` | `d97651288416a4b2979f4ea4e65b572d66d53c77cbeb7e61a69f43a71544fa1f` | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | `d8363bd8494e448903defaaaa817c866e554ada09b0397c75dfe8d94cc382811` | status `0`, `9/9` |

The structural-guard continuation ledger is:

| Attempt | Authorized correction | Command SHA-256 | Frozen diff SHA-256 | stdout SHA-256 | stderr SHA-256 | Result |
|---|---|---|---|---|---|---|
| D | initial complete four-role guard | `c7af50b100ed05c3c8f3e1b2f50facaff167c23cc71aa9d89c2140f83624b9d8` | n/a | empty | empty | status `1` |
| E | three reviewed false-expectation corrections | `a94c5bb32ebc11ccbfc1d09de6694acf5515dc208fab687869bbf84211d363c2` | `43d6f5b9d85249438e699201c3054babc2fda798181fe2e72c411f92684a1271` | empty | empty | status `1` |
| F | exact-line `rg -xF` match for `dormant_git_executable` | `80e367d39fb5d4ec1468a278fc2b8386c8c3bda17add67f51c5f403b8b2d0107` | `173beb614f61e8b7249cd800b954a4ee44d3f766e285f49853f845e751e737c7` | empty | `e4537dc3fa0b0442e943589bdc93e180575687444c31c25859e2587414e0dc3c` | status `1`, AWK delimiter syntax |
| G | remove only the erroneous backslashes from the two multiline AWK string delimiters | `42308badefdadd7f5bc4d8c3ca049efe26803e92836f7b5bba6e3cfdb5c1537d` | `e70c02290052678262caad6191dbf33f9f3896a9ea611eba3860f732c7b92682` | `dc90330bbb644222f69b29e3c77b7788f71854f0f78aea2d95ffd43d8f62de04` | empty | status `0` |

All successful status files have SHA-256
`9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa`;
the empty-file SHA-256 is
`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.
The G environment is
`HOME=/home/oleg`, `PATH=/usr/local/bin:/usr/bin:/bin`, and
`LC_ALL=C.UTF-8`; its retained environment record SHA-256 is
`12c8e9d8439a95606ce22abf876b4ca4d3e692d54b3b17842e74dfa5bc8ee5b9`.
Its exact invocation is:

```text
env -i HOME=/home/oleg PATH=/usr/local/bin:/usr/bin:/bin LC_ALL=C.UTF-8 /bin/bash /tmp/zllvm-inbox206d-root-role-remediation-validation/continuations/inbox206g/source_guard.command
```

The G guard independently reported:

```text
retained_206a_206b=exact
registered_worktrees_control_stash_watcher_pins=exact
generic_registration_guard=unchanged
production_main_resolver_public_build=unchanged
payload_verification_and_driver_order=unchanged
private_role_order=control-authority-payload-source
role_paths_modes_allowlist=closed
control_git_acquisition=bounded-owned-closed
synthetic_observation=owned-test-only-real-path-rejected
negative_matrix=closed
contract_change=uniform-paragraph-only
ratchet=131
source_guard=pass
```

The retained implementation and contract SHA-256 values at the successful
guard are respectively
`073bdddeeac4a0b99e39cd54e5b2ea7db403796d25416dcf5ac578ea7ff5ad14`
and
`eb112e86d0ea43dfae6fde3974fd77294eae7ee8c68b4cf0b4c293b80f4f4cc6`.
Ratchet `131` is unchanged. No earlier guard, Zig gate, formatter, compile,
test, validator, state guard, project command, or real-candidate validation
was rerun in E, F, or G.

### Terminal boundary

This slice does not validate the real candidate and does not create a
validation receipt. The candidate remains inert and the old source remains
authoritative. Activation, compatibility, v3, compiler work, performance,
cleanup, ratchet movement, and credit remain outside authority.
