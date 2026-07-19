# INBOX-184 reproducible compiler-rt corpus v1 contract

## Status and disposition

This is a non-binding evidence contract. It selects Strategy C in principle:
create one new, reproducible compiler-rt corpus rather than substitute any
currently retained input for the lost historical corpus.

This document does **not** authorize or perform generation, materialization,
copying, normalization, concatenation, adoption, pinning, validation,
performance measurement, production wiring, or ratchet credit. The accepted
O2 ratchet remains **131**.

The lost historical input and its output identity remain reference-only:

```text
historical_path=tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll
historical_input_sha256=7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b
historical_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
historical_population=443/285/158
historical_first_failure=compiler_rt.trunc.truncl
disposition=reference-only; not a future input or identity
```

No candidate bytes are created by this slice. No current candidate is a
fallback.

## Inspected operating boundary

INBOX-184 was originally authorized at `82a529df`. During this evidence-only
slice, the user authorized formatting-only watcher commit `7bcb7fab`, and the
tracked operating documents reconciled that boundary at `de964aaf`. The
inspected composite boundary is:

```text
composite_HEAD=de964aaf850959cdd6339ce13f7e38399d42a511
composite_tree=cc673a7547b02117da2a9e7215f4e0c7bf3a1dfb
authorization_commit=82a529dfb3ae5e56f34c0ce413b7bf59bb52ae2f
user_infrastructure=9f84022c,5555afb6,7bcb7fab
ratchet=131
stash@{0}=On x86_64-codegen-expanded-frontier: INBOX-93 preserve B2B wiring plus five diagnosis tests
```

The watcher was not edited or staged:

```text
watcher_path=scripts/z_llvm_watcher_loop.sh
watcher_HEAD_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
watcher_index_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
watcher_worktree_blob=b64131cf60dd0ef638e815cd33db9ae8595a72cf
watcher_content_sha256=02f972ddc3ad5bf48e6f474312e7f58763b1886ff35e2c92c3902db27234fae5
watcher_status=clean
```

The previous watcher blob `75c9a932...` and the pre-commit working identity
`accca76b...` are superseded.

Frozen surfaces inspected read-only:

| Surface | SHA-256 |
|---|---|
| retention policy | `a31e3fbf7aa03c8544fc5f9921e350c25e4e470cc3c779dfb356136634e052dd` |
| retention pins | `f4374187d77ec6b7c42ee1b64538ead1a2d599697595a7f59c28b23dae5c6614` |
| cleanup tool | `8e0c54ad6fed9e46326049dbe64bff743daddcc2527c1dc4d5e02be15fba2d5e` |
| bypass TSV | `2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11` |
| 126-symbol facade manifest | `2adcd99ee3bfbe0e9f09673f1df02ab305b5ddb2c1b461023152d5d03a079c26` |
| `composed_selector_calls.zig` | `f1046632d670d61439df7252ba12a1ea474829a4b479ed7758ea4e223866cf2d` |
| `value_use/actions/calls.zig` | `ee5e8d740a42ed1165461cbf2357d63e68347534988915c7f92625cc88032ed0` |
| `value_use/model.zig` | `3bd22867b20587918132090143f407e042f32d44a3948ad3d7dc23a4cd02dfd7` |
| `value_use/core.zig` | `d0e8fe7c03120d7ad8044f575a95c71c945b4bc145c7b7b7e9d3467423a8b819` |
| value-use facade | `4f5887e9d2bce0943df26c1e08e8360053440da64eefd19ddfd9d53225dddd7a` |
| accepted INBOX-181 aggregate evidence | `358fdb7c4f2f0a60ed34d325d8a673bc6596a88d20b169dfd596ab4b485c6f82` |
| accepted INBOX-182 no-candidate audit | `4ac3e73213c9768ee4d721a8376fe8837260bfeaa64915644d5924eb9e5d285d` |
| accepted INBOX-183 design | `c72eb2671750e7e7cfebeb61efc2a4f1bdf741a86ef98d2f21ba816ca8e626f3` |

The accepted INBOX-181 aggregate remains evidence only. Ordinary
GPR/pointer direct calls and `zig.target.intByteSize` are individually and
jointly isolated, but production routing is still dormant.

## Existing candidates remain unauthorized

The four retained inputs were inspected without modification:

| ID | Path | Bytes | Mode | SHA-256 | Disposition |
|---|---|---:|---:|---|---|
| AC285 | `tmp/inbox63_accepted_cohort.ll` | 7,215,373 | `0664` | `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4` | unauthorized reference |
| R426 | `tmp/inbox178_o2_call_final_use/compiler_rt_regenerated.ll` | 6,198,914 | `0664` | `fc2f433e2106ee431285722bec533e6799748abcfe6b750acbdfb25bd5d7464f` | unauthorized reference |
| RS426 | `tmp/inbox178_o2_call_final_use/compiler_rt_regenerated_safe.ll` | 7,650,265 | `0664` | `9f8772b6c46701ace5bbaf891267f12d8e7325c07b129fc1c3cfe7390d0db88b` | unauthorized reference |
| RM438 | `tmp/inbox178_o2_call_final_use/compiler_rt_regenerated_small.ll` | 1,215,866 | `0664` | `8cc6381b35cc063e4e0cf70f0ac387c94238333b849513ed66a57a1a46a6fde8` | unauthorized reference |

None is retention-pinned. None has the complete source, compiler, command,
environment, and deterministic-reproduction manifest required below. No
current file is renamed, copied, normalized, concatenated, or treated as a
seed for v1.

## Strategy C v1 generation contract

### Stable contract and artifact identifiers

The stable contract ID is:

```text
o2-calls-compiler-rt-v1-releasefast-x86_64-linux-gnu-baseline-zig-bdee02bc
```

It is deliberately distinct from the historical input, `49a19f04`, AC285,
R426, RS426, and RM438. After three-way byte reproduction, the immutable
artifact ID is:

```text
o2-calls-compiler-rt-v1-releasefast-x86_64-linux-gnu-baseline-zig-bdee02bc-sha256-<64-lowercase-hex>
```

The placeholder may be filled only by a separately authorized
materialization task after three byte-identical generations. The contract
ID alone never identifies or authorizes candidate bytes.

### Source root, revision, and member set

The compiler source root retained by repository records is:

```text
zig_source_worktree=../ziglang
zig_source_commit=bdee02bc0c7f227c0f11bc9a449df673fe803540
compiler_rt_root=../ziglang/lib/compiler_rt.zig
```

The commit is the exact content of `docs/evidence/ziglang_pin.txt`. Its
tracked-file SHA-256 is
`addebfc419954a039711d03dac09349253522094b79824cc15db023921b62196`.

The source-provenance member set is the **entire Git tree** at that commit,
not a hand-maintained subset. A future materialization must retain the raw
NUL-delimited output of:

```text
git -C ../ziglang ls-tree -rz --full-tree bdee02bc0c7f227c0f11bc9a449df673fe803540
```

The member ordering is Git's raw tree order. Every record retains mode,
object type, object ID, and byte pathname. No pathname, line ending, mode, or
blob is normalized. Any gitlink is recorded with its exact object ID; an
unavailable required gitlink is a stop.

Before generation, the future task must prove:

```text
git -C ../ziglang rev-parse HEAD^{commit}
  == bdee02bc0c7f227c0f11bc9a449df673fe803540
git -C ../ziglang status --porcelain=v1 -z --untracked-files=all
  == empty
```

It must also record `HEAD^{tree}` and the SHA-256 and byte count of the raw
tree manifest. The tree hash is intentionally not inferred in this
evidence-only slice.

The semantic inclusion rule is the pinned Zig compiler's complete import
and code-generation closure rooted at `lib/compiler_rt.zig` for the target,
CPU, and mode below. The entire pinned Zig tree is the provenance boundary,
so an indirect import from `lib/std`, generated compiler knowledge, or
another tracked path cannot escape source accounting. There is exactly one
root compilation unit.

There is **no source-member concatenation** and no post-export linking,
sorting, reduction, extraction, or cohort selection. The compiler decides
semantic declaration order under the pinned source and binary. The emitted
module is accepted only as raw bytes.

### Compiler and exporter identities

The sole compiler/exporter executable is:

```text
../ziglang/build/stage4/bin/zig
```

LLVM-IR export is the pinned stage4 compiler's embedded LLVM backend. There
is no second exporter executable and no `z_llvm` transformation in corpus
generation.

Retained repository sources establish the command shape:

| Retained source | SHA-256 | Relevance |
|---|---|---|
| `tools/capture_zig_ir.zig` | `07a52fcb8b329d4a5b2d512af64b1a2e4751fe9f263441492807e412976f334c` | authoritative `build-obj`, LLVM-IR, strip, target, mode, and raw-output capture shape |
| `tools/check_zig_stage4_emitter.zig` | `0aa360afff894a4e3cc3eacdd8d531658eb39c211c93ce7ee408f75ccd1e50b9` | retained pin/version relationship |
| `tools/run_abi_differential.sh` | `f508dafe0bd6b71917999e72c62bf942c889e7a02d507a6b566d3ebdefcd3371` | retained explicit `-mcpu=<cpu>` compiler-rt capture precedent |
| `src/distribution_zig_air_inventory.zig` | `76e654e1568d05c7e751f3e67edca63f68fd2a47a865b3f7b12c54ad04262f7a` | retained proof that `lib/compiler_rt.zig` is a standalone release-mode root |
| `build.zig` | `051381dcd4811460c39c19a0b902deedd69b5722bac15698c8146f5b32b122ff` | retained capture-step registration |

The v1 generation calls stage4 directly. This avoids adding the unrelated
host Zig binary and build-runner cache to the byte-producing command.

Before generation, a future task must record and freeze:

- stage4 executable SHA-256, byte count, mode, and `zig version` bytes;
- proof that `zig version` contains the pinned commit prefix;
- the pinned Zig Git commit and tree;
- whether stage4 is dynamically linked, and the path, SHA-256, and byte
  count of every resolved dynamic dependency if any;
- the exact identities of `git`, `env`, `sha256sum`, `stat`, and `cmp` used
  for provenance and comparison;
- kernel, architecture, filesystem, and process-environment manifest.

Any source/binary mismatch, missing binary, missing dependency, dirty Zig
tree, or inability to record an exact identity is a stop. A version prefix
without the full binary hash is insufficient.

### Mode, target, CPU/features, flags, and output

The v1 compiler contract is:

```text
root=../ziglang/lib/compiler_rt.zig
mode=ReleaseFast
target=x86_64-linux-gnu
cpu=baseline
feature_additions=none
feature_subtractions=none
backend=LLVM
strip=true
emit_binary=false
output=raw textual LLVM IR
module_count=1
```

The complete ordered compiler argument vector is:

```text
../ziglang/build/stage4/bin/zig
build-obj
-fllvm
-flibllvm
-fstrip
-fno-emit-bin
-femit-llvm-ir=<generation-specific-output>
-O
ReleaseFast
-target
x86_64-linux-gnu
-mcpu=baseline
../ziglang/lib/compiler_rt.zig
```

There are no additional compiler arguments. In particular, there is no
native CPU selection, LTO override, debug-path rewrite, IR pass,
normalizer, reducer, function filter, linker, selector, or `z_llvm` step.
Pinned compiler defaults for unmentioned options are part of the pinned
binary identity.

The generated file is the compiler's raw textual LLVM IR byte stream,
including its original declaration order, metadata order, whitespace,
comments, paths, and final newline behavior. No normalization is permitted.
The output files from independent runs are compared byte-for-byte; differing
but semantically equivalent LLVM IR is a failure.

### Environment and cache policy

Each generation uses an empty inherited environment via `/usr/bin/env -i`
and exactly this allowlist:

```text
HOME=<generation-root>/home
LANG=C
LC_ALL=C
PATH=/usr/bin:/bin
SOURCE_DATE_EPOCH=0
TMPDIR=<generation-root>/tmp
TZ=UTC
ZIG_GLOBAL_CACHE_DIR=<generation-root>/cache/global
ZIG_LOCAL_CACHE_DIR=<generation-root>/cache/local
```

No proxy, network, compiler, linker, package-manager, user cache, or host CPU
variable is inherited. Network access is forbidden.

Generations 1, 2, and 3 have disjoint, initially absent home, temporary,
local-cache, global-cache, output, and log directories. A cache directory is
never shared or warmed between generations. The source tree and stage4
binary are the same read-only identified inputs for all three runs.

If stage4 cannot run under this exact allowlist, the contract stops for
review. The future worker may not add an environment variable, share a
cache, or fall back to ambient defaults.

### Exact future generation locations and commands

The separately authorized materialization root is:

```text
tmp/inbox184_o2_compiler_rt_v1/materialize
```

It must not exist before the materialization task starts. That task creates
only:

```text
tmp/inbox184_o2_compiler_rt_v1/materialize/source/
tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/
tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/
tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/
tmp/inbox184_o2_compiler_rt_v1/materialize/comparison/
```

The future task must run these setup commands from the z_llvm repository
root, after confirming the root does not exist:

```text
test ! -e tmp/inbox184_o2_compiler_rt_v1/materialize
mkdir -p tmp/inbox184_o2_compiler_rt_v1/materialize/source
mkdir -p tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/home tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/tmp tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/cache/global tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/cache/local tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/output tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/logs
mkdir -p tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/home tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/tmp tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/cache/global tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/cache/local tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/output tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/logs
mkdir -p tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/home tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/tmp tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/cache/global tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/cache/local tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/output tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/logs
mkdir -p tmp/inbox184_o2_compiler_rt_v1/materialize/comparison
git -C ../ziglang ls-tree -rz --full-tree bdee02bc0c7f227c0f11bc9a449df673fe803540 > tmp/inbox184_o2_compiler_rt_v1/materialize/source/zig-tree.nul
```

The three byte-producing commands, run from the z_llvm repository root, are
exactly:

```text
/usr/bin/env -i HOME=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/home LANG=C LC_ALL=C PATH=/usr/bin:/bin SOURCE_DATE_EPOCH=0 TMPDIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/tmp TZ=UTC ZIG_GLOBAL_CACHE_DIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/cache/global ZIG_LOCAL_CACHE_DIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/cache/local ../ziglang/build/stage4/bin/zig build-obj -fllvm -flibllvm -fstrip -fno-emit-bin -femit-llvm-ir=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/output/compiler_rt_v1.ll -O ReleaseFast -target x86_64-linux-gnu -mcpu=baseline ../ziglang/lib/compiler_rt.zig

/usr/bin/env -i HOME=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/home LANG=C LC_ALL=C PATH=/usr/bin:/bin SOURCE_DATE_EPOCH=0 TMPDIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/tmp TZ=UTC ZIG_GLOBAL_CACHE_DIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/cache/global ZIG_LOCAL_CACHE_DIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/cache/local ../ziglang/build/stage4/bin/zig build-obj -fllvm -flibllvm -fstrip -fno-emit-bin -femit-llvm-ir=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-2/output/compiler_rt_v1.ll -O ReleaseFast -target x86_64-linux-gnu -mcpu=baseline ../ziglang/lib/compiler_rt.zig

/usr/bin/env -i HOME=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/home LANG=C LC_ALL=C PATH=/usr/bin:/bin SOURCE_DATE_EPOCH=0 TMPDIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/tmp TZ=UTC ZIG_GLOBAL_CACHE_DIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/cache/global ZIG_LOCAL_CACHE_DIR=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/cache/local ../ziglang/build/stage4/bin/zig build-obj -fllvm -flibllvm -fstrip -fno-emit-bin -femit-llvm-ir=tmp/inbox184_o2_compiler_rt_v1/materialize/gen-3/output/compiler_rt_v1.ll -O ReleaseFast -target x86_64-linux-gnu -mcpu=baseline ../ziglang/lib/compiler_rt.zig
```

Standard output and standard error for each invocation must be retained
separately without rewriting. The future task must record the exact shell,
working-directory bytes, umask, start/end status, and command line alongside
each log.

No command in this section ran during INBOX-184.

## Missing prerequisites: fail closed

The following values or capabilities are deliberately unresolved now:

1. the pinned Zig commit's exact tree hash and raw tree-manifest hash;
2. current local availability and cleanliness of that exact source tree;
3. stage4 binary SHA-256, byte count, mode, version bytes, and dependency
   identities;
4. proof that the exact environment allowlist and `-mcpu=baseline` command
   successfully emit the standalone compiler-rt root;
5. the three output byte counts and SHA-256 values;
6. the final candidate input SHA-256 and artifact ID;
7. candidate-specific report, object, owner, ledger, per-function, and
   frontier identities;
8. the exact guard-confined dynamic-coverage counter patch and its source
   hash;
9. an authorized retention location and pin for the complete bundle;
10. sufficient retained capacity for source, binary, three generation
    records, validation records, and the adopted input.

These are future proof obligations, not blanks that may be inferred from
R426, RS426, RM438, AC285, filenames, historical output identities, or
ambient tools. Any unavailable prerequisite stops the corresponding future
stage. No existing candidate may be substituted.

## Separately authorized three-generation materialization

A future materialization task is reversible and additive:

1. Verify the accepted contract document and its commit.
2. Verify the materialization root and final adoption path do not exist.
3. Capture the exact source-tree, stage4, dependency, host-tool, environment,
   and filesystem manifests before generation.
4. Create the three disjoint generation roots and their empty cache,
   temporary, home, output, and log directories.
5. Execute generations 1, 2, and 3 sequentially with the exact commands
   above. No failed run is retried.
6. Retain for each run its command, environment, exit status, stdout,
   stderr, source/tool manifest, output byte count, output mode, and output
   SHA-256.
7. Require successful exit, a nonempty regular output file, equal byte
   counts, equal SHA-256 values, and pairwise raw `cmp` equality for all
   three outputs.
8. Treat path-dependent, cache-dependent, order-dependent, metadata-only, or
   whitespace-only differences as nondeterminism and stop.
9. Only after all three outputs are identical may a separately authorized
   adoption step copy generation 1's exact bytes to:

   ```text
   tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll
   ```

   The future adoption command is exactly:

   ```text
   /usr/bin/install -D -m 0444 tmp/inbox184_o2_compiler_rt_v1/materialize/gen-1/output/compiler_rt_v1.ll tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll
   ```

10. The adopted file must be mode `0444`, must retain the same byte count and
    SHA-256, and must be accompanied by the finalized artifact ID and the
    complete reproduction bundle.
11. Add an explicit retention pin only under retention-policy authority.
12. Stop for validation review. Materialization grants no protocol adoption,
    production wiring, performance run, or ratchet credit.

Reversibility is bounded to paths and pin rows created by that future
directive. It may not overwrite or delete existing candidates or retained
evidence. On failure, no candidate is adopted; diagnostic generation roots
remain retained for review unless a later directive explicitly authorizes
their removal.

## Later ratchet-131 baseline validation

Baseline validation is a separate authorization after materialization and
pinning. It runs on the accepted ratchet-131 production source with ordinary
and `intByteSize` routing still dormant.

### Three non-timing output repetitions

Using one immutable ratchet-131 `z_llvm` artifact and the exact adopted v1
input, perform three independent non-timing repetitions. Each repetition
must retain:

- exact input and `z_llvm` artifact identities;
- exact command and environment;
- exit status;
- complete report bytes, population, first failure, and SHA-256;
- emitted object bytes and SHA-256;
- owner-manifest bytes, owner ledger, and SHA-256;
- per-function object bytes and disassembly;
- a sorted per-function identity manifest and its SHA-256;
- candidate-specific frontier rows and proof;
- stdout and stderr bytes for every command.

All three repetitions must be byte-identical in every output above. A stable
population with differing bytes is a failure.

The report command shape remains:

```text
LC_ALL=C <immutable-ratchet-131-z_llvm> --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/o2_calls_perf/compiler_rt_v1/compiler_rt_v1.ll > /dev/null 2> <repeat>/report.log
```

Object, owner, disassembly, and per-function commands must be frozen
verbatim in that future directive before execution, using the accepted
INBOX-181 procedure as provenance. They may not be improvised after seeing
the first output.

Newly named identities must use the v1 artifact ID, for example:

```text
o2_calls_crt_v1_r131_input_sha256
o2_calls_crt_v1_r131_report_sha256
o2_calls_crt_v1_r131_report_population
o2_calls_crt_v1_r131_object_sha256
o2_calls_crt_v1_r131_owner_sha256
o2_calls_crt_v1_r131_owner_ledger
o2_calls_crt_v1_r131_per_function_manifest_sha256
o2_calls_crt_v1_r131_frontier_manifest_sha256
```

None may be called `49a19f04`, `061a64e4`, or `5d91960e` merely because a
historical workflow used those names. A coincidental byte hash is recorded
as an observation, not treated as inherited acceptance.

### Dynamic coverage of both accepted call routes

The same future validation must prove nonzero dynamic execution of:

```text
ordinary GPR/pointer DirectCallAction
zig.target.intByteSize IntByteSizeCallAction
```

Static IR lines, classifier matches, and accepted INBOX-181 isolation are
supporting evidence but not dynamic coverage.

The observation layer must be guard-confined and procedural. It may count
only the exact accepted action tags and lifecycle boundaries. It may not
change classifier decisions, request construction, action attachment,
staging, instructions, diagnostics, output, or fallback behavior.

Because production is still dormant at ratchet 131, the future directive
must separately authorize a hash-frozen validation-only aggregate consumer
derived from the accepted INBOX-181 lifecycle. The observer is added to that
already reviewed validation routing; the observer itself cannot change
routing. The validation tree claims no production wiring or ratchet credit.

Retained coverage evidence must include:

- exact baseline, validation-consumer, observer, and guard patches;
- exact source hashes before, during, and after;
- nonzero per-family action counts;
- per-family request and argument-stage counts;
- transaction, snapshot, and complete-action counts;
- proof that only the two accepted families entered the validation route;
- identical semantic outputs with and without observation;
- exact restoration to the ratchet-131 source tree.

Any zero family count, unexpected family count, output movement, guard
failure, or restoration mismatch stops validation.

### Immutable validation and reproduction bundle

Before any A/B comparison, retention authority must protect:

- the read-only adopted input;
- the accepted contract and materialization commits;
- the full pinned Zig source tree identity and raw tree manifest;
- the exact stage4 binary and every required dynamic dependency;
- all three generation commands, environments, logs, outputs, hashes, and
  comparisons;
- the final candidate ID and input identity;
- the immutable ratchet-131 `z_llvm` artifact;
- all three repeated report/object/owner/per-function outputs;
- the dynamic two-route coverage patch, counters, logs, and restoration
  proof;
- an exact offline reproduction procedure;
- explicit retention-policy and pin rows.

If any item cannot be retained immutably and protected from cleanup, the
protocol cannot proceed.

## Frozen future A/B performance contract

After separate validation acceptance and separate combined production
wiring authorization, the standing performance contract remains unchanged:

1. A and B use the same exact accepted v1 input bytes, input hash, command,
   target, CPU pin, environment, cache policy, and output validation.
2. A and B are built in detached worktrees only after each complete source
   tree and commit is final.
3. Both `z_llvm` artifacts are immutable mode `0555` before timing.
4. The machine passes the idle-machine preflight.
5. Exactly two warmups per artifact are discarded.
6. Timed runs are six pairs in exactly `AB, BA, AB, BA, AB, BA` order.
7. Every sample is retained; there is no outlier removal.
8. There is no discretionary rerun.
9. `median(B) - median(A) <= max(median(A) * 5%, 100 ms)`.
10. Median paired ratio `B/A <= 1.05`.
11. `max_rss(B) - max_rss(A) <= 16 MiB`.
12. Every sample validates the exact input, artifact, exit status, and all
    newly accepted candidate-specific output identities.
13. Any failed validation, machine activity, contamination, nonstationarity,
    or threshold failure stops for review.

The A artifact is the accepted ratchet-131 baseline. B is frozen only after
the complete combined production source, guard, evidence, and production
commit are final. Generation and baseline-validation runs are never timing
samples.

## Fail-closed stops

Every future stage stops without fallback on:

- missing, dirty, ambiguous, or wrong source revision or tree;
- unavailable source objects, gitlinks, stage4 binary, binary dependency, or
  comparison tool;
- source-member, command, mode, target, CPU, feature, flag, environment, or
  cache ambiguity;
- need for an unlisted environment value or command flag;
- preexisting output/materialization/adoption paths;
- generation failure or any output-byte, byte-count, or SHA-256 difference;
- path-, cache-, metadata-, order-, or whitespace-dependent output;
- report, object, owner, ledger, per-function, frontier, or exit-status
  divergence across baseline repetitions;
- missing or zero dynamic coverage for either accepted call route;
- observation changing routing, output, diagnostics, or accepted source;
- incomplete restoration of temporary validation source;
- inability to make and retain the complete immutable bundle;
- retention-pin or headroom failure;
- any attempt to substitute AC285, R426, RS426, RM438, the historical report,
  or another unreviewed input.

There is no automatic protocol amendment, regeneration, alternate mode,
alternate candidate, fix-forward, threshold change, or rerun.

## Future authorization boundaries

The stages are separate and ordered:

1. **Contract acceptance.** Accept or reject this non-binding v1 contract.
2. **Materialization/reproduction.** Verify prerequisites and perform the
   three independent generations; no validation or wiring.
3. **Ratchet-131 baseline validation.** Establish new repeated identities,
   dynamic route coverage, restoration, and immutable retention.
4. **Validation acceptance.** User and Reviewer accept or reject the complete
   bundle and new identities.
5. **Combined production wiring.** Only after acceptance, wire the already
   isolated ordinary plus `intByteSize` aggregate, run the full authorized
   correctness gates, and perform the final owner recount. The sole
   conditional textual credit remains `131 -> 130` for the exact
   `intByteSize` gateway; ordinary is a zero-count semantic migration and no
   helper-collapse credit is assumed.
6. **Post-final-tree performance.** Freeze B only after the final production
   commit and execute the unchanged counterbalanced protocol.

Completion of one stage grants no authority for the next.

## INBOX-184 execution boundary

Only read-only repository inspection commands were used to prepare this
contract:

```text
sed -n ...
rg -n ...
rg --files ...
git status --short
git rev-parse ...
git log ...
git show --stat ...
git stash list
git hash-object ...
git ls-files -s ...
stat -c ...
sha256sum ...
```

No project code, `z_llvm`, Zig command, generation, materialization,
pinning, selector/report, correctness gate, performance command, network
operation, Git maintenance, cleanup, `clean_tmp`, candidate execution,
protocol execution, production wiring, or ratchet credit ran. No source,
tool, test, guard, build, inventory, retention, candidate, report, or
watcher file changed.

## Stop

Strategy C is selected in principle only. Ratchet 131, production routing,
the bypass inventory, facade, retention policy and pins, candidates,
historical evidence, watcher, and stash remain unchanged.

STOP for Watcher/Reviewer acceptance before generation, materialization,
copying, adoption, pinning, validation, protocol execution, production
wiring, ratchet credit, or performance measurement.
