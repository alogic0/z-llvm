# Compiler generalization: typed constant tables

Status: stage 2 accepted after focused, native and cumulative integration
qualification. Baseline stage 1 is `1905a579`.
Evidence is under `local-state/validations/compiler-generalization/batch-01/stage-02/`.

The four table layouts now use a typed description of element family, count,
stride, alignment, serialized extent, permitted access widths and allowed index
bits. Their compatibility constants preserve existing callers. Description
validation reconstructs the canonical fields; forged layouts cannot authorize
an access. Extent, scaled index, field offset, access end and signed target
displacement checks use checked arithmetic.

Index proofs retain their bit contract. In particular, `510` constrains both
the envelope and even parity for paired scalar accesses. It is not an arbitrary
numeric upper bound. The change adds no general interval proof or arbitrary
table-length support. GEP admission still requires a proven i64 index.

The mechanical migration qualifies the original four layouts separately from
the extension. Four original-layout/memory objects and selection owner manifests
remain exact against the preceding compiler. The initial mechanical fixture
also matches independent native results. Corresponding index and prepared-view
consumers derive their masks and strides from the same description.

The capability extension admits literal i16 arrays at power-of-two counts from
2 through 65,536. Counts 64 and 256 share the implementation and receive strict
native tests, exhaustive bounded indexes, high-bit inputs, protected-page ends,
adjacent guards and injected failures. The normal predecessor already compiles
the standalone new fixture through other composed operations; this is not a
claim that the complete backend previously rejected that fixture.

Boundary tests cover invalid counts, forged descriptions, wrong widths/strides,
parity, raw unproved indexes, writable/escaped pointers and arithmetic limits.
Floating and named-pair families keep their original counts and initializer
boundaries. The existing proof-depth and traversal budgets are unchanged.

The initial extension intercepted unused zero-initialized i16 globals in hello's
ReleaseSafe object input. Its failed receipt is retained. The correction checks
literal payload eligibility before specializing newly admitted counts, leaving
other unsupported unused payloads to ordinary emission. All four original
layouts retain their prior closed codec errors. The reduced and complete failed
Safe inputs now match the mechanical predecessor's objects and owner manifests.

The corrected source passes all 2,406 Fast units, 88 selected Debug/Fast checks
and 74 structural tests. The earlier full 2,403 Debug run predates the payload
correction; it is not reported as a full Debug run of the final source.
Final qualification passes 12,480 local observations against 6,240 independent
LLVM observations, 54 controls, the selected captured object suite, all 60 ABI
cases and hello in all three release modes. The corrected compiler identity is
`0fbb3ef520227619c96b904f83c502449e9ceeb9018d9bc5647bddd23219dd97`.

The guard source path transition retains all 24 ordered frozen digests. Two
historical consumer-policy rows now bind their existing qualified copies; the
other 22 rows, historical model mapping, six other contracts and independent
holds remain unchanged. Current guard mutation tests qualify the new description
spelling. Historical bytes receive no new acceptance credit.

All 17 serial integration gates pass on the unchanged corrected source in
`complete-check`, followed by source/compiler and all seven contract checks.
The integrated executable gate invokes `validation/upstream_c.zig`, which runs
the complete 231-population native registry in all three release modes through
both routes. Its registry digest matches the maintained source; the new table
population again records 12,480 local and 6,240 reference observations.
The three authenticated frontend AIR cache hits reuse no backend objects or
executable results. The serial wall time is 4,190,158 ms and the minimum
observed free storage is 84,492,562,432 bytes. These are validation accounting,
not a compiler performance measurement.

All ordinary products use managed validation or named compiler pipelines.
Commands, source/input/compiler identities, original failures and diagnoses
remain maintained. Automatic post-gate collection at
`local-state/retirements/automatic-storage-cleanup/1794854448688093973-2470703/report.json`
reclaims 5,785,493,504 allocated file bytes from 32 completed trees with current
integrity verified. The mechanical, uncorrected extension and corrected table
compiler consumers have ended. Their explicit releases and the diagnosed failed
workspace dispositions are recorded in `post-table-disposition` at the cycle
root. Its collector receipt
`local-state/retirements/automatic-storage-cleanup/1794856518431022835-2514450/report.json`
reclaims another 4,467,273,728 allocated file bytes from all 24 eligible trees;
no eligible candidate remains. The repaired stage-3, corrected stage-4 and experimental stage-5 compilers
retain only their named downstream consumers. Seventeen independent holds and
the seven integrity contracts remain effective.

Two closed ordinary-product roots retain specific collector-admission exceptions,
with no validation consumer: the 49,020,928-byte original hello workspace has
aggregate status `blocked`, which the workspace publisher does not recognize as
closed, and the 45,977,600-byte legacy ABI root uses an unsupported producer
layout. Their diagnostics and identities are maintained. No original report is
rewritten and neither root is classified as required acceptance data.
