# Half Pointer Store Acceptance

schema_version: 1
directive: `INBOX-35 pre-authorized successor`
target: `x86_64-linux`
validation_tier: 3
result: pass

The accepted successor baseline is `ac122f64`, report state 443 selected / 232
emitting / 211 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`. The production and permanent-test
diff used for validation has sha256
`926fa413f8940fd15b81f94a0ae58ec17832de4ee6d34f3a6ab4fb04c73462bc`.
The current-source ReleaseFast z_llvm has sha256
`fc731269283d3acb380a6e73643eccb006c68b086734105de5461c40c3d83e8d`.

The composed selector extends the accepted scalar FP pointer-store model to
`half`. Admission still requires the exact named pointer to be an ABI pointer
parameter recorded by the selector's single provenance authority. The half
payload is materialized in XMM0, moved bit-exactly into EAX, and stored with a
16-bit `movw` through the proven GPR pointer. Pointer spills continue through
the existing scalar frame/value-location path. Derived pointers, half stack
stores and loads, FP immediates, and all unproved targets remain fail-closed.

Permanent execution writes both output pointers for seven payloads covering
both zeros, minimum subnormal, a finite normal, infinity, a quiet NaN payload,
and a signaling NaN payload. All 14 stored words match exactly. Derived f32
and fp16 pointer stores remain rejected.

Fresh report-all advances from 443 selected / 232 emitting / 211 failing to
443 selected / 233 emitting / 210 failing. `compiler_rt.sincos.sincosh` is
the only new emission.

The row-exact object contains the captured `sincosh` body with external
linkage and four `R_X86_64_PLT32` relocations: `__extendhfsf2`, the dotted
`compiler_rt.sincos.sincosf` symbol, and two calls to `__truncsfhf2`. It
native-links through `zig build-exe -fno-lld` with the unchanged exact
dependency objects accepted for the typed-switch and `__trunch` closures. A
normal Zig `_start` executes 10 precomputed half inputs and checks both output
words, for 20 exact results. Cases cover signed zeros, signed minimum
subnormals, finite positive/negative normals, infinities, and quiet/signaling
NaN payloads. The controlled range reducer records zero calls; no runtime host
libm oracle participates.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=233 failed_functions=210 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
focused tests: unit=933/933 direct_f16_outputs=14/14 derived_pointer_fail_closed=2/2 native_sincosh_outputs=20/20 reducer_calls=0
tier2: pass; steps=24/24 tests=941/941 structural=8/8 selected object/executable modes=pass integrated_executable=5/5
tier3: pass; subgates=17 strict_real_rows=100/100/100 integrated_executable=5/5 release_source_link_probe=100/100
```

Logs and artifacts:

- `tmp/inbox35_half_store_report.log`, sha256
  `6994be49552ee52b20a622d3a072dbe8e88dc18baf94ac3a5b66871f6e4078ba`;
- `tmp/inbox35_half_store_tier2.log`, sha256
  `37ebae8543ad43630ea9c7335c879ed79a9342e414bf9a47b9e554578147462f`;
- `tmp/inbox35_sincosh_reference.log`, sha256
  `3338d460e0eaf3a97fd353aaa2a763e45a0a28939f6dff3faccde54dc49b9405`;
- `tmp/inbox35_sincosh_row.ll`, sha256
  `a755e55170e98df47559db26b9d19e73446f586d0f6636dcb55f6eb56be1069d`;
- `tmp/inbox35_sincosh_row.o`, sha256
  `b31c85f7f5fd57577cce599e0bc670ef6faed47b8c1ab9c94a66dbadd21c773b`;
- `tmp/inbox35_sincosh_readelf.log`, sha256
  `edf6c38e4a776fde839f169e93fffae9fbd414ae7923637d9dac1671369f4519`;
- `tmp/inbox35_sincosh_row_acceptance`, sha256
  `257fec2a0d089b11fe1a9ec50d2bd68a04f634dd0ecf9f3ad398d80fb61c3943`.

Tier 3 acceptance is recorded separately in
`docs/evidence/distribution_all_after_inbox35_half_pointer_store.md`.
The INBOX-35 pipeline is exhausted; stop for the fresh inventory and
vector-mask architectural checkpoint.
