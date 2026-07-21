# INBOX-206BK Zig-only materialization-readiness design

```text
design_kind=zig_only_materialization_readiness
design_status=incomplete
implementation_authority=none
execution_authority=none
build_authority=none
install_authority=none
evidence_generation_authority=none
D01=withheld
D02=unauthorized
ratchet=131
continuation_root_created=false
evidence_file_created=false
```

## 1. Decision and scope

This is a documentation/architecture checkpoint. It specifies a prospective
private Zig 0.16 tool; it does not implement, compile, format, build, test,
install, invoke, or publish that tool. INBOX-206BJ is permanently withdrawn,
and `e75f2ddddf6a4b4095eaf3376b7f613d73e771a7` is superseded operating
history only. No JavaScript, ECMAScript, Python, Perl, AWK, handwritten codec,
or handwritten hash is part of the project solution.

The prospective implementation is exactly:

```text
source=tools/inbox206_materialization_readiness.zig
build_owner=build.zig
input=/home/oleg/prog/z_llvm/docs/evidence/inbox206bb_phase3_wrapper_package_specification.md
output=/home/oleg/prog/z_llvm/docs/evidence/inbox206bi_phase3_wrapper_materialization_readiness.md
continuation=/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206bi
```

The tool is a private, host-only evidence materializer. It has no import from
`src/`, no import by `src/`, no resolver or authority-selection API, no generic
path argument, no production CLI verb, and no call from `z_llvm`. A later
directive must separately authorize the two-file implementation (`tools/...zig`
and `build.zig`), a still later directive must authorize focused gates, and a
final directive must authorize evidence generation. The output and continuation
remain absent and non-symlink throughout BK.

## 2. Frozen authority

### 2.1 Operating and project authority

| authority | identity |
|---|---|
| operating HEAD | `c8474635772134ba9a202f99910c178a38d77925` |
| direct parent | `dba5894f1f6a9467e669671859e2ac60ea6d7495` |
| operating tree | `37b0fb39d1f77f640061358b0c843e5e2186acc3` |
| sole operating path | `docs/next_steps.md` |
| next-steps SHA-256 | `f184d982bc29855481394463d5abaac745f755c9e230496bbb24b7afb78245d2` |
| inbox SHA-256 | `77c6ae99bce4967b3a4fcb6b7c22554839fd00b535f08c653040f7eee0facc30` |
| specification | mode 0644; 82,425 bytes; `4b851b4a3650e6c55cd53f72b9f3e3e91146433523ccf2bbc6c4ad6dc1065eb3` |
| `build.zig` | mode 0664; 36,368 bytes; `a0c923499cd4515326fb287d729c53ae6d68bb465a4b4a033a737a19466ce466` |
| artifact-store pattern | 266,895 bytes; `073bdddeeac4a0b99e39cd54e5b2ea7db403796d25416dcf5ac578ea7ff5ad14` |
| bundle-publisher pattern | 11,655 bytes; `e2319a13aa01c00243e8941a75141af3bff3764059200e7092c7ada0d514721a` |
| watcher infrastructure | parent `dba5894f...`; SHA-256 `1221b00a6aacd7deaae9aab50bd2600be33a13b0ed645428f9475a2cb81a893d`; blob `058c659544fd13cc88ff79f62e196f1b9644f9e0`; PID 3206208, untouched |

### 2.2 Named Zig 0.16 standard-library authority

| exact path | SHA-256 | admitted design surface |
|---|---|---|
| `lib/std/Build.zig` | `dffb5a172899d660c370c6cdeca04c073468c64f28b9bb6fce919e71d1d5326d` | `addExecutable`, `addTest`, `addInstallArtifact`, `installArtifact`, `step` |
| `lib/std/unicode.zig` | `6b7243b43bb1467b48d3027bcb379078f9ca077086bfe6f887d04de6259c2934` | `utf8ValidateSlice`, `Utf8View` |
| `lib/std/crypto.zig` | `fa1d7e3a94a94f74e32be2bb6a0591225ea6eb57b0541b7ba3b02ea487c5c3ff` | exported crypto namespace only |
| `lib/std/crypto/sha2.zig` | `e58c67128f2c754049f737688ddcef809c017dbdd6de59995da3fbe99938db85` | `std.crypto.hash.sha2.Sha256.hash/init/update/final` |
| `lib/std/Io/Dir.zig` | `413302d836c509684352d7fa92ae377e469da504b6ec771e53fb5475fafe5b46` | descriptor-relative open/create/stat, `createFileAtomic`, `renamePreserve` |
| `lib/std/Io/File.zig` | `ef1600af9cfcb35e4f2ad626a28ce3a45bdb04c84fcf9309d027767da0e00330` | file stat, permission, read/write, and sync |
| `lib/std/Io/File/Atomic.zig` | `bc31d9be7cb7bb27bb643fee1bd34dbf35d89d5af0e4961e91ca74b21eba7cc9` | `link` no-replace atomic visibility and `deinit` |

The paths above are rooted at `/home/oleg/.zig/0.16.0/files`. No other local
library or project source is design authority.

## 3. Prospective private tool boundary

The tool accepts no user-selected path. Its input and output are compile-time
constants equal to the allowlisted names in section 1. It refuses argv beyond
the program name and reads no environment variable, configuration file,
resolver state, control repository, store, manifest, registered worktree, or
continuation directory.

The internal design has five private phases:

1. `acquireInput`: open the fixed specification read-only and no-follow,
   require regular mode 0644, bounded size 82,425, and exact SHA-256.
2. `parseAuthority`: validate UTF-8, extract canonical regions and matrix rows
   as byte slices, and build owned token/process metadata.
3. `validateClosure`: prove region, token, process, DAG, I/O, status,
   checkpoint, and write closure without rendering executable content.
4. `renderInertEvidence`: render a Markdown evidence candidate wholly in
   memory, including deterministic inert fixtures whose hashes are explicitly
   non-executable and non-authoritative.
5. `publishEvidence`: only after every prior phase succeeds, apply the
   allowlisted exclusive-publication protocol in section 11. This phase is
   blocked by the unresolved local API guarantee in section 11.4.

There is no subprocess API, shell command, wrapper invocation, assertion
invocation, project command, cache, or production call edge in any phase.

## 4. Raw-byte and UTF-8 model

The input owner holds one bounded `[]u8` allocation for its complete lifetime.
All source regions and token lexemes are `[]const u8` slices borrowing from
that allocation. Every offset is a zero-based half-open byte interval
`[start, end)` into that exact allocation or into a separately identified
canonical-region slice. Character indices never substitute for byte offsets.

`std.unicode.utf8ValidateSlice` must accept the complete source before any
textual interpretation. `Utf8View` may validate fixture text, but token and
region scanning remains byte-oriented. SHA-256 is exclusively
`std.crypto.hash.sha2.Sha256`; the implementation may call its one-shot or
streaming API and `std.fmt.bytesToHex(.lower)`. It may not contain copied
cryptographic constants, a handwritten digest, a Unicode decoder, or a codec.

Bounds are fixed before implementation review:

| allocation | maximum |
|---|---:|
| specification input | 82,425 bytes exactly |
| canonical regions | 39 records |
| process rows | 140 records |
| token occurrences | derived count, capped at 512 and required exact by manifest |
| inert fixture/evidence candidate | 4 MiB |
| one decoded literal field | 512 KiB |

Overflow in offset addition, length accumulation, output growth, or count
conversion is a distinct failure before publication.

## 5. Exact 39-region closure

Canonical delimiters are unique, line-anchored byte strings. Region interiors
exclude delimiter lines and include their final LF. A single forward scan must
require one BEGIN and one matching END, reject nesting, reject overlap, reject
an END before its BEGIN, and reject an unknown kind or ID. The closed set is
24 template regions, 14 assertion-copy regions, and one matrix region.

| kind | region | bytes | SHA-256 |
|---|---|---:|---|
| matrix | `MATRIX_ROWS` | 20,318 | `c2e399d701e96583c7ffa5d0e348dce1cae1c26d0dc05ba34f34c03d1c9459ec` |
| template | `T_OUTER` | 353 | `8416931252c47e2ac10429e203887a5837b4f47d448a9a449793d20360cf76db` |
| template | `T_CONSTRUCT_10` | 1,623 | `8a25bb3308c2c8cdf02cef8788070c271d139b8127ea0f8a235a98674d180fd2` |
| template | `T_READ_GATE` | 198 | `f126cde2a7b4596de583a7f43c4a8f72cdeb4b8a95921b4752e112bb0e641a6b` |
| template | `T_COPY_SELECTOR` | 394 | `0a8ee1a73b9d1b8d33b6c5bf7428546c0db169b912eff798d7d3f5d51f970653` |
| template | `T_INVOCATION_BATCH` | 1,286 | `88cb673bfd5694458dfcbad8ed437847406172de12e044e948068bc217f2b253` |
| template | `T_AUDIT_BATCH` | 491 | `ecd60eebb766f0ec33f2de343ddfd4551817c47e0477742d85d5fd792152bd57` |
| template | `T_ARTIFACT_IDENTITIES` | 356 | `eb8498407a2bf2f7177365e8bff61944e2ef45550be2234bb399b42b32cf4fc5` |
| template | `T_MARKER_DERIVE` | 245 | `f7dfd0b7febf9c065c7404e21b523c591af71831f13da4e9e01ca806c090e201` |
| template | `T_MARKER_FINALIZE` | 280 | `0bb8edbedfdd3e7295fdf8a422204fb523df980181cc3d6e9f0ed14548c8a9bd` |
| template | `T_FINAL_CLOSURE` | 128 | `9699aa0bfb49fd45880bdf4cc5e069f052fb0fe017e4ee6049d07b0a57966af8` |
| template | `P002` | 183 | `f3f07054713485485986b67af5f4ab819ff6f280fa2afddb1d42ac3071826411` |
| template | `P003` | 803 | `40a7144e019b45af04e112d456a43f63e925992a3d93e93887498ff25c5d8131` |
| template | `P004` | 241 | `17ec8b17eef2ac773d192b45b1deb8e2fe8bee6f8f5ed7975eb5291c448c9b97` |
| template | `P005` | 3,530 | `e1828a654a4b8262dac83c9fc871df9b4b76bca65353bb90f08aece88261647d` |
| template | `P006` | 247 | `fd087cb63ce5fe9fbee17a4aff126ea4f3c7869f2336a9f4264d35272f79d245` |
| template | `P007` | 260 | `92042292dbe0662a61efda982251e888e44a1580a7b1bbbe1a16446d1a973aef` |
| template | `P008` | 295 | `27df9fd261ba0e2fe4b575398a709d9a0cb7145827bd72c819031034daee63e0` |
| template | `P009` | 243 | `1b97341986df8c9552fd93fa2d4c0a9dc535b89de4319f7b1bbed4bc0bd3ec76` |
| template | `P010` | 211 | `78d15fedc6349ecac733d97869b00602b9e97ccaa6153d41b284682fa86ac55d` |
| template | `P011` | 213 | `07cf33df752f203187c469aeccbc7d20a904d8deae48fc70df001c0592d1c790` |
| template | `P012` | 258 | `8eb5c3ea80d081f21276a7073548e1044296d115c6a71b80095ac43be816fced` |
| template | `P013` | 249 | `12550a723800e9dc77f0615f749a777195ef62d8f44a2ee6e2a1f4f547b33770` |
| template | `P014` | 333 | `ceda5b7e75492576596a93fb60aa8b813a22cab1785f25706e9e2dc80ed8a935` |
| template | `P015` | 518 | `0519263f35aa760da0c50d6f5e7b8c0bd894886c718790739934f3797602f2c5` |
| assertion | `P002` | 85 | `453cd42dcf47790fcba30180e7d9e1cb7c1a1997b07c064384b20a9bb067d902` |
| assertion | `P003` | 705 | `e0215d8cdf0a45aea24e0e8f54715159798c24baf782e3c39dd71923c4bbb192` |
| assertion | `P004` | 141 | `9339e311a57c9e07657f6bb0a2323723784819c418b4058aad6a58c0207eebaa` |
| assertion | `P005` | 3,430 | `057a68edb24f99f5c18001203d53846e4ecf0d6fa6dee81acc56c4cc0a1f976a` |
| assertion | `P006` | 146 | `8d2b7f5092cec8a9bc38b41147e7b47ac3737083c188699bb61c6cb191a2eece` |
| assertion | `P007` | 159 | `a430068dfc6efbc1740507f8283e92df449fcc088a2896317c1ab385b038f1d5` |
| assertion | `P008` | 194 | `e7455095df8f6242e7d0bcd1248ac54aa4505cde367bbf0dda6cdb4377453b56` |
| assertion | `P009` | 142 | `69ddc0b193f29573fb8464ba63f4118c0181834261fc567ab0323fec65b31d4b` |
| assertion | `P010` | 110 | `83fa92142449e13e4741fbfbd50c597df34e165c475f8c8585f8faeb6670e027` |
| assertion | `P011` | 112 | `3f07f6221fb676d267f137bb8a63309d780d03946ed928f7e26da27129c0aaea` |
| assertion | `P012` | 157 | `2ec54f435d4c8f5fbbd635f36b382a170eaa56ef37e87c8f5062af16d0438bc3` |
| assertion | `P013` | 148 | `688ce553003e4634c2537c140fe1f118a361d58a92b44880069e3ea79c1bbb8c` |
| assertion | `P014` | 232 | `068279f2354bc4738826a526450e99fccf4a9955c5aa4e23c95b8c1b2cb1820e` |
| assertion | `P015` | 420 | `e258aec554bc2567e07d0944d0cc9b55758bc47f25b326f17b64dc1d1f7fd8bb` |

Any count, ID, byte length, hash, delimiter, ordering, nesting, or overlap
mismatch is terminal.

## 6. Typed-token contract

The parser recognizes only ASCII `@@NAME@@` tokens inside template regions.
Each occurrence stores template ID, token ID, ordinal, and exact byte span.
Sorted spans must be strictly disjoint; the union of token spans plus immutable
intervals must partition each template exactly once.

| token or family | type | sole provenance | validation and escaping |
|---|---|---|---|
| `ROOT` | absolute path | future execution directive | fixed allowlisted path, normalized, no NUL/CR/LF/TAB/traversal; raw inner bytes |
| `SLICE` | slice ID | future directive | `INBOX-206` plus uppercase suffix; ASCII |
| `HEAD`, `PARENT`, `TREE` | Git OID | future direct-child authority | 40 lowercase hex and exact relations; ASCII |
| `INBOX_SHA256` | digest | future ignored inbox | 64 lowercase hex; ASCII |
| `CHANGED_PATH` | tracked path | future parent diff | exactly `docs/next_steps.md`; ASCII |
| `PROCESS_ID` | process ID | closed matrix | exactly P001-P140; ASCII |
| `INPUT_BASENAME` | basename | process input manifest | nonempty closed enum, no slash/dot component/control byte; raw inner bytes |
| `LITERAL_ASSERTION` | read-only logic | separate future review | complete fixed block identity and no-write audit required; unresolved in BK |
| specifically named `*_BYTES_JS` fields | inert literal bytes | separate keyed-file authority | exact length/hash/schema and context safety; unresolved in BK |
| `MARKER_BYTES_JS` | marker bytes | separate marker review | exact 16 LF-terminated lines; unresolved in BK |
| `MARKER_SHA256` | digest | marker bytes | 64 lowercase hex and exact hash; unresolved in BK |
| `INNER_JS`, `EXPECTED_OUTPUT_JS` | legacy outer-source string content | committed historical template | inventory-only; materialization prohibited by Zig-only rule |

The exact occurrence authority is:

```text
T_OUTER INNER_JS:17-29 PROCESS_ID:216-230 EXPECTED_OUTPUT_JS:265-287 PROCESS_ID:307-321
T_CONSTRUCT_10 ROOT:72-80 BOUNDARY_FILE_BYTES_JS:1072-1098 DERIVATION_FILE_BYTES_JS:1184-1212 PRECON_DERIVATION_BYTES_JS:1302-1332 PRECON_GATES_BYTES_JS:1434-1459
T_READ_GATE ROOT:39-47 INPUT_BASENAME:96-114 LITERAL_ASSERTION:153-174 PROCESS_ID:180-194
T_COPY_SELECTOR ROOT:39-47
T_INVOCATION_BATCH ROOT:39-47
T_AUDIT_BATCH ROOT:39-47 AUDIT_GATE_RESULTS_BYTES_JS:260-291 AUDIT_DISPOSITION_BYTES_JS:377-407
T_ARTIFACT_IDENTITIES ROOT:39-47 ARTIFACT_IDENTITIES_BYTES_JS:181-213
T_MARKER_DERIVE ROOT:39-47 MARKER_BYTES_JS:163-182 MARKER_SHA256:210-227
T_MARKER_FINALIZE ROOT:72-80 MARKER_BYTES_JS:217-236
T_FINAL_CLOSURE ROOT:39-47 LITERAL_ASSERTION:83-104 PROCESS_ID:110-124
P002 ROOT:39-47
P003 ROOT:39-47 SLICE:168-177 HEAD:254-262 PARENT:280-290 TREE:306-314 CHANGED_PATH:338-354 INBOX_SHA256:376-392
P004 ROOT:39-47
P005 ROOT:39-47 SLICE:484-493 HEAD:900-908 PARENT:1094-1104 TREE:1288-1296 CHANGED_PATH:1466-1482 INBOX_SHA256:1677-1693
P006 ROOT:39-47
P007 ROOT:39-47
P008 ROOT:39-47
P009 ROOT:39-47
P010 ROOT:39-47
P011 ROOT:39-47
P012 ROOT:39-47
P013 ROOT:39-47
P014 ROOT:39-47
P015 ROOT:39-47
```

`LITERAL_FILE_BYTES_JS` is declared but unused and must be rejected rather
than silently accepted. Missing, unused, duplicate, undeclared, overlapping,
ambiguous, invalid, unresolved, chained, global, cascading, regex-selected,
or cyclic substitutions fail before rendering. Bytes outside declared spans
must compare unchanged after reverse reconstruction.

The historical `T_OUTER` region is still one of the 39 identities, but its two
string-content tokens would require an ECMAScript codec. The Zig-only boundary
therefore permits inventory and span validation only. It prohibits outer
materialization and is one reason this design remains incomplete.

## 7. Complete P001-P140 process and DAG closure

The matrix parser requires exactly 140 Markdown data rows, eight fields each,
ordered P001 through P140 with no duplicate or gap. Each process has expected
stdout `Pnnn_OK` plus LF, numeric status 0, and consumes only the immediately
preceding successful checkpoint; P001 consumes a future preconstruction
authority and P140 is terminal. This gives 139 process edges, one initial edge,
and one terminal edge, with no back edge or self-consumption.

### 7.1 Closed process catalogue

| P-ID or range | exact authority |
|---|---|
| P001 | produce ten initial files |
| P002-P005 | boundary header/content and independent derivation header/content |
| P006-P014 | environment header, counts, ID order, ID uniqueness, token uniqueness, five-field shape, ID domain, count domain, ordinal syntax |
| P015 | environment-token schema/hash |
| P016 | produce selector authority |
| P017-P022 | selector bytes, schema, ordered coverage, unique IDs, legal indices, exact bindings |
| P023-P034 | exact selector binding ET01 through ET12, one process each |
| P035-P038 | ET01 count/order/literal-ordinals/uniqueness |
| P039-P042 | ET02 count/order/literal-ordinals/uniqueness |
| P043-P046 | ET03 count/order/literal-ordinals/uniqueness |
| P047-P050 | ET04 count/order/literal-ordinals/uniqueness |
| P051-P054 | ET05 count/order/literal-ordinals/uniqueness |
| P055-P058 | ET06 count/order/literal-ordinals/uniqueness |
| P059-P062 | ET07 count/order/literal-ordinals/uniqueness |
| P063-P066 | ET08 count/order/literal-ordinals/uniqueness |
| P067-P070 | ET09 count/order/literal-ordinals/uniqueness |
| P071-P074 | ET10 count/order/literal-ordinals/uniqueness |
| P075-P078 | ET11 count/order/literal-ordinals/uniqueness |
| P079-P082 | ET12 count/order/literal-ordinals/uniqueness |
| P083 | 77-row/12-definition/no-extra environment coverage |
| P084-P089 | exact equivalence rows 1 through 6 |
| P090-P100 | type/mode/hash for the ten initial files and selector, in catalogue order |
| P101 | marker absence/non-symlink |
| P102 | produce five invocation files |
| P103-P106 | atomic schema, atomic state, instance binding, counts |
| P107-P108 | conflict and dependency closure |
| P109-P112 | bijection schema, cardinality, environment coverage, dimension coverage |
| P113-P117 | type/mode/hash for five invocation files |
| P118 | produce two audit files |
| P119-P122 | two audit type/mode gates and two audit schema gates |
| P123 | produce artifact identity ledger |
| P124-P135 | replay atomic summary, audit disposition, audit results, boundary, derivation, dependency, atomic matrix, bijection, preconstruction derivation, preconstruction gates, conflicts, selector |
| P136 | derive marker bytes/hash without writing |
| P137 | sole exclusive marker write |
| P138-P140 | marker type/mode, marker bytes/schema, and final 20-file identity/clean-state closure |

### 7.2 Exact write and I/O closure

| producer | sole prospective writes | consumers |
|---|---|---|
| P001 | `authority_boundary.tsv`, `authority_derivation.tsv`, `ak_replay.tsv`, `environment_authority.tsv`, `environment_equivalence.tsv`, `environment_tokens.tsv`, `environment_variable_policy.tsv`, `preconstruction_derivation.tsv`, `preconstruction_gates.tsv`, `schema_authority.tsv` | P002-P015, P023-P101 |
| P016 | `selector_authority.tsv` | P017-P034, P100, P135 |
| P102 | `atomic_summary.tsv`, `dependency_order.tsv`, `invocation_atomic_matrix.tsv`, `invocation_bijection.tsv`, `remaining_conflicts.tsv` | P103-P117, P124, P129-P132, P134 |
| P118 | `audit_gate_results.tsv`, `audit_disposition.tsv` | P119-P122, P125-P126 |
| P123 | `artifact_identities.tsv` | P124-P135 and final closure |
| P137 | `AUDIT_COMPLETE` | P138-P140 |

All other 134 processes are read-only. P136 is read-only marker derivation;
P138-P140 are post-marker read-only. The validator must parse each matrix
input, producer, predicate/schema, count/order/mode/hash rule, allowed-command
set, write classification, and freeze status. It rejects an unknown command,
an unproduced input, a consumer before its producer, a write outside the six
rows above, a duplicated output, an output consumed by its own producer, an
incorrect stdout/status, or any cycle.

## 8. Deterministic inert fixtures

Fixtures are pure in-memory byte values owned by the Zig tool. They use a
fixed synthetic root, fixed uppercase slice, fixed lower-hex identities,
closed process IDs, safe ASCII basenames, and separately tagged inert literal
samples. Rendering walks the ordered token spans once, copies each immutable
interval byte-for-byte, inserts exactly one validated fixture value, and then
proves reverse reconstruction to the canonical template.

The tool records canonical template identity, fixture-value manifest, rendered
byte count, standard-library SHA-256, immutable interval coverage, token output
spans, and reverse-equality result. Fixture records must say:

```text
fixture_kind=serialization_only
fixture_executable=false
fixture_authoritative=false
future_operating_hash_claim=false
```

No fixture is written as a wrapper, source file, cache, package, marker, or
artifact. `T_OUTER` receives no rendered fixture because that would require the
prohibited ECMAScript string codec. Its region identity and token spans are
validated, and the missing Zig-only replacement representation is reported as
an atomic blocker. Thus fixtures are deterministic without pretending that
the complete historical wrapper format is materializable.

## 9. Ownership, allocator, and stable lifetimes

The future implementation uses one caller-owned allocator and explicit owned
types:

- `InputDocument` owns the source allocation and open-file identity; all
  `Region.source` slices borrow from it and cannot outlive it.
- `ParsedAuthority` owns fixed-capacity region/process/token arrays and owned
  copies only for values that outlive parsing.
- `FixtureSet` owns fixture values and rendered buffers; it cannot expose a
  slice after `deinit`.
- `EvidenceCandidate` owns one bounded complete output buffer and its digest.
- `Publication` owns directory/file descriptors and atomic-file state until
  link or unwind.

Every acquisition has immediate `defer`; every partially initialized aggregate
has `errdefer`; transfer of ownership clears the prior owner exactly once.
Slices into growable buffers are forbidden. No global mutable storage, hidden
allocator, arena escape, dangling slice, double free, or partial output buffer
is admitted. An allocation error unwinds all owned memory and reaches no
publication operation.

## 10. Stable fail-closed error taxonomy

The public process exit is nonzero with no partial evidence bytes; internal
errors remain distinct for tests and evidence:

```text
InputPathMismatch InputTypeMismatch InputModeMismatch InputSizeMismatch InputHashMismatch InvalidUtf8
RegionDelimiterMissing RegionDelimiterDuplicate RegionKindUnknown RegionNested RegionOverlap RegionIdentityMismatch
MatrixFieldCount MatrixCountMismatch ProcessIdMismatch ProcessDuplicate ProcessGap ProcessCycle
InputUnproduced OutputDuplicate WriteUnauthorized StdoutMismatch StatusMismatch CheckpointMismatch
TokenUndeclared TokenUnused TokenMissing TokenDuplicate TokenOverlap TokenAmbiguous TokenInvalid TokenUnresolved
EscapingUnavailable ImmutableByteMismatch ReverseMismatch FixtureHashMismatch AllocationLimitExceeded IntegerOverflow
OutputPathMismatch OutputAlreadyExists ParentIdentityUnprovable SymlinkRejected PublicationUnsupported
PrepublicationMismatch AtomicLinkFailed DirectorySyncFailed PostpublicationMismatch
```

No error is diagnosed by a second execution. No retry, repair, cleanup pass,
normalization, overwrite, fallback, or fix-forward occurs. Before the atomic
link, errors leave no output path. After a successful link, bytes are complete
and immutable; a durability/read-back error reports an unaccepted complete
publication, never a partial file.

## 11. Prospective build-owned wiring

A later two-file implementation may add only these build relationships:

1. A host Debug executable named `inbox206-materialization-readiness` from
   `tools/inbox206_materialization_readiness.zig` using `b.addExecutable`.
2. A focused test artifact from the same source using `b.addTest`, with one
   uniquely named top-level step
   `inbox206-materialization-readiness-test` depending on exactly one
   `b.addRunArtifact(test_artifact)`.
3. Ordinary install registration using `b.installArtifact(tool)` so a later
   separately authorized `zig build install` can install the private developer
   tool. No production target depends on it.

No run step is attached to install, default, `test`, `run`, readiness,
distribution, artifact-store, or production steps. The source exposes no
module and is not imported by another project file. Build, test, and install
remain unauthorized in BK.

## 12. Exclusive publication design and blocker

### 12.1 Intended descriptor-relative protocol

The future tool must:

1. Require the fixed input identity before allocating output.
2. Require the output string equals the one allowlisted absolute path and the
   continuation remains absent/non-symlink without opening it.
3. Open `/`, then `home`, `oleg`, `prog`, `z_llvm`, `docs`, and `evidence` one
   literal component at a time with `follow_symlinks=false`; keep the resulting
   `evidence` directory descriptor and reject any non-directory.
4. Require the basename is exactly
   `inbox206bi_phase3_wrapper_materialization_readiness.md`; preflight it
   absent and non-symlink descriptor-relatively.
5. Build and hash all evidence bytes in memory. Call `createFileAtomic` on the
   held parent descriptor with permissions 0644 and `replace=false`.
6. Write all bytes, sync the atomic file, stat the open descriptor, require
   regular mode 0644 and exact size, stream SHA-256 from that descriptor, and
   require the expected digest.
7. Call `File.Atomic.link`, whose reviewed Zig 0.16 contract atomically exposes
   the file and fails with `PathAlreadyExists` rather than replacing anything.
8. Sync the held directory descriptor using the locally established Linux
   `fsync(dir.handle)` pattern; no shell subprocess is involved.
9. Open the final basename relative to the same held directory descriptor with
   `allow_directory=false`, `follow_symlinks=false`, and `resolve_beneath=true`;
   require regular mode 0644, exact size, exact complete-byte SHA-256, and byte
   equality. Sync the directory again and return success.

`defer atomic.deinit(io)` owns pre-link temporary cleanup. No `replace`, rename
over destination, chmod-after-link, append, truncate-existing, generic path,
or post-success mutation is allowed.

### 12.2 Guarantees established by named local APIs

- `createFileAtomic(..., .replace=false)` plus `Atomic.link` provides atomic
  no-replace visibility and `PathAlreadyExists` collision behavior.
- `OpenFileOptions.follow_symlinks=false`, `allow_directory=false`, and
  descriptor-relative component opens provide no-follow admission for named
  components and final read-back.
- `File.stat`, `setPermissions`/creation permissions, `File.sync`, and
  standard-library SHA-256 provide type, mode, size, durability-before-link,
  and content identity checks.
- The retained local publication pattern demonstrates file sync, atomic link,
  no-follow final open, read-back identity, and Linux directory `fsync`.

### 12.3 Exact unresolved guarantee

The named Zig 0.16 `Io.Dir.Stat` aliases `Io.File.Stat` and exposes inode but
not a device/filesystem identifier. The named `Dir.realPath` documentation
explicitly warns that it has limited platform support and can introduce race
conditions. Therefore these locally inspected APIs do not establish a stable,
race-free `(device,inode)` identity proving that the held output parent is the
previously reviewed main-worktree `docs/evidence` directory across mount or
rename races.

This is an explicit local-API blocker:

```text
publication_blocker=parent_directory_device_and_inode_identity_unprovable_from_named_zig_0_16_api
exclusive_publication_protocol_complete=false
fallback_invented=false
evidence_generation_authority=none
```

A later design amendment must either authorize and verify an exact Zig 0.16
descriptor identity API that supplies both device and inode, or obtain a
Reviewer ruling that a narrower explicitly stated threat model is sufficient.
It may not substitute path canonicalization, shell `stat`, a foreign-language
helper, or a weakened guarantee.

## 13. Test design for later authorization

The focused synthetic suite remains in the prospective tool's private `test`
blocks and uses `std.testing.allocator` and `std.testing.io`. It covers:

- exact 39-region extraction and every missing/duplicate/nested/overlap case;
- invalid UTF-8 and proof that all reported offsets are byte offsets;
- exact P001-P140 order, row shape, DAG, producer/consumer, stdout/status,
  checkpoint, and write closure, with one negative per invariant;
- every token type and occurrence manifest, plus missing, unused, duplicate,
  undeclared, overlap, ambiguity, invalid value, unresolved authority,
  immutable-byte drift, reverse mismatch, and cycle negatives;
- standard-library SHA-256 empty-string and `abc` vectors, without a local hash
  implementation;
- deterministic in-memory fixture equality and explicit non-authority labels;
- allocation failure at each owned boundary, exact cleanup, stable borrowed
  lifetimes, and no publication call on parse/render error;
- synthetic publication-interface state-machine tests only. Real output,
  control, store, continuation, and registered worktrees are never selected by
  tests.

The publication blocker prevents an end-to-end real-path test, install run, or
evidence generation from being considered ready.

## 14. Final disposition

The pure-Zig parser, validator, fixture renderer, build wiring, and publisher
are designs only. The canonical source authority is fully enumerated, the
P001-P140 closure is finite, and ownership/error behavior is fail closed. Two
atomic blockers remain: the prohibited legacy ECMAScript outer-string
materialization and the missing race-free parent `(device,inode)` identity
from the named Zig 0.16 APIs. Neither is weakened or bypassed.

```text
design_kind=zig_only_materialization_readiness
design_status=incomplete
implementation_authority=none
execution_authority=none
build_authority=none
install_authority=none
evidence_generation_authority=none
D01=withheld
D02=unauthorized
ratchet=131
continuation_root_created=false
evidence_file_created=false
registered_worktree_directory_access=none
watcher_pid_disturbed=false
```
