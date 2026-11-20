# INBOX-156 — B03–B07 re-isolation matrix

Status: evidence only. No production wiring, action/model amendment, guard
policy change, performance run, or Tier 3 run is included. The landed
direct-materialization ratchet remains **152**.

## Verdict

The individually accepted set is exactly **B03 + B04 + B05 + B06**.
B07 remains a wholesale residual.

| Family | Direct credit | Full unit | Focused canaries | Cohort/object/owner | Per-function result | Verdict |
|---|---:|---|---|---|---|---|
| B03 | 1 | 1353/1353 | 2/2, 35 cases | exact | 285 compared, 0 divergent, 0 missing | accepted |
| B04 | 1 | 1353/1353 | 2/2, 35 cases | exact | 285/0/0 | accepted |
| B05 | 1 | 1353/1353 | 2/2, 35 cases | exact | 285/0/0 | accepted |
| B06 | 1 | 1353/1353 | 2/2, 35 cases | exact | 285/0/0 | accepted |
| B07 | 8 | 1353/1353 | 2/2, 35 cases | divergent: 443/279/164; complete object/owner fail closed | six lost rows; all other functions exact under the six-stub comparison | retain wholesale |

The accepted-family aggregate B03+B04+B05+B06 passes 1353/1353 unit tests,
both focused canaries, the exact whole-cohort projections, and the 285/0/0
per-function comparison. No minimal interacting-subset isolation was
needed.

Reviewer-directed arithmetic:

```text
accepted direct credits = B03(1) + B04(1) + B05(1) + B06(1) = 4
retained direct credit = B07(8)
helper-collapse credit = 0
conditional later ratchet = 152 - 4 = 148
equivalent floor form = 140 + retained B07 credit(8) = 148
```

This is matrix arithmetic for a later reviewed wiring decision, not a
landed ratchet. This commit leaves the ratchet at 152.

## Frozen baseline

The accepted code baseline is commit
`3534551d7268b1d59a0f2ebd3ca566fa23944c12`, tree
`6743856de4e8041c2511a6b7a129ef31671e9fc5`. The matrix was executed from
authorization HEAD `298012bb3c8ec1c39eed73c2ae82f007821dbd15`, tree
`0d889c02289826c0472249fe9e0ad6a507249cfe`; the only tracked difference
from the accepted baseline is `docs/next_steps.md`. Production sources,
tools, and build roots are identical.

Baseline results:

```text
artifact=430fa414879303ed55967f2586961271bcae9cd8c7242cee8b3accc251e0c87f
report=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report_counts=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=167/17/101
per_function=285/0/0
per_function_file=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
```

Frozen inputs and implementation:

| Input | SHA-256 |
|---|---|
| `tmp/inbox63_accepted_cohort.ll` | `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4` |
| `tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll` | `7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b` |
| `tmp/inbox142_family_isolation/compare_elf_functions.zig` | `34b5d400b47a9e861e5f6e7082f54ad57d6bc9b3e5e772d60420074b4dd4ce8f` |
| `value_use/actions/scalar_named.zig` | `6de4086bb1285db52ebac352acb743e49a6778b2407def137ab71d56b9464416` |
| `value_use/model.zig` | `eb989e6cb6e8aa9645387751a1839ab751741f96484b6fc3f3cb6dd0d3fdb649` |
| `value_use/planning/lifetime_admission.zig` | `35bb4d9f12bd372063692aa9cb55333ce06b47b39d0964d13be7bd121e20b1b6` |
| baseline `composed_selector_scalar.zig` | `a57561870d8a17c3d56956c41225230ae976092223d4512934bef41243f7ce91` |
| baseline `source_guard/consumer_policy.zig` | `95a9a8b1956e0acd26d55e3980232f18d7755392021c4747c7b08057dee79bc6` |
| baseline `source_guard/consumer_policy_tests.zig` | `33f48de81b68aefee3c46b2063a8a265943372bb721a19924b7c5a54daf194a9` |

The forward-Q1, action, and model files were never edited during the
matrix.

## Temporary-build provenance

Each isolated source routes exactly one complete family through the
already-frozen `NamedScalarBinaryAction`; all other candidates and R03/R04
stay on their accepted legacy paths. B01 and I52B0 remain their already
landed production wiring. The aggregate routes only B03–B06.

The temporary consumer needed a narrowly marked procedural guard
exemption because accepted production policy correctly rejects premature
use of the dormant actions. The same exact guard and guard-test sources
were used by every temporary build:

```text
temporary_consumer_policy=6712917cede48f0b5f019c42b0a2850699d2133f1b772c6a4e4f865244d5f9a2
temporary_consumer_policy_tests=b9898741ecac7c8e4bde45148182bcfef2af938b24333eb085a1b6ecc2d8ea06
```

The exemption recognizes only the exact INBOX-156 matrix marker. It does
not change action/model behavior or family admission, and the complete
1353-test suite still runs for every build. The accepted guard sources
were restored before this evidence file was created.

| Build | Temporary patch | Consumer source | Frozen artifact |
|---|---|---|---|
| B03 | `8f3ea4d4f9b5d2819c22719f6f36582838f34244a4bf23a94ee11b6b475e4410` | `ee81dc023c866bedb60a8462adbb99b1c72e235ceec6829e8662b92a3935dff1` | `8ae7e5d1bf42aa9cd35b7ea9961747541ccdae46c8f3cdfa26201a7a10bc865b` |
| B04 | `29369bf1fc99b16babc6c230ec86bc7739e4c542d8a167e318a9c4a9d36384cd` | `4ed9b8007453e70d3f742b128e6e271ef024859bb83f4c427dae960505420e6f` | `c5e12d23221f547f0104d67859f046a682f02d58de1b897e578543d5b647194f` |
| B05 | `32478486cac08ef455ce195772806e973ec0b1bdec5263749b020afbe3823987` | `08425cd935d71b038ffe2608d71a2567724e6f49f453850d1145da821e4f7eb7` | `6f254309849a4264832b36f9d7c80d166219621ab0be7d11e3450022fa11c756` |
| B06 | `695cca3f8addd581b372bcf1004d8ad85abf5b5a70f5db29bb48d69261ea43ea` | `f3d84e0330f748c7584a10bbd92e3c6dc181ccd3edc88c8a73806e42e351f227` | `919e8906a2833b482cea17248132f73508e53ca8b6ab6eef70f3762ca8c819cb` |
| B07 | `65083d0333d7b3741cc730ec2be35f05718fafabf7a838d2282443c4edc8e680` | `b5ec74764c4f9d6d2e4879b170374a344e165ef28d1e8a223b229396d384ffa5` | `8713462b76de6821237a5b21d37d13530e4d91d48e6ec19cdcd597b78fd809a2` |
| B03+B04+B05+B06 | `febdfb1bc484dbd30702665290e1c653aaf702cbce96d9b359ab15123af22c53` | `7f0e0936bc40fa197a304360631b6628b3ec855e49c529e6501ca74d76674c61` | `c91d99a4a0a8cd6375a6a6a36f56f2f886ed339764d71fd1bb70004dd40ccc91` |

All retained procedural files are under
`tmp/inbox156_o2_reisolation_matrix/`. The sorted 116-file SHA-256
manifest is `tmp/inbox156_o2_reisolation_matrix/hashes.sha256`, SHA-256
`3f206b509a2dc8f32f9e8aab88fd5f5035c6574ec2b2bbf0e2b6b6571ba5d56e`.
Empty build logs have the canonical empty-file hash
`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.

## Exact command shapes

Each isolated source and the aggregate used:

```text
/home/oleg/bin/zig build

/home/oleg/bin/zig build test --summary all

/home/oleg/bin/zig build focused-codegen-canaries --summary all

LC_ALL=C <frozen-artifact> --emit=obj --generic-cfg-selector \
  --report-all-codegen-failures --target=x86_64-linux \
  --input-limit=67108864 \
  tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll

LC_ALL=C <frozen-artifact> --emit=obj --generic-cfg-selector \
  --target=x86_64-linux --input-limit=67108864 \
  tmp/inbox63_accepted_cohort.ll

LC_ALL=C <frozen-artifact> --emit=selection-owner-manifest \
  --generic-cfg-selector --target=x86_64-linux \
  --input-limit=67108864 tmp/inbox63_accepted_cohort.ll

/home/oleg/bin/zig run \
  tmp/inbox142_family_isolation/compare_elf_functions.zig -- \
  tmp/inbox156_o2_reisolation_matrix/results/baseline/accepted.o \
  <isolated-accepted-object>
```

The report command intentionally returns the established local-failure
status after recording all 443 rows. No performance or Tier-3 command was
run.

## Per-family evidence

Every focused-canary run passed `__multi3` (6 executable cases) and `fma`
(29 executable cases), total 2/2 canaries and 35 cases. Every retained
canary log has SHA-256
`d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6`.

### B03 — accepted

The aligned `mul-i32-preserve-order` production-path fixture passes.
Full unit is 1353/1353; log SHA-256
`52fa2f15ae65d15058947bbdc6813ad8d94b53f6ffdf34fc585790ad2bb53319`.
Report, object, and owner hashes are the frozen identities, and the
per-function result is 285/0/0.

### B04 — accepted

The aligned accumulator-lhs i32 shift, both variable-i16 shifts, and both
i32-ashr production-path forms pass. Full unit is 1353/1353; log SHA-256
`e2b3c85e59df40f3dbaccda389fd57b7078dc519fe1d34eaf35ccdc9b5da0582`.
Report, object, owner, and all per-function bytes are exact.

### B05 — accepted

The aligned `shl i56` and current-RHS exact-EI production paths pass.
Full unit is 1353/1353; log SHA-256
`2f81319541160e71aa8fd74ed5a2d8c23302e79e14f61c3fa44fed9fe81a1e65`.
Report, object, owner, and all per-function bytes are exact.

### B06 — accepted

The aligned exact-EI `or i55` production path passes. Full unit is
1353/1353; log SHA-256
`3203675ea117c025c46d470d6d7fbbd9690fd1775b14159fb1c5fdcd8ec2e681`.
Report, object, owner, and all per-function bytes are exact.

### B07 — retained wholesale

The aligned spill32-RHS unit path and all dormant forward-Q1 coverage pass;
full unit is 1353/1353 with log SHA-256
`a3c94643239cb5f23ad2bfa22a3a5119db3aaaf9e827f5a58c1bfa84eb81b0f4`.
The complete cohort nevertheless remains divergent:

```text
report=9e283eade6790443768b41e112c7c8f28993564d3df83fc5c5e5d1737a27ae72
report_counts=443/279/164
first_six_new_failures=unsupported_value/composed-block-unknown-rhs
```

The six formerly accepted rows are:

| Function | First semantic producer in the accepted IR |
|---|---|
| `compiler_rt.floatuneidf.__floatuneidf` | `%54 = and i32 %50, %53` |
| `compiler_rt.floatuneisf.__floatuneisf` | `%36 = or i26 %common.ret.op.i71, %35` |
| `compiler_rt.floatuneihf.__floatuneihf` | `%39 = or i13 %38, %29` |
| `compiler_rt.floateidf.__floateidf` | `%17 = sub i64 %.neg, %26` |
| `compiler_rt.floateisf.__floateisf` | `%17 = sub i64 %.neg, %26` |
| `compiler_rt.floateihf.__floateihf` | `%17 = sub i64 %.neg, %26` |

The first semantic divergence in each row is the named/named B07 RHS
admission at the listed producer, before an instruction can be emitted.
This is not downstream branch-offset movement. Complete object and owner
generation both fail closed at
`compiler_rt.floatuneidf.__floatuneidf`; both stderr files have SHA-256
`499bf7a7b6fe05147bcbedb3020c4084e9157f5f5d282d23a60645ca10158ec5`.
No empty/partial object or owner file is treated as an identity.

For the required surviving-function comparison, the Zig-only filter
`tmp/inbox151_o2_family_isolation/filter_failed_functions.zig`
(`bf3048be1b774909dadf750df2e2530f447824e67b87612c8eb40306b639f97a`)
replaced exactly those six definitions with `unreachable` stubs in the
common accepted input. The stubbed IR hash is
`aab55894392a18b43cd5a84ac0fad3feec2fd9e90001dafc5e00f1924f779ace`.
Baseline and B07 both produce object
`1c394b3fa27d86620f0bd57876e0632b09c01853935538c9195e29cc3555b7b8`;
the comparator reports 285/0/0 with file hash
`aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240`.
Thus all otherwise emitted functions are exact, while the six required
B07 rows are not restored. Per the matrix rule, B07 is retained wholesale
with zero accepted credit and no fix-forward.

## Accepted-family aggregate

The aggregate contains B03+B04+B05+B06, while B07 and R03/R04 remain
legacy. Full unit passes 1353/1353; log SHA-256
`95294b3a6651ce521834f16e409c1af7add534afa87f516a372d93f5f11da9a0`.
Focused canaries pass 2/2 and 35 cases. Its identities are:

```text
report=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
object=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=167/17/101
per_function=285/0/0
```

Because the complete accepted-family aggregate is exact, no interacting
subset exists to isolate.

## Closeout

All temporary consumer and guard edits were restored. The restored source
hashes equal the frozen baseline hashes above, and the tracked worktree
was clean before adding this document. `stash@{0}` remains:

```text
On x86_64-codegen-expanded-frontier:
INBOX-93 preserve B2B wiring plus five diagnosis tests
```

All preserved patches remain untouched. No production wiring, multiply
work, performance run, or Tier 3 was performed.
