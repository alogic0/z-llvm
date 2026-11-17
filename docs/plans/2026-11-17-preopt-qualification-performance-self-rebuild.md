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
| M1 | Full unchanged ReleaseSmall behavior through local preopt optimization and object emission | Authorized; admission in progress under the [M1 plan](2026-11-17-release-small-preopt-behavior.md) |
| M2 | Generated-program runtime and code/executable size against LLVM | Pending M1 review and explicit authorization |
| M3 | Compiler build and next-generation self-rebuild through local preopt, initially Fast | Pending M2 review and explicit authorization |

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

- Baseline: `435ba95c` / compiler `c32ba3cf`, no blocking findings from reviewer.
- M1: active; no completion or next-milestone authorization yet.
- M2 and M3: gated; no implementation or benchmark collection started.
