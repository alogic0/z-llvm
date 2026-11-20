# Tier 2 Selector Validation

schema_version: 1
z_llvm_base_commit: `e9f22b95`
ziglang_pin: `bdee02bc0c7f227c0f11bc9a449df673fe803540`
change: `composed signed i6 greater-than negative one`
result: `pass`

```text
focused selector test: status=0 tests=10/10
zig build test: status=0 tests=735/735
zig build structural-smoke: status=0
zig build distribution-object: status=0 rows=38
zig build distribution-releasesafe-object: status=0 rows=9
zig build distribution-zig-integrated-exe: status=0 rows=5
zig build distribution-boundary: status=0
```

Tier 3 was not required for this focused selector form.
