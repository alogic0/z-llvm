# INBOX-53 Phase 4 Narrow-Return P0

schema_version: 1
directive: `INBOX-53 continuation, self-declared P0 correctness interrupt`
target: `x86_64-linux-gnu`
status: focused-pass, accepted-row audit-invalidated

## Defect And Repair

The specialized `zig.target.intByteSize` direct-call lowering bound an i16
return in EAX without clearing its ABI-undefined upper 16 bits. Subsequent
32-bit operations could consume those bits. The repair masks EAX to 16 bits
immediately after the call and aligns RSP for the otherwise frameless direct
call path.

A permanent executable selector canary patches the helper relocation to a
hostile stub returning `0xdead0020` in EAX. The selected i16 logical shift
must produce exactly 8 after normalization. The test fails on the prior code.

## Accepted-Row Audit

The defective call shape occurs in two previously accepted rows:

- `compiler_rt.udivmodei4.__udivei5`: i16 result followed by `lshr i16`;
- `compiler_rt.udivmodei4.__umodei4`: i16 result followed by `zext i16`.

Their historical executable summaries did not execute either row; they
described unrelated shared canaries. Those semantic closures are therefore
invalidated under the standing audit convention.

An extracted-row harness linked both current selector objects against an
assembly helper that returns low i16 `16` with hostile high EAX bits
`0xdead`. The exact 128-bit early-return case (`12345` divided by
`2^100 + 17`) passes for quotient and remainder, proving the repaired call
boundary is consumed correctly. A general case (`2^100 + 2^57 + 12345`
divided by `2^40 + 17`) does not pass: `__udivei5` reaches an invalid generated
array index (`0x80000001`) and faults. The same general failure reproduces
with the pre-repair accepted object, so it is a separate pre-existing
selector defect rather than a regression from this repair.

Result: this P0 repairs and permanently covers the narrow-return defect, but
does **not** re-accept `__udivei5` or `__umodei4`. Their row-exact semantic
closures remain invalidated pending a separate repair and a general-case
quotient/remainder matrix.

## Focused Validation

```text
zig build test --summary failures
result: pass (1024/1024 tests in the isolated P0 tree)

hostile-upper-bits selector canary
result: pass

extracted __udivei5/__umodei4 early-return semantic proof
result: pass (2/2 exact results)

extracted __udivei5 general semantic proof
result: fail (pre-existing generated-index defect; closure remains invalid)
```

The INBOX-53 Phase 4 cycle-2 capability is excluded from this standalone P0
commit. Immediate Tier-3 evidence:
`docs/evidence/distribution_all_after_inbox53_intbytesize_p0.md`.
