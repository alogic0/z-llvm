# Upstream behavior and resource follow-up

The follow-up milestones in the [compiler plan](../plans/2026-11-11-complete-compiler-object-and-self-rebuild.md)
remain open. The [PHI checkpoint](compiler_behavior_phi_checkpoint_20261111.json)
accepts the narrow repair at `84f1ad7c`; it does not establish a repaired compiler
rebuild or completion of the upstream behavior matrix.

The pinned reference passes all 2,097 named tests in Debug, ReleaseSafe,
ReleaseFast and ReleaseSmall, including each mode's recorded upstream skips.
Both previously accepted compiler generations compile the full suite through
their normal LLVM route, then fail `@exp with vectors` in all four modes.
The retained failing invocations remain failures.

The reduced case identifies a floating PHI edge that snapshots named inputs
into XMM0 before materializing a literal through that same register. Reserving
XMM0 during snapshot planning preserves the input. Executable f32/f64 tests,
the new `phi_fp_literals` native population and an independently linked runtime
exp oracle cover the repair. The original runtime again selects all 455
definitions; its owners are unchanged, and both backend build modes emit the
same complete object. The old backend fails the new regression.

Debug and ReleaseSafe each pass 2,183 unit, 63 structural and two profile checks.
Readiness and all 17 serial integration gates pass. Both complete native suites
pass all 116 populations, preserve all 4,241 prior command outcomes, and retain
identical optimizer outputs, owner manifests and objects for the preceding 115
populations. All 822 cumulative fault controls are detected. Frozen source,
backend binaries, runtime events and object checks bind these results to the
checkpoint. Historical artifact seals and provider/contract pins verify without
rewriting their manifests.

Explicit local-hook behavior attempts expose further global syntax, wide integer,
x87 vector, floating atomic, varargs and ReleaseSmall runtime boundaries. A
normal-resource frontend probe still terminates with SIGSEGV under the inherited
46 MiB main-stack limit and CPU affinity 0–15. Frame-allocation experiments remain
isolated: selecting the large Sema function does not outweigh failing existing
tests. None of that prototype is accepted into the maintained backend.

Evidence is retained under
`local-state/validations/compiler-behavior-completion-20261111/batch-01/`.
The next implementation work closes the observed local-hook boundaries and
reduces frame growth with executable regression coverage, followed by fresh
compiler generations, the full behavior matrices and normal-resource self-rebuild.
