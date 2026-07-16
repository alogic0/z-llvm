# INBOX-93 binding-compatibility cross-product audit

Status: evidence-only audit completed on accepted B2A commit
`714af63799ce536827d1c85b778bb0b517c05054`, tree
`02d8e695d57984731a6c36ccd8100757e1fbd1cc`. No production source, action,
planner, guard, tool, or runner changed in this commit.

The uncommitted B2B stop state was preserved in stash
`INBOX-93 preserve B2B wiring plus five diagnosis tests`. Its original wiring
carrier re-applies cleanly against the accepted tree:

```text
patch=tmp/inbox92_store_perf/inbox92_store_wiring_hard_stop.patch
patch_sha256=6be43a125f2ab937365a02d54158b3c6a99181dc35892209c446d6140f26727b
git_apply_check=pass
```

The accepted diagnosis is committed unchanged as
`inbox92_o2_store_spill_value_diagnosis.md` (SHA-256
`a7e949c488c9fcf4d149ec43201b9edd7fd6002ce475b0f6d79fc5fcdc329dac`).

## Cross-product

`inbox93_o2_store_gep_binding_compatibility_audit.tsv` contains 34 classified
cells: 26 store cells and 8 already-wired GEP collateral cells. Its SHA-256 is
`6fc3e173713f7f5ac587323703c7221ae7ba3ec30c225880330be07969081248`.

The store cells cover:

- named and immediate i1/i32 values;
- named and rejected-immediate i64 values;
- exact gpr32/gpr64 and accumulator/register/spill homes;
- scalar GPR, spill, stack-object, stack-array, indexed stack-pointer, and
  readonly-table pointer operands;
- stack-object address source and destination operands for pointer stores; and
- FP/XMM/vector/aggregate, pair, reverse-width, and insufficient-width negative
  boundaries.

The accepted-cohort source was scanned by exact function identity. Cohort
groups S1-S7 in the TSV freeze 23 i1-named, 8 i1-immediate, 28 i32-named,
19 i32-immediate, 27 i64-named, 2 i64-immediate, and 15 ptr-named function
identities. The groups are identity sets, not occurrence counts; a function may
contain multiple matching stores. The exact `%236` row is separately pinned to
`compiler_rt.udivmodei4.__udivei5`, selector position 395, gpr64/64 binding,
spill slot 380, and accepted `reload_rsp_eax` low32 interpretation.

The GEP collateral cells cover exact gpr64 named indices, exact GPR and spill
pointer bases, stack-array/stack-pointer/readonly-table/f32-pair descriptors,
and constant action intent. GEP has no semantic-width coercion: every named
integer request remains i64/gpr64, every pointer request is exact, and every
descriptor request retains its canonical typed class.

## Stop-trigger decision

The audit found no heterogeneous accepted coercion. The only missing compatible
cells are homogeneous low-bit integer views:

```text
semantic request: integer width <= 32, form gpr32, class gpr32
binding: wider scalar GPR class whose defined width covers the semantic width
home: arg64 | scratch64 | rax | spill64, each with an existing low32 operation
interpretation: low semantic bits only; no sign/zero-extension claim
```

All pointer, FP/XMM, vector, aggregate, pair, reverse-width, insufficient-width,
and durable-relocation cases remain fail-closed. Therefore the directive's stop
trigger did not fire, and commit 2 may implement only the dormant canonical
binding/request compatibility relation. The five preserved diagnosis tests are
to be folded into that amendment's focused suite; production store wiring is
not restored in B2A2.
