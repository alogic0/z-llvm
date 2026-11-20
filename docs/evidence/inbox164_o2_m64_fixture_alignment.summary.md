# INBOX-164 — M64 fixture alignment

Status: complete for review. This is a test/evidence-only slice. Production,
Q1, actions, model, admission, guard policy, tools, build roots, and the
bypass inventory are unchanged. The direct-resolution ratchet remains
**140**. No performance command and no Tier 3 command was run.

## Scope and baseline

The accepted dormant M64 code baseline is `a93b2c82`; the accepted
INBOX-163 retention evidence is `f837fede`. Work began from authorization
HEAD `387dba4c60fa42cb2fb5afc5724614606e9caa82`.

The only test source changed is:

```text
src/codegen/x86_64/generic_cfg/composed_selector_scalar_tests.zig
```

The tracked evidence also adds this summary and the performance-omission
hash table. No production `.zig` file changed.

`SelectorAllocationPlan` canonically stores assignments and inclusive
interval ends; it does not store a separate interval-start map. Each
fixture binds its named values before the recorded current position.
Accordingly, the manifest records the exact stored end and whether it
covers the current instruction instead of inventing an unrepresented
start. No endpoint is `maxInt`.

Every fixture uses the real `SelectorAllocationPlan` representation and
the canonical empty address-dependency domain: zero owners and zero
edges. “Assignment” is planned physical storage; “binding” is the
canonical current home installed in the selector.

## Four-fixture manifest

### 1. `generic cfg selector materializes mul64 lhs into planned register`

```text
current_position=2
old:     assignment=gpr64/R8  interval_end=1 (expired) binding=scratch64/R8
lhs:     assignment=gpr64/RDI interval_end=2 (available at current) binding=arg64/RDI
rhs:     assignment=gpr64/RSI interval_end=2 (available at current) binding=arg64/RSI
product: assignment=gpr64/R8  interval_end=2 (result) binding=created scratch64/R8
dependencies=owners:0 edges:0
```

Intent: `old` is the allocator-visible expired occupant that makes R8
available for the current result; `lhs` and `rhs` are both consumed at
the current instruction. The expected stream and all bindings are
unchanged:

```text
mov_arg64_arg R8,RDI
imul_arg64_arg64 R8,RSI
```

### 2. `generic cfg selector reloads spilled mul64 rhs through rax when scratch registers are live`

```text
current_position=4
lhs:     assignment=gpr64/RDX interval_end=4 binding=scratch64/RDX
rhs:     assignment=spill/1   interval_end=4 binding=spill64/slot2
product: assignment=gpr64/RDX interval_end=4 binding=created scratch64/RDX
live_rdi: assignment=gpr64/RDI interval_end=10 binding=scratch64/RDI
live_rsi: assignment=gpr64/RSI interval_end=10 binding=scratch64/RSI
live_rcx: assignment=gpr64/RCX interval_end=10 binding=scratch64/RCX
live_r8:  assignment=gpr64/R8  interval_end=10 binding=scratch64/R8
live_r9:  assignment=gpr64/R9  interval_end=10 binding=scratch64/R9
dependencies=owners:0 edges:0
```

Intent: both operands end at their use, while every alternate scratch
register survives it. Planned spill index 1 canonically corresponds to
`slot2`. The expected stream and bindings are unchanged:

```text
reload_rsp_rax slot2
imul_arg64_rax RDX
result=scratch64/RDX
rhs=spill64/slot2
```

### 3. `generic cfg selector multiplies by an rax-resident i64 rhs`

```text
current_position=0
lhs:     assignment=gpr64/RDI interval_end=0 binding=arg64/RDI
rhs:     assignment=gpr64/RSI interval_end=0 binding=RAX
product: assignment=gpr64/RDI interval_end=0 binding=created scratch64/RSI
dependencies=owners:0 edges:0
near-miss: same plan/current position; rhs binding=EAX; diagnostic remains composed-block-mul64-rhs
```

Intent: both operands are consumed at the current instruction. The
planned RHS assignment records its semantic allocation identity while
the canonical current binding records the accepted prior staging in
RAX. This is the sole reviewed Option-A plan-visible correction; its
before/after proof is below.

### 4. `generic cfg selector reloads spilled mul64 lhs through rax when scratch registers are live`

```text
current_position=4
lhs:      assignment=spill/5   interval_end=4 binding=spill64/slot10
rhs:      assignment=spill/6   interval_end=4 binding=spill64/slot12
live_rax: assignment=spill/0   interval_end=10 binding=RAX before preservation, spill64/slot0 after
live_rdi: assignment=gpr64/RDI interval_end=10 binding=scratch64/RDI
live_rsi: assignment=gpr64/RSI interval_end=10 binding=scratch64/RSI
live_rdx: assignment=gpr64/RDX interval_end=10 binding=scratch64/RDX
live_rcx: assignment=gpr64/RCX interval_end=10 binding=scratch64/RCX
live_r8:  assignment=gpr64/R8  interval_end=10 binding=scratch64/R8
live_r9:  assignment=gpr64/R9  interval_end=10 binding=scratch64/R9
dependencies=owners:0 edges:0
```

Intent: both multiply operands end at current, every scratch register
and the accumulator occupant survive, and the allocator-selected spill
indices map to the installed even-numbered frame slots. The expected
stream and bindings are unchanged:

```text
spill_rax_rsp slot0
reload_rsp_rax slot10
imul_rax_rsp slot12
live_rax=spill64/slot0
result=RAX
```

## Option-A plan-visible correction

The RAX-resident-RHS fixture meets all five reviewed criteria.

1. The accepted pre-alignment fixture installed no plan.
2. The truthful `lhs`, `rhs`, and `product` intervals all end at
   `current_position=0`, so the operands are current-inclusive.
3. The accepted legacy register-conflict authority treats an interval
   ending at current as occupied. Therefore planned RDI cannot be
   clobbered before its LHS is consumed.
4. A detached fixture-minus-plan source and compiled unit artifact
   reproduce the old stream.
5. The sole movement is the deterministic selection of free RSI,
   staging LHS there, and retaining the result there. The RHS binding
   remains RAX and the near-miss diagnostic is unchanged.

Before, with no plan:

```text
instructions=[
  mov_arg_rax RSI,
  imul_arg64_rax RDI,
]
lhs=arg64/RDI
rhs=RAX
product=scratch64/RDI
following return move=mov_arg_rax RDI
```

After, with the truthful plan:

```text
instructions=[
  mov_arg_rax RSI,
  mov_arg64_arg RSI,RDI,
  imul_arg64_rax RSI,
]
lhs=arg64/RDI
rhs=RAX
product=scratch64/RSI
following return move=mov_arg_rax RSI
```

The detached proof came from HEAD
`387dba4c60fa42cb2fb5afc5724614606e9caa82`. The copied source contains
the no-plan fixture and its old stream assertions. The compiled unit
artifact was retained read-only, run directly, and the detached
worktree was then removed. No permanent plan-blind correctness fixture
was added.

```text
plan_blind_source=tmp/inbox164_o2_m64_fixture_alignment/plan_blind_proof/composed_selector_scalar_tests.zig
plan_blind_source_sha256=b6cc545e629291bf82cf9527df7d2327e4a0dfaa7f92cab21956035b7e40e995
plan_blind_unit_artifact=tmp/inbox164_o2_m64_fixture_alignment/plan_blind_proof/unit_tests_no_plan
plan_blind_unit_artifact_sha256=e15c0cc74656bf06733502d708bd7d8b35d3b65670dfc56f94a96f0547e5e327
plan_blind_unit_artifact_bytes=121371149
command=tmp/inbox164_o2_m64_fixture_alignment/plan_blind_proof/unit_tests_no_plan 2>&1 | tee tmp/inbox164_o2_m64_fixture_alignment/plan_blind_proof/unit_tests_no_plan.log
result=1365/1365 tests passed
log_sha256=4035a5ede37144704c56ea889c95e5b7cde57bd8e28c2f037188eaeb26c231f1
```

The other three fixtures retain their exact pre-alignment instruction
streams, bindings, and diagnostics. No other Option-A exception was
required.

## Production hash identity and performance omission

Performance is omitted because every production source, tool, build
configuration/root, and facade is byte-identical to the accepted
ratchet-140 authorization tree. The complete 424-row proof is tracked
in
`docs/evidence/inbox164_o2_performance_omission_hash_contract.tsv`.

```text
command=/home/oleg/bin/zig run tmp/inbox148_o2_checkpoint_slice4/hash_contract.zig -- 387dba4c docs/evidence/inbox164_o2_performance_omission_hash_contract.tsv 2>&1 | tee tmp/inbox164_o2_m64_fixture_alignment/validation/performance_omission_hash_contract.log
result=424/424 identical
production=311
tools=72
build_configuration=1
build_roots=37
facades=3
table_sha256=e56b04a50bd698ee3da989916b3560365b48ba19586113cd2dcd8bd85b4fbf04
log_sha256=cd53864fbf18d416f92b987030ad434a8c3729a8ea5b7defde138bc323ec0921
```

## Decisive identities

Commands:

```text
command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --report-all-codegen-failures --target=x86_64-linux --input-limit=67108864 tmp/inbox92_second_resume2_perf/compiler_rt_frozen.ll > /dev/null 2> tmp/inbox164_o2_m64_fixture_alignment/validation/fresh_full_report.log

command=LC_ALL=C zig-out/bin/z_llvm --emit=obj --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox164_o2_m64_fixture_alignment/validation/accepted.o 2> tmp/inbox164_o2_m64_fixture_alignment/validation/accepted.stderr

command=LC_ALL=C zig-out/bin/z_llvm --emit=selection-owner-manifest --generic-cfg-selector --target=x86_64-linux --input-limit=67108864 tmp/inbox63_accepted_cohort.ll > tmp/inbox164_o2_m64_fixture_alignment/validation/owner_manifest.tsv 2> tmp/inbox164_o2_m64_fixture_alignment/validation/owner_manifest.stderr

command=/home/oleg/bin/zig run tmp/inbox142_family_isolation/compare_elf_functions.zig -- tmp/inbox163_o2_multiply_isolation/results/baseline/accepted.o tmp/inbox164_o2_m64_fixture_alignment/validation/accepted.o > tmp/inbox164_o2_m64_fixture_alignment/validation/function_diff.tsv
```

Results:

```text
report_sha256=49a19f04ad9f5cddf82a9464c74216c0284b1f8600448a1669ee4f6c38415681
report=443 selected / 285 emitted / 158 failed
first_failure=compiler_rt.trunc.truncl/UnsupportedLongDoubleAbi
object_sha256=061a64e4241c92be1fafbdd9800f00cd3ac7bd1d2d3bef460d79ea1d5a32a0be
owner_sha256=5d91960e5a01a0e6387f7ef2894dae4a1de93d2ce648c28377f97cd4afa0229d
owner_ledger=40 composed_block + 127 composed_cfg / 17 legacy / 101 structural
accepted_stderr_bytes=0
owner_stderr_bytes=0
per_function=285 compared / 0 divergent / 0 missing
per_function_log_sha256=aa378a2733f9b5bbd9160016942ab69a57da10672b1a0b94eabb13b9ff359240
```

## Correctness gates

All commands ran against the final test source state. Logs are retained
under `tmp/inbox164_o2_m64_fixture_alignment/validation/`.

### Full unit

```text
command=/home/oleg/bin/zig build test --summary all 2>&1 | tee tmp/inbox164_o2_m64_fixture_alignment/validation/full_unit.log
result=7/7 steps; 1365/1365 tests passed
log_sha256=db5d3a7edef39a71a1372ad7cbccf681047b5aa6716531ebb7205bf56fd8783e
```

### Source guard

```text
command=/home/oleg/bin/zig test src/codegen/x86_64/generic_cfg/composed_selector_source_guard_tests.zig 2>&1 | tee tmp/inbox164_o2_m64_fixture_alignment/validation/source_guard.log
result=55/55 tests passed
log_sha256=610cf0022a86aaaaebdb9eeb39ce1615ac1e1fb4a3bcf4642e040fa18b1667f6
```

### ABI differential

```text
command=/home/oleg/bin/zig build abi-differential --summary all 2>&1 | tee tmp/inbox164_o2_m64_fixture_alignment/validation/abi_differential.log
result=5/5 steps; 60/60 cases; 30/30 real functions
log_sha256=164a09c506f729addcd4a95328b6b83ce270fd5f43f07d1a07077f900ebbdd87
```

### Focused codegen canaries

```text
command=/home/oleg/bin/zig build focused-codegen-canaries --summary all 2>&1 | tee tmp/inbox164_o2_m64_fixture_alignment/validation/focused_canaries.log
result=2/2 canaries; 35 execution cases; fma and __multi3 object/stream/symbol/helper checks exact
log_sha256=d704046eacfa8c3c2cf852ed97c86ab42b5a6a07dcfe4dd7de48cb870f2292c6
```

### Integrated executable

```text
command=/home/oleg/bin/zig build distribution-zig-integrated-exe --summary all 2>&1 | tee tmp/inbox164_o2_m64_fixture_alignment/validation/integrated_exe.log
result=2/2 steps; 7/7 build/run/stdout/exit
log_sha256=af4778377ef98ce4f68de8b4e2ee80628a4b9db424df668e7076eeedf199abab
```

### Strengthened Tier 2

```text
command=/home/oleg/bin/zig build test structural-smoke compare-codegen-asm compare-codegen-objdump compare-codegen-readelf distribution-object distribution-executable distribution-debug-object distribution-debug-executable distribution-releasesafe-object distribution-zig-integrated-exe abi-differential --summary all 2>&1 | tee tmp/inbox164_o2_m64_fixture_alignment/validation/tier2.log
result=29/29 steps; 1373/1373 tests passed; integrated-exe 7/7; ABI 60/60 + 30/30
log_sha256=2e4c7a0b8d02cdb0b4a2d93b08b87cd45f145ff64833eb73941b2ac108ff5761
```

## Review boundary

INBOX-164 changes fixture truthfulness only. M64 remains wholly retained,
production stays legacy-routed, the ratchet remains 140, and re-isolation
has not begun. `stash@{0}` and all preserved patches are untouched.
No authorized or acceptance-grade Tier 3 was run.
