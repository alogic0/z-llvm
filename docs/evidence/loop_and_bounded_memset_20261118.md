# Loop promotion and bounded x86_64 memset on M3

The promoted backend is `5d6b921e`. The original fill driver makes 5,914,624 calls per process. The 8–16-byte candidate saved a median of 21.37 ms in ReleaseFast and 21.63 ms in ReleaseSmall. All twelve measured pairs favored the candidate in each mode. Seven dynamic fill sites grew by 41 bytes each. Both stripped executables grew by 288 bytes. The four other frozen workloads produced byte-identical baseline and candidate objects and executables. [Measurement plan](../plans/2026-11-18-loop-and-bounded-memset.md)

## Original driver

Each column reports milliseconds for a complete process on CPU 2 of an AMD Ryzen 7 7840HS. The governor was `performance`, boost was enabled and CPU 10 was the SMT sibling. Each workload and route had two warmups and twelve measured blocks. The local baseline and candidate each led six times per route. The same static LLVM reference image ran twice per block. All 560 visits returned their expected digest and empty stderr. The LLVM column uses the visit paired with the candidate. Dispersion is the median absolute deviation of the twelve paired differences.

| Workload | Mode | Baseline | Candidate | LLVM O3 or Oz | Paired change | MAD |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Arguments and branches | Fast | 72.62 | 72.45 | 51.74 | −0.02 | 0.37 |
| Arguments and branches | Small | 72.18 | 72.30 | 51.73 | −0.11 | 0.25 |
| Loop and memory | Fast | 235.98 | 235.53 | 81.47 | −0.40 | 0.88 |
| Loop and memory | Small | 236.38 | 234.90 | 103.64 | −1.41 | 1.34 |
| Nested calls | Fast | 145.79 | 145.89 | 55.88 | −0.05 | 0.26 |
| Nested calls | Small | 145.95 | 146.18 | 55.86 | −0.01 | 0.38 |
| Register pressure | Fast | 96.28 | 96.29 | 48.70 | +0.12 | 0.36 |
| Register pressure | Small | 96.21 | 96.01 | 48.83 | −0.25 | 0.53 |
| Memset family | Fast | 82.67 | 61.21 | 14.95 | −21.37 | 0.44 |
| Memset family | Small | 82.84 | 60.83 | 14.87 | −21.63 | 0.54 |

The Fast trial-to-baseline paired ratio was 0.7383, with paired time differences from −22.89 to −20.69 ms. Small measured 0.7367, from −22.75 to −16.51 ms. Of the twelve lengths in the original driver, only 15 and 16 bytes enter the new path.

| Memset artifact, bytes | Local baseline | Local candidate | LLVM O3 and Oz |
| --- | ---: | ---: | ---: |
| Kernel text | 843 | 1,130 | 275 |
| Kernel read-only data | 0 | 0 | 0 |
| ELF object file | 1,992 | 2,280 | 1,832 |
| Stripped executable text | 147,049 | 147,337 | 146,489 |
| Executable read-only data | 59,712 | 59,712 | 59,712 |
| Stripped executable file | 239,288 | 239,576 | 238,872 |

Fast and Small had identical image bytes within each local version. The size increase was 34.0% of kernel text and 0.12% of the whole executable. The baseline and candidate each used the M2 inputs, original driver objects and static link settings for all five workloads. Both compilers, forty route preparations and all timings were fresh. The baseline matched all 679 accepted M3 source members and the SDK, target and build settings. Its executable SHA-256 was `6a4dcb44d0d24482974dd312bb1f18936105133581302d8266d690a336aece15`. The candidate SHA-256 was `7e65fbe3bec2906c1cc42816f87b72f0a74d1c199538d354f5127fee4e205361`.

## Loop promotion

Applying only SROA removed the single-element stack slot. On the same M3 emitter and driver it slowed the loop in all twelve pairs in both modes. The local Fast medians moved from 233.95 to 275.47 ms, a paired increase of 40.99 ms (MAD 2.47). Small moved from 232.09 to 272.04 ms, a paired increase of 40.09 ms (MAD 3.15). The LLVM O3 and Oz reference medians were 80.06 and 103.28 ms. All 112 visits produced the expected timed digest. All eight prepared images agreed on 272 scalar cases including zero trips and signed wraparound. Deliberately using a stale accumulator changed 254 outcomes. Dropping the induction value from the XOR changed 219.

The local frame shrank from 280 to 264 bytes and function text from 127 to 125 bytes. Stack accesses on a nonterminal iteration increased from nine to eleven. The promoted loop spills and reloads both values on the backedge before copying them into their next-iteration stack slots. LLVM's machine backend kept the accumulator in EAX and the induction value in ECX on the same promoted IR. Primary review declined the release-pipeline SROA change and deferred work on backedge copies.

## Fill semantics and measured cutoff

For an ordinary nonvolatile dynamic length, the selector compares the unsigned value of `len - 8` with 8. Lengths 8 through 16 repeat the low byte into a 64-bit word and store it at `dst` and `dst + len - 8`. The stores coincide at 8, overlap at 9 through 15, and meet at 16. Each path returns the original pointer. Constant lengths use the existing lowering. The 115-byte constant routine was identical on both Fast and Small. Focused Debug and ReleaseFast tests checked dynamic and constant calls, constant inline memset, volatile and invalid-inline refusal, and live inputs. Each test run passed all 17 entries.

The original native oracle passed all 1,442 observations and both checked-wrapper traps in each image. A separate shared-memory harness checked 2,850 fills per image against the full writable page between two protected pages. It covered all lengths in the new range, six destination offsets, high fill bits, the returned pointer and three live scalar values. Six zero-length calls returned inaccessible pointers untouched. Fourteen out-of-bounds calls, including 64-bit lengths above 4 GiB, trapped with SIGILL and left every shared byte intact. Two deliberate prewrites were visible to the parent. Both local modes and both LLVM references passed on the baseline and candidate.

The first assembly check returned 1 because the CLI rejects reachable-only assembly output. The recovery authenticated the eight completed guarded runs and used full-module assembly from the same optimized IR. Each of the seven printed fill sequences in each mode assembled to exactly the 63 bytes at the matching offset in its measured reachable object. The outer shell exited 127 because its queue script was edited during collection. Both original exits and their diagnostics are preserved.

The diagnostic linked the same measured kernel objects with copies of the original driver. Each copy replaced the twelve 64-bit entries at file offset 194,480 with one length. The load in `_start` references `.rodata + 0xbfe0`. Each of the six arms for each length made the same 5,914,624 calls. All 84 images agreed with a direct model, including the two LLVM references at each length. There were two warmups and twelve measured blocks per arm. The table gives whole-process paired candidate-minus-baseline differences, in milliseconds.

| Bytes | Path | Fast paired change | Fast MAD | Small paired change | Small MAD |
| ---: | --- | ---: | ---: | ---: | ---: |
| 0 | Fallback | +0.74 | 0.17 | +0.71 | 0.15 |
| 1 | Fallback | +1.28 | 0.08 | +1.38 | 0.06 |
| 2 | Fallback | +0.67 | 0.20 | +0.58 | 0.13 |
| 7 | Fallback | −2.20 | 0.28 | −2.51 | 0.36 |
| 8 | Two stores | −13.34 | 0.32 | −13.38 | 0.40 |
| 9 | Two stores | −15.45 | 0.21 | −15.61 | 0.22 |
| 15 | Two stores | −28.99 | 0.30 | −29.23 | 0.51 |
| 16 | Two stores | −31.25 | 0.33 | −31.49 | 0.44 |
| 17 | Fallback | −7.87 | 0.43 | −7.88 | 0.63 |
| 31 | Fallback | −18.08 | 0.58 | −17.64 | 0.53 |
| 32 | Fallback | −17.12 | 1.12 | −16.34 | 0.42 |
| 63 | Fallback | −40.17 | 1.23 | −41.09 | 2.31 |
| 64 | Fallback | −39.20 | 1.48 | −38.53 | 2.11 |
| 127 | Fallback | −90.59 | 3.14 | −92.76 | 3.13 |

The 0-, 1- and 2-byte cases paid a measurable cost in both modes. Longer fallback cases also gained time while executing the byte loop. The original-driver gain therefore applies to the complete candidate, including the changed dispatch and placement of the loop. For example, the byte-store instruction in `family_checked` moved from object offset `0x77` to `0xa0`.

## Contribution of the two stores at fixed addresses

A diagnostic copy of each candidate object preserved the length check and all seven fallback sequences at their linked addresses. At each site, changing two bytes from `40 0f` to `eb 1d` diverted eligible lengths to the existing fallback. All other bytes of the object and stripped executable were identical in each pair. For example, the first length check starts at `0x1035ead`, the added jump at `0x1035eb7`, and the fallback at `0x1035ed6`. Both diagnostic images passed the original 1,442-observation oracle, both bounds traps and the original mixed-driver digest.

| Mode | Forced fallback, ms | Genuine candidate, ms | Paired change, ms | MAD, ms | Paired range, ms | Candidate faster |
| --- | ---: | ---: | ---: | ---: | --- | ---: |
| Fast | 65.262 | 61.180 | −3.857 | 0.740 | −4.978 to −1.453 | 12/12 |
| Small | 65.744 | 61.634 | −3.935 | 1.104 | −6.163 to −2.396 | 12/12 |

With the layout fixed, the genuine path saved about 6% on the original family driver. The diagnostic pays one extra taken short branch for each eligible call. The earlier 26% comparison includes the different layout and dispatch. Both comparisons used the original mixed input, with separate rounds of timing. Primary review independently checked all fourteen changed bytes per executable, the original traps and all 112 visits, and accepted the measured cutoff for this family.

## Qualification and provenance

The exact frozen candidate passed 2,446 unit tests and 74 structural checks in Debug. The ABI differential matched 60 cases. The maintained Debug distribution gates passed 38 captured-object checks and 27 native executable cases. The measured ReleaseFast executable then re-emitted each of their 27 distinct IR inputs. All 27 object byte strings matched the corresponding Debug emissions. An independent audit rehashed the 679 candidate source files, reconstructed all fourteen diagnostic driver objects from the original ELF and checked 1,848 timed stdout/stderr pairs and all 84 single-length link checks. The 112 fixed-layout visits have a separate audit.

The integrated selector and encoder gate completed with exit 0 on the measured ReleaseFast compiler. It passed all seven integrated executables, seven unchanged upstream Zig programs and the upstream C fixture. The three release modes matched the entire 237-population native registry. Primary review checked all 2,133 original reference, direct and release outcomes and all 1,422 selection-owner manifests. The memset differential passed 8,652 observations and twelve traps across six route/mode combinations. The execution-breadth controls passed 22,788 observations and 54 negative cases. The complete checked command took 2,617.99 seconds.

The eight-file patch on parent `dd38812d` has SHA-256 `46a70903bd2dee1766665777a2e5b98a86d0ecc78c149e7d99a8778e8f9e590c`. Its 679-member source list hashes to `6b23ab15ca138b8f8d15ec9b5afe81ea40d26e0e8a4c5854cef20495df5b20ad`. Primary review reproduced the complete committed change and all 679 source identities at `5d6b921e`. M3's whole-compiler self-rebuild, four upstream behavior runs and serial distribution gate retain their original identities at `d968e3ac`. This performance change received fresh, affected Tier 2 qualification. [M3 qualification](release_fast_compiler_preopt_self_rebuild_20261117.md) · [Original timing driver](../../test/behavioral/performance_memset.zig)

## Evidence and storage

Paths in the table are relative to `local-state/validations/loop-and-bounded-memset-20261118/batch-01/`. The collector removed eight completed measurement workspaces in transaction `1795042690941978020-3506641`, reclaiming 445,775,872 allocated bytes. The final closure ledger records each owned workspace and its removal, the idle sweep, and the owners and reasons for other retained roots.

| Evidence | Paths within the batch |
| --- | --- |
| Patch, exact source members and measured backend build | `fill-source/candidate.patch`, `fill-source/candidate-source.txt`, `fill-compiler/ReleaseFast/bin/z_llvm.build.json`, `result-audit/source-candidate/` |
| Original and SROA loop, disassembly, scalar oracle and negative cases | `loop-original/loops_memory/`, `loop-sroa/sroa-only.ll`, `loop-sroa/loops_memory/`, `loop-controls/`, `loop-sample/report.json` |
| Common drivers, forty route preparations and whole-family samples | `common-drivers/identities.txt`, `fill-original/report.json`, `fill-candidate/report.json`, `fill-sample/report.json` |
| Host, independent size and timing comparisons | `fill-sample/host.txt`, `result-audit/sizes.tsv`, `result-audit/full-independent.tsv` |
| Guarded bytes, diagnostic receipts and fourteen assembled site checks | `fill-focused/`, `fill-controls/disposition.md`, `fill-controls/wrapper-disposition.md`, `fill-controls-02/verified-sites.tsv` |
| Diagnostic driver table, model, outputs, ranges and pair signs | `fill-instruments/driver-load.txt`, `fill-lengths/lengths/prepared.json`, `fill-lengths/lengths/report.json`, `result-audit/length-drivers.tsv`, `result-audit/length-independent.tsv` |
| Same-layout control, full object and image differences, and raw timing | `layout-control/addresses.tsv`, `layout-control/local-fast/`, `layout-control/local-small/`, `layout-control/report.json`, `layout-control/independent.tsv` |
| Tier 2 unit, object, ABI, native and owner evidence | `tier2-core/report.json`, `tier2-integrated/checks.json`, `tier2-integrated/integrated/integrated.stdout`, `tier2-integrated/integrated/unchanged-upstream-c/report.json` |
| Workspace releases, collector transactions, other owners and idle sweep | `storage/closure.json`, `storage/removals.jsonl`, `storage/other-owners.jsonl`, `storage/final-idle.path` |

The first timing-tool bootstrap failed to compile its schedule test. Its successor corrected the initializer and passed the Debug and ReleaseFast schedule checks before any measurements. The first source and diagnostic remain in `meter-build/`. Frozen M2 inputs and oracle contracts were reused. All timings reported here came from new executions.
