# x86_64 Full-Product Fixed-Definition Binding

schema_version: 1
z_llvm_base_commit: `f89ff217`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `selector-visible RDX:RAX full-product definition relocation`
result: `pass`

The composed selector now prepares a full-product instruction by displacing
live RAX and RDX owners through the existing scalar/pair spill protocol. After
the instruction, it consumes both physical definitions together and binds the
i128 product to the allocation plan's ordinary register-pair or pair-spill
location. This follows the per-definition `defineVirtReg` invariant named by
INBOX-14: fixed physical definitions do not bypass the authoritative value
map.

Focused tests prove:

- live RAX and RDX-backed values are preserved before definition;
- RDX:RAX relocates to a planned register pair;
- RDX:RAX stores to a planned pair spill;
- selector-produced relocation code executes and returns both product halves.

Tier 3 was required by `docs/validation_tiers.md` because this changes the
selector allocation boundary. The previous result could not be reused because
it predates fixed-definition displacement and binding.

```text
zig build test: status=0
zig build distribution-all: status=0 subgates=17 local_fail=0
strict real rows: ReleaseFast=100 ReleaseSafe=100 ReleaseSmall=100
```

Log: `tmp/distribution_all_after_full_product_binding.log`.

The focused `__muloti4` row remains at
`no_emitter/composed-block-call-form`; report-all remains 443 selected, 136
emitted, and 307 failed. No tracker or ratchet moves.
