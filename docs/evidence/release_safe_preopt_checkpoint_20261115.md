# ReleaseSafe preopt implementation checkpoint

This is an intermediate C/D checkpoint for the
[active plan](../plans/2026-11-14-release-safe-preopt-behavior.md), not preopt
milestone acceptance. The qualified repair selects **all 921 captured runtime
definitions**, up from 769, with no previously selected definition lost.
Promoted source passes full units, readiness and fixed runtime replay; neither real preopt attempt delivered an
object or executed the behavior suite. Later test inputs remain not yet
captured. Final inventory, audits, all 2,097 outcomes and preservation/integration
remain required.

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
This remains selection/native evidence, not a delivered real preopt object.

The reviewed historical-model transition preserves all 24 ordered byte
identities from `frozen-contracts-v3.sha256`, including the original seal.
Its successor redirects only the historical model row to the already maintained
exact `dd52f632` file. The evolving model's two body fingerprints receive no
acceptance credit from that historical row; current source guards, mutation
tests and source receipts qualify them separately. The peer review, exact row
mapping and publication checks live under `contract-transition/`.

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
The original predecessor compiler remains for preservation, the current
candidate stays stable through its audit consumers, and isolated residual
development has its own source-worktree pipeline. No ordinary object or binary
identity was promoted into a new retention pin.

The prior `fe2d88b4` runtime trace now has a complete verified audit of 182,330
events and 455 functions under
`local-state/retirements/native-event-audit/1794755248284530338-4147305/`.
Guarded retirement rejects its managed compiler symlink as `NotRegularFile`;
the original 53 MB raw stream and 44 MB compiler pipeline remain explicitly
retained for an alias-aware original-build retirement proof. Original receipts
and symlink identities were not rewritten. Exact reconstruction binds changed
sources to checkpoint Git blobs and two saved files matching the original build
hashes. Details and the retained exception are under `retire-fe2-trace/`.
