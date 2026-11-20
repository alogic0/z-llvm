# Integer-Helper Bucket Closure Evidence

schema_version: 1
z_llvm_commit: `30cc6abd`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
result: `pass`

The historical integer cluster contains 45 non-tail selector rows and 21
integer-family `UnsupportedTailCallAbi` rows. The non-tail bucket is now fully
accounted for by 43 composed-selection rows plus the two integer
terminal-template rows, `__udivei4` and `__umodei5`.

```text
non_tail_integer_rows=45
composed_selection_rows=43
integer_terminal_template_rows=2
open_integer_selector_rows=0
report_all_emitted=163
report_all_failed=280
first_failing_function=compiler_rt.trunc.__trunch
remaining non-tail/non-unsupported-type failures=0
remaining integer UnsupportedTailCallAbi rows=21 (separate ABI family)
```

Source log: `tmp/std_debug_hello_i128_shift_acceptance.log`.

This is the standing INBOX-16 stop boundary. Work must not proceed into the
soft-float selector cluster without user direction.
