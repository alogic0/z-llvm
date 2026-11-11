# Compiler objects, runtime and self-rebuild

Implementation `b738377e` completes the
[compiler object and self-rebuild plan](../plans/2026-11-11-complete-compiler-object-and-self-rebuild.md).
Both fixed inputs produce complete local x86_64 ELF objects: **8,928/8,928
compiler definitions** and **455/455 runtime definitions**. The unchanged pinned
compiler builds through the local postopt hook, starts, compiles the unchanged
behavior programs and rebuilds itself through a fresh local hook.

The [acceptance record](compiler_object_self_rebuild_acceptance_20261111.json) separates the five milestones.
Evidence is retained under
`local-state/validations/compiler-object-completion-20261111/batch-01/`.
The preceding selection acceptance and sealed historical evidence remain intact.

## Object and lowering contracts

The original compiler's 258 decoder rejections comprised 31 LLVM backslash
escapes, 200 poison scalar cells, 19 floating layouts and eight relative-address
table expressions. Shared decoding supports those observed forms, preserving
string bytes, floating payloads, layouts, references and relocation addends.
Poison scalar cells use zero refinement. The required-symbol closure uses a
checked module-inventory budget. The 1 MiB per-global and 16 MiB section bounds
remain. Defined weak ODR function/data aliases retain target address, size,
type, visibility and weak binding.

Runtime repairs use the existing typed storage, transfers and ABI authority.
They cover pair pressure and preservation, i128 counts/min/max and constant
funnel shifts, exact unsigned divq assembly, scalar comparisons, half operations,
bounded floating-vector graphs, wide conversions, readonly-table indices and
incoming x87 byval values. All 68 preceding runtime rejections close while
preserving the original 387 selections and owners. Unsupported neighboring
assembly, layouts and ABI envelopes remain closed.

The self-build exposed a live-input error in scalar intrinsic lowering.
`Target.cTypeByteSize` returned 10 for f80 because a popcount destroyed a live
accumulator holding 16. The shared displacement decision now queries the
canonical after-current liveness authority and uses existing checked spills;
preservation-frame planning covers the affected operations. Canonical-query
errors still propagate through normal and PHI paths with rollback. The frozen
Source/value-use interfaces, inventories and 24 guard contracts are unchanged.
The extracted target function and new 25-function native population cover the
repair, including register/computed/load inputs, live aliases and exact stores.

The former `unsupported-global` fixture, `@value = global double 1.0`, now has
fresh Debug, ReleaseFast and LLVM positive proofs. All eight initializer bytes
and linked observations agree. The replacement unsupported vector-global
fixture retains its rejection, diagnostic and empty object contract.

## Unchanged build and self-rebuild

Both generations use upstream source
`1c08b09d1c847f4f02c8216e3b62df323861a437`, x86_64 Linux GNU, CPU `baseline`,
ReleaseFast and the LLVM-enabled configuration. Dedicated caches and install
roots retain original/effective CMake and native-libc configs, provider hashes,
commands, environments and postopt markers. Host-tool setup uses the pinned
emitter outside the compiler/runtime object claim. The candidate fronts the
actual self-build. Every delivered hook object is complete and accounted for;
each generation includes the compiler module.

| Generation | Compiler input SHA-256 | Runtime input SHA-256 | Executable SHA-256 |
| --- | --- | --- | --- |
| Pinned emitter builds candidate | de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e | 68ace8a2bc16e77e8f928bc829ca3357ecfeec0108a1b7b5a4616a858280350f | cc8389b1d973608f1a8d63f53790c942be387128c0eefca13ce18cc5e196977a |
| Candidate rebuilds pinned source | 7217b032845c0bb8e653823eac80bfae571707eed60793047c2576e27b849976 | ef3379e2d3d1189d83139adf69df2f9d943997c91345044cfb5f54f657dcd229 | b2846840434d20b3385e1e2d7802453bd90de0a3104c838977699e5ee2e1b7ac |

Initial compiler-object reuse is explicit and verifies exact input/backend hashes,
all 620 backend source/build inputs, arguments, actual source command, events,
owners and ELF. The self-build disables reuse and executes the backend freshly.
Fresh captures retain their own hashes and definition inventories. The self-built
compiler module has the same 443,624,107 bytes and 8,928 definitions as the fixed
input. A complete comparison of all 6,007,492 lines establishes bijective changes
to 30,389 private anonymous globals and 109 SSA value names; all remaining bytes,
including types, instructions, constants, strings and control flow, match.
A one-byte stride mutation from 16 to 10 is rejected by that comparison.

The recorded process setup grants the main stack **1 GiB** and pins the
self-build frontend to **CPU 0**, so its compiler work runs on that stack.
The generated-frame guard remains **8 MiB**, stack-object guard **64 KiB**, and
upstream worker stacks **60 MiB**. Earlier main/worker stack failures remain
failed resource attempts. This resource choice changes no compiler source,
target or object acceptance condition.

Both distinct retained executables print the pinned version, compile and execute
the unchanged `hello_libc` and `while_loops` programs, and reject the invalid-source
control. These behavior checks use each candidate's normal `-fllvm` path. The
f80 layout regression also passes with both fresh generations and the
pinned-emitter reference. LLVM optimization
and the declared LLVM/system providers remain part of the build; this proof is
limited to the specified configuration and local object hook.

## Cumulative validation and preservation

Debug and ReleaseSafe each pass **2,182 unit, 63 structural and two profiling
checks**. All eight readiness procedures and **17 serial integration gates**
pass. Both **115-population** native suites pass **94,661,250 local /
47,330,625 reference observations per build**. The three added populations cover
nine global, 26 runtime-frontier and 25 intrinsic-preservation functions, with
12,460, 852 and 1,168 observations per executable respectively.

Strict comparisons preserve all **112 baseline entries**, **4,133 command
outcomes**, **345 optimized IR files** and **675 owner manifests per build**.
Of 681 baseline objects, **579 are byte-identical**. All **102 changed objects
per build** have individual before/after hashes, source causes, changed functions,
contract inspections, disassembly and baseline/current/LLVM execution evidence.
The 30 unique hash pairs match across Debug and ReleaseFast. Seventy-two objects
reuse exact preceding inspected pairs; 30 receive eight fresh pair inspections
for the intrinsic repair. Symbol properties, initialized data and relocation
provider counts agree. Strict comparators retain their requires-review outcomes.

All **768 cumulative fault controls** are detected: 594 retained, 54 global,
54 runtime-frontier, 54 intrinsic-preservation and twelve original-runtime
controls. Retained control outcomes and diagnostics are checked explicitly.
Each original runtime object also passes **1,280 local and 1,280 independent
LLVM observations**. A separate raw-bit oracle adds **902 observations per
route** and six supplemental controls. These drivers exercise specific exports;
they do not claim execution of every runtime definition. They also pass against
the retained faulty self-build runtime, so their coverage does not detect that
f80 layout error. The direct frontend layout regression and the complete runtime
graph comparison provide the additional checks for that failure.
Both fresh runtime captures also match the original's complete allocated
contents, 937 symbol properties and 1,298 relocations after a bijective mapping
of private anonymous symbols. The earlier faulty f80 module fails this check.

The fixed prefix 100, execution cohort twelve, all **36 core selected-object
and observation records**, ratchet 130 and accepted-status file remain unchanged.
Thirty wrapper records differ only in the four separately reviewed
reference/link size and hash fields. Strict full-log results and every reviewed
difference are retained. The release bundle matches accepted identity
`3b65f5608098bf2c5f7816bea4b38a0cf0333797b516d1c7ae21d1f7e89d5249`.

## Source and evidence binding

The fixed compiler remains **443,624,107 bytes / 8,928 definitions**, SHA-256
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`.
The fixed runtime remains **1,856,543 bytes / 455 definitions**, SHA-256
`ca04995e5bc4d6537f6e1b994a79569ed8dc10d64451f89dfc0714fb40a732af`.
Complete census, independent production and balanced event audits agree on each
original input and its owners.

The backend checkpoint freezes **3,409 files** at `e398030f`, including all
**620 compiler source/build inputs**. The later orchestration-only checkpoint
`b738377e` freezes 3,410 files; all backend inputs and both executed backend
binaries retain their identities. Each long
run retains its exact source freeze and post-run verification. Final checks
verify providers, 24 frozen contracts, three AIR payloads, thirteen scratch
files and all 51,301 historical batch-30 artifacts. The final seal retains
accepted inputs, objects, executable observations, reports and provenance.

Failed, interrupted and canceled development attempts remain excluded from
acceptance. Concurrent timings establish completion and resource compliance;
they do not establish a controlled performance improvement.

The batch retains `original-input-proofs-v26.json`,
`cumulative-gates-audit-v32.json`, `whole-compiler-behaviors-v34.json`,
`source-binding-v34.json` and `orchestration-reuse-binding-v34.json` as the
milestone and reuse audits. The exact unchanged-build command is
`whole-command-v34.sh`; its actual-zero receipt is `unchanged-build-v34-run.json`.
`accepted-artifacts.sha256` seals the retained proof files and publication.
