# INBOX-64 Selection-Owner Observability Stop

Status: **unaccepted ownership-movement stop; review requested**.

INBOX-64 is acknowledged by id. Work started from the Supervisor acceptance
HEAD `2c43624e` above accepted INBOX-63 commit `02d375a2`. The implementation
adds the provisional O0 `SelectionOwner` authority and a separate optional
manifest, but the live owner totals disagree with the historical accounting.
Per the directive, validation stopped before strengthened Tier 2 and no serial
Tier 3 was run.

## Delivered implementation

- `SelectionOwner` is distinct from unchanged `codegen_path` and has exactly
  `unassigned`, `composed_block`, `composed_cfg`, `legacy_envelope`, and
  `structural_fallback`.
- Composed ownership is committed by `SelectionTransaction` only after a
  selector returns `.selected`. Legacy and structural-fallback ownership is
  assigned after the final lowerer succeeds and before verification/return.
- A successfully returned generic-CFG function fails closed if ownership is
  still `unassigned`; manifest generation also fails closed on an unassigned
  emitted row.
- Both permanent selection-atomicity negative tests seed
  `legacy_envelope` and compare it during exact rollback-state validation.
- `--emit=selection-owner-manifest` is a separate, optional output. It sorts by
  the stable function-name row identity and does not enter mandatory summaries
  or ratchets.

The frozen two-run manifest is
[`inbox64_selection_owner_manifest.tsv`](inbox64_selection_owner_manifest.tsv).

## Determinism and live topology

Both manifest runs produced byte-identical output:

- SHA-256: `5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d`
- rows excluding header: `285`
- `unassigned`: `0`

| Owner | Live rows |
| --- | ---: |
| `composed_block` | 40 |
| `composed_cfg` | 127 |
| `legacy_envelope` | 17 |
| `structural_fallback` | 101 |
| **Total** | **285** |

The two report streams were also byte-identical (SHA-256
`49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681`)
and observed the unchanged diagnostic topology:

```text
summary zllvm-codegen-report-all target=x86_64-linux selected_functions=443 emitted_functions=285 failed_functions=158 first_failing_function=compiler_rt.trunc.truncl first_failing_diagnostic=UnsupportedLongDoubleAbi first_failing_selector_tag=unsupported_type first_failing_selector_detail=unsupported-return-type local_fail=1
```

This observation came from the optional manifest run and is not a strengthened
Tier-2 acceptance claim.

## Historical-ledger reconciliation

The historical `165 / 17 / 103` was net acceptance accounting, not an owner
trace. The older 120-emitting-row report represented 17 legacy rows and 103
rows then attributed to fallback. Against those same 120 stable row identities,
the live manifest now reports 7 composed rows, 17 legacy rows, and 96 fallback
rows. These seven older rows are now captured by composed selection:

- `compiler_rt.__negdf2` (`composed_block`)
- `compiler_rt.__negdi2` (`composed_block`)
- `compiler_rt.__negsf2` (`composed_block`)
- `compiler_rt.__negsi2` (`composed_block`)
- `compiler_rt.__negti2` (`composed_block`)
- `compiler_rt.count0bits.__ctzdi2` (`composed_cfg`)
- `compiler_rt.count0bits.__ffsdi2` (`composed_cfg`)

Conversely, five of the 165 net rows accepted after that report are live
structural-fallback rows rather than composed rows:

- `compiler_rt.cmp.__cmpdi2`
- `compiler_rt.cmp.__cmpsi2`
- `compiler_rt.cmp.__ucmpdi2`
- `compiler_rt.cmp.__ucmpsi2`
- `compiler_rt.int.__udivdi3`

Therefore the historical assumption moves by `+7 - 5 = +2` composed and
`-7 + 5 = -2` fallback, yielding the observed `167 / 17 / 101`. O0 did not
reorder selectors or alter precedence to force either split.

## Validation boundary and stop state

Completed bounded checks:

- the focused unsupported-after-mutation and mapped-error transaction tests
  passed with non-default owner restoration;
- `zig build` completed;
- the owner manifest was generated twice with byte-identical output;
- the four successful tags sum to 285 and no successful row is unassigned.

Not run because the INBOX-64 ownership-movement stop fired:

- strengthened Tier 2, including the full captured cohort, permanent canaries,
  real-program boundary, and accepted-object SHA-256 comparison;
- serial Tier 3.

The previously accepted object digest `061a64e4` is consequently a baseline,
not a new O0 acceptance result. No capability admission, selector reordering,
fallback retirement, diagnostic change, ratchet change, O1 work, sharding,
harness promotion, or X1 stage was performed. Review is required before any
further work.
