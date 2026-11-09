# Canonical quoted symbols and the 20 GB admission policy

Status: complete and accepted at `a9e9c0f1`. Both complete diagnostic/production
replays and fresh/cached full 17-gate runs pass, with 1,501 canonical records
matching between runs.
Plan: [quoted symbol addresses](../plans/2026-11-08-quoted-symbol-addresses.md).
Record: [full acceptance](quoted_symbol_addresses_acceptance_20261108.json).
Raw evidence: `local-state/validations/quoted-symbols-20261108/`.

Implementation is frozen at `a9e9c0f1`, following `b51fc4aa`. The baseline is
`b43dd3dc`, documented at `4ed60955`. The intervening user-directed policy
change, `1d725945`, requires 20,000,000,000 bytes free at admission and reserves
11,410,065,408 bytes during execution, retaining the 8 GiB working allowance.
The source manifest covers 1,766 build, compiler, tool and test files.

## Shared symbol identity

Symbolic addresses now validate complete LLVM identifiers and preserve their
quoted/escaped spelling. Constant GEP parsing uses quote-aware fields, including
commas inside symbol names. Module lookup, verifier maps and reachable alias
closure use canonical identifier equality. The existing MC symbol boundary
decodes escapes for ELF names; literal backslashes are not decoded twice.
This admits ordinary quoted integer-array globals through the shared path.
Layout, width, checked addend, global-property, ABI and register-effect limits
remain enforced.

Structured construction preserves quotes instead of stripping them. AIR has a
different producer contract: its names contain literal symbol bytes. A single
conversion at the AIR-to-IR boundary encodes those bytes as complete LLVM names
for definitions, direct callees, global references and scalar initializers.
That conversion is not an idempotent pass over arbitrary LLVM IR. Verifier
maps reject malformed names before insertion and detect canonically duplicate
definitions and mismatched call signatures.

The seven-function `quoted_symbols` population tests `[4 x i64]` and `[8 x i64]`
tables with runtime indexes, differently escaped alias chains, pointer
initializers, literal quotes/backslashes, positive and negative offsets,
integer call-address arguments, mutation with neighboring guards and pointer
PHIs. Its independent C oracle checks 1,024 observations per executable.
Both direct and release routes pass in Fast/Safe/Small with frozen Debug and
ReleaseFast compilers: 6,144 local and 3,072 reference observations per build.
Unit checks also cover source-IR preservation, repeat selection and rollback.

## Complete replay results

| Population | Previous selections | Current selections | Rejections | Lost successes |
| --- | ---: | ---: | ---: | ---: |
| Compiler | 7,441 / 8,928 | 7,657 / 8,928 | 1,271 | 0 |
| Runtime | 284 / 455 | 284 / 455 | 171 | 0 |

Compiler failures decrease by 216, or 14.53%. Every one of the 225 quoted-table
first failures advances: 216 functions select, five encounter an overflow
multiply operand limitation, three encounter a load-width limitation and one
encounters a store-width limitation. No targeted table rejection remains.

Both production replays agree with the diagnostic census on selected function
identities and failure tuples. The compiler audit covers 3,471,975 events and
8,928 matched function starts/ends; the runtime audit covers 70,654 events and
455 starts/ends. Both streams finish without a pending function, legalizer or
retry. Their expected process exit is one because selection remains incomplete.
Dependency coverage stays conservative. No complete compiler/runtime object,
compiler startup, behavior or self-rebuild success is claimed.

The profiled compiler production replay takes 888.06 seconds including its
runner, with maximum RSS 6,549,100 KiB. It records 1,191,267 legalizer attempts,
63,470 rewrites and 65,857 selection iterations. Concurrent integration work and
profiling affect these measurements; they are not throughput comparisons.

## Validation and build identities

Debug and ReleaseSafe each pass 1,979 unit tests and 23 structural checks.
The two profiling process tests, five whole-compiler report tests and all nine
readiness commands pass. Final Debug units and structural checks were also
executed explicitly because the build wrapper reused matching cached results.
The final readiness run uses dedicated retained tooling caches.

The new native population passes against these frozen compiler identities:

| Build | SHA-256 |
| --- | --- |
| Debug, focused | `7f1572c8260b4ce84cc701f917a4ee86ce5d3291cf2edfae3f29292ce6bd729c` |
| ReleaseFast | `3fbb28ba840594c249d772fa72ffc9163d7c7b517231f6f6fc99bbb8bc3626c1` |
| Debug, rebuilt for readiness/suite | `26053ebe4f56a32c013a43be41a51e6b28e0a04955963fb963e95b2c6ed83d93` |

The bounded ELF comparison finds identical machine code, ordinary allocated
data and all 22,151 declared readonly objects, covering 1,524,182 bytes. Entry
point, allocated layouts and symbol coverage match. It finds 119,847 differing
bytes outside declared object ranges in `.data.rel.ro`; nonallocated metadata
also differs. This is not whole-file identity or a proof about reads outside
declared objects. Focused and suite binaries remain separately authenticated.

Both full runs pass all 17 gates and 62 native populations, each with
1,955,844 local observations against 977,922 references. All 61 previous native
records are preserved. The five fixed programs pass all fifteen program/mode
pairs. The larger Zig corpus preserves all 87 input/mode pairs and 603 observation
controls; the C corpus preserves 138 pairs and 552 controls. The core fault
controls pass 21 pairs, 22,788 observations and 54 fault detections.

The fresh run takes 3,682.41 seconds and the cached run 3,509.25 seconds. The
official comparison matches all 1,501 canonical records. All three fresh exports
become authenticated cache hits, with identical keys and descriptor sizes; no
execution results are cached.

| Run | Starting free bytes | Minimum reported free bytes | Reported decrease |
| --- | ---: | ---: | ---: |
| Fresh | 47,898,742,784 | 40,061,620,224 | 7,837,122,560 |
| Cached | 42,759,090,176 | 40,125,562,880 | 2,633,527,296 |

Both decreases fit the existing 8 GiB allowance. The 240 additional samples
reach 40,061,513,728 bytes; final postcheck free space is 42,610,524,160 bytes.
These global filesystem measurements include unrelated activity and are not
atomic or throughput comparisons.

Both compiler-core runs pass in all three modes: 100 functions lowered,
emitted and linked, and twelve executed per mode. All 36 selected-object,
descriptor and observation records match the previous checkpoint. Linked sizes
match. Twenty-four Fast/Safe reference wrappers grow by 24 or 32 bytes; all
twelve Small reference wrappers retain exact hashes. The longer validation path
is consistent with the metadata changes, but prior temporary wrappers are absent,
so no old/new executable section identity is claimed. The runner's only source
changes outside this slice are the approved headroom test expectations.
Both suites start above 20 GB; this checks the configured admission and reserve
contract, not a guarantee that every workload finishes from exactly 20 GB free.

## Retention and operational record

Final source membership/content, compiler, frontend, original input, prior
evidence and scratch audits pass. Original compiler/runtime inputs, accepted
evidence, compiler snapshots, both AIR generations and all thirteen scratch
files are retained. The acceptance manifest authenticates 1,057 files with
SHA-256 `426aae4930e3090e6cfb7dadde024cfbe1ac1e000b0db0d0787da90dd5680841`.
Audited inactive project caches were retired before the full pair. Shared executable/tool
retirement covers 54 and 138 files, respectively, totaling about 7.20 GB of
logical file bytes; the first local-cache inventory was about 1.11 GB allocated.
These are separate measurements, not a net filesystem recovery claim. A larger
observed free-space increase is not attributed to this cleanup.

Retiring individual cached executables left stale tool references. The original
readiness/linker failure and failed resume are retained; an exact link retry
passed unchanged. Matching stale metadata was then removed, and final readiness
and production validation used dedicated caches. The first full-suite invocation
also failed owned-root validation before any gate; the corrected setup creates
matching scratch/cache owner directories. These failed invocations are excluded
from acceptance. No archives were created and no cache retirement occurred during
the full pair.

An attempted process-tree stop mistakenly included unrelated PIDs because
zero-valued membership entries remained in its list. The shell exited early;
effects on unrelated jobs are unconfirmed. The original process snapshot, list
and review remain under the evidence root. That list was not reused; subsequent
stopping used one exact PID after checking its executable path.

## Next shared repair

The census identifies 59 `composed-block-smulo-i64-rhs` failures with the same
concrete call shape: `llvm.umul.with.overflow.i64`, a spilled i64 left operand
and a constant i64 right operand. Fifty-eight spilled values come from selects,
and one from binary arithmetic. Constants range from 12 to 120; the common
values are 24, 40, 12, 48, 20 and 56. The observed operation is unsigned even
though the diagnostic tag contains `smulo`.

The next slice should materialize that operand through shared transfer and
register-effect rules, preserving live values around the RAX/RDX sequence.
Cover overflow/no-overflow, aliases, spills, surrounding calls, rollback and
independent native execution; then replay both complete inputs. The group size
does not predict the number of newly selected functions. Keep undef/poison
call semantics as a separate decision.
