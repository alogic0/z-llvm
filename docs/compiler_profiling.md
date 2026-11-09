# Compiler profiling

Use hardware sampling when investigating compiler throughput, together with
the existing `--profile=PATH` phase and allocation instrumentation. Run the
preflight below before concluding that hardware sampling is unavailable.
Attribute current bottlenecks using a compiler built from the current source.

## Host preflight

Run from the repository root on the host where compilation will execute:

```bash
uname -r
perf --version
cat /proc/sys/kernel/perf_event_paranoid
perf stat -e cycles:u,instructions:u -- true
```

R780M was verified on 2026-11-09 with `kernel.perf_event_paranoid=2`.
This setting permits per-process user-space profiling while restricting kernel
profiling; use explicit `:u` events. See the
[kernel access-control documentation](https://docs.kernel.org/admin-guide/perf-security.html).
The `true` command checks counter access; a real recording must also verify
samples and decoded stacks.

If access is denied, the host setup used here is:

```bash
sudo sysctl kernel.perf_event_paranoid=2
```

That command changes the running setting. To retain it after reboot:

```bash
printf '%s\n' 'kernel.perf_event_paranoid = 2' |
  sudo tee /etc/sysctl.d/99-z-llvm-perf.conf
sudo sysctl --load=/etc/sysctl.d/99-z-llvm-perf.conf
```

Persistence has not been confirmed by a reboot test. Check access on each host
and after reboot. If recording still fails, retain the exact command, exit
status and error with the run, then use the built-in profiler for the available
diagnostics. Historical reports of `perf_event_paranoid=4` remain evidence about
their original runs.

## Record the current compiler

Use the pinned Zig 0.17.0 and a ReleaseFast compiler with debug symbols and
frame pointers retained. Install into a new run directory so the ordinary
`zig-out` installation is preserved. The following Bash example uses the
retained Safe Fibonacci IR; input mode and compiler build mode are independent.

This input is local retained state, not a checked-in fixture. Check that it is
present before building. If absent, select another verified retained input or
use the [fixture capture workflow](environment.md). Keep the chosen input and
invocation identical across a comparison.

```bash
set -euo pipefail
profile_input=local-state/validations/zig-input-20261106/fibonacci/ReleaseSafe/capture/object-input.ll
test -r "$profile_input"
mkdir -p local-state/validations
profile_run=$(mktemp -d local-state/validations/compiler-perf.XXXXXX)
zig build -Doptimize=ReleaseFast --prefix "$profile_run/compiler"
profile_compiler="$profile_run/compiler/bin/z_llvm"

git rev-parse HEAD > "$profile_run/revision.txt"
git diff --binary -- src build.zig .zigversion > "$profile_run/source.patch"
sha256sum "$profile_compiler" "$profile_input" > "$profile_run/identities.sha256"
perf --version > "$profile_run/perf-version.txt"
uname -r > "$profile_run/kernel.txt"
cat /proc/sys/kernel/perf_event_paranoid > "$profile_run/perf-event-paranoid.txt"

profile_status=0
timeout --signal=INT --kill-after=5s 120s \
  perf record -e cycles:u -F 199 --call-graph fp --user-callchains \
  -o "$profile_run/perf.data" -- \
  "$profile_compiler" --generic-cfg-selector --codegen-reachable \
  --target=x86_64-unknown-linux-gnu --input-limit=67108864 --emit=obj \
  --selection-owner-output="$profile_run/owners.tsv" \
  "$profile_input" > "$profile_run/output.o" 2> "$profile_run/record.log" || profile_status=$?
printf '%s\n' "$profile_status" > "$profile_run/exit-status.txt"
test "$profile_status" -eq 0

perf report --stdio --no-children -g none \
  -i "$profile_run/perf.data" > "$profile_run/self.txt"
perf report --stdio --no-children --percent-limit 5 -g graph,5,caller \
  -i "$profile_run/perf.data" > "$profile_run/callers.txt"
perf script --max-stack 16 -i "$profile_run/perf.data" > "$profile_run/stacks.txt"
printf 'Profile saved in %s\n' "$profile_run"
```

Save the actual invocation with the run, including any changed flags, time
limit and untracked source inputs. Treat object and ownership output as
unverified after a timeout or nonzero exit; retained samples can still help
diagnose the interrupted interval. Choose an explicit longer limit for a larger workload.
For accepted evidence, follow the existing
[retention contract](zllvm_artifact_retention_contract.md).

## Verify and interpret the recording

Check `record.log` for sample counts, `self.txt` for lost samples and named
functions, and `stacks.txt` for multiple named caller frames from compiler work.
An empty recording or unresolved stacks do not establish a caller-level hotspot.
Report losses and stack limitations with the findings.

Use `--call-graph fp --user-callchains` on this host. The verified ReleaseFast
binary retains frame pointers. Check stack decoding again after changing the
compiler or build configuration; frame-pointer sampling requires those pointers
in the profiled code. See the
[perf recording manual](https://man7.org/linux/man-pages/man1/perf-record.1.html).

The 2026-11-09 `--call-graph dwarf` attempt collected hardware samples and
resolved leaf symbols, but decoding caller stacks failed with
`unwind: failed with 'address range overlaps an existing module'`.
Frame-pointer recording resolved caller stacks with the same binary and input.
Keep a decoding failure separate from a counter-access failure.

`self.txt` attributes samples to the function executing at the sampled
instruction; caller views attribute work through the recorded call chain.
Hardware samples locate expensive code. Use `--profile=PATH` in a separate
diagnostic run for compiler phases, per-function selection, legalizer outcomes
and allocation counts; the [profile contract](evidence/selection_performance.md)
defines nesting and allocation accounting. `--profile-events=PATH` also retains
progress through interruption, with output overhead included in its timings.

Measure speedups in separate repeated runs with hardware sampling and both
built-in profiling outputs disabled. Warm up, alternate baseline/candidate
processes, keep inputs and build settings fixed, and avoid overlapping builds or
validation. Retain wall/CPU time and peak RSS. Check object and ownership equality
between profiled and unprofiled runs of the same compiler, then apply the task's
existing baseline equivalence and correctness checks. Compiler throughput and
generated-program runtime performance are separate measurements.

## Verified host smoke run

The 2026-11-09 verification used the retained compiler at
`local-state/validations/large-function-performance-20261107/compiler-fast/bin/z_llvm`
and the Safe Fibonacci input above. Frame-pointer recording captured **3,758
cycles:u samples with zero reported losses**, resolved function names and caller
stacks, and produced an object byte-identical to the capture's `local.o`.

Raw local evidence is in
`local-state/validations/perf-smoke-20261109-zPLDy3/`:

- `perf-fp.data`, `record-fp.log`, `report-fp.txt`, `fibonacci-fp.o`: successful
  frame-pointer recording and output.
- `perf.data`, `record.log`, `fibonacci.o`: the DWARF attempt described above.

This verifies the host setup using a historical binary. Profile the current
revision before attributing current compiler bottlenecks. The smoke run does
not update accepted performance or capability counters.
