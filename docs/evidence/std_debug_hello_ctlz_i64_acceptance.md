# Typed I64 Count-Leading-Zeros Acceptance

schema_version: 1
directive: `INBOX-37 pre-authorized successor`
target: `x86_64-linux`
validation_tier: 2
result: pass

The accepted successor baseline is `12c1e3dc`, report state 443 selected / 235
emitting / 208 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`. The production and permanent-test
diff used for validation has sha256
`01e456f7cd04588cdb553886f129994d22e29d0c5223a5c82cfa24f9f8e5363f`.
The current-source ReleaseFast z_llvm has sha256
`2e1b6301b25d5b9f0bdaf4a81f2670994bae0bebfe8ccde619c48d4271a9f8f9`.

The composed selector admits only the exact
`llvm.ctlz.i64(i64, i1 immarg) -> i64` shape. Both legal immediate flags are
accepted; malformed value widths, non-i1 flags, non-literal flags, and
literals outside zero/one remain fail-closed. The lowering reuses the existing
`clz_i64_rdi_eax` machine and verifier operation. That operation computes the
0--64 result in RAX and its final 32-bit operation zero-extends the physical
register, so the selector records the typed i64 result as `.rax` rather than
misclassifying it as `.eax`.

Permanent exact-form coverage checks both legal flags and a malformed i32
payload. Selector/encoder/verifier execution covers zero, low and high single
bits, an interior single bit, and all-ones, with the i64 return observed
directly through the C ABI.

Fresh report-all remains 443 selected / 235 emitting / 208 failing; no closure
is claimed. A complete diff against the Part 1 report changes exactly the
eight directed rows and no others. Each advances from
`composed-block-llvm-intrinsic` to `composed-block-binary-width`:

- `compiler_rt.divdf3.__divdf3`;
- `compiler_rt.muldf3.__muldf3`;
- `compiler_rt.subdf3.__subdf3`;
- `compiler_rt.adddf3.__adddf3`;
- `compiler_rt.floatundidf.__floatundidf`;
- `compiler_rt.floatundisf.__floatundisf`;
- `compiler_rt.floatdidf.__floatdidf`;
- `compiler_rt.floatdisf.__floatdisf`.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=235 failed_functions=208 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused coverage: legal_flags=2/2 malformed_width_fail_closed=1/1 executable_cases=5/5
report delta: directed_frontier_advances=8 collateral_changes=0 closures=0
tier2: pass; steps=24/24 tests=945/945
tier3: not-triggered; no row closure, ABI change, object-writer change, or milestone boundary
```

Commands:

```text
zig build test structural-smoke --summary all
zig build install -Doptimize=ReleaseFast --prefix tmp/inbox37_ctlz64_install
tmp/inbox37_ctlz64_install/bin/z_llvm --emit=obj --target=x86_64-linux --passes=zig-debug-accepted --input-limit=67108864 --report-all-codegen-failures --generic-cfg-selector tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
```

Logs:

- `tmp/inbox37_ctlz64_report.log`, sha256
  `0aa658e770d9cf197f36f7cd1307af57bb3e548d484156a25573f95169f982e0`;
- `tmp/inbox37_ctlz64_tier2.log`, sha256
  `423dccf940efcf3f9eea92e865a4a84112f052ba97b2195e389b7e464e830634`.

The INBOX-37 pipeline is exhausted. Do not start `llvm.cttz.i64`; the tranche
order explicitly requires a separate directive for that capability.
