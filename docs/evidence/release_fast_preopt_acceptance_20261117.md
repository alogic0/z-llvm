# ReleaseFast preopt behavior qualification

The unchanged pinned upstream behavior suite passes through the local optimizer
and local object emitter in ReleaseFast at backend source `c32ba3cf`. One complete
unchanged run matches all **2,097 ordered reference outcomes**, including
**2,063 OK and 34 SKIP**. No compiler source repair was needed. The
[acceptance record](release_fast_preopt_acceptance_20261117.json) binds the exact
source, frontend, reference, inventories, audits, preservation and storage proof.

The generation-1 frontend remains `972160f2`, from pinned upstream source
`1c08b09d`. Matching normal LLVM Fast reference `3974cd8a` preserves the original
`33ac5970` reference's complete ordered outcomes. All 25 providers remain
unchanged, so no new reference run was needed. Normal resources and initially
absent private frontend local/global caches are recorded. The full behavior run
uses fresh backend, link and execution results; it reuses the authenticated
frontend executable, unchanged source/providers and existing reference data.

| Complete preopt population | Definitions | Input bytes | Optimized bytes | Object SHA-256 prefix |
| --- | ---: | ---: | ---: | --- |
| Compiler runtime | 921 | 9,067,653 | 7,455,455 | `bd1a083a` |
| Test module | 7,459 | 44,873,406 | 37,309,433 | `3ad7015d` |

Global hook policy is `ZLLVM_ZIG_MODE=ReleaseFast`, selecting
`zig-release-fast-accepted`. Compiler-runtime frontend mode is also Fast and is
recorded separately. Both optimizer and both emitter invocations reconcile to
the complete runtime/test inventories. Every measured input limit is file size
plus one; optimizer outputs bind exactly to emitter inputs by size, hash and
delivery path. Complete definitions, declarations, globals and aliases remain
accounted for. Independent selection censuses select every definition, with no
failed or omitted function. Object, ownership and ELF audits pass.

Strict full ordered-event audits verify **425,916 runtime records** and
**2,876,595 test records**, with balanced function scopes and exact report,
counter, failure, input and producer bindings. All 3,302,511 records are read;
tails or samples supply no completeness credit. LLVM verifies the retained IR
only as a separate validation reference.

The real optimizer-failure control invokes the actual candidate with input limit
one. The compile fails: one failed optimizer, zero emitters, no delivered object
and no behavior execution. Original failed receipts remain failed. Source review
of the unchanged frontend separates LLVM target/analysis/pass-manager
construction from pass execution. The selected preopt branch executes the local
commands and returns on their failure; it executes no LLVM optimizer or object
emission pass and supplies no fallback delivery.

Compiler `87ab3a8e` has a complete 679-file source/build receipt from documentation
head `6a95f245`; all runtime source membership and Git blobs match `c32ba3cf`.
Final verification rehashes the SDK executable and complete library using the
maintained identity implementation, plus frontend, source, reference and all
providers. The setup's fourteen Debug and fourteen Fast runner contract tests
are explicitly adopted through five byte-identical tool copies. A live Bash edit
caused a duplicate setup build; both original receipts actually finished zero
before an attempted stop reached them. Its diagnosis and original outcomes stay
explicit. No canceled or failed producer is invented.

Fresh preservation keeps fixed Debug object `92825c8e` and owners `50a5e008`
exact, matches all **60 ABI cases** and passes all **27 M1 executables**. Final
serial integration passes all **17 gates** and the complete **237-population
native suite**, run `dce612f4ce8a62a319cfd89b7adcfb50`. It reuses authenticated
real-row frontend AIR while rerunning backend, object, link and execution checks.
The source-bound 2,438 Fast-unit/74-structural maintenance baseline remains
separate; this milestone does not label those checks as fresh executions.
Existing ReleaseSafe and four-mode postopt acceptance is preserved without a new
full Safe/Small execution claim. Scheduling remains deferred; no performance
parity, complete compiler preopt/self-rebuild or IR-construction-removal claim is
added. LLVM construction, bitcode parsing, setup and declared providers remain.

Evidence root:
`local-state/validations/release-fast-preopt-20261117/batch-01/`.
`capture-01/run/report.json` is the single complete local result;
`reconcile-01/report.json` closes inventory and stage pairing;
`final-verification/report.json` binds every E/F consumer. The strict audit root is
`local-state/retirements/native-event-audit/1794922116642381911-211285/`.

After full audits and explicit native dry review, the two raw streams retire
through receipt `1794928345814245086-401036`, reclaiming **1,030,979,584 allocated
bytes** while retaining inputs, original reports/diagnostics, complete audits and
auditor sources. This closes tracing detail without adding a compiler replay pin.
Final workspace receipt `1794928634410961222-406119` reclaims **97,415,168 bytes**
and confirms **all owned pipelines closed and zero owned temporary roots**.
Earlier receipts record each completed consumer boundary, including the guarded
ordinary default compiler teardown. Independently owned historical work remains
under its original contracts.

The explicit 170-file maintained manifest hashes to
`3a609f41d4ae95e06e905a7fd08908fd81d47d6374d311d651ca87031832c959`.
Its additive eighth policy entry preserves all seven original manifest paths and
bytes, every other policy field and all seventeen independent holds. All eight
manifests verify. Ordinary binaries, objects, executables, caches, retired raw
streams and live mutable controls are excluded from new pins.

This closes the [bounded plan](../plans/2026-11-17-release-fast-preopt-behavior.md).
Stop for review; ReleaseSmall and other successor implementation remain separate.
