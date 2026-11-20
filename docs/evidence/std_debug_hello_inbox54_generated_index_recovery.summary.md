# INBOX-54 Generated-Index Correctness Recovery

schema_version: 1
directive: `INBOX-54`
target: `x86_64-linux-gnu`
status: focused-pass, tier-3-accepted

## Defect And Repair

The accepted `compiler_rt.udivmodei4.__udivei5` object faults in its general
division path for dividend `2^100 + 2^57 + 12345` and divisor `2^40 + 17`.
At the first invalid access, GDB records `RCX=0x80000001` at:

```text
mov 0x1b94(%rsp,%rcx,4),%eax
```

The bad index originates in IR value `%158 = sub nuw i64 %.0377.lcssa,
%.0376.lcssa.fr`, the `m - n` incoming value for Loop4 PHI `%.0373`. Selection
kept `%158` live in RAX, then a local-stack `i32` load overwrote EAX without
using the selector's accumulator-clobber authority. The later PHI edge copied
the stale mixed-width RAX value and generated the invalid index.

The shared repair makes `appendLoadStackI32` call the existing
`clobberAccumulator` authority before any EAX-writing stack load. There is no
function-name admission or separate register authority. A permanent JIT
regression keeps an i64 subtraction live only through a PHI edge, performs a
stack `i32` load of `0x80000000`, and proves that the PHI still returns the
subtraction.

## Exact Native Matrix

The permanent integrated executable now selects and native-links exact
debug-stripped bodies from the captured compiler_rt module (source md5
`b0eda7a6427c3084fdf096a68696f19c`). It executes:

- 13 unsigned 128-bit cases through both `__udivei5` and `__umodei4`;
- 7 signed 128-bit cases through each of `__divei4`, `__divei5`, `__modei4`,
  and `__modei5`.

The 54 exact operations cover zero, dividend-smaller-than-divisor, equality,
ordinary multi-limb division, 32/64-bit divisor boundaries, all-one limbs,
`0x7fffffff`/`0x80000000`/`0xffffffff` transitions, all signed operand-sign
combinations, and signed-minimum input. Quotients and remainders are checked
limb-for-limb against constants independently verified with arbitrary-
precision integer arithmetic and truncation toward zero.

The combined matrix linked against all six pre-repair accepted objects faults
with SIGBUS (exit 135). The same harness linked against the repaired objects
exits 0. The normal permanent `distribution-zig-integrated-exe` ReleaseFast
case also exits 0.

## Accepted-Row Audit

The captured accepted-row inventory was searched for local stack `i32` loads,
then each exact candidate body was emitted independently before and after the
repair and object-compared:

```text
__udivei4  identical    __udivei5  changed
__umodei4  changed      __umodei5  identical
__divei4   changed      __divei5   changed
__modei4   changed      __modei5   changed
```

Therefore the repaired shape genuinely occurs in six accepted rows. All six
join the row-exact executable matrix. The two byte-identical unsigned siblings
need no re-proof. The only additional captured textual candidate,
`rem_pio2_large`, fails closed under exact extraction at its existing pressure
boundary, so it is not an accepted hit and creates no invalidated closure.

This re-accepts the semantic closures of `__udivei5` and `__umodei4`, which
were invalidated by the INBOX-53 narrow-return audit, and re-proves the four
signed siblings. Object-emission counters do not move.

## Focused Validation

```text
zig build test --summary failures
result: pass

zig build test structural-smoke compare-codegen-asm compare-codegen-objdump
  compare-codegen-readelf distribution-object distribution-executable
  distribution-debug-object distribution-debug-executable
  distribution-releasesafe-object distribution-zig-integrated-exe --summary all
result: pass; 24/24 steps, 1027/1027 tests

zig run tools/run_distribution_zig_integrated_exe.zig -- --mode=ReleaseFast
result: pass; 4/4 native executables, including the 54-operation matrix

compiler_rt report-all
result: unchanged; 443 selected / 284 emitting / 159 failing
```

Artifacts:

- Tier 2 `tmp/inbox54_tier2.log`, sha256
  `4f2d76ecb7cd9ca7327a12931b898c58bcde8d3f9a0e935f096ac2229f50adf8`;
- report `tmp/inbox54_report.log`, sha256
  `590d86d38a305a475732a6ca46eb0aa99eef6dcda847eb581a2280f438813614`;
- exact unsigned fixture, sha256
  `89a516050b4994e60a98c1fdd5a540b0f58ef830f1589514a3e65292226d09de`;
- exact signed-division fixture, sha256
  `9c0eba56d9964fa691a9b5d08030c96ed84bf5a651c4e4f5478eb03390b643a5`;
- exact signed-remainder fixture, sha256
  `ba172cd6f6c8b5b6e7a9c7a14c00de62a60b9996d6d005b7ffcbbbdf5a8f0cc8`.

Immediate Tier-3 acceptance is recorded separately in
`docs/evidence/distribution_all_after_inbox54_generated_index_recovery.summary.md`.
