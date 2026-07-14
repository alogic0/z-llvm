# Half-To-Double Extension Composition Acceptance

schema_version: 1
directive: `INBOX-39 pre-authorized successor`
target: `x86_64-linux`
validation_tier: 3
result: pass

The accepted baseline is `e6166c0a`, report state 443 selected / 238 emitting /
205 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`. The production and permanent-test
diff used for validation has sha256
`8830909c56ae3fe746c51c2c4945462cb96f6c82d22085c5ceb6426fc79c056f`.
The current-source ReleaseFast z_llvm has sha256
`80cb404747a0147e540987ea908df6c7f241f54f17061888ae5fa92734fde74e`.

The composed selector now admits exact `fpext half -> double` by composing the
proven nonrecursive `__extendhfsf2` half-to-float helper with the existing
register-parametric `cvtss2sd` operation in XMM0. The same helper retains its
existing half-to-float behavior; unrelated half arithmetic and wider FP casts
remain fail-closed.

The first fresh report advanced `__fmah` to `composed-block-spill-frame` rather
than claiming a closure. Frame preplanning reserved call-spill space for
explicit scalar-SSE IR calls but not for admitted half casts that synthesize
the same helper-call boundary. It now classifies only the admitted
half-to-float, half-to-double, and float-to-half helper conversions as scalar
SSE calls. This uses the existing frame allocator, spill layout, and call
preservation authority; no parallel frame policy was introduced. A permanent
three-half-argument regression proves an earlier extension survives two later
helper calls and that the selected machine verifies.

The exact captured `compiler_rt.fma.__fmah` body emits as one 109-byte global
function with three `R_X86_64_PLT32` relocations to `__extendhfsf2` and one to
`__truncsfhf2`. A native `zig build-exe -fno-lld` executable resolves those
already established compiler-rt helpers and passes 20 precomputed raw-half
cases. Coverage includes signed zeros, subnormals, normals, overflow, both
infinities, invalid infinity combinations, quiet/signaling NaN payloads, and a
rounding-sensitive cancellation case.

Fresh report-all advances to 443 selected / 239 emitting / 204 failing. The
complete report diff removes exactly `compiler_rt.fma.__fmah` and introduces
no new or collateral failure changes.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=239 failed_functions=204 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused coverage: composition_sequence=1/1 implicit_call_frame_regression=1/1 exact_fmah_cases=20/20 relocations=4/4
report delta: collateral_changes=0 closures=1
tier2: pass; steps=24/24 tests=954/954
tier3: pass; subgates=17/17 local_fail=0
```

Commands:

```text
zig build test structural-smoke --summary all
zig build install -Doptimize=ReleaseFast --prefix tmp/inbox39_half_double_install
tmp/inbox39_half_double_install/bin/z_llvm --emit=obj --target=x86_64-linux --passes=zig-debug-accepted --input-limit=67108864 --report-all-codegen-failures --generic-cfg-selector tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
zig build distribution-all
```

Artifacts:

- `tmp/inbox39_half_double_report.log`, sha256
  `ad8cc6306372ef5af67033086c05bf0e2f0ac77f33ff8c849a09fa20528e665a`;
- `tmp/inbox39_half_double_tier2.log`, sha256
  `8ce021fc9be9f64c1d8b8829cec93db7b5504824fe284e7652acc9d5767600a5`;
- `tmp/inbox39_fmah_row.ll`, sha256
  `87366705eeb7b8a4ea18c7b41357edd60a4cec3d675f725f5135b01c61003d49`;
- `tmp/inbox39_fmah_row.o`, sha256
  `8353911536eac738dc7beccfbfa571131e6c6d6de66f40eb17eaf3daca68f481`;
- `tmp/inbox39_fmah_readelf.log`, sha256
  `a72aa0b9a041c3b8642b8ec168b9c238e57969f941c513d1e3e6ab285a080b50`;
- `tmp/inbox39_fmah_objdump.log`, sha256
  `fb0853e5e013e8372964d0bb72634ef14214878c1c39661cb993a0dd6bd71d1d`;
- `tmp/inbox39_fmah_row_acceptance`, sha256
  `e940bbbba43c38340c7b1edc9d86a2b88dec34f1ebd4f4007f126a746bd3e02a`;
- `tmp/inbox39_fmah_reference.log`, sha256
  `a1889d6613c8d669de71a82e59dd51e62e3a0afc91989066b0eeb90b1b2bb6d6`.

The INBOX-39 pipeline is exhausted. Stop at the refreshed frontier for the
next directive; the agreed order is half `fcmp uno/olt` before half `fadd`,
then the lanes-canonical mask slice before aggregate-ABI review.
