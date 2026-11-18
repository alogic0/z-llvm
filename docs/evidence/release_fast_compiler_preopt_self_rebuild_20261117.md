# ReleaseFast compiler build and self-rebuild through local preopt

The pinned stage-4 Zig compiler built upstream revision `1c08b09d` through the local optimizer and x86_64 object emitter. That new executable rebuilt the same source using a separate install prefix and fresh private caches. Both resulting compilers are byte-identical. Their SHA-256 is `622c7d9e406bc5f1cf458d6f6a7b90f5488a2566a4ec1beb47ec9c1797d84b63` over 94,633,352 bytes.

The tested backend source is `d968e3ac`. Its ReleaseFast binary has SHA-256 `90a9904d12030337a37993ade6c0609681b4e5770230bde6715f0e6934445f13`. The managed run used baseline x86_64 Linux GNU, ordinary 16 MiB stack and CPUs 0–15, `-j1`, the original LLVM-enabled CMake configuration, pinned libc inputs and resolved providers. The stage-4 frontend warmed each private cache for host tools before the corresponding build. Each build used fresh local optimization and emission with the `zig-release-fast-accepted` pass list. LLVM IR construction, bitcode handling, host tools, libraries and linking remain part of the build. [Milestone plan](../plans/2026-11-17-release-fast-compiler-preopt-self-rebuild.md)

The backend build receipt names the private checkout's parent `070dab56`. Its two-file patch has SHA-256 `5a450f6feb0e85cecda989c00fb8283b97be3e4388c83c20df1bb83a6ef31b12`. After promotion, the reviewer verified that all 679 source members matched the bytes at `d968e3ac`.

Final source and driver verification passed in `final-verification-04`. It matched all 679 compiler source files and 1,115 module and tool source identities, the SDK executable and complete library, and eight generation-specific driver bindings. Primary review rehashed all 82 final identities and separately reproduced the source archive. The preceding verifier retained exit 2 because its archive command named an absent `build.zig.zon`. The corrected verifier enumerated the five committed roots and recorded all 2,589 entries before extracting them.

## Compiler builds

| Measurement | Generation 1 | Generation 2 |
| --- | ---: | ---: |
| Compiler driver SHA-256 prefix | `d505fc64` | `622c7d9e` |
| Local optimizer / emitter invocations | 2 / 2 | 2 / 2 |
| Compiler definitions selected | 66,539 | 66,539 |
| Compiler object bytes | 105,870,528 | 105,870,528 |
| Compiler-rt definitions selected | 921 | 921 |
| Compiler-rt object bytes | 2,857,456 | 2,857,456 |
| Build command wall time | 2,092.08 s | 2,533.42 s |
| Compiler emitter wall time | 2,000.39 s | 1,997.00 s |
| Compiler emitter maximum RSS | 6,115,176 KiB | 6,082,728 KiB |

Both generations emitted the same compiler object, SHA-256 `0c2c52b3139ba04e59cbd75f13658241e9b254e69fbe4c01f6477cdad5e4be8a`. Both executables printed `0.17.0-dev.11+1c08b09d1`, compiled and ran the unchanged hello_libc and while_loops programs, and returned 1 for the invalid Zig source. Sampled free storage reached a minimum of 174,580,842,496 bytes during the two-generation run.

For each build the raw and optimized compiler inventories agree on all 66,539 definitions, 475 declarations, 52,467 globals and one alias. The compiler-rt inventories agree on 921 definitions, 48 declarations, 116 globals and 462 aliases. Independent censuses selected every definition. Each delivered object passed its ownership, ELF section, symbol and relocation checks. Each generation's ordered event audits read 26,115,184 compiler records and 425,916 compiler-rt records against their own producer and terminal reports.

Across the two generations, 28 anonymous global renamings account for every one of the 111 changed lines in each compiler-rt IR comparison. Only the ELF string table differed between the runtime objects. All allocated sections, symbol records after renaming, and relocations matched. In the local behavior runs, each raw and optimized runtime and test IR pair differed on one generated `builtin.zig` debug path. The two private caches contained identical source bytes at the recorded paths. Both behavior objects matched byte for byte.

The two linked compilers have identical section contents, build providers and resolved dynamic library bytes. The first reconciliation helper stopped on the interpreter's absolute path. The corrected check bound the executable's PT_INTERP to the interpreter's own ELF SONAME, `ld-linux-x86-64.so.2`. It checked all eight direct dependencies, fourteen build-time provider entries and nineteen resolved loader entries. The original failed receipt is in `reconcile-03`. The complete comparison is in `reconcile-04`.

## Upstream behavior

| Fresh frontend | Normal LLVM | Local preopt |
| --- | --- | --- |
| Generation 1 | 2,063 OK, 34 SKIP | 2,063 OK, 34 SKIP |
| Generation 2 | 2,063 OK, 34 SKIP | 2,063 OK, 34 SKIP |

Each of the four executions has its own build, link, native execution and checked receipt. All 2,097 names and outcomes match in order, including the skips. An independent parser checked the numbered lines and terminal totals from each original test log against its report. Each local report names its own generation's fresh LLVM report as its reference. All four match the authenticated normal ReleaseFast reference `3974cd8a`. The ordered outcome array hashes to `d2f366d355bce75fc6b8beccb234f92f48cc07b82f4acdd7607940c1103474ba` in compact jqz JSON with its terminal newline.

The two local routes produced byte-identical behavior executables, SHA-256 `9cf83220a1d488f58ae6b037d074a3dfffb86b81366a52c77cfd3dad45526c43`. Both new frontends also passed the four compile-time f80 layout checks and nine native observations.

The two local behavior audits each verified 425,916 ordered runtime records and 2,876,595 ordered test records. Both selected all 921 runtime definitions and all 7,459 test definitions. The two generations produced the same 2,884,720-byte runtime object and the same 20,353,648-byte test object.

The stage-4 seed, generation 1 and generation 2 each ran a real local optimizer with a one-byte input limit. In each case the optimizer rejected the input, the frontend exited 1, and the captured command chain ended before emission, object delivery or compiler installation. The separate invalid-Zig-source controls exercised frontend diagnostics.

## Selector checkpoints and original failures

The original whole compiler emitter returned 1 after eight selector failures. Three involved variable shifts, four involved extraction from an undefined two-word aggregate, and one involved `sliceToArrayPtr`. Its two-stage runtime path succeeded. The first review checkpoint replayed each refused real function as its own ELF object with owners. Defined numeric and guarded-byte controls passed 390 observations on each route. All five deliberately faulty variants failed their designated checks. The aggregate files matched the prior owner's repair. The shift source preserves the original refusal and rollback for i55 and i56.

| Failed whole build | Selected definitions | Successfully emitted | Failed |
| --- | ---: | ---: | ---: |
| First | 66,539 | 66,531 | 8 |
| Second | 66,539 | 66,536 | 3 |

The original compiler invocation reports and their backend stderr agree on each count. Primary review caught a mislabeled field in `publication-03` that reported successful emissions as selections. The corrected `publication-04` binds the two counts and the failures to each native command, original report, invocation and stderr. Both original exit-1 receipts and the superseded published summary are preserved.

At instruction position 145 in `sliceToArrayPtr`, forming `%46` requested spilling `%44` from RCX to slot 75, byte 600 of a 600-byte frame. The address was `%17 + 4`, and its sole load was its last use. The loaded scalar, `%45` in EAX, remained live. The reduced case requested spilling unused `%42` to slot 69, byte 552 of a 552-byte frame. Both spill victims had zero live dependent addresses or PHI obligations. The defined harness checked both last use and a derived alias surviving a clobber against guarded bytes. A two-predecessor PHI control exposed an earlier candidate that addressed byte 0 on an edge requiring byte 2.

The next whole attempt emitted those eight functions and refused three `Io.Writer.printFloat` specializations. The refused call overwrote the buffer pointer in RDI with the incoming result pointer from RDX before the buffer reached RSI. The reviewed repair saves the live source before assigning the mixed arguments. The final backend replayed all eleven extracts and passed 490 defined observations per route, including guarded incoming and frame addresses through a call that clobbers six volatile registers. All eight designated mutations were detected. Both failed build receipts and both independently reviewed patch checkpoints are retained. [Review ledger](../plans/2026-11-17-preopt-qualification-performance-self-rebuild.md#review-ledger)

## Indexed reachability

All four compiler captures have byte-identical 342,034,159-byte raw IR and 294,963,087-byte optimized IR. The optimized SHA-256 is `6f3af5dc9e2a8b716ad6dc8a561e2789f06f7b25741b4dd929933919b6be1209`. The emitter measured exclusive reachability at 3,423.803790946 seconds in the original failed build, 1.296401262 seconds after indexing on the next failed build, and 1.254359517 and 1.252821441 seconds in the two successful builds. On that optimized input, the measured speedup of the exclusive reachability phase was 2,729.52× in generation 1 and 2,732.87× in generation 2. The compiler build table reports the end-to-end command times.

## Preservation

The promoted selector passed the Debug unit suite and structural smoke gate. The ABI and encoding differential matched all 60 cases. The object and native executable gates covered 38 and 27 rows respectively with their separately recorded Debug compiler. The hello_libc check ran with LLVM and local code across ReleaseFast, ReleaseSafe and ReleaseSmall.

The fresh serial Tier 3 command completed all 17 subgates with zero local failures. It matched all 237 registered native populations on ReleaseFast, ReleaseSafe and ReleaseSmall, using the normal LLVM run and both local routes in each mode. Its real-program checks reused three authenticated AIR inputs. The full command took 1 h 3 min 10 s. The minimum available space recorded by the serial driver was 133,930,360,832 bytes.

All 180 deliberate native faults were detected. The four populations contributed 27 word-pair freeze controls, 36 integer shift controls, 90 stack-object address controls and 27 mixed stack-argument controls. These faults ran on the programs produced by the same cumulative gate. Primary review verified the 2,133 positive registry command and output records, every injected failure and all 36 fault-harness baseline commands, using the retained raw streams.

The graph-index review had already compared 120 graph observations and 54 production emissions before the selector changes. Its receipt and the historical Safe, Fast, Small and postopt qualifications retain their original compiler identities. The two successful compiler builds, four full upstream suites, f80 probes, failure controls, object censuses and ordered-event audits described above all ran afresh.

The final selector emitted identical bytes with indexed and unindexed reachability on all nine graph inputs, including the empty output and actual refusal for a reachable opaque instruction. All eight GlobalDCE fixtures matched using the project's normalizer. The seven fixtures classified as LLVM-equivalent also matched `opt-22`, and both versions of the linked C harness passed all five entry points. The original raw comparison retained its actual exit 1 for an 88-byte result whose checked-in expectation has one extra terminal LF. On the historical compiler-rt input, the original emitter produced `ed3de3e2`. Both current graph variants produced `7b65b191`. The original-to-first-selector comparison on that same input found 498 changed bodies among 921 and 296 changed normalized relocation lists. Adding the mixed-call repair caused zero further differences on this particular runtime input.

The fixed Debug behavior input contains 7,874 selected functions. The original backend reproduced the historical 27,286,368-byte object, SHA-256 `92825c8e7821e8c2becc774942f149aacfd14a99167247199b1ee44c4d4d81c1`. The final backend produced 27,507,296 bytes, SHA-256 `e02b15b20af4efa5317bc37308bf6200cd45792eec17ab77d17d1f6b05910f6e`. The strict byte comparison exited 1. Both objects retained the exact owner map and, when freshly linked against the historical Debug runtime and providers, produced all 2,097 historical fixed-local outcomes in order. These included 2,063 passes, 33 skips and the inherited failure in `behavior.floatop.test.@exp with vectors`. Mutating the wrapped-squaring function introduced exactly one further native failure.

The complete Debug ELF comparison covered all 13,755 symbols, including 7,936 defined function symbols. These covered 7,874 distinct extents and 62 additional names sharing an extent. All 5,819 non-function symbol records matched. The extra text spans contained only zeros, 1,989 bytes in the old object and 2,640 bytes in the new. Among 61,925 text relocations, every target, type and addend stayed the same. Each of the 4,916 data relocations preserved its source offset, type and target. Of their addends, 73 moved within their functions. Across all six complete variants, the 74 jump-table slots referenced the same 68 IR function/label pairs across 23 tables. Their ELF destinations matched the encoder's independently observed byte position and an instruction boundary confirmed with GNU objdump. For example, `__jmptab_371[0]` moved from +1177 to +1254 within `Io.Threaded.posixExec` and landed on `%Case` in both objects.

The original, graph, i64-shift, aggregate and mixed-call-first subjects each reproduced the historical bytes. Adding the five stack-address files to the mixed-call subject produced the exact promoted object and accounted for all 4,882 changed function bodies, 26 changed alias bodies and all 73 moved addends in that order. Applying the stack-address files first refused three `Io.Writer.printFloat` specializations and produced zero object bytes. The smallest changed function, `Io.Threaded.doNothingSignalHandler`, used RSI for the same stack address that the earlier object held in RCX. All six deliberately wrong ELF objects failed on their intended checks, including a jump-table slot redirected to a different valid block in the same function. Primary review accepted this transition for the fixed IR and promoted compiler after independently checking all six variants with LLVM disassembly.

## Storage

The two failed whole builds each recorded a completed native build command with exit 1. The original collector refused explicit release of the nested workspaces. The reviewer held the first proposed fix because another layout key in the same evidence directory could cite the same report. At `b6f04956`, the collector requires the whole-compiler `validation` owner and its actual install and cache paths as well as the authenticated command and nonzero exit. The frozen two-file patch passed 41 isolated CLI cases on each of Debug and ReleaseFast. The reviewer verified both original layouts and the native refusal and collection receipts.

The installed collector, SHA-256 `cfe7e9c514a1e7a705ba72fd778d6299f9e6c7a3aa56319be2c41d6ff3c0124c`, repeated all 41 cases. Its first production dry review also found the completed fixture owner's empty scratch. A separately reviewed one-byte budget collected just that empty workspace. The unchanged project policy then selected exactly the two failed-build workspaces and reclaimed 1,693,540,352 allocated bytes. The reviewer rehashed both original reports, commands, checked exits and strict audits, verified all eight historical roots were absent, and closed the blocker. All nine prior manifests and seventeen independent holds matched admission.

Once their ordered audits and downstream comparisons had completed, the eight successful raw event streams went through a separate reviewed dry run and apply. The collector reclaimed 19,753,529,344 allocated bytes. The complete captured IR, diagnostic reports, owners, ELF contracts, inventories, profiles and ordered audit results remain in the batch.

The collector also returned `SpecialCacheEntry` on the final investigator's four symbolic links to its preceding source variants. Primary review verified all four links and authorized their teardown. The checked producer verified both owners, all nine prior manifests and seventeen holds, removed the four links and rehashed all eight referenced compilers and objects. It completed with exit 0. The first refused release retains exit 1. The first idle collection released the final replay workspace. Its predecessor was still pinned by the teardown's ordinary eight-line hash list because the filename ended in `.sha256`. The reviewed correction preserved the inode, all 1,898 original bytes and all eight target hashes under `original-targets.txt`. The original pin report, collector refusal and successful filename correction are retained. Primary review confirmed the four investigation roots were removed under native receipts `1795030684459571839-3103291` and `1795031578248386392-3134152`. The four actions reclaimed 1,796,349,952 allocated bytes.

The six final workspace removals reclaimed 2,925,318,144 allocated bytes across their original collector transactions. The checked outer build workspace was collected at normal validation completion. The collector released the nested two-generation build, final selector checkout, two backend compilers and qualified tools after their last consumers. Each of the six paths has a matching removed action and collector receipt.

The final census covers every owned workspace and checks for residual temporary entries, compiled payloads and raw event streams. A separate idle sweep follows the last removal. The registered proof includes original compiler and behavior receipts, audited IR, source identities, and both captured streams for the 2,133 positive registry executions, 36 fault baselines and 180 injected faults. The registration receipt records the tenth verified manifest and seventeen pre-existing holds.

## Evidence locations

The batch lives at `local-state/validations/compiler-preopt-self-rebuild-20261117/batch-01`. [Machine-readable qualification](release_fast_compiler_preopt_self_rebuild_20261117.json)

| Evidence | Path within the batch |
| --- | --- |
| First and second selector patches, operands, disassembly and guarded native controls | `selector-combined/selector-review.md`, `selector-mixed-call/selector-review.md` |
| Failed whole attempts and original audits | `build-01`, `build-02`, `build-01-original-audit`, `build-02-original-audit` |
| Fresh build commands, frontend identity, resources, IR and object receipts | `build-03/run/report.json`, `build-03/run/self-rebuild` |
| Four full suite executions and original numbered lines | `build-03-{initial,self}-{llvm,local}/run` |
| Whole and local suite censuses, ELF contracts and ordered audit references | `build-03-{initial,self}-{compiler-audit,local-audit}` |
| Cumulative preservation and native faults | `integration-03/report.json`, `preservation-faults-03/report.json` |
| Failure controls | `seed-control-03`, `build-03-{initial,self}-optimizer-failure` |
| Fixed Debug native outcomes, complete ELF and per-source case attribution | `preservation-native-transition-03`, `preservation-native-intermediates-04`, `preservation-native-intermediates-05`, `preservation-native-elf-03` |
| Final-selector graph preservation | `preservation-graph-04/report.json` |
| Matched reachability and cross-generation reconciliation | `reachability-full-03/report.json`, `reconcile-04/report.json` |
| Reviewed Debug workspace release records and actual native removals | `storage/preservation-diagnosis-03/actual-removals.jsonl` |
| Final compiler, SDK, sources, driver paths and failure diagnosis | `final-verification-04/report.json`, `final-verification-03/diagnosis.md` |
| Six final compiler, tool and build workspace removals | `storage/final-products-03/actual-removals.jsonl` |
| Corrected published qualification, invocation counts and document checks | `publication-04/qualification.json`, `publication-04/original-attempts.json`, `project-docs-04/checks.json` |
| Original suite, module, ordered-event and failure-control inventories | `publication-03/{suites,modules,events,controls}.json` |
| Final workspace census, native collection and idle sweep | `final-storage-03/report.json`, `final-storage-03/transactions.jsonl` |
| Maintained proof manifest and registration | `maintained-compiler-preopt-self-rebuild-20261117.sha256`, `final-storage-03/policy-registration/report.json` |
