# INBOX-192 calls artifact durability audit

Status: evidence and design audit only. No artifact store, object, archive,
snapshot, manifest implementation, resolver, publisher, compatibility copy, or
pin was created. No current artifact, path, mode, pin, contract, source, tool,
protocol, identity, calls sequence, checkpoint, or ratchet was changed.

## 1. Scope and starting boundary

The read-only audit started from clean tracked operating commit
`bce22f9e503347eac14425215f80c27eb959db7a`, immediately above accepted
INBOX-191 commit `b510d277f0e4dcd86a9a362030549af498edea52`.
The accepted validation contract and complete future streams remain:

```text
contract_sha256=448482a91a47f00cfd0c0e89d73c5c7332a49beb21906e529914913491f383ba
canonical_stream_sha256=9fecf6990636f2bf4b7a325e951260a4ce7ee34964aedd739d2f6aa3a7e53a18
coverage_stream_sha256=e8a1871bf46f50ef0533062a9af068724a56dddc71d433b5c4514fb8c2d70b2e
source_commit=43de59b06ca3a687368bfaf0595c5759c8ab3a57
source_tree=d56a8d1aad6c8c80b9106fa3ee9bf8b10630fc2f
production_tools_build_diff_from_source_commit=empty
ratchet=131
```

The other frozen boundary checks were exact:

| Surface | Observed identity |
|---|---|
| adopted compiler-rt v1 input | mode `0444`; 1,897,410 bytes; SHA-256 `9b8d6993d8378bc3df5c559d5492d311bb2395024097dd42c8905647947b5ae1` |
| adoption manifest | mode `0444`; 4,394 bytes; SHA-256 `500e73c8433aa73159adfba5de8a6708ae4030140b97b823ef895caa1528f2bf` |
| reproduction final manifest | mode `0664`; 458,294 bytes; SHA-256 `885008980c8a272e82d06cf89b81652ab5a9669e89364b01d7b9e2761135ff1e` |
| validation bundle manifest | mode `0444`; 2,519 bytes; SHA-256 `0576d5803400ea9575d65fc501b87d514c97e806540be29018fb5192bd68e7f0` |
| aggregate coverage patch | mode `0444`; 41,140 bytes; SHA-256 `7508d1d8f74b7e9b97ae5722a0822a86c8d2079779a25cd37559ce5bc651036f` |
| retention pins | mode `0664`; 3,051 bytes; SHA-256 `1ef9803cab9c4f7cd7fb3a2fa352844457f0efb655b5b8ced51d7232434888d3` |
| watcher | HEAD/index/worktree Git blob `b64131cf60dd0ef638e815cd33db9ae8595a72cf` |
| stash | `stash@{0}` object `7985c6d01040a6e47e4ce5b918866d0e89517ac7` |
| pinned Zig source | commit `bdee02bc0c7f227c0f11bc9a449df673fe803540`; tree `aa032b2b82a48a4684657f909e6e270a6c925e33` |
| pinned stage4 | mode `0775`; 530,327,885 bytes; SHA-256 `dcea3478273d7ffe3895709c8eed4ccc0724548869cdb86183fc7356164410b7` |
| v2 detached source | clean, detached commit `43de59b06ca3a687368bfaf0595c5759c8ab3a57`; tree `d56a8d1aad6c8c80b9106fa3ee9bf8b10630fc2f` |
| future v3 namespace | root absent; external preflight/driver prefixes have zero files |

Validation-v1 and validation-v2 remain exhausted immutable evidence.
Validation-v3 remains blocked and unexecuted. The mandatory post-calls
checkpoint remains future-only.

## 2. Audit identity convention

No manifest file was generated. To give bounded directories exact identities
without materializing anything, this audit streamed a deterministic observation
record into SHA-256:

```text
regular: F<TAB>relative-path<TAB>bytes<TAB>mode<TAB>sha256<LF>
symlink: L<TAB>relative-path<TAB>mode<TAB>link-target<LF>
order:   LC_ALL=C bytewise ascending relative-path
```

The selected roots contain no symlink or other special-file rows. Directory
counts include each bounded root directory. A “manifest SHA-256” below is the
hash of that streamed observation, not a proposed store manifest and not an
authority. Virtual groups use the same regular-file record with the displayed
full current path.

The four and only four proposed retention classes are:

1. `canonical-input`: bytes that a future authorized process must consume
   exactly;
2. `irreplaceable-acceptance-evidence`: exact commands, outputs, samples,
   comparisons, or stopped-state records whose evidentiary value cannot be
   recreated by rerunning;
3. `reproducible-cache`: derived bytes that may be recreated only from a
   complete, already retained deterministic recipe and inputs;
4. `ephemeral-scratch`: non-authoritative working state that may be recreated
   and carries no acceptance claim.

Mixed physical roots are split into logical groups where necessary. A bounded
root that contains irreplaceable records is conservatively assigned that class
as a whole; this avoids silently downgrading evidence merely because it also
contains reproducible caches.

## 3. Current calls-critical inventory

### 3.1 Canonical accepted cohort

| Current dependency | Exact state | Authority / consumers / provenance | Pin and reconstruction | Proposed authority |
|---|---|---|---|---|
| `tmp/inbox63_accepted_cohort.ll` | regular; mode `0664`; 7,215,373 bytes; SHA-256 `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4` | Current authority is this sole `tmp/` file. It is the 285-row accepted-cohort input used by object, owner, frontier, and per-function identity gates. INBOX-182/183/184 identify it as AC285 and explicitly reject it as a substitute for the lost performance input. | No live pin. No complete deterministic creation chain is retained. Loss blocks fresh exact accepted-cohort object/owner work and cannot be repaired by renaming another corpus. | logical ID `calls/input/accepted-cohort-ac285/v1`; primary group `calls-inputs`; snapshot `snapshot/calls-inputs/v1`; class `canonical-input` |

Failure consequence: this is the clearest unpinned sole-authority gap in the
current calls sequence.

### 3.2 Dormant calls and isolation evidence

Every row is unpinned. Exact reruns would not reproduce timestamps, process
state, raw logs, or the reviewed stop/acceptance history, so the exact record
has no reconstruction procedure. Source and commands may be used only as
provenance after separate authorization.

| Current bounded root | Exact observed state | Provenance and consumers | Proposed logical ID / primary / snapshot / class |
|---|---|---|---|
| `tmp/inbox174a_o2_call_rollback` | mode `0775`; 9 files, 2 directories, 303,242 bytes; manifest `38b665951fe8b49d7c68f0d136035378552aede3b1d1351f8b4a5f0fdb3e2e02` | INBOX-174a sole-rollback proof; later INBOX-178/178b model and guard review | `calls/evidence/174a-rollback/v1`; `calls-evidence`; `snapshot/calls-evidence-174a/v1`; `irreplaceable-acceptance-evidence` |
| `tmp/inbox178_o2_call_final_use` | mode `0775`; 15 files, 2 directories, 15,455,114 bytes; manifest `f1339539156f68558b7afeda9ff8dafb01dc1b170b000cbaacd1606cfeaa7c98` | INBOX-178 semantic implementation and 57-row matrix provenance | `calls/evidence/178-final-use/v1`; `calls-evidence`; `snapshot/calls-evidence-178/v1`; `irreplaceable-acceptance-evidence` |
| `tmp/inbox178a_o2_call_final_use_proof` | mode `0775`; 5 files, 2 directories, 49,446 bytes; manifest `3e1be38c389b02c2dfd1c3396fbbf7ee159841c282518a828db70c4a8564f0f3` | INBOX-178a proof completion and retained exploratory provenance | `calls/evidence/178a-proof/v1`; `calls-evidence`; `snapshot/calls-evidence-178a/v1`; `irreplaceable-acceptance-evidence` |
| `tmp/inbox178b_o2_call_alias_remediation` | mode `0775`; 15 files, 2 directories, 547,280 bytes; manifest `8041ed75201b7f74efd6e92b4beafe2138952e887a1ef93529fe778c2039a1e2` | Accepted call-local alias remediation; feeds the accepted dormant calls baseline | `calls/evidence/178b-alias/v1`; `calls-evidence`; `snapshot/calls-evidence-178b/v1`; `irreplaceable-acceptance-evidence` |
| `tmp/inbox179_o2_ordinary_call_reisolation` | mode `0775`; 36 files, 11 directories, 192,606,711 bytes; manifest `3535ad70153c4f338edd62f71c1a8a33e9221bb5c712027d3e15d45ae16ba00e` | Accepted ordinary direct-call isolated object/owner/per-function, unit, guard, canary, and ABI evidence | `calls/evidence/179-ordinary-isolation/v1`; `calls-evidence`; `snapshot/calls-evidence-179/v1`; `irreplaceable-acceptance-evidence` |
| `tmp/inbox180_o2_intbytesize_reisolation` | mode `0775`; 33 files, 11 directories, 192,489,412 bytes; manifest `c7e32f2b4c05d1a67486eddda120d2fdca9b3e886fdc9b080cab9c2f96702719` | Preserved first intByteSize compliant-stop attempt; required provenance for INBOX-180a | `calls/evidence/180-intbytesize-stop/v1`; `calls-evidence`; `snapshot/calls-evidence-180/v1`; `irreplaceable-acceptance-evidence` |
| `tmp/inbox180a_o2_intbytesize_bypass_transition_reisolation` | mode `0775`; 40 files, 11 directories, 192,521,996 bytes; manifest `e3c4cac230defc8371048712e188519b0f596c1f86bceb9018ec1f670b5d9fd7` | Accepted intByteSize isolated evidence, including the reviewed temporary guard overlay | `calls/evidence/180a-intbytesize-isolation/v1`; `calls-evidence`; `snapshot/calls-evidence-180a/v1`; `irreplaceable-acceptance-evidence` |
| `tmp/inbox181_o2_ordinary_intbytesize_aggregate_reisolation` | mode `0775`; 40 files, 11 directories, 192,559,904 bytes; manifest `a9d250f1e7a99d699976cf61883c96c5e70ef9ab803802fff26dbde5a9f8e55b` | Accepted two-family aggregate isolation and exact combined temporary-guard proof; future combined wiring review | `calls/evidence/181-aggregate-isolation/v1`; `calls-evidence`; `snapshot/calls-evidence-181/v1`; `irreplaceable-acceptance-evidence` |

Subtotal: 193 regular files, 52 directories, 786,533,105 bytes. Loss of any
row erases accepted proof or the reviewed failure chain; it does not authorize a
rerun.

### 3.3 Compiler-rt v1 reproduction

The top-level live pin covers `tmp/inbox184_o2_compiler_rt_v1`, but a live pin
only protects cleanup policy; it is not a second copy.

| Current bounded group | Exact observed state | Provenance, reconstruction, and consequence | Proposed authority |
|---|---|---|---|
| `materialize/gen-1` | 827 files, 14 directories, 57,780,053 bytes; manifest `7049d4fa5785d59a56c4daad1809e1dae597cfb4efaca923dd25f994060d5c98` | INBOX-185 generation 1. Output is 1,897,410 bytes, mode `0664`, SHA-256 `9b8d6993…`; exact caches/logs are evidence. The frozen INBOX-184/185 procedure can reproduce the raw module only under later authority, not the attempt record. | `calls/reproduction/compiler-rt-v1/gen-1`; primary `compiler-rt-v1-reproduction`; snapshot `snapshot/compiler-rt-v1-reproduction/v1`; `irreplaceable-acceptance-evidence` |
| `materialize/gen-2` | 827 files, 14 directories, 57,780,053 bytes; manifest `3962a636f4ea37d5778cc5fd66c6c22d14083c787a5f4732f66de7412e51d12b` | INBOX-185 generation 2; same raw-module bytes and SHA, distinct attempt records | `calls/reproduction/compiler-rt-v1/gen-2`; same groups; `irreplaceable-acceptance-evidence` |
| `materialize/gen-3` | 827 files, 14 directories, 57,780,053 bytes; manifest `3fbba16333a5cee8032f6413fecc92475fdc41b638d26d840c4d99afa7616cc1` | INBOX-185 generation 3; same raw-module bytes and SHA, distinct attempt records | `calls/reproduction/compiler-rt-v1/gen-3`; same groups; `irreplaceable-acceptance-evidence` |
| `materialize/source` | 40 files, 1 directory, 2,178,252 bytes; manifest `2e0d120702b3faf6158f55bbadb2c786821225ab62831c7c35e7407e7aaae95c` | Frozen source/tool/environment identities and one-shot commands; required to establish provenance | `calls/reproduction/compiler-rt-v1/source-proof`; same groups; `irreplaceable-acceptance-evidence` |
| `materialize/comparison` | 23 files, 1 directory, 923,116 bytes; manifest `6c857a677772c3899be2267413e1df655064b69e4aa171653bdc91b377dc989a` | Pairwise equality, postflight, and retained-file manifests; exact final manifest SHA is `88500898…` | `calls/reproduction/compiler-rt-v1/comparison-proof`; same groups; `irreplaceable-acceptance-evidence` |

The exact top-level envelope is mode `0775`, 2,544 files, 46 directories,
176,441,527 bytes, manifest
`71f5ff1c9522eb434af8e385266b68afd084e3f1a30f233e527fedbeb1678709`.
The five component totals reconcile exactly to that envelope.

### 3.4 Adopted input, validation bundle, and exhausted v1/v2

The top-level live pin covers `tmp/o2_calls_perf`. Its exact envelope is mode
`0755`, 2,384 files, 124 directories, 38,281,361 bytes, manifest
`5fa94bf8ae0e8a2ce58cda31aa07274c02e027ddba21bc1737d5032774a964bc`.
The following disjoint logical groups reconcile exactly to it.

| Current bounded group | Exact observed state | Authority / consumers / reconstruction / consequence | Proposed authority |
|---|---|---|---|
| adopted core: `compiler_rt_v1.ll`, `adoption_manifest.tsv`, `adoption_final.sha256` | 3 files, 1,902,042 bytes; virtual manifest `a11d162243f0368afa4860ac836187771a80b11097d48a5076f5605e56e61c1a`; exact input and manifest identities are in section 1 | Sole canonical raw INPUT for the future v3 report phases. INBOX-185 gives a deterministic generation recipe and three equal sources; that procedure is reconstruction provenance, not permission to regenerate. Loss blocks v3. | `calls/input/compiler-rt-v1/raw/v1`; primary `calls-inputs`; snapshot `snapshot/calls-inputs/v1`; `canonical-input` |
| retention proof: eight `retention_report.*` files | 8 files, 14,688 bytes; virtual manifest `5138b9f1346d6a02bb5c5ed858a661cfa1f379676ee13198f001406ae9a2acbd` | INBOX-186 one-shot no-delete reporter proof; historical evidence only | `calls/evidence/compiler-rt-v1/retention-proof`; primary `compiler-rt-v1-validation-evidence`; snapshot `snapshot/compiler-rt-v1-validation-evidence/v1`; `irreplaceable-acceptance-evidence` |
| `inbox187_baseline_validation_contract_bundle` | mode `0555`; 15 files, 3 directories, 97,645 bytes; manifest `00490ee1d69aaed9654f5d68328caa8cd4d979f01d755d3a3c05f4d0189c2462` | Accepted future aggregate-consumer/observer/guard bundle. Consumers are future v3 coverage build/apply-check only. Git may contain source patches, but the sealed accepted bundle and its proof are the reviewed authority. | `calls/input/validation-v3/coverage-bundle/v1`; primary `calls-validation-inputs`; snapshot `snapshot/calls-validation-inputs/v1`; `canonical-input` |
| exhausted v1 preflight: eight `baseline_validation_v1.preflight.*` files | mixed exact member mode `0644`; 8 files, 7,929 bytes; virtual manifest `0c7f91efc3d1a1fae29f200076d83d2cb60b093a8d0d4f0180e3d35bb0873b8f` | INBOX-188 compliant stop. No retry or reuse. Loss erases why v1 was exhausted. | `calls/evidence/validation-v1-stop/v1`; primary `compiler-rt-v1-validation-evidence`; snapshot `snapshot/compiler-rt-v1-validation-evidence/v1`; `irreplaceable-acceptance-evidence` |
| exhausted v2 external preflight/driver records | 18 files, 16,005 bytes, mode `0444`; virtual manifest `de51eda971576c7dab38ac866e11c408b6c18555fd67f6d087fc945d111c8030` | INBOX-190 launcher/preflight record. No retry or reuse. | `calls/evidence/validation-v2-external-stop/v1`; same primary/snapshot; `irreplaceable-acceptance-evidence` |
| `baseline_validation_v2` | mode `0755`; 2,332 files, 119 directories, 36,243,052 bytes; manifest `cf8dde0ea07b95db623c136c981f1e725863db604616e225b48ea23f73dd0594` | Exhausted immutable v2 root. Its clean detached source is commit `43de59b0…`, tree `d56a8d1a…`; source-preflight failed before build. Exact source subtree: 2,315 files, 91 directories, 36,240,122 bytes, manifest `5c2ffa508a5b5aecd079a75307db5a42ac6b627aa7e6549d2f2eecfdec1ea1c9`. Git can recreate source content, but not the failed-attempt records or registered-root evidence. | `calls/evidence/validation-v2-stop/v1`; same primary/snapshot; `irreplaceable-acceptance-evidence` |

All expected v2 build, artifact, repetition, identity, coverage, restoration,
and read-only-retention outputs remain absent. Their absence is part of the
accepted stop ledger, not missing data to fill.

## 4. Accepted performance evidence

These are the surviving accepted performance roots. They are all unpinned and
all are currently sole path authorities. Each includes immutable A/B artifacts
and raw/derived timing evidence; exact samples and environmental observations
are not reconstructible. The tracked evidence summary provides provenance and
commands, but a rerun would be a new experiment rather than reconstruction.

| Current bounded root | Exact observed state | Proposed logical ID / primary / snapshot / class |
|---|---|---|
| `tmp/inbox116_icmp_scratch_perf` | mode `0775`; 4,998 files, 201 directories, 742,293,602 bytes; manifest `68d92ad153f88ef335d6cd14cd0f710927981ff3207c1068fddf2ca47e96f2c7` | `performance/accepted/inbox116`; `accepted-performance`; `snapshot/performance-inbox116/v1`; `irreplaceable-acceptance-evidence` |
| `tmp/inbox118_icmp_eq0_perf` | mode `0775`; 4,994 files, 201 directories, 742,614,741 bytes; manifest `4001a1e8032c2fa1b9313b380e0adae0c824e7d3d43c2c173b07393d28aede99` | `performance/accepted/inbox118`; same primary; `snapshot/performance-inbox118/v1`; same class |
| `tmp/inbox120_icmp_setcc_perf` | mode `0775`; 4,997 files, 201 directories, 743,033,240 bytes; manifest `7696a5f8f7366a3d845caddd29e80b8fe91181edf0023885a2965192b287750e` | `performance/accepted/inbox120`; same primary; `snapshot/performance-inbox120/v1`; same class |
| `tmp/inbox122_icmp_signbit_perf` | mode `0775`; 5,002 files, 201 directories, 743,649,247 bytes; manifest `08c36107c53d50f76e299f7209e666188a5c09d2ccdc60d756fa4ff1a6fac145` | `performance/accepted/inbox122`; same primary; `snapshot/performance-inbox122/v1`; same class |
| `tmp/inbox128_o2_r1/perf` | mode `0775`; 44 files, 6 directories, 182,489,168 bytes; manifest `c84272f8a81c0585309157953f695de822b70708f7e8e586581338ed3c85cceb` | `performance/accepted/inbox128-r1`; same primary; `snapshot/performance-inbox128/v1`; same class |
| `tmp/inbox133_cast_wiring/perf` | mode `0775`; 5,191 files, 207 directories, 744,167,240 bytes; manifest `ed27f4576659c13ba87fe6ec88046786f7cb37129fb1817b99550d3945a66377` | `performance/accepted/inbox133`; same primary; `snapshot/performance-inbox133/v1`; same class |
| `tmp/inbox152_o2_scalar_named_wiring/perf` | mode `0775`; 5,304 files, 208 directories, 807,737,661 bytes; manifest `e6766a943578e22e752ee661fe8c9b8a81556ee8581a4e324c8f1fb451027d4e` | `performance/accepted/inbox152`; same primary; `snapshot/performance-inbox152/v1`; same class |
| `tmp/inbox157_o2_scalar_named_wiring2/perf` | mode `0775`; 5,316 files, 208 directories, 844,567,907 bytes; manifest `2ceb579fe7510a6ed0dda0f5aded72cdc07610c2cf14715433ed6b0a8e5beaeb` | `performance/accepted/inbox157`; same primary; `snapshot/performance-inbox157/v1`; same class |
| `tmp/inbox160_o2_b07_wiring/perf` | mode `0775`; 5,322 files, 208 directories, 844,453,235 bytes; manifest `6530bbbd20d79a72210dd5d7dfe664df0c6ce72e6c74c262db94564dbc03a96b` | `performance/accepted/inbox160`; same primary; `snapshot/performance-inbox160/v1`; same class |
| `tmp/inbox166_o2_m64_wiring/perf` | mode `0775`; 5,344 files, 208 directories, 836,300,198 bytes; manifest `797e8f48b32c1edd039a48e7e238ba50513e60ca0b73b765de7400907c8ff3dc` | `performance/accepted/inbox166`; same primary; `snapshot/performance-inbox166/v1`; same class |
| `tmp/inbox172_o2_quotient_wiring/perf` | mode `0775`; 5,358 files, 208 directories, 833,211,354 bytes; manifest `b4a7e35e39ba1b8e546d3fef073b800b4a301fdfb36986eafd8a406345a7fcf1` | `performance/accepted/inbox172`; same primary; `snapshot/performance-inbox172/v1`; same class |

Subtotal: 51,870 files, 2,057 directories, 8,064,517,593 bytes.

Examples of the small decision records embedded in the five newest roots are
the paired-metrics SHA-256 values `47e2055e…` (INBOX-152), `2e709631…`
(157), `56c67ca4…` (160), `04fe50f4…` (166), and `4dc11268…` (172).
Those compact records are not substitutes for the immutable artifacts, raw
samples, worktree/source identities, and logs in their bounded snapshots.

### 4.1 Already absent accepted performance material

Tracked acceptance summaries refer to these roots, but they are absent now:

```text
tmp/inbox87_third_resume_perf
tmp/inbox92_second_resume2_perf
tmp/inbox95_b3b_perf
tmp/inbox96_b3c_perf
tmp/inbox100_memcpy_perf
tmp/inbox102_fixed_unary_perf
tmp/inbox106_ordinary_load_perf
tmp/inbox107_readonly_load_perf
tmp/inbox108_readonly_load_remeasure
tmp/inbox109_table_i16_perf
tmp/inbox126_o2_i_b3_perf
tmp/inbox143_o2_final_narrowed_wiring
tmp/inbox145_o2_checkpoint_slice1
tmp/inbox146_o2_checkpoint_slice2
```

Their summaries remain provenance, not byte recovery. In particular,
`tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll`, required SHA-256
`7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b`,
is absent after the exhaustive INBOX-182 repository-local no-candidate audit.
It has no proposed object or snapshot because no bytes are available. Logical
ID `performance/historical/lost-compiler-rt-frozen` must remain status
`absent-unrecoverable`; it cannot resolve to AC285, compiler-rt v1, or any
other candidate.

The historical absences demonstrate that tracked summaries and live-pin policy
are not durable byte retention.

## 5. Accepted Tier-3 evidence

| Current dependency | Exact observed state | Pin / provenance / consequence | Proposed authority |
|---|---|---|---|
| `tmp/inbox63_serial_tier3.log` | regular; mode `0664`; 501,030 bytes; SHA-256 `05076492c34230e1485dccbcdc79cf291c9154a6633717d48f9ebf22ef9c5b21` | unpinned; accepted INBOX-63 serial evidence; exact run cannot be recreated | `tier3/evidence/inbox63`; primary `tier3-evidence`; snapshot `snapshot/tier3-inbox63/v1`; `irreplaceable-acceptance-evidence` |
| `tmp/inbox66c_serial_tier3_bfb263d9_fresh.log` | regular; mode `0664`; 501,553 bytes; SHA-256 `61949b63b783b538accb4a564aaefca4a2c6c51abcdb2a663b7300c3eb82063e` | unpinned; accepted INBOX-66c serial evidence | `tier3/evidence/inbox66c`; same primary; `snapshot/tier3-inbox66c/v1`; same class |
| `tmp/inbox67_serial_tier3_b1b1d2fb.log` | regular; mode `0664`; 507,997 bytes; SHA-256 `3f80b4277a3394f6a645921e72d44573e61da51f24a857dfdc1ab27a2fa6b6c5` | unpinned; accepted tracked serial-runner evidence | `tier3/evidence/inbox67`; same primary; `snapshot/tier3-inbox67/v1`; same class |
| `tmp/inbox69_evidence_protected` | mode `0775`; 7 files, 1 directory, 531,774 bytes; manifest `25fec09cf32d49c8fa94aca7d81f3b1abed75f9e4e565636dce353a86d620931` | live-pinned. Contains accepted Tier-3 raw log SHA-256 `95014fff0902e59d7827521c85d7ef46449830c73d61c02a8f9a2e5b42bbd076` and focused equivalence streams. Exact run is not reconstructible. | `tier3/evidence/inbox69`; same primary; `snapshot/tier3-inbox69/v1`; same class |

Subtotal present: 10 files, 1 directory, 2,042,354 bytes.

The live-pinned path
`tmp/inbox80_evidence_protected/tier3_cdd95cb0.raw.log` is absent. Its pin row
records expected acceptance identity
`27b455d6f293ce93f85aebff3b6d818fe1e12f760fe8e1b306942e43138273ff`.
The INBOX-80 summary remains, but the accepted raw log is a lost
`irreplaceable-acceptance-evidence` object. The stale live pin must be preserved
until a later ruling; this audit neither removes nor repairs it.

## 6. Exact reconciliation and durability gaps

The non-overlapping present inventory above reconciles as follows:

| Group | Files | Bytes |
|---|---:|---:|
| accepted cohort | 1 | 7,215,373 |
| calls dormant/isolation evidence | 193 | 786,533,105 |
| compiler-rt reproduction | 2,544 | 176,441,527 |
| adopted input + validation bundle + v1/v2 evidence | 2,384 | 38,281,361 |
| surviving accepted performance evidence | 51,870 | 8,064,517,593 |
| surviving accepted Tier-3 evidence | 10 | 2,042,354 |
| **total** | **57,002** | **9,075,031,313** |

The bounded roots contain 2,280 directories and no symlink or special-file
entries. The total is 8.451782 GiB of regular-file content before
content-addressed deduplication.

Closed gap findings:

1. None of the 57,002 files has both a primary store object and a sealed
   snapshot. Every current path is therefore a single local path authority.
2. AC285, every calls proof root, every surviving performance root, and three
   of four present Tier-3 groups are unpinned.
3. The two compiler-rt roots and INBOX-69 are live-pinned, but all copies and
   pins are on the same filesystem. A pin controls cleanup, not durability.
4. Four equal compiler-rt raw modules exist, but the surrounding attempt
   records are distinct. Equality supplies reconstruction evidence for the raw
   input only; it does not duplicate every evidentiary constituent.
5. The INBOX-80 live pin names an absent file. Numerous accepted performance
   roots are also absent. No local retention design can retroactively restore
   those bytes.
6. Disk failure is explicitly outside the project guarantee. The proposed two
   logical copies protect against accidental path loss, stale compatibility
   copies, and partial publication on this disk; they are not
   hardware-independent redundancy.

## 7. Proposed local authority and resolution

The sole proposed authority is:

```text
/home/oleg/prog/z_llvm-artifacts
```

It does not exist at audit time and was not created.

Future resolution is closed:

1. If `ZLLVM_ARTIFACT_STORE` is set, require one absolute, normalized path.
   Reject empty, relative, `.`/`..`-containing, NUL/control-containing, or
   symlink-resolved ambiguity. It must name the one configured store.
2. Otherwise resolve the absolute Git common directory, not the current
   worktree’s `.git` indirection. For this repository it is
   `/home/oleg/prog/z_llvm/.git`; its main repository root is
   `/home/oleg/prog/z_llvm`.
3. Derive the sibling as
   `dirname(main-root) + "/" + basename(main-root) + "-artifacts"`, yielding
   `/home/oleg/prog/z_llvm-artifacts`.
4. A non-`.git` common directory, unresolved main root, cross-device alias, or
   mismatch between an explicit store and the configured authority fails
   closed. Detached worktrees therefore cannot select a different default.

Repository `tmp/` is compatibility scratch only. Existing bytes do not become
authoritative merely because their path matches a historical contract.

## 8. Versioned logical-ID manifest design

This section specifies a future format; it creates no manifest.

### 8.1 Safe encoding and closed rows

The proposed tracked index is a versioned TSV with first row:

```text
zllvm-artifact-manifest-v1
```

All keys use lowercase ASCII. Logical IDs match
`[a-z0-9][a-z0-9._/-]*`; relative keys match the same alphabet and must have
no empty, `.`, or `..` segment, no leading/trailing slash, and no segment over
255 bytes. Decode must reject tabs, CR, LF, NUL, backslash, percent escapes that
are not uppercase `%HH`, duplicate IDs, duplicate relative keys with unequal
identity, and unknown enum values. Human text is UTF-8 encoded bytewise with
TAB/CR/LF/NUL/`%` and non-safe bytes represented as uppercase `%HH`.
Decoding followed by canonical re-encoding must be byte-identical.

Closed row kinds are `object`, `logical-ref`, `snapshot`, and
`snapshot-member`. Closed statuses are `active`, `exhausted-evidence`,
`future-required`, `superseded`, and `absent-unrecoverable`. The retention
class field accepts only the four classes in section 2.

An `object` row contains:

```text
schema-version
logical-artifact-id
sha256
bytes
mode
media-type
provenance
deterministic-reconstruction
retention-class
status
relative-content-addressed-key
```

Object keys are exactly
`objects/sha256/<first-two-hex>/<remaining-62-hex>`. Objects are regular,
mode `0444`, and their key, content hash, byte count, and manifest row must
agree. Mode is also retained as logical metadata where a compatibility copy
requires a different reviewed mode.

A `logical-ref` binds one reviewed logical ID and optional compatibility path
to one object. It cannot override hash, bytes, or class. A changed object
requires a new logical ID/version or an explicitly reviewed superseding row.

### 8.2 Separate snapshot identities

A snapshot is not an alias for its primary objects. Its row contains its own
logical ID, compressed SHA-256, compressed bytes, mode `0444`, media type
`application/zstd+tar`, format `ustar+zstd-v1`, relative key
`snapshots/sha256/<first-two>/<remaining>.tar.zst`, constituent-manifest
SHA-256, recipe ID, status, and retention class.

Each `snapshot-member` maps one safe archive member path to an object logical
ID, object hash, bytes, and mode. Members are unique primary-object keys, so
identical content appears once even when several logical IDs refer to it.
The constituent manifest is sorted by archive member path and hashed
independently. The mapping is sufficient to reconstruct every logical ID and
compatibility path without consulting directory traversal state.

Primary object and sealed snapshot are the required two logical same-disk
copies. A snapshot is valid only if every member and the archive itself verify.
An invalid primary does not make an invalid or unavailable snapshot acceptable.

## 9. Deterministic sealed `tar.zst` recipe

Future implementation review should freeze recipe
`ustar-zstd-v1` to the locally observed tools:

```text
/usr/bin/tar: GNU tar 1.35
/usr/bin/zstd: Zstandard CLI 1.5.5
/usr/bin/sha256sum and /usr/bin/install: GNU coreutils 9.4
environment: env -i PATH=/usr/bin:/bin LC_ALL=C TZ=UTC SOURCE_DATE_EPOCH=0
```

The recipe is:

1. Resolve and verify every primary object using descriptor-relative,
   no-follow opens. Build the unique member list from the reviewed snapshot
   manifest only; never walk `tmp/` or discover members from a directory.
2. Sort the NUL-delimited object keys bytewise under `LC_ALL=C`. All object
   member paths fit ustar and are regular files.
3. Stream GNU tar with `--format=ustar`, `--sort=name`, `--mtime=@0`,
   `--owner=0`, `--group=0`, `--numeric-owner`, `--mode=0444`,
   `--no-acls`, `--no-xattrs`, `--no-selinux`, `--no-recursion`, and the
   exact NUL member list, from the store root. No directory entry, symlink,
   hardlink, device, FIFO, socket, sparse member, or PAX extension is allowed.
4. Pipe tar stdout directly, under `pipefail`, to
   `/usr/bin/zstd -T1 -19 --check --no-progress`. There is no intermediate
   uncompressed archive. Capture both producer statuses; either nonzero status
   rejects the snapshot.
5. Write compressed bytes to a unique same-filesystem incoming regular file,
   hash and size it, set mode `0444`, synchronize file and parent directory,
   and atomically publish to its content-addressed snapshot key. An existing
   unequal object is a collision and a hard failure.
6. Proof-read by streaming the sealed snapshot through zstd and tar listing
   before extraction; reject every non-regular or unsafe member and every
   unexpected member. Extract only into a fresh no-follow proof directory,
   verify every member hash/bytes/mode and the exact constituent set, then
   remove that proof directory only under a separately reviewed successful
   publisher lifecycle. Failed proof state is retained for diagnosis.

The archive contains primary object keys, not historical `tmp/` paths. The
logical-ID manifest supplies reconstruction and compatibility mappings.

## 10. Capacity design

The proposed store and repository are on the same ext4 filesystem. Audit-time
free space was 97,743,224,832 bytes; free inodes were 56,229,442. This is an
observation, not a reservation.

For the present 57,002-file scope, a conservative non-deduplicated ustar size
computed from each current file size is:

```text
logical_regular_bytes=9075031313
ustar_bytes=9119899136
ustar_overhead_bytes=44867823
snapshot_capacity_bound=2*ustar_bytes+1048576=18240846848
existing_validation_reserve=49112001332
manifest_and_metadata_bound=67108864
incoming_object_temp_upper_bound=9075031313
conservative_required_free=85570019670
audit_time_headroom=12173205162
```

The `2 * ustar + 1 MiB` snapshot bound deliberately does not assume compression
and is larger than the expected zstd output. Content-addressed deduplication
may reduce primary and snapshot bytes, but capacity approval must not depend on
that reduction.

Before any future publication, recompute on the actual target filesystem:

```text
required_free =
    existing_validation_reserve
  + all_new_unique_primary_bytes
  + largest_incoming_object_temporary
  + exact_conservative_snapshot_output_bound
  + bounded_manifest_and_journal_overhead
  + any separately authorized compatibility-copy peak
```

Require both free bytes and free inodes after accounting for all existing live
store objects. Refuse work if the filesystem, store identity, available space,
or reserve moves between preflight and publication. Do not migrate wholesale
`tmp/`; admit only reviewed bounded logical groups. Compatibility
materialization has its own capacity preflight and may not consume the
validation reserve.

## 11. Fail-closed publisher and compatibility resolver

This is design only.

### 11.1 Publication

The future publisher must:

- resolve manifest and object paths through directory descriptors;
- reject traversal, symlink components, non-regular sources or destinations,
  partial incoming files, unknown rows, duplicate/colliding unequal bytes,
  hash/size/mode mismatch, invalid snapshots, and insufficient capacity;
- copy into a unique `O_CREAT|O_EXCL` same-filesystem incoming path without
  following links;
- hash while copying, synchronize, read back, re-hash, set the final reviewed
  mode, synchronize again, then atomically rename and synchronize the parent;
- treat an existing content key as success only after full regular-file,
  hash, size, and mode verification; and
- publish the new manifest generation atomically only after both the primary
  object and snapshot proof succeed.

No transaction-owned, stack-backed, or borrowed path string may become durable
manifest storage.

### 11.2 `tmp/` compatibility copies

The future resolver takes a logical ID, never a caller-provided object path. It
selects the deterministic active manifest row, verifies the primary object and
the required snapshot, and then:

1. validates the reviewed compatibility path beneath the exact repository
   root with no symlink or traversal component;
2. if the destination exists, accepts it only when it is a regular file with
   the exact hash, bytes, and reviewed mode; unequal/stale content fails closed
   and is never silently used or overwritten;
3. otherwise creates a unique same-directory temporary regular file, streams
   and hashes the verified object, synchronizes it, applies the reviewed mode,
   reads it back, and atomically renames it without replacing an unexpected
   destination;
4. synchronizes the destination directory and verifies the published path
   again before returning it to a consumer.

Missing primary, unavailable/invalid snapshot, stale copy, generation mismatch,
or post-resolution mutation is an error. Resolution has no fallback to an
arbitrary existing `tmp/` file and no “closest hash” behavior.

## 12. Complete future-v3 path mapping

The accepted contract is unchanged. The following family map covers every
hard-coded producer/consumer path in its sections 7.2 and 7.3.

| Contract path family | Producer / consumer | Future logical authority and class | Compatibility rule |
|---|---|---|---|
| adopted `$INPUT` and accepted coverage `$BUNDLE` | immutable preflight; canonical/coverage reports and coverage build | existing `calls/input/compiler-rt-v1/raw/v1` and `calls/input/validation-v3/coverage-bundle/v1`; `canonical-input` | resolve and verify before root creation; historical paths may remain exact verified compatibility copies |
| `$PARENT/baseline_validation_v3.preflight.{command.txt,environment.txt,cwd.txt,start.utc,end.utc,stdout.raw,stderr.raw,status,records.tsv}` | sole immutable-input preflight record; review consumer | `calls/validation-v3/preflight/<name>`; snapshot `snapshot/calls-validation-v3-preflight/v1`; `irreplaceable-acceptance-evidence` | publish after the one attempt; external prefix paths are atomic compatibility copies |
| `$PARENT/baseline_validation_v3.driver.{command.txt,environment.txt,cwd.txt,start.utc,end.utc,stdout.raw,stderr.raw,status,records.tsv}` | sole driver bootstrap record; review | `calls/validation-v3/driver/<name>`; same snapshot; same class | same |
| `$ROOT/canonical/source` | worktree-add; source-preflight/build; later restoration proof | Git commit `43de59b0…` remains source authority; generated checkout is `reproducible-cache` | no wholesale source snapshot; recreate only from verified full commit under authorized contract |
| `$ROOT/canonical/build/{cache/**,prefix/**}` and repetition `{home,tmp}` | build/report working state | `calls/validation-v3/cache/...`; `reproducible-cache` for successful deterministic build products, otherwise `ephemeral-scratch` | compatibility-only; not required in the sealed acceptance snapshot unless an exact failure makes it evidentiary |
| `$ROOT/canonical/artifact/z_llvm` and `artifact.identity.tsv` | artifact install/identity; all report/object/owner producers | after successful validation, `calls/validation-v3/canonical-artifact`; `canonical-input` | verify object and snapshot before each consumer; atomic compatibility copy |
| all canonical named-step `status`, `records/*.{command,environment,cwd,start,end,stdout,stderr}`, and build raw/status records | each contract `run_step`; final evidence | `calls/validation-v3/canonical-record/<step>`; `irreplaceable-acceptance-evidence` | publish each closed step group after its sole producer; never synthesize a missing status |
| `repetition-N/report.*`, summaries, ordered/sorted failures, frontier and grouped frontier | report/parsers; identity/comparison | `calls/validation-v3/repetition-N/report-proof`; `irreplaceable-acceptance-evidence` | atomic copies only after the complete producer group verifies |
| `repetition-1/accepted.ll` plus extract/freeze/identity records | sole repetition-1 extract; all canonical and coverage object/owner consumers | `calls/validation-v3/canonical-accepted-ll`; `canonical-input` plus associated `irreplaceable-acceptance-evidence` records | publish once, mode `0444`, then all later phases resolve the same object identity |
| `repetition-N/accepted.o`, owner TSV, objdump/readelf/objcopy output, function manifests/files, per-function identities, owner ledger | canonical object/owner and inspection producers; comparisons/identity | `calls/validation-v3/repetition-N/successful-subset-proof`; `irreplaceable-acceptance-evidence` | one sealed repetition snapshot with exact finite function-member mapping |
| `$CANONICAL/comparisons/*`, identity TSV, repetition/final manifests | comparison, identity, finalizers; review and coverage identity checks | `calls/validation-v3/canonical-final`; `irreplaceable-acceptance-evidence`; the identity TSV is also a future validation input | publish only after all three repetitions agree |
| `$ROOT/coverage/source` and coverage build/cache/artifact | worktree creation, accepted bundle application, coverage build; off/on producers | source is Git-authoritative; build cache `reproducible-cache`; coverage artifact `canonical-input` for the two coverage phases only | separate from canonical artifact and excluded from performance |
| coverage directory-creation records and `$ROOT/coverage/reference/*` channel/accepted identity records | directory creation and before/after checks; review | `calls/validation-v3/coverage-reference`; `irreplaceable-acceptance-evidence` | publish as one closed reference group |
| `$OFF` report, parsed raw report, object/owner, inspections, functions, per-function, owner-ledger, records/status | observation-off sole producers; comparisons | `calls/validation-v3/coverage-off`; `irreplaceable-acceptance-evidence` | sealed off snapshot; channel paths must remain absent |
| `$ON/report.coverage.tsv`, `object.coverage.tsv`, `owner.coverage.tsv` | exactly one corresponding on producer; counter validators | `calls/validation-v3/coverage-on/channel/<kind>`; `irreplaceable-acceptance-evidence` | absent before producer; no cross-channel fallback |
| remaining `$ON` report/object/owner/inspection/function/ledger/counter validation records | on producers and validators; comparisons | `calls/validation-v3/coverage-on`; `irreplaceable-acceptance-evidence` | sealed on snapshot after exact channel and semantic equality checks |
| coverage `*.files.sha256`, `*.final.tsv`, and `final-manifests.sha256` | off/on/final finalizers; review | `calls/validation-v3/coverage-final`; `irreplaceable-acceptance-evidence` | final coverage snapshot and manifest generation |
| any unlisted future v3 output | no producer | none; invalid | fail closed; do not copy or add it implicitly |

The exact finite patterns remain those in accepted contract sections 7.2 and
7.3: `N` is 1, 2, or 3; function IDs come only from the corresponding sorted
function manifest; each `run_step`/`run_recorded` owns its unique command,
environment, cwd, timestamps, stdout, stderr, status, and records paths.
Canonical, observation-off, and observation-on roots remain disjoint.
Coverage creates no `accepted.ll`; it consumes the one canonical object.

The v3 root and prefixes are absent today. Their logical rows would initially
have `future-required` status and no object key. They become active only after
their sole contracted producer succeeds and a separately authorized publisher
verifies both local logical copies.

## 13. Ordered next sequence

The only safe sequence is:

1. Review and accept or amend this audit.
2. Separately authorize and implement a non-destructive local copy-and-verify
   store, manifest, primary-object publisher, deterministic snapshot publisher,
   and compatibility resolver.
3. Review the implementation and the exact retained identities. No current
   `tmp/` path is removed, replaced, or demoted during that step.
4. Separately amend and re-review the v3 contract so the durable logical
   manifest is authoritative and every hard-coded `tmp/` input/output is an
   atomic verified compatibility copy.
5. Only then consider authorizing one v3 execution.

Deletion, relocation, compatibility-path retirement, stale-pin removal, or
cleanup requires a later explicit ruling. Protocol adoption, calls production
wiring, correctness gates, performance, ratchet credit, and the post-calls
checkpoint remain outside INBOX-192.

```text
audit=COMPLETE_READ_ONLY
proposed_store=/home/oleg/prog/z_llvm-artifacts
store_created=false
primary_objects_created=0
snapshots_created=0
compatibility_copies_created=0
pins_changed=0
v3_execution=NOT_AUTHORIZED_OR_RUN
production=UNCHANGED_DORMANT
ratchet=131
next=STOP_FOR_WATCHER_REVIEWER_DURABILITY_DESIGN_REVIEW
```
