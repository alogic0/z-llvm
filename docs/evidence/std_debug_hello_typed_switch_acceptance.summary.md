# Typed Integer Switch Acceptance

schema_version: 1
directive: `INBOX-27 Part 2`
target: `x86_64-linux-gnu`
validation_tier: 3
result: pass

The accepted baseline is commit `3716cbebda4459044cdd65e1ef91fe65ecbafe8f`
plus staged selector diff sha256
`48c8c7b777891f60cf3dff160617a3f9579f5423727df409fb09ec3e170753fd`.
The current-source z_llvm used for report and acceptance was built in an
isolated cache/prefix and has sha256
`e080dd50fb44859b09dd9ec98a05dce60de30cc594c78f81bc9a41c7862baa3a`.

The composed selector now lowers bounded integer `switch` terminators as
compare chains. Conditions are type-driven from i1 through i32, narrow values
are materialized once and masked to their declared width, and at most eight
unique constant cases are admitted. Case constants are normalized to the same
typed bit pattern, including negative narrow constants. The existing CFG edge
spill/restore authority remains responsible for transfers, and switch edges
into phi blocks remain fail-closed.

An unreachable default is omitted only for the captured masked-range proof:
the condition must be the named result of `and` with constant 3, cases 0, 1,
2, and 3 must all be present, and the default block must be plain
`unreachable` with no other incoming edge. The chain compares 0 through 2 and
jumps to case 3. Missing cases, extra incoming edges, indirect branches,
unsupported widths, and larger case sets remain fail-closed.

Executable selector tests cover the exhaustive i32 `and 3` form over inputs
0 through 7 and -1, an ordinary i16 switch reached through `trunc i32` with a
negative case and reachable default, and rejection of a missing masked case.
Repository tests pass 905/905.

Fresh report-all advances from 443 selected / 199 emitting / 244 failing to
443 / 202 / 241. `compiler_rt.sin.sinf`, `compiler_rt.cos.cosf`, and
`compiler_rt.sincos.sincosf` fully emit. The captured acceptance object uses
those exact bodies with debug records removed and external linkage restored;
it contains one `R_X86_64_PLT32 compiler_rt.rem_pio2f.rem_pio2f` relocation
per function and native-links with `zig build-exe -fno-lld`.

The native canary passes 12 exact cases for each scalar result and both
`sincosf` outputs. Eight direct cases cover signed zeros, signed minimum
subnormals, and finite polynomial/range paths. Four controlled large inputs
make the reducer return switch residues 0, 1, 2, and 3 with a fixed reduced
argument; all expected bits are precomputed and the reducer call count is
exactly 12. No host libm or runtime expected-value oracle participates.

Collateral advances are recorded without semantic claims. `compiler_rt.fma.fma`
and six EI-to-FP rows (`__floatuneidf`, `__floatuneisf`, `__floatuneihf`,
`__floateidf`, `__floateisf`, `__floateihf`) now stop at
`stage2-switch-phi-edge`. Six FP-to-EI rows (`__fixunsdfei`, `__fixunssfei`,
`__fixunshfei`, `__fixdfei`, `__fixsfei`, `__fixhfei`) now stop at
`composed-block-cast-from-not-int`.

```text
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=202 failed_functions=241
focused tests: unit=905/905 masked_switch=9/9 ordinary_i16_switch=5/5 missing_case_fail_closed=pass
native trig canary: status=0 functions=3 direct_cases=8 controlled_cases=4 switch_residues=0,1,2,3 reducer_calls=12 relocations=3 native_linker=zig-build-exe-fno-lld
tier2: pass; steps=21/21 structural=8/8 selected_zllvm_executable=146/146
tier3: pass; distribution-all subgates=17 local_fail=0
```

Logs: `tmp/inbox27_switch_tier2.log` (sha256
`25fc469fcd3657e68affa3bdc7bec21c91134c9ab3fc364a31f73ec83978c7f1`),
`tmp/inbox27_switch_report.log` (sha256
`423e528d8eefa21348486499b8351bbe80d4a5aed447ceda9170910187030c70`),
and `tmp/distribution_all_after_inbox27_typed_switch.log` (sha256
`84060b0fde34b032bebf3dcc8009a31b152da5c281841a7d530f875b3ee9c435`).
Acceptance IR: `tmp/inbox27_trig_switch_acceptance.ll` (sha256
`ccdee056e56cccec8309cd68c73151b38c84b7e716dfa901a2c0175891f8f571`).
Object: `tmp/inbox27_trig_switch_acceptance.o` (sha256
`c8e531b2c2e48e1b37901e27f5384633e8d16b6d34edd59f53ec2290f58d3855`).
Executable: `tmp/inbox27_trig_switch_acceptance` (sha256
`baebe6ba311ab8169271a60499d402c0e785f0dea52c3c6a215ca27c557f8d84`).

`INBOX-27` Part 2 is complete. No third capability is authorized; stop for
the plan's periodic review.
