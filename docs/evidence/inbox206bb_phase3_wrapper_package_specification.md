# INBOX-206BB inert Phase-3 wrapper-package specification

package_kind=inert_template_specification
package_status=incomplete
implementation_ready=false
execution_authority=none
D01=unaccepted

## 1. Authority and disposition

This is the sole INBOX-206BB result. It specifies, but does not materialize or
execute, every process after the accepted INBOX-206BA preconstruction
checkpoint.

```text
head=7cf4b88a39980cdcf27d649ee760d14842c1e8d9
parent=63197dba206a14010ebf699077e026533f31e9e6
tree=a39e6386c6ca66a064600c993ea564c8581acb21
sole_changed_parent_path=docs/next_steps.md
next_steps_sha256=c5003f6f317f4580186c4fcb295d61c7d8db48c272b7c181ad52cb36c9e2b03f
worker_inbox_sha256=f0ea154d6643870ea1564dd797fdcac4697052f79f428e09bafab153eda0a59d
```

BA remains absent/non-symlink. AV and AY are immutable inputs. AX, AW, and AZ
remain absent. This specification creates no continuation, cache, executable,
marker, or temporary package. Ratchet remains 131. D01 and D02 receive no
credit. No wrapper below has execution authority.

## 2. Inputs and final files

```text
AV_ROOT=/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206av
AV_PATHS_SHA256=40877472f52d08d4f24c28c664a41769119ef6db41bba714e8a255b8711fd562
AV_INVENTORY_SHA256=a7f4f45dec7706e73253e8167ea65f54cf2f7f4dbcfca452dae9dc067eca9b28
AV_LEDGER_SHA256=d11c2d8443cc65b830e87a8d8d5ae676564f6a8f38cc9c89e51b8f50e7c227dd
AY_ROOT=/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay
AY_PATHS_SHA256=5e626a7985d104cf641a28f715c989295f379cae6dd47b6a5438c1bbf6976117
AY_INVENTORY_SHA256=27d6ccc0940950b695567306ad60ab65da18f6688fca1aa024423e05e09ccbd5
AY_LEDGER_SHA256=8535aa624a5c378cb36139f85520b1738a66626f091d6dc40a32da83358d5b28
```

The final continuation has exactly 20 regular, non-symlink, non-executable,
mode-0644 files:

```text
AUDIT_COMPLETE
ak_replay.tsv
artifact_identities.tsv
atomic_summary.tsv
audit_disposition.tsv
audit_gate_results.tsv
authority_boundary.tsv
authority_derivation.tsv
dependency_order.tsv
environment_authority.tsv
environment_equivalence.tsv
environment_tokens.tsv
environment_variable_policy.tsv
invocation_atomic_matrix.tsv
invocation_bijection.tsv
preconstruction_derivation.tsv
preconstruction_gates.tsv
remaining_conflicts.tsv
schema_authority.tsv
selector_authority.tsv
```

Six byte-identical AY copies are `ak_replay.tsv`,
`environment_authority.tsv`, `environment_equivalence.tsv`,
`environment_tokens.tsv`, `environment_variable_policy.tsv`, and
`schema_authority.tsv`. Four keyed derivations are `authority_boundary.tsv`,
`authority_derivation.tsv`, `preconstruction_derivation.tsv`, and
`preconstruction_gates.tsv`. No path crosses this boundary.

Later producers add `selector_authority.tsv`; then
`invocation_atomic_matrix.tsv`, `invocation_bijection.tsv`,
`atomic_summary.tsv`, `remaining_conflicts.tsv`, and `dependency_order.tsv`;
then `audit_gate_results.tsv` and `audit_disposition.tsv`; then
`artifact_identities.tsv`; finally `AUDIT_COMPLETE`.

## 3. Schemas and independent cardinalities

Every TSV uses literal tabs and preserves empty fields. A scanner must reach
EOF and explicitly return zero; the last row never supplies process status.

| file | fields | data rows | total lines |
|---|---:|---:|---:|
| authority_boundary.tsv | 2 | 18 | 19 |
| authority_derivation.tsv | 5 | 19 | 20 |
| environment_authority.tsv | 5 | 12 | 13 |
| environment_tokens.tsv | 8 | 12 | 13 |
| environment_variable_policy.tsv | 6 | 77 | 78 |
| environment_equivalence.tsv | 4 | 6 | 7 |
| selector_authority.tsv | 8 | 12 | 13 |
| invocation_atomic_matrix.tsv | 7 | 128 | 129 |
| invocation_bijection.tsv | 9 | 54 | 55 |
| remaining_conflicts.tsv | 5 | 8 | 9 |
| dependency_order.tsv | 5 | 12 | 13 |
| audit_disposition.tsv | 2 | 16 | 17 |
| artifact_identities.tsv | 5 | 18 | 19 |

`authority_boundary.tsv` is header `field<TAB>value` followed by these exact
ordered unique keys:

```text
slice
kind
operating_commit
operating_parent
operating_tree
operating_changed_path
ignored_inbox_sha256
ak_root
ak_disposition
al_state
am_state
implementation
execution
validation
production_awk
D02
ratchet
credit
```

`authority_derivation.tsv` independently has header
`source_path<TAB>key_or_order<TAB>source_value<TAB>expected_value<TAB>disposition`
plus 19 rows. Neither cardinality may be inferred from the other.

## 4. Typed substitution authority

Every wrapper is future-identity-dependent because it names the future root or
slice. Consequently:

```text
identity_independent_wrapper_count=0
materialized_wrapper_hashes_claimed=false
```

| token | type and canonical encoding | validation | exact replacement rule |
|---|---|---|---|
| `@@ROOT@@` | normalized absolute UTF-8 path under the fixed continuation parent | absent/non-symlink, no CR/LF/tab/NUL, no `//`, `/./`, `/../`, disjoint from all registrations | only declared token offsets |
| `@@SLICE@@` | `INBOX-206` plus uppercase suffix | `^INBOX-206[A-Z]+$` | only declared token offsets |
| `@@HEAD@@`, `@@PARENT@@`, `@@TREE@@` | 40 lowercase hex | non-merge HEAD/direct parent/tree equality | only declared token offsets |
| `@@INBOX_SHA256@@` | 64 lowercase hex | exact ignored inbox bytes | only declared token offsets |
| `@@CHANGED_PATH@@` | `docs/next_steps.md` | sole parent-diff path | only declared token offsets |
| `@@PROCESS_ID@@` | `P` plus three digits | member of section 6 | declared marker/error offsets |
| `@@INNER_JS@@` | ECMAScript double-quoted-string content | decode raw-equals reviewed inner bytes | once in outer template |
| `@@EXPECTED_OUTPUT_JS@@` | ECMAScript string content | decodes to `Pnnn_OK` plus LF | once in outer template |
| `@@LITERAL_FILE_BYTES_JS@@` | literal non-executable file bytes | decoded hash/length/schema reviewed | declared once per output |
| `@@LITERAL_ASSERTION@@` | separately reviewed fixed read-only assertion block | hash/length and allowed-command audit | declared once per gate |
| `@@MARKER_SHA256@@` | 64 lowercase hex | hash of reviewed marker bytes | declared marker offsets |
| `@@MARKER_BYTES_JS@@` | marker bytes including final LF | section 9 schema | declared once per producer |

Each process manifest must list exact occurrence counts and byte offsets in
lexical order. Materialization validates all fields, proves disjoint offsets,
replaces one typed token at a time, and proves every byte outside those offsets
unchanged. Chained/global/cascading/regex/width-inferred/substring replacement
is prohibited.

## 5. Finite producer/consumer DAG

| order | processes | output or assertion | next consumer |
|---:|---|---|---|
| 1 | P001 | ten initial files | P002 |
| 2 | P002-P005 | independent 19/20-line boundary/derivation gates | P006 |
| 3 | P006-P014 | nine authority gates | P015 |
| 4 | P015 | token schema | P016 |
| 5 | P016 | selector file | P017 |
| 6 | P017-P022 | selector base gates | P023 |
| 7 | P023-P034 | 12 selector binding gates | P035 |
| 8 | P035-P082 | 48 environment gates | P083 |
| 9 | P083 | environment coverage | P084 |
| 10 | P084-P089 | six equivalence gates | P090 |
| 11 | P090-P100 | 11 initial type/mode gates | P101 |
| 12 | P101 | marker absence | P102 |
| 13 | P102 | five invocation files | P103 |
| 14 | P103-P106 | atomic gates | P107 |
| 15 | P107-P108 | conflict/dependency gates | P109 |
| 16 | P109-P112 | bijection gates | P113 |
| 17 | P113-P117 | invocation type/mode gates | P118 |
| 18 | P118 | two audit files | P119 |
| 19 | P119-P122 | audit type/mode/schema gates | P123 |
| 20 | P123 | artifact identities | P124 |
| 21 | P124-P135 | identity replay gates | P136 |
| 22 | P136 | marker derivation, no write | review boundary |
| 23 | P137 | sole marker write | P138 |
| 24 | P138-P140 | post-marker read-only closures | terminal |

Each process requires the exact previous status/output. The DAG is finite and
acyclic; no group contains its own producer command, receipt, log, or result.

## 6. Complete repeated-process catalogue

Nine authority processes are P006 header, P007 counts, P008 ordered IDs, P009
unique IDs, P010 unique tokens, P011 five-field shape, P012 ID domain, P013
count domain, and P014 ordinal syntax. P015 is token schema.

Selector base processes are P017 frozen bytes, P018 schema, P019 ordered
ET01-ET12 coverage, P020 unique IDs, P021 legal field indices, and P022 exact
source/header/rule bindings. P023-P034 bind ET01-ET12 respectively.

```text
P035 ET01-count  P036 ET01-order  P037 ET01-ordinals  P038 ET01-unique
P039 ET02-count  P040 ET02-order  P041 ET02-ordinals  P042 ET02-unique
P043 ET03-count  P044 ET03-order  P045 ET03-ordinals  P046 ET03-unique
P047 ET04-count  P048 ET04-order  P049 ET04-ordinals  P050 ET04-unique
P051 ET05-count  P052 ET05-order  P053 ET05-ordinals  P054 ET05-unique
P055 ET06-count  P056 ET06-order  P057 ET06-ordinals  P058 ET06-unique
P059 ET07-count  P060 ET07-order  P061 ET07-ordinals  P062 ET07-unique
P063 ET08-count  P064 ET08-order  P065 ET08-ordinals  P066 ET08-unique
P067 ET09-count  P068 ET09-order  P069 ET09-ordinals  P070 ET09-unique
P071 ET10-count  P072 ET10-order  P073 ET10-ordinals  P074 ET10-unique
P075 ET11-count  P076 ET11-order  P077 ET11-ordinals  P078 ET11-unique
P079 ET12-count  P080 ET12-order  P081 ET12-ordinals  P082 ET12-unique
```

Every process is separate: no shared validation loop, composite gate, borrowed
status/marker, or pipeline-final-row dependency. Selection uses complete TSV
fields after explicit header exclusion; fixed matching is only `grep -x -F`
over extracted records.

P084-P089 are the six equivalence rows. P090-P100 cover the initial ten files
plus selector. P103-P106 are atomic schema, invocation-atomic state, instance
binding, and counts. P109-P112 are bijection schema, cardinality, environment
coverage, and dimension coverage. P113-P117 cover the five invocation files.
P119-P120 cover two audit file modes and P121-P122 their schemas.

P124-P135 replay, in order, atomic summary, audit disposition, audit gate
results, authority boundary, authority derivation, dependency order, atomic
matrix, invocation bijection, preconstruction derivation, preconstruction
gates, remaining conflicts, and selector authority.

### 6.1 Complete P-ID/input/assertion-requirement matrix

Every P-ID is explicit. “yes” means no write; producer rows name their sole writes. P016-P140 remain incomplete requirements.

| P-ID | input | producer | predicate/schema | count/order/mode/hash | allowed reads/commands | no-write or sole write | freeze family/status |
|---|---|---|---|---|---|---|---|
<!-- BG-CANONICAL-BEGIN matrix MATRIX_ROWS -->
| P001 | AY six copies + four literals | BA preconstruction | produce ten | exact paths/0644/hash/schema | AY; dd,printf,sync | ten named files | incomplete construction |
| P002 | authority_boundary.tsv | P001 | header | 2 fields | sed | yes | BC-frozen |
| P003 | authority_boundary.tsv | P001 | full boundary | 19 lines/order/values | cat,cmp,wc | yes | BC-frozen |
| P004 | authority_derivation.tsv | P001 | header | 5 fields | sed | yes | BC-frozen |
| P005 | authority_derivation.tsv | P001 | full derivation | 20 lines/order/values | cat,cmp,wc | yes | BC-frozen |
| P006 | environment_authority.tsv | P001 | header | 5 fields | sed | yes | BC-frozen |
| P007 | environment_authority.tsv | P001 | counts | 7,7,4,24,4,4,4,7,4,4,4,4 | tail,cut,cmp | yes | BC-frozen |
| P008 | environment_authority.tsv | P001 | ID order | ET01-ET12 | tail,cut,cmp | yes | BC-frozen |
| P009 | environment_authority.tsv | P001 | ID uniqueness | 12 unique/13 lines | cut,sort,wc | yes | BC-frozen |
| P010 | environment_authority.tsv | P001 | token uniqueness | 12 unique | cut,sort,wc | yes | BC-frozen |
| P011 | environment_authority.tsv | P001 | field shape | 5 each | perl | yes | BC-frozen |
| P012 | environment_authority.tsv | P001 | ID domain | ET01-ET12 only | cut,grep | yes | BC-frozen |
| P013 | environment_authority.tsv | P001 | count domain | 4/7/24 only | cut,grep | yes | BC-frozen |
| P014 | environment_authority.tsv | P001 | ordinals | 2-digit sequential | perl | yes | BC-frozen |
| P015 | environment_tokens.tsv | P001 | token schema | hash/13 lines/8 fields | sha256sum,sed,wc,perl | yes | BC-frozen |
| P016 | AV selector | P015 | produce selector | exact retained bytes/0644 | AV; dd | selector_authority.tsv | incomplete producer |
| P017 | selector_authority.tsv | P016 | frozen bytes | exact selector authority | target; cut,grep,wc,cmp,sha256sum | yes | incomplete selector |
| P018 | selector_authority.tsv | P017 | 8-field schema | exact selector authority | target; cut,grep,wc,cmp,sha256sum | yes | incomplete selector |
| P019 | selector_authority.tsv | P018 | ordered ET coverage | exact selector authority | target; cut,grep,wc,cmp,sha256sum | yes | incomplete selector |
| P020 | selector_authority.tsv | P019 | unique IDs | exact selector authority | target; cut,grep,wc,cmp,sha256sum | yes | incomplete selector |
| P021 | selector_authority.tsv | P020 | legal indices | exact selector authority | target; cut,grep,wc,cmp,sha256sum | yes | incomplete selector |
| P022 | selector_authority.tsv | P021 | source/header bindings | exact selector authority | target; cut,grep,wc,cmp,sha256sum | yes | incomplete selector |
| P023 | selector + environment TSVs | P022 | ET01 binding | complete fields/exact binding | target; cut,grep -x -F,cmp,wc | yes | incomplete binding |
| P024 | selector + environment TSVs | P023 | ET02 binding | complete fields/exact binding | target; cut,grep -x -F,cmp,wc | yes | incomplete binding |
| P025 | selector + environment TSVs | P024 | ET03 binding | complete fields/exact binding | target; cut,grep -x -F,cmp,wc | yes | incomplete binding |
| P026 | selector + environment TSVs | P025 | ET04 binding | complete fields/exact binding | target; cut,grep -x -F,cmp,wc | yes | incomplete binding |
| P027 | selector + environment TSVs | P026 | ET05 binding | complete fields/exact binding | target; cut,grep -x -F,cmp,wc | yes | incomplete binding |
| P028 | selector + environment TSVs | P027 | ET06 binding | complete fields/exact binding | target; cut,grep -x -F,cmp,wc | yes | incomplete binding |
| P029 | selector + environment TSVs | P028 | ET07 binding | complete fields/exact binding | target; cut,grep -x -F,cmp,wc | yes | incomplete binding |
| P030 | selector + environment TSVs | P029 | ET08 binding | complete fields/exact binding | target; cut,grep -x -F,cmp,wc | yes | incomplete binding |
| P031 | selector + environment TSVs | P030 | ET09 binding | complete fields/exact binding | target; cut,grep -x -F,cmp,wc | yes | incomplete binding |
| P032 | selector + environment TSVs | P031 | ET10 binding | complete fields/exact binding | target; cut,grep -x -F,cmp,wc | yes | incomplete binding |
| P033 | selector + environment TSVs | P032 | ET11 binding | complete fields/exact binding | target; cut,grep -x -F,cmp,wc | yes | incomplete binding |
| P034 | selector + environment TSVs | P033 | ET12 binding | complete fields/exact binding | target; cut,grep -x -F,cmp,wc | yes | incomplete binding |
| P035 | three environment TSVs | P034 | ET01 count | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-count |
| P036 | three environment TSVs | P035 | ET01 order | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-order |
| P037 | three environment TSVs | P036 | ET01 ordinals | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-ordinals |
| P038 | three environment TSVs | P037 | ET01 uniqueness | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-uniqueness |
| P039 | three environment TSVs | P038 | ET02 count | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-count |
| P040 | three environment TSVs | P039 | ET02 order | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-order |
| P041 | three environment TSVs | P040 | ET02 ordinals | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-ordinals |
| P042 | three environment TSVs | P041 | ET02 uniqueness | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-uniqueness |
| P043 | three environment TSVs | P042 | ET03 count | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-count |
| P044 | three environment TSVs | P043 | ET03 order | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-order |
| P045 | three environment TSVs | P044 | ET03 ordinals | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-ordinals |
| P046 | three environment TSVs | P045 | ET03 uniqueness | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-uniqueness |
| P047 | three environment TSVs | P046 | ET04 count | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-count |
| P048 | three environment TSVs | P047 | ET04 order | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-order |
| P049 | three environment TSVs | P048 | ET04 ordinals | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-ordinals |
| P050 | three environment TSVs | P049 | ET04 uniqueness | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-uniqueness |
| P051 | three environment TSVs | P050 | ET05 count | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-count |
| P052 | three environment TSVs | P051 | ET05 order | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-order |
| P053 | three environment TSVs | P052 | ET05 ordinals | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-ordinals |
| P054 | three environment TSVs | P053 | ET05 uniqueness | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-uniqueness |
| P055 | three environment TSVs | P054 | ET06 count | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-count |
| P056 | three environment TSVs | P055 | ET06 order | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-order |
| P057 | three environment TSVs | P056 | ET06 ordinals | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-ordinals |
| P058 | three environment TSVs | P057 | ET06 uniqueness | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-uniqueness |
| P059 | three environment TSVs | P058 | ET07 count | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-count |
| P060 | three environment TSVs | P059 | ET07 order | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-order |
| P061 | three environment TSVs | P060 | ET07 ordinals | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-ordinals |
| P062 | three environment TSVs | P061 | ET07 uniqueness | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-uniqueness |
| P063 | three environment TSVs | P062 | ET08 count | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-count |
| P064 | three environment TSVs | P063 | ET08 order | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-order |
| P065 | three environment TSVs | P064 | ET08 ordinals | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-ordinals |
| P066 | three environment TSVs | P065 | ET08 uniqueness | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-uniqueness |
| P067 | three environment TSVs | P066 | ET09 count | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-count |
| P068 | three environment TSVs | P067 | ET09 order | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-order |
| P069 | three environment TSVs | P068 | ET09 ordinals | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-ordinals |
| P070 | three environment TSVs | P069 | ET09 uniqueness | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-uniqueness |
| P071 | three environment TSVs | P070 | ET10 count | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-count |
| P072 | three environment TSVs | P071 | ET10 order | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-order |
| P073 | three environment TSVs | P072 | ET10 ordinals | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-ordinals |
| P074 | three environment TSVs | P073 | ET10 uniqueness | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-uniqueness |
| P075 | three environment TSVs | P074 | ET11 count | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-count |
| P076 | three environment TSVs | P075 | ET11 order | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-order |
| P077 | three environment TSVs | P076 | ET11 ordinals | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-ordinals |
| P078 | three environment TSVs | P077 | ET11 uniqueness | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-uniqueness |
| P079 | three environment TSVs | P078 | ET12 count | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-count |
| P080 | three environment TSVs | P079 | ET12 order | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-order |
| P081 | three environment TSVs | P080 | ET12 ordinals | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-ordinals |
| P082 | three environment TSVs | P081 | ET12 uniqueness | header-excluded complete fields | cut,grep -x -F,sort,uniq,wc,cmp | yes | incomplete env-uniqueness |
| P083 | three environment TSVs | P082 | coverage | 77 rows/12 definitions/no extras | cut,sort,cmp,wc | yes | incomplete coverage |
| P084 | environment_equivalence.tsv | P083 | equivalence row 1 | exact full row/pass | sed,grep -x -F,cmp | yes | incomplete equivalence |
| P085 | environment_equivalence.tsv | P084 | equivalence row 2 | exact full row/pass | sed,grep -x -F,cmp | yes | incomplete equivalence |
| P086 | environment_equivalence.tsv | P085 | equivalence row 3 | exact full row/pass | sed,grep -x -F,cmp | yes | incomplete equivalence |
| P087 | environment_equivalence.tsv | P086 | equivalence row 4 | exact full row/pass | sed,grep -x -F,cmp | yes | incomplete equivalence |
| P088 | environment_equivalence.tsv | P087 | equivalence row 5 | exact full row/pass | sed,grep -x -F,cmp | yes | incomplete equivalence |
| P089 | environment_equivalence.tsv | P088 | equivalence row 6 | exact full row/pass | sed,grep -x -F,cmp | yes | incomplete equivalence |
| P090 | ak_replay.tsv | P089 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P091 | authority_boundary.tsv | P090 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P092 | authority_derivation.tsv | P091 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P093 | environment_authority.tsv | P092 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P094 | environment_equivalence.tsv | P093 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P095 | environment_tokens.tsv | P094 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P096 | environment_variable_policy.tsv | P095 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P097 | preconstruction_derivation.tsv | P096 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P098 | preconstruction_gates.tsv | P097 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P099 | schema_authority.tsv | P098 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P100 | selector_authority.tsv | P099 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P101 | AUDIT_COMPLETE path | P100 | absence | absent/non-symlink | path metadata | yes | incomplete absence |
| P102 | five AV invocation files | P101 | produce batch | exact bytes/0644 | AV; dd,sync | five named files | incomplete producer |
| P103 | invocation_atomic_matrix.tsv | P102 | schema | 7 fields/128 rows/69 resolved/59 blocked | cut,sort,grep,wc,cmp | yes | incomplete atomic |
| P104 | invocation_atomic_matrix.tsv | P103 | invocation atomic | 7 fields/128 rows/69 resolved/59 blocked | cut,sort,grep,wc,cmp | yes | incomplete atomic |
| P105 | invocation_atomic_matrix.tsv | P104 | instance binding | 7 fields/128 rows/69 resolved/59 blocked | cut,sort,grep,wc,cmp | yes | incomplete atomic |
| P106 | invocation_atomic_matrix.tsv | P105 | counts | 7 fields/128 rows/69 resolved/59 blocked | cut,sort,grep,wc,cmp | yes | incomplete atomic |
| P107 | remaining_conflicts.tsv | P106 | conflicts | 8 C01-C08 rows | cut,cmp,wc | yes | incomplete conflict |
| P108 | dependency_order.tsv | P107 | dependencies | 12 ordered acyclic rows | cut,cmp,wc | yes | incomplete dependency |
| P109 | invocation_bijection.tsv | P108 | schema | 9 fields/54 rows/exact-once | cut,sort,grep,wc,cmp | yes | incomplete bijection |
| P110 | invocation_bijection.tsv | P109 | cardinality | 9 fields/54 rows/exact-once | cut,sort,grep,wc,cmp | yes | incomplete bijection |
| P111 | invocation_bijection.tsv | P110 | environment coverage | 9 fields/54 rows/exact-once | cut,sort,grep,wc,cmp | yes | incomplete bijection |
| P112 | invocation_bijection.tsv | P111 | dimension coverage | 9 fields/54 rows/exact-once | cut,sort,grep,wc,cmp | yes | incomplete bijection |
| P113 | invocation_atomic_matrix.tsv | P112 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P114 | invocation_bijection.tsv | P113 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P115 | atomic_summary.tsv | P114 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P116 | remaining_conflicts.tsv | P115 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P117 | dependency_order.tsv | P116 | type/mode/hash | regular/0644/noexec/reviewed hash | stat,sha256sum | yes | incomplete type-mode |
| P118 | two literal audit records | P117 | produce audit | exact schemas/current markers/0644 | literal bytes; printf,sync | two named files | incomplete producer |
| P119 | audit_gate_results.tsv | P118 | type/mode | regular/0644/noexec | stat,sha256sum | yes | incomplete type-mode |
| P120 | audit_disposition.tsv | P119 | type/mode | regular/0644/noexec | stat,sha256sum | yes | incomplete type-mode |
| P121 | audit_gate_results.tsv | P120 | schema | 4 fields/exact markers | cut,grep,wc,cmp | yes | incomplete audit schema |
| P122 | audit_disposition.tsv | P121 | schema | 2 fields/16 data/false-none | cut,grep,wc,cmp | yes | incomplete audit schema |
| P123 | 18 literal identity rows | P122 | produce identities | 19 lines/hash/bytes/mode | 18 files; sha256sum,stat,printf,sync | artifact_identities.tsv | incomplete producer |
| P124 | atomic_summary.tsv | P123 | identity replay | exact ledger row/hash/bytes/mode | ledger + file; grep -x -F,sha256sum,stat | yes | incomplete identity |
| P125 | audit_disposition.tsv | P124 | identity replay | exact ledger row/hash/bytes/mode | ledger + file; grep -x -F,sha256sum,stat | yes | incomplete identity |
| P126 | audit_gate_results.tsv | P125 | identity replay | exact ledger row/hash/bytes/mode | ledger + file; grep -x -F,sha256sum,stat | yes | incomplete identity |
| P127 | authority_boundary.tsv | P126 | identity replay | exact ledger row/hash/bytes/mode | ledger + file; grep -x -F,sha256sum,stat | yes | incomplete identity |
| P128 | authority_derivation.tsv | P127 | identity replay | exact ledger row/hash/bytes/mode | ledger + file; grep -x -F,sha256sum,stat | yes | incomplete identity |
| P129 | dependency_order.tsv | P128 | identity replay | exact ledger row/hash/bytes/mode | ledger + file; grep -x -F,sha256sum,stat | yes | incomplete identity |
| P130 | invocation_atomic_matrix.tsv | P129 | identity replay | exact ledger row/hash/bytes/mode | ledger + file; grep -x -F,sha256sum,stat | yes | incomplete identity |
| P131 | invocation_bijection.tsv | P130 | identity replay | exact ledger row/hash/bytes/mode | ledger + file; grep -x -F,sha256sum,stat | yes | incomplete identity |
| P132 | preconstruction_derivation.tsv | P131 | identity replay | exact ledger row/hash/bytes/mode | ledger + file; grep -x -F,sha256sum,stat | yes | incomplete identity |
| P133 | preconstruction_gates.tsv | P132 | identity replay | exact ledger row/hash/bytes/mode | ledger + file; grep -x -F,sha256sum,stat | yes | incomplete identity |
| P134 | remaining_conflicts.tsv | P133 | identity replay | exact ledger row/hash/bytes/mode | ledger + file; grep -x -F,sha256sum,stat | yes | incomplete identity |
| P135 | selector_authority.tsv | P134 | identity replay | exact ledger row/hash/bytes/mode | ledger + file; grep -x -F,sha256sum,stat | yes | incomplete identity |
| P136 | literal marker + absent path | P135 | derive marker | 16 lines/hash/false-none | printf pipe,sha256sum,grep | yes | incomplete derive |
| P137 | literal marker | review after P136 | exclusive finalizer | umask0022/no-clobber/0644 | printf,sync | AUDIT_COMPLETE | incomplete finalizer |
| P138 | AUDIT_COMPLETE | P137 | type/mode | regular/non-symlink/0644 | stat | yes | incomplete closure |
| P139 | AUDIT_COMPLETE | P138 | bytes/schema | hash/16 lines/false-none | sha256sum,sed,wc,cmp | yes | incomplete closure |
| P140 | target root | P139 | terminal closure | 20 paths/all0644/ledger/noexec/clean | find,sort,sha256sum,stat,git status | yes | incomplete closure |
<!-- BG-CANONICAL-END matrix MATRIX_ROWS -->

## 7. Complete invariant wrapper templates

### 7.1 Canonical ordinary-string outer source

Every process uses this complete envelope. No backtick, JavaScript template
literal, `String.raw`, JavaScript interpolation, concatenated/generated/sourced
command text, or `eval` is permitted.

```javascript
// BG-CANONICAL-BEGIN template T_OUTER
const command = "@@INNER_JS@@";
const result = await tools.exec_command({cmd: command, workdir: "/home/oleg/prog/z_llvm", yield_time_ms: 10000, max_output_tokens: 1000});
if (result.exit_code !== 0) throw new Error("@@PROCESS_ID@@_NONZERO");
if (result.output !== "@@EXPECTED_OUTPUT_JS@@") throw new Error("@@PROCESS_ID@@_OUTPUT");
text(result.output);
// BG-CANONICAL-END template T_OUTER
```

Occurrences are exactly one `@@INNER_JS@@`, two `@@PROCESS_ID@@`, and one
`@@EXPECTED_OUTPUT_JS@@`. Decoded `@@INNER_JS@@` must raw-equal the separately
reviewed inner bytes including their final LF.

### 7.2 T-CONSTRUCT-10 — P001

```sh
# BG-CANONICAL-BEGIN template T_CONSTRUCT_10
set -euo pipefail
export LC_ALL=C
umask 0022
[ "$(umask)" = 0022 ]
ROOT=@@ROOT@@
AY=/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay
[ ! -e "$ROOT" ] && [ ! -L "$ROOT" ]
mkdir --mode=0755 -- "$ROOT"
dd if="$AY/ak_replay.tsv" of="$ROOT/ak_replay.tsv" iflag=fullblock,nofollow oflag=nofollow conv=excl,fsync status=none
dd if="$AY/environment_authority.tsv" of="$ROOT/environment_authority.tsv" iflag=fullblock,nofollow oflag=nofollow conv=excl,fsync status=none
dd if="$AY/environment_equivalence.tsv" of="$ROOT/environment_equivalence.tsv" iflag=fullblock,nofollow oflag=nofollow conv=excl,fsync status=none
dd if="$AY/environment_tokens.tsv" of="$ROOT/environment_tokens.tsv" iflag=fullblock,nofollow oflag=nofollow conv=excl,fsync status=none
dd if="$AY/environment_variable_policy.tsv" of="$ROOT/environment_variable_policy.tsv" iflag=fullblock,nofollow oflag=nofollow conv=excl,fsync status=none
dd if="$AY/schema_authority.tsv" of="$ROOT/schema_authority.tsv" iflag=fullblock,nofollow oflag=nofollow conv=excl,fsync status=none
printf '%s' '@@BOUNDARY_FILE_BYTES_JS@@' >"$ROOT/authority_boundary.tsv"
sync -f "$ROOT/authority_boundary.tsv"
printf '%s' '@@DERIVATION_FILE_BYTES_JS@@' >"$ROOT/authority_derivation.tsv"
sync -f "$ROOT/authority_derivation.tsv"
printf '%s' '@@PRECON_DERIVATION_BYTES_JS@@' >"$ROOT/preconstruction_derivation.tsv"
sync -f "$ROOT/preconstruction_derivation.tsv"
printf '%s' '@@PRECON_GATES_BYTES_JS@@' >"$ROOT/preconstruction_gates.tsv"
sync -f "$ROOT/preconstruction_gates.tsv"
[ "$(find -P "$ROOT" -mindepth 1 -maxdepth 1 -type f | wc -l)" -eq 10 ]
echo P001_OK
# BG-CANONICAL-END template T_CONSTRUCT_10
```

The four byte placeholders occur once each and are typed non-executable file
bytes. The six copies are explicit and ordered; no loop generates source.

### 7.3 T-READ-GATE — P017-P101, P103-P117,
P119-P122, P124-P135, P138-P140

```sh
# BG-CANONICAL-BEGIN template T_READ_GATE
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
[ -d "$ROOT" ] && [ ! -L "$ROOT" ]
INPUT="$ROOT/@@INPUT_BASENAME@@"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
@@LITERAL_ASSERTION@@
echo @@PROCESS_ID@@_OK
# BG-CANONICAL-END template T_READ_GATE
```

`@@INPUT_BASENAME@@` is a closed-set final filename. Each P-ID has one
separately reviewed fixed assertion block with exact bytes, length, SHA-256,
allowed reads, and no-write proof. A table may describe but never generate or
execute an assertion. Allowed commands are `read`, `cut`, `wc`, `sort`,
`uniq`, `cmp`, `sha256sum`, `stat`, target-root-limited `find -P`, and
`grep -x -F` after complete-field extraction.

### 7.4 T-COPY-SELECTOR — P016

```sh
# BG-CANONICAL-BEGIN template T_COPY_SELECTOR
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
AV=/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206av
[ -d "$ROOT" ] && [ ! -L "$ROOT" ]
[ ! -e "$ROOT/selector_authority.tsv" ] && [ ! -L "$ROOT/selector_authority.tsv" ]
dd if="$AV/selector_authority.tsv" of="$ROOT/selector_authority.tsv" iflag=fullblock,nofollow oflag=nofollow conv=excl,fsync status=none
echo P016_OK
# BG-CANONICAL-END template T_COPY_SELECTOR
```

### 7.5 T-INVOCATION-BATCH — P102

```sh
# BG-CANONICAL-BEGIN template T_INVOCATION_BATCH
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
AV=/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206av
[ -d "$ROOT" ] && [ ! -L "$ROOT" ]
[ ! -e "$ROOT/invocation_atomic_matrix.tsv" ] && [ ! -L "$ROOT/invocation_atomic_matrix.tsv" ]
dd if="$AV/invocation_atomic_matrix.tsv" of="$ROOT/invocation_atomic_matrix.tsv" iflag=fullblock,nofollow oflag=nofollow conv=excl,fsync status=none
[ ! -e "$ROOT/invocation_bijection.tsv" ] && [ ! -L "$ROOT/invocation_bijection.tsv" ]
dd if="$AV/invocation_bijection.tsv" of="$ROOT/invocation_bijection.tsv" iflag=fullblock,nofollow oflag=nofollow conv=excl,fsync status=none
[ ! -e "$ROOT/atomic_summary.tsv" ] && [ ! -L "$ROOT/atomic_summary.tsv" ]
dd if="$AV/atomic_summary.tsv" of="$ROOT/atomic_summary.tsv" iflag=fullblock,nofollow oflag=nofollow conv=excl,fsync status=none
[ ! -e "$ROOT/remaining_conflicts.tsv" ] && [ ! -L "$ROOT/remaining_conflicts.tsv" ]
dd if="$AV/remaining_conflicts.tsv" of="$ROOT/remaining_conflicts.tsv" iflag=fullblock,nofollow oflag=nofollow conv=excl,fsync status=none
[ ! -e "$ROOT/dependency_order.tsv" ] && [ ! -L "$ROOT/dependency_order.tsv" ]
dd if="$AV/dependency_order.tsv" of="$ROOT/dependency_order.tsv" iflag=fullblock,nofollow oflag=nofollow conv=excl,fsync status=none
echo P102_OK
# BG-CANONICAL-END template T_INVOCATION_BATCH
```

### 7.6 T-AUDIT-BATCH — P118

```sh
# BG-CANONICAL-BEGIN template T_AUDIT_BATCH
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
[ -d "$ROOT" ] && [ ! -L "$ROOT" ]
[ ! -e "$ROOT/audit_gate_results.tsv" ] && [ ! -L "$ROOT/audit_gate_results.tsv" ]
[ ! -e "$ROOT/audit_disposition.tsv" ] && [ ! -L "$ROOT/audit_disposition.tsv" ]
printf '%s' '@@AUDIT_GATE_RESULTS_BYTES_JS@@' >"$ROOT/audit_gate_results.tsv"
sync -f "$ROOT/audit_gate_results.tsv"
printf '%s' '@@AUDIT_DISPOSITION_BYTES_JS@@' >"$ROOT/audit_disposition.tsv"
sync -f "$ROOT/audit_disposition.tsv"
echo P118_OK
# BG-CANONICAL-END template T_AUDIT_BATCH
```

Both typed byte fields occur once and preserve retained schemas/cardinalities.

### 7.7 T-ARTIFACT-IDENTITIES — P123

```sh
# BG-CANONICAL-BEGIN template T_ARTIFACT_IDENTITIES
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
[ -d "$ROOT" ] && [ ! -L "$ROOT" ]
[ ! -e "$ROOT/artifact_identities.tsv" ] && [ ! -L "$ROOT/artifact_identities.tsv" ]
printf '%s' '@@ARTIFACT_IDENTITIES_BYTES_JS@@' >"$ROOT/artifact_identities.tsv"
sync -f "$ROOT/artifact_identities.tsv"
[ "$(wc -l <"$ROOT/artifact_identities.tsv")" -eq 19 ]
echo P123_OK
# BG-CANONICAL-END template T_ARTIFACT_IDENTITIES
```

Its 18 bytewise-path-ordered data rows exclude itself and `AUDIT_COMPLETE` and
use identity scope `pre-final-self-excluded`.

### 7.8 T-MARKER-DERIVE — P136

```sh
# BG-CANONICAL-BEGIN template T_MARKER_DERIVE
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
[ -d "$ROOT" ] && [ ! -L "$ROOT" ]
[ ! -e "$ROOT/AUDIT_COMPLETE" ] && [ ! -L "$ROOT/AUDIT_COMPLETE" ]
printf '%s' '@@MARKER_BYTES_JS@@' | sha256sum | grep -x -F '@@MARKER_SHA256@@  -'
echo P136_OK
# BG-CANONICAL-END template T_MARKER_DERIVE
```

P136 writes nothing. It freezes marker bytes/hash and literal finalizer
source/hash for separate review.

### 7.9 T-MARKER-FINALIZE — P137

```sh
# BG-CANONICAL-BEGIN template T_MARKER_FINALIZE
set -euo pipefail
export LC_ALL=C
umask 0022
[ "$(umask)" = 0022 ]
ROOT=@@ROOT@@
MARKER="$ROOT/AUDIT_COMPLETE"
[ -d "$ROOT" ] && [ ! -L "$ROOT" ]
[ ! -e "$MARKER" ] && [ ! -L "$MARKER" ]
set -o noclobber
printf '%s' '@@MARKER_BYTES_JS@@' >"$MARKER"
sync -f "$MARKER"
echo P137_OK
# BG-CANONICAL-END template T_MARKER_FINALIZE
```

This is the sole marker producer: one complete exclusive no-clobber write in a
closed shell. `apply_patch`, `chmod`, overwrite, append, rename, generated
command, sourced table, and `eval` are forbidden. No target byte may change
after P137.

### 7.10 T-FINAL-CLOSURE — P138-P140

```sh
# BG-CANONICAL-BEGIN template T_FINAL_CLOSURE
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
[ -d "$ROOT" ] && [ ! -L "$ROOT" ]
@@LITERAL_ASSERTION@@
echo @@PROCESS_ID@@_OK
# BG-CANONICAL-END template T_FINAL_CLOSURE
```

P138 verifies marker regular/non-symlink/type/mode 0644. P139 verifies exact
bytes/hash/schema and false/none fields. P140 independently verifies the
20-file path set, all-0644 inventory, NUL-sorted ledger, zero execute bits, and
unchanged main/control state. Each is read-only and separately frozen.

### 7.11 BC-frozen P002-P015 inner templates

These 14 blocks are complete inner templates after literal assertion insertion.
They contain no `@@LITERAL_ASSERTION@@` and no undeclared executable-logic
token. They are inert text and must not be invoked in BC.

#### P002 — authority-boundary header

```sh
# BG-CANONICAL-BEGIN template P002
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
INPUT="$ROOT/authority_boundary.tsv"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
[ "$(sed -n '1p' "$INPUT")" = $'field\tvalue' ]
echo P002_OK
# BG-CANONICAL-END template P002
```

#### P003 — authority-boundary exact 19-line content

```sh
# BG-CANONICAL-BEGIN template P003
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
INPUT="$ROOT/authority_boundary.tsv"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
expected=$(cat <<'EXPECTED'
field	value
slice	@@SLICE@@
kind	inert-environment-and-invocation-atomic-audit-closure
operating_commit	@@HEAD@@
operating_parent	@@PARENT@@
operating_tree	@@TREE@@
operating_changed_path	@@CHANGED_PATH@@
ignored_inbox_sha256	@@INBOX_SHA256@@
ak_root	/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ak
ak_disposition	accepted-stage1-and-enumeration-evidence-only
al_state	absent-permanent
am_state	absent-permanent
implementation	no
execution	no
validation	no
production_awk	unauthorized
D02	unauthorized
ratchet	131-unchanged
credit	none
EXPECTED
)
echo "$expected" | cmp - "$INPUT"
[ "$(wc -l <"$INPUT")" -eq 19 ]
echo P003_OK
# BG-CANONICAL-END template P003
```

#### P004 — authority-derivation header

```sh
# BG-CANONICAL-BEGIN template P004
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
INPUT="$ROOT/authority_derivation.tsv"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
[ "$(sed -n '1p' "$INPUT")" = $'source_path\tkey_or_order\tsource_value\texpected_value\tdisposition' ]
echo P004_OK
# BG-CANONICAL-END template P004
```

#### P005 — authority-derivation exact independent 20-line content

```sh
# BG-CANONICAL-BEGIN template P005
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
INPUT="$ROOT/authority_derivation.tsv"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
expected=$(cat <<'EXPECTED'
source_path	key_or_order	source_value	expected_value	disposition
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	__header__	field<TAB>value	field<TAB>value	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	slice	INBOX-206AY	@@SLICE@@	mechanical-current-authority
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	kind	inert-environment-and-invocation-atomic-audit-closure	inert-environment-and-invocation-atomic-audit-closure	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	operating_commit	f473db5eb40ff69d36f1723b32a8c42178316854	@@HEAD@@	mechanical-current-authority
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	operating_parent	47b783e4570be05e6eb7bb81c4a9071bad8d354e	@@PARENT@@	mechanical-current-authority
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	operating_tree	6d10ffdf9b3817ae77052719c67a7a2c7cef4dda	@@TREE@@	mechanical-current-authority
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	operating_changed_path	docs/next_steps.md	@@CHANGED_PATH@@	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	ignored_inbox_sha256	f5838f11c010a83602191db36786162178fd072c1736d0b7149aa6cbc113a347	@@INBOX_SHA256@@	mechanical-current-authority
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	ak_root	/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ak	/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ak	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	ak_disposition	accepted-stage1-and-enumeration-evidence-only	accepted-stage1-and-enumeration-evidence-only	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	al_state	absent-permanent	absent-permanent	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	am_state	absent-permanent	absent-permanent	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	implementation	no	no	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	execution	no	no	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	validation	no	no	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	production_awk	unauthorized	unauthorized	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	D02	unauthorized	unauthorized	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	ratchet	131-unchanged	131-unchanged	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	credit	none	none	unchanged
EXPECTED
)
echo "$expected" | cmp - "$INPUT"
[ "$(wc -l <"$INPUT")" -eq 20 ]
echo P005_OK
# BG-CANONICAL-END template P005
```

#### P006 — environment-authority header

```sh
# BG-CANONICAL-BEGIN template P006
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
INPUT="$ROOT/environment_authority.tsv"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
[ "$(sed -n '1p' "$INPUT")" = $'definition_id\ttoken\texpected_count\tordered_variables\tliteral_ordinals' ]
echo P006_OK
# BG-CANONICAL-END template P006
```

#### P007 — exact expected-count stream

```sh
# BG-CANONICAL-BEGIN template P007
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
INPUT="$ROOT/environment_authority.tsv"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
expected=$(cat <<'EXPECTED'
7
7
4
24
4
4
4
7
4
4
4
4
EXPECTED
)
tail -n +2 "$INPUT" | cut -f3 | cmp - <(echo "$expected")
echo P007_OK
# BG-CANONICAL-END template P007
```

#### P008 — ordered ET01-ET12 IDs

```sh
# BG-CANONICAL-BEGIN template P008
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
INPUT="$ROOT/environment_authority.tsv"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
expected=$(cat <<'EXPECTED'
ET01
ET02
ET03
ET04
ET05
ET06
ET07
ET08
ET09
ET10
ET11
ET12
EXPECTED
)
tail -n +2 "$INPUT" | cut -f1 | cmp - <(echo "$expected")
echo P008_OK
# BG-CANONICAL-END template P008
```

#### P009 — unique IDs

```sh
# BG-CANONICAL-BEGIN template P009
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
INPUT="$ROOT/environment_authority.tsv"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
[ "$(tail -n +2 "$INPUT" | cut -f1 | LC_ALL=C sort -u | wc -l)" -eq 12 ]
[ "$(wc -l <"$INPUT")" -eq 13 ]
echo P009_OK
# BG-CANONICAL-END template P009
```

#### P010 — unique tokens

```sh
# BG-CANONICAL-BEGIN template P010
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
INPUT="$ROOT/environment_authority.tsv"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
[ "$(tail -n +2 "$INPUT" | cut -f2 | LC_ALL=C sort -u | wc -l)" -eq 12 ]
echo P010_OK
# BG-CANONICAL-END template P010
```

#### P011 — exactly five fields per row

```sh
# BG-CANONICAL-BEGIN template P011
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
INPUT="$ROOT/environment_authority.tsv"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
/usr/bin/perl -F'\t' -lane 'scalar(@F)==5 or die "field-count\n"' "$INPUT"
echo P011_OK
# BG-CANONICAL-END template P011
```

#### P012 — closed ID domain

```sh
# BG-CANONICAL-BEGIN template P012
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
INPUT="$ROOT/environment_authority.tsv"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
tail -n +2 "$INPUT" | cut -f1 | grep -E -v '^ET(0[1-9]|1[0-2])$' > /dev/null && exit 1 || status=$?
[ "$status" -eq 1 ]
echo P012_OK
# BG-CANONICAL-END template P012
```

#### P013 — closed count domain

```sh
# BG-CANONICAL-BEGIN template P013
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
INPUT="$ROOT/environment_authority.tsv"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
tail -n +2 "$INPUT" | cut -f3 | grep -E -v '^(4|7|24)$' > /dev/null && exit 1 || status=$?
[ "$status" -eq 1 ]
echo P013_OK
# BG-CANONICAL-END template P013
```

#### P014 — literal sequential two-digit ordinals

```sh
# BG-CANONICAL-BEGIN template P014
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
INPUT="$ROOT/environment_authority.tsv"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
/usr/bin/perl -F'\t' -lane 'next if $.==1; @o=split(/,/, $F[4], -1); @o==$F[2] or die "ordinal-count\n"; for($i=0;$i<@o;$i++){ $o[$i] eq sprintf("%02d",$i+1) or die "ordinal-value\n" }' "$INPUT"
echo P014_OK
# BG-CANONICAL-END template P014
```

#### P015 — exact token schema and retained identity

```sh
# BG-CANONICAL-BEGIN template P015
set -euo pipefail
export LC_ALL=C
ROOT=@@ROOT@@
INPUT="$ROOT/environment_tokens.tsv"
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
[ "$(sha256sum "$INPUT" | cut -d ' ' -f1)" = 4e9c9f331fcab38a19ae617eafd07d768bd7654980a1fd094890c7db73a339fc ]
[ "$(wc -l <"$INPUT")" -eq 13 ]
[ "$(sed -n '1p' "$INPUT")" = $'definition_id\ttoken\tscope\tordered_variables\texecutable_resolution\tunknown_variable_rule\tsecret_safe_rule\tdefinition_state' ]
/usr/bin/perl -F'\t' -lane 'scalar(@F)==8 or die "field-count\n"' "$INPUT"
echo P015_OK
# BG-CANONICAL-END template P015
```

### 7.12 P002-P015 frozen identities and occurrence manifests

All byte counts include the final LF. Offsets are zero-based UTF-8 byte
half-open spans within the inner template. All templates allow reads only of
the named input beneath `@@ROOT@@`; commands are limited to shell builtins,
`sed`, `cat`, `cmp`, `wc`, `tail`, `cut`, `sort`, `grep`, `sha256sum`, and the
literal `/usr/bin/perl` scanners shown. None has a redirection to a filesystem
path, producer operation, mode change, or write capability.

| P-ID | input / producer | predicate | bytes | SHA-256 | identity-token spans | output/status |
|---|---|---|---:|---|---|---|
| P002 | authority_boundary.tsv / P001 | exact header | 183 | f3f07054713485485986b67af5f4ab819ff6f280fa2afddb1d42ac3071826411 | ROOT 39:47 | `P002_OK` LF / 0 |
| P003 | authority_boundary.tsv / P001 | exact 19-line schema/order/keys/values | 803 | 40a7144e019b45af04e112d456a43f63e925992a3d93e93887498ff25c5d8131 | ROOT 39:47; SLICE 168:177; HEAD 254:262; PARENT 280:290; TREE 306:314; CHANGED_PATH 338:354; INBOX_SHA256 376:392 | `P003_OK` LF / 0 |
| P004 | authority_derivation.tsv / P001 | exact header | 241 | 17ec8b17eef2ac773d192b45b1deb8e2fe8bee6f8f5ed7975eb5291c448c9b97 | ROOT 39:47 | `P004_OK` LF / 0 |
| P005 | authority_derivation.tsv / P001 | exact independent 20-line schema/order/values | 3530 | e1828a654a4b8262dac83c9fc871df9b4b76bca65353bb90f08aece88261647d | ROOT 39:47; SLICE 484:493; HEAD 900:908; PARENT 1094:1104; TREE 1288:1296; CHANGED_PATH 1466:1482; INBOX_SHA256 1677:1693 | `P005_OK` LF / 0 |
| P006 | environment_authority.tsv / P001 | exact header | 247 | fd087cb63ce5fe9fbee17a4aff126ea4f3c7869f2336a9f4264d35272f79d245 | ROOT 39:47 | `P006_OK` LF / 0 |
| P007 | environment_authority.tsv / P001 | exact count stream | 260 | 92042292dbe0662a61efda982251e888e44a1580a7b1bbbe1a16446d1a973aef | ROOT 39:47 | `P007_OK` LF / 0 |
| P008 | environment_authority.tsv / P001 | ordered ET01-ET12 IDs | 295 | 27df9fd261ba0e2fe4b575398a709d9a0cb7145827bd72c819031034daee63e0 | ROOT 39:47 | `P008_OK` LF / 0 |
| P009 | environment_authority.tsv / P001 | unique IDs and 13 lines | 243 | 1b97341986df8c9552fd93fa2d4c0a9dc535b89de4319f7b1bbed4bc0bd3ec76 | ROOT 39:47 | `P009_OK` LF / 0 |
| P010 | environment_authority.tsv / P001 | unique tokens | 211 | 78d15fedc6349ecac733d97869b00602b9e97ccaa6153d41b284682fa86ac55d | ROOT 39:47 | `P010_OK` LF / 0 |
| P011 | environment_authority.tsv / P001 | exactly five fields every row | 213 | 07cf33df752f203187c469aeccbc7d20a904d8deae48fc70df001c0592d1c790 | ROOT 39:47 | `P011_OK` LF / 0 |
| P012 | environment_authority.tsv / P001 | closed ID domain | 258 | 8eb5c3ea80d081f21276a7073548e1044296d115c6a71b80095ac43be816fced | ROOT 39:47 | `P012_OK` LF / 0 |
| P013 | environment_authority.tsv / P001 | closed count domain | 249 | 12550a723800e9dc77f0615f749a777195ef62d8f44a2ee6e2a1f4f547b33770 | ROOT 39:47 | `P013_OK` LF / 0 |
| P014 | environment_authority.tsv / P001 | sequential two-digit ordinals | 333 | ceda5b7e75492576596a93fb60aa8b813a22cab1785f25706e9e2dc80ed8a935 | ROOT 39:47 | `P014_OK` LF / 0 |
| P015 | environment_tokens.tsv / P001 | exact hash/header/13 lines/eight fields | 518 | 0519263f35aa760da0c50d6f5e7b8c0bd894886c718790739934f3797602f2c5 | ROOT 39:47 | `P015_OK` LF / 0 |

The separately frozen literal assertion blocks begin with the regular-file and
no-symlink assertion and end immediately before each success output:

| P-ID | assertion bytes | assertion SHA-256 |
|---|---:|---|
| P002 | 85 | 453cd42dcf47790fcba30180e7d9e1cb7c1a1997b07c064384b20a9bb067d902 |
| P003 | 705 | e0215d8cdf0a45aea24e0e8f54715159798c24baf782e3c39dd71923c4bbb192 |
| P004 | 141 | 9339e311a57c9e07657f6bb0a2323723784819c418b4058aad6a58c0207eebaa |
| P005 | 3430 | 057a68edb24f99f5c18001203d53846e4ecf0d6fa6dee81acc56c4cc0a1f976a |
| P006 | 146 | 8d2b7f5092cec8a9bc38b41147e7b47ac3737083c188699bb61c6cb191a2eece |
| P007 | 159 | a430068dfc6efbc1740507f8283e92df449fcc088a2896317c1ab385b038f1d5 |
| P008 | 194 | e7455095df8f6242e7d0bcd1248ac54aa4505cde367bbf0dda6cdb4377453b56 |
| P009 | 142 | 69ddc0b193f29573fb8464ba63f4118c0181834261fc567ab0323fec65b31d4b |
| P010 | 110 | 83fa92142449e13e4741fbfbd50c597df34e165c475f8c8585f8faeb6670e027 |
| P011 | 112 | 3f07f6221fb676d267f137bb8a63309d780d03946ed928f7e26da27129c0aaea |
| P012 | 157 | 2ec54f435d4c8f5fbbd635f36b382a170eaa56ef37e87c8f5062af16d0438bc3 |
| P013 | 148 | 688ce553003e4634c2537c140fe1f118a361d58a92b44880069e3ea79c1bbb8c |
| P014 | 232 | 068279f2354bc4738826a526450e99fccf4a9955c5aa4e23c95b8c1b2cb1820e |
| P015 | 420 | e258aec554bc2567e07d0944d0cc9b55758bc47f25b326f17b64dc1d1f7fd8bb |

### 7.13 Complete current placeholder inventory

The code-template occurrence inventory is exact. Names in this table are
rendered without delimiter pairs so the table itself is not executable
materialization authority.

| template | occurrences and ordered half-open spans |
|---|---|
| T-OUTER | INNER_JS 17:29; PROCESS_ID 216:230; EXPECTED_OUTPUT_JS 265:287; PROCESS_ID 307:321 |
| T-CONSTRUCT-10 | ROOT 72:80; BOUNDARY_FILE_BYTES_JS 1072:1098; DERIVATION_FILE_BYTES_JS 1184:1212; PRECON_DERIVATION_BYTES_JS 1302:1332; PRECON_GATES_BYTES_JS 1434:1459 |
| T-READ-GATE | ROOT 39:47; INPUT_BASENAME 96:114; LITERAL_ASSERTION 153:174; PROCESS_ID 180:194 |
| T-COPY-SELECTOR | ROOT 39:47 |
| T-INVOCATION-BATCH | ROOT 39:47 |
| T-AUDIT-BATCH | ROOT 39:47; AUDIT_GATE_RESULTS_BYTES_JS 260:291; AUDIT_DISPOSITION_BYTES_JS 377:407 |
| T-ARTIFACT-IDENTITIES | ROOT 39:47; ARTIFACT_IDENTITIES_BYTES_JS 181:213 |
| T-MARKER-DERIVE | ROOT 39:47; MARKER_BYTES_JS 163:182; MARKER_SHA256 210:227 |
| T-MARKER-FINALIZE | ROOT 72:80; MARKER_BYTES_JS 217:236 |
| T-FINAL-CLOSURE | ROOT 39:47; LITERAL_ASSERTION 83:104; PROCESS_ID 110:124 |
| P002 | ROOT 39:47 |
| P003 | ROOT 39:47; SLICE 168:177; HEAD 254:262; PARENT 280:290; TREE 306:314; CHANGED_PATH 338:354; INBOX_SHA256 376:392 |
| P004 | ROOT 39:47 |
| P005 | ROOT 39:47; SLICE 484:493; HEAD 900:908; PARENT 1094:1104; TREE 1288:1296; CHANGED_PATH 1466:1482; INBOX_SHA256 1677:1693 |
| P006-P015 | ROOT 39:47 once in each template |

Placeholder type/future authority is closed as follows: ROOT, SLICE, HEAD,
PARENT, TREE, CHANGED_PATH, and INBOX_SHA256 use section 4 identity authority;
INNER_JS and EXPECTED_OUTPUT_JS use the separately reviewed outer-materializer
authority; PROCESS_ID and INPUT_BASENAME are closed enums from sections 2 and
6; all names ending `_BYTES_JS` are literal non-executable file-byte fields
whose decoded bytes, count, hash, and schema must be independently reviewed;
MARKER_SHA256 is the reviewed marker hash. `LITERAL_ASSERTION` is executable
logic authority and therefore is prohibited from future materialization until
replaced by a complete literal block.

Declared-but-unused in code templates: `LITERAL_FILE_BYTES_JS` has zero code
occurrences and is superseded by the specifically named `_BYTES_JS` fields.
Actually present but previously undeclared specific fields are now typed:
BOUNDARY_FILE_BYTES_JS, DERIVATION_FILE_BYTES_JS,
PRECON_DERIVATION_BYTES_JS, PRECON_GATES_BYTES_JS,
AUDIT_GATE_RESULTS_BYTES_JS, AUDIT_DISPOSITION_BYTES_JS, and
ARTIFACT_IDENTITIES_BYTES_JS are each one literal-file-byte field;
INPUT_BASENAME is a closed basename enum. No other token is admitted.


### 7.14 BG canonical-region grammar and assertion proof copies

Canonical regions have one unique BEGIN/END pair, exclude delimiter lines, include the interior final LF, and are globally non-nested and non-overlapping. Token inventory is derived only from `template` regions; matrix, assertion copies, tables, prose, expected manifests, and closure source remain outside that scan.

```text
canonical_region_count=39
canonical_template_region_count=24
canonical_assertion_region_count=14
canonical_matrix_region_count=1
utf8_span_convention=zero-based-half-open
frozen_interior_mutation=false
```

#### P002 canonical assertion proof copy

```sh
# BG-CANONICAL-BEGIN assertion P002
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
[ "$(sed -n '1p' "$INPUT")" = $'field\tvalue' ]
# BG-CANONICAL-END assertion P002
```

#### P003 canonical assertion proof copy

```sh
# BG-CANONICAL-BEGIN assertion P003
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
expected=$(cat <<'EXPECTED'
field	value
slice	@@SLICE@@
kind	inert-environment-and-invocation-atomic-audit-closure
operating_commit	@@HEAD@@
operating_parent	@@PARENT@@
operating_tree	@@TREE@@
operating_changed_path	@@CHANGED_PATH@@
ignored_inbox_sha256	@@INBOX_SHA256@@
ak_root	/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ak
ak_disposition	accepted-stage1-and-enumeration-evidence-only
al_state	absent-permanent
am_state	absent-permanent
implementation	no
execution	no
validation	no
production_awk	unauthorized
D02	unauthorized
ratchet	131-unchanged
credit	none
EXPECTED
)
echo "$expected" | cmp - "$INPUT"
[ "$(wc -l <"$INPUT")" -eq 19 ]
# BG-CANONICAL-END assertion P003
```

#### P004 canonical assertion proof copy

```sh
# BG-CANONICAL-BEGIN assertion P004
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
[ "$(sed -n '1p' "$INPUT")" = $'source_path\tkey_or_order\tsource_value\texpected_value\tdisposition' ]
# BG-CANONICAL-END assertion P004
```

#### P005 canonical assertion proof copy

```sh
# BG-CANONICAL-BEGIN assertion P005
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
expected=$(cat <<'EXPECTED'
source_path	key_or_order	source_value	expected_value	disposition
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	__header__	field<TAB>value	field<TAB>value	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	slice	INBOX-206AY	@@SLICE@@	mechanical-current-authority
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	kind	inert-environment-and-invocation-atomic-audit-closure	inert-environment-and-invocation-atomic-audit-closure	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	operating_commit	f473db5eb40ff69d36f1723b32a8c42178316854	@@HEAD@@	mechanical-current-authority
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	operating_parent	47b783e4570be05e6eb7bb81c4a9071bad8d354e	@@PARENT@@	mechanical-current-authority
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	operating_tree	6d10ffdf9b3817ae77052719c67a7a2c7cef4dda	@@TREE@@	mechanical-current-authority
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	operating_changed_path	docs/next_steps.md	@@CHANGED_PATH@@	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	ignored_inbox_sha256	f5838f11c010a83602191db36786162178fd072c1736d0b7149aa6cbc113a347	@@INBOX_SHA256@@	mechanical-current-authority
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	ak_root	/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ak	/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ak	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	ak_disposition	accepted-stage1-and-enumeration-evidence-only	accepted-stage1-and-enumeration-evidence-only	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	al_state	absent-permanent	absent-permanent	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	am_state	absent-permanent	absent-permanent	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	implementation	no	no	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	execution	no	no	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	validation	no	no	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	production_awk	unauthorized	unauthorized	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	D02	unauthorized	unauthorized	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	ratchet	131-unchanged	131-unchanged	unchanged
/tmp/zllvm-inbox206-authority-validation-evidence/continuations/inbox206ay/authority_boundary.tsv	credit	none	none	unchanged
EXPECTED
)
echo "$expected" | cmp - "$INPUT"
[ "$(wc -l <"$INPUT")" -eq 20 ]
# BG-CANONICAL-END assertion P005
```

#### P006 canonical assertion proof copy

```sh
# BG-CANONICAL-BEGIN assertion P006
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
[ "$(sed -n '1p' "$INPUT")" = $'definition_id\ttoken\texpected_count\tordered_variables\tliteral_ordinals' ]
# BG-CANONICAL-END assertion P006
```

#### P007 canonical assertion proof copy

```sh
# BG-CANONICAL-BEGIN assertion P007
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
expected=$(cat <<'EXPECTED'
7
7
4
24
4
4
4
7
4
4
4
4
EXPECTED
)
tail -n +2 "$INPUT" | cut -f3 | cmp - <(echo "$expected")
# BG-CANONICAL-END assertion P007
```

#### P008 canonical assertion proof copy

```sh
# BG-CANONICAL-BEGIN assertion P008
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
expected=$(cat <<'EXPECTED'
ET01
ET02
ET03
ET04
ET05
ET06
ET07
ET08
ET09
ET10
ET11
ET12
EXPECTED
)
tail -n +2 "$INPUT" | cut -f1 | cmp - <(echo "$expected")
# BG-CANONICAL-END assertion P008
```

#### P009 canonical assertion proof copy

```sh
# BG-CANONICAL-BEGIN assertion P009
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
[ "$(tail -n +2 "$INPUT" | cut -f1 | LC_ALL=C sort -u | wc -l)" -eq 12 ]
[ "$(wc -l <"$INPUT")" -eq 13 ]
# BG-CANONICAL-END assertion P009
```

#### P010 canonical assertion proof copy

```sh
# BG-CANONICAL-BEGIN assertion P010
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
[ "$(tail -n +2 "$INPUT" | cut -f2 | LC_ALL=C sort -u | wc -l)" -eq 12 ]
# BG-CANONICAL-END assertion P010
```

#### P011 canonical assertion proof copy

```sh
# BG-CANONICAL-BEGIN assertion P011
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
/usr/bin/perl -F'\t' -lane 'scalar(@F)==5 or die "field-count\n"' "$INPUT"
# BG-CANONICAL-END assertion P011
```

#### P012 canonical assertion proof copy

```sh
# BG-CANONICAL-BEGIN assertion P012
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
tail -n +2 "$INPUT" | cut -f1 | grep -E -v '^ET(0[1-9]|1[0-2])$' > /dev/null && exit 1 || status=$?
[ "$status" -eq 1 ]
# BG-CANONICAL-END assertion P012
```

#### P013 canonical assertion proof copy

```sh
# BG-CANONICAL-BEGIN assertion P013
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
tail -n +2 "$INPUT" | cut -f3 | grep -E -v '^(4|7|24)$' > /dev/null && exit 1 || status=$?
[ "$status" -eq 1 ]
# BG-CANONICAL-END assertion P013
```

#### P014 canonical assertion proof copy

```sh
# BG-CANONICAL-BEGIN assertion P014
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
/usr/bin/perl -F'\t' -lane 'next if $.==1; @o=split(/,/, $F[4], -1); @o==$F[2] or die "ordinal-count\n"; for($i=0;$i<@o;$i++){ $o[$i] eq sprintf("%02d",$i+1) or die "ordinal-value\n" }' "$INPUT"
# BG-CANONICAL-END assertion P014
```

#### P015 canonical assertion proof copy

```sh
# BG-CANONICAL-BEGIN assertion P015
[ -f "$INPUT" ] && [ ! -L "$INPUT" ]
[ "$(sha256sum "$INPUT" | cut -d ' ' -f1)" = 4e9c9f331fcab38a19ae617eafd07d768bd7654980a1fd094890c7db73a339fc ]
[ "$(wc -l <"$INPUT")" -eq 13 ]
[ "$(sed -n '1p' "$INPUT")" = $'definition_id\ttoken\tscope\tordered_variables\texecutable_resolution\tunknown_variable_rule\tsecret_safe_rule\tdefinition_state' ]
/usr/bin/perl -F'\t' -lane 'scalar(@F)==8 or die "field-count\n"' "$INPUT"
# BG-CANONICAL-END assertion P015
```

### 7.15 Frozen BG inert static closure

This source parses and hashes inert document bytes only. It invokes no assertion, package wrapper, generated package command, or package member.

```text
closure_source_bytes=9385
closure_source_sha256=8f2ccbbc8540aa17949e6b183ea40e77054de41972b29db6f1ba65a5f931c8a5
closure_expected_output=BG_STATIC_CLOSURE_OK
closure_expected_status=0
```

```javascript
const RC="/usr/bin/xxd -p -c 200000 docs/evidence/inbox206bb_phase3_wrapper_package_specification.md";
const r=await tools.exec_command({cmd:RC,workdir:"/home/oleg/prog/z_llvm",yield_time_ms:10000,max_output_tokens:50000});if(r.exit_code!==0||!r.output.endsWith("\n"))throw new Error("BG_C_READ");
const h=r.output.slice(0,-1);if(h.indexOf("\n")!==-1||h.length%2!==0)throw new Error("BG_C_HEX");function hn(c){const n=c.charCodeAt(0);if(n>=48&&n<=57)return n-48;if(n>=97&&n<=102)return n-87;throw new Error("BG_C_HEXCHAR");}const d=new Uint8Array(h.length/2);for(let i=0;i<d.length;i++)d[i]=(hn(h[i*2])<<4)|hn(h[i*2+1]);
function ue(s){const a=[];for(let i=0;i<s.length;i++){let c=s.charCodeAt(i);if(c>=55296&&c<=56319){if(i+1>=s.length)throw new Error("BG_C_U");const z=s.charCodeAt(++i);if(z<56320||z>57343)throw new Error("BG_C_U");c=65536+((c-55296)<<10)+(z-56320);}else if(c>=56320&&c<=57343)throw new Error("BG_C_U");if(c<=127)a.push(c);else if(c<=2047)a.push(192|(c>>6),128|(c&63));else if(c<=65535)a.push(224|(c>>12),128|((c>>6)&63),128|(c&63));else a.push(240|(c>>18),128|((c>>12)&63),128|((c>>6)&63),128|(c&63));}return new Uint8Array(a);}function E(s){return ue(s);}
function rotr(x,n){return(x>>>n)|(x<<(32-n));}const K=[1116352408,1899447441,3049323471,3921009573,961987163,1508970993,2453635748,2870763221,3624381080,310598401,607225278,1426881987,1925078388,2162078206,2614888103,3248222580,3835390401,4022224774,264347078,604807628,770255983,1249150122,1555081692,1996064986,2554220882,2821834349,2952996808,3210313671,3336571891,3584528711,113926993,338241895,666307205,773529912,1294757372,1396182291,1695183700,1986661051,2177026350,2456956037,2730485921,2820302411,3259730800,3345764771,3516065817,3600352804,4094571909,275423344,430227734,506948616,659060556,883997877,958139571,1322822218,1537002063,1747873779,1955562222,2024104815,2227730452,2361852424,2428436474,2756734187,3204031479,3329325298];
function sha(a){const bit=a.length*8,total=((a.length+72)>>6)<<6,b=new Uint8Array(total);b.set(a);b[a.length]=128;const v=new DataView(b.buffer);v.setUint32(total-4,bit>>>0,false);v.setUint32(total-8,Math.floor(bit/4294967296),false);let q=[1779033703,3144134277,1013904242,2773480762,1359893119,2600822924,528734635,1541459225],w=new Uint32Array(64);for(let o=0;o<total;o+=64){for(let i=0;i<16;i++)w[i]=v.getUint32(o+i*4,false);for(let i=16;i<64;i++){const x=w[i-15],y=w[i-2];w[i]=(w[i-16]+(rotr(x,7)^rotr(x,18)^(x>>>3))+w[i-7]+(rotr(y,17)^rotr(y,19)^(y>>>10)))>>>0;}let z=q.slice();for(let i=0;i<64;i++){const t1=(z[7]+(rotr(z[4],6)^rotr(z[4],11)^rotr(z[4],25))+((z[4]&z[5])^((~z[4])&z[6]))+K[i]+w[i])>>>0,t2=((rotr(z[0],2)^rotr(z[0],13)^rotr(z[0],22))+((z[0]&z[1])^(z[0]&z[2])^(z[1]&z[2])))>>>0;z=[(t1+t2)>>>0,z[0],z[1],z[2],(z[3]+t1)>>>0,z[4],z[5],z[6]];}for(let i=0;i<8;i++)q[i]=(q[i]+z[i])>>>0;}return q.map(x=>x.toString(16).padStart(8,"0")).join("");}
function ix(a,n){const o=[];for(let i=0;i+n.length<=a.length;i++){let q=true;for(let j=0;j<n.length;j++)if(a[i+j]!==n[j]){q=false;break;}if(q)o.push(i);}return o;}function mark(k,id,s,b){const w=b?"BEGIN":"END";if(s==="html")return E("<!-- BG-CANONICAL-"+w+" "+k+" "+id+" -->\n");if(s==="js")return E("// BG-CANONICAL-"+w+" "+k+" "+id+"\n");return E("# BG-CANONICAL-"+w+" "+k+" "+id+"\n");}
const S=[["matrix","MATRIX_ROWS","html",20318,"c2e399d701e96583c7ffa5d0e348dce1cae1c26d0dc05ba34f34c03d1c9459ec"],["template","T_OUTER","js",353,"8416931252c47e2ac10429e203887a5837b4f47d448a9a449793d20360cf76db"],["template","T_CONSTRUCT_10","sh",1623,"8a25bb3308c2c8cdf02cef8788070c271d139b8127ea0f8a235a98674d180fd2"],["template","T_READ_GATE","sh",198,"f126cde2a7b4596de583a7f43c4a8f72cdeb4b8a95921b4752e112bb0e641a6b"],["template","T_COPY_SELECTOR","sh",394,"0a8ee1a73b9d1b8d33b6c5bf7428546c0db169b912eff798d7d3f5d51f970653"],["template","T_INVOCATION_BATCH","sh",1286,"88cb673bfd5694458dfcbad8ed437847406172de12e044e948068bc217f2b253"],["template","T_AUDIT_BATCH","sh",491,"ecd60eebb766f0ec33f2de343ddfd4551817c47e0477742d85d5fd792152bd57"],["template","T_ARTIFACT_IDENTITIES","sh",356,"eb8498407a2bf2f7177365e8bff61944e2ef45550be2234bb399b42b32cf4fc5"],["template","T_MARKER_DERIVE","sh",245,"f7dfd0b7febf9c065c7404e21b523c591af71831f13da4e9e01ca806c090e201"],["template","T_MARKER_FINALIZE","sh",280,"0bb8edbedfdd3e7295fdf8a422204fb523df980181cc3d6e9f0ed14548c8a9bd"],["template","T_FINAL_CLOSURE","sh",128,"9699aa0bfb49fd45880bdf4cc5e069f052fb0fe017e4ee6049d07b0a57966af8"]];
const I=[["P002",183,"f3f07054713485485986b67af5f4ab819ff6f280fa2afddb1d42ac3071826411",85,"453cd42dcf47790fcba30180e7d9e1cb7c1a1997b07c064384b20a9bb067d902"],["P003",803,"40a7144e019b45af04e112d456a43f63e925992a3d93e93887498ff25c5d8131",705,"e0215d8cdf0a45aea24e0e8f54715159798c24baf782e3c39dd71923c4bbb192"],["P004",241,"17ec8b17eef2ac773d192b45b1deb8e2fe8bee6f8f5ed7975eb5291c448c9b97",141,"9339e311a57c9e07657f6bb0a2323723784819c418b4058aad6a58c0207eebaa"],["P005",3530,"e1828a654a4b8262dac83c9fc871df9b4b76bca65353bb90f08aece88261647d",3430,"057a68edb24f99f5c18001203d53846e4ecf0d6fa6dee81acc56c4cc0a1f976a"],["P006",247,"fd087cb63ce5fe9fbee17a4aff126ea4f3c7869f2336a9f4264d35272f79d245",146,"8d2b7f5092cec8a9bc38b41147e7b47ac3737083c188699bb61c6cb191a2eece"],["P007",260,"92042292dbe0662a61efda982251e888e44a1580a7b1bbbe1a16446d1a973aef",159,"a430068dfc6efbc1740507f8283e92df449fcc088a2896317c1ab385b038f1d5"],["P008",295,"27df9fd261ba0e2fe4b575398a709d9a0cb7145827bd72c819031034daee63e0",194,"e7455095df8f6242e7d0bcd1248ac54aa4505cde367bbf0dda6cdb4377453b56"],["P009",243,"1b97341986df8c9552fd93fa2d4c0a9dc535b89de4319f7b1bbed4bc0bd3ec76",142,"69ddc0b193f29573fb8464ba63f4118c0181834261fc567ab0323fec65b31d4b"],["P010",211,"78d15fedc6349ecac733d97869b00602b9e97ccaa6153d41b284682fa86ac55d",110,"83fa92142449e13e4741fbfbd50c597df34e165c475f8c8585f8faeb6670e027"],["P011",213,"07cf33df752f203187c469aeccbc7d20a904d8deae48fc70df001c0592d1c790",112,"3f07f6221fb676d267f137bb8a63309d780d03946ed928f7e26da27129c0aaea"],["P012",258,"8eb5c3ea80d081f21276a7073548e1044296d115c6a71b80095ac43be816fced",157,"2ec54f435d4c8f5fbbd635f36b382a170eaa56ef37e87c8f5062af16d0438bc3"],["P013",249,"12550a723800e9dc77f0615f749a777195ef62d8f44a2ee6e2a1f4f547b33770",148,"688ce553003e4634c2537c140fe1f118a361d58a92b44880069e3ea79c1bbb8c"],["P014",333,"ceda5b7e75492576596a93fb60aa8b813a22cab1785f25706e9e2dc80ed8a935",232,"068279f2354bc4738826a526450e99fccf4a9955c5aa4e23c95b8c1b2cb1820e"],["P015",518,"0519263f35aa760da0c50d6f5e7b8c0bd894886c718790739934f3797602f2c5",420,"e258aec554bc2567e07d0944d0cc9b55758bc47f25b326f17b64dc1d1f7fd8bb"]];for(const x of I){S.push(["template",x[0],"sh",x[1],x[2]]);S.push(["assertion",x[0],"sh",x[3],x[4]]);}const bodies={},ranges=[];for(const s of S){const a=mark(s[0],s[1],s[2],true),b=mark(s[0],s[1],s[2],false),ai=ix(d,a),bi=ix(d,b);if(ai.length!==1||bi.length!==1||bi[0]<=ai[0]+a.length)throw new Error("BG_C_DELIM_"+s[1]);const z=d.slice(ai[0]+a.length,bi[0]);if(z.length!==s[3]||z[z.length-1]!==10||sha(z)!==s[4])throw new Error("BG_C_ID_"+s[1]);bodies[s[0]+":"+s[1]]=z;ranges.push([ai[0],bi[0]+b.length]);}ranges.sort((a,b)=>a[0]-b[0]);for(let i=1;i<ranges.length;i++)if(ranges[i-1][1]>ranges[i][0])throw new Error("BG_C_NEST");
const P=[["T_OUTER","INNER_JS:17:29,PROCESS_ID:216:230,EXPECTED_OUTPUT_JS:265:287,PROCESS_ID:307:321"],["T_CONSTRUCT_10","ROOT:72:80,BOUNDARY_FILE_BYTES_JS:1072:1098,DERIVATION_FILE_BYTES_JS:1184:1212,PRECON_DERIVATION_BYTES_JS:1302:1332,PRECON_GATES_BYTES_JS:1434:1459"],["T_READ_GATE","ROOT:39:47,INPUT_BASENAME:96:114,LITERAL_ASSERTION:153:174,PROCESS_ID:180:194"],["T_COPY_SELECTOR","ROOT:39:47"],["T_INVOCATION_BATCH","ROOT:39:47"],["T_AUDIT_BATCH","ROOT:39:47,AUDIT_GATE_RESULTS_BYTES_JS:260:291,AUDIT_DISPOSITION_BYTES_JS:377:407"],["T_ARTIFACT_IDENTITIES","ROOT:39:47,ARTIFACT_IDENTITIES_BYTES_JS:181:213"],["T_MARKER_DERIVE","ROOT:39:47,MARKER_BYTES_JS:163:182,MARKER_SHA256:210:227"],["T_MARKER_FINALIZE","ROOT:72:80,MARKER_BYTES_JS:217:236"],["T_FINAL_CLOSURE","ROOT:39:47,LITERAL_ASSERTION:83:104,PROCESS_ID:110:124"],["P002","ROOT:39:47"],["P003","ROOT:39:47,SLICE:168:177,HEAD:254:262,PARENT:280:290,TREE:306:314,CHANGED_PATH:338:354,INBOX_SHA256:376:392"],["P004","ROOT:39:47"],["P005","ROOT:39:47,SLICE:484:493,HEAD:900:908,PARENT:1094:1104,TREE:1288:1296,CHANGED_PATH:1466:1482,INBOX_SHA256:1677:1693"],["P006","ROOT:39:47"],["P007","ROOT:39:47"],["P008","ROOT:39:47"],["P009","ROOT:39:47"],["P010","ROOT:39:47"],["P011","ROOT:39:47"],["P012","ROOT:39:47"],["P013","ROOT:39:47"],["P014","ROOT:39:47"],["P015","ROOT:39:47"]];function toks(b){const o=[];for(let i=0;i+1<b.length;){if(b[i]===64&&b[i+1]===64){let j=i+2;while(j+1<b.length&&!(b[j]===64&&b[j+1]===64))j++;if(j+1>=b.length)throw new Error("BG_C_TOKEN");let n="";for(let k=i+2;k<j;k++){const x=b[k];if(!((x>=65&&x<=90)||(x>=48&&x<=57)||x===95))throw new Error("BG_C_TOKEN");n+=String.fromCharCode(x);}o.push(n+":"+i+":"+(j+2));i=j+2;}else i++;}return o.join(",");}for(const p of P)if(toks(bodies["template:"+p[0]])!==p[1])throw new Error("BG_C_SPAN_"+p[0]);
const str=(()=>{let u=[];for(const x of d)u.push(x);return String.fromCharCode.apply(null,u.slice(0,0));})();if(ix(d,E("### 6.1 Complete P-ID/input/assertion-requirement matrix\n")).length!==1||ix(d,E("+### 6.1 Complete P-ID/input/assertion-requirement matrix\n")).length!==0)throw new Error("BG_C_HEAD");text("BG_STATIC_CLOSURE_OK\n");
```


## 8. Future materialization boundary

The templates are invariant source authorities but intentionally retain typed
placeholders. No materialized byte count, SHA-256, or execution readiness is
claimed. A separately reviewed future package must contain, before execution:

1. exact template bytes, byte count, and SHA-256;
2. a per-process manifest listing every placeholder occurrence and byte offset;
3. canonical values and validation results for all typed fields;
4. materialized inner bytes, byte count, and SHA-256;
5. raw reverse-substitution equality to the invariant inner template;
6. ordinary-string outer bytes, byte count, and SHA-256;
7. decoded outer-command raw equality to the inner bytes;
8. exact expected stdout and numeric-status authority;
9. an independently reviewed producer/consumer and allowed-write record.

This is one blocking materialization boundary. It requires a new non-merge
operating commit and path-naming directive. Any ambiguity, unknown placeholder,
missing/duplicate occurrence, invalid value, altered invariant byte, or hash
mismatch stops before continuation creation. Tables may validate source but may
not generate or execute commands.

## 9. Marker authority

The marker template has exactly 16 LF-terminated lines, in this order:

```text
audit_scope=@@SLICE@@-evidence-design-only
enumeration_schema_environment_closure=passed
environment_definitions=12
environment_policy_rows=77
orchestration_instances=54
atomic_rows=128
resolved_audit_rows=69
unresolved_blocking_rows=59
conflict_set=C01,C02,C03,C04,C05,C06,C07,C08
dependency_steps=12
implementation_ready=false
execution_authority=none
production_AWK=unauthorized
D02=unauthorized
ratchet=131-unchanged
completion_write=final
```

Only `@@SLICE@@` is operating-bound. P136 must prove exact bytes, 16-line
schema, and hash while marker path remains absent/non-symlink. P137 is the sole
write. No completion claim is valid until P001-P136 have all passed.

## 10. Reads, writes, checkpoints, and failure stops

P001 reads only AY and writes the first ten target files. P016 and P102 read
only named AV files and write their batches. P118 and P123 write only their
literal named outputs. P137 writes only `AUDIT_COMPLETE`. All other processes
are read-only. No post-preconstruction process reads registration metadata or
enters a registered worktree directory.

Every process has exact sole output `Pnnn_OK` plus LF and numeric status 0.
Every process permits exactly one nested invocation. The complete source and
hashes of its inner and ordinary-string outer wrapper must be frozen before
invocation. A tool-layer exception, missing/multiple invocation, nonzero or
absent status, extra output, count/schema/order/mode/hash mismatch, unexpected
path, or identity drift is terminal. After first failure: no inspection,
diagnosis, retry, repair, cleanup, regeneration, normalization, mode change,
fix-forward, or later command.

## 11. Predeclared static checks

These are the complete source authority for the only post-draft checks allowed
in INBOX-206BB. They read only this result and Git metadata and do not invoke a
wrapper template:

The P002-P015 streamed source-identity and token-offset command is:

```sh
set -euo pipefail
DOC=/home/oleg/prog/z_llvm/docs/evidence/inbox206bb_phase3_wrapper_package_specification.md
for n in $(seq 2 15); do
  id=$(printf 'P%03d' "$n")
  extract() { /usr/bin/perl -0777 -ne 'BEGIN{$id=shift @ARGV} if(/#### \Q$id\E\b.*?```sh\n(.*?)```/s){print $1; $ok=1} END{$ok or exit 1}' "$id" "$DOC"; }
  bytes=$(extract | wc -c)
  sha=$(extract | sha256sum | cut -d ' ' -f1)
  tokens=$(extract | /usr/bin/perl -0777 -ne 'while(/@@[A-Z0-9_]+@@/g){push @o,$&.":".$-[0]."-".$+[0]} END{print join(",",@o)}')
  printf '%s\t%s\t%s\t%s\n' "$id" "$bytes" "$sha" "$tokens"
  extract | bash -n
done
```

The complete code-template placeholder inventory command is:

```sh
set -euo pipefail
DOC=/home/oleg/prog/z_llvm/docs/evidence/inbox206bb_phase3_wrapper_package_specification.md
/usr/bin/perl -0777 -ne 'while(/^(#{3,4}) ([^\n]+)\n(?:(?!^#{3,4} ).)*?```(?:sh|javascript)\n(.*?)```/msg){$name=$2;$body=$3;@o=();while($body=~/@@[A-Z0-9_]+@@/g){push @o,$&.":".$-[0]."-".$+[0]} print $name,"\t",scalar(@o),"\t",join(",",@o),"\n"}' "$DOC"
rg -o '@@[A-Z0-9_]+@@' "$DOC" | LC_ALL=C sort | uniq -c
```

The P002-P015 literal assertion-block identity command is:

```sh
set -euo pipefail
DOC=/home/oleg/prog/z_llvm/docs/evidence/inbox206bb_phase3_wrapper_package_specification.md
for n in $(seq 2 15); do
  id=$(printf 'P%03d' "$n")
  inner() { /usr/bin/perl -0777 -ne 'BEGIN{$id=shift @ARGV} if(/#### \Q$id\E\b.*?```sh\n(.*?)```/s){print $1; $ok=1} END{$ok or exit 1}' "$id" "$DOC"; }
  assertion() { inner | /usr/bin/perl -0777 -ne 'if(/(\[ -f "\$INPUT" \] && \[ ! -L "\$INPUT" \]\n.*?)(?=echo P\d{3}_OK\n)/s){print $1; $ok=1} END{$ok or exit 1}'; }
  printf '%s\t%s\t%s\n' "$id" "$(assertion | wc -c)" "$(assertion | sha256sum | cut -d ' ' -f1)"
done
```

```sh
set -euo pipefail
ROOT=/home/oleg/prog/z_llvm
DOC=$ROOT/docs/evidence/inbox206bb_phase3_wrapper_package_specification.md
git -C "$ROOT" diff --check -- "$DOC"
[ "$(git -C "$ROOT" status --porcelain=v1 --untracked-files=all)" = '?? docs/evidence/inbox206bb_phase3_wrapper_package_specification.md' ]
[ "$(grep -c '^package_kind=inert_template_specification$' "$DOC")" -eq 2 ]
[ "$(grep -c '^package_status=incomplete$' "$DOC")" -eq 2 ]
[ "$(grep -c '^implementation_ready=false$' "$DOC")" -eq 3 ]
[ "$(grep -c '^execution_authority=none$' "$DOC")" -eq 3 ]
[ "$(grep -c '^D01=unaccepted$' "$DOC")" -eq 2 ]
[ "$(stat -c '%a' "$DOC")" = 644 ]
[ "$(sed -n '/^### 6\.1 /,/^## 7\./p' "$DOC" | grep -c '^| P[0-9][0-9][0-9] |')" -eq 140 ]
grep -q -F 'P035 ET01-count' "$DOC"
grep -q -F 'P082 ET12-unique' "$DOC"
grep -q -F 'P140' "$DOC"
grep -q -F 'identity_independent_wrapper_count=0' "$DOC"
grep -q -F 'materialized_wrapper_hashes_claimed=false' "$DOC"
grep -q -F 'exactly 16 LF-terminated lines' "$DOC"
for n in $(seq 2 15); do
  id=$(printf 'P%03d' "$n")
  block=$(/usr/bin/perl -0777 -ne 'BEGIN{$id=shift @ARGV} if(/#### \Q$id\E\b.*?```sh\n(.*?)```/s){print $1; $ok=1} END{$ok or exit 1}' "$id" "$DOC")
  ! printf '%s' "$block" | grep -q -F '@@LITERAL_ASSERTION@@'
done
actual_tokens=$(rg -o '@@[A-Z0-9_]+@@' "$DOC" | LC_ALL=C sort -u)
expected_tokens=$(cat <<'TOKENS'
@@ARTIFACT_IDENTITIES_BYTES_JS@@
@@AUDIT_DISPOSITION_BYTES_JS@@
@@AUDIT_GATE_RESULTS_BYTES_JS@@
@@BOUNDARY_FILE_BYTES_JS@@
@@CHANGED_PATH@@
@@DERIVATION_FILE_BYTES_JS@@
@@EXPECTED_OUTPUT_JS@@
@@HEAD@@
@@INBOX_SHA256@@
@@INNER_JS@@
@@INPUT_BASENAME@@
@@LITERAL_ASSERTION@@
@@LITERAL_FILE_BYTES_JS@@
@@MARKER_BYTES_JS@@
@@MARKER_SHA256@@
@@PARENT@@
@@PRECON_DERIVATION_BYTES_JS@@
@@PRECON_GATES_BYTES_JS@@
@@PROCESS_ID@@
@@ROOT@@
@@SLICE@@
@@TREE@@
TOKENS
)
[ "$actual_tokens" = "$expected_tokens" ]
```

Before commit, the only tracked change is this document and `git diff --check`
passes. The commit is non-merge and changes only this file. After commit, main
and control are clean.

## 12. Incomplete disposition

This retained draft does not close the wrapper package. BC freezes only the
P002-P015 literal assertion/inner-template family. P016-P140 remain explicit
requirements and blockers. It does not resolve C01-C08, implement D02-D07,
authorize D01/D02, create a marker, execute a wrapper, validate a candidate,
or grant production credit.

```text
package_kind=inert_template_specification
package_status=incomplete
implementation_ready=false
execution_authority=none
D01=unaccepted
ratchet=131
registered_worktree_directory_access=none
continuation_root_created=false
wrapper_execution=false
```
