# Keeping an x86_64 loop accumulator in R9D

Commit `3a9b6d8f99d5` keeps one private i32 accumulator in R9D through an ordinary leaf loop. On the frozen 272-input workload, median paired runtime fell by 36.42 ms in Fast and 38.00 ms in Small. The compiler-generated loop won all twelve pairs in each mode and shrank from 111 to 95 bytes. The other four frozen programs retained their exact object and executable bytes.

The baseline was the single-use equality branch revision, `56eb24a6`. Primary review compared all 682 candidate source files with an independent archive of the public commit, and verified the committed five-file diff against the qualified patch. The fresh compiler, native tests, measurements and Tier 2 results are bound to those bytes. The matched assembly experiments below explain how the production opportunity was selected. [Experiment plan](../plans/2026-11-18-loop-register-residency.md)

## Matched production and register loops

The fresh baseline backend, SHA-256 `372cac1c97b1a2aa98c1ebca320ea20808a70973535bc7df295c2c3dd35b7f29`, used 680 compiler source files. It reproduced the earlier 111-byte loop and the 237,480-byte static executable in both the Fast and Small pipelines. The original workload used the unchanged 272-input driver. A second driver set all 272 inputs to one trip count before the timed loop. Its six fixtures shared one executable per arm and mode. Every timed launch made 35,651,584 external calls. The independent arithmetic models agreed on 1,999 iterations per 272 calls for the original mix, or 262,012,928 iterations per launch.

The production loop carries the accumulator, induction variable and bound through a 280-byte frame. The first register variant kept them in EDI, R10D and ESI. For a call with N trips, the original probe performed 5N + 4 stack reads and 2N + 4 writes, excluding call/return stack traffic. The register variant performed one entry read and three entry writes. Both reserved the full frame. The assembly retained the original arithmetic, instruction starts, comparison, conditional exit, loop backedge, exit jump and return. The 28 changed bytes in nine instructions were confined to the probe. A fresh static link preserved every other byte. Both release pipelines emitted the same object and linked images, and each mode label has separately measured visits on the same host.

The independent native check compared all 272 signed return values and the uint64 aggregate digest for each arm, mode and fixture. All 7,616 valid return values matched, with the six callee-saved registers, stack pointer and direction flag checked across each wrapper call. Changing the accumulator increment from seven to eight changed 224 mixed results. It changed the aggregate digest at every positive fixed count and in the mix. Zero trips returned the original input for both increments. The primary reviewer independently rehashed 25 artifacts, checked eight linked pairs and ran another 1,388 native cases per valid arm and mode.

| Fixture | Fast paired savings, ns/call (MAD) | Small paired savings, ns/call (MAD) | Pairs faster, Fast / Small |
| --- | ---: | ---: | ---: |
| Original mix | 0.348 (0.060) | 0.458 (0.065) | 12 / 11 |
| 0 | 0.001 (0.008) | −0.010 (0.018) | 7 / 3 |
| 1 | 0.035 (0.016) | 0.040 (0.033) | 11 / 11 |
| 8 | 0.888 (0.088) | 0.932 (0.101) | 11 / 12 |
| 15 | 1.854 (0.290) | 1.711 (0.496) | 11 / 10 |
| 64 | −9.120 (0.369) | −8.811 (0.617) | 1 / 2 |
| 256 | −64.186 (1.588) | −62.189 (1.004) | 0 / 0 |

There were 392 visits on CPU 2 of an AMD Ryzen 7 7840HS. Each cell summarizes twelve measured pairs after two warmup pairs. MAD is the median absolute deviation. Positive savings mean the register version ran faster. Its mixed times were 195.54 ms Fast and 197.46 ms Small, against production at 208.56 and 213.41 ms. The median paired savings were 12.39 and 16.32 ms. Both visit orders favored it on the mix. At 256 trips it took 7.44 and 7.40 s against 5.20 and 5.15 s. LLVM O3 and Oz measured 82.57 and 104.72 ms on the historical mixed driver. Those reference times come from the previous production comparison. [Previous compiler measurements](x86_loop_edges_20261118.md)

The fixed and mixed drivers place the header at offsets 0x12 and 0x32 within a 64-byte line. Each fixture preserves its address across arms. The mixed driver also changes trip count from call to call. These differences limit extrapolation from a fixed-trip slope to the mixed workload. The fixed curve changes sign within one executable. Two seven-byte LEAs on the accumulator dependency chain prompted a second, directly paired measurement.

The evidence root is `local-state/validations/loop-register-residency-20261118/batch-01`. For this comparison see `prepare/{images,layout}.tsv`, `oracles/{oracles,native}.tsv`, `sample/report.json` and `audit/{visits,pairs,summary,slopes,historical-llvm}.tsv`. The schedule, assembly and model are under `procedure/`. Independent results are in `review-oracle/model.json`, `review-diagnostic/independent.json` and `review-samples/paired.json`.

## Accumulator copy controls

The second experiment kept production (A) and the original register loop (R). Two more versions replaced only the seven-byte copies at offsets 0x33 and 0x44 along the accumulator dependency chain. L used a two-byte base-only LEA, and M used a two-byte MOV. Both then executed the same five-byte NOP at offsets 0x35 and 0x46. Relative to A and R they decode two additional instructions per trip. Other bytes, branch targets and stack reservation match R. L and M differ in exactly four bytes across each entire object and linked program. The R versus L comparison measures shortening each LEA and adding the following NOP together.

Both short-copy versions matched all 7,616 individual return values and all digests again. The M fault reproduced every wrong output of the earlier faulty register loop. The reviewer rehashed 45 live files, checked the actual instruction bytes, reran the independent native cases and reconstructed all 560 timing visits. Two warmups preceded twelve measured four-arm blocks for each mode and fixture. Each arm occupied each position three times, and each ordered pair of adjacent arms occurred three times. Each arm preceded every other arm three times in each mode position.

| Fixture | Production to MOV, Fast / Small | Short LEA to MOV, Fast / Small | Long LEA to short LEA plus NOP, Fast / Small |
| --- | ---: | ---: | ---: |
| Original mix | 24.69 / 21.76 ms | −0.62 / −0.18 ms | 9.64 / 7.51 ms |
| 0 | 0.18 / −0.02 ms | −0.23 / −0.11 ms | 0.21 / 0.42 ms |
| 15 | 92.29 / 93.05 ms | −0.01 / 0.46 ms | 15.51 / 24.32 ms |
| 64 | 284.41 / 272.19 ms | 3.57 / 8.90 ms | 602.72 / 596.94 ms |
| 256 | 1,157.40 / 1,120.32 ms | −18.15 / 19.48 ms | 3,490.11 / 3,377.57 ms |

The table reports median paired savings between the indicated arms in the same measured blocks. MOV beat production in all twelve mixed pairs in both modes. At zero trips the median difference was within 0.2 ms. Between 64 and 256 trips the median per-round increase in production-to-MOV savings was 0.122 ns per additional iteration in Fast and 0.125 ns in Small. The associated MADs were 0.016 and 0.012 ns. Differences between the two short copy opcodes fell within the dispersion at long trip counts. Both short forms recovered the long-trip loss seen with R. The primary reviewer used the direct production-to-MOV comparison to authorize a bounded compiler prototype.

The machine layout and common bytes are in `control-prepare/{layout,images,control-pairs}.tsv`. Native outputs and mutations are under `control-native/`. The 80 warmups and 480 measured visits are in `control-sample/report.json`. The four contrasts, visit-order medians, ranges and slopes are in `control-audit/{visits,pairs,summary,slopes}.tsv`. Independent checks are recorded by `review-copy-control/{review,copy-review}.json`.

## Compiler prototype

The compiler change starts from `56eb24a6`. It acts on the final instructions of the x86_64 composed selector after the existing frame compaction. It can keep one initialized, nonescaping 32-bit stack word in R9D through a leaf loop. The entry jumps to a header, the header branches to the latch or the return block, and the latch jumps back to the header. The selector identifies those blocks by their edges and requires an unannotated, nonvariadic function with an i32 return and i32 parameters using the ordinary C calling convention. It requires direct, ordinary 32-bit accesses to the same private object, including a latch read and write. A complete machine-effect check covers the prologue, the body and the exit. The selector verifies that every other spill is disjoint and the whole function leaves R9 available under the ordinary calling convention. It substitutes existing register moves for the initialization, updates and reloads, including the zero-trip return. The selected owner, original frame reservation, flags and arithmetic are preserved.

The prototype declines alternate entries, escaped or volatile memory, unknown effects, a live R9 alias and unproved calling conventions or attributes. A sixth integer argument that survives the loop has a real incoming R9 spill. `coldcc` and `"no_caller_saved_registers"` can protect R9 even when no selected instruction explicitly mentions it. The eligibility test handles both inline attributes and attribute-group references conservatively.

The first Debug trial kept the four stack accesses in the renamed add/XOR recurrence. The original production-shaped fold already used R9. An independent reconstruction of the original patch and selected actions showed that the different arithmetic materialized its literal in RCX. The successor admits this RCX-only move and records the effective-ABI boundary. The diagnosed trial is in `prototype-development/`, the machine evidence is in `prototype-effects/effects.txt`, and the corrected Debug run is in `prototype-development-02/`.

The five-file patch has SHA-256 `cccbc3363d58d2e21c88e88db1b515b1fdf6426e0cbd9c903e08e47b2d030d58`. The fresh measured compiler has SHA-256 `33ee3c18d30ab3525326ef288191d911d5781cb44f7ebc9c07094166fd43f92e` across a source membership of 682 files. Both focused Debug and ReleaseFast runs passed all eleven entries, including the three private-loop tests. The frozen patch, full file identities and build are under `prototype-source/`, `prototype-compiler/ReleaseFast/` and `prototype-focused/`.

## Native behavior and ABI

A C driver checked six returned words per input on 160 edge combinations and 256 deterministic random inputs. Its references used unsigned 32-bit arithmetic and checked the initial and final memory value and call count for the external writer. Direct emission and the normal Fast and Small routes each ran the baseline, frozen candidate and LLVM reference. All nine produced the same 2,496 rows. On all three local routes the original fold shrank from 111 to 95 bytes and the different add/XOR recurrence from 124 to 108. The sixth-argument, volatile, alternate-entry and escaped-address functions retained their exact machine bytes. The relative relocation on the escaped callee still names `add_to_cell`. The four Fast/Small controls using a scalar `alloca i32` exercised the existing path and had identical fold bytes and 2,496 correct rows per image. Three deliberate faults changed the increment, ignored a live sixth argument or suppressed the external write. Each failed on its designated result. The byte identities and addresses are in `prototype-native/{function-bytes,native,scalar-word}.tsv`. The complete returned words are in each route's `rows.stdout`, and the relative relocations are in `prototype-audit/fallback-relocations/`.

The primary reviewer wrote a separate C oracle and five other loop fixtures, and checked all 2,450 native cases on each of direct, Fast and Small against LLVM. The independent caller additionally placed a 64-bit sentinel in R9. The normal implicit and explicit C cases showed the new register use. Each of the nine cold-convention or special-preservation objects matched the baseline byte for byte and kept the full sentinel on zero and positive trips. A deliberately clobbering callee tripped the check. In the first LLVM O0 control, the explicit register-saving attribute also saved and restored RAX, obscuring the ordinary return. The replacement caller measured just the R9 preservation for those LLVM cases and continued to check the return and R9 for all local cases. See `review-prototype/`, `review-prototype-abi-baseline/`, `review-prototype-abi-baseline-02/` and `review-prototype-abi/`.

## Production performance

The ReleaseFast backend ran the normal Fast and Small optimization and emission routes on the five frozen programs. The baseline and candidate used the same inputs, driver objects and expected outputs. Each had a fresh 20-row cohort, including LLVM O3 and Oz. Every baseline object and linked executable matched its historical identity at `56eb24a6`. The local loop in Fast and Small was the only program to change. Its object fell from 800 to 784 bytes, and the stripped executable from 237,480 to 237,464 bytes. The two release modes emitted the same changed loop object (`e2c0737e`) and the same runtime executable (`a199ae9c`). The independent review rehashed all 40 live object/executable pairs and all 560 observed outputs.

| Original workload | Fast candidate − baseline, ms (MAD) | Small candidate − baseline, ms (MAD) | Faster pairs, Fast / Small | Object .text, bytes |
| --- | ---: | ---: | ---: | ---: |
| Arguments and branches | +0.05 (0.43) | +0.32 (0.40) | 6 / 4 | 100 |
| Loop and memory | −36.42 (4.43) | −38.00 (4.39) | 12 / 12 | 111 → 95 |
| Nested calls | +0.09 (0.69) | −0.08 (0.84) | 4 / 6 | 105 |
| Register pressure | −0.05 (0.15) | +0.26 (0.49) | 9 / 6 | 199 |
| Memset | −0.04 (0.53) | +0.15 (0.44) | 6 / 5 | 1,130 |

Each mode and workload had two warmup pairs and twelve measured pairs on CPU 2. Each arm led six measured pairs. The four route positions were balanced across the twelve rounds. The loop's median runtime moved from 212.49 to 180.46 ms in Fast and from 216.08 to 177.12 ms in Small. The median paired candidate/baseline ratios were 0.830 and 0.820, for runtime reductions of 17.02% and 17.96%. The observed savings across individual pairs ranged from 20.95 to 98.92 ms in Fast and from 31.45 to 58.05 ms in Small. For the four other local programs, object and executable bytes were identical and each median difference was smaller than its MAD. Fresh loop LLVM reference visits measured about 82 ms at O3 and 104 ms at Oz. The candidate took 2.18 times as long as O3 in Fast and 1.69 times as long as Oz in Small, using the median paired ratios.

The production selector keeps the accumulator in R9D. The index and limit continue to use the original 280-byte frame. In the body this removes one of five stack reads and one of two stack writes per trip. Its shorter program changes instruction positions. The hand-written MOV probe preserved positions and moved all three loop values into registers. The two timings quantify different code changes against the same historical production source. The compiler result here covers the original mixed input. The fixed-count curves above belong to the matched assembly experiment.

The input, optimization, object and executable identities, sizes and native output are in `{baseline,prototype}-original/report.json`. See `prototype-sample-original/report.json` for raw times, `prototype-audit/original/{paired-ms,sizes}.tsv` for an independent recomputation, and `review-prototype-samples/{live-rehash.json,paired.tsv}` for the primary review.

## Qualification

The frozen source passed 2,453 Debug unit tests and 74 structural tests. The ABI differential matched all 60 cases. The object and executable distribution checks passed 38 and 27 cases. Re-emission through both the Debug and measured ReleaseFast backend gave identical objects for all 27 distinct inputs. The public and private runner trees matched on all 1,822 file identities before and after the integrated run. The gate added no entries to the legacy temporary directory.

| Integrated check | Fresh result |
| --- | --- |
| Scalar differential | 8 programs, 3 harness modes, 6,528 observations |
| Memset, memcpy and byte-loop differential | 8,652, 53,802 and 195,888 observations respectively, with 12 checked traps in each family |
| Execution breadth | 21 function/mode combinations, 22,788 observations and 54 negative controls |
| Unchanged upstream Zig programs | 7 programs across Fast, Safe and Small |
| Input-driven `jsmn-jsondump` | 138 matched inputs across the 3 modes and 552 negative controls |
| Upstream C native registry | 237 populations, with the recorded reference and local observation counts matched in all 3 modes |

Both Tier 2 receipts record underlying and checked exits of zero on `33ee3c18`. The complete logs, compiler and tool identities, differential counts, registry rows, stdout and owners are under `prototype-tier2-core/` and `prototype-tier2-integrated/`. Historical inputs, harness source, expected results and the identity record at `56eb24a6` provided the comparison contract. The builds, native checks, measurements and selector gates above ran on this cycle's measured source.

Primary review independently checked 2,133 native registry outputs and 1,422 local owner manifests. Each of the 237 populations ran once on LLVM and twice on the local routes in each of three modes. The reviewer accepted the five-file patch after inspecting source, ABI behavior, native results, timings and Tier 2. The review decision is in `prototype-promotion/primary-authorization.txt`. The maintained gate evidence and compiler build receipt are the inputs to `review-prototype-qualification/`.

## Storage and preservation

The first timing tool stopped during compilation because the pinned Zig version rejected the array repetition in its schedule test. Its successor used explicit zero-filled arrays, passed Debug and ReleaseFast schedule tests and supplied the measured tool. No timing rows came from the failed build. Its first release attempt encountered a live waiter. The subsequent collector recorded removal after the waiter closed. The original private literal-effect test and the first LLVM special-ABI caller also retained their failing receipts and diagnoses through successful controls. See `meter/disposition.md`, `meter-02/`, `prototype-development/disposition.md` and `review-prototype-abi-baseline*/`.

The two matched-assembly cohorts completed their native, timing and independent review before release. The production benchmark transaction `1795070375720477540-345180` removed nine completed workspaces and reclaimed 1,267,838,976 allocated file bytes. These included the baseline compiler, common drivers, timing tool, both original image cohorts and the native comparison objects. The final candidate source and compiler served the promotion and qualification consumers. Raw timing rows, source and tool identities, native results, disassemblies, reviewed patches and gate records remain in the batch.

The final census matched all 52 managed workspaces to removal transactions. Thirty-seven had ordinary validation lifetimes. All 13 pipelines and both retained validation investigations had explicit releases. The collector reclaimed 5,472,280,576 allocated file bytes (5.10 GiB). The batch has zero residual temporary entries, compiled programs, objects, archives, raw events or profiles. Transaction `1795074024053563021-503860` performed the last five removals and verified all ten current manifests. The seventeen independent holds matched admission.

The idle sweep `1795074227811519709-510513` found zero eligible removals. Of the thirteen remaining other-owner roots, four have aliased cache files, three await pipeline release, three are protected by the ReleaseSafe preservation hold, two retain failed workspaces for investigation and one producer is open. The validation launcher and storage collector own their reusable bootstrap caches. The evidence paths are `storage/closure.json`, `storage/removals.jsonl`, `storage/other-owners.jsonl`, `storage/manifest-integrity.path` and `storage/final-idle.path`.
