# Complete compiler selection

Status: resumed at the user's request after the validated performance deliveries
at `c19bdc66` and `0bf96594`. The latest accepted checkpoint is `669fd097`,
selecting 8,860/8,928 compiler definitions and 351/455 runtime definitions.
Continue through all 68 remaining original compiler definitions.

Baseline: accepted code `7080d454`, documentation `742e35fc`; compiler
7,799/8,928, runtime 284/455. Preserve the original compiler input SHA-256
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`
and all existing successful function identities. The denominator and input
must not change to manufacture coverage. Selection remains distinct from
complete object emission, compiler startup and self-rebuild.

1. Classify remaining failures from the complete census and inspect concrete
   operands, types and physical locations. Add diagnostic context only where
   existing records cannot identify the boundary.
2. Implement cohesive groups through shared typed selector, transfer, storage
   and ABI contracts. Preserve defined behavior, alias/liveness and rollback
   invariants. Use executable edge cases and independent LLVM comparisons;
   never admit a function by name or return placeholder code.
3. After each coherent change, replay affected original functions and check
   prior successes. Reclassify later failures instead of assuming the first
   boundary was the last one. Continue across families without requesting
   renewed authorization for this goal.
4. Use the validation tiers: focused checks during implementation, Tier 2 for
   provisional commits, and cumulative serial Tier 3 at cohesive checkpoints
   and final acceptance. Respect immediate Tier-3 triggers for correctness,
   ABI/frame/relocation invariants. Existing logs apply only to matching inputs.
5. Finish with a complete original-input census and production replay that
   both select exactly all 8,928 definitions, complete event audits, source and
   binary identity checks, preserved native populations and full integration.

The first work group investigates scalar comparisons and pointer/FP freezes;
later groups follow the observed frontier. Keep the core prefix/cohort and
ratchet 130 unchanged unless separately supported by explicit evidence. Preserve
all original inputs, accepted evidence, AIR payloads and thirteen scratch files;
create no archives. Use the authenticated quoted-symbols AIR generation when
its producer identities match. Source or cache infrastructure changes follow
their own validation routing.

Evidence root: `local-state/validations/compiler-selection-completion-20261108/`.
The previous accepted checkpoint remains authoritative until a new cumulative
acceptance is recorded. Progress counts before that are provisional.

The first checkpoint is accepted at `9ba5e61c`: pointer freeze aliases, private normalization
of scalar `samesign` comparisons and signed interpretation of unsigned-spelled
i32 immediates. It fixes a confirmed dirty-upper-bit i8 comparison miscompile.
Debug and ReleaseSafe pass 1,995 units and 23 structural checks each. Two new
native populations pass all modes/routes with Debug and ReleaseFast compilers.
The complete compiler census and production replay select 7,943/8,928, adding
144 with every preceding success preserved. All 164 targeted first boundaries
advance; twenty reach later limits. Runtime reaches 285/455. Event audits,
readiness and all 17 integration gates pass. The 66 native populations record
2,043,396 local observations and preserve all 64 preceding populations. See the
[accepted evidence](../evidence/scalar_comparisons_pointer_freeze.md).

The second checkpoint is accepted at `636816de`: mandatory private zero/null
refinement of undefined call operands and validated pointer capture, readnone
and initialization promises. Compiler census and production replay select
8,170/8,928, adding 227 with no lost successes; runtime retains 285/455.
Debug/ReleaseSafe each pass 1,999 units and 24 structural checks. All nine
readiness commands and 17 integration gates pass. All 67 native populations
pass, preserving the preceding 66, and the twelve-function new call population
passes both routes and all modes with frozen Debug/Fast builds. See the
[accepted evidence](../evidence/call_values_pointer_promises.md).

The third checkpoint is accepted at `d06659d1`: exact vector/scalar bitcasts,
stable lane PHIs, wider internal integer and pointer vectors, scalar freeze and
closed lane intrinsics, with preserving typed shifts under register pressure.
Compiler census and production replay select 8,422/8,928, adding 252 without
lost successes; runtime retains 285/455. Debug/ReleaseSafe each pass 2,004 units
and 24 structural checks. All nine readiness commands and 17 integration gates
pass. All 69 native populations pass and preserve the preceding 67. Both new
populations pass both routes and all modes with frozen Debug/Fast builds.
See the [accepted evidence](../evidence/integer_vector_graphs.md).

The fourth checkpoint is accepted at `5d71dc80`: general runtime copy views,
exact integer memory, private undefined select arms and conservative pair-word
reuse/cleanup. Complete census and production selection reach 8,552/8,928,
adding 130 with no lost successes; runtime retains 285/455. Debug/ReleaseSafe
pass 2,013 units and 24 structural checks, with a valid cached Debug structural
result. Readiness and all 17 serial gates pass; 72 native populations preserve
the prior 69. The interrupted outer full/census captures remain explicit;
durable final gate records and independent production matching verify the work
without inferring unavailable wrapper exit statuses. See the
[accepted evidence](../evidence/runtime_integer_storage.md).

The fifth checkpoint is accepted at `bb74a371`: canonical graph indexes,
complete successor liveness, scalable traversal storage, private indirect scalar
PHI slots and 512-byte owned value-use identities. Complete compiler census and
production replay select 8,664/8,928, adding 112 with no lost successes; runtime
retains 285/455. Debug/ReleaseSafe pass 2,030 units and 24 fresh structural checks.
Readiness and all 17 serial gates pass with durable actual checked return codes.
All 74 native populations preserve the prior 72. The first compiler production
attempt timed out; the completed same-source retry with an explicit existing
two-hour deadline supplies the matched production proof. The 2,759-file seal
verifies. See the [accepted evidence](../evidence/scalable_cfg_indirect_phi.md).

That checkpoint leaves 264 compiler definitions. The following frame
source at `726a7c55` passed all 17 integration gates and 75 native populations;
its incomplete whole-input attempts were explicitly superseded. The integer
intrinsic slice at `f955509f` then passed all 17 gates and 76 populations,
preserving the previous populations. It adds signed saturation, i128 leading-zero
count, signed comparison, poison-enabled scalar absolute value, and the observed
fixed-product and shift forms. Its current-source original probes select eleven
of nineteen targeted definitions, with eight later boundaries; the complete
runtime census retains 285/455 without lost successes. The accepted whole-compiler
count remains 8,664/8,928 because complete current-input acceptance is pending.
See the [slice evidence](../evidence/integer_intrinsic_slice.md).

The earlier request to finish the integer intrinsic slice and stop was honored.
The user subsequently resumed this main plan. Batch 08 begins with current-source
replays of the retained nineteen-function frontier and shared aggregate PHI/freeze
boundaries. Performance work interrupts capability work only when a required
replay cannot finish. Evidence is retained under the existing root's `batch-08/`.

Batch 08 implements private integer/pointer-and-flag PHIs, selects, constructors
and freezes, named integer freezes through 64 bits and i65/i96 carriers, and
preserving atomic storage views. The first integer-pair source passes 2,053 units,
24 structural checks and two profile checks in both Debug and ReleaseSafe. Its
77-population Debug native run preserves all previous observations and all 1,161
prior compiler artifacts byte for byte. The nineteen original targets advance
from eleven to fourteen selections, with no lost preceding successes; runtime
retains 285/455 and the preceding slice's owners. Its cumulative integration run
passes twelve gates before a missing temporary Zig cache object stops a harness
link. The exact harness passes all modes/routes with isolated caches. No complete
Tier-3 or whole-compiler acceptance is claimed for that attempt. The expanded
aggregate group receives fresh cumulative validation with isolated harness caches;
full original-input census and independent production replay still accept counts.

The final combined source passes 2,061 units, 24 structural checks and two
profile checks in both Debug and ReleaseSafe, with all nine readiness procedures
covered by fresh checks and verified reuse. Its complete 79-population Debug
and ReleaseFast native suites preserve all 76 preceding registry entries,
2,837 command outcomes and 1,161 compiler artifacts per build. All 270 calibrated
faults are detected. All nineteen retained original targets select, with the
expanded diagnostic selecting 24/25; the runtime census retains 285/455 and
preceding owner identities. All 17 cumulative serial gates pass with checked
return code zero and the 3,157-file source snapshot verified afterward. See the
[validated slice](../evidence/ssa_transport_storage_slice.md).

The [seven-helper Zig migration](../evidence/batch08_zig_helpers.md) is committed
at `2afa81e8`. Generators reproduce all retained bytes; the maintained native
runner, fault checker and comparator replace research and comparison scripts.
The active workflow uses no Python, including inline inspections and edits.

The first-source 264-target diagnostic actually times out at its one-hour
deadline in `codegen.loongarch.Assemble.parseInstruction`, with 211 complete
function records and no terminal census event. It supplies no complete coverage
count. Bounded final-source profiling identifies liveness lookups, hashing and
binding scans as the remaining replay bottleneck; an isolated prototype follows
the plan's explicit performance exception. Those interrupted attempts are
superseded by the complete unchanged-input proof below.

Batch 08 is accepted at `dba98f43`: reusable eager selector snapshots and derived
physical-binding counts preserve capture timing, rollback, dependency errors and
fixed transaction guards. Debug/ReleaseSafe each pass 2,066 units, 24 structural
and two profile checks; readiness and all 17 serial gates pass. Both complete
79-population native suites preserve 2,945 outcomes and 1,206 compiler artifacts.
The original-input census and independent production replay both traverse all
8,928 definitions and select 8,722, adding 58 with every prior success and owner
preserved. Complete event and source audits verify; runtime retains 285/455.
The 206 remaining definitions are still in scope, beginning with observed
integer-carrier and physical stack-argument boundaries. See the
[accepted checkpoint](../evidence/compiler_selection_batch08.md).

Batch 09 is accepted at `7d419080`: shared incoming/outgoing physical integer
locations, aligned native i128 stack pairs, split i65–i127 words, private carrier
classification and preserving pair-low extraction under full register pressure.
Debug/ReleaseSafe each pass 2,076 units, 24 structural and two profile checks;
readiness and all seventeen serial gates pass. Both complete 80-population native
suites preserve the preceding 79 entries, 2,945 outcomes and 1,206 artifacts.
All 126 new-population fault checks detect their injected errors. Complete
unchanged-input census and independent production agree on 8,739 compiler and
296 runtime selections, adding seventeen and eleven respectively without lost
successes or owners. Complete event audits and all 3,173 committed source hashes
verify. Both production reports still stop at remaining selection failures.
Continue through all 189 remaining compiler definitions, beginning with the
observed fp128 storage/transport and structured-value families. See the
[accepted physical ABI evidence](../evidence/integer_physical_abi.md).

Batch 10 is accepted at `7a96ace8`: exact private binary128 transport, owned
bitcasts/freezes, standard numerical helpers and all sixteen comparisons, with
complete XMM return verification and preserved bitwise negation. Explicit
structured-module ownership closes emitted helper definitions while imported
Zig IR retains its external runtime policy. Debug/ReleaseSafe each pass 2,086
units, 24 structural and two profile checks; readiness and all seventeen serial
gates pass. Both complete 81-population native suites preserve all 80 preceding
entries, 2,981 outcomes and 1,221 compiler artifacts byte for byte. All 126 new
fault controls are detected. Complete original-input census and independent
production agree on 8,754 compiler and 318 runtime selections, adding fifteen and
twenty-two without lost successes or owners. All 4,379,680 compiler events balance
and all 3,186 frozen file hashes bind to the committed tree. Production still
stops at remaining selection failures. Continue through all 174 original compiler
rejections, beginning with stack-object copy and PHI pointer views. See the
[accepted binary128 evidence](../evidence/binary128_payloads.md).

Batch 11 is accepted at `948fad9c`: owned scalar, integer-pair and array frame
addresses pass through copy, pointer-PHI, byte-offset and direct-call contracts.
The change fixes confirmed pointer-PHI swap and simultaneous copy-source
miscompiles. Debug/ReleaseSafe each pass 2,095 units, 24 structural and two
profile checks; readiness and all seventeen serial gates pass. Both complete
82-population native suites preserve all 81 preceding entries and 3,017 outcomes.
Of 1,236 prior artifacts, 1,218 are byte-identical; the same eighteen intentional
object changes in three populations pass LLVM comparison and explicit review.
The strict requires-review results remain intact. All 180 new fault checks
detect their errors. Complete original-input census and independent production
agree on 8,777 compiler selections, adding 23 without lost successes or owners;
runtime retains 318. All 4,363,840 compiler events balance, and 3,195 frozen file
hashes bind to the code commit. The final test-only correction preserves exact
Fast/census binaries; Debug native/fault proofs are freshly replayed, with its
inspection discrepancy and superseded records explicit. Continue through the
remaining 151 original compiler rejections. See the
[accepted frame-address evidence](../evidence/stack_object_addresses.md).

Batch 12 is accepted at `08616a11`: independent owned-object eligibility and
checked symbolic integer operands use the existing typed address contracts.
Debug/ReleaseSafe each pass 2,097 units, 24 structural and two profile checks;
all nine readiness procedures and seventeen serial integration gates pass.
Both complete 84-population native suites preserve all 82 preceding entries,
3,053 command outcomes and 1,251 compiler artifacts byte for byte. All 126
new fault controls detect their errors. Complete unchanged-input census and
independent production agree on 8,792 compiler selections, adding fifteen with
no lost successes or owners; runtime retains 318. All 4,364,586 compiler events
balance, and all 3,205 frozen file hashes bind to the accepted code tree.
Production still stops at the remaining 136 selection failures. Continue with
the measured scalar shift and call-attribute boundaries, then every remaining
original rejection. See the
[accepted address-operand evidence](../evidence/address_value_operands.md).

Batch 13 is accepted at `2eb2fc9b`: private word/pair shifts and bounded narrow
or nullable call attributes add fifteen compiler selections, retaining every
previous success and owner. Complete original-input census and independent
production agree on 8,807 compiler selections; runtime retains 318. All
4,366,614 compiler events balance. Debug/ReleaseSafe each pass 2,106 units,
25 structural and two profiling checks; all nine readiness procedures and
seventeen integration gates pass. Both complete 86-population native suites
retain all prior entries and 3,125 outcomes. Twelve intentional native object
differences and nine core object differences retain their strict failures and
explicit function-byte/ablation reviews. All 162 fault controls are detected.
All 3,218 frozen source hashes bind to the accepted code tree. Continue through
full-width integer division, typed i52 truncation and two-word record freezes,
then every remaining original rejection. See the
[accepted shift and call evidence](../evidence/shift_and_call_operands.md).

Batch 14 is accepted at `631c973d`: standard full-width i128 division, private
word bridges for i52 truncations and stable freezes of existing flat two-word
records. Complete original-input census and independent production agree on
8,823 compiler selections, adding sixteen without lost successes or owners;
runtime retains 318. Debug/ReleaseSafe each pass 2,109 units, 25 structural and
two profile checks; readiness completion explicitly retains a missing Zig cache
object failure and its successful isolated-cache resume. All seventeen serial
gates and both complete 89-population native suites pass. Both strict native
comparators preserve all 3,197 preceding outcomes and 1,311 artifacts per build
exactly. All 162 new fault controls detect their errors. All 36 selected core
objects and observations match; wrapper metadata differences and strict log
failures remain explicit. All 4,367,199 compiler events balance, and 3,235 frozen
file hashes bind to the committed code tree. Continue through all 105 remaining
original compiler rejections. See the
[accepted integer pair/storage evidence](../evidence/integer_pair_storage.md).

Batch 15 is accepted at `52d29d4c`: half products, quotients, exact negation
and memory views, standard half/quad and i128/quad conversion helpers, and
mixed scalar-SSE integer-pair calls. Complete compiler census and independent
production agree on 8,829 selections and 99 rejections, adding six with no
lost selections or owners; runtime reaches 320/455, adding two. Debug and Safe
each pass 2,114 units, 63 structural and two profile checks. Readiness and all
17 integration gates pass. Both 91-population native suites pass 59,822,370
local observations per build and preserve the preceding 89 populations,
3,305 command outcomes and all 1,356 artifact hashes exactly. All 108 new fault
controls are detected. Source/binary/event and retained-input audits pass.
The failed preflight full-v16 launch remains explicit; fresh same-source
full-v17 supplies complete acceptance. See the
[accepted half/conversion evidence](../evidence/half_and_extended_conversions.md).
Continue through all 99 original failures. The isolated extended80 payload and
direct-call successor is provisional until its complete replays are accepted.

Batch 16 is accepted at `50ba1a5d`: exact extended80 payloads, aligned memory
arguments and direct-call ST0 capture/return. Complete compiler census and
independent production agree on 8,838 selections and 90 rejections, adding nine
with no lost selections or owners; runtime reaches 331/455, adding eleven.
Debug/ReleaseSafe each pass 2,121 units, 63 structural and two profile checks.
Readiness and all seventeen integration gates pass. Both complete 92-population
native suites preserve all preceding 91 entries, 3,377 outcomes and 1,386
artifact hashes per build exactly. All 54 new fault controls detect their
errors. All 4,371,382 compiler event rows audit successfully; source, binary,
retained-input and core-object checks pass. See the
[accepted extended80 transport evidence](../evidence/extended80_payload_transport.md).
Continue through all 90 original rejections. Isolated numerical conversion,
comparison and sign-operation results require their own cumulative acceptance.

Batch 18 accepts the combined conversion, predicate and sign work at
`669fd097`. Complete original compiler census and independent production agree
on 8,860 selections and 68 rejections, adding 22 without lost successes or
owner changes; runtime reaches 351/455, adding twenty. All 4,375,366 compiler
event rows audit successfully. Debug/ReleaseSafe each pass 2,127 units,
63 structural and two profile checks; readiness and all seventeen integration
gates pass. Both complete 96-population native suites preserve all preceding
92 entries, 3,413 outcomes and 1,401 artifact hashes per build exactly. All
216 new fault controls detect their errors. Every selected core object and
observation matches; reviewed wrapper metadata and strict log differences
remain explicit. Source, binary and retained-input bindings pass, including
fresh distinct-name records after an initial receipt/report filename collision.
See the [accepted floating evidence](../evidence/floating_conversions_predicates.md).
Continue through all 68 original compiler rejections. Isolated store-only half
storage, wide byte swaps, scalar vector choices, further conversions and math
intrinsics receive no cumulative acceptance credit until complete replays.
