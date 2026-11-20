# INBOX-185 compiler-rt v1 three-generation materialization/reproduction

## Disposition

INBOX-185 completed successfully. The three independently cached, sanitized,
one-shot stage4 generations produced byte-identical raw LLVM IR:

```text
contract_id=o2-calls-compiler-rt-v1-releasefast-x86_64-linux-gnu-baseline-zig-bdee02bc
reproduced_artifact_id=o2-calls-compiler-rt-v1-releasefast-x86_64-linux-gnu-baseline-zig-bdee02bc-sha256-9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1
generation_count=3
bytes_each=1897410
sha256_each=9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1
exit_status_each=0
stdout_bytes_each=0
stderr_bytes_each=0
pairwise_cmp_statuses=0,0,0
```

This proves reproducibility only. The outputs remain in the ignored
generation roots with their original mode `0664`. No output was adopted,
copied, renamed, normalized, chmodded for adoption, retention-pinned,
validated, executed by `z_llvm`, or accepted as a performance-protocol
input.

The ratchet remains **131**. This slice claims no production wiring, helper
collapse, protocol adoption, validation identity, performance result, or
credit.

## Authorization and inspected boundary

The complete `docs/worker_inbox.md` and `docs/next_steps.md` were read before
work. Their inspected identities were:

| File | Lines | Bytes | SHA-256 |
|---|---:|---:|---|
| `docs/worker_inbox.md` | 9,777 | 599,547 | `6aedb95d832095cb722b1c25d29bf1d6d3672271bc45756426f4ca086fe851b5` |
| `docs/next_steps.md` | 1,869 | 323,373 | `9ec175e63df7e4e666006df3daac8b0daa4c05727e094e755fa44f143281dab4` |

```text
authorization_HEAD=61edd65af6a27cbc0e6452b06d001f4b2c481327
authorization_tree=e185b672c4bed70c6666c21503c1518741200f88
accepted_contract_commit=1c343ec879e46eb488a737e6da8db4ebdc6038f5
accepted_contract_sha256=a5c1d3f97b35d1815cc933cebf1a5261fd7fa9fde1277beb97a694a987bf02da
contract_path=docs/evidence/inbox184_o2_reproducible_compiler_rt_corpus_contract.md
branch=x86_64-codegen-expanded-frontier
starting_tracked_status=clean
ratchet=131
```

The watcher was never edited or staged:

```text
watcher_HEAD_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
watcher_index_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
watcher_worktree_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
watcher_content_sha256=02f972ddc3ad5bf48e6f474312e7f58763b1886ff35e2c92c3902db27234fae5
watcher_status=clean
```

The only stash entry remained:

```text
stash@{0}=7985c6d01040a6e47e4ce5b918866d0e89517ac7
stash_subject=On x86_64-codegen-expanded-frontier: INBOX-93 preserve B2B wiring plus five diagnosis tests
```

## Complete preflight before root creation

Every identity, absence, cleanliness, dependency, and capacity check below
completed before
`tmp/inbox184_o2_compiler_rt_v1/materialize` was created. No preflight
failure was repaired or bypassed.

### Absence and capacity

Both required paths were absent:

```text
materialization_root=tmp/inbox184_o2_compiler_rt_v1/materialize
materialization_root_before=absent
adoption_path=tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll
adoption_path_before=absent
```

The conservative retained-capacity calculation passed:

```text
reference_zig_cache_bytes=2167907014
reference_zig_source_bytes=2075584360
stage4_bytes=530327885
per_generation_margin_bytes=67108864
fixed_bundle_margin_bytes=2147483648
required_bytes=3*(2167907014+67108864)+2147483648=8852531282
available_bytes=97955401728
headroom_bytes=89102870446
capacity=PASS
filesystem=/dev/nvme0n1p2
filesystem_type=ext4
mount=/
```

### Pinned source and compiler

```text
zig_source_worktree=../ziglang
zig_HEAD=bdee02bc0c7f227c0f11bc9a449df673fe803540
zig_tree=aa032b2b82a48a4684657f909e6e270a6c925e33
zig_status_bytes=0
zig_pin_file_sha256=addebfc419954a039711d03dac09349253522094b79824cc15db023921b62196
compiler_rt_root=../ziglang/lib/compiler_rt.zig
compiler_rt_root_bytes=25063
compiler_rt_root_mode=664
compiler_rt_root_sha256=388ce4e0ac6dd5a285a19c66d193d088d3515f5dd726cafc475d222cdd8b4fa0
stage4_path=../ziglang/build/stage4/bin/zig
stage4_bytes=530327885
stage4_mode=775
stage4_sha256=dcea3478273d7ffe3895709c8eed4ccc0724548869cdb86183fc7356164410b7
stage4_version=0.17.0-dev.364+bdee02bc0
stage4_linkage=dynamic
```

The raw NUL-delimited full-tree manifest was captured before generation:

```text
command=git -C ../ziglang ls-tree -rz --full-tree bdee02bc0c7f227c0f11bc9a449df673fe803540
path=tmp/inbox184_o2_compiler_rt_v1/materialize/source/zig-tree.nul
bytes=2154652
mode=664
sha256=9c3a5ecab710fc6a76496a0bc6bb344aa4942a19c558cb5653d045c726da8818
```

### Resolved dynamic dependencies

`linux-vdso` was recorded separately as kernel-provided. Every regular
resolved dependency was captured by canonical path, byte count, mode, and
SHA-256:

| Path | Bytes | Mode | SHA-256 |
|---|---:|---:|---|
| `/usr/lib/x86_64-linux-gnu/libm.so.6` | 952,616 | 644 | `1b87a1a50b496cfead2b0ad134c2ff536705c82608db240c7e8aa48d6c0e4217` |
| `/usr/lib/x86_64-linux-gnu/libc.so.6` | 2,125,328 | 755 | `d8db8739a1633c972cec6a4fe0566bdcec6fd088f98723492ab0361f66238f75` |
| `/usr/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2` | 236,616 | 755 | `1cd555ac46b7887edeaf3c42aac5408c8135e52f6b37870da2cf82d5fe14e829` |
| `/usr/lib/x86_64-linux-gnu/libclang-cpp.so.22.1` | 62,326,208 | 644 | `9bc9a129ff0daac529d0d263f369ba6daee270ea667950b9c6766fffd35b989c` |
| `/usr/lib/x86_64-linux-gnu/libLLVM.so.22.1` | 149,342,008 | 644 | `b316ca59d45601481362b635e50b8e8e1427e383714bc29c7b404b51e9a49d99` |
| `/usr/lib/x86_64-linux-gnu/libz3.so.4` | 16,106,752 | 644 | `730694c87a99a1e512562bd36d005c121610531c146e4317be0e1a8d53882b18` |
| `/usr/lib/x86_64-linux-gnu/libz.so.1.3` | 113,000 | 644 | `9b64150b28505a33d6bc3ecf709c279f6de97a1c184dbda65d06ee4537f6d286` |
| `/usr/lib/x86_64-linux-gnu/libzstd.so.1.5.5` | 755,864 | 644 | `0a2128bc10841fb29e76d08d945864dfb0b6a66da5df6df5d8299197439e54bb` |
| `/usr/lib/x86_64-linux-gnu/libxml2.so.2.9.14` | 1,967,424 | 644 | `8b6f68c242929aebe49eb28f800dc3e8ee7147298c94bdabc834f61eff1ac177` |
| `/usr/lib/x86_64-linux-gnu/libstdc++.so.6.0.33` | 2,592,224 | 644 | `1fd75fe70354a416d75aef22bcae68c47bd25d20e2d0568c30b1a9838cf62f11` |
| `/usr/lib/x86_64-linux-gnu/libgcc_s.so.1` | 183,024 | 644 | `d93224d2b0dab4247598be683adca02f5cf00586f99c187579cd7e92058fb7cb` |
| `/usr/lib/x86_64-linux-gnu/libffi.so.8.1.4` | 47,672 | 644 | `00f593fe192f2851b8ce23b25cec2488d769beb5a8f63e8c9e563071e1075153` |
| `/usr/lib/x86_64-linux-gnu/libedit.so.2.0.72` | 220,472 | 644 | `195c607216f8581dbf516346ed38f4c73500cac4b84e18eb0a4fd49931e4cd56` |
| `/usr/lib/x86_64-linux-gnu/libicuuc.so.74.2` | 2,140,336 | 644 | `7560aadde38e5f4237a47a1ddd5891f9b36768a77a60faae30beee003ac01901` |
| `/usr/lib/x86_64-linux-gnu/liblzma.so.5.4.5` | 202,904 | 644 | `696e868dd0700a19a6d65fc01608ec2d70d3cb91f65710e89180cd2e688f30cb` |
| `/usr/lib/x86_64-linux-gnu/libtinfo.so.6.4` | 208,328 | 644 | `28ab8e2e29d46dc8f7222025ca2d61e0b898364c6426cc631bf4ecc7c7f5ac52` |
| `/usr/lib/x86_64-linux-gnu/libbsd.so.0.12.1` | 80,888 | 644 | `e86cd4f0019f42c2ba5e60602e0edc8694d2948377d98c3654d0f6bddb5254bb` |
| `/usr/lib/x86_64-linux-gnu/libicudata.so.74.2` | 30,795,392 | 644 | `ddbb3718b8bd9cbd780e5ab08b4503c30a6c4fa0706ebe5d074ed6b596c1714e` |
| `/usr/lib/x86_64-linux-gnu/libmd.so.0.1.0` | 55,536 | 644 | `423e18586b6ea740f4465afd64f7a9a4cb7264ed979c8e7256f9085af5345fef` |

The retained dependency manifest SHA-256 is
`cf84b0563ea7a9e0eeabe5a8d2a5ab5e00c671814382d13bf2088878f0b1bffa`.

### Host and frozen-surface manifests

```text
cwd=/home/oleg/prog/z_llvm
shell=/bin/bash
umask=0002
architecture=x86_64
kernel=Linux R780M 6.17.0-23-generic #23~24.04.1-Ubuntu SMP PREEMPT_DYNAMIC Tue Apr 14 16:11:48 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
preflight_utc=2026-07-19T21:15:40.595290875Z
preflight_epoch=1784495740
```

The retained host-tool manifest identifies `bash`, `git`, `env`,
`sha256sum`, `stat`, `cmp`, `mkdir`, `date`, `readlink`, `ldd`, `file`,
`du`, `df`, `findmnt`, `wc`, `sed`, and `rg` by resolved path, mode, byte
count, and SHA-256:

```text
host_tools_manifest_sha256=82db4cce6b56f060e2041a6531b8427b12a80982dccce28dcc7509b5a58b3e2d
host_environment_sha256=79bc36be2b00a756ea4b99bc0e287136491af4e05e776abed33cdeba32cba9ab
preflight_summary_sha256=6db4978008fd1584556c7c4730698d6c37a37b4624a751278fac0872584bd0f3
pre_generation_manifest_file_sha256=77f421417ed97f8a4d789cecef168ae39628ca6bc4bda11f4f2da457329e65a5
preflight_status=PREFLIGHT_PASS
preflight_status_file_sha256=5e6c3919a3603f66a2d2fcdda37d17b0ad1fe7793498311d5c5a7ae028363a56
```

The frozen-surface manifest contained the watcher, retention policy and
pins, cleanup tool, bypass TSV, 126-symbol facade manifest, dormant call
production/action/model/core/facade sources, source-guard files, accepted
INBOX-181/182/183 evidence, and the INBOX-184 contract:

```text
frozen_surfaces_manifest_sha256=f3670f52f5213b2c0b89f3824848816487e61d2c346eba2d448bc8ed60ef65a9
```

The separately retained candidate/report manifest preserved AC285, all
three INBOX-178 regenerations, their report logs, the historical retained
`49a19f04` report, and the accepted owner manifest:

```text
candidates_reports_manifest_sha256=080d4b91512a13966d3d43455a214045d226900e9099fdd9cd7ca40f124140b9
```

No candidate or report was read as an executable input, substituted,
renamed, copied, modified, or retention-pinned.

## Root creation and isolation

Only after every preflight passed, the accepted roots were created:

```text
tmp/inbox184_o2_compiler_rt_v1/materialize/source
tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/{home,tmp,cache/global,cache/local,output,logs}
tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/{home,tmp,cache/global,cache/local,output,logs}
tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/{home,tmp,cache/global,cache/local,output,logs}
tmp/inbox184_o2_compiler_rt_v1/materialize/comparison
```

For every generation, `HOME`, `TMPDIR`, local cache, global cache, output,
and log directories were distinct and empty at creation. No generation
shared or prewarmed a cache. The common source and stage4 inputs retained
the identities above.

## Exact generation environment and commands

Each byte-producing command ran from `/home/oleg/prog/z_llvm` under
`/bin/bash`, sequentially, exactly once. Each invocation inherited nothing
through `/usr/bin/env -i` except:

```text
HOME=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-N/home
LANG=C
LC_ALL=C
PATH=/usr/bin:/bin
SOURCE_DATE_EPOCH=0
TMPDIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-N/tmp
TZ=UTC
ZIG_GLOBAL_CACHE_DIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-N/cache/global
ZIG_LOCAL_CACHE_DIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-N/cache/local
```

The exact commands were:

```text
/usr/bin/env -i HOME=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/home LANG=C LC_ALL=C PATH=/usr/bin:/bin SOURCE_DATE_EPOCH=0 TMPDIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/tmp TZ=UTC ZIG_GLOBAL_CACHE_DIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/cache/global ZIG_LOCAL_CACHE_DIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/cache/local ../ziglang/build/stage4/bin/zig build-obj -fllvm -flibllvm -fstrip -fno-emit-bin -femit-llvm-ir=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/output/compiler_rt_v1.ll -O ReleaseFast -target x86_64-linux-gnu -mcpu=baseline ../ziglang/lib/compiler_rt.zig

/usr/bin/env -i HOME=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/home LANG=C LC_ALL=C PATH=/usr/bin:/bin SOURCE_DATE_EPOCH=0 TMPDIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/tmp TZ=UTC ZIG_GLOBAL_CACHE_DIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/cache/global ZIG_LOCAL_CACHE_DIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/cache/local ../ziglang/build/stage4/bin/zig build-obj -fllvm -flibllvm -fstrip -fno-emit-bin -femit-llvm-ir=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/output/compiler_rt_v1.ll -O ReleaseFast -target x86_64-linux-gnu -mcpu=baseline ../ziglang/lib/compiler_rt.zig

/usr/bin/env -i HOME=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/home LANG=C LC_ALL=C PATH=/usr/bin:/bin SOURCE_DATE_EPOCH=0 TMPDIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/tmp TZ=UTC ZIG_GLOBAL_CACHE_DIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/cache/global ZIG_LOCAL_CACHE_DIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/cache/local ../ziglang/build/stage4/bin/zig build-obj -fllvm -flibllvm -fstrip -fno-emit-bin -femit-llvm-ir=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/output/compiler_rt_v1.ll -O ReleaseFast -target x86_64-linux-gnu -mcpu=baseline ../ziglang/lib/compiler_rt.zig
```

No invocation was retried, substituted, or run with an alternate flag,
binary, source, target, CPU, environment, path, or cache.

## Raw one-shot results

| Generation | Start UTC | End UTC | Duration ns | Status | Output bytes | Mode | SHA-256 |
|---|---|---|---:|---:|---:|---:|---|
| gen-1 | `2026-07-19T21:17:01,966294613+00:00` | `2026-07-19T21:17:06,445449224+00:00` | 4,477,011,535 | 0 | 1,897,410 | 664 | `9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1` |
| gen-2 | `2026-07-19T21:17:33,505009218+00:00` | `2026-07-19T21:17:38,088483150+00:00` | 4,581,134,773 | 0 | 1,897,410 | 664 | `9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1` |
| gen-3 | `2026-07-19T21:18:04,739245924+00:00` | `2026-07-19T21:18:09,268250497+00:00` | 4,527,045,980 | 0 | 1,897,410 | 664 | `9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1` |

Each output is a nonempty regular file reported by `file` as:

```text
ASCII text, with very long lines (12200)
```

For each generation:

```text
stdout_bytes=0
stdout_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
stderr_bytes=0
stderr_sha256=e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
home_regular_files=0
tmp_regular_files=0
global_cache_regular_files=547
local_cache_regular_files=267
output_regular_files=1
```

Every generation retains `command.txt`, `environment.txt`, `start.utc`,
`end.utc`, `duration.ns`, `stdout.raw`, `stderr.raw`, `exit.status`,
`output.sha256`, `output.stat`, `output.file`, and `output.bytes`. These
records were not rewritten or normalized.

## Three-way comparison

The comparison commands each ran once:

```text
/usr/bin/cmp -s tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/output/compiler_rt_v1.ll tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/output/compiler_rt_v1.ll
status=0

/usr/bin/cmp -s tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/output/compiler_rt_v1.ll tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/output/compiler_rt_v1.ll
status=0

/usr/bin/cmp -s tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/output/compiler_rt_v1.ll tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/output/compiler_rt_v1.ll
status=0
```

The output-path count is exactly 3. All three byte counts and SHA-256 values
are equal. The retained comparison records are:

```text
output_manifest_sha256=3b31168f0d293835e5dd0bd6815c73f240c3d18d3a87c7721a5f17f600fe97d1
pairwise_cmp_status_sha256=13d212ab3708905bdb0b4fc9be0543bbee8ade00c4905ec973a7069da27c244f
comparison_manifest_file_sha256=d9307a137cb7b3d045aaadb06f0890f348f325c755f642abc488da6f2de45851
reproduction_result_sha256=f529e638c2e7df8dd99a505fd31d6db487432ffe82087dca1490edb3dbc6a5a4
```

No path-, cache-, ordering-, metadata-, whitespace-, byte-count-, hash-, or
raw-byte nondeterminism was observed.

## Postflight identity verification

Postflight ran only after gen-3 and the three pairwise comparisons:

```text
zllvm_HEAD=61edd65af6a27cbc0e6452b06d001f4b2c481327
zllvm_tree=e185b672c4bed70c6666c21503c1518741200f88
zllvm_tracked_status_bytes=0
zig_HEAD=bdee02bc0c7f227c0f11bc9a449df673fe803540
zig_tree=aa032b2b82a48a4684657f909e6e270a6c925e33
zig_status_bytes=0
raw_zig_tree_manifest_stream_sha256=9c3a5ecab710fc6a76496a0bc6bb344aa4942a19c558cb5653d045c726da8818
raw_zig_tree_manifest_stream_bytes=2154652
raw_zig_tree_manifest_cmp_status=0
stage4_sha256=dcea3478273d7ffe3895709c8eed4ccc0724548869cdb86183fc7356164410b7
compiler_rt_root_sha256=388ce4e0ac6dd5a285a19c66d193d088d3515f5dd726cafc475d222cdd8b4fa0
stage4_dependencies_before_after_cmp=0
frozen_surfaces_before_after_cmp=0
candidates_reports_before_after_cmp=0
ratchet=131
adoption_path_after=absent
watcher_status=clean
stash@{0}=unchanged
```

The postflight status record SHA-256 is
`748ff5b85b311cd43cc11472501ac9a38bcf8e281b65456b9a7bd15dc1afcdaf`.
Available filesystem capacity after generation was 97,775,153,152 bytes.

## Retained ignored bundle

The ignored materialization root remains present and was not cleaned:

```text
root=tmp/inbox184_o2_compiler_rt_v1/materialize
retained_root_bytes_before_final_manifest=175520604
final_manifest_entries=2542
final_manifest=tmp/inbox184_o2_compiler_rt_v1/materialize/comparison/retained-files-final.tsv
final_manifest_sha256=885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e
directory_manifest_sha256=0bee766efb3bf586390a3ebb58c97858504d45d6a32a3703e6ea91fca208911d
```

The final manifest records mode, owner, group, byte count, SHA-256, and path
for every retained regular file that existed before the manifest itself.
The generation outputs, disjoint caches, raw logs, statuses, timings,
source/tool/dependency manifests, comparisons, and postflight records remain
available for review.

## Explicit exclusions and stop

Only the three authorized stage4 generation invocations ran. This slice did
not run or perform:

- adoption through `/usr/bin/install`, copying, renaming, normalization, or
  mode `0444`;
- retention-policy or pin edits;
- `z_llvm`, selector/report, dynamic coverage, baseline validation, or
  protocol execution;
- Zig project build/test gates or any production correctness gate;
- performance samples or A/B artifact construction;
- source, tool, test, guard, build, inventory, facade, bypass, watcher, or
  production changes;
- production call wiring, helper collapse, ratchet credit, network access,
  Git maintenance, cleanup, or `clean_tmp`;
- any retry, alternate generation, fallback candidate, or substitute.

The historical `49a19f04` report remains reference-only. No new report,
object, owner, per-function, frontier, dynamic-coverage, validation, or
performance identities are claimed.

STOP after this evidence commit for Watcher/Reviewer review. Adoption,
pinning, baseline validation, protocol execution, production wiring, credit,
and performance remain separately unauthorized.
