# Named I1 Or Acceptance

schema_version: 1
directive: `INBOX-32`
target: `x86_64-linux-gnu`
validation_tier: 3
result: pass

The composed selector now admits the exact typed `or i1 %a, %b` form when
both operands are named predicate values. It reuses the existing scalar
scratch-register and value-location model; immediate operands, wider integer
OR forms, and non-integer forms remain fail-closed.

Permanent executable selector coverage evaluates all four truth-table inputs
through both operand orders. One function consumes the predicate in a branch
and the other in a select, for eight exact calls. Structural inspection also
proves that both paths contain the machine `or` operation. Focused near misses
prove that named/immediate i1 OR and named i8 OR still report
`composed-block-binary-width`.

Three directed captured rows now emit and pass a parser/printer-derived native
module with expected bits precomputed from the pinned Zig compiler-rt sources:

- `compiler_rt.log.log`;
- `compiler_rt.exp2.exp2f`;
- `compiler_rt.exp2.__exp2h`.

The native matrix executes 15 f64 log calls, 17 f32 exp2 calls, and 14 f16
exp2 calls. The 46 raw results match exactly across both zero signs,
subnormals, normal values, underflow and overflow boundaries, infinities, and
quiet/signaling NaN payloads. The half row links against the unchanged,
previously accepted INBOX-30 half conversion-helper object; this cycle makes
no new claim about those helpers.

Fresh report-all advances from 443 selected / 214 emitting / 229 failing to
443 selected / 221 emitting / 222 failing. In addition to the three directed
closures, these four emissions are collateral and carry no separate semantic
claim:

- `compiler_rt.fixunsdfdi.__fixunsdfdi`;
- `compiler_rt.fixunsdfsi.__fixunsdfsi`;
- `compiler_rt.fixunssfdi.__fixunssfdi`;
- `compiler_rt.fixunssfsi.__fixunssfsi`.

The pre-authorized successor row `compiler_rt.exp2.exp2` now stops at its exact
`icmp sgt i64 %value, -1` frontier (`composed-block-icmp-form`).

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=221 failed_functions=222 local_fail=1
focused tests: unit=919/919 named_i1_or_calls=8/8 fail_closed_near_misses=2/2 native_row_calls=46/46
tier2: pass; steps=24/24 tests=927/927 structural=8/8 assembly/encoding/object inspection=pass integrated_executable=5/5
```

Logs and artifacts:

- `tmp/inbox32_i1_or_report.log`, sha256 `0b3e8250648912c9f59aed301dea839b6a68e0a639c658f5e6e61ddd01ec884d`;
- `tmp/inbox32_i1_or_tier2.log`, sha256 `c59c8b83dd4b3408c591aa0a7e2301a5ecfbb87deba8cc99862949076ff4357c`;
- `tmp/inbox32_i1_or_reference.log`, sha256 `9efe907ffc95784dee7880dcfd6dea489eb2baa91423a01d82b4058d2fe9d981`;
- `tmp/inbox32_i1_or_rows.ll`, sha256 `6cce6730fb99cd5a988b5844bbfd97522f7e5d56f8bc71336dc67d620b6a2be6`;
- `tmp/inbox32_i1_or_rows.o`, sha256 `57dd2b0a32ca86084677dfbb026e92b431021b0eab50aaa8ed816ba71618b063`;
- `tmp/inbox32_i1_or_rows_acceptance`, sha256 `5a58808873250b0d786a8afc3bb268696b94b3a976b55c85a8973bebac970129`.

Tier 3 acceptance is recorded separately in
`docs/evidence/distribution_all_after_inbox32_named_i1_or.md`.
