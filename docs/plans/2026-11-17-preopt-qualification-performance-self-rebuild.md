# Preopt qualification, generated-code measurement and self-rebuild

Date: 2026-11-17
Owner: primary implementation agent. Independent reviewer: thread
`01a1cf53-4a3b-70d1-adb6-9655b6d4cb24`.
Starting baseline: `435ba95c`, compiler source `c32ba3cf`. The reviewer accepted
ReleaseFast after source/log review with no blocking findings. Builds and
validation belong to the implementation owner; reviewer checks are source/logs.

The user authorized these three ordered milestones. Each requires a concrete
commit, frozen source, completed validation, storage closure and an explicit
review-ready handoff. Stop successor implementation after every milestone.
Only the reviewer's explicit authorization after resolving findings opens the
next milestone; time, an idle reviewer and self-assessment never open the gate.
Findings receive a bounded fix and another review.

| Milestone | Scope | State |
| --- | --- | --- |
| M1 | Full unchanged ReleaseSmall behavior through local preopt optimization and object emission | Independently accepted at `a27b8e86`. [M1 plan](2026-11-17-release-small-preopt-behavior.md) |
| M2 | Generated-program runtime and code/executable size against LLVM | Independently accepted at `8594ba04` for the five measured processes on the recorded host. [Runtime and size results](../evidence/generated_program_performance_20261117.md) |
| M3 | Compiler build and next-generation self-rebuild through local preopt, initially Fast | Explicitly authorized after M2 review. [ReleaseFast build and self-rebuild plan](2026-11-17-release-fast-compiler-preopt-self-rebuild.md) |

M2 freezes a representative bounded workload set, independent correctness
oracles, commands, repeated unprofiled execution protocol, tool/source/provider
identities and comparable target/link/strip/debug settings before collecting
comparisons. Retain every result and variability. Separate generated-program
runtime and text/data/file sizes from compiler throughput and instrumentation.
Fast and Small currently share an implemented pass subset; their names imply no
speed or size parity. Report measured gaps and ranked proposals. Substantial
optimizer changes need a concrete reviewed slice, not a silent benchmark repair.
Its detailed plan and ownership/admission are written only after M1 review.

M3 adapts the accepted compiler/self-rebuild framework with a new explicit preopt
plan. Require complete compiler/runtime inventories, local optimization and
object emission, resulting compiler usability, a next self-rebuild generation,
behavior/reference comparisons, no-fallback controls, complete ownership/audits
and measured size/resource admission under normal resources. Postopt acceptance
is preservation evidence with no preopt execution credit. LLVM IR construction,
setup and declared providers remain dependencies. No stubs, omissions, fallback
or weaker acceptance are permitted. Its detailed plan starts after M2 review.

Every milestone declares producers, consumers, maintained exceptions and release
conditions before admission. Preserve the eight current proof contracts and
independent holds. Collect at ordinary stage boundaries and immediately after
the final consumer releases; retry idle deferrals. Never edit a running script.
Use AGENTS.md, development_storage.md and validation_tiers.md. Existing evidence
may be reused only with explicit unchanged relevant identities; label fresh and
reused results separately.

Review-ready messages contain the commit range, plan/evidence paths, exact fresh
and reused results, original failures/limitations and storage disposition. Send
to the review thread and verify delivery. The acknowledgment return path was
confirmed with `delivered: true` on 2026-11-17. Prefer the exposed thread-message
tool when available; otherwise the explicitly authorized local two-thread
transport may deliver messages. A failed delivery leaves the gate pending.

## Review ledger

| Decision | Independent review and disposition |
| --- | --- |
| Fast baseline `435ba95c` | Reviewed the accepted run at compiler source `c32ba3cf` and authorized M1. |
| M1 admission `fd52842b` | Approved the plan and per-gate adoption policy. Reuse requires matching source membership and bytes, executable, SDK/library, providers, target, mode, corpus, arguments and expected contract. This decision authorized M1 execution only. |
| Interrupted build | The outer command returned 143 and the original monitor outcome remained unknown. The child build completed with exit 0. The reviewer required a separate disposal protocol that preserved all three original records. |
| First recovery patch `16a5e403` | Requested independent held-release and retained-member discovery, plus a current process-argument check for the quarantine path. The revised Debug/Fast fixtures covered both refusal and rollback. |
| Recovery patch `3070d6c4` | Closed the first two findings. Requested use of the canonical owner policy and matching valid SHA-256 strings for the completed child and its admission. |
| Recovery patch `b89ae2ec` | Approved the ten frozen files and r8 Debug/Fast results, including 26 refusals, two reader rollbacks and eleven legacy checks in each mode. The files were promoted at `ec639588` after final verification on `c32ba3cf`. |
| First real dry plan `5d2f0b97` | One ready, zero removed. Apply was held because the retained list would pin twelve independent live controls. |
| Successor plan `a95f4392` | Approved exactly one apply after reviewing the 25 retained paths, the one-action dry receipt, exact tree, original records and live controls. Native receipt `1794957605971871164-1072275` records one removal and 265,383,936 reclaimed file bytes. The monitor outcome remains unknown. |
| M1 milestone, 2026-11-17 | Reviewer `01a1cf53-4a3b-70d1-adb6-9655b6d4cb24` accepted `a27b8e86be13e26ff5eeabb9ed4c168358d9bf4d` on tested core `c32ba3cfb1f67340ac5706fbc77ac56569b37007`, x86_64-linux-gnu baseline. The accepted JSON SHA-256 is `ec181f836f66308aed9fc0e827b0f58c5d6b734928f0cf0689bb5366d83d7d7f`. The reviewer explicitly authorized M2. |
| M2 measurement | `32adb32c` froze five workloads and four routes. The first sampler exited 1 while checking affinity, before it launched a workload. At `1ee97b3b`, the corrected and qualified meter ran all 40 warmups and 240 measured processes on the twenty authenticated images. |
| M2 preservation | Serial run `cbc9a73d6b32028addb6bf8ee5d091e1` passed all 17 gates. The three real-row modes reused authenticated frontend AIR. The fresh native report binds the selected backend `ab067396` and the 237-population registry. |
| M2 report verification | The first order check exited 1 because it parsed the space-separated expected lists with a tab separator. The successor checks the original 280 rows and includes changed-route and missing-row controls. Both attempts remain in the batch evidence. |
| M2 milestone | Reviewer `01a1cf53-4a3b-70d1-adb6-9655b6d4cb24` accepted `8594ba0471c2185b6c12f9b81b48a7b7a8656ac8` on core `c32ba3cf`. The verified result JSON SHA-256 is `6c3343f929f5ac2fa2d0d61f76f5a957004340f7100521d11df8a974e6d5f435`. Review covered the oracles, forty links, 280 executions, ratios, ELF sizes, seventeen gates, 237 populations and storage closure. |
| M3 admission | The reviewer authorized the two-generation local preopt compiler build in ReleaseFast under normal resources. M3 must return as a frozen result for independent review. Preserve all nine current proofs and seventeen holds. |

M1 matched 2,097 ordered Small outcomes and audited 903 runtime and 6,684 test
definitions, both emitted objects and 2,943,342 ordered events. The corrected
real failure control, fresh fixed Debug comparison, 60 ABI cases, 27
executables, 17 integration gates and 237 native populations passed.
[ReleaseSmall qualification](../evidence/release_small_preopt_acceptance_20261117.md)
