# Performance on baseline x86-64 Linux

LLVM produced faster executables on all five workloads in the November 17
comparison. Later changes sped up the locally generated loop and memory-fill
programs. The published compiler also spent over three minutes emitting one
object for `pointer_constants.ll`.

| Measure | Workload and report date | Baseline | Measured result |
| --- | --- | --- | --- |
| Compiler time | Direct object emission for `pointer_constants.ll`, Nov 19, 2026 | First installed helper (G1), 19.1 s. Same helper source built with LLVM, 1.42 s. | The self-built helper (G2) took **209.2 s**. All three produced the same 240,912-byte object. [Timings and profile](evidence/llvm_free_self_rebuild_20261119.md#pointer-constants-emission-time) |
| Generated-program runtime | Five fixed programs, Nov 17, 2026 | LLVM O3 for ReleaseFast and LLVM Oz for ReleaseSmall | Local programs took **1.39–5.55×** the LLVM O3 time and **1.40–5.57×** the LLVM Oz time. Memory fill had the largest ratio. [All five programs](evidence/generated_program_performance_20261117.md#runtime) |
| Generated-program runtime | Memory fill, Nov 18, 2026 | Previous local implementation and a paired LLVM reference | Bounded stores saved **21.37 ms** per Fast process and **21.63 ms** per Small process against the local baseline. Fast medians were 61.21 ms with the change and 14.95 ms with LLVM O3. [Paired measurements](evidence/loop_and_bounded_memset_20261118.md#original-driver) |
| Generated-program runtime | Loop with 272 inputs, Nov 19, 2026 | Previous local backend `56eb24a6` | Keeping the accumulator in a register saved **36.42 ms** per Fast process and **38.00 ms** per Small process. The change won all twelve pairs in each mode. [Loop measurements](evidence/loop_register_residency_20261118.md) |
| Object and executable size | Register pressure, Nov 17, 2026 | LLVM O3 and Oz, 1,040-byte object and 237,496-byte stripped executable | The local object was **144 bytes smaller** (896 bytes). The local stripped executable was **80 bytes larger** (237,576 bytes). [Object and executable sizes](evidence/generated_program_performance_20261117.md#object-and-executable-bytes) |
| Executable size | Memory fill, Nov 18, 2026 | Previous local stripped executable, 239,288 bytes | The faster fill grew the executable by **288 bytes**, to 239,576 bytes in both modes. The LLVM reference was 238,872 bytes. [Size breakdown](evidence/loop_and_bounded_memset_20261118.md#original-driver) |

The November 17 runtime ratios are medians of twelve same-round comparisons
of complete processes with common drivers and inputs. The later local
improvements each use the baseline named in their row. The G2 measurement
times direct object emission by an already-built compiler. Cold builds of
`z_llvm` and Zig are a proposed follow-up if the focused experiment passes.
[Measurement protocol](plans/2026-11-17-generated-program-performance.md) · [Next experiment](next_steps.md)
