# INBOX-92 spill-value diagnosis

Status: diagnosis only; no remedy is authorized or included. The preserved B2B
wiring remains uncommitted.

## Frozen subject

- Accepted B2A source commit: `714af63799ce536827d1c85b778bb0b517c05054`
- Accepted B2A tree: `02d8e695d57984731a6c36ccd8100757e1fbd1cc`
- Dispatch-only HEAD during diagnosis: `9109276fe509e48bcd766c01002273eea117ff33`
- Preserved wiring carrier:
  `tmp/inbox92_store_perf/inbox92_store_wiring_hard_stop.patch`
- Preserved wiring SHA-256:
  `6be43a125f2ab937365a02d54158b3c6a99181dc35892209c446d6140f26727b`
- GDB binding trace:
  `tmp/inbox92_store_perf/trace_value_binding.log`
- GDB binding-trace SHA-256:
  `cc4fe14d75370c371b408a9f9165f393f3fd2b329c2278be459d89e8145a067f`

## Result

This proves fork **(b)**. The stop is not premature expiry during preparation.
The existing `.gpr32` request accepts a `.spill64` physical home and emits the
accepted 32-bit reload when the binding has `gpr32` virtual-register metadata.
The actual `__udivei5` value instead reaches the store as a `gpr64/64` binding in
that spill home. The closed request model cannot describe that binding as the
32-bit semantic store operand:

1. The current B2B consumer precheck sees `gpr64` and returns
   `composed-block-store-value-spill` before registering either request.
2. Directly registering the intended `i32/.gpr32` request succeeds, but `seal()`
   raises `error.ValueUseRegisterClassMismatch` at
   `ValueUseTransaction.validateRequest` after the at-or-after liveness check has
   already passed.
3. Registering the observed `.gpr64` class instead also succeeds, but `seal()`
   raises `error.ValueUseTypeMismatch`: a `.gpr32` use form is deliberately valid
   only with a `gpr32` expected class.

Accordingly, the separately reviewed remedy fork is B2A2 plus the complete
operand-home/type/class cross-product re-audit. This diagnosis does not authorize
a lifecycle amendment, consumer predicate, or production behavior change.

## Actual row and binding

The failing IR is the final scalar store at selector position 395:

```llvm
%233 = load i32, ptr %166
%234 = zext i32 %233 to i64
%235 = sub nsw i64 %234, %.lcssa468
%236 = trunc i64 %235 to i32
store i32 %236, ptr %166
```

The allocation-plan probe and GDB trace recovered:

| Field | Actual value |
| --- | --- |
| Store value | `%236` |
| Current selector position | `395` |
| Live interval end | `395` (at-current, not after-current) |
| Planned assignment | `gpr32/r8` |
| Bound virtual register | index `325`, class `gpr64`, bits `64` |
| Bound physical home | `.spill64`, frame slot `380` (`0x5f0(%rsp)`) |

The metadata originates in the accepted alias-only trunc path. `lowerCast`
preserves a `.spill64` location for a greater-than-32-bit to 32-bit trunc and
calls `bindValueLoc`; a new binding derives its class/bits from that location,
and `.spill64` has `gpr64/64` metadata. Thus `%236` retains the source-width
virtual class even though the IR result and allocation plan are 32-bit.

The accepted object proves the physical operation itself is expressible. The
relevant stream is:

```text
4f80: mov 0x5f0(%rsp),%eax
4f87: mov 0x798(%rsp),%rcx
4f8f: mov 0x708(%rsp),%r8
4f97: add %r8,%rcx
4f9a: mov %eax,0x1b94(%rsp,%rcx,4)
```

That is exactly value reload, pointer base reload, pointer index reload/add, and
store. No new spill-source materializer is needed; the missing part is an
approved typed view of the actual binding metadata.

## Phase record

The direct phase reproduction uses the observed `gpr64/64 + spill64` binding and
the same at-current interval boundary.

| Phase | Actual binding and request state | Result |
| --- | --- | --- |
| Consumer entry | `%236`: vreg 325, `gpr64/64`, `.spill64` slot 380, end/current `395/395`; transaction has 0 requests and phase `.registering` | The current consumer precheck returns the mapped spill diagnostic before request registration. |
| Registration (direct reproduction) | Binding unchanged; pointer and value action are both registered; request count 2; phase `.registering` | Registration succeeds without mutation. |
| Seal with semantic `gpr32` request | Binding unchanged; request count 2; phase remains `.registering`; instruction count 0 | Liveness validation passes, then `ValueUseRegisterClassMismatch` is raised. |
| Seal with observed `gpr64` expected class | Binding unchanged; request count 2; phase remains `.registering`; instruction count 0 | Class check passes, then `ValueUseTypeMismatch` is raised by the `.gpr32` form/type contract. |
| Prepare | Not entered for the actual binding | The error precedes preparation, so preparation cannot have dropped the source. |
| Materialization/action | Not entered for the actual binding | No instruction or selector state is mutated. |

The valid control records every later phase using an at-current `gpr32/32`
binding in `.spill64`:

| Phase | Control request/binding state |
| --- | --- |
| Registration | 2 requests; `.registering`; source binding unchanged in spill slot 0. |
| Seal | `.sealed`; source binding unchanged. |
| Prepare | `.prepared`; source binding unchanged. `prepare()` temporarily enables `preserve_current_position_values`, so ending-at-current sealed operands remain available. |
| Materialization | `.materialized`; source binding unchanged. |
| Action/commit | Emits `reload_rsp_eax`, indexed-pointer reload, then store, with no durable source rebind. |

## Focused coverage

Uncommitted diagnosis tests cover:

- the exact production `lowerStore` path with an at-current spilled scalar value
  and indexed/spilled pointer, asserting `reload_rsp_eax` ->
  `reload_arg64_rsp rcx` -> indexed store;
- a spill-backed value live after the store, reloaded exactly once and retaining
  its binding;
- failure after preparation, proving instructions, bindings, dependency domain,
  and EFLAGS roll back exactly;
- the actual binding-class seal failure and the alternative expected-class type
  failure, both before mutation;
- successful request state and unchanged binding through registration, seal,
  preparation, and materialization for the valid `gpr32/.spill64` control.

`zig build test` result after the diagnosis tests: `1151/1153` passed. All five
INBOX-92 diagnosis tests pass. The two remaining failures are the already-known
incomplete-B2B source-guard ratchet and the pre-existing uncommitted i64 spilled-
pointer wiring test; neither is part of this root-cause fork. The build's bundled
ABI differential completed `60/60 + 30/30`; this was incidental to running the
unit target, not B2B acceptance evidence. No cohort, canary, Tier 2,
performance-after, or Tier 3 gate was run for this diagnosis-only stop.
