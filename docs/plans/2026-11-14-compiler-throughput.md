# Measured compiler throughput improvement

Date: 2026-11-14
Status: complete at implementation `7e7a1063`; measurements and preservation accepted.
Baseline checkout: `43a509cc`; backend source matches accepted `dbf7ade0`.

Improve one measured backend bottleneck without changing admitted IR, ABI,
ownership, object contents or the accepted compiler behavior. The preceding
[compiler/self-rebuild plan](2026-11-11-complete-compiler-object-and-self-rebuild.md)
and [validation performance delivery](2026-11-09-validation-performance-improvement.md)
remain complete.

## Fixed workloads and measurements

- Original compiler: 8,928 definitions, 443,624,107 bytes, SHA-256
  `de26621926e7262000930b6f28dbb481fba2440be930faafd9fa8f0a4e6a504e`.
- Original Debug behavior: 7,874 definitions, 67,658,559 bytes, SHA-256
  `d8b983f4686a19acdf9f5bcc84c084b6fbc68e104e1671032509f7180c9aa02b`.
- Use tooling Zig 0.17.0, a ReleaseFast backend with symbols/frame pointers,
  x86_64 Linux GNU, CPU baseline, and the accepted postopt emission arguments.
- Keep commands, hashes, build receipts, phase profiles, sampling diagnostics,
  wall/CPU time and peak RSS outside build caches under
  `local-state/validations/compiler-throughput-20261114/`.
- Verify hardware counter access and decoded stacks on this host. Keep bounded
  interrupted profiles separate from completed object/ownership evidence.
- Measure throughput without hardware or compiler profiling. Warm up, alternate
  baseline/candidate runs and retain host load/pressure observations. Report the
  completed measurement scope explicitly; component timings do not establish a
  complete compiler speedup.

## Delivery

1. Profile both fixed workloads, then select one shared implementation change
   from the measured cost. Preserve the original checks and rejection boundaries.
2. Add focused tests for the actual invariant or algorithmic equivalence, then
   build baseline/candidate with matching settings and compare the complete
   fixed objects and ownership manifests exactly.
3. Apply the [validation tiers](../validation_tiers.md) for the changed subsystem.
   Record the trigger, command and reason unchanged results cannot be reused
   before any Tier-3 run. Do not expand acceptance counters.
4. Publish measurements and limitations, bind the accepted source and evidence,
   and update the handoff. Stop this slice after one qualified improvement.

Existing storage-retirement work is independent. Preserve its edits and all
accepted compiler inputs, executable identities and sealed evidence.

## Selected change

The fresh complete Debug behavior recording has 23,115 hardware samples, no
reported losses, and decoded caller stacks. Its object and ownership output
match acceptance exactly. Copying accounts for 41.01% of self samples; caller
views attribute substantial copying to address-owner removal on binding writes.
The bounded large-function recording separately confirms transaction snapshots
and repeated liveness work as remaining costs. Keep those larger changes out
of this slice.

Owner removal cannot fail, so it can compact the canonical owned records
without a speculative whole-domain copy. Empty dependency replacements use
that same removal path before constructing a replacement candidate. Nonempty
replacement validation, failure atomicity, transaction rollback snapshots,
identity ownership and all domain limits stay unchanged. Test borrowed owner
names, ordering, missing owners and independent copied domains before measuring.

## Completion

Three measurement pairs, after warming both variants, reduce median backend
emission for the fixed Debug input from 114.39 to 109.66 seconds (4.1%). Maximum
peak RSS is 1,329,124 versus 1,329,008 KiB. All eight measurement/warmup outputs
and owner manifests match acceptance exactly. Pair order is baseline/candidate,
candidate/baseline, baseline/candidate; profiling is disabled during measurement.

Both official unit modes pass 2,365 unit, 65 structural and two profile checks.
All 17 integration gates and both complete 225-population native suites pass. Fresh
complete original compiler, original runtime and separate Small-runtime objects
reproduce accepted hashes and ownership and pass census, ELF and ordered-event
audits. The main frozen source verifies after the terminal integration run.

Source-verified native comparisons preserve all 8,204 prior command outcomes and
3,399 backend artifacts per build, with zero additions or differences. All 6,696
native faults and 28 runtime faults are detected: 6,724 required controls total.
The qualified source snapshot verifies after terminal qualification. The committed
three-file source delta matches the built and tested candidate patch exactly.
Fixed acceptance populations and historical seals retain their prior scope.

See the [measurement and qualification evidence](../evidence/compiler_throughput_20261114.md)
and [machine-readable acceptance](../evidence/compiler_throughput_20261114.json).
The proposed successor is the [ReleaseSafe preopt behavior plan](2026-11-14-release-safe-preopt-behavior.md);
its implementation is outside this slice.
