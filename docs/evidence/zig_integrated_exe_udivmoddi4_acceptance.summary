# Executable `__udivmoddi4` Evidence

schema_version: 1
z_llvm_base_commit: `770c7a22`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The standalone exact executable validates five quotient/remainder control-flow
paths. The permanent arithmetic canary also preserves its framed spilled-phi
loop result, proving that canonical phi frame destinations remain stable across
lexically later backedges.

```text
summary zig-integrated-exe total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 minimal_inline_asm_syscall_rows=3 compiler_rt_i128_arithmetic_rows=1 setcc_predicate_rows=1 local_fail=0
summary zig-integrated-object pipeline=postopt ir_writer=false total=146 executable_ok=146 link_only_ok=0 local_fail=0
exact __udivmoddi4 executable: status=0 cases=5/5
```

Logs: `tmp/selector_tier2_udivmoddi4_acceptance_exe.log` and
`tmp/selector_tier2_udivmoddi4_acceptance_object.log`.
