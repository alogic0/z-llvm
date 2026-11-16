# ReleaseSafe preopt behavior acceptance

The unchanged generation-1 upstream behavior suite passes through local
optimization and local object emission in ReleaseSafe at backend source
`ae9d359f`. One complete frozen-candidate run matches all **2,097 ordered
reference outcomes**, including **2,065 OK and 32 SKIP**. The
[acceptance record](release_safe_preopt_acceptance_20261116.json) binds the
source bridge, results, audits, preservation and storage disposition.

The accepted frontend remains `972160f2`, from pinned source `1c08b09d`.
Its original normal LLVM Safe reference is `8725f827`; the current-provider
reference `eb95b922` preserves the same complete ordered outcomes. Only system
libc and the loader changed in that refresh; all 25 declared providers are
verified before and after the accepted runs.

| Complete preopt population | Definitions | Input bytes | Optimized bytes | Delivered object SHA-256 prefix |
| --- | ---: | ---: | ---: | --- |
| Compiler runtime | 921 | 9,067,653 | 7,455,455 | `7533e0ae` |
| Test module | 7,716 | 51,462,960 | 42,045,876 | `148f1e13` |

The final inventory reconciles both optimizer and both emitter invocations,
all function/declaration/global/alias identities, exact stage output/input chains
and separate runtime/test populations. Independent censuses, ELF/owner audits
and complete ordered-event audits pass. The streams contain 425,500 runtime
and 3,085,054 test records. Input capture, successful optimization, complete
object delivery, behavior outcomes and audit completion have separate proof.

The hook policy is globally Safe: `ZLLVM_ZIG_MODE=ReleaseSafe` selects
`zig-release-safe-accepted`. Compiler-runtime frontend mode remains Fast.
Source review of the unchanged frontend distinguishes LLVM setup construction
from pass execution. Actual local commands and output chains prove delivery;
a real optimizer failure produces one failed optimizer, zero emitters and no
behavior execution. The selected preopt branch executes no LLVM optimizer or
object-emission pass and provides no fallback delivery.

The same Fast executable `f04acdbb` ran the final preopt, full Tier 3 and
preservation checks. Its original dirty-source build receipt remains unchanged;
the committed-source bridge verifies all 666 core files, complete membership,
Git blobs, build settings and pinned Zig/library identities. A separate committed
Debug build `f17e2e00` passes its complete native suite.

| Required preservation | Result |
| --- | --- |
| Tier 3 | All 17 serial gates pass, with authenticated existing AIR reuse recorded and actual backend/native execution. |
| Native corpus | Both 230-population suites pass; the original 225 and five additions remain separate. |
| Historical native outcomes | 8,204 retained per corresponding historical host build. |
| Native artifacts | 3,399 compared per build: 3,381 exact hashes and eighteen exact qualified transitions. |
| Original faults | All 6,724: 3,348 native and fourteen fixed-runtime controls per build. |
| Addition and rejection controls | 414 addition controls, nine artifact rejection controls, eight fault-projection rejection controls and sixteen fixed-object rejection controls. |
| Fixed postopt inputs | Complete 8,928 compiler, 455 runtime, separate 503 Small-runtime and 7,874 Debug behavior definitions, with independent object/event audits. |
| Existing postopt behavior | All 2,097 ordered original outcomes match in Debug, ReleaseFast, ReleaseSafe and ReleaseSmall, with every delivered object independently audited. |

The [preservation diagnosis](release_safe_preopt_preservation_diagnosis_20261115.md)
binds the eighteen exact artifact transitions: C source-path embedding, required
extended negative-zero spelling and a two-byte commutative runtime multiply
exchange. Three separate fixed-object transitions are qualified: one compiler
function, the same two-byte multiply exchange in Small runtime, and two Debug
test bodies with bounded layout changes. All other text/data bytes and normalized
metadata remain strict; original input and ownership identities stay unchanged.
The compiler proof includes 135,166 guarded native observations, ten completed
target/reference compilations and a detected short-copy mutation. The fixed
Debug comparison preserves all 2,097 old/current local outcomes, including one
pre-existing vector-exp failure in that extra experiment. It earns no normal
LLVM outcome acceptance credit. Both changed tests pass; an injected squaring
error produces exactly one additional failure. The separate fresh postopt
matrix matches every normal reference outcome in all four modes.

Both 455-definition runtime builds
pass 21,792 local and 21,792 reference observations each. Exact link replay binds
the runtime change to nine executable identities and 27 fault records per build;
the other 3,321 fault executable records remain exact. Original strict failures
and canceled aggregates keep their original outcomes. Completed subcommand reuse
is explicit and bound to its original receipts and bytes.

Final collector receipt `local-state/retirements/automatic-storage-cleanup/1794833237221762778-1839971/report.json` reclaims
**2,095,722,496 allocated bytes** after closing the superseded compiler
and ten diagnosed fixed/helper workspaces. The user's newly authorized
generalization stage temporarily owns the two qualified Fast/Debug pipelines
through its first baseline/candidate comparison; their exact handoff and release
condition are recorded without pinning compiler bytes. Earlier stage receipts
record collection at each completed
consumer boundary. The cycle's native hold is closed; all seventeen independent
holds and the original six integrity contracts remain unchanged. A seventh
manifest selects maintained proof and inputs, excluding ordinary compilers,
objects, executables, caches and raw traces. Audited trace retirement keeps
whole-stream hashes, semantic audits, original producer/input/report bindings
and copied auditor sources; it does not claim to rehash retired bytes.

Eight diagnosed roots/families account for 975,556,608 allocated bytes and have
specific storage investigations:
five closed legacy ABI roots await supported scoped admission; the canceled R2
child workspace retains its original unfinished-producer guard; and C2's raw
stream retains its unbound-producer provenance investigation. These are recorded
dispositions, without required accepted-proof retention claims or invented
completion. The additional Fast family keeps the original unfinished outer job
hold, three workspaces and two completely audited raw streams. Its actual child
passes every reference outcome and its independent audit passes; a separate
managed verifier rechecks that completed result without replay. The outer exit
and signal sender are unknown. The guarded release rejection is retained;
supported owner recovery must close that original job before any scoped release.
No mutable job control or ordinary payload becomes a new accepted pin.
Adopted frontend/reference/provider/source/throughput dependencies
and maintained bootstrap caches keep their existing contracts and owners.

This closes the [single-mode plan](../plans/2026-11-14-release-safe-preopt-behavior.md).
LLVM IR construction, bitcode parsing, target/analysis/pass-manager setup and
declared providers remain dependencies. Other preopt modes, complete compiler
preopt build/self-rebuild, LLVM IR-builder replacement and provider removal
remain separate milestones. The earlier compiler-generation matrix and
normal-resource self-rebuild acceptance remain separate records.

The user's 2026-11-16 instruction authorizes the compiler-mechanism
generalization plan after this acceptance and commit. Its source admission and
implementation are separate from the frozen Safe candidate.
