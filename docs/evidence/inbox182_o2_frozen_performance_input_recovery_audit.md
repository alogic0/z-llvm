# INBOX-182 frozen performance-input recovery audit

## Result and stop disposition

No existing byte-exact copy of the required input was found in the
repository-local inventory.

```text
required_path=tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll
required_sha256=7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b
accepted_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
accepted_report_population=443/285/158
result=no exact regular-file, Git-blob, or archive-member candidate
ratchet=131 unchanged
```

The audit exhausted the current repository tree, retained `tmp` and cache
files, every registered worktree, Git administrative files, every currently
present Git blob (including unreachable objects exposed by
`--batch-all-objects`), reflog/object provenance, and every detected archive
container. It found no target-hash match. The retained record proves how the
input was consumed, but does not preserve its creation command or the
complete source/tool chain required to reproduce its bytes deterministically.

Per INBOX-182, this is the no-candidate stop: no reconstruction, protocol
amendment, recovery, pinning, or production wiring was attempted.

## Authorization and frozen starting state

The operating authorization is commit
`953dc169a36d46417e3c0f64dc2d9c83dfbb6674`, tree
`e3400f2a85be725a1957dca2dedeb12d85977382`. The worktree was clean before
the audit. `stash@{0}` remained:

```text
On x86_64-codegen-expanded-frontier: INBOX-93 preserve B2B wiring plus five diagnosis tests
```

The frozen surfaces were checked before inventory:

| Surface | SHA-256 or Git blob |
|---|---|
| `scripts/z_llvm_watcher_loop.sh` HEAD/index/worktree | Git blob `8f3be1dd08dadc6f42ede169ca05e84daae773ab` |
| `scripts/z_llvm_watcher_loop.sh` content | `ac1d08eed3aadc8ed9ccf7afb5df93889630c95a68e7fe594aba67a760a89dd7` |
| `docs/retention_headroom_policy.md` | `a31e3fbf7aa03c8544fc5f9921e350c25e4e470cc3c779dfb356136634e052dd` |
| `docs/evidence/tmp_retention_pins.tsv` | `f4374187d77ec6b7c42ee1b64538ead1a2d599697595a7f59c28b23dae5c6614` |
| `tools/clean_tmp.zig` | `8e0c54ad6fed9e46326049dbe64bff743daddcc2527c1dc4d5e02be15fba2d5e` |
| bypass TSV | `2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11` |
| facade manifest | `2adcd99ee3bfbe0e9f09673f1df02ab305b5ddb2c1b461023152d5d03a079c26` |
| accepted INBOX-181 evidence | `358fdb7c4f2f0a60ed34d325d8a673bc6596a88d20b169dfd596ab4b485c6f82` |

The facade manifest remains the header plus 126 symbols. The accepted
ratchet remains 131.

All 40 retained INBOX-181 files were present, totaling 192,559,904 bytes.
The SHA-256 of the sorted `sha256sum` stream for those files was
`386a88cd3efd1ef7b1b62c7122afd61506370bc2bc4b13ec92dbb6841a6b97f5`.
Both retained INBOX-181 source manifests verified every listed path
successfully, including the dormant call sources, guard sources, bypass TSV,
facade manifest, retention files, cleanup tool, and watcher script.

## Regular-file, `tmp`, cache, and worktree inventory

The requested path is absent. Its parent directory is also absent. Git
ignores the path through `.gitignore:19` (`tmp/`), and there is no tracked
path history for it.

The main repository-root scan, excluding `.git`, streamed every regular file
through `sha256sum`:

```text
regular_files=710019
regular_bytes=60811178410
target_matches=0
read_or_hash_anomalies=0
```

That boundary includes all retained files and the 29 registered worktrees
under the repository root. It includes:

```text
tmp_top_level_directories=68
tmp_files=707204
tmp_bytes=55649552252
cache_named_directories=8559
cache_path_files=376684
cache_path_bytes=46938865416
```

Within that boundary, 24,147 `.ll` files (1,958 distinct SHA-256 values)
were also classified separately; none matched the target.

Git registered 39 worktrees in total: the main tree, 29 additional
worktrees beneath the repository root, and these nine external registered
worktree paths:

```text
/home/oleg/prog/zllvm-inbox45-p0
/tmp/z_llvm_clean_tmp_update
/tmp/zllvm-inbox104-before
/tmp/zllvm-inbox107-before
/tmp/zllvm-inbox108-a
/tmp/zllvm-inbox108-b
/tmp/zllvm-inbox109-a
/tmp/zllvm-inbox109-b
/tmp/zllvm_check
```

The nine external registered worktrees were streamed independently:

| Worktree | Regular files | Bytes | Target matches |
|---|---:|---:|---:|
| `/home/oleg/prog/zllvm-inbox45-p0` | 4,724 | 5,047,061,020 | 0 |
| `/tmp/z_llvm_clean_tmp_update` | 2,308 | 75,757,430 | 0 |
| `/tmp/zllvm-inbox104-before` | 2,454 | 279,842,656 | 0 |
| `/tmp/zllvm-inbox107-before` | 2,457 | 279,933,136 | 0 |
| `/tmp/zllvm-inbox108-a` | 2,457 | 279,927,565 | 0 |
| `/tmp/zllvm-inbox108-b` | 2,457 | 279,897,126 | 0 |
| `/tmp/zllvm-inbox109-a` | 2,458 | 279,909,681 | 0 |
| `/tmp/zllvm-inbox109-b` | 2,458 | 280,002,733 | 0 |
| `/tmp/zllvm_check` | 5 | 1,164,898 | 0 |
| **Total** | **21,778** | **6,803,496,245** | **0** |

Thus the non-Git-object regular-file boundary covered 731,797 files and
67,614,674,655 bytes across the main repository boundary and all external
registered worktrees. There were no symlinks in the main boundary.

## Git objects, references, and reflogs

`git cat-file --batch-all-objects` exposed:

| Object type | Count | Decompressed bytes |
|---|---:|---:|
| blob | 17,194 | 1,119,754,689 |
| commit | 2,936 | 1,218,757 |
| tree | 17,612 | 34,020,977 |

Every one of the 17,194 blobs was streamed directly from `git cat-file` into
`sha256sum`; target matches were zero. No blob was checked out or written to
an intermediate file. The same blob stream was classified by MIME type;
there were no archive-format Git blobs requiring member enumeration.

The repository had eight refs, nine reflog files, and 2,925 unique commit
identities named by reflogs. `--batch-all-objects` includes currently present
reachable and unreachable objects, so the blob result is broader than the
37,625 objects named by current refs/reflogs. No ignored target-path history
exists in `git log --all --reflog --full-history`.

All 1,342 regular Git administrative files (39,355,356 bytes), including
reflogs, were also hashed as existing files. None matched the target.

## Archive audit

A content-type scan of all 710,019 current repository regular files found
one archive/container:

```text
path=tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt.a
format=Unix ar
container_bytes=216
container_sha256=69311c1cb8f3c2f0fef09e1143ab6a1b5ec5f752601c017147030013708442ec
```

Its single member was enumerated and streamed without extraction:

```text
member=tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o
mode=rw-r--r--
uid=0
gid=0
member_bytes=0
member_timestamp=1969-12-31 18:00
member_content_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
target_match=no
```

The separately retained zero-byte member path had the same empty-content
hash and was already covered by the regular-file scan. MIME scans of all
21,778 external-worktree regular files and all 17,194 Git blobs found no
other archive container. There is therefore no archived target match and no
archive extraction or candidate materialization occurred.

## Current manifests, scripts, commands, and historical references

Before this audit document was added, the target SHA occurred in 30 current
reference files: 29 evidence files and one other operating document. The
exact target path occurred in 57 current reference files: 56 evidence files
and one other operating document. There were no `tmp` or non-document
references to either string. The retention policy, retention pins, cleanup
tool, and watcher contain neither the target path nor its SHA-256.

The historical files record many commands that *consume* the frozen input,
for example:

```text
LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector \
  --report-all-codegen-failures --target=x86_64-linux \
  --input-limit=67108864 \
  tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll \
  > /dev/null 2> <report.log>
```

They do not record a command that created `compiler_rt_frozen.ll`.

The first decisive retained record is
`docs/evidence/inbox92_o2_store_family_migration.summary`. It records:

```text
input_sha256=7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
selected/emitted/failed=443/285/158
first_failure=compiler_rt.trunc.truncl
first_diagnostic=UnsupportedLongDoubleAbi
```

It also records the before/after sample hashes, timings, RSS, snapshot
metrics, and the fact that both sides used the same frozen input. The
recorded target directory, report, raw samples, metric logs, and input are
now absent. It does not record the frozen input's byte count, generation
command, source corpus identity, compiler identity, or creation-time
environment.

Earlier accepted records used different capture hashes:

```text
INBOX-87/INBOX-91 capture=7be46e0b88c96fce0ce527407672843c43d3416ce56257d53a286603bd533e06
INBOX-90 capture=3575879c50f476c03ae4bfb0e29948d65dc20fce7428aba5dbda5df080d48ca8
```

Those captures reproduced the same report hash but are not the target input.

## Explicitly excluded reference inputs

These existing inputs were streamed and remain reference-only:

| Existing input | Bytes | SHA-256 | Disposition |
|---|---:|---|---|
| `tmp/inbox178_o2_call_final_use/compiler_rt_regenerated.ll` | 6,198,914 | `fc2f433e2106ee431285722bec533e6799748abcfe6b750acbdfb25bd5d7464f` | excluded substitute |
| `tmp/inbox178_o2_call_final_use/compiler_rt_regenerated_safe.ll` | 7,650,265 | `9f8772b6c46701ace5bbaf891267f12d8e7325c07b129fc1c3cfe7390d0db88b` | excluded substitute |
| `tmp/inbox178_o2_call_final_use/compiler_rt_regenerated_small.ll` | 1,215,866 | `8cc6381b35cc063e4e0cf70f0ac387c94238333b849513ed66a57a1a46a6fde8` | excluded substitute |
| `tmp/inbox63_accepted_cohort.ll` | 7,215,373 | `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4` | 285-row input, excluded substitute |

INBOX-178 already recorded that the target was absent at operating HEAD
`f0a99e88`, was not retention-pinned, and that the three regenerated inputs
matched neither the target hash nor its 443-row population. The
`inbox63_accepted_cohort.ll` run produces 285/285/0 rather than 443/285/158.
Retained `49a19f04` report logs prove historical output only; they are not
input recovery candidates. No reference file was copied, renamed, combined,
normalized, or patched.

## Reconstruction-provenance finding

The retained chain is insufficient for deterministic byte reconstruction.
It preserves:

- the expected input path and SHA-256;
- the consumer command shape;
- the resulting report hash and population;
- performance commands, samples, and environment fragments such as
  `LC_ALL=C` and `taskset -c 0`;
- later different-hash inputs and their excluded status.

It does **not** preserve, as one proven chain:

- the exact command that produced the target `.ll`;
- the target byte count;
- the exact compiler/compiler-rt source corpus and revision used to create it;
- the exact compiler binary identity and full invocation;
- target CPU/features, optimization/code-generation flags, and any input
  enumeration/filtering order used during creation;
- the creation-time environment/cache inputs;
- a retained manifest tying all of those facts to the target SHA-256.

Later evidence contains compiler pins for later gates, but no retained record
proves that any such pin generated this target. Consequently, neither a
lossless reconstruction recipe nor all exact source/tool inputs can be
established from repository-local evidence. No apparent recipe was executed.

## Exact read-only command record

The audit used only repository-local read/hash/list commands. The core
commands were:

```text
git status --short
git rev-parse HEAD^{commit} HEAD^{tree}
git stash list
git worktree list --porcelain
git for-each-ref
git reflog --all
git check-ignore -v tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll
sha256sum -c \
  tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/results/aggregate/restored_source_hashes.sha256
sha256sum -c \
  tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation/results/baseline/source_hashes.sha256

find . -path './.git' -prune -o -type f -print0 |
  xargs -0 sha256sum |
  awk -v target=7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b \
      '$1 == target { print }'

find <each-external-registered-worktree> -type f -print0 |
  xargs -0 sha256sum |
  awk -v target=7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b \
      '$1 == target { print }'

git cat-file --batch-all-objects --batch-check='%(objectname) %(objecttype) %(objectsize)'
git cat-file --batch-all-objects --batch-check='%(objectname) %(objecttype)' |
  awk '$2 == "blob" { print $1 }' |
  while read oid; do git cat-file blob "$oid" | sha256sum; done

git cat-file --batch-all-objects --batch-check='%(objectname) %(objecttype)' |
  awk '$2 == "blob" { print $1 }' |
  while read oid; do git cat-file blob "$oid" | file --mime-type -b -; done

find . -path './.git' -prune -o -type f -print0 |
  xargs -0 file --mime-type --
ar tv tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt.a
ar p tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt.a |
  sha256sum

rg -l --hidden --glob '!.git/**' \
  '7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b' .
rg -l --hidden --glob '!.git/**' \
  'tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll' .
```

No `z_llvm`, Zig, selector-report, correctness-gate, performance, network,
cleanup, `clean_tmp`, Git maintenance, reflog-expiration, garbage-collection,
deletion, generation, or reconstruction command ran.

## Final boundary

The repository-local audit found no existing exact regular file, Git blob,
or archive member. The historical record lacks the complete deterministic
creation provenance. The three regenerated inputs, the 285-row accepted
cohort, retained report logs, prior capture hashes, and all other
different-hash inputs remain reference-only.

STOP before reconstruction, recovery, pinning, performance-protocol
amendment, production wiring, or ratchet credit.
