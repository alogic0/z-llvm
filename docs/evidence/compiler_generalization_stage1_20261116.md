# Compiler generalization: shared operand queries

Status: stage 1 accepted. ReleaseSafe acceptance is committed as `338b8972`;
its compiler baseline is `ae9d359f`. Stage-2 preparation is isolated and supplies
no stage-1 acceptance credit. Evidence lives under
`local-state/validations/compiler-generalization/batch-01/stage-01/`.

The shared operand walker now provides exact named-use queries with separate
occurrence and distinct-user counts, optional type checks and explicit opaque
coverage. Removed instructions and replacement bookkeeping are excluded. Each
PHI incoming value is an occurrence; the PHI itself is one user. Direct symbols,
labels and result definitions remain outside value-use queries. The existing
structured-only `def_use` contract remains unchanged.

Vector-combine uses these queries and the existing replacement API. Coverage,
types and dominance are checked before the first write. PHI dominance is checked
at the incoming predecessor edge. All allocation precedes the allocation-free
replacement and removal. A function-local insert index stores instruction
positions, reading current operands after earlier substitutions. Its lazy
dominance relation remains valid because this pass does not change CFG topology.
The duplicate replacement and use walkers are removed.

The second consumer is the backend's cyclic 128-bit byte-vector load/store
admission query. It requires one raw occurrence with compatible type and complete
coverage. The old omissions for allocation counts, indirect callees, shuffle
masks and atomic operands cannot legally consume this selected vector type under
the existing type/conflict policy. This consolidation establishes no observed
wrong-code repair in that memory path.

Two changes are classified separately. Opaque-reference refusal deliberately
restricts optional rewrite eligibility; an empty structured walk cannot prove
absence. Its regression compares complete printed IR, instruction storage and
all removed/replacement fields before and after refusal. The current-insert
repair addresses a confirmed compile failure: both frozen Fast/Debug Safe
binaries return `UnknownValue` on a valid CFG whose block layout differs from
dominance order. A copied insert retained a removed scalar name after an earlier
fold. Reading its current instruction removes that stale snapshot dependency.

The regression input and transformed result pass LLVM verification. Two existing
vector fixtures match both baseline builds exactly. Three existing memory
fixtures (`packed_vector_memory`, `memory_bitcasts`, `large_memory_bytes`) retain
exact Fast object bytes and ownership. The new case passes 65,543 native
observations against an independent LLVM build; a valid-IR return mutation is
detected. This standalone proof changes no native-registry population counter.

Both 2,395-unit builds pass. Full readiness, optimizer fixture comparisons,
66 structural tests, 60 ABI differential cases and 6,528 scalar observations
pass on the frozen source. The first focused run records its actual 42-test Debug
and 43-test Fast snapshots; later test additions receive no earlier Debug credit.
All 17 serial integration gates pass on that frozen source in `integration-02`;
its checked command returns zero after rechecking source, compiler and all seven
protected contracts. The complete 230-population native suite passes in three
release modes through both routes. The original target-omission failure remains
failed. Its successor reuses
only four completed IR comparisons, rechecking their inputs and outputs, and
executes all memory and native checks with an explicit x86_64 target.

The complete uncommitted source delta, including new files, is retained in
`complete-source.patch`; original partial command snapshots remain unchanged.
The integration run reuses authenticated frontend AIR from the existing
`validation-performance-20261109` cache; all three modes pass current cache
admission. Backend compilation, object checks and native execution are fresh.
Its 65.36-minute serial wall time is validation accounting, not a compiler
performance comparison. Minimum observed free storage is 112,324,009,984 bytes.
The first Tier-3 attempt failed root admission before subgates because it named
a retired temporary cache. Original failure and rejected release attempts remain;
the distinct successor root fixes admission without changing storage policy.

Temporary products use managed workspaces. The two exact Safe backend pipelines
and diagnosed qualification scratch are released after their final comparison:
the closure receipt records 227,172,352 allocated file bytes collected.
Qualification-r2, cache admission and failed Tier-3 helper closures separately
collect 918,364,160, 214,577,152 and 109,248,512 bytes. Successful integration
scratch has ordinary validation lifetime. The stage-1 candidate remains only
through the declared stage-2 original-layout comparison.

Readiness also created `tmp/inbox66_abi_diff/run-1892218` through its legacy default
scratch argument. The maintained 60-case report and identities are copied to
`qualification-r2/legacy-abi`. Its 45,977,600 allocated bytes are a specific
collector-admission investigation owned by this cycle, with no continuing test
consumer; no managed layout or successful disposal is invented. Future ABI
commands must supply managed scratch. The five historical ABI roots are outside
this disposition. Existing seven contracts, seventeen independent holds and
historical model/fe2 exception ownership remain unchanged.
