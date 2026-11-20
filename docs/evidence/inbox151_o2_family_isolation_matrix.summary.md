# INBOX-151 O2 scalar Slice 3 family-isolation matrix

Status: Stage 1 evidence only. No production wiring is landed by this
commit. The direct-materialization ratchet remains **154**. No performance
run and no Tier 3 run were performed.

## Verdict

The individually accepted set is exactly **B01 + I52B0**.

| Family | Direct credit | Full unit | Cohort/object/owner | Per-function result | Stage-1 disposition |
|---|---:|---|---|---|---|
| B01 | 1 | 1339/1339 | exact | 285 compared, 0 divergent, 0 missing | accepted for a later wiring review |
| B03 | 1 | 1338/1339 | exact | 285/0/0 | retain wholesale |
| B04 | 1 | 1336/1339 | exact | 285/0/0 | retain wholesale |
| B05 | 1 | 1337/1339 | exact | 285/0/0 | retain wholesale |
| B06 | 1 | 1338/1339 | exact | 285/0/0 | retain wholesale |
| B07 | 8 | 1338/1339 | divergent: 443/279/164; object and owner cannot be produced | surviving-function comparison described below | retain wholesale |
| I52B0 | 1 | 1339/1339 | exact | 285/0/0 | accepted for a later wiring review |

The aggregate containing only B01 and I52B0 is exact and passes 1339/1339
unit tests plus both focused canaries. Therefore no interacting-subset
minimization was required.

The Reviewer-corrected arithmetic resulting from this matrix is:

```text
accepted direct credits = B01(1) + I52B0(1) = 2
helper-collapse credit = 0
conditional later ratchet = 154 - 2 - 0 = 152
```

This is arithmetic for review, not a wiring claim or landed target. This
evidence commit leaves the ratchet at 154.

## Frozen baseline and inputs

The accepted dormant semantic baseline is commit
`0661c8cdea9760979964f90619718f178bece52b`, tree
`9183d42ec62ffd25ffc86107906d8bf32d0678bf`. The matrix was run from
authorization HEAD `f0444966cecbc1a02aa1c4705de9ddcd0b0af9b0`, tree
`b2e478d9402d8e65647d9df1d975ccd609820414`. The only tracked delta from
the accepted dormant commit to that authorization HEAD is
`docs/next_steps.md`; production sources are identical.

Frozen baseline results:

```text
artifact=63b1102c0e3e6b7445ac0366397dbb3c5c16917e6051d6a23eccc1a21ad2607d
report=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report_counts=443/285/158
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=167/17/101
```

Inputs and fixed implementation leaves:

| Input | SHA-256 |
|---|---|
| `tmp/inbox63_accepted_cohort.ll` | `d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4` |
| `tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll` | `7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b` |
| `tmp/inbox142_family_isolation/compare_elf_functions.zig` | `34b5d400b47a9e861e5f6e7082f54ad57d6bc9b3e5e772d60420074b4dd4ce8f` |
| `value_use/actions/scalar_named.zig` | `6de4086bb1285db52ebac352acb743e49a6778b2407def137ab71d56b9464416` |
| `value_use/model.zig` | `b81a0173dd7af97a346df71c030e6655d925891496f6bf7049e3e6cf8f13ab76` |
| `value_use/core.zig` | `fa2de662869ea1890466ea1e40b4700f803e05c24a35f5b0e44ecb9796aace43` |
| baseline `composed_selector_scalar.zig` | `1546fe4c600b4649ecd0aab8ee9c556e11feb70818e9d4b4ef49b0ad0e2d4c2c` |
| baseline `source_guard/consumer_policy.zig` | `e96f4c7c034a7992f3d799df88e3fde4de4ae5357a3eb55b88928ff1b5435c7f` |

The accepted action, model, and core files were never edited during the
matrix. Temporary consumer wiring selected exactly one complete family at
a time; all other candidate families and R03/R04 stayed on the legacy
path. The aggregate selected only B01 and I52B0.

## Temporary-build provenance

All temporary sources, binaries, logs, and comparison products are retained
under `tmp/inbox151_o2_family_isolation/`. They are ignored procedural
artifacts and are not part of this commit.

The temporary consumer source SHA-256 and compiled artifact SHA-256 pairs
are:

| Build | Consumer source | Artifact |
|---|---|---|
| B01 | `5459db7ba892c387333e03391b117261190c87cc8ac918977ecfe26fe96838fb` | `fdd22fee41ee834ee30b3c18ad739903658c8a3634fd6b71e9efad5694741032` |
| B03 | `48c64e143431f50c6862d867bd503843e8c6eb82db6501d44c0f55feb6a50c02` | `31f9fcf6d7509e04e96c9e94f005193915a01f7173f461c6be5beea6961e9e93` |
| B04 | `bc35f972e0d73526b35576e806079decbcf027c5d2828f9c3a3bc4117affbdf4` | `17f84264a27b12ac87b73039574676095d6c751b97676d63d07efa6088862adb` |
| B05 | `341095b31d23a71faa54f90cc3e6cf10fa01f1a8eeac934b87baabe275c3361b` | `855c87081c6c8b7cc7d7f1958372d700b98f8cf473d9ac6029dbb495a85053b1` |
| B06 | `10c33fc563bfa09e10092cfd8c4393bced78cb2dcfcb1d004dce820e7731713d` | `d23c3eca92333c3c761e9216207e56637dd1ed16eaead749db43a5bd4172f8e6` |
| B07 | `83f8bd6638f34a8b467e9a686f5cea00a0ea8ccc12ee9a4bc418301071ffb475` | `5797b1d19fc5730a6f31a6e2e224082eef1e6be92d47d4f4d2564bbf5f227281` |
| I52B0 | `2812a87b0a02c9a9763e0a34af7a074a04549718cb0cdf13d28a2177099a392f` | `b8c8d1db8a6f412cd9c2aafd6ead857685e5785bb4117e60109af0c7fbc1c608` |
| B01 + I52B0 aggregate | `de529ee2a692485014ff614c050f0f79a87d22169da5473026342b97378369c1` | `624c190f230a1005ce50f7195719e93ea12d333ae0986ad341401235a6ae0ee4` |

Because the production guard correctly rejects premature use of the
dormant action, matrix builds used one narrowly marked temporary guard
exemption. Its exact source hash is
`5853b2875e3cd44b1a01c93859db4621609d1f64fe26f535760277d6405753cd`.
It exempts only the matrix marker in `composed_selector_scalar.zig`;
all other source-guard policies and negative fixtures remained active
during the full-unit command. The accepted guard was restored after every
temporary build and is not changed by this commit.

The empty build logs have SHA-256
`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.

## Exact commands

The following command shapes were run separately against every isolated
source and again against the accepted-family aggregate:

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
  tmp/inbox151_o2_family_isolation/results/baseline/accepted.o \
  <isolated-accepted-object>
```

The report command intentionally returns the established local-failure
status while recording all 443 rows. No performance or Tier-3 command was
run.

## Complete per-family results

Every focused-canary run passed both canaries and all 35 executable cases:
`__multi3` 6 and `fma` 29. Each retained canary log has SHA-256
`d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6`.

Except for B07, every family report has the exact baseline report hash,
every accepted object has the exact baseline object hash, every owner
manifest has the exact baseline owner hash, and every per-function
comparison is:

```text
summary compared=285 divergent=0 missing=0
```

whose file SHA-256 is
`aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240`.

### B01 — accepted

Full unit passed 1339/1339; log SHA-256
`61d964e7d0e88af803c0762ae67ebfdaa63761288b725879a0802825a3399bd9`.
All cohort projections and per-function bytes are exact. No semantic or
branch-offset divergence exists.

### B03 — retained wholesale

Full unit passed 1338/1339; log SHA-256
`d91407f00a5f0f32b659b87f655065bb8b8625dfe12f4000379dbc97a0c36538`.
The failing production-path fixture is:

```text
named i32 multiply preserves the accepted accumulator-before-rhs order
error.ValueUseSourceIntervalMissing
```

The first semantic divergence occurs during transaction sealing, before
instruction mutation. The complete cohort and every emitted function are
still byte-identical, so there is no downstream branch-offset drift to
attribute. The unit failure nevertheless retains the complete family.

### B04 — retained wholesale

Full unit passed 1336/1339; log SHA-256
`8c613e402c0bff65d92b0aea5f8d2b9d6628405e91a36f81c0bcb8898b8b297e`.
The three failing production-path fixtures are:

```text
accumulator-resident named i32 shift keeps accepted direct materialization stream
  error.ValueUseSourceIntervalMissing
generic cfg selector lowers variable i16 shifts
  error.ValueUseSourcePlanMissing
generic cfg selector lowers i32 arithmetic-right shifts
  error.ValueUseSourceIntervalMissing
```

Each first divergence is a seal-time admission failure before instruction
mutation. The cohort and all 285 emitted functions are exact; there is no
branch-offset drift. The complete family is retained.

### B05 — retained wholesale

Full unit passed 1337/1339; log SHA-256
`26a867cbd710fddb44903068fcbdf89b6da7e998731e9be2f12ded76e73626e4`.
The two failing production-path fixtures are:

```text
generic cfg selector exact ei binary and shift reuse a dead accumulator lhs
exact ei shift preserves the accepted current-use accumulator rhs spill
```

Both expected an accepted result and instead received a diagnostic. The
first divergence is action admission/result selection, not an emitted
instruction. The cohort and all emitted function bytes are exact, so no
downstream branch offsets moved. The complete family is retained.

### B06 — retained wholesale

Full unit passed 1338/1339; log SHA-256
`25aac2e201c63228d1a6d4e4ec3dac5f62e3559985b46a0e1d6f4de9389bac59`.
The failing fixture is:

```text
generic cfg selector exact ei binary and shift reuse a dead accumulator lhs
```

It received a diagnostic rather than the accepted result. The cohort and
all emitted function bytes are exact; no downstream offset drift exists.
The complete family is retained.

### B07 — retained wholesale

Full unit passed 1338/1339; log SHA-256
`edbce587fbc04c8bd1d6b52d54c44fa63e1b48ad0fafdcb88b27d5671c8ea873`.
The failing fixture is:

```text
generic cfg selector reloads 32-bit spill rhs for binary accumulator op
```

It received an unexpected diagnostic. More decisively, the cohort report
moved to 443/279/164 with SHA-256
`9e283eade6790443768b41e112c7c8f28993564d3df83fc5c5e5d1737a27ae72`.
These six formerly accepted functions fail with
`unsupported_value/composed-block-unknown-rhs`:

| Function | First semantic producer in the accepted IR |
|---|---|
| `compiler_rt.floatuneidf.__floatuneidf` | `%54 = and i32 %50, %53` |
| `compiler_rt.floatuneisf.__floatuneisf` | `%36 = or i26 %common.ret.op.i71, %35` |
| `compiler_rt.floatuneihf.__floatuneihf` | `%39 = or i13 %38, %29` |
| `compiler_rt.floateidf.__floateidf` | `%17 = sub i64 %.neg, %26` |
| `compiler_rt.floateisf.__floateisf` | `%17 = sub i64 %.neg, %26` |
| `compiler_rt.floateihf.__floateihf` | `%17 = sub i64 %.neg, %26` |

The complete object and owner commands both stop at
`compiler_rt.floatuneidf.__floatuneidf` with
`error.UnsupportedCodegenControlFlow`; their stderr SHA-256 is
`499bf7a7b6fe05147bcbedb3020c4084e9157f5f5d282d23a60645ca10158ec5`.
No partial object or owner manifest is treated as evidence.

To complete the per-function check despite that fail-closed object result,
an ignored Zig-only filter replaced exactly those six definitions with the
same `unreachable` stubs in both baseline and B07 inputs, retaining their
definitions so the module's aliases remain valid. The filter SHA-256 is
`bf3048be1b774909dadf750df2e2530f447824e67b87612c8eb40306b639f97a`;
the stubbed IR SHA-256 is
`aab55894392a18b43cd5a84ac0fad3feec2fd9e90001dafc5e00f1924f779ace`.
Both resulting objects have SHA-256
`1c394b3fa27d86620f0bd57876e0632b09c01853935538c9195e29cc3555b7b8`,
and the comparator reports 285/0/0 with the canonical comparison-file hash
`aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240`.

Thus the first divergence is the named/named B07 transaction admission at
the six listed semantic producers. All otherwise emitted functions remain
byte-identical; there is no masked downstream branch-offset divergence.
The complete B07 family is retained with zero credit.

### I52B0 — accepted

Full unit passed 1339/1339; log SHA-256
`66c7509b1c8ec1e7ab95ad608e248d8cf51380a017d6da061010feabee3871e8`.
All cohort projections and per-function bytes are exact. No semantic or
branch-offset divergence exists.

## Accepted-family aggregate

The aggregate contains B01 and I52B0 only. Full unit passed 1339/1339;
log SHA-256
`66a323059a61a00810d766ecb1697f0f5f5c85149d109dcc8e8a0dccf2ec94bc`.
Focused canaries passed 2/2 and 35 executable cases. The report, object,
owner manifest, and all 285 per-function comparisons are exact. Because
the aggregate is identical, no minimal interacting subset exists to
isolate.

## Closeout

After the temporary builds, both modified tracked files were restored to
their accepted hashes shown above. No action/model file was changed, no
production wiring or guard exemption is committed, and the only tracked
change in this slice is this evidence document. `stash@{0}` remains
`7985c6d01040a6e47e4ce5b918866d0e89517ac7`; all preserved patches remain
untouched.
