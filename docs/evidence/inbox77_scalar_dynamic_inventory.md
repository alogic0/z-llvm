# INBOX-77 pre-repair dynamic failure inventory

This inventory was captured before any INBOX-77 repair from reconstruction
commit `8156c1e91c562bdb5a26e63a18c5f5e4738561bd` (tree
`9931dd8990b09b4f470cff758d54fb80b006452a`), based directly on accepted 5B
`f78eeed4`.  The preserved patch is
`tmp/inbox74_intermixed_reslice_base.patch`, SHA-256
`bfc0a2a3fe25290d543077852213d3b0f1c962cc7eed131321c01bc42c06b888`.

The reconstructed full-cohort report is
`tmp/inbox77_reconstruction_full_capture_report.log`, SHA-256
`cff5c02de6c112c300084a9dea45194fbcd1164592c322f4c3c49203b8faebc0`.
It reports **443 selected / 259 emitted / 184 failed**, first failure
`compiler_rt.trunc.truncl` / `UnsupportedLongDoubleAbi`.  Compared with the
accepted-5B baseline (**443 / 285 / 158**), exactly 26 formerly accepted rows
regress.  The selector tag/detail below is the real value recovered through the
existing `lowerFunctionWithOptions` report-all plumbing; no temporary
production instrumentation was used.

This list is explicitly **SHADOWED**: lowering stops at the first unsupported
producer in each function, so a listed function may contain later failing
producers hidden behind the first tag/detail.  Consequently repair order must
come from the combined static and dynamic inventories, not by fixing these rows
one at a time.

| # | Formerly accepted row | First selector tag | First selector detail |
|---:|---|---|---|
| 1 | `compiler_rt.divdf3.__divdf3` | `unsupported_value` | `composed-block-and64-lhs` |
| 2 | `compiler_rt.extendhfdf2.__extendhfdf2` | `unsupported_value` | `composed-block-add64-lhs` |
| 3 | `compiler_rt.extendsfdf2.__extendsfdf2` | `unsupported_value` | `composed-block-add64-lhs` |
| 4 | `compiler_rt.fixdfdi.__fixdfdi` | `unsupported_value` | `composed-block-and64-lhs` |
| 5 | `compiler_rt.fixdfsi.__fixdfsi` | `unsupported_value` | `composed-block-and64-lhs` |
| 6 | `compiler_rt.fixunsdfdi.__fixunsdfdi` | `unsupported_value` | `composed-block-and64-lhs` |
| 7 | `compiler_rt.fixunsdfsi.__fixunsdfsi` | `unsupported_value` | `composed-block-and64-lhs` |
| 8 | `compiler_rt.floatdidf.__floatdidf` | `unsupported_value` | `composed-block-xor64-lhs` |
| 9 | `compiler_rt.floatdihf.__floatdihf` | `unsupported_value` | `composed-block-and64-lhs` |
| 10 | `compiler_rt.floatdisf.__floatdisf` | `unsupported_value` | `composed-block-and64-lhs` |
| 11 | `compiler_rt.floateidf.__floateidf` | `unsupported_value` | `composed-block-usub-sat-lhs` |
| 12 | `compiler_rt.floateihf.__floateihf` | `unsupported_value` | `composed-block-usub-sat-lhs` |
| 13 | `compiler_rt.floateisf.__floateisf` | `unsupported_value` | `composed-block-usub-sat-lhs` |
| 14 | `compiler_rt.floatsidf.__floatsidf` | `unsupported_value` | `composed-block-xor64-lhs` |
| 15 | `compiler_rt.floatundidf.__floatundidf` | `unsupported_value` | `composed-block-add64-lhs` |
| 16 | `compiler_rt.floatundihf.__floatundihf` | `unsupported_value` | `composed-block-and64-lhs` |
| 17 | `compiler_rt.floatundisf.__floatundisf` | `unsupported_value` | `composed-block-and64-lhs` |
| 18 | `compiler_rt.floatuneidf.__floatuneidf` | `unsupported_value` | `composed-block-usub-sat-lhs` |
| 19 | `compiler_rt.floatuneihf.__floatuneihf` | `unsupported_value` | `composed-block-usub-sat-lhs` |
| 20 | `compiler_rt.floatuneisf.__floatuneisf` | `unsupported_value` | `composed-block-usub-sat-lhs` |
| 21 | `compiler_rt.floatunsidf.__floatunsidf` | `unsupported_value` | `composed-block-xor64-lhs` |
| 22 | `compiler_rt.log.log` | `unsupported_value` | `composed-block-and64-lhs` |
| 23 | `compiler_rt.log10.log10` | `unsupported_value` | `composed-block-and64-lhs` |
| 24 | `compiler_rt.log2.log2` | `unsupported_value` | `composed-block-and64-lhs` |
| 25 | `compiler_rt.truncdfhf2.__truncdfhf2` | `unsupported_value` | `composed-block-and64-lhs` |
| 26 | `compiler_rt.truncdfsf2.__truncdfsf2` | `unsupported_value` | `composed-block-and64-lhs` |

First-failure buckets are: `and64-lhs` 13, `add64-lhs` 3,
`xor64-lhs` 4, and `usub-sat-lhs` 6.  The static inventory additionally predicts
the shadowed `or64-lhs`, exact-EI `binary-lhs`, and exact-EI `shift-lhs`
siblings, so they belong to the same structural batch even though they do not
appear as first failures here.
