# INBOX-183 calls performance-protocol amendment design

## Status

This is a non-binding evidence design. It does not select a replacement
input, amend the performance protocol, authorize materialization or pinning,
validate a baseline, authorize production wiring, or grant ratchet credit.

The exact historical input remains absent:

```text
historical_path=tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll
historical_input_sha256=7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b
historical_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
historical_population=443/285/158
ratchet=131 unchanged
```

INBOX-182 exhaustively found no repository-local copy. It did not prove that
the input cannot exist externally. External recovery, replacement-input
selection, and protocol amendment remain separate decisions.

## Frozen starting state

The operating authorization is commit
`cdae254395c2e645ce4cbd965fbfd449642ce453`, tree
`6b94aae6ac75e30b1dd3e111c574c8376cd05328`. The worktree was clean and
`stash@{0}` remained:

```text
On x86_64-codegen-expanded-frontier: INBOX-93 preserve B2B wiring plus five diagnosis tests
```

Frozen surfaces checked before this design:

| Surface | SHA-256 or Git blob |
|---|---|
| watcher HEAD/index/worktree | Git blob `8f3be1dd08dadc6f42ede169ca05e84daae773ab` |
| watcher content | `ac1d08eed3aadc8ed9ccf7afb5df93889630c95a68e7fe594aba67a760a89dd7` |
| retention policy | `a31e3fbf7aa03c8544fc5f9921e350c25e4e470cc3c779dfb356136634e052dd` |
| retention pins | `f4374187d77ec6b7c42ee1b64538ead1a2d599697595a7f59c28b23dae5c6614` |
| cleanup tool | `8e0c54ad6fed9e46326049dbe64bff743daddcc2527c1dc4d5e02be15fba2d5e` |
| bypass TSV | `2d6c8c8819c4b0dff10b9d803a62125d7c46155c04a2c2cf2006f2aecffd8b11` |
| facade manifest | `2adcd99ee3bfbe0e9f09673f1df02ab305b5ddb2c1b461023152d5d03a079c26` |
| accepted INBOX-181 evidence | `358fdb7c4f2f0a60ed34d325d8a673bc6596a88d20b169dfd596ab4b485c6f82` |
| accepted INBOX-182 evidence | `4ac3e73213c9768ee4d721a8376fe8837260bfeaa64915644d5924eb9e5d285d` |

Production call routing remains dormant. The accepted ordinary GPR/pointer
and `zig.target.intByteSize` aggregate isolation remains evidence only.

## Measurement purpose versus historical identity

The calls performance gate has two independent concerns:

1. **Measurement invariants.** It detects incremental wall-time and
   resident-memory cost caused by the combined production wiring while input,
   environment, artifact construction, sample ordering, and validation are
   held constant.
2. **Workload identity.** The exact input bytes determine which selector
   paths execute and how often. Replacing those bytes changes the workload
   and therefore changes the baseline report/object/owner identities.

The first concern survives loss of the historical file. The second does not.
`49a19f04` is a historical report-output identity, not an input identity and
not permission to call a different input equivalent. A future amendment
would establish a new workload and new baseline identities; it must not
reuse `49a19f04` as its acceptance name.

Performance does not replace correctness validation. The performance gate
measures overhead only after the candidate workload, both accepted call
routes, and the complete production change have separately passed their
authorized correctness contracts.

## Existing candidate foundations

Every option below is currently unauthorized. The file modes and timestamps
are observations, not retention guarantees.

| ID | Existing path | Bytes | SHA-256 |
|---|---|---:|---|
| AC285 | `tmp/inbox63_accepted_cohort.ll` | 7,215,373 | `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4` |
| R426 | `tmp/inbox178_o2_call_final_use/compiler_rt_regenerated.ll` | 6,198,914 | `fc2f433e2106ee431285722bec533e6799748abcfe6b750acbdfb25bd5d7464f` |
| RS426 | `tmp/inbox178_o2_call_final_use/compiler_rt_regenerated_safe.ll` | 7,650,265 | `9f8772b6c46701ace5bbaf891267f12d8e7325c07b129fc1c3cfe7390d0db88b` |
| RM438 | `tmp/inbox178_o2_call_final_use/compiler_rt_regenerated_small.ll` | 1,215,866 | `8cc6381b35cc063e4e0cf70f0ac387c94238333b849513ed66a57a1a46a6fde8` |

No row exists in `docs/evidence/tmp_retention_pins.tsv` for any candidate.
All four are retained `tmp` files without a current immutable pin. A
documentation reference does not provide retention.

INBOX-182 found other `.ll` files and historical different-hash capture
references, but no additional option has both a current exact path/hash and
retained evidence tying it to a compiler-rt selector population/report.
Absent `7be46e0b...` and `3575879c...` captures therefore are not current
candidate foundations, and unrelated retained IR files are not promoted
merely because they exist.

### Retained report facts

The following are historical, retained results. They were not rerun:

| ID | Retained report | Report SHA-256 | Selected/emitted/failed | First failure |
|---|---|---|---:|---|
| AC285 | `tmp/inbox178_o2_call_final_use/validation/fresh_full_report.log` | `8605d5b68c88c21d3e9df6fd70a3ca16c9f0a4b55a4ed327d9ce7801cdeb635c` | `285/285/0` | none |
| R426 | `tmp/inbox178_o2_call_final_use/validation/fresh_full_report_regenerated.log` | `6df127fc1d08158b91c79fbb5906628c5947b9af87147d91280f137628a095b0` | `426/233/193` | `compiler_rt.__memset` |
| RS426 | `tmp/inbox178_o2_call_final_use/validation/report_safe.log` | `17d9d2839d862b337361f261edd1f0bfca95fe845c5c33f0b4004f7c93326aa6` | `426/168/258` | `compiler_rt.__negsi2` |
| RM438 | `tmp/inbox178_o2_call_final_use/validation/report_small.log` | `7ac0bb6f23ad7b892edf523a201ff5deb76da5885dbeba5b5e493746bc4707b2` | `438/223/215` | `compiler_rt.bcmp` |

None has the historical `443/285/158` population. These reports support
static comparison only; none is adopted as a future baseline identity.

### Static call-family evidence

Read-only textual inspection proves that all four IR files contain both
relevant semantic shapes:

| ID | Textual `zig.target.intByteSize` call lines | Textual nonnull-pointer `compiler_rt.int.__udivmoddi4` call lines |
|---|---:|---:|
| AC285 | 46 | 2 |
| R426 | 24 | 2 |
| RS426 | 24 | 2 |
| RM438 | 24 | 2 |

For AC285 only, the retained INBOX-173 selected-composed-function census
narrows those static forms to:

```text
ordinary GPR/pointer direct calls=2
ordinary named argument uses=6
zig.target.intByteSize calls=12
zig.target.intByteSize named i16 argument uses=12
```

The two ordinary calls are the nonnull-pointer `__udivmoddi4` calls in
`compiler_rt.int.__umoddi3` and `compiler_rt.int.__moddi3`. Static presence
does not prove that a timing run executes an accepted `DirectCallAction` or
`IntByteSizeCallAction`, nor does it prove transaction counts or relative
weight. No dynamic coverage is inferred here.

### AC285 — retained accepted-cohort foundation

Retained strengths:

- exact input hash and bytes exist;
- it has a long accepted-history record;
- retained output proves `285/285/0`;
- accepted-cohort object and owner projections historically reproduce
  `061a64e4...` and `5d91960e...`;
- INBOX-173 provides an accepted static census for both call families.

Provenance gaps:

- no retained manifest binds the exact AC285 bytes to a complete generation
  command, source-member list/order, tool binary, and environment;
- retained full-mode export cache metadata records Zig pin
  `bdee02bc0c7f227c0f11bc9a449df673fe803540`, exporter state
  `3553582a0269368c84c6bbb3273c28fc307c7edcde0a02096d57f9fdeb1451de`,
  and ReleaseSafe/ReleaseSmall/ReleaseFast descriptors, but does not prove
  that exact combination and ordering generated the AC285 file;
- the current file is not retention-pinned.

Representativeness risks:

- it contains only the 285 already accepted functions, omitting the
  historical 158 failing rows;
- its `285/285/0` report path and workload mix differ materially from the
  lost report-all workload;
- static route presence is known, but dynamic route execution and counts are
  not.

Required future authority: explicit user/Reviewer selection of AC285 as a
new protocol foundation, followed by a separate materialization/pinning and
baseline-validation task. That task must reproduce the exact
`d8da86ca...` bytes from a complete manifest or reject the option.

### R426 — retained general regeneration

Retained strengths:

- exact current bytes and hash exist;
- retained report proves `426/233/193`;
- static IR contains both call-family shapes.

Provenance gaps:

- retained evidence calls it a local regeneration but records no creation
  command, exact source revision, tool binary, full flags, or environment;
- no object/owner baseline identity or selected-route census is frozen for
  this candidate;
- it is not retention-pinned.

Representativeness risks:

- it selects 17 fewer functions than the historical population and emits 52
  fewer;
- its first failure and failure mix differ;
- static call lines do not establish dynamic route counts.

Required future authority: explicit selection plus a separately authorized
task that reconstructs and proves the complete R426 generation manifest,
reproduces exact `fc2f433e...` bytes, pins them, and executes the common
baseline-validation contract below. Failure to reproduce the exact bytes
rejects this option.

### RS426 — retained “safe” regeneration

Retained strengths:

- exact current bytes and hash exist;
- retained report proves `426/168/258`;
- static IR contains both call-family shapes.

Provenance gaps:

- the filename suggests a mode, but no retained manifest proves its exact
  source/tool/mode/flag chain;
- no candidate-specific object/owner identity or selected-route census is
  frozen;
- it is not retention-pinned.

Representativeness risks:

- only 168 functions emit, 117 fewer than the historical emitted population;
- the failure distribution and first failure differ substantially;
- the workload may overweight early rejection rather than complete call
  lowering;
- dynamic route coverage is unproven.

Required future authority: explicit selection and a separate task proving
the exact generation manifest and exact `9f8772b6...` reproduction, then
pinning and common baseline validation. The mode name alone is not
provenance.

### RM438 — retained “small” regeneration

Retained strengths:

- exact current bytes and hash exist;
- its selected count, 438, is the closest retained count to 443;
- retained report proves `438/223/215`;
- static IR contains both call-family shapes.

Provenance gaps:

- the filename does not prove a ReleaseSmall source/tool/flag chain;
- no candidate-specific object/owner identity or selected-route census is
  frozen;
- it is not retention-pinned.

Representativeness risks:

- closeness of selected count does not imply similar function membership,
  instruction mix, action counts, or performance weight;
- it emits 62 fewer functions than the historical input and has a different
  first failure;
- its much smaller byte size reflects a materially different IR form;
- dynamic route coverage is unproven.

Required future authority: explicit selection and a separate task proving
the exact generation manifest and exact `8cc6381b...` reproduction, then
pinning and common baseline validation. Population proximity alone cannot
authorize it.

## Common future ratchet-131 baseline-validation contract

Every option must pass the following separately authorized stage on the
accepted ratchet-131 source tree before any A/B comparison.

### 1. Exact input and generation provenance

The future task must:

- freeze an exact candidate path, byte count, SHA-256, file mode, and
  immutable candidate ID;
- retain a complete source-member manifest, ordering rule, source revisions,
  compiler/exporter binary hashes, build modes, target/CPU/features, all
  flags, environment inputs, and exact generation command;
- regenerate the bytes from that manifest and prove exact equality to the
  selected candidate;
- fail closed if the exact bytes cannot be reproduced;
- add an explicitly authorized retention pin and reproducibility bundle
  before performance sampling.

No existing option currently satisfies this requirement.

### 2. Deterministic baseline outputs

Using immutable ratchet-131 artifacts, the future validation must perform a
Reviewer-approved repeated-output check. The amendment must freeze the
repeat count; this design proposes three independent, non-timing
invocations. All repetitions must have identical:

- input hash and artifact hash;
- exit status;
- report bytes, population, first failure, and report SHA-256;
- object bytes and object SHA-256;
- owner-manifest bytes, ledger, and owner SHA-256;
- per-function bytes/disassembly and any frozen frontier proof.

The candidate-specific identities must be named, for example:

```text
calls_perf_<candidate>_r131_input_sha256
calls_perf_<candidate>_r131_report_sha256
calls_perf_<candidate>_r131_object_sha256
calls_perf_<candidate>_r131_owner_sha256
calls_perf_<candidate>_r131_owner_ledger
calls_perf_<candidate>_r131_per_function_manifest_sha256
```

The report identity must be newly established for that candidate and must
not be named or accepted as `49a19f04`. Existing object/owner hashes are
historical references only until this candidate-specific repetition stage
establishes its own named identities.

### 3. Verified dynamic coverage of both accepted routes

The future validation must prove nonzero dynamic encounters for:

```text
ordinary GPR/pointer DirectCallAction family
zig.target.intByteSize IntByteSizeCallAction family
```

The exact coverage mechanism and counters require Reviewer/user acceptance.
A sufficient design is:

1. a guard-confined procedural census on the ratchet-131 baseline that
   counts the frozen semantic classifiers without changing production
   output; and
2. a separately bounded validation artifact using the already accepted
   aggregate lifecycle to prove nonzero transaction/action execution for
   each family, with source-order argument-stage counts and no other call
   family admitted.

Both logs, exact commands, source/artifact hashes, per-family counts, and
restoration proof must be retained. Static IR call lines are not a substitute
for these dynamic proofs. The validation must not claim production wiring or
ratchet credit.

### 4. Immutable retention and reproducibility

Before A/B comparison, the accepted validation bundle must include:

- the pinned exact input;
- generation sources or immutable source identities;
- generator/tool artifacts and hashes;
- the exact generation command and environment manifest;
- repeated-output logs and newly named baseline identities;
- dynamic route-coverage logs;
- retention-policy authorization and protection against cleanup;
- a read-only reproduction procedure with a fail-closed hash check.

Validation acceptance is a separate review event. Merely completing the
task does not authorize wiring.

## Frozen future A/B measurement invariants

Any future amended calls performance gate retains all standing invariants:

1. A and B use the same exact accepted input bytes, input hash, command,
   target, CPU pin, environment, cache policy, and output validation.
2. A and B artifacts are built in detached worktrees only after their
   respective source trees and commits are final.
3. Both artifacts are immutable mode 0555 before any timing.
4. The machine must pass an idle-machine preflight.
5. Exactly two warmups per artifact are discarded.
6. Timed runs are exactly six counterbalanced pairs:
   `AB, BA, AB, BA, AB, BA`.
7. Every timed sample is retained; there is no outlier removal.
8. There is no discretionary rerun.
9. Median wall-time delta must be no greater than
   `max(A_median * 5%, 100 ms)`.
10. Median of paired ratios `B/A` must be no greater than `1.05`.
11. Maximum-RSS increase must be no greater than 16 MiB.
12. Every sample must validate the exact candidate input, artifact, exit
    status, and newly accepted candidate-specific output identity.
13. Any failed or contaminated batch stops for review.

The A artifact is the accepted ratchet-131 baseline artifact. B may be
frozen only after the combined production wiring tree, guards, evidence,
and production commit are final. Baseline-validation runs are not timing
samples and cannot be reused as A/B samples.

## Required future decision sequence

The stages are deliberately separate and none is authorized here.

### Stage 1 — material protocol decision

The user and Reviewer choose one exact input foundation, or choose external
recovery instead, and explicitly accept a performance-protocol amendment.
The decision freezes the new input/provenance/coverage/identity contract and
the deterministic-repeat count. Until this acceptance, every candidate is
unauthorized.

### Stage 2 — materialization, pinning, and baseline validation

A new bounded directive authorizes only:

- exact candidate materialization or adoption;
- complete generation/source/tool provenance;
- deterministic reproduction and repeated outputs;
- dynamic coverage of both accepted routes;
- candidate-specific report/object/owner/per-function identities;
- retention pinning and reproducibility evidence.

It runs on the accepted ratchet-131 tree and stops for review. It grants no
production wiring or ratchet credit.

### Stage 3 — validation acceptance

The user and Reviewer accept or reject the Stage-2 bundle and its newly
named identities. Rejection returns to Stage 1; it does not permit an
unreviewed alternate candidate or rerun.

### Stage 4 — combined production wiring

Only after Stage-3 acceptance may a separate directive wire the already
accepted ordinary plus `intByteSize` aggregate. It must:

- retain all other call families on legacy paths;
- run the complete exact correctness gates specified by that directive,
  including candidate-specific report/object/owner/per-function identities,
  unit, source guard, focused canaries, ABI, integrated executable,
  strengthened Tier 2, and frontier proofs;
- perform the final production-owner recount;
- claim zero textual credit for ordinary semantic ownership;
- claim the sole conditional direct credit for `intByteSize`,
  `131 -> 130`, only if the exact gateway is removed;
- claim no helper-collapse credit;
- freeze the final B artifact only after the complete production tree and
  commit are final;
- run the amended post-final-tree A/B protocol above.

Any identity, correctness, performance, contamination, owner-recount, or
ratchet discrepancy stops without fix-forward or discretionary rerun.

## Material acceptance-gate changes requiring user authorization

Each of the following changes is material and cannot be inferred from this
plan:

1. choosing a repository-local candidate or choosing external recovery;
2. replacing the historical input path/hash and workload population;
3. accepting a generation/source/tool provenance standard for the new input;
4. authorizing generation, materialization, copying, normalization, or
   pinning of candidate bytes;
5. changing retention policy/pins or creating a reproducibility bundle;
6. defining and authorizing the dynamic two-route coverage mechanism and
   required counts;
7. freezing the deterministic-repeat count;
8. adopting new report/object/owner/per-function identity names and values;
9. retiring `49a19f04` from the calls performance acceptance basis while
   retaining it as historical evidence;
10. accepting the new baseline-validation bundle;
11. authorizing the combined production wiring and conditional
    `131 -> 130` credit;
12. accepting the amended post-final-tree performance result.

Thresholds, counterbalancing, warmups, immutable artifacts, per-sample
validation, contamination stop, and no-rerun rules are not proposed for
relaxation.

## Comparison and non-recommendation

No candidate can be recommended for protocol adoption from retained evidence
alone:

- AC285 has the strongest accepted static call-family census and historical
  object/owner evidence, but is a narrower success-only workload and lacks a
  complete generation manifest.
- RM438 is numerically closest to the old selected-function count, but count
  proximity does not prove similar membership, route frequency, or timing
  weight, and its provenance is incomplete.
- R426 and RS426 are broader than AC285 but differ materially in emitted and
  failed populations and also lack complete provenance and dynamic coverage.

The unresolved decision is therefore not “which current hash is closest.”
It is whether the future protocol should prioritize the accepted 285-function
success corpus, a broader newly reproducible compiler-rt corpus, or external
recovery of the exact historical input. That is a user/Reviewer acceptance
decision after provenance and representativeness evidence is available.

## Commands and execution boundary

Only read-only repository inspection was used:

```text
sed -n ... docs/worker_inbox.md docs/next_steps.md
git status --short
git rev-parse HEAD^{commit} HEAD^{tree}
git stash list
stat -c ... <candidate>
sha256sum <candidate-or-retained-evidence>
rg -n ... <candidate-or-retained-evidence>
sed -n ... <candidate-or-retained-evidence>
```

No project code, `z_llvm`, Zig command, selector/report, correctness gate,
performance command, network operation, Git maintenance, cleanup,
`clean_tmp`, generation, reconstruction, candidate materialization,
baseline validation, protocol amendment, or production wiring ran.

## Stop

Every candidate remains unauthorized. Ratchet 131, production routing,
retained artifacts, watcher, retention policy/pins/tooling, bypass TSV,
facade manifest, and stash remain unchanged.

STOP for Watcher/Reviewer and user review before protocol adoption,
materialization, pinning, baseline validation, production wiring, ratchet
credit, or performance sampling.
