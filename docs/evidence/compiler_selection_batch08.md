# Batch 08 compiler-selection checkpoint

Accepted source: `dba98f4347d614643233cde6db535976eb557992`, following
`bb74a371`. The active [all-8,928 plan](../plans/2026-11-08-complete-compiler-selection.md)
continues through all 206 remaining compiler definitions.

Record: [acceptance JSON](compiler_selection_batch08_acceptance_20261110.json).
Raw evidence: `local-state/validations/compiler-selection-completion-20261108/batch-08/parser-throughput/`.
`accepted-artifacts.sha256` pins the retained binaries, source seals and proof records.

| Population | Before | After | Remaining | Lost successes |
| --- | ---: | ---: | ---: | ---: |
| Compiler | 8,664 / 8,928 | 8,722 / 8,928 | 206 | 0 |
| Runtime | 285 / 455 | 285 / 455 | 170 | 0 |

This accepts the cumulative frame, integer-intrinsic and
[SSA/atomic-storage work](ssa_transport_storage_slice.md). Snapshot-storage
changes make the required whole-input replays finish; they introduce no new
function-admission rule, opcode or public ABI. The
[seven-helper Zig migration](batch08_zig_helpers.md) remains in the active
workflow; historical Python files are retained as evidence and are not executed.

## Selector changes

Physical-location filters precede pure interval lookup when the address-dependency
domain is empty. Production selectors also track counts of accumulator, scalar,
pair and XMM bindings. A zero count can skip a scan; positive counts retain the
original iteration and choice. Nonempty dependency domains keep their existing
validation traversal, including errors on unrelated homes. Canonical binding
mutation maintains counts, and rollback rebuilds them from restored bindings.

Both transaction implementations borrow reusable storage owned by the selector.
Every begin still eagerly captures all names, virtual-register metadata and value
locations in the original order. Simultaneous snapshots lease distinct buffers;
rollback keeps the original clear/reinsert sequence. Released storage can grow
and be reused, and selector destruction frees it. Nested rollback and allocation
failure tests verify that active captures survive reuse and failed growth.

The pinned transaction representation remains 688,656 bytes. An earlier private
counter prototype failed that assertion; the final implementation rebuilds its
derived counts instead of enlarging snapshots. The assertion and source guards
are unchanged. The separate active-union-copy experiment is not adopted.

## Complete original-input proof

The compiler input remains 443,624,107 bytes, SHA-256
`de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`.
`whole-census-v3-audit.json` verifies null filters, all 8,928 unique definitions,
exact original membership and a balanced terminal count. It preserves every
preceding success and owner and adds 58 selections.

The independent production replay matches every selected identity and rejection
tuple. Its function audit matches all 8,928 original identities and individual
outcomes. The event audit verifies 4,110,182 ordered records, balanced scopes and
one outcome for every function. The complete runtime census and production
replay likewise agree on all 455 identities and rejection tuples. Runtime owners
are unchanged.

Both production reports remain complete blocked-selection reports, with expected
checked exit 1. Source and backend verification succeeds. No complete compiler
or runtime object, compiler startup, or self-rebuild is established.

## Validation and identities

Debug and ReleaseSafe each pass 2,066 unit tests, 24 structural checks and two
profile/interruption checks. All nine readiness procedures are covered, including
the explicit ABI differential dependency: 60 cases and 30 function/mode matches.

All 79 native populations pass with Debug and ReleaseFast compilers. Per build,
all 2,945 command outcomes and 1,206 preceding compiler artifacts match exactly:
246 optimizer outputs, 483 objects and 477 ownership manifests. The final root
ReleaseFast integration suite independently repeats that comparison. Retained
Debug coverage uses the recorded worktree compiler and exact source-file
equality; its build receipt remains under `worktree-v3/local-state/compiler-debug-v3/`.

The root ReleaseFast compiler is SHA-256
`61f44899356c505c61511a70107dbe4e15d65d6cce4cfeeb87c4c600c137d9f3`.
Its receipt records Zig 0.17.0, x86_64-linux-gnu, baseline CPU, retained symbols
and frame pointers. The 3,164-file validated source seal verifies after full
integration and production. `adopted-committed-source-comparison.json` verifies
that every sealed file matches the committed source tree.

All 17 serial integration gates pass with checked return code zero, run ID
`52bdae32f1af577fb6c4e9a0518e1e92`. All three real-row modes retain 100 lowered,
emitted and native-linked functions. The 100-object release bundle has the same
identity as before, `3b65f5608098bf2c5f7816bea4b38a0cf0333797b516d1c7ae21d1f7e89d5249`;
one producer supplies all three consumers and executions are not cached. All
54 execution controls pass over 21 function/mode combinations and 22,788
observations. The thirteen pinned scratch files verify.

All 36 core-cohort records preserve selected objects and observed fields. Strict
full-log equality is not claimed: the raw comparison first differs at the
selected compiler path; a path-only projection then differs at independently
built reference-wrapper sizes. Both failed comparisons are retained. The explicit
four-field review retains reference/linked sizes and hashes separately, without
changing the comparator or claiming an ELF-section cause. Descriptors, selected
object bytes/hashes, results, witnesses, counts and statuses match.

The fixed 100-row prefix, twelve-function cohort, ratchet 130 and
`accepted_status.json` remain unchanged; the whole-compiler selection count is a
separate population.

## Measurements and continuation

The earlier unfiltered attempt times out after 7,200.56 seconds, with 6,648
function records and no terminal event. All those records match the new census
exactly. The completed new census takes 4,019.40 seconds; the production wrapper
takes 4,260.18 seconds and serial integration takes 3,799.07 seconds. These runs
used concurrent workloads and establish bounded replay completion, not a
controlled overall speedup ratio.

`whole-census-v3-families.json` classifies all 206 current failures. Continue
with shared integer-carrier and physical stack-argument contracts where the
concrete operands support them, then the observed floating, structured-value
and pointer-transport boundaries. Preserve the complete original input and all
accepted successes, and keep the full census and independent production replay
as cumulative acceptance checks.
