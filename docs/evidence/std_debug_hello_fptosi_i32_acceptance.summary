# Scalar FP To Signed I32 Acceptance

schema_version: 1
directive: `INBOX-38 pre-authorized successor`
target: `x86_64-linux`
validation_tier: 2
result: pass

The accepted successor baseline is `f9db8bcf`, report state 443 selected / 236
emitting / 207 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`. The production and permanent-test
diff used for validation has sha256
`4e99fca757b6409d12381f8b747b962e4f7479fe2da562911ed9471f49756df4`.
The current-source ReleaseFast z_llvm has sha256
`59681bc3fc16d97ba347809a04ac215823f2e583b26c00ed32b998fd2a2fc94f`.

The composed selector admits only exact `fptosi float -> i32` and
`fptosi double -> i32` casts. It materializes the typed source through the
existing XMM value-location authority, preserves a live accumulator result,
then reuses the existing `cvttss2si` or `cvttsd2si` machine, encoder, and
verifier operation. `fptoui`, half sources, and non-i32 destinations retain
their prior fail-closed ownership and diagnostics.

Permanent executable coverage converts float and double sources arriving in
independent SysV XMM argument registers. Eight paired cases cover positive and
negative zero, positive and negative subnormals, fractional truncation toward
zero on both signs, the greatest defined f32 value below positive i32 overflow,
and the exact positive and negative i32 boundaries. The first conversion stays
live across the second, proving the fixed-EAX preservation path before the
results are combined.

Fresh report-all remains 443 selected / 236 emitting / 207 failing; no closure
is claimed. A complete diff against INBOX-38 Part 1 changes exactly the two
directed rows and no others:

- `compiler_rt.exp.exp` advances from `unsupported_instruction fptosi` to
  `composed-block-gep-readonly-table-global`;
- `compiler_rt.exp.expf` advances through the same frontier.

This later boundary is expected: both captured bodies use function-local
constant tables, while the accepted module-aware table capability deliberately
excludes `.rodata`/local-symbol ownership.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=236 failed_functions=207 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused coverage: executable_defined_cases=8/8 fail_closed_shapes=3/3 directed_frontier_advances=2 collateral_changes=0 closures=0
tier2: pass; steps=24/24 tests=949/949
tier3: not-triggered; no row closure, ABI change, object-writer change, ratchet move, or milestone boundary
```

Commands:

```text
zig build test structural-smoke --summary all
zig build install -Doptimize=ReleaseFast --prefix tmp/inbox38_fptosi_install
tmp/inbox38_fptosi_install/bin/z_llvm --emit=obj --target=x86_64-linux --passes=zig-debug-accepted --input-limit=67108864 --report-all-codegen-failures --generic-cfg-selector tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
```

Logs:

- `tmp/inbox38_fptosi_report.log`, sha256
  `4463fcb4539a818646130ee8ca35b3dadadbc5cb85276e6506a7c7c3d953554d`;
- `tmp/inbox38_fptosi_tier2.log`, sha256
  `27c0897e036e7081ab9b9b4f9eb53a55a95c39d26148050d6fd86fe8f4b56bcd`.

The INBOX-38 pipeline is exhausted. Stop for the next scalar-tranche directive;
the other ranked successor, exact signed i32 division by two, remains the
strongest concrete two-row scalar frontier outside the reviewed constant-table
exclusion.
