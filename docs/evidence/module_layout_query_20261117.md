# Shared module-aware memory layout

Status: accepted after production qualification and storage closure.
Admission is the separately accepted GEP repair at `77723de9`; this source has
its own fresh Tier-3 result.
Evidence root is
`local-state/validations/compiler-generalization/follow-up-20261116/stage-01/query-production`.

The borrowed query resolves current-module types with explicit identifier
equality and returns store size, allocation stride, ABI alignment and field
offsets as distinct facts. Checked limits and an optional caller-owned node
predicate apply to every complete child, including zero-length array children.
Cycles, ambiguous names, incomplete types and unsupported/overflowing queries
remain unknown. Field offsets require proof of the complete source layout.

Constant tables retain their literal codecs, shapes, byte-spelling identifiers,
native override gates and serialized extent. They query the actual named pair
instead of constructing a replacement literal type. Backend storage retains
its 4 MiB and u32 count limits, decoded identifiers, scalar/vector limits and
floating/vector override rejection. Only absent module layouts select its
explicit native x86 default. Geometry facts grant no register ABI.

The audit confirms five native geometry failures in the predecessor: i80 array
and struct alignment without an i128 entry, and next-larger integer alignment
for i24/i9. LLVM chooses the smallest declared integer width at least as large
as the requested width, or its largest width. The query interprets explicit
integer, floating, vector, aggregate and pointer specs separately. This corrects
those five semantics; recursive-walker factoring is a separate part of the
change. Layout-aware memory-location analysis uses the same geometry while
retaining store widths and its existing named/target-free/root/alias policies.

Newly known analysis geometry is a separate capability from backend admission.
In particular, the query can prove wide-integer allocation strides that the
legacy DataLayout left unknown without an exact explicit entry. The maintained
`wide-analysis-audit` compares eighteen scalar, array and struct cases for i129,
i256 and i65535 against LLVM under two layouts. All strides, alignments and
analysis offsets match; an explicit-i256 legacy control also matches. Backend
storage still declines every wide case. This does not add a wide register ABI.

The isolated pure query passes Debug/Fast tests and all 48 LLVM-verified audit
comparisons. Two i8:32 layouts that LLVM rejects remain separately classified.
Initial backend/table callers pass 2,425 Fast units and 76 layout checks per
mode. Two analysis regressions actually fail before migration, then pass in
Debug/Fast together with all existing layout checks. These are prototype facts;
the exact-source promotion bridge preserves their scope. Fresh production
qualification passes all 2,431 Fast units, 82 layout tests per Debug/Fast,
74 structural checks and deterministic original/reference regeneration.

The deterministic five-function native canary has an independent C oracle for
320 observations and ten field-corruption controls. Its original reference
setup failed because Clang replaces the non-native module layout before codegen.
The preserved successor folds geometry with LLVM under the declared layout
first, then compiles the independently folded reference; all observations and
fault controls pass. The registry's explicit reference fixture preserves this
contract for local direct and optimized routes. Registry size is now 237; no
compiler-core/rt ratchet or new milestone/performance claim is made.

Production compiler is
`71ce00e004a5156fff4251831aaa3c3a629531a401269a1dd3d75cb0864509f7`.
The fixed Debug object and owner bytes retain hashes `92825c8e...` and
`50a5e008...`; the padded GEP object/owners also remain exact. All six focused
native populations pass 396 fault controls. The new geometry population matches
1,920 local observations with 960 reference observations and all 90 faults.
All 60 ABI comparisons, fixed __multi3/FMA canaries and 27 M1 executables pass.
Source identities remain unchanged. Fresh serial Tier 3 passes all seventeen
gates and all 237 native populations, run `969566b4b37d5eca2f0651f26045c496`.
Authenticated frontend AIR is reused; backend, link and execution results are
fresh. Current contracts verify. Guarded ordinary-product teardown and final
storage disposition also pass.

The isolated source/probe pipeline is released after exact-byte promotion and
test-import-only normalization. Its collector receipt
`local-state/retirements/automatic-storage-cleanup/1794899670473817714-3752010/report.json`
reclaims 182,304,768 allocated bytes. The completed unit/build wrappers also
collect 615,403,520 and 265,367,552 bytes. The earlier predecessor closes after
comparison. The three final collector receipts `1794905885885338553-3949726`,
`1794906363238237687-3958444` and `1794906606241528263-3963497` reclaim
5,632,352,256 allocated bytes from closed query and related prototype work.
The ordinary main Debug producer is retired; both diagnosed prototype setup
attempts retain their original failed receipts and maintained failing source.
Seven current manifests and seventeen independent holds remain unchanged.

Only three owned pipelines remain: the qualified query compiler, adopted for
stage-02's production comparison, and the isolated later-prototype source/compiler,
retained through ordered promotion and exact-source/native comparison. Their
paths, consumers and release conditions are in the maintained retention notes.
