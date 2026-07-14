# Exact SSE Aggregate Return Acceptance

schema_version: 1
directive: `INBOX-42`
target: `x86_64-linux`
validation_tier: 3
result: pass

The accepted baseline is `e24702a8`, report state 443 selected / 247 emitting /
196 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`. The implementation-only staged
tree accepted by Tier 3 is
`f0c0dfd5c70bc5d1feca429d505acbfbaa59d207`.

`sysv_abi.zig` remains the sole classifier. Its exact return whitelist admits
only `{ <2 x float> }` as one packed low XMM0 eightbyte and
`{ double, double }` as scalar leaves in XMM0 and XMM1. Mixed aggregates,
aggregate parameters and calls, sret, wider vectors, fp80/fp128, generic
extractvalue, aggregate allocas, and nonterminal aggregate operations remain
fail-closed.

The existing value map owns typed aggregate leaves as references to the
authoritative scalar/vector SSA bindings. Terminal constant-index
`insertvalue` construction requires poison and complete leaves. Return
materialization resolves the current register or spill location at the return,
and the split-double path uses a scratch XMM parallel copy so XMM1/XMM0 sources
cannot clobber one another. A focused test proves the exact XMM1-to-XMM0,
XMM0-to-XMM1 swap sequence.

The verifier derives aggregate return requirements from the same classifier
and tracks XMM defined widths through existing moves, packed operations, and
reloads. Negative tests reject a missing XMM1 double leaf and a packed XMM0
with only one 32-bit lane defined. Incomplete and non-whitelisted selector
forms are also permanent negative cases.

The pinned-Zig integrated executable calls two exported z_llvm-selected
functions with `callconv(.c)`. It checks both return fields bit-for-bit across
six f32 and six f64 pairs: both signed zeros, signed minimum subnormals,
asymmetric finite normals, signed infinities, quiet NaN payloads, and signaling
NaN payloads. This proves packed low-XMM0 order for `{ <2 x float> }` and
XMM0/XMM1 field order for `{ double, double }` without relying on symbol or
block-name matching.

Fresh report-all remains exactly 443 selected / 247 emitting / 196 failing:
directed closures are zero. `__divdc3` advances to its first
`llvm.maxnum.f64` intrinsic, `__muldc3` to `<4 x double>` construction, and
`__divsc3` / `__mulsc3` to aggregate allocas. A planning-only correction
defers unsupported vector-phi rejection to its actual edge so it no longer
masks an earlier body frontier; vector phis remain fail-closed.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=247 failed_functions=196 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=0 collateral_emissions=0 new_failures=0
focused ABI coverage: f32_pairs=6/6 f64_pairs=6/6 raw_fields=24/24 swapped_xmm_parallel_copy=1/1
tier2: pass; steps=24/24 tests=968/968
tier3: pass; subgates=17/17 integrated_executable=6/6 local_fail=0
```

Commands:

```text
zig build test
zig build install -Doptimize=ReleaseFast --prefix tmp/inbox42_aggregate_sse_acceptance_install
tmp/inbox42_aggregate_sse_acceptance_install/bin/z_llvm --emit=obj --target=x86_64-linux --passes=zig-debug-accepted --input-limit=67108864 --report-all-codegen-failures --generic-cfg-selector tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
zig build distribution-all
```

Artifacts:

- `tmp/inbox42_aggregate_sse_report.log`, sha256
  `6b67a62d5dadcefff4bbe95114c27e377014f1fdd006bb739f06e08ef5e48c1d`;
- `tmp/inbox42_aggregate_sse_tier2.log`, sha256
  `7ad57a534b5655cb701cb1872330b6832e967a78df6f6d9b2e19636dbcc897fb`;
- `tmp/distribution_all_after_inbox42_aggregate_sse_returns.log`, sha256
  `dcaab9443211605c05d54096b596c55b6dfe377d507cd8a35995bd6d0b69dbb5`.

Continue with INBOX-42's pre-authorized aggregate stack-object slice. It owns
one exact 8-byte, 4-aligned f32-pair object through the existing frame
authority, bounded constant field offsets, pointer PHIs through existing edge
handling, and the captured store/load/merge forms. No third cycle is
authorized.
