# Exact F32 Aggregate Stack-Object Acceptance

schema_version: 1
directive: `INBOX-42`
cycle: `pre-authorized-aggregate-object-successor`
target: `x86_64-linux`
validation_tier: 3
result: pass

The accepted baseline is `4e0645bf`, report state 443 selected / 247 emitting /
196 failing, captured compiler_rt IR md5
`b0eda7a6427c3084fdf096a68696f19c`, and stage4 pin
`bdee02bc0c7f227c0f11bc9a449df673fe803540`. The implementation-only staged
tree accepted by Tier 3 is
`943de086aa1c01775b2ad14c9a7324581fd72fcb`.

`aggregate_object.zig` is the shared typed decoder and read-only provenance
proof for exactly `{ float, float }`, including named module types. The existing
frame authority allocates one 8-byte, 4-aligned object and records a typed value
location with the object's base and current displacement. Constant byte GEPs
remain inside that object; 4-byte scalar stores and an offset-zero 8-byte packed
load are bounds checked against the same proof.

Pointer PHIs do not introduce an aggregate-pointer register class. Their
destinations remain ordinary existing 64-bit register or spill locations, and
the typed frame pointer materializes as `rsp + disp` on the existing edge path.
The allocation planner now applies its pressure-exemption policy to `phi_out`,
so frame-owned alloca/GEP sources cannot be reintroduced into register
allocation by CFG liveness. The verifier records the exact low-XMM width
defined by packed stack and pointer loads.

The permanent mmap executable creates two exact objects, writes both f32
fields, selects whole-object and second-field pointers through separate PHIs,
overwrites the selected second field, loads `<2 x float>`, and returns it through
the previously accepted packed aggregate ABI. Both branch outcomes preserve
raw signaling-NaN, signed-zero, minimum-subnormal, infinity, and quiet-NaN
payload bits. Five negative cases reject a three-field object, stronger object
alignment, an end-of-object scalar store, a mixed-offset pointer PHI, and a
packed load from the second field at their intended diagnostics.

Fresh report-all remains exactly 443 selected / 247 emitting / 196 failing.
Directed closures and collateral emissions are both zero. `__divsc3` advances
from aggregate alloca to its `llvm.maxnum.f32` intrinsic frontier, and
`__mulsc3` advances to `<4 x float>` construction. `__divdc3` and `__muldc3`
remain at their prior intrinsic and vector-construction frontiers.

Dynamic field offsets, other aggregate layouts or alignments, aggregate
parameters/calls, aggregate stores or copies, vectors wider than the exact
packed load, sret, fp80/fp128, and broader extractvalue/insertvalue forms remain
fail-closed.

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=247 failed_functions=196 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
report delta: directed_closures=0 collateral_emissions=0 new_failures=0
focused coverage: executable_branches=2/2 raw_result_fields=4/4 negative_boundaries=5/5
tier2: pass; steps=24/24 tests=970/970
tier3: pass; subgates=17/17 integrated_executable=6/6 local_fail=0
```

Commands:

```text
zig build test
zig build install -Doptimize=ReleaseFast --prefix tmp/inbox42_aggregate_object_acceptance_install
tmp/inbox42_aggregate_object_acceptance_install/bin/z_llvm --emit=obj --target=x86_64-linux --passes=zig-debug-accepted --input-limit=67108864 --report-all-codegen-failures --generic-cfg-selector tmp/udivmoddi4_ptr_null_cache/o/8c6b4a5e45095cb98b30ca8d3f251feb/libcompiler_rt_zcu.o.zllvm.ll
zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe --summary all
zig build distribution-all
```

Artifacts:

- `tmp/inbox42_aggregate_object_report.log`, sha256
  `55d0bc8bfda7d143fd52084495c8efa1d8c799a11a82a5a20fb0f03628f5d32a`;
- `tmp/inbox42_aggregate_object_tier2.log`, sha256
  `521013cb6ebdc35128bbdbe03232834915ca03ff41696b29174e0c76658a100f`;
- `tmp/distribution_all_after_inbox42_aggregate_object.log`, sha256
  `7cb780d87daa1a3b422231b9c4c8459829caf36c3d7aced5b316f85d93296bc3`.

The INBOX-42 pipeline is exhausted. Stop for review; no third capability cycle
is authorized.
