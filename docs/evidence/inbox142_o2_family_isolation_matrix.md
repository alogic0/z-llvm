# INBOX-142 — immediate family-isolation matrix

Status: evidence-only architectural checkpoint. No production, test, guard,
tool, build, or inventory file is changed by this slice. The production
ratchet remains 166.

## Result

The complete family-isolation matrix changes the proposed partition:

- byte-identical and compositionally compatible:
  **R00, R01, R02, R05, R06, L01, L02, L03**;
- retained wholesale:
  **R03** and **R04**.

R03 has one divergent accepted function:
`compiler_rt.exp2.exp2`. The root producer is
`%11 = ashr i32 %10, 8`. The frozen action spills and reloads the live `%10`
source, while the accepted path preserves it in EDI. R04 remains retained
by the already-accepted fma evidence.

The aggregate of all eight individually byte-identical families is itself
byte-identical across all 285 emitted functions. There is no hidden
cross-family interaction to isolate.

The honest proposed ratchet is **166 -> 154**, not 153. This document does
not authorize or contain that wiring.

## Frozen basis

```text
matrix_head=172e33f7c5da5e00f2ae92be3481ee56b2423027
matrix_tree=b4c945f6a617ed2c748d66dfa157830d9e896361
branch=x86_64-codegen-expanded-frontier
frozen_action_model_commit=de3cb6f980369534932488502424370aecf82486
baseline_scalar_source_sha256=78452e32276f9968e22f938d52ea758f36845af08fa883c98ae78a509fff5c3c
baseline_artifact_sha256=a04cdc613975e7ef4ef05dcdb35052b5eb5822f317f28b24130828f442c6f06d
baseline_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
baseline_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
baseline_owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
baseline_report=443 selected / 285 emitted / 158 failed
baseline_first_failure=compiler_rt.trunc.truncl / UnsupportedLongDoubleAbi
baseline_owner_ledger=167/17/101
current_ratchet=166
```

The current production tree is byte-identical to the accepted
`de3cb6f9` production tree; intervening commits are evidence and Supervisor
mailbox records only.

Frozen production/action inputs:

```text
scalar_arithmetic.zig=ff6d112ac285bef239f64873d77954e48e66594049a18867b6def17fb91e64f1
value_use/model.zig=b9c61b866fecb563795ae94be3eabfeb7d173e75b95cdf79325e430698b02ad8
value_use/core.zig=8d4221bdde74f697d5c16f819c2458511f7663bb550da67fa747d964386cedf1
compiler_rt_frozen.ll=7c91f5f602ec45c57a96ad82d1e097c47a47df7b00809800ebcefc3fccf6760b
accepted_cohort.ll=d8da86cae494d7d4a58053ab24b1e8be944859263072b85ffa164880b0110cd4
```

The temporary source generator validates the accepted scalar-source hash
before writing. Each generated source was formatted, hashed, built once,
copied to immutable temporary storage, and then the tracked source was
restored with scoped `git checkout --`. The tracked worktree was clean
after every build.

```text
temporary_source_generator_sha256=1e7d233cf09c85a5b4dc695104a36b8808cd9bd58a65a3ae4a28d16842b9618f
closed_classifier_template_sha256=a394b5f01d4a4aad32a22c853b239ef2126ccda6a76c4749370245fa71800305
elf_function_comparator_sha256=34b5d400b47a9e861e5f6e7082f54ad57d6bc9b3e5e772d60420074b4dd4ce8f
```

No retired carrier was applied. The preserved carrier hashes remain:

```text
retired_B5_state=1fb434f2e2209d7af2caae5b865d334fd635207bace49fc143a68db7e5c1bf05
stopped_INBOX_141_state=7e2fc523fe0d74f46bd209a83b7d9e133093582611b458028a95a8bc52ab8f42
```

## Method

Each candidate build wires exactly one complete semantic family:
R00-R03, R05-R06, or L01-L03. All other immediate families use the
accepted legacy source unchanged. In particular, every R04 form remains
legacy in every matrix member.

Each frozen artifact was used independently for:

1. the complete 443-row report;
2. the 285-row accepted object;
3. the selection-owner manifest;
4. an ELF symbol-level comparison of every
   `compiler_rt.*` function's exact bytes against the baseline.

The function comparator matched all 285 emitted functions by symbol
identity and compared each function's own section slice, so one
length-changing function cannot mask later symbols. A whole-object match
therefore has both aggregate and per-function proof. For a mismatch, the
full disassembly was compared and the earliest changed control-transfer
encoding was separated from the first semantic instruction change.

Exact command shapes:

```text
build:
  /home/oleg/bin/zig build

report:
  LC_ALL=C <artifact> --emit=obj --generic-cfg-selector \
    --report-all-codegen-failures --target=x86_64-linux \
    --input-limit=67108864 \
    tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll

accepted object:
  LC_ALL=C <artifact> --emit=obj --generic-cfg-selector \
    --target=x86_64-linux --input-limit=67108864 \
    tmp/inbox63_accepted_cohort.ll

owner projection:
  LC_ALL=C <artifact> --emit=selection-owner-manifest \
    --generic-cfg-selector --target=x86_64-linux \
    --input-limit=67108864 tmp/inbox63_accepted_cohort.ll

per-function comparison:
  /home/oleg/bin/zig run \
    tmp/inbox142_family_isolation/compare_elf_functions.zig -- \
    <baseline-object> <variant-object>
```

No performance command or Tier 3 command was run.

## Family matrix

Every report is independently
`49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`.
Every owner manifest is independently
`5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d`.
All manifest stderr files are empty.

| Family | Whole object | Per-function result | Semantic result | Disposition |
|---|---|---|---|---|
| R00 | exact `061a64e4...` | 285 compared, 0 different | zero-count ownership transition is byte-identical | eligible |
| R01 | exact `061a64e4...` | 285 compared, 0 different | complete lshr family and helper collapse are byte-identical | eligible |
| R02 | exact `061a64e4...` | 285 compared, 0 different | complete shl family is byte-identical | eligible |
| R03 | **`60c50ffc...`** | 285 compared, **1 different** | live shared source changes from EDI preservation to stack spill/reload | **retain** |
| R05 | exact `061a64e4...` | 285 compared, 0 different | zero-count wide-action ownership transition is byte-identical | eligible |
| R06 | exact `061a64e4...` | 285 compared, 0 different | complete wide scratch add/sub family is byte-identical | eligible |
| L01 | exact `061a64e4...` | 285 compared, 0 different | complete reverse-subtract family is byte-identical | eligible |
| L02 | exact `061a64e4...` | 285 compared, 0 different | complete immediate-LHS shl family is byte-identical | eligible |
| L03 | exact `061a64e4...` | 285 compared, 0 different | complete immediate-LHS lshr family is byte-identical | eligible |

The eight identical per-function reports share raw SHA-256
`aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240`.
The R03 report is
`9f4e56431d028a0359ac182aaec3ed4b228efb2988b2e79fbfc198770ca0604a`.

### Frozen isolated source and artifact hashes

```text
family  source_sha256                                                   artifact_sha256
R00     e714f3a252b455d4711387a2d7498ed5cd2b0c88638100b6e4970abdd5910bbc  b8da36275c400f2e4e60e8fb054ca01cc1862226ffdffd8a4886a4a247f34eac
R01     9e736bf11dbbd611ead07a85f36ae3d658904f8d95e24150c3ac870716427898  4aa2e579fac5d5b77b34456f7e0426c9352767c2fdb13b4026663be4fdcd67a3
R02     9da81a8da60fdba6a44b0bbe5d9bb58e4cafad912ca19d623e7dc0a57daf1c78  640b114a84df66b3bb5aa698d03f90046a4e9683a33b0ea54f03fbe70abb8862
R03     6c398c6e5893cc07cc458a2c27db989ee8b38705dac533e8a936f3838e69dbe1  e9b79be068e46252f515c01f857e5f9ecb651813940b4df5136964283caaa25c
R05     d8ca7d5b2645343abd8ff3bd381bf610f5e8d8be944ea0557bcb532cb1a69d77  a0132e675346ac7e025bebd7a39f922a32870c9b530e50b5927e012f6c0d1305
R06     79fa58f394237d938964aeb05c71b2ba976634b580e1a570081382d730516a4a  95bf869d9d43a873e4fdc664865d6f735d7f563bd090e30399712c86f86bf1ae
L01     56c22916f292948e5f4a1ee91851725a947d6279671c3281ab1ddd0197fe25af  9a57244fd7f0d2e07bad7026995bd1b892ec041ce97c9f3da3fbc450f1a18c94
L02     44359adb559eaa48a88297fe28df64d7afbfdfcb8b815a72fe626dd7f101bd95  588bf95c8c72f0af43833d2b9a885a20966775d1c507b6048d88aabd49c2f62b
L03     8f4e13c88d251ecd8def7328b373ce480e1ef1631bf4d1560455a0d7d062f522  0ddc3e8135a35622e37c9eed9e0fdf80bc6b9e3ee6dea838b3773f76c6c625fc
```

## R03 complete divergence attribution

R03 covers 58 semantic occurrences in 36 functions. The symbol-level
comparison proves that exactly one accepted function changes:

```text
function=compiler_rt.exp2.exp2
baseline_offset=0x1c61f
baseline_size=996
isolated_R03_offset=0x1c61f
isolated_R03_size=1004
raw_first_different_function_byte=150
baseline_function_sha256=f32741928481a439aeb07aa4ff3b481347e4f3e45a860bcbecae662e8fb90adb
isolated_R03_function_sha256=ea4c476a0dfe32e77d3e1f3edbaa1d49ce354d63e8e364d9c115ff04d9d45fb5
```

The raw first byte at function offset 150 is not the root producer. It is
the displacement of an earlier `jne`; the target moves because the later
R03 sequence grows. Two more earlier jumps change for the same reason.

The first semantic change begins at function offset 204, for:

```llvm
%10 = add i32 %9, 128
%11 = ashr i32 %10, 8
```

Accepted:

```asm
add    $0x80,%eax
mov    %eax,%edi
mov    %edi,%eax
sar    $0x8,%eax
mov    %eax,0x28(%rsp)
```

Isolated R03:

```asm
add    $0x80,%eax
mov    %eax,0x28(%rsp)
mov    0x28(%rsp),%eax
sar    $0x8,%eax
mov    %eax,0x30(%rsp)
```

The accepted R03 authority preserves `%10`, which is consumed later by
`%14 = shl i32 %10, 1`, into EDI. The frozen action instead gives `%10` a
durable spill and reloads it into EAX. The later `%14` stream consequently
also reloads the changed stack home; that is downstream from the same R03
home decision, not an independent R02 divergence. Subsequent differences
are address/stack-offset or branch-displacement movement caused by the
eight-byte growth.

The complete disassembly diff is frozen at:

```text
tmp/inbox142_family_isolation/results/r03/exp2.diff
sha256=8cd6387c5882ec86f1132a433790849c9d26bfc34dcbd7d88199d25ef3491844
```

R03 is retained wholesale under the named future owner
`scalar_immediate_ashr_live_source_home_preservation`. No R03 form may
transactionally attempt and fall back.

## R04 retained evidence

R04 was not a candidate matrix member because INBOX-142 starts with it
already retained. Its accepted evidence remains:

```text
root_function=compiler_rt.fma.fma
root_producer=%32 = add nuw i6 %31, 1
accepted_stream_sha256=cc791b46ef93f564040e5245874216a7aa267df7319e84135862177f4eff776a
retired_wired_stream_sha256=0eaed5c57bf54dd1d02107403856af347cdb13b25ec63def693a1792ea3361c3
accepted_object_sha256=b8b720e69b6b32d427cd1633ef8b76f663f9933300cca291feefc560ce994b2f
retired_wired_object_sha256=d369a7a4d939c767e53eafb336592fd45b505fdb3f623455450a34bfb671e835
```

Its frozen action preserves the shared physical accumulator once, while
the accepted path gives the live i6 `%31` and i52 `%30` aliases distinct
EDI and RSI homes. R04 remains wholesale legacy-owned by
`scalar_immediate_multi_alias_preservation`.

## Aggregate interaction check

The aggregate enables exactly:

```text
R00,R01,R02,R05,R06,L01,L02,L03
```

R03 and R04 remain legacy. Its frozen identities are:

```text
aggregate_source_sha256=c7020ba8b1319111fd9bea9fb3b2c00f970843481b1e8f4a322d257b5b6858ab
aggregate_artifact_sha256=fce5d4af3bb7b4c97267bd6c2ced481faec6cf87131435d2c2543e37ad91bd3a
aggregate_report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
aggregate_object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
aggregate_owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
aggregate_function_compare=285 compared / 0 different / 0 missing
aggregate_function_compare_sha256=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
```

Thus individual identity composes for the complete eligible set. There is
no interacting subset to minimize and no unattributed aggregate movement.

## Honest ratchet

The eligible families remove only these frozen textual gateways:

```text
R00  semantic ownership only                                      0
R01  lowerBinaryImmediateRhs/emitValueIntoScratch x2
     + tryLowerLshr64SpillThroughRax/resolveValue last owner       3
R02  lowerBinaryImmediateRhs/resolveValue x1
     + lowerBinaryImmediateRhs/emitValueIntoEax x1                 2
R05  semantic ownership only                                      0
R06  lowerBinaryImmediateRhs/emitValueIntoScratch x2               2
L01  lowerBinaryImmediateLhs/emitValueIntoScratch x2               2
L02  lowerBinaryImmediateLhs/emitValueIntoScratch x1               1
L03  lowerBinaryImmediateLhs/emitValueIntoScratch x2               2
                                                                  --
eligible reduction                                                12
```

Retained:

```text
R03  lowerBinaryImmediateRhs/emitValueIntoScratch x1 remains
R04  zero textual gateways; semantic legacy owner remains
```

Therefore:

```text
current_ratchet=166
eligible_reduction=12
proposed_future_target=154
```

The prior 153 projection included R03's one gateway and is superseded.

## Review boundary

Complete eligible set:

```text
R00,R01,R02,R05,R06,L01,L02,L03
```

Complete retained set:

```text
R03 -> scalar_immediate_ashr_live_source_home_preservation
R04 -> scalar_immediate_multi_alias_preservation
```

This is the required stop for architectural review. A final 154-ratchet
patch is not preauthorized by this evidence.
