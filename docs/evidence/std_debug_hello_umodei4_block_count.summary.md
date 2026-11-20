# `__umodei4` Block-Count Frontier

schema_version: 1
z_llvm_base_commit: `2ad94d00`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `advanced`

The bounded stage-two CFG envelope increases from 64 to 128 blocks. The exact
captured `__umodei4` body has 65 blocks and remains within the existing frame
pressure envelope: 24 live values, 18 spill slots needed, and zero spill slots
over the 32-slot frame. The focused report-all retry advances to the next
independent selector form.

```text
summary stage2-pressure-diagnostic function=compiler_rt.udivmodei4.__umodei4 blocks=65 edges=115 no_spill_limit=6 spill_slot_count=32 spill_envelope_limit=38 max_live_values=24 max_block=Then15 max_boundary=198 max_spill_slots_needed=18 max_spill_slots_over_envelope=0 first_exceed_block=- first_exceed_boundary=- first_exceed_live_values=0 first_exceed_spill_slots_needed=0 first_exceed_spill_slots_over_envelope=0 local_fail=0
summary zllvm-codegen-report-all target=x86_64-unknown-linux-gnu selected_functions=443 emitted_functions=131 failed_functions=312 first_failing_function=compiler_rt.udivmodei4.__umodei4 first_failing_diagnostic=UnsupportedCodegenControlFlow first_failing_selector_tag=no_emitter first_failing_selector_detail=composed-block-call-form local_fail=1
```

Logs: `tmp/std_debug_hello_debug_umodei4_fresh_global.log` and
`tmp/umodei4_block128_retry.log`.
