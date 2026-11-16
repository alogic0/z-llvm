# Compiler generalization: optional-pointer composition

Status: stage 3 accepted after cumulative integration, final source, compiler
and contract verification, and storage closure. Baseline is the accepted table
source `1032e124`. Evidence is under
`local-state/validations/compiler-generalization/batch-01/stage-03/`.

The obsolete load/return handler and its named optional-pointer helper are
removed from air_patterns_optional_pointer.zig, along with their sole fallback
caller. Ordinary pointer comparisons, branches, loads, PHIs and returns use
composed CFG selection. The original raw family and captured row already had
composed ownership under the normal predecessor; their exact objects and owner
manifests are preserved. This removes unused fallback recognition rather than
claiming a new owner for those accepted rows.

The standalone fixture covers the original helper name, a renamed PHI with a
load adjustment, independent live noise across a branch and a six-parameter
pressure case that really spills. Strict composed tests execute both null and
nonnull paths before and after permissible XOR commutation. Unsupported vector
return ABI admission still rejects with complete machine rollback. Source IR
is unchanged by selection. The remaining `lowerRuntimeOptionalPointerPreoptMain`
and `lowerRuntimeOptionalPointerMain` shapers, plus their
`isRuntimeOptionalPointerPreoptCall` call-name predicate, remain for the fixture's
main-function forms. Their call substitutions are outside this slice; no new
call-to-direct-operation substitution or proof is introduced.

The first release-route comparison exposed existing wrong code after commuting
`xor -1, noise` to `xor noise, -1`. Both the predecessor and initial cleanup
compiler emitted byte-identical faulty objects; LLVM verifies and executes the
same optimized input correctly. A computed scalar's canonical register home
changed while emitting the absent arm and was then read on the present arm,
where that move had never executed. A spelling-sensitive frame heuristic hid
the missing preservation in the original spelling.

The separate repair derives persistent-home demand from existing CFG live-out
facts for instruction-produced 32/64-bit GPR values at conditional, switch and
indirect forks. Existing frame setup and boundary spilling establish the homes
before the fork. ABI inputs, linear edges and unsupported classes retain their
contracts. No register, frame-size, argument or proof-budget limit is increased.
The exact original optimized failure now executes correctly and matches LLVM.

The repaired source passes 110 selected tests in Debug and Fast, all 2,409 Fast
units and 74 structural checks. The original build aggregate remains failed
because its isolated source could not resolve owner-relative integrity paths;
build-repaired-seal verifies the completed unit/structural results and all seven
contracts from the storage owner. It does not rerun or rewrite the failed receipt.

Qualification preserves two raw objects and their owners, passes 6,336 local
observations against 3,168 independent LLVM observations, detects all 72 controls,
and passes captured-row object smoke, 60 ABI cases and three hello modes. The
first final aggregate stopped at the private checkout's default Zig source path;
qualification-complete authenticates completed comparisons and executes the
remaining checks with an absolute source path. Original aggregates stay failed.
The fixed 67,658,559-byte Debug module also compiles with byte-identical objects
and owner manifests before and after this repair. That is preservation evidence,
not a performance comparison.

The repaired Fast compiler is
30ecba944d662061985dcedc4dab8484bc99462262e90b2a1dcd993415508418.
Main must match its qualified source before and after all 17 integration gates.
Confirmed wrong code and shared allocation/frame behavior require this full gate
before stage acceptance or production identity promotion.

All 17 serial integration gates pass in integration on the unchanged promoted
source. The checked command returns zero after verifying source/compiler bytes
and all seven contracts. The upstream C report passes all three release modes,
contains all 232 registered observation populations and binds the exact current
registry digest and 30ecba94 compiler. The optional-pointer population again
records 6,336 local observations and 3,168 LLVM observations. Three authenticated
frontend AIR hits reuse no backend objects or executable results.

Serial wall time is 3,908,514 ms, with a minimum observed 133,413,277,696 free
bytes. These are validation accounting, not a compiler performance comparison.
main-promotion preserves the eight-file source delta and verifies every qualified
relevant byte on main. source-disposition removes the original worktree through
Git after that transfer and closes both empty workspace wrappers in receipt
1794857523710525503-2535910. The repaired compiler remains only through the
now-completed full gate and previously completed identity comparisons. Its
explicit closure is recorded in
`closure/report.json`; receipt
`1794862292703584416-2713265` collects the compiler and outer gate workspace,
reclaiming 983,695,360 allocated file bytes. No eligible candidate remains.

Automatic post-gate collection at
local-state/retirements/automatic-storage-cleanup/1794861853797963414-2702969/report.json
reclaims 2,015,633,408 allocated file bytes from twelve completed workspaces.
The temporary real-row evidence roots are empty after the serial runner's own
closure. All original failed receipts, selected reproduction inputs, commands,
source deltas and identities remain maintained.

The corrected identity and scheduling experiment compilers and their isolated
source worktrees retain only their named next consumers. The known blocked-hello
and legacy-ABI admission exceptions remain diagnosed closed ordinary products,
with no validation consumer. Seven integrity contracts, seventeen independent
holds and historical model/fe2 exception ownership remain unchanged.
