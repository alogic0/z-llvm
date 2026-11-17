# Table reservation and emission agreement

Status: Tier-2 accepted with storage closure, following accepted layout query
`c56210ec`. Evidence root is
`local-state/validations/compiler-generalization/follow-up-20261116/stage-02`.

The table description now owns the shared load envelope and the sole supported
derived offset. Pointer reservation and emitted loads use the same type, access,
address-space and atomic/syncscope predicates. Reservation and address actions
share the bounded +8 double-tail query. Literal codecs, shapes, index proof,
volatile support and ordinary-address fallback remain with their existing owners.

The live-consumer proof remains on `ir.operands`: unsupported wide/mixed loads,
derived uses and escapes retain ordinary materialization; removed consumers do
not block the specialization; opaque coverage cannot prove supported-only uses.
Full-selector tests check both machine verification and emitted ELF. The new
native opaque-consumer case extends the existing deterministic table fixture to
eleven functions and 1,408 observations per execution without adding a population.

This is bounded Tier-2 maintenance. Prototype Debug/Fast and native interaction
checks pass, but production qualification uses its exact promoted predecessor
and fresh source-bound results. Fresh production qualification passes all 78
table tests in Debug/Fast, all 2,433 Fast units and 74 structural checks. Generated
fixtures are byte-identical across two runs and pass LLVM verification. Source
identities verify. Production compiler `f72dbd89...` preserves the fixed Debug
object/owners exactly. All four focused native populations and 243 fault controls
pass; the extended table population matches 8,448 local observations with 4,224
LLVM-reference observations and detects all 99 controls. Captured-row smoke,
all 60 ABI comparisons, three hello_libc modes, fixed arithmetic canaries and all
27 M1 executables pass. Final storage closure passes. The first
predecessor-release attempt was deferred without mutation under the automatic
post-collector lock; its actual exit and diagnostics are preserved separately.
Cumulative integration of the later maintenance
batch remains required before closing its tracker. No performance, new pointer
capability or new ReleaseSafe outcome claim is made.

The predecessor compiler is released after its consumers close. Final collector
receipt `1794908904158951786-4015863` retires it and closed qualification scratch,
reclaiming 967,086,080 allocated bytes. Earlier stage boundaries collect
615,104,512 unit bytes, 265,326,592 build bytes and 50,077,696 nested native bytes.
All seven current manifests verify; seventeen independent holds and policy are
unchanged. Only the table compiler adopted for stage 3, and the isolated later
prototype source/compiler, remain owned pipelines with named release conditions.
