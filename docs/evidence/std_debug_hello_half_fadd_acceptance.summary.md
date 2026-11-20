# Half Addition Acceptance

schema_version: 1
directive: `INBOX-40 pre-authorized successor`
target: `x86_64-linux`
validation_tier: 3
result: pass

The accepted baseline is `25052481`, report state 443 selected / 243 emitting /
200 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`. The validated production and
permanent-test diff has sha256
`5400ac64c450ff92fb7bd609bab2ec6ff695354aa5bc7dcde870b6fce78aabf8`.
The current-source ReleaseFast z_llvm has sha256
`fabb6f5dcf9dd7f448e06b28fbcd438fe17c4bb21bee811f4ae11b02becd2ccc`.

Scalar half `fadd` now widens each admitted named or literal half operand to
binary32, emits the existing `addss`, and truncates through the proven
nonrecursive `__truncsfhf2` helper. Two named operands use the existing pair
spill authority across their sequential `__extendhfsf2` calls. Other half
binary operations and unsupported operand forms remain fail-closed.

The composition is bit-exact for binary16 addition, not an assumed
approximation. For finite operands with unbiased-exponent separation at most
13, aligning two 11-bit binary16 significands produces at most 24 significant
bits, so binary32 represents the exact sum before the final binary16 rounding.
At larger separation the smaller operand is less than one quarter of the
distance from the larger binary16 value to an adjacent binary16 midpoint, so
it cannot alter the correctly rounded binary16 result; losing it in binary32
therefore cannot create a double-rounding change. Subnormal pairs require no
more precision than the close-exponent case. IEEE addition handles signed
zeros, overflow, infinities, and NaNs; permanent execution covers those forms,
including midpoint-adjacent finite cases and quiet/signaling NaN payloads.

The captured floor/ceil CFG also required four exact typed prerequisites:

- half and pointer local allocas/stores plus the exact empty `m` stack-memory
  barrier now use the existing frame, memory, and call authorities;
- immediate-left variable `shl i16 -1, %named` normalizes its EAX result to
  the low 16 bits and executes all 16 defined shift counts;
- `icmp sgt i16 %named, -1` is an exact normalized sign-bit test;
- scalar half literals materialize as raw low-16-bit XMM payloads, without a
  conversion or payload loss.

The extracted `compiler_rt.floor_ceil.__floorh` and `__ceilh` object contains
two global functions and exactly eight `R_X86_64_PLT32` relocations: four to
`__extendhfsf2` and four to `__truncsfhf2`. A native
`zig build-exe -fno-lld` executable passes 24 precomputed raw-half inputs for
both functions (48 calls), covering both zeros, positive/negative subnormals,
fractional and integral boundaries, maximum finite values, infinities, and
quiet/signaling NaN payloads.

Fresh report-all advances to 443 selected / 246 emitting / 197 failing.
`__floorh` and `__ceilh` are the two directed, executably proven closures.
`compiler_rt.int_from_float.__fixhfsi` emits collaterally through the exact i16
prerequisites and is recorded without a row-level semantic claim. No new
failure appears.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=246 failed_functions=197 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused coverage: half_fadd_cases=11/11 captured_fadd_inf_cases=8/8 i16_shift_counts=16/16 i16_sign_cases=5/5 half_literal_select_outcomes=4/4 exact_floor_ceil_calls=48/48 relocations=8/8
report delta: directed_closures=2 collateral_emissions_without_semantic_claims=1 new_failures=0
tier2: pass; steps=24/24 tests=960/960
tier3: pass; subgates=17/17 local_fail=0
```

Commands:

```text
zig build test structural-smoke --summary all
zig build install -Doptimize=ReleaseFast --prefix tmp/inbox40_half_fadd_acceptance_install
tmp/inbox40_half_fadd_acceptance_install/bin/z_llvm --emit=obj --target=x86_64-linux --passes=zig-debug-accepted --input-limit=67108864 --report-all-codegen-failures --generic-cfg-selector tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
zig build distribution-all
```

Artifacts:

- `tmp/inbox40_half_fadd_report.log`, sha256
  `d885109f7682d5f35ffe53b4c794b3c2230c8a3f471034f3936a10d79d0d5053`;
- `tmp/inbox40_half_fadd_tier2.log`, sha256
  `a3c460e7a0e829bd5b7fce4f23a9a9fe5182ee7c79b3752eb30261ce477a6a2b`;
- `tmp/inbox40_half_round_rows.ll`, sha256
  `eade22112cc149856ee23c0e5a346993eff796887602011e6372064dc6d74737`;
- `tmp/inbox40_half_round_rows.o`, sha256
  `e78751272db4991558639f5bdddd16cf3497ead03895a1906239a80a5be40773`;
- `tmp/inbox40_half_round_acceptance`, sha256
  `fd57f37ca580475d51f722d0c74bed63dabf9841c667782b4250dfc0e3492766`.

The INBOX-40 pipeline is exhausted. Stop before the lanes-canonical
vector-mask bridge from `docs/evidence/vector_mask_checkpoint_inventory.md`;
implementation requires its own directive.
