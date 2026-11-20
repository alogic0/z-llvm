# I64 Remainder Closure Re-Proof

schema_version: 1
directive: `INBOX-27` fix-forward before Part 2
contract_class: correctness closure re-proof
baseline_commit: `916694a6`
target: `x86_64-linux-gnu`
validation_tier: 2
result: pass

The alloca/spill collision audit invalidated the earlier structural closure of
`compiler_rt.int.__moddi3`: the captured body spilled its sign mask at frame
offset zero while its `__udivmoddi4` remainder out-parameter used the same
offset. This cycle adds both `__moddi3` and the sibling `__umoddi3` shape to the
permanent composed-selector executable canary.

The canary object contains the exact wrapper forms. `__umoddi3` allocates an
i64 remainder slot, calls `compiler_rt.int.__udivmoddi4`, and returns the loaded
remainder. `__moddi3` derives the dividend sign mask, computes unsigned
magnitudes, calls the same helper through its alloca-backed out-parameter, and
restores the signed remainder with xor/sub. A separately compiled helper object
provides the composed-path callee, so acceptance covers z_llvm object emission,
native linking, the call boundary, the repaired frame layout, and execution.

Exact executable cases:

```text
__umoddi3(123, 10)                         = 3
__umoddi3(0x8000000000000005, 7)          = 6
__umoddi3(0xffffffffffffffff, 16)         = 15
__moddi3(123, 10)                         = 3
__moddi3(-123, 10)                        = -3
__moddi3(123, -10)                        = 3
__moddi3(-123, -10)                       = -3
```

Validation:

```text
zig build test: pass
zig build distribution-zig-integrated-exe -- --mode=ReleaseFast:
  total=3 build_ok=3 run_ok=3 stdout_ok=3 exit_ok=3 local_fail=0
zig build distribution-zig-integrated-exe:
  total=5 build_ok=5 run_ok=5 stdout_ok=5 exit_ok=5 local_fail=0
```

Focused log: `tmp/inbox27_moddi3_closure_reproof.log`, sha256
`e0c99c6b8153d9d0f475bcf8027cc3cdf67026ff08d1c14ba8c03f9f7b51cefd`.
Repository-test log: `tmp/inbox27_moddi3_closure_reproof_tests.log`, sha256
`e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`.
Full permanent-canary log:
`tmp/inbox27_moddi3_closure_reproof_all_canaries.log`, sha256
`858acdb6d7a0dd8f1ea92f6a4cbfbb74223f317fada752f5181d7b4dd361bfa4`.

This restores the semantic closure claim for `__moddi3` and adds executable
semantic closure for the matching `__umoddi3` composed shape. It does not move
the accepted report-all counters.
