# Current state

The accepted record is [accepted_status.json](accepted_status.json). The block
below is generated and checked by `zig build check-docs`; regenerate it with
`zig build check-docs -- --write` after an explicitly accepted evidence update.

<!-- accepted-status:start -->

Accepted revision: `ea1e1e1abb047f47374528f4fc6f6db706f87645`; tree: `8f778b9392fcff16cdee216e14b142ddc255e9d2`.

Population: compiler-core candidate prefix (100 rows), selector `real-candidate-selector-v3`.
Modes: ReleaseFast, ReleaseSafe, ReleaseSmall. Source pin: `1c08b09d1c847f4f02c8216e3b62df323861a437`.
Candidate SHA-256: `847e014b2abab0800d0df690ef324dc5fa01299dcf60645b4dc55ca406fe2a31`.

| Metric | Accepted value per mode | Scope |
| --- | ---: | --- |
| Functions lowered | 100 | Compiler-core prefix |
| Objects emitted | 100 | Compiler-core prefix |
| Native links | 100 | Compiler-core prefix |
| Functions executed | 5 | Fixed execution cohort |
| Paired harnesses accepted | 5 | Legacy real_programs_ok cohort metric |
| Local failures | 0 | Compiler-core gate |

Compiler-rt bypass ratchet: 130 (separate 285-function population).

<!-- accepted-status:end -->

The [2026-11-02 checkpoint](evidence/current_pin_acceptance_20261102.json)
is an explicit migration to the current Zig pin and frozen selector-v3
population. Full fresh and cached integration results and their canonical
comparison back the values above. The membership audit retains 30 prefix
entries and replaces 70; 63 former names have no runtime AIR at this pin.
Four audited source-bound functions execute in each mode.

The same checkpoint repairs aggregate and optional snapshots across aliasing
writes, typed address scaling, displacement boundaries and current SysV carriers.
The ABI differential passes 60 native cases. Zig's unchanged upstream
`hello_libc.zig` executes through the local preopt optimizer and object emitter
in all three release modes. These program, compiler-rt and behavioral populations
remain separate from the compiler-core prefix.

The [FMA audit](evidence/current_pin_fma_canary_20261102.json) preserves 29
exact-result checks and requires 8,192 bitwise comparisons with LLVM compiling
the identical frozen IR. Tagged optional ABI signatures, wider variadic calls
and other unimplemented representations remain explicit boundaries.
IR construction, the system linker/CRT and libc remain dependencies of the
unchanged-program route.

Fresh export publication still retains duplicate working and cached descriptors.
The accepted run used a verified cleanup wrapper; capacity forecast acceptance
remains separate. See [next steps](next_steps.md) for that follow-up and for
expanding execution coverage within the fixed prefix. Earlier checkpoints and
measurements remain documented under the roadmap and evidence directories.
