# ReleaseSafe preopt implementation checkpoint

Historical stage-E checkpoint. The
[2026-11-16 acceptance](release_safe_preopt_acceptance_20261116.md) supersedes
the remaining-work statements below and closes stages F/G, including fixed-input
qualification, four-mode postopt preservation and storage disposition.

This records implementation through stage E of the
[active plan](../plans/2026-11-14-release-safe-preopt-behavior.md), not preopt
milestone acceptance. The fifth complete preopt attempt matches **all 2,097
ordered reference outcomes: 2,065 passes and 32 skips**. It delivers both complete
local objects, selecting **921/921 runtime and 7,716/7,716 test definitions**.
Independent inventories, ownership/ELF checks and both full ordered event
streams pass. Separate reconciliation accounts for every optimizer/emitter
invocation and both runtime/test populations. The real optimizer failure control
stops compilation with zero emitter invocations and no fallback credit.

A conservative typed floating cancellation rule repairs the fourth attempt's
sole optimized-float-mode failure. Debug/ReleaseFast units, calibrated native
optimizer checks, full readiness and structural validation pass. Complete serial
Tier 3 passes all 17 gates, including the full 230-population native suite, on
the same frozen source and Fast executable. Two earlier attempts were canceled
by SIGTERM; their original results remain canceled. The signal attribution
control preserves normal cancellation behavior; no signal was received by the
successful supervisor. At this checkpoint, the committed-Git source bridge,
preservation and storage closure remained required before milestone acceptance.

The maintained runner now selects `--local-pipeline preopt` explicitly, binds
the selected reference hash and providers, exports the Safe hook policy, and
applies shared disk admission and monitoring. Optimizer and emitter captures
have separate completion records. Their chain binds resolved frontend paths,
file sizes and hashes; input limits use each complete input's size plus one.
Failed or partial optimization cannot deliver an object. Postopt remains the
default. Debug/ReleaseFast tool units and process-level positive, failure,
partial-output, pairing, provider and resource controls passed.

The frozen generation-1 frontend remains `972160f2`, paired with original
normal-LLVM reference `8725f827`. Admission found changed libc/loader bytes;
the required current-runtime reference `eb95b922` preserves every ordered
outcome, including skips. Compiler-runtime frontend mode Fast is recorded
separately from the global Safe optimizer hook. No frontend source or binary
was changed.

The first focused repairs preserve extended negative-zero bit patterns in LLVM
text, dispatch constant-length inline memset through the existing memory action,
and repair scalar multiply operand staging and immediate subtraction. The
multiply change remains inside the typed action owner. Frozen resolution,
binding and facade budgets are unchanged. Inline memset uses the existing
preservation-demand predicate; frame layout and the pinned guard-model bytes
are unchanged in that first checkpoint.

The next repair adds bounded constant-table index proofs, preserves floating
table loads during scalar-memory fallback, and snapshots ordinary two-double
return loads through existing scalar memory and SSE return owners. It also
handles full i128 literal returns, sub-byte integer-to-FP conversions, frameless
immediate shifts and live accumulator preservation. Index proofs require bounded
typed values or uniform reaching stores in nonescaping private storage; unknown
paths, escapes, effectful accesses and nonzero aliases decline. Existing table
shapes, pointer offsets, ABI classification, frame layout and resolver budgets
remain unchanged.

`residual-focused-r6/` binds the isolated source and fixtures before and after
121 focused tests in both Debug and ReleaseFast. The `preopt_values` canary
passes 15,360 local observations against 7,680 reference observations and 45
failure controls; `preopt_memory` passes 9,216 against 4,608 and 54 controls.
Both cover all three release modes and both local routes. The latter includes
protected page edges, unaligned exact FP payloads, snapshots across mutation and
caller clobbers, private stores, wide masks and table-to-frame round trips.
The full runtime census selects 921/921 with zero losses. These two populations
bring the registry to 229, separately from the original 225 and 6,724 faults.
This D4 qualification is selection/native evidence; the subsequent third capture
provides the first real runtime object evidence below.

The reviewed historical-model transition preserves all 24 ordered byte
identities from `frozen-contracts-v3.sha256`, including the original seal.
Its successor redirects only the historical model row to the already maintained
exact `dd52f632` file. The evolving model's two body fingerprints receive no
acceptance credit from that historical row; current source guards, mutation
tests and source receipts qualify them separately. The peer review, exact row
mapping and publication checks live under `contract-transition/`.

The test-module repair keeps the narrow shift's current LHS alive while staging
a spilled count in RCX. Frameless word masks and pair OR operations preserve
live accumulator values through existing owners; pair widening chooses an
already assigned free result pair before emission. A typed optional legalizer
folds proven constant four-float insertion views and snapshots all four ordinary
load lanes at the original load position. It preserves the exact 16-byte access
span and declines dynamic/unknown lanes, effectful accesses and extra consumers.
Operand lists are cloned; the original IR remains unchanged and rewriting is
idempotent. These changes introduce no vector ABI, frame-layout or resolver
budget expansion.

The separate `preopt_test_frontier` population covers wide masks, exhaustive
small shifts, signed overflow round trips, live caller-clobbering calls, exact
FP payloads and unaligned protected-page snapshots across mutation. All three
release modes and both local routes pass 107,520 local observations against
53,760 references and all 54 injected faults. This brings the registry to 230;
the original 225 populations and 6,724 required faults remain separate.

The float-mode failure contains `(x + C) - C` with `fast` on both operations;
its strict neighbor must retain two-step rounding. InstCombine now cancels
matching finite scalar float/double constants only with complete conservative
permissions on both operations, using the existing typed literal decoder and
replacement authority. It requires a prior producer in the same block and
preserves other uses of that producer. Strict, incompletely licensed,
nonfinite, unequal, dynamic and cross-block cases decline. This follows the
common rewrite permissions described by the
[LLVM 22 fast-math contract](https://releases.llvm.org/22.1.0/docs/LangRef.html#fast-math-flags).
No frontend, selector, ABI or frame-layout change is involved.

The separate optimizer regression checks nine functions and 5,120 independent
C bit/rounding observations per execution. Four local pipelines pass against
the LLVM reference, and all 20 injected faults are detected. Cold and cached
helper runs have identical outputs. The original backend fails the independent
golden. An initial faulty partial-flags oracle failed in the LLVM reference
before local execution; its original receipt, exact fixture and diagnosis are
preserved, and it receives no validation credit. These controls are separate
from the native registry and its original 6,724 required faults.

Evidence lives under
`local-state/validations/release-safe-preopt-20261115/batch-01/`:

| Evidence | Result and scope |
| --- | --- |
| `baseline/`, `reference-current-runtime/` | Frontend/reference/source admission; current-provider reference matches all 2,097 outcomes. |
| `tooling-debug*`, `tooling-fast*` | Runner/auditor units and CLI controls; failed attempts remain with diagnoses. |
| `capture-01/`, `capture-02/`, `attempts.jsonl` | Complete encountered runtime inputs, separate optimizer/emitter statuses and original failures. No delivered preopt object. |
| `inventory-capture-02/` | Independent 921-definition census and full strict failed-stream verification (`stream-audit.json`). Stream verification grants neither object credit nor trace retirement. |
| `repair-fneg*` | Typed extended payloads survive LLVM verification and native/reference comparisons. |
| `precommit-owner/` | Debug/Fast typed-action and source-guard controls; all-mode scalar execution/faults; 906 selections and zero losses. |
| `precommit-fast-r2/` | Source-verified Fast candidate `fe2d88b4`: 2,369 units, known 455-definition runtime object/native replay, upstream C boundary and all 227 native populations across three release modes. |
| `precommit-contract-r3/` | Current Debug/Fast guard/frame tests pass; both additions pass all modes and 54 fault controls; all twelve object hashes match the recorded Fast candidate. All current frozen contracts verify. |
| `precommit-readiness-r3/` | All nine current-source readiness procedures pass, including the full Debug unit gate, all 60 ABI comparisons and generated scalar differential checks. |
| `precommit-final-checks/` | All 2,370 current-source ReleaseFast units pass; documentation checks validate 24 documents, 517 links and both accepted-status blocks; the unchanged frozen contract verifies. |
| `residual-focused-r6/` | All 921 captured runtime definitions selected without loss; 121 Debug/Fast focused tests; both added native populations and all 99 controls pass with exact source/fixture binding. |
| `d4-promoted/` | Promoted source matches R6 exactly; all 2,378 ReleaseFast units, nine readiness procedures, 66 structural tests and all six selected integrity manifests pass. The fixed 455-function runtime object/native replay passes 21,792 local and reference observations plus 14 controls. |
| `build-residual-r2/`, `tools-residual/` | Canonical backend `4ced5fb1` from commit `4b15d49e`, with complete source membership and hash verification. |
| `capture-03/` | Both local optimizer stages finish. Runtime emission delivers all 921 definitions; test emission fails on nine of 7,716, preserving all original receipts and complete inputs. |
| `inventory-capture-03/` | Four complete inputs parse and pass LLVM verify-only checks. Independent runtime census, ownership and ELF audits pass. Full ordered streams verify: 421,726 runtime events and 3,056,459 test events, with the test stream correctly recorded as unsuccessful. |
| `test-frontier-views-r2/` | Both actual vector-view tests pass in Debug/Fast; all nine original failed definitions select. Earlier import-only checks receive no test credit. |
| `test-frontier-native/` | Complete test census selects 7,716/7,716; runtime selects 921/921. The new native population and all 54 fault controls pass with exact production-source and fixture binding. |
| `test-frontier-fingerprint/` | Existing source-guard API derives the reviewed pair OR/widening body hashes. Only those two model rows change; full current guard and mutation tests pass in the broader gate. |
| `test-frontier-promoted-r3/` | All 2,384 ReleaseFast units, Debug readiness including all 60 ABI comparisons, 66 structural tests and six selected integrity manifests pass. The fixed 455-definition runtime object/native replay passes 21,792 local and reference observations plus 14 controls. New rollback tests cover current RCX inputs, spilled counts, both preservation flags, accumulator aliases and pair pressure. Earlier new-fixture setup failures retain their receipts, patches and diagnoses. |
| `capture-04/` | Both local objects delivered and all 2,097 tests executed; the sole optimized-float-mode failure remains an original failed result. |
| `inventory-capture-04/` | Complete separate runtime/test inventories, full censuses and both object/ownership/ELF audits pass. Full streams verify 425,500 runtime and 3,085,054 test events; compilation succeeds even though behavior execution fails. |
| `fastmath-units/` | Three actual new tests pass in Debug/ReleaseFast, covering both scalar widths, flag combinations, shared uses, rejection boundaries and idempotence. |
| `fastmath-real-input/` | The exact retained captured helper pair reproduces the old two fast operations; the repaired optimizer removes them, preserves both strict operations and passes LLVM verify-only before/after. |
| `fastmath-before-r2/`, `fastmath-native-r2/` | The old backend fails the independent golden; the corrected candidate passes all existing optimizer cases, four added pipelines, 20 faults and the identical-output cold/cached pair. |
| `fastmath-reference-diagnosis/` | Preserved original reference-oracle failure and emitted LLVM function excerpts; the corrected executable boundary explicitly omits reassociation permission. |
| `fastmath-promoted/` | All 2,387 ReleaseFast units, nine readiness procedures, 60 ABI comparisons, 6,528 scalar observations, 66 structural tests and all six selected integrity manifests pass, with exact source/fixture/backend verification before and after. |
| `capture-05/` | One unchanged complete local preopt run matches all 2,097 outcomes, delivers both complete objects and verifies source, frontend, backend and all 25 providers before and after. Its actual precommit head and complete dirty-source snapshot remain recorded. |
| `inventory-capture-05/` | Complete runtime/test inventories, 921/921 and 7,716/7,716 independent censuses and both object/ownership/ELF audits pass. Full streams verify 425,500 runtime and 3,085,054 test events against the original real producer. |
| `route-control/`, `reconcile-capture-05/` | A real local optimizer failure produces one failed optimizer invocation, zero emitters and a failed compile. Separate stage-E reconciliation accounts for both module pairs, every invocation, all outcomes and independent audits. Stages F/G remain open. |
| `fastmath-tier3/`, `fastmath-tier3-r2/`, `signal-trace-control/` | Canceled full-gate attempts retain their SIGTERM outcomes and receive no aggregate acceptance. A controlled cancellation verifies signal sender attribution while preserving normal cancellation behavior; frontend/backend binaries are unchanged. |
| `fastmath-tier3-r3/` | All 17 serial gates pass; each real-row mode lowers/emits/links 100 functions and passes all 12 execution witnesses. The full native suite passes on the exact `f04acdbb` compiler; source, fixtures, providers and six integrity manifests verify before/after. Original precommit source head and dirty snapshot remain unchanged. The serial runner records 4,078,999 ms and a minimum 207,939,821,568 free bytes, above the 20,000,000,000-byte admission floor. |
| `native-archive-build-r2/`, `native-archive-projector/`, `native-archive-controls-r2/` | Debug/Fast archive and source-identity tests pass. Separate historical self comparisons each preserve 8,204 outcomes and 3,399 artifact hashes from the exact accepted manifest. Controls reject 33 actual historical cross-build object differences, a changed manifest and a changed command outcome. Each new build must compare directly to its corresponding historical build, hashing new artifacts live; those final comparisons remain pending. |

The first two new native populations (`inline_memset`, `preopt_scalar_ops`) are
separate from the accepted 225 and the original 6,724 required faults. Existing
native fixtures contain no inline memset calls. The predicate-only source
bridge after the Fast run is qualified by full emitted-encoding equivalence and
the twelve exact object comparisons; it does not silently relabel the older
Fast build as a build from the final checkout.

Original failure receipts, complete inputs and required raw events remain
maintained. Diagnosed scratch is released after its consumers close. Collection
receipt `1794747507613180725-3968490` reclaimed 1,538,461,696 allocated bytes;
`1794749047728472361-4009830` reclaimed another 452,546,560 bytes after the
focused contract check. Both verified all six current integrity manifests.
Readiness collection `1794750043894370545-4036529` reclaimed another
667,664,384 allocated bytes with the same six manifests verified.
Final-check collection `1794750624299558653-4049984` reclaimed 372,432,896
allocated bytes. Explicit release and collection of eight diagnosed workspaces
and the superseded fneg compiler reclaimed another 2,245,496,832 allocated bytes
in receipt `1794751560822798581-4072251`. D4's successful R6 workspaces reclaimed
544,948,224 bytes in `1794754838419183966-4138219`; original failed attempts
remain preserved with their diagnoses. This checkpoint does not close milestone storage.
The original predecessor compiler remains for preservation. D4's isolated source
worktree and diagnosed scratch were released after promotion. C3's private
caches and ordinary runtime object were released after audits, reclaiming
168,235,008 allocated bytes in receipt `1794761053238581973-76545`.
Complete captured inputs, raw events and the original compiler remain for their
recorded audit/retirement consumers. No ordinary object or binary identity was
promoted into a new retention pin.

The prior `fe2d88b4` runtime trace now has a complete verified audit of 182,330
events and 455 functions under
`local-state/retirements/native-event-audit/1794755248284530338-4147305/`.
The ordinary `release-trace` route rejects its managed compiler symlink as
`NotRegularFile`; its original failed receipts and symlink identities remain
unchanged under `retire-fe2-trace/`. The supported reviewed-records audited
route separately closes tracing detail from complete audit/input/producer/report
bindings and copied auditor sources, without reconstructing an obsolete
compiler. Seven verified streams are queued for this explicit review after
Tier 3 and the committed-source bridge; raw bytes and compiler pipelines remain
retained until their actual consumers close and the native collector qualifies
retirement. The older C2 stream has no retained inner-producer receipt and is
excluded, with its provenance limitation recorded. No successful retirement is
claimed from preparing this route.
