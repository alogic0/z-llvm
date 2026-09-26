# Optimizer review repair plan

Starting revision: `771fa8d3`. Scope: the three confirmed project-review bugs
in SCCP, integer comparison folding, and GlobalOpt.

1. [x] Add failing regressions for SCCP loop call arguments, width-aware signed
   and equality comparisons, and globals referenced by module-level values.
2. [x] Keep SCCP's speculative call operands separate from the original IR until
   the lattice converges; preserve constant-call folding.
3. [x] Normalize integer comparison operands to their IR width, including i128,
   and retain unsigned ordering.
4. [x] Prevent GlobalOpt folding/removal when initializers, aliases, or opaque
   references can expose a global; preserve optimization of unescaped globals.
5. [x] Extend the native LLVM comparison harness and run focused regressions,
   unit/structural/storage tests, documentation checks, and readiness.
6. [x] Run the required full distribution integration gate and record results.

## Validation preflight

Use Zig 0.16.0 and LLVM 22. These are confirmed wrong-code repairs, so
[validation tiers](../validation_tiers.md) requires Tier 3. Previous runs
cannot validate the changed optimizer source and new regression inputs.
Reuse only the unchanged emitter's validated immutable AIR-export cache;
rerun all optimization, object, linking, and execution checks.

Evidence directory: `local-state/validations/optimizer-review-20260926/`.

```sh
/home/oleg/.zig/0.16.0/files/zig build distribution-all -- --serial \
  --serial-root=local-state/validations/optimizer-review-20260926/full \
  --real-rows-validation-root=local-state/validations/optimizer-review-20260926/project-improvement \
  --real-rows-cache-root=local-state/caches/project-improvement \
  --zig-emitter=/home/oleg/prog/ziglang/build/stage4/bin/zig
```

## Implementation and validation

The new unit tests reproduced all three review failures before the fixes. SCCP
now copies call argument storage before speculative substitution. Integer
comparisons use width-normalized bitpatterns and signed/unsigned interpretation.
GlobalOpt checks global initializers and aliases before folding or deleting a
global. For unparsed expressions containing symbol references, and for module
assembly, it conservatively skips the optimization; exact direct loads remain
distinct from possible opaque references.

Six new unit tests cover the failures and nearby boundaries, including positive
constant-call and unescaped-global optimization cases. The native comparison
runner now checks 16 functions in the focused pipeline and `release-o3`, with
explicit expected values and an independent LLVM 22 reference. Both passed.

Focused validation passed 1,422 unit tests, eight structural tests, nine storage
tests, and documentation checks (`focused.log`). Readiness passed
(`readiness.log`), including optimizer fixtures, the 16-function native
regressions, ABI comparisons, corpus/handoff checks, and generated behavioral
comparisons. The original review reproductions now return 1, 2, and 9 as
expected under `release-o3`, with LLVM verification passing.

Full integration passed (`distribution-all.log`, exit 0): all 17 subgates
reported success with `local_fail=0`, in 2,229,334 ms (37m 09s) wall time.
Each release mode lowered, emitted, and natively linked 100 compiler-core
functions and passed all four fixed-cohort executions. All three AIR-export
cache identities were verified hits; optimization, linking, and execution
checks ran again. Integrated objects/executables, release-object inspection,
native links/probes, and linker-boundary checks passed. The release-source
object bundle identity remained
`a5dcce564ade761f3cf47c9767f69615cdadbe0d6c2cc88419efaaf52e9518fa`.

Implementation and regression source hashes are recorded in `source.sha256`
in the evidence directory and match the validated working tree. Accepted-status
counters and support claims remain unchanged.
