# Compiler generalization: bounded scheduling experiment

Status: measured and deferred under the plan's conditional performance gate.
The qualified prototype does not meet its declared benefit criteria and was
never promoted to production. Evidence is under
`local-state/validations/compiler-generalization/batch-01/stage-05`;
`prototype-source.patch` preserves the complete five-file delta.
Its SHA-256 is
`9d039baf93dd98536ea4e896ecdd8d243077502eac7a2a5c022d83fd67f65772`.

The historical fixed-Debug profile identifies 38,165 memory-bitcast attempts for
one rewrite. Unchanged attempts account for 5,017,480,528 logical allocated bytes;
these are allocation traffic, not live memory or RSS. The experiment changes
only that rule's applicability check at its existing priority position.

The rule shares its exact active-result/unflagged cast predicate with a pure
mayApply query. A negative result skips candidate-block construction. Opaque
call envelopes retain a conservative ordinary attempt. The query is recomputed
for every function version after every rewrite; no cached negative fact crosses
a rewrite. The five prioritized stages and remaining enum order are unchanged.
Mandatory normalization, label retention, original-form retries, the 1,024
rewrite limit and its charge point remain in the existing driver.

Skipped rules retain their registered profile descriptor but record no invented
attempt, allocation, timing or begin/end event. Existing profile schemas and
fields are unchanged. A private explicit initial-budget parameter permits tests
to exercise the real driver at exact exhaustion; production callers pass the
unchanged default. The root test import ensures these driver tests really run.

The prototype passes 18 selected Debug/Fast checks, all 2,421 Fast units and
74 structural checks. Interacting-rule tests cover self-tail, tail, signed,
memory-byte and memory-bitcast priority, revisiting a cast after an earlier
rewrite, changed versions with the same function name, removed/no-result casts
and opaque fallback. Actual driver tests cover zero-budget success, a free
original-form retry, one permitted rewrite and exhaustion before machine writes.

Nine prior objects and owner manifests remain byte-identical, including the
fixed 67,658,559-byte Debug module. Native memory-bitcast, memory-byte and prefetch
populations pass 99,840 local observations against 49,920 LLVM observations and
all 81 controls. Captured-row smoke, 60 ABI cases and three hello modes pass.
The prototype Fast compiler is
0f9f5253e227e719327dcbe13e105db5b1be1501607fc1f098a28343ff19b06f;
the qualified identity baseline is 067d6892.

The fixed input SHA-256 is
`d8b983f4686a19acdf9f5bcc84c084b6fbc68e104e1671032509f7180c9aa02b`.
Both compilers were built in Fast mode; the measured backend invocations use
the same Debug-mode environment, x86-64 target, reachability, report-all and
input-size settings. No profiling output, stack or CPU-affinity override is used.

An additional valid-IR 17-lane/i136 boundary probe passes 256 LLVM observations;
both baseline and prototype reject with the same exit 2 and
UnsupportedCodegenInstruction. It establishes preserved rejection, not support
for that layout or a newly repaired memory issue.

Diagnostic profiles taken during independent validation reduce memory-bitcast
attempts from 38,165 to 16,806 and unchanged logical allocation traffic from
5,017,480,528 to 2,627,193,968 bytes, with one rewrite in both runs. Their timing
and allocation traffic do not establish an unprofiled elapsed-time or RSS gain.
The unchanged fixed object and owners are maintained by identity; ordinary
objects and compiler pipelines retain only their declared next consumers.

Before execution, `measurement/retention.md` declared five alternating
unprofiled pairs plus warmups, matching flags/environment and every output
check. Delivery required all five pairs to improve elapsed time and the median
to improve by at least 1%, with no median RSS increase above 2%. Alternatively,
at least 5% lower median RSS with no median elapsed regression was sufficient.
These are bounded local evidence criteria, not portable test thresholds.

The idle comparison completed both warmups and all five alternating pairs.
All twelve compiler executions returned zero and reproduced the qualified
object digest and byte-identical owner manifest. Source, input and compiler
identities verify before and after. Warmups are excluded from these results:

| Pair | First compiler | Baseline seconds | Prototype seconds | Baseline minus prototype |
| --- | --- | ---: | ---: | ---: |
| 1 | Baseline | 106.03 | 106.02 | 0.01 s |
| 2 | Prototype | 105.26 | 104.99 | 0.27 s |
| 3 | Baseline | 100.86 | 97.10 | 3.76 s |
| 4 | Prototype | 95.77 | 97.67 | -1.90 s |
| 5 | Baseline | 101.63 | 101.58 | 0.05 s |

Median elapsed time is 101.63 s before and 101.58 s after: a 0.0492% difference.
Median peak RSS rises from 1,388,404 to 1,398,168 KiB (0.7033%). One paired run is
slower. The predeclared elapsed or RSS benefit is
not demonstrated. This result earns no compiler performance claim; fewer scans
and lower logical allocation traffic alone are insufficient.

The complete timing set, identities, commands and qualified patch are retained.
The isolated source worktree was removed through Git and its compiler/checkout
pipelines were released after their last consumers. The guarded collector
receipt is
`local-state/retirements/automatic-storage-cleanup/1794865590185066369-2788609/report.json`:
three trees and 371,470,336 allocated file bytes reclaimed, with current integrity
verified and all seven contracts and seventeen independent holds preserved.
The conditional production/profile-event/integration route was not opened.
Production scheduling remains unchanged at accepted source
`bce0fdcb7a49543f0be7601b0890c3211cb28a6a`. The
[stage-4 result](compiler_generalization_stage4_20261116.md) independently passes
all 17 integration gates and all 233 native populations; it supplies no
production acceptance credit for the unmerged prototype.

The accepted implementation stages are shared use queries at `1905a579`, typed
tables at `1032e124`, optional-pointer cleanup and scalar fork preservation at
`6be85e91`, and scoped identities at `bce0fdcb`. Original dirty build receipts
retain their source identities; committed-source bridges verify the qualified
relevant bytes rather than relabeling the original builds.

All cycle compiler and source-worktree pipelines are closed. Final documentation
checks and guarded collection are recorded under `stage-05/docs` and
`stage-05/final-closure`. The seven current contracts and seventeen independent
holds remain intact. The two diagnosed ordinary-product admission exceptions
are recorded in the stage-4 evidence, with no current validation consumer.
They are separate from required acceptance data. No additional abstraction
work starts from this result; the authorized sequence is complete.
