# Constant-table consumer fallback

Status: accepted after Tier-2 qualification and storage closure under
`local-state/validations/table-contract-fixes-20261116/batch-02`.
The user's follow-up identifies the remaining consumer-side P2 gap in
`1fa64f9e`; the older unrelated worker inbox does not control this repair.

The new full-selector test reproduces the exact valid bounded `i32` load from a
literal 64-element i16 table. Unchanged production code fails that success test
with `UnsupportedCodegenInstruction`. The preserved predecessor report records
the actual test exit 1 separately from its successful reproduction wrapper.

Table reservation now checks every live structured use of the derived address.
Each load must fit the descriptor's shared load-type/access contract. The same
contract is checked by specialized lowering. The existing first +8 double-pair
tail is checked recursively, with no broader offset admission. Mixed consumers,
other derived addresses, escapes, terminators, atomic loads and uncertain opaque
use coverage choose ordinary pointer materialization. Removed instructions do
not count as live consumers. This is conservative optional-specialization
admission, without adding a new specialized load width.

The regression calls the complete production selector, verifies its machine
function and ELF output, and checks ordinary symbolic addressing. It includes
the reported load, a supported i16 load sharing its pointer with an i32 load,
and an unsupported derived-address consumer. All 76 table tests pass in Debug
and Fast, including existing i16/double/pair and local ELF placement controls.
All 2,422 Fast units and 74 structural checks pass on unchanged consumed source.

The maintained generator extends the existing `table_contracts` population with
wide loads, mixed-width consumers, a derived wide load and an escaped pointer.
LLVM verifies the generated IR. Its C oracle checks independent little-endian
word assembly and safely reads the returned pointer using memcpy. Deterministic
generation, 1,280 independent reference observations and all ten generation
faults pass. Native direct/release routes in three modes pass 7,680 local versus
3,840 LLVM observations and 90 faults. The three prior table populations also
pass; the four populations detect all 234 native faults. Registry population
count remains 235; no compiler-core or compiler-rt ratchet changes.

Candidate Fast compiler is
`6d31ed937856d2d93596469ad5dc7f360c78e7b314a86f0f4bee6b07b8415086`.
This compile-rejection repair uses Tier 2; ABI, ELF emission, verifier invariants,
milestones and confirmed wrong-code behavior are unchanged. The previous
seventeen-stage result is historical evidence for its earlier source and is not
reused as current integration acceptance.

The first qualification aggregate preserves its actual failed legacy TLS-symbol
inspection: its script incorrectly forced generic selection for a default-route
inspection. Its four successful native reports are reused only after exact
source/compiler/result checks. The first successor also remains failed: setup
assumed a nonexistent optional build.zig.zon and ran no remaining tests.
`qualification-complete-v2` copies only the two actual build files and uses normal
selection settings. Captured-row object smoke, all 60 ABI differential cases and
hello_libc in three release modes pass. That aggregate then fails the fixed-canary
preflight because its contained root lacks the emitter pin file; it earns no
fixed-canary or M1 execution credit.

`qualification-final` supplies the existing pin-file option and read-only inputs,
verifies the earlier source/compiler/report identities, and executes the remaining
tools. The fixed __multi3/FMA object and execution checks pass, as do all 27 M1
executable cases. These setup corrections change no production or test source.
All three failed aggregates, diagnoses and completed-subcommand credit remain
explicit; no failed aggregate is relabeled as passed.

All consumers are closed and the candidate compiler pipeline is released.
Producer teardown removes only verified borrowed source links and stages the
diagnosed legacy inspection products after their consumers close. Native
publication's original `SpecialCacheEntry` refusal is preserved; `closure-v2`
verifies its one completed release before publishing the remaining releases.

The final guarded collection receipt is
`local-state/retirements/automatic-storage-cleanup/1794889249523529806-3461028/report.json`:
three temporary trees and 776,380,416 allocated file bytes reclaimed. Earlier
stage receipts record their completed collections, including the default-route
compiler and legacy inspection teardown. No task temporary files or default
main compiler payload remain. Original source targets, seven current integrity
manifests, policy and all seventeen independent holds are unchanged.
