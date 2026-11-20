# Packed FP Subtraction Acceptance

schema_version: 1
directive: `INBOX-28` pre-authorized successor
target: `x86_64-linux`
validation_tier: 2
result: pass

The committed prerequisite is `11483785`, which acknowledges `INBOX-28` and
accepts the typed lane-shift capability. The accepted compiler_rt baseline is
443 selected / 202 emitting / 241 failing, with captured IR md5
`b0eda7a6427c3084fdf096a68696f19c`. The source-only successor diff used for
validation has sha256
`e2f06f3c2aac602e453ae4871fe98b35af34145d77ec4e46de50d8d272020b4c`.
The current-source z_llvm was explicitly installed through an isolated cache
and prefix and has sha256
`2c9949be92cbcb5620b3ddba6f8af3640386801c40f6bfb1ead77d7e7628d9cb`.

The packed-XMM selector now admits type-driven `fsub` for exactly f32x2 and
f64x2. Register-parametric `subps` and `subpd` machine operations sit beside
the accepted packed add/multiply forms, with exact encoding, assembly, size,
and verifier coverage. Lowering always materializes the left operand into the
destination, protects a live right-operand register, and subtracts the right
operand from it. Result definedness is the intersection of the two static
lane masks. Packed division, remainder, other element types and widths, and
unsupported vector operations remain fail-closed.

The existing spill-pressure canaries execute both `%pair - zeroinitializer`
and `zeroinitializer - %pair`, making operand reversal observable. Five f32x2
and five f64x2 input pairs cover signed-zero preservation and cancellation,
finite positive/negative values, signed minimum subnormals, infinities, and
quiet NaNs with payloads. All 210 output words match exactly, including all 40
packed-subtraction results checked against literal precomputed bit patterns,
while both packed spill/reload paths remain active.

Fresh report-all remains 443 selected / 202 emitting / 241 failing.
`compiler_rt.log.log` advances from packed `fsub` to its concrete
`sitofp i12 ... to double` instruction. No other diagnostic changes, no row
closes, and no collateral emission occurs. Therefore Tier 3 is not triggered.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=202 failed_functions=241 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused tests: unit=906/906 f64x2_cases=5/5 f32x2_cases=5/5 exact_output_words=210/210 packed_fsub_words=40/40 operand_orders=2/2
tier2: pass; steps=24/24 tests=914/914 structural=8/8 assembly/encoding/object inspection=pass selected object/executable modes=pass integrated_executable=5/5
tier3: not-triggered; no row closure or shared subsystem boundary
```

Commands:

```text
zig build test --summary all
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
zig build install -Doptimize=ReleaseFast --cache-dir tmp/inbox28_fsub_zig_cache --prefix tmp/inbox28_fsub_install
tmp/inbox28_fsub_install/bin/z_llvm --emit=obj --target=x86_64-linux --passes=zig-debug-accepted --input-limit=67108864 --report-all-codegen-failures --generic-cfg-selector tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll
```

Logs: `tmp/inbox28_packed_fsub_tier2.log` (sha256
`300aa84bc99ff89fe5fc67f262386596c9f6ba15a7217470141636f2d773289e`)
and `tmp/inbox28_packed_fsub_report.log` (sha256
`63c41407638bc329a0f5ae6244c356686793729e65499c392de3f3d8b526494b`).

The INBOX-28 one-cycle pipeline is exhausted. Stop after commit and request
the plan's periodic review before selecting another capability.
