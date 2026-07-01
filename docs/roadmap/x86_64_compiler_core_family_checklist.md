# x86_64 Compiler-Core Family Checklist

This checklist tracks recurring AIR/backend families for the x86_64 Zig
compiler-core replacement path. It is not a per-function or per-instruction
task list. Each item should be closed by a reusable semantic/lowering/backend
abstraction, source-backed frontier rows, object/native-link/executable proof
where applicable, and refreshed inventory evidence.

Use `docs/working-cycle.md` for the worker loop. Use
`docs/roadmap/x86_64_compiler_core_inventory_priorities.md` for the latest
counts and first-source evidence.

## Completion Rule

A family is complete only when all applicable release modes have evidence for:

- typed/model-owned facts, with no AIR-text scraping or source-name sidecars;
- reusable lowering or backend support, not selected case-id handling;
- fail-closed diagnostics for unsupported subforms;
- x86_64 object emission without LLVM TargetMachine;
- Zig native linker handoff without LLD;
- executable proof for stable callable rows, or explicit boundary proof where
  execution is not meaningful;
- refreshed inventory showing the targeted unsupported bucket reduced or
  reclassified.

## Primary Families

The "first closure target" is the smallest meaningful slice that should reduce
the measured compiler-core bucket. It is not the whole family. It should be
large enough to prove the reusable abstraction and small enough to validate in
one worker cycle.

| Status | Family | Current priority | Main implementation layer |
| --- | --- | --- | --- |
| [ ] | aggregate ABI at scale | highest | semantic layout, ABI planner, backend |
| [ ] | error-union try/wrap/unwrap | highest | typed AIR facts, CFG lowering |
| [ ] | pointer/slice/address forms | high | typed AIR parser, address lowering |
| [ ] | aggregate-shape ops | high | aggregate semantic lowering |
| [ ] | union-tag shape | high | semantic lowering, CFG lowering |
| [ ] | optional shape | medium | semantic lowering, CFG lowering |
| [ ] | vector forms | medium | ABI planner, backend |
| [ ] | scalar transforms | medium | semantic lowering, backend |
| [ ] | safety runtime paths | medium | safety-edge CFG, runtime boundary |
| [ ] | float math | medium-low | backend, runtime boundary |
| [ ] | select shape | low but enabling | semantic lowering, CFG lowering |

## First Closure Targets

- aggregate ABI at scale:
  close structs, arrays, and slices in calls and returns beyond the selected
  frontier rows. The first target should include one direct call, one return,
  and one aggregate field/payload use that reaches object/native-link proof.
- error-union try/wrap/unwrap:
  close the high-count `unwrap_errunion_err`, `wrap_errunion_err`, and `try`
  forms first. Then add pointer and cold variants: `try_ptr`,
  `unwrap_errunion_err_ptr`, and `try_cold`.
- pointer/slice/address forms:
  close `ptr_slice_len_ptr`, `ptr_add`, `slice_ptr`, and
  `ptr_slice_ptr_ptr` first. Then add `is_non_null_ptr`, `ptr_sub`, and
  `runtime_nav_ptr` if inventory still shows them.
- aggregate-shape ops:
  close `slice_len`, `slice`, and `array_to_slice` as source-backed typed
  aggregate operations, not source-name special cases.
- union-tag shape:
  close `get_union_tag`, `union_init`, `set_union_tag`, and `tag_name`.
  Include at least one payload read and one switch/branch over the tag.
- optional shape:
  close generic `wrap_optional`, optional payload extraction, optional pointer
  checks, and non-selected catch/branch flows that still appear in compiler-core
  inventory.
- vector forms:
  close a narrow `shuffle_one` subset first, with fail-closed diagnostics for
  unsupported vector widths and element types. Then evaluate `reduce` and
  `splat`.
- scalar transforms:
  close remaining integer transforms after the selected scalar rows:
  `clz`, `ctz`, `popcount`, `shl_exact`, `shr_exact`, `bit_reverse`, `neg`,
  and broader widths/types for already-covered `byte_swap`, `max`, `min`, and
  `abs`.
- safety runtime paths:
  close checked overflow operations and ReleaseSafe runtime-call shapes:
  `add_with_overflow`, `sub_with_overflow`, `mul_with_overflow`, and
  `shl_with_overflow`.
- float math:
  classify each builtin as local lowering, runtime call, or explicit boundary.
  Start with `sqrt`, `floor`, `ceil`, `round`, and `trunc_float`; leave logs
  and trig as runtime/boundary until there is distribution evidence.
- select shape:
  close generic `select` for scalar integer and pointer values first. Vector
  selects belong with the vector family.

## Boundary And Backend Families

| Status | Family | Current priority | Expected policy |
| --- | --- | --- | --- |
| [ ] | packed aggregates | high boundary | implement common aligned forms; keep unsupported packed/unaligned forms fail-closed |
| [ ] | x87 surfaces | boundary | decide explicit boundary vs limited lowering for distribution-relevant uses |
| [ ] | varargs | boundary | implement or explicitly hand off C ABI varargs boundaries |
| [ ] | inline asm | boundary | preserve strict fail-closed diagnostics unless a real distribution row requires support |
| [ ] | debug metadata | boundary | keep transform skip/salvage policy explicit; do not count as codegen replacement |

## Per-Family Worker Template

For each unchecked family:

1. Refresh or read the latest focused inventory evidence for one mode first.
2. Pick the highest-count concrete pair with a real source-backed shape.
3. Add narrow typed-v2 hook facts in `../ziglang` only if z_llvm cannot derive
   the semantic operands safely.
4. Implement reusable z_llvm model/lowering/backend support.
5. Add 2-3 representative frontier rows, including one negative or boundary row
   when the family has unsupported subforms.
6. Prove the row with the focused frontier gate and object/native-link/executable
   checks.
7. Update counters and this checklist only after the relevant inventory bucket
   drops or is explicitly reclassified.

## Suggested Order

1. Error-union try/wrap/unwrap.
2. Pointer/slice/address forms.
3. Aggregate ABI at scale.
4. Aggregate-shape ops.
5. Union-tag shape.
6. Optional shape.
7. Safety runtime paths.
8. Scalar transforms.
9. Vector forms.
10. Packed aggregates.
11. Float math.
12. x87, varargs, inline asm, and debug metadata policy closure.
