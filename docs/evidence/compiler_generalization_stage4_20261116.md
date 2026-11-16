# Compiler generalization: compact scoped identities

Status: accepted after all cumulative gates, source/compiler/contract checks
and storage closure. Evidence is under
`local-state/validations/compiler-generalization/batch-01/stage-04`.
The selected caller contracts are recorded in `caller-audit.md`.

The baseline is accepted CFG source `6be85e91`; the admitted target is Linux
x86-64 with Zig 0.17.0. The implementation is in
[scoped_names](../../src/codegen/x86_64/generic_cfg/value_use/scoped_names.zig),
with the unchanged-source execution regression in
[value_use_names](../../src/tests/value_use_names.zig).

Value-use Identity and PreparedIdentity become a namespace and numeric slot,
at most 16 bytes, instead of separate 512-byte owned name buffers. A selector
owns an append-only name pool for one function/rewrite attempt. It retains each
exact source name once. Hash lookup uses byte equality; interning neither
canonicalizes quoted/escaped spelling nor changes the existing distinction
between numbered slots and quoted numeric names. Semantic ordering still uses
resolved lexical bytes, never insertion order or numeric IDs.

Namespaces are process-unique and checked for exhaustion without wrapping. A
handle resolves only in its live pool, rejecting other functions, generations,
deinitialized/reused storage and invalid slots before name lookup. Insertion
owns the bytes and reserves capacity before publication; allocation failure
publishes no partial name, slot or namespace. Complete memo entries may survive
rollback, but their slots never change meaning. Retries and rewrites create
fresh selector pools. Each instruction transaction also receives a unique
namespace, checked with its authority pointer and view generation, so reusing
the same transaction address cannot revive request or accumulator-session handles.

The bounded migration covers source correlation, lifetime snapshots, prepared
table symbols/address components, source resolution and semantic ordering.
ActionIdentity remains a separate 512-byte result/callee/label representation;
the address-dependency domain retains its 192-byte boundary. The private
rename-and-retry path remains for those consumers. This stage does not claim
all backend name limits are removed.

The strict composed regression executes source parameter names longer than 512
and 4,096 bytes without a private renamer, including distinct long shared
prefixes. Source printing remains exact. Its first three functions execute
through the strict JIT probe; the fourth uses a linked external identity_sink
call whose real symbol and relocation remain unchanged. The maintained native
fixture uses 769-byte names because LLVM's ordinary local-name limit truncates
the earlier larger fixture; its original reference failure is retained. The
normal predecessor rejects the new ABI parameter names with exit 2 and
ValueUseIdentityTooLong. Its existing alpha retry explicitly declines such long
parameter/block names; the current compiler succeeds through the normal route.

Focused tests cover exact spelling, long prefixes, cross-pool and stale handles,
rollback followed by a different name, all insertion allocation failures,
transaction OOM atomicity, foreign sources and same-address request/session
reuse. The transaction layout falls from 688,656 to 269,984 bytes, with exact
static layout assertions updated and checked. This is a representation-size
result, not a measured compiler RSS or wall-time result.

The new scoped_names leaf is enumerated by the source guard and may import only
std; its public surface is freshNamespace, Identity and Pool. Guard mutation
tests reject authority/inline imports and additional public declarations. The
historical split-policy bindings moved to their existing identical qualified
copies before main changed, preserving all 24 ordered frozen digests, the other
22 rows, six other contracts and seventeen independent holds.

The corrected source passes 244 selected tests in Debug and Fast, all 2,417 Fast
units and 74 structural checks. Six previous objects and owner manifests remain
byte-identical. The new fixture passes 6,336 local observations against 3,168
LLVM observations and all 36 controls; captured-row smoke, 60 ABI cases and
hello in all three release modes pass. The original qualification aggregate
assumed predecessor failure code 1 and stopped after actual code 2; its failed
receipt remains. qualification-complete verifies the six completed comparisons,
checks the actual predecessor diagnostic and executes the remaining checks.

The fixed 67,658,559-byte Debug module also compiled through this exact compiler
as the baseline leg of stage-05/qualification. Its object digest is
92825c8e7821e8c2becc774942f149aacfd14a99167247199b1ee44c4d4d81c1,
matching both objects recorded in stage-03/full-module-qualification. Its owner
manifest is byte-identical to that stage's after.owners.tsv. This reuses the
completed fixed-input observation with the same target, Debug environment,
reachability and report-all settings; that baseline leg enabled diagnostic
profiling. It is preservation evidence, not an unprofiled timing comparison.

The corrected Fast compiler is
067d6892b93184981328189692a3879275d35fa698da35d66b858caaea6729ba.
All 17 serial integration gates pass on the unchanged promoted source. The
checked command returns zero after verifying the complete relevant source,
compiler and seven current contracts. The upstream C report passes all three
release modes and all 233 registered native populations. It binds compiler
067d6892 and registry digest
`1e4903aff4d9354667d4d4fba2c86ed95ea6c2e175d0aa903266e7d235f7e88f`.
The identity population again records 6,336 local observations and 3,168 LLVM
observations. Three authenticated frontend AIR hits reuse no backend objects or
executable results. The source-owned object bundle retains identity
`3b65f5608098bf2c5f7816bea4b38a0cf0333797b516d1c7ae21d1f7e89d5249`.

Serial wall time is 3,648,708 ms, with a minimum observed 112,105,938,944 free
bytes and the unchanged 20 GB admission floor. This is validation accounting,
not a compiler performance comparison. `main-promotion` preserves the 28-file
qualified delta and verifies every relevant byte on main; the separate v6
policy change preserves the frozen contracts. `source-disposition` removes
the original source worktree through Git after transfer, closing its two empty
workspace wrappers in collector receipt
`1794863617304177561-2741978`. Final compiler release follows its now-completed
measurement and full-integration consumers.

Automatic post-gate collection at
`local-state/retirements/automatic-storage-cleanup/1794869667393900608-2967788/report.json`
reclaims 2,016,063,488 allocated file bytes from eleven completed workspaces.
The receipt records complete collection and verified current integrity. Original
failed receipts, selected reproductions, commands, qualified source deltas and
identities remain maintained.

Final compiler and integration-cache closure is recorded in
`local-state/retirements/automatic-storage-cleanup/1794870063641240152-2977403/report.json`:
two verified trees and 1,003,560,960 allocated file bytes reclaimed. All named
compiler and source-worktree consumers are complete. The seven current
contracts and seventeen independent holds remain intact. Production scheduling
is unchanged; the isolated stage-5 prototype was measured and deferred.

Two closed ordinary-product roots retain specific admission exceptions, with
no current validation consumer. The 49,020,928-byte stage-2 hello workspace has
an original terminal `blocked` aggregate that the workspace publisher does not
admit; the 45,977,600-byte `tmp/inbox66_abi_diff/run-1892218` tree uses an
unsupported legacy producer layout. They are not required acceptance data.
Neither original report is rewritten and no replacement producer is fabricated.
At compiler closure, the hello root is the only remaining populated managed
temporary workspace in this cycle; the legacy ABI root is outside that tree.

The acceptance commit matches all qualified relevant source bytes. Original
dirty build receipts and the preserved stage-4 delta remain unchanged;
`stage-04/acceptance.json` records the committed-source bridge and terminal
integration, documentation and closure results. Temporary artifact identities
remain provenance, without pinning the retired compiler or emitted objects.
