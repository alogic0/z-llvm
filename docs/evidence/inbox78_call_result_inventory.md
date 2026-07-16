# INBOX-78 pre-migration call-result accumulator inventory

This inventory is frozen before any INBOX-78 production or test migration at
accepted-5C HEAD `4cb867b5737fd6d95ac662eab8e1af16a9114dcc`
(tree `6ffb5bc7507a17af9e5bfdbd17cbb538e6130207`).  Its code state contains
accepted slice 5C `4c99aa00` plus the docs-only acceptance/dispatch commit.

The inventory covers every textual accumulator authority occurrence in
`composed_selector_calls.zig`: `bindEax`, `bindRax`, `clobberAccumulator`,
`spillCurrentAccumulator`, and `AccumulatorDefinitionTransaction.begin`.
Function names and operations are the stable identity; line numbers describe
this frozen source only.  There are **31 occurrences and zero unclassified
sites**.

Classification:

- **A — already migrated:** accepted 5B compare-like or 5C arithmetic-call
  producer already uses the transaction/EFLAGS authority.  A remaining direct
  clobber is internal to the accepted aggregate arithmetic producer, not a
  scalar call result.
- **B — INBOX-78:** remaining physical EAX/RAX call-result producer to migrate.
- **C — exclusion:** XMM, i128/pair, aggregate/overflow, or internal temporary;
  no scalar EAX/RAX call result may be claimed by commit 6.

| ID | Frozen line | Enclosing producer and occurrence | Class | Reason / commit-6 treatment |
|---|---:|---|:---:|---|
| 01 | 152 | `lowerCall`: `bindEax` for ordinary direct i32 result | B | transaction begins before caller-clobber preservation and commits zero-extending EAX after the call |
| 02 | 153 | `lowerCall`: `bindRax` for ordinary direct i64 result | B | full-RAX result; pointer result joins this typed path in commit 6 |
| 03 | 180 | `lowerUsubSatI64`: transaction begin | A | migrated arithmetic call producer in accepted 5C |
| 04 | 230 | `lowerScalarSseCall`: `bindEax` for mixed SSE/GPR i32 result | B | preserve existing scalar-call argument assignment and XMM staging order |
| 05 | 232 | `lowerScalarSseCall`: `bindRax` for mixed SSE/GPR i64/pointer result | B | full-RAX result; no XMM authority widening |
| 06 | 255 | `lowerFpAbs`: `clobberAccumulator` | C | XMM result; RAX is only an internal bit-manipulation temporary |
| 07 | 346 | `lowerUnsignedOverflowI32`: `clobberAccumulator` | A | accepted 5C arithmetic/flags producer; public result is aggregate value+overflow, not a scalar call result |
| 08 | 443 | `lowerSmulOverflowI64`: `clobberAccumulator` | C | aggregate result and fixed full-product RAX/RDX ownership |
| 09 | 518 | `lowerCtlzI32`: `clobberAccumulator` | B | inline intrinsic call-result definition |
| 10 | 520 | `lowerCtlzI32`: `bindEax` | B | zero-extending 32-bit result |
| 11 | 537 | `lowerCtlzI64`: `clobberAccumulator` | B | inline intrinsic call-result definition |
| 12 | 539 | `lowerCtlzI64`: `bindRax` | B | emitter genuinely defines the full 64-bit result |
| 13 | 548 | `lowerCtlzI52`: `clobberAccumulator` | B | inline exact-i52 result; physical emitter defines EAX |
| 14 | 551 | `lowerCtlzI52`: `bindRax` | B | commit with explicit zero-extended-RAX logical domain after EAX normalization |
| 15 | 595 | `lowerCttzI32`: `clobberAccumulator` | B | inline intrinsic call-result definition |
| 16 | 597 | `lowerCttzI32`: `bindEax` | B | zero-extending 32-bit result |
| 17 | 614 | `lowerCttzI64`: `clobberAccumulator` | B | inline intrinsic call-result definition |
| 18 | 616 | `lowerCttzI64`: `bindRax` | B | emitter genuinely defines the full 64-bit result |
| 19 | 647 | `lowerCtpop(64)`: `bindRax` | B | RAX input/result in-place; transaction must preserve accepted stream |
| 20 | 658 | `lowerCtpop(128)`: `clobberAccumulator` | C | i128/pair result with two-limb accumulation |
| 21 | 704 | `lowerBitPermutation(64)`: `bindRax` | B | in-place scalar RAX result |
| 22 | 717 | `lowerBitPermutation(128)`: `clobberAccumulator` | C | i128/pair result and RAX internal temporary |
| 23 | 763 | `lowerI128Compare`: transaction begin | A | migrated compare-like producer in accepted 5B |
| 24 | 808 | `lowerCtlzI16`: `clobberAccumulator` | B | accepted i16 normalization masks the input and adjusts an EAX result |
| 25 | 811 | `lowerCtlzI16`: `bindEax` | B | EAX establishes full zero-extended RAX; logical result stays i16 |
| 26 | 832 | `lowerFshlI32`: `bindEax` | B | in-place EAX intrinsic result |
| 27 | 879 | `lowerIntByteSizeCall`: `bindEax` | B | accepted direct i16 call only after emitted `and eax, 0xffff`; no ABI upper-bit inference |
| 28 | 899 | `lowerAbsI32`: `spillCurrentAccumulator` | B | replace with typed transaction preparation while preserving operand order |
| 29 | 901 | `lowerAbsI32`: `bindEax` | B | zero-extending EAX result |
| 30 | 922 | `lowerAbsI64`: `spillCurrentAccumulator` | B | replace with typed transaction preparation while preserving operand order |
| 31 | 924 | `lowerAbsI64`: `bindRax` | B | full-RAX emitter result |

Totals: **A = 3, B = 24, C = 4, unclassified = 0**.  The raw direct
inventory is 8 `bindEax`, 8 `bindRax`, 11 `clobberAccumulator`, two
`spillCurrentAccumulator`, and two transaction begins.

## Call forms without a direct occurrence

The inventory also classifies result forms represented by branches rather than
one of the searched operations:

- ordinary and mixed scalar direct calls returning `void` and unused calls
  remain byte-identical and bind no result;
- scalar SSE/XMM results are excluded;
- ordinary i128, aggregate, and sret results are excluded;
- indirect calls, unsupported attributes/calling conventions, raw arguments,
  operand bundles, and argument-allocation redesign remain rejected/excluded;
- generic ordinary i8/i16 direct returns remain rejected.  The admitted narrow
  direct-call form is `zig.target.intByteSize` i16, whose emitted mask—not an
  inferred ABI guarantee—establishes defined upper bits;
- pointer results are commit-6 scope and use the genuine full-RAX ABI result.

No XMM/pair/sret/indirect authority, location authority, allocator widening,
argument-allocation redesign, or CFG-aware EFLAGS authority is authorized.
