# INBOX-198 v3 Operational Root and Private Test-Seam Design

## 1. Scope, accepted basis, and disposition

This documentation-only reconciliation starts from exact operating commit
`d0b777bcdaa452c621624d132fdb585b301dd81e`, parent
`6ee7bda862ed1f43fcdb96f7d23b99870cd790e7`. It creates no path and
implements or executes nothing.

INBOX-197 is accepted as a compliant evidence/design stop. Its four
capability boundaries, eight machine schemas, closed error behavior,
zero-write resolver/verifier requirement, finite nonrecursive evidence DAG,
generation-v2 lineage blocker, frozen-function reuse map, negative-proof
inventory, and implementation order remain frozen.

Final design acceptance was withheld for two real contradictions:

1. the repository-local future-v3 root put artifact inputs, outputs,
   publisher sources, and compatibility targets beneath the registered main
   worktree, despite the absolute worktree artifact-treatment exclusion; and
2. the production CLI was fixed to the real authority while synthetic proofs
   had no private way to supply a disjoint synthetic authority and
   registration fixture through the same command implementation.

This design reconciles those contradictions with:

- one exact absent sibling operational root outside every current registered
  worktree and outside the real artifact authority;
- two exact separately protected future source-worktree children;
- exact-path role checks rather than rejecting the operational root merely
  because it contains protected children;
- a narrow, no-follow, read-only allowlist for named tracked control files in
  the main worktree; and
- one private `AuthorityConfig` plus one shared internal command driver, with
  compile-time-separated production and synthetic configuration acquisition.

The frozen identities are:

```text
accepted_INBOX_197_commit=6ee7bda862ed1f43fcdb96f7d23b99870cd790e7
INBOX_197_design_sha256=3717cc34f8e3d6c6841b679c1c2e70354d6a7cdef7d6f5e7ce9e48431b9a9bac
accepted_contract_sha256=d445f6a45f039415052cb0fb1efc71b1975f2ea68d28e3637aede503145fc387
tracked_live_manifest_sha256=61b7426bd52a3a139999f17f36d91ecaab954e6132fe36eca541480cdf31104d
artifact_tool_sha256=94dfc1fc27ffe1268eb02453bcac1a3634aa11af38d0c94fbaa3b43decd25859
real_store=/home/oleg/prog/z_llvm-artifacts
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

## 2. Exact operational-root derivation and proof

### 2.1 Deterministic derivation

The production derivation is:

```text
main_git_common_dir=/home/oleg/prog/z_llvm/.git
main_repository_root=dirname(main_git_common_dir)=/home/oleg/prog/z_llvm
repository_parent=dirname(main_repository_root)=/home/oleg/prog
repository_basename=basename(main_repository_root)=z_llvm
operational_leaf=repository_basename + "-baseline-validation-v3"
operational_root=/home/oleg/prog/z_llvm-baseline-validation-v3
```

No environment variable, argv, current directory, fallback name, numeric
suffix, or alternate root may change this result. A later production
configuration must recompute it from the exact normalized Git common
directory and require byte equality with the frozen absolute path.

The old path remains:

```text
old_repository_local_root=/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3
old_repository_local_root_state=absent_and_unauthorized
```

It is never a fallback, compatibility root, migration source, cleanup target,
or accepted alias.

### 2.2 Read-only path and registration proof

Narrow exact-path checks observed:

```text
operational_root=/home/oleg/prog/z_llvm-baseline-validation-v3
operational_root_normalized_absolute=true
operational_root_state=absent
old_repository_local_root_state=absent
registration_count=43
operational_root_registration_bidirectional_conflicts=0
real_store_registration_bidirectional_conflicts=0
operational_root_real_store_bidirectional_conflict=0
```

Only Git registration metadata was read. No registered worktree directory was
entered, statted, traversed, or hashed. The accepted path/topology/non-main
hashes were not recomputed and remain the frozen authority.

The operational root is execution workspace only. It is not a store, object,
snapshot, manifest, logical reference, compatibility authority, registered
worktree, or artifact authority. Its absence is required until a separate
path-specific directive authorizes creation.

## 3. Exact path vocabulary

The following variables are exact aliases only:

```text
OP=/home/oleg/prog/z_llvm-baseline-validation-v3
BOOTSTRAP=/home/oleg/prog/z_llvm-baseline-validation-v3/bootstrap
CANONICAL=/home/oleg/prog/z_llvm-baseline-validation-v3/canonical
COVERAGE=/home/oleg/prog/z_llvm-baseline-validation-v3/coverage
COMPAT=/home/oleg/prog/z_llvm-baseline-validation-v3/compatibility
DURABILITY=/home/oleg/prog/z_llvm-baseline-validation-v3/durability
```

Every later executable v3 path must be below one of these exact children.
There is no inherited `$PARENT`. External preflight and driver records move
inside `$BOOTSTRAP`; no v3 execution record remains in the main worktree.

The exact future protected Git control paths are:

```text
/home/oleg/prog/z_llvm-baseline-validation-v3/canonical/source
/home/oleg/prog/z_llvm-baseline-validation-v3/coverage/source
```

Their creation requires separate explicit user authorization naming each
path. Once registered, each complete tree is excluded from artifact
treatment, hashing, publication, resolution, compatibility materialization,
migration, cleanup, and retirement. Every later modification or removal
requires another explicit user authorization naming the exact path.

All build outputs, records, manifests, comparisons, compatibility targets,
and publisher sources are exact sibling paths outside those two subtrees.
Opening a known parent directory no-follow is not permission to enumerate it.

## 4. Exact-path role model

The future private guard has these closed roles:

| Role | Admitted location | Access | Registration rule |
|---|---|---|---|
| `artifact_authority` | exactly `/home/oleg/prog/z_llvm-artifacts` in production | no-follow store read or separately authorized store mutation | root must be bidirectionally disjoint from all registrations |
| `operational_root_bootstrap` | exactly `$OP`, only while absent and before source registration | one separately authorized atomic root creation | exact root must be disjoint from all current registrations and store |
| `operational_target` | exact named path below `$OP`, outside both source subtrees | producer/record/build/compatibility access granted by later directive | **target itself**, not `$OP`, must be bidirectionally disjoint from every registration |
| `publisher_source` | exact finite regular file below `$OP`, outside source subtrees | no-follow read only after semantic closure | source itself must be disjoint from every registration |
| `tracked_control_read` | exact allowlisted regular tracked file in main worktree | no-follow read only | narrow main-registration exception; never artifact treatment |
| `protected_source_control` | exactly either source path above | Git control only | registered-worktree exclusion; no artifact operation |
| `synthetic_authority` | exact later-authorized test root | test-only store mutation | disjoint from production store, operational root, and all registrations |
| `synthetic_target` | exact test compatibility/output path | test-only finite mutation | same disjointness and no-follow rules |

An operational target may have a parent that also contains a protected source
sibling. The guard checks the exact final target/source against each
registration and validates each named ancestor no-follow; it does not apply
`assertStoreRoot` to `$OP`, `$CANONICAL`, or `$COVERAGE` as a whole and does
not enumerate siblings. Thus `$CANONICAL/artifact/z_llvm` remains admissible
after `$CANONICAL/source` is registered, while `$CANONICAL/source/**` remains
rejected.

Any exact target that equals, contains, or is contained by a registered path
fails closed. Symlink, non-directory ancestor, unsafe traversal, changed
registration, path normalization difference, missing path-specific authority,
or an unclassified role also fails closed.

## 5. Main-worktree tracked-control exception

The exception is read-only, exact, and finite. It grants no artifact-source
authority and no directory access. The production allowlist is:

```text
/home/oleg/prog/z_llvm/docs/evidence/artifact_manifest_v1.tsv
/home/oleg/prog/z_llvm/docs/evidence/inbox187_o2_compiler_rt_v1_baseline_validation_execution_contract.md
/home/oleg/prog/z_llvm/docs/evidence/inbox192_calls_artifact_durability_audit.md
/home/oleg/prog/z_llvm/docs/evidence/inbox197_v3_artifact_cli_surface_design.md
/home/oleg/prog/z_llvm/docs/evidence/inbox198_v3_operational_root_and_test_seam_design.md
/home/oleg/prog/z_llvm/docs/evidence/inbox194_calls_canonical_source_spec_v1.tsv
/home/oleg/prog/z_llvm/docs/evidence/tmp_retention_pins.tsv
/home/oleg/prog/z_llvm/tools/zllvm_artifact_store.zig
/home/oleg/prog/z_llvm/build.zig
/home/oleg/prog/z_llvm/docs/next_steps.md
```

Each read requires:

1. byte equality with one exact allowlist entry;
2. normalized absolute path equality;
3. no-follow regular-file open from an exact no-follow parent chain;
4. the expected mode/bytes/SHA-256 when frozen by the controlling directive;
5. registration equality before and after; and
6. immediate close after the bounded parse/hash/read.

The exception does not permit directory iteration, recursion, a relative
path, a caller extension, globbing, another main-worktree file, a publisher
source, compatibility destination, store object, snapshot member, migration,
cleanup, or path retirement. The tracked manifest remains control authority
only through the accepted tracked/generation byte-equality rule.

## 6. Accepted input compatibility targets

The 19 accepted logical references remain authority-resolved from the real
store. Their optional operational compatibility targets are finite and
non-authoritative:

| Logical ID | Exact compatibility target | Mode |
|---|---|---|
| `calls/input/accepted-cohort-ac285/v1` | `$COMPAT/inputs/calls/input/accepted-cohort-ac285/v1/payload` | `0664` |
| `calls/input/compiler-rt-v1/raw/adoption-final/v1` | `$COMPAT/inputs/calls/input/compiler-rt-v1/raw/adoption-final/v1/payload` | `0444` |
| `calls/input/compiler-rt-v1/raw/adoption-manifest/v1` | `$COMPAT/inputs/calls/input/compiler-rt-v1/raw/adoption-manifest/v1/payload` | `0444` |
| `calls/input/compiler-rt-v1/raw/module/v1` | `$COMPAT/inputs/calls/input/compiler-rt-v1/raw/module/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/baseline-source.sha256/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/manifests/baseline-source.sha256/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/bundle-files.sha256/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/manifests/bundle-files.sha256/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/bundled-source.sha256/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/manifests/bundled-source.sha256/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/combined-apply-source.sha256/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/manifests/combined-apply-source.sha256/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/future-tool-identities.sha256/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/manifests/future-tool-identities.sha256/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/patch-manifest.tsv/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/manifests/patch-manifest.tsv/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/payload-final-modes.tsv/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/manifests/payload-final-modes.tsv/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/preflight-and-apply-proof.txt/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/manifests/preflight-and-apply-proof.txt/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/restored-source.sha256/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/manifests/restored-source.sha256/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/sequential-apply-source.sha256/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/manifests/sequential-apply-source.sha256/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/manifests/touched-paths.txt/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/manifests/touched-paths.txt/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/patches/01-aggregate-consumer.patch/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/patches/01-aggregate-consumer.patch/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/patches/02-fixed-observer.patch/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/patches/02-fixed-observer.patch/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/patches/03-exact-combined-guard.patch/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/patches/03-exact-combined-guard.patch/v1/payload` | `0444` |
| `calls/input/validation-v3/coverage-bundle/patches/aggregate-consumer-observer-guard.patch/v1` | `$COMPAT/inputs/calls/input/validation-v3/coverage-bundle/patches/aggregate-consumer-observer-guard.patch/v1/payload` | `0444` |

The canonical `$INPUT` is the resolved target for
`calls/input/compiler-rt-v1/raw/module/v1`. The canonical `$BUNDLE` is the
resolved target for the combined coverage patch logical ID. Existing
repository-local inputs are not executable aliases. Every compatibility path
above requires a later path-specific materialization directive and exact
manifest resolution; none is created here.

## 7. Complete 27-family operational mapping

The finite domains from INBOX-196 remain exact: `<N>` is `1`, `2`, or `3`;
`<canonical-step>` and `<coverage-step>` are the accepted 27/18 step sets;
`<record-part>` is `command`, `environment`, `cwd`, `start`, `end`, `stdout`,
or `stderr`; `<channel>` is `report`, `object`, or `owner`; and
`<function-id>` comes only from the corresponding sorted generated manifest.

Every row below is a future-required definition. No path, row, or authority is
created.

| # | Logical-ID family | Exact new operational path/family | Producer and consumers | Publisher source / compatibility |
|---|---|---|---|---|
| 1 | `calls/validation-v3/<external-kind>/<external-name>/v1` | `$BOOTSTRAP/<external-kind>/<external-name>` where kind is `preflight` or `driver` and name is the accepted nine-file set | sole launcher; bootstrap review and terminal evidence | each exact closed file is its own finite publisher source; never a main-worktree prefix |
| 2 | namespace parents only | `$BOOTSTRAP`, `$CANONICAL/{records,manifests,comparisons,build,artifact,repetition-1,repetition-2,repetition-3}`, `$COVERAGE/{records,manifests,comparisons,build,artifact,reference,observation-off,observation-on}`, `$COMPAT`, `$DURABILITY` | exact phase bootstrap; contains named children only | directories are never publisher sources or compatibility targets |
| 3 | `calls/validation-v3/canonical/cache/<tree-path>/v1` | `$CANONICAL/build/cache/<finite-build-path>` and `$CANONICAL/build/prefix/<finite-install-path>` | canonical build; artifact producer | only explicit final regular files may later be publisher sources; no recursive cache publication |
| 4 | `calls/validation-v3/canonical/repetition-<N>/{home,tmp}/<tree-path>/v1` | `$CANONICAL/repetition-<N>/{home,tmp}/<finite-working-path>` | one repetition report producer | ephemeral; never implicit publisher input |
| 5 | `calls/validation-v3/canonical/artifact/z_llvm/v1` | `$CANONICAL/artifact/z_llvm` | canonical build/install; every canonical and coverage report/object/owner producer | exact regular artifact is finite publisher source and later verified local compatibility copy |
| 6 | `calls/validation-v3/canonical/artifact/identity/v1` | `$CANONICAL/artifact/artifact.identity.tsv` | artifact identity step; canonical/coverage preflight and review | exact file is finite publisher source |
| 7 | canonical step status/record families | `$CANONICAL/status/<canonical-step>` and `$CANONICAL/records/<canonical-step>.{command,environment,cwd,start,end,stdout,stderr}` | one `run_step`; canonical finalizer/review | closed step files form one finite source set excluding publication records |
| 8 | canonical build raw/status records | `$CANONICAL/build/{stdout.raw,stderr.raw,status}` | sole canonical build; artifact identity/review | exact three files only |
| 9 | repetition raw-report family | `$CANONICAL/repetition-<N>/{report.stdout,report.stderr,report.status,report.summary,failures.ordered,failures.sorted,frontier.tsv,frontier.grouped.tsv}` | repetition report/parsers; accepted subset and comparisons | exact closed repetition report-proof set |
| 10 | `calls/validation-v3/canonical/accepted-ll/object/v1` | `$CANONICAL/repetition-1/accepted.ll` | repetition-1 extraction; every canonical and coverage object/owner producer | exact read-only regular file; finite publisher source and verified local compatibility copy |
| 11 | accepted-ll proof family | `$CANONICAL/repetition-1/{accepted.extract.*,accepted.freeze.*,accepted.identity.*}` using the accepted exact proof names | accepted-subset finalizer; canonical/coverage preflight | exact closed proof files only |
| 12 | repetition successful-subset family | `$CANONICAL/repetition-<N>/{accepted.o,owner.tsv,objdump.txt,readelf.txt,text.bin,functions.manifest,owner.ledger.tsv}` | exact object/owner/inspection steps; identity/comparison finalizers | exact closed files only |
| 13 | canonical per-function family | `$CANONICAL/repetition-<N>/functions/<function-id>/{bytes,disassembly,identity}` | sole per-function extractor; 285/0/0 comparisons | finite manifest-derived members only |
| 14 | canonical comparison family | `$CANONICAL/comparisons/<accepted-name>` | exact comparator; canonical finalizer/review | exact generated comparison records only |
| 15 | `calls/validation-v3/canonical/identities/v1` | `$CANONICAL/manifests/canonical-identities.tsv` | three-repetition equality finalizer; coverage reference/off/on | exact file is finite publisher source and later verified local compatibility copy |
| 16 | canonical repetition/final manifests | `$CANONICAL/repetition-<N>/final-manifest.tsv` and `$CANONICAL/manifests/canonical-final.tsv` | repetition and canonical finalizers; coverage preflight/review | exact manifests only; never publication receipts |
| 17 | `calls/validation-v3/coverage/cache/<tree-path>/v1` | `$COVERAGE/build/cache/<finite-build-path>` and `$COVERAGE/build/prefix/<finite-install-path>` | coverage build; coverage artifact producer | only explicit final files may be publisher sources; excluded from performance |
| 18 | coverage artifact family | `$COVERAGE/artifact/{z_llvm,artifact.identity.tsv}` | coverage build/install; observation-off/on | exact two files only; coverage artifact remains excluded from performance |
| 19 | coverage reference family | `$COVERAGE/reference/<accepted-name>` | coverage bootstrap from canonical identities; off/on validators | exact closed reference files |
| 20 | coverage off family | `$COVERAGE/observation-off/status/<coverage-step>`, `records/<coverage-step>.{command,environment,cwd,start,end,stdout,stderr}`, and `semantic/<accepted-name>` | sole observation-off producers; on comparator/finalizer | exact closed off group; channel paths remain absent |
| 21 | coverage on channel family | `$COVERAGE/observation-on/channels/{report.coverage.tsv,object.coverage.tsv,owner.coverage.tsv}` | exactly one matching report/object/owner producer; counter validators | exact three channels, each absent before its producer |
| 22 | remaining coverage on family | `$COVERAGE/observation-on/status/<coverage-step>`, `records/<coverage-step>.{command,environment,cwd,start,end,stdout,stderr}`, and `semantic/<accepted-name>` | sole observation-on producers; equality/counter/finalizer | exact closed on group excluding publication records |
| 23 | coverage per-function family | `$COVERAGE/observation-{off,on}/functions/<function-id>/{bytes,disassembly,identity}` | phase extractor; canonical/off/on equality | finite canonical-manifest-derived members only |
| 24 | coverage comparison family | `$COVERAGE/comparisons/<accepted-name>` | coverage comparators/counter validators; finalizer | exact generated comparison files only |
| 25 | coverage phase/final manifests | `$COVERAGE/observation-{off,on}/final/{files.sha256,phase.final.tsv}` and `$COVERAGE/manifests/{final-manifests.sha256,coverage-final.tsv}` | off/on/coverage finalizers; review | exact finite final files excluding publication evidence |
| 26 | publication evidence family | `$DURABILITY/publication/<group-id>/{command,environment,stdin,stdout,stderr,status,receipt,verification}` | separately authorized post-wrapper; terminal ledger | never included in the semantic group it describes and never a source for its own publication |
| 27 | `calls/validation-v3/durability-terminal/v1` | `$DURABILITY/terminal/terminal-ledger.tsv` | finite ledger over expected publication groups; human/Reviewer | terminal file is deliberately not publishable and has no compatibility target |

Every semantic publisher receives an exact finite file list derived from the
corresponding row. No publisher receives `$OP`, `$CANONICAL`, `$COVERAGE`, a
directory, glob, or recursive source. Publication records live only under
row 26 and cannot appear in the group they describe.

## 8. Comprehensive old-to-new replacement rule

A later contract amendment must:

1. replace the exact old root
   `/home/oleg/prog/z_llvm/tmp/o2_calls_perf/compiler_rt_v1/baseline_validation_v3`
   with `$OP`;
2. replace old external `$PARENT/baseline_validation_v3.preflight.*` and
   `.driver.*` files with row-1 bootstrap paths;
3. replace every old canonical/coverage/input/bundle/build/cache/record/status/
   comparison/channel/finalizer path with sections 6 and 7;
4. retain the exact workloads, source commit, patch order, environment,
   command bodies, phase ordering, counters, channels, statuses, equality
   checks, identities, restoration semantics, and acceptance rules; and
5. reject the amendment if any executable token contains the old root or if
   one phase mixes old and new paths.

Historical exhausted-v1/v2 paths remain immutable evidence and are not
subject to string replacement. The replacement applies only to future-v3
executable streams and ledgers.

## 9. Private `AuthorityConfig`

### 9.1 Closed private shape

The future implementation uses one file-private, non-`pub` configuration:

```text
AuthorityConfig
  authority_mode: production | synthetic_test
  artifact_store_root: absolute path
  tracked_manifest_path: absolute path
  main_git_common_dir: absolute path
  main_repository_root: absolute path
  operational_root: absolute path
  canonical_source_control: absolute path
  coverage_source_control: absolute path
  tracked_control_allowlist: fixed-capacity 10-path array
  expected_registration:
    count
    path_sha256
    topology_sha256
    non_main_sha256
    repository_tmp_count
    system_tmp_count
    other_count
  registration_input:
    live_git_metadata
    synthetic_canonical_fixture
```

There is no function pointer, callback, vtable, allocator in the public
intent, command-line flag, environment selector, fallback, dynamic plugin, or
open-ended path list.

`AuthorityConfig` is borrowed construction input only. Before parsing argv,
private `OwnedAuthorityConfig.init`:

- normalizes and duplicates every scalar path into command-lifetime allocator
  storage;
- copies the fixed arrays and expected hashes/counts;
- obtains and owns the canonical registration bytes according to the
  compile-time mode;
- parses one owned `RegistrationSnapshot`;
- validates all production or synthetic cross-path disjointness; and
- retains no slice borrowed from argv, environment, a temporary parser, or a
  test stack frame.

`deinit` frees each owned path and registration allocation exactly once.
Partial initialization tracks owned counts and rolls back only initialized
entries.

### 9.2 Production construction

`main` has exactly one production construction:

```text
runCommand(.production, init, productionAuthorityConfig())
```

`productionAuthorityConfig()` is private and contains only:

- the accepted real store;
- the exact tracked manifest and main Git paths;
- the exact sibling operational root and two protected source children;
- the fixed tracked-control allowlist;
- the accepted registration hashes/counts; and
- `.live_git_metadata`.

The accepted `ZLLVM_ARTIFACT_STORE` handling remains, but production requires
its resolved result to equal the accepted real store. No new argv,
environment variable, override, alternate authority, test mode, or
configuration file is visible in the production binary.

### 9.3 Synthetic construction

Tests instantiate:

```text
runCommand(.synthetic_test, test_init, syntheticAuthorityConfig(fixture))
```

The synthetic configuration names only one later-authorized synthetic store,
one disjoint synthetic operational root, one synthetic tracked manifest, and
one owned canonical registration fixture. It must prove bidirectional
disjointness from:

- the real store;
- the production operational root;
- the main repository;
- every registration in the fixture and accepted live metadata; and
- every retained real/synthetic root named by the controlling test directive.

Synthetic mode cannot resolve, open, stat, hash, or mutate the real store,
real manifest, main tracked-control allowlist, production operational root, or
a registered worktree. Tests create all synthetic bytes themselves within
their separately authorized root.

The registration fixture is exact canonical
`git worktree list --porcelain`-format bytes. The mode changes only how those
bytes are acquired: production captures live metadata through the existing
absolute Git command; tests provide owned fixture bytes. Both then call the
same `parseRegistration`, expected-count/hash validation, equality checks,
path-role guards, and drift checkpoints. Synthetic drift is modeled by
replacing the test fixture between checkpoints, never by a Git worktree
operation.

## 10. Shared internal command driver

### 10.1 Compile-time and runtime split

The only compile-time branch is configuration acquisition:

```text
runCommand(comptime mode, init, borrowed_config)
  -> OwnedAuthorityConfig.init(mode, borrowed_config)
  -> CommandDriver.init(init, owned_config)
  -> CommandDriver.execute()
```

The production instantiation contains no synthetic selector. The test
instantiation contains no production authority constant. After
`OwnedAuthorityConfig.init`, both execute the same runtime code for:

- argv count and token parsing;
- stdin empty/spec handling;
- canonical schema parse/re-encode;
- manifest pair and generation-lineage checks;
- logical resolution and immutable verification;
- registration checkpoints and exact path-role validation;
- capacity checks and transaction boundaries;
- atomic compatibility or publication operations;
- rollback and post-commit disposition;
- closed error-to-status mapping;
- stdout/stderr encoding; and
- receipt generation.

No test calls a lower-level transaction helper in place of the command
driver. A proof counts only when it supplies exact argv/environment/stdin and
asserts exact stdout/stderr/status through the shared driver.

### 10.2 Driver ownership

Private `CommandDriver` owns:

- the allocator and `std.Io` handles borrowed for one invocation;
- one moved `OwnedAuthorityConfig`;
- owned argv tokens after canonical parsing;
- owned stdin/spec bytes;
- one registration guard snapshot;
- one parsed manifest/generation context;
- one transaction state for the selected command; and
- bounded output buffers.

It does not own external source files, store objects, caller output handles,
or registered worktrees. Descriptors use local `defer`; allocations use
single-owner `deinit`; mutating commands retain the INBOX-197 pre-commit and
post-commit semantics. Configuration deinitialization runs once after command
output finalization or error mapping.

### 10.3 Visibility and error surface

`AuthorityConfig`, `OwnedAuthorityConfig`, `AuthorityMode`, `CommandDriver`,
the production/synthetic constructors, and all path-role helpers are private
to `tools/zllvm_artifact_store.zig`. No `pub` declaration, build-module
export, facade, header, or external test leaf is added.

The driver exposes one private explicit error union that maps exhaustively to
the accepted INBOX-197 closed error document/status table. Configuration
errors are not a new public error surface; they map to the existing
`authority`, `registration`, `path`, `schema`, or `internal-invariant`
families. No inferred error becomes `anyerror`.

Tests remain co-located in the existing tool source and may use
`builtin.is_test` only to construct synthetic fixtures. No production
callback, fault hook, environment override, or alternate command is compiled
into the production instantiation.

## 11. Reconciled path-guard algorithm

For an exact candidate:

1. normalize the absolute candidate and require byte equality;
2. capture/validate registration according to the private mode;
3. classify the requested role before opening a path;
4. for tracked control, require exact allowlist equality and no-follow regular
   read;
5. for protected source control, reject every artifact operation;
6. for artifact authority, require bidirectional disjointness against all
   registrations;
7. for operational/publisher/compatibility roles, require containment beneath
   `$OP`, exclusion from both source subtrees, and bidirectional disjointness
   of the **exact candidate** against all registrations;
8. open only each explicitly named ancestor no-follow, without iteration;
9. perform the role-specific operation; and
10. revalidate registration before mutation, commit, and result emission.

The algorithm never asks whether all of `$OP` is disjoint after its source
children are registered. It never treats an allowed tracked control file as
an artifact, publisher source, or compatibility target.

## 12. Frozen later seam proofs

All proofs are future-only:

- production configuration derives the exact sibling root and rejects an
  environment/argv attempt to select another;
- production has exactly one `.production` driver instantiation and no
  synthetic argv/env path;
- synthetic configuration cannot name the real store, tracked manifest,
  production operational root, main repository, or registered path;
- production and synthetic invocations with equivalent synthetic bytes yield
  byte-identical parsing, result, and closed-error behavior;
- owned configuration survives temporary fixture/argv teardown and frees each
  allocation exactly once on success and every early error;
- malformed registration, changed registration, wrong counts/hashes, and
  synthetic drift fail at the same shared checkpoints;
- exact operational siblings remain usable after either source child appears
  in the registration fixture;
- each source subtree and every ancestor/descendant intersection is rejected;
- exact tracked-control allowlist reads succeed no-follow; a sibling,
  directory, symlink, relative path, publisher-source use, and compatibility
  use fail;
- all 19 input compatibility targets and representative members from every
  one of the 27 families classify correctly;
- old-root tokens, mixed-root command streams, recursive discovery, directory
  publisher sources, and terminal-evidence publication fail structurally;
- resolver/verifier remain zero-write in both modes; and
- compatibility/publisher interruption and rollback use the same shared
  driver path in production-shaped synthetic tests.

Guards must reject new public declarations, a second command driver, a second
configuration constructor for production, production test-mode strings, new
argv/environment authority selection, callbacks, and direct low-level test
execution that bypasses the shared driver.

## 13. Preserved v2 blocker and remaining structural stops

The INBOX-197 blocker remains exact:

```text
successor-generation-schema=zllvm-artifact-manifest-v2_REQUIRED
generation_1=IMMUTABLE_V1
repair_authorized=false
```

Additional named stops remain:

| Stop | Condition |
|---|---|
| `operational-root-bootstrap` | `$OP` remains absent; creation needs a later path-specific directive and fresh registration/store checks. |
| `protected-source-worktree-creation` | each exact source child needs explicit user authorization; this design cannot create or register it. |
| `tracked-control-role-implementation` | current `RegistrationGuard` has no exact allowlisted main-worktree control-read role. |
| `operational-exact-path-guard` | current store-root disjointness helper rejects ancestor roots and does not implement the exact sibling-target role. |
| `private-command-driver` | current `main` parses and dispatches directly; no private shared configuration seam exists. |
| `read-only-snapshot-streaming` | the INBOX-197 no-write snapshot verifier still requires bounded implementation. |
| `accepted-cli-executable-identity` | the future absolute executable path/build identity is not yet frozen. |

None is repaired here. Any implementation that requires a public config,
callback, new production argv/env capability, broad operational-root
exception, directory discovery, or weakening registered-worktree protection
is a structural stop.

## 14. Exact later sequence

1. Watcher/Reviewer review this reconciliation.
2. If accepted, separately amend and re-review the INBOX-197 CLI-surface
   design so it incorporates this exact root, role model, and private seam.
3. Only after that design acceptance, consider a separately bounded dormant
   read-only resolver/verifier implementation.
4. Compatibility materializer, future-output publisher, contract amendment,
   v3 execution, production wiring, performance, ratchet credit, and the
   post-calls checkpoint remain later independent decisions.

No step is preauthorized.

## 15. Static closure record

```text
operating_head=d0b777bcdaa452c621624d132fdb585b301dd81e
operating_parent=6ee7bda862ed1f43fcdb96f7d23b99870cd790e7
git_common_dir=/home/oleg/prog/z_llvm/.git
new_operational_root=/home/oleg/prog/z_llvm-baseline-validation-v3
new_operational_root_state=absent
old_repository_local_root_state=absent
registration_metadata_count=43
new_root_registration_conflicts=0
real_store_registration_conflicts=0
new_root_real_store_conflicts=0
accepted_input_compatibility_targets=19
future_family_rows=27
protected_future_source_paths=2
tracked_control_allowlist_paths=10
private_authority_configs=1
shared_command_drivers=1
successor_v2_blocker=preserved
registered_worktree_traversal=none
real_store_traversal_or_hashing=none
path_creation=none
validation_v3=absent_and_unauthorized
production=unchanged_dormant
ratchet=131
next=STOP_FOR_WATCHER_REVIEWER_RECONCILIATION_REVIEW
```

Only exact named paths, read-only Git registration metadata, and named tracked
files in the main worktree informed this design. No broad/recursive discovery,
`find`, registered-worktree traversal/hash, path creation, worktree operation,
project or artifact command, build, test, gate, implementation, source/tool/
contract/store/manifest/pin mutation, compatibility materialization, cleanup,
v3 execution, production wiring, performance, Tier work, checkpoint action,
ratchet movement, or credit action ran.
