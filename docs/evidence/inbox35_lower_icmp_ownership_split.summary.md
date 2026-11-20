# Lower-Icmp Ownership Split

schema_version: 1
directive: `INBOX-35 interlude authorization`
target: `x86_64-linux-gnu`
validation_tier: focused structural interlude
result: pass

The composed selector's complete `lowerIcmp` implementation moved from
`composed_selector_scalar.zig` to the comparison-owned
`composed_selector_icmp.zig` module. The scalar module retains a public alias,
so implementation and test call sites are unchanged. The new module imports
only comparison dependencies; no predicate, diagnostic, instruction, or value
location behavior changed.

The old and new `lowerIcmp` function bodies have identical sha256
`bd4cfcd9fcd299aa957d9732cf87ad9ee89e4ecc73fa3826fd0518613142fa8e`.
The scalar module falls from 1,026 lines at the accepted baseline to 774 lines;
the comparison module is 271 lines.

```text
Build Summary: 6/6 steps succeeded; 938/938 tests passed
unit: 930/930
structural-smoke: 8/8
distribution-all: not run per the authorized move-only interlude contract
```
