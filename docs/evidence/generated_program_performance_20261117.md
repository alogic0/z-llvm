# Generated-program runtime and size on x86_64

On the five fixed workloads, the local Fast images took **1.39–5.55 times** the LLVM O3 runtime. The local Small images took **1.40–5.57 times** the LLVM Oz runtime. All 120 same-round comparisons favored LLVM. The largest relative gap was the memset family. The largest absolute gap was the loop benchmark, which took about 150 ms longer per Fast process. Each pair ran the same driver, inputs and number of calls. [Frozen protocol](../plans/2026-11-17-generated-program-performance.md)

## Runtime

Times are milliseconds per complete process, including startup, the common driver and process reap. Each cell shows the median and median absolute deviation over twelve measured processes. Ratios are the medians of the twelve local/LLVM ratios from matching rounds. The raw file includes every observation in execution order, including the two warmups per route. The JSON includes the minimum, maximum and MAD for every timing and ratio. [All 280 observations](generated_program_performance_20261117_samples.tsv) · [Machine-readable results](generated_program_performance_20261117.json)

| Workload | Local Fast | LLVM O3 | Fast/O3 | Local Small | LLVM Oz | Small/Oz |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Arguments and branches | 70.64 ± 0.19 | 50.67 ± 0.18 | 1.39× | 70.67 ± 0.25 | 50.56 ± 0.11 | 1.40× |
| Loop and memory | 230.05 ± 0.46 | 79.89 ± 0.22 | 2.88× | 229.88 ± 0.48 | 101.32 ± 0.23 | 2.27× |
| Nested calls | 144.59 ± 0.15 | 54.89 ± 0.11 | 2.64× | 144.40 ± 0.24 | 54.92 ± 0.10 | 2.63× |
| Register pressure | 94.01 ± 0.34 | 47.76 ± 0.06 | 1.96× | 93.90 ± 0.20 | 47.85 ± 0.20 | 1.96× |
| Memset family | 80.84 ± 0.26 | 14.61 ± 0.13 | 5.55× | 80.93 ± 0.45 | 14.54 ± 0.07 | 5.57× |

The common scalar driver made 35,651,584 calls per scalar workload and process. The memset driver made 5,914,624 calls across lengths 0–127, five fill values and four offsets. The widest paired range was memset Fast/O3, 5.26–5.80×. The slowest local Fast memset sample, 85.35 ms, remains in the results.

## Object and executable bytes

Each triple gives **local / LLVM O3 / LLVM Oz** bytes. Separate local Fast and Small invocations produced identical optimized IR, objects and timed executables for each of the five workloads. Both named pipelines select the same implemented pass list. The JSON retains their separate rows.

| Workload | Kernel object .text | Whole object file | Stripped timed executable |
| --- | ---: | ---: | ---: |
| Arguments and branches | 116 / 22 / 22 | 816 / 616 / 616 | 237,496 / 237,400 / 237,400 |
| Loop and memory | 127 / 124 / 28 | 816 / 720 / 624 | 237,496 / 237,496 / 237,400 |
| Nested calls | 105 / 59 / 59 | 936 / 712 / 712 | 237,480 / 237,432 / 237,432 |
| Register pressure | 199 / 74 / 74 | 896 / 1,040 / 1,040 | 237,576 / 237,496 / 237,496 |
| Memset family | 843 / 275 / 275 | 1,992 / 1,832 / 1,832 | 239,288 / 238,872 / 238,872 |

The LLVM register-pressure objects contain 48 bytes of read-only vector constants. All other workload objects have zero named read-only data, and all twenty have zero named writable data and BSS. Every timed executable has 19,072 bytes of named writable data and 41,216 bytes of BSS. Shared driver/runtime code, ELF metadata and section alignment affect the final file size. For example, the Fast loop executables have the same length despite their 2.88× runtime ratio. The JSON gives executable-section, named text/rodata/data/BSS, total allocated file-backed and allocated NOBITS bytes for each image.

## Ranked follow-up proposals

1. **Keep loop-carried scalars in registers.** LLVM completed this workload about 150 ms sooner in the Fast comparison and 129 ms sooner in Small. The local optimized IR retains a one-element stack slot. Its object has a 280-byte frame and 15 instructions with stack-address operands. Both LLVM loops have zero such instructions. Start with a proven nonescaping, single-element slot and its loop-carried value. Inspect promotion and edge copies separately. Recheck zero iterations, wrapping arithmetic and the existing alias/volatile exclusions before rerunning both modes.
2. **Improve bounded byte-fill lowering.** Memset has the largest runtime ratio and the largest kernel text difference, 843 versus 275 bytes. The local checked fill issues one byte store per loop iteration. LLVM's variable-length paths transfer work to the linked memset implementation, and its constant-fill code is shorter. Compare a bounded short-fill sequence and a shared routine where the callee is known to be nonrecursive. Preserve zero lengths, checked traps, return pointers, alignment and live values. Reuse all 1,442 semantic observations and both fault cases.
3. **Remove eligible tiny direct calls.** The local nested-call object contains three static call sites across two callers. Both LLVM objects contain zero, while retaining callable definitions. The Fast and Small elapsed differences are about 90 ms each. Evaluate the existing cost-bounded inliner on callees proved noninterposable, preserving externally callable symbols and ABI behavior. Compare size and runtime in both modes before widening its use.
4. **Reduce integer temporaries and spills before testing packed reductions.** The register-pressure probe contains 60 local instructions and 16 stack-address instructions. LLVM uses 16 instructions, including packed integer adds and XORs, with 48 bytes of constants. The paired gap is 1.96× in both modes. First measure scalar live-range and spill improvements. A separate SSE2 slice can then test its extra read-only data against the remaining gap.
5. **Simplify branch and merge materialization.** The arguments probe reserves 264 stack bytes and emits 116 bytes of text. LLVM uses 22 bytes and no stack-address operands. Compare flag-consuming branches, fallthrough layout and avoiding redundant merge copies while retaining the signed division edge results. This workload has the smallest measured process gap, about 20 ms.

Static instruction counts include emitted padding. The timing interval covers each complete process. Each proposal needs its own reviewed implementation and remeasurement.

## Execution and evidence

The compiler core was `c32ba3cf`. Its fresh ReleaseFast backend was `ab067396`, built from `a27b8e86` with the authenticated Zig 0.17.0 SDK and 19,501 library files. The original procedure was frozen at `32adb32c`. LLVM 22.1.8 clang compiled the identical IR with O3 or Oz. All routes used baseline x86_64, identical static linker arguments and common ReleaseFast driver objects, stripped images and disabled LTO. Programs ran unprofiled on CPU 2 of an AMD Ryzen 7 7840HS with the performance governor and boost enabled. SMT sibling 10 remained available to the host. One-minute host load was 2.23 before and 1.94 after sampling.

The independent arithmetic model and frozen historical LLVM outputs agreed for all four scalar workloads. The semantic runs checked 272 outputs per scalar image and 1,442 buffer/pointer/live-value observations per memset image. All eight bounds-failure processes terminated with SIGILL. All normal prechecks, warmups and measured executions returned zero, matched the expected stdout and wrote empty stderr. The supplied IR, workload definitions and golden outputs were reused. Compilation through each local/LLVM route, all forty links, native executions and ELF measurements were fresh in M2. These fixed kernels cover integer control flow, calls, register pressure and byte fills on one host. Compiler throughput, whole-application performance and self-rebuild were outside this measurement.

The first sampling command exited 1 while recording affinity because `taskset -pc 0` rejected PID zero. It launched zero generated programs. Revision `1ee97b3b` verified kernel and spawned-child affinity in Debug and ReleaseFast, then ran the full unchanged schedule against the twenty authenticated prepared images. The initial failure and both freezes are preserved.

The local evidence root is `local-state/validations/generated-program-performance-20261117/batch-01`. `programs/` contains the exact IR, commands, owners, link invocations, ELF listings and disassembly. `timed-run/` holds the full samples and stdout/stderr. `inspect/` contains the independent command, link-input, statistics and section checks. The compact tracked result records their hashes.

A fresh serial distribution run on backend `ab067396` passed all 17 gates. Its run ID was `cbc9a73d6b32028addb6bf8ee5d091e1`. The native gate ran Fast, Safe and Small against the 237-population registry. The machine-readable result records the individual gate outcomes and cache observations. The final verification and storage inventories are under `final-checks-r2/` and `storage/result.json` in the local evidence root.

The first final order check exited 1 on the first row because it split its expected workload list on tabs. The archived sample row matched the frozen order. The successor uses explicit separators and checks every row, with separate controls for a changed route and a missing row. The original receipt and first-row reproduction are in `final-checks-incident/`.
