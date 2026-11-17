# ReleaseSmall behavior through the local optimizer and object emitter

One unfiltered run matched all **2,097 ordered LLVM ReleaseSmall outcomes**, with
**2,063 OK and 34 SKIP**. The pinned generation-1 frontend and backend source
`c32ba3cf` needed no compiler repair. Both the global hook and the compiler-rt
frontend ran in ReleaseSmall. The hook selected `zig-release-small-accepted`.

| Independently inventoried module | Runtime | Tests |
| --- | ---: | ---: |
| Definitions | 903 | 6,684 |
| Declarations | 48 | 611 |
| Globals | 116 | 4,365 |
| Aliases | 462 | 46 |
| Input bytes before local optimization | 2,595,183 | 14,462,768 |
| Optimizer output and emitter input bytes | 1,928,056 | 10,863,806 |
| Delivered object bytes | 2,825,888 | 18,970,464 |
| Delivered object SHA-256 prefix | `e7a7c80e` | `29f888ee` |
| Audited ordered events | 418,992 | 2,524,350 |

Exactly two optimizer invocations and two emitter invocations account for all
observed capture directories. The optimizer output in each pair matches the
emitter input by delivery path, size and SHA-256. Each input was admitted at
its measured byte length plus one. The selection censuses and independent ELF
and owner audits account for every definition in both objects. The event
auditor read all 2,943,342 events and verified the function scopes, counters,
termination and bindings to the producer, input and report.

The run used normal resources, initially empty private caches, x86_64-linux-gnu
and a baseline CPU. Backend optimization, object emission, native linking and
execution ran afresh. Admission authenticated the existing frontend `972160f2`,
upstream source `1c08b09d`, suite, libc configuration and all 25 providers.
The existing normal LLVM Small reference `61021ed7` matches the generation-1
reference `9fe0c436` on every named result. Those identities permitted reference
reuse. LLVM still supplies IR construction, bitcode parsing, setup and declared
providers.

The complete ordered name/outcome arrays from the local run and its normal
LLVM reference compare byte for byte in compact jqz JSON. Their SHA-256,
including the trailing newline, is
`d2f366d355bce75fc6b8beccb234f92f48cc07b82f4acdd7607940c1103474ba`.

The final failure control gave the real optimizer an input limit of one byte.
The compile returned 1 after one failed optimization, with zero emitter calls,
delivered objects or test executions. The original trial used a Fast-only
matcher, missed the Small invocation and produced two extra objects. Its
child returned 0 and its enclosing check returned 1. Separate object audits
cover those deliveries. The corrected control has its own receipts.

Final verification matched the 679 compiler source files, the SDK executable
and all 19,501 SDK library files to their qualified identities. The backend
executable `995d5d9d` differed from the previous Fast qualification binary
despite matching compiler inputs and flags. The cause of the byte difference
is unknown. Fresh preservation therefore covered the fixed Debug object and
owners, 60 ABI cases, 27 executables, all 17 integration gates and all 237
native populations. The integration reused authenticated frontend AIR for the
real-program rows and reran their backend, object, link and execution checks.
Safe, Fast and four-mode postopt results retain their original execution dates.
The integration run ID is `29797e98b2ddfd9b9308832fdb2949fc`. The maintained
runner's 14 contract tests passed in both Debug and ReleaseFast.

The evidence root is
`local-state/validations/release-small-preopt-20261117/batch-01/`.
`capture-01/run/report.json` contains the ordered execution results.
`reconcile-01/report.json` pairs the stages, `inventory-01/native-summary.path`
locates the strict audits, and `final-verification/report.json` binds the
completed preservation checks. The two raw event streams were retired after
audit, reclaiming 917,413,888 allocated bytes.

The outer setup command returned 143. Its checked monitor disappeared with an
unknown terminal outcome. A separate admission verified the completed SDK child
build and its actual exit of 0. The original layout, checked receipt and job
record preserve this distinction. The storage recovery tool has its own
Debug and ReleaseFast qualification at patch `b89ae2ec`. The review and
operational decisions are recorded in the
[interrupted-workspace plan](../plans/2026-11-17-interrupted-workspace-recovery.md).

The first real dry plan included 12 independently owned controls in its
retained list. The reviewer held that plan. The successor kept historical
control copies, checked the live protections and had one ready action in dry
review. The separately authorized apply removed that workspace, reclaiming
265,383,936 allocated bytes. Its final record preserves the 25 reviewed paths
and the unknown monitor outcome. Both the native command and post-checks
returned zero. The transaction receipt is `1794957605971871164-1072275`.

The final project documentation check returned 0 after checking 24 documents,
565 internal links and two generated status blocks. Its first command failed
during build-option parsing. A release attempt for that cache was deferred
while a sibling coordinator matched the old run name. The original receipts
are under `documentation/` and `documentation-r2/`, and `project-docs/`
contains the successful checked command.

The final inventory accounts for 63 owned workspace roots. All were retired,
including the r5 tools in receipt `1794957870653458992-1079030` and the final
documentation workspace in `1794958702101664120-1096803`. The remaining
evidence contains no raw event streams, ELF files or archives. The 468-file
maintained manifest hashes to
`dcb1fe9ba263f06ffd2ce46d81a47ac5af2eeab57a7eb2fc2faccceadc60c36a`.
It is the ninth current proof contract. All nine verified after registration.
The original eight paths and hashes, the rest of the policy and all 17 manual
holds matched their pre-registration identities. The machine-readable record
binds the original results, source, recovery transaction and storage closure.
[Acceptance record](release_small_preopt_acceptance_20261117.json)
