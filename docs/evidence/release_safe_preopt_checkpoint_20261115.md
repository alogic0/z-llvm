# ReleaseSafe preopt implementation checkpoint

This is an intermediate C/D checkpoint for the
[active plan](../plans/2026-11-14-release-safe-preopt-behavior.md), not preopt
milestone acceptance. The complete captured runtime now selects **906 of 921
definitions**, up from 769, with no previously selected definition lost.
Fifteen runtime failures remain; neither real preopt attempt delivered an
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
are unchanged.

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

The two new native populations (`inline_memset`, `preopt_scalar_ops`) are
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
allocated bytes. Explicit release and collection of diagnosed predecessor
workspaces and the superseded fneg compiler is continuing under
`close-repairs/finish-r3.log`; this checkpoint does not close milestone storage.
The original predecessor compiler remains for preservation, the current
candidate stays stable through its audit consumers, and isolated residual
development has its own source-worktree pipeline. No ordinary object or binary
identity was promoted into a new retention pin.
