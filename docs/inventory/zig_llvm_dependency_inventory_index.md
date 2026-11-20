# Zig LLVM Dependency Inventory Index

This is the top-level inventory index for Zig's current dependency on LLVM, LLD,
and Clang-adjacent behavior.

The project goal is not to clone all of LLVM in isolation. The goal is to map the
LLVM behavior Zig actually depends on, reproduce required optimizer and IR
semantics in small verified slices, and keep backend, linker, C frontend, debug,
bitcode, sanitizer, and LTO work separated until a Zig-backed need is documented.

All paths are relative to `prog`.

## Inventory Files

| Inventory | Owner area | Purpose | Current status |
| --- | --- | --- | --- |
| `z_llvm/docs/inventory/zig_llvm_api_inventory.md` | API, IR, target, codegen, debug, bitcode, linker | Maps Zig's direct LLVM/ZigLLVM/LLD binding surface to local replacement owners. | Source-backed foundation; needs periodic refresh when Zig changes bindings. |
| `z_llvm/docs/inventory/zig_llvm_pass_pipeline_inventory.md` | optimizer pipeline | Maps the LLVM pass pipeline Zig invokes through `TargetMachine.emitToFile`. | Source-backed foundation with priorities and local status. |
| `z_llvm/docs/fixtures/zig_emitted_ir.md` | Zig-emitted IR corpus | Records fixture strategy for real Zig-emitted LLVM IR. | Bootstrap corpus complete for initial source-backed parser/verifier/optimizer slices. |
| `z_llvm/docs/semantics/ir_verifier_foundation.md` | IR semantics | Records the first LLVM-compatible verifier milestone and comparison boundary. | Implemented for the accepted scalar/control-flow IR subset. |
| `z_llvm/docs/semantics/mandatory_canonicalization.md` | optimizer canonicalization | Records the P0 canonicalization set, ordering contract, fixtures, and unsupported LLVM gaps. | Implemented as fixture-equivalent subsets for the accepted IR surface. |
| `z_llvm/docs/semantics/memory_side_effect_semantics.md` | memory legality | Records the shared memory-effect, alias/mod-ref, MemoryLocation, and MemorySSA gap contract. | Implemented as a conservative legality layer used by memory-sensitive passes. |
| `z_llvm/docs/semantics/scalar_optimization_pipeline.md` | scalar optimizer | Records the scalar pass dependency map, pass statuses, fixtures, ordering, and deferred algorithms. | Implemented for DCE, ADCE, SCCP, GVN, DSE fixture subsets plus EarlyCSE foundation. |
| `z_llvm/docs/semantics/loop_optimization_pipeline.md` | loop optimizer | Records loop canonical form, LoopInfo helper APIs, LICM legality, missing loop analyses, and deferred transforms. | Implemented as LoopInfo/LICM foundation with fixture-equivalent scalar LICM cases. |
| `z_llvm/docs/codegen/zig_native_backend_handoff.md` | native backend handoff | Maps local optimizer facts to Zig AIR, Liveness, native codegen, MC/object validation, and out-of-scope backend replacement work. | Source-backed handoff study; backend experiments remain validation-only unless explicitly activated. |
| `z_llvm/docs/semantics/optional_bitcode_debug_lto_tracks.md` | optional tracks | Keeps bitcode, debug info, LTO, sanitizer, vectorization, and target-codegen details separated with activation criteria. | Source-backed index; no optional track is active by default. |
| `z_llvm/docs/bitcode/construct_inventory.md` | bitcode | Inventories module/type/value/function/metadata/summary constructs needed before a bitcode writer or parser. | Inventory only; no writer/parser. |
| `z_llvm/docs/debug/metadata_inventory.md` | debug info | Inventories Zig-emitted debug metadata and optimizer preservation rules. | Raw metadata preservation only; debug semantics deferred. |
| `z_llvm/docs/lto/behavior_gaps.md` | LTO | Records Zig LLVM LTO phase choices, local placeholder status, and LTO gap table. | Pre-link pipeline surface only; bitcode and summaries deferred. |
| `z_llvm/docs/analysis/optimizer_analysis_prerequisites.md` | optimizer analyses | Inventories shared analysis hooks required before optimizer algorithm parity claims. | Current hooks and missing parity blockers documented. |
| `z_llvm/docs/ir/unsupported.md` | gap tracking | Lists IR constructs this project rejects, defers, or supports narrowly. | Must be updated whenever parser/verifier/pass behavior changes. |
| `z_llvm/docs/roadmap/llvm_algorithm_parity_gap_closure_plan.md` | optimizer parity rubric | Tracks gaps between local optimizer passes and original LLVM algorithms. | Rubric for optimizer epics, not a global blocker. |

## Dependency Categories

Use these categories consistently in inventories and roadmap slices:

| Category | Meaning | First local owner |
| --- | --- | --- |
| `IR semantics` | LLVM-compatible module, function, type, value, instruction, metadata, verifier, and textual IR behavior. | `src/ir/`, `docs/ir/*.md` |
| `optimizer` | LLVM middle-end passes and analyses Zig invokes through LLVM pipelines. | `src/passes/`, `src/analysis/`, `docs/passes/` |
| `target/data-layout` | Triple, target feature, address-space, ABI, size, alignment, and DataLayout facts. | `src/target/`, `docs/target/` |
| `codegen` | TargetMachine behavior, instruction selection, register allocation, stack frame, ABI lowering, and assembly/object handoff. | `src/codegen/`, `docs/codegen/` |
| `debug info` | Debug metadata validation/preservation/emission and DWARF/CodeView behavior. | `src/debug/`, `docs/passes/instrumentation_metadata.md` |
| `object/linker` | MC, assembly printer, relocations, object/archive writing, LLD invocation, and linker command shaping. | `src/mc/`, `docs/mc/` |
| `C frontend` | Clang driver, `zig cc`, `zig c++`, `translate-c`, preprocessing, and C/C++ option compatibility. | Inventory only unless optimizer behavior depends on it. |
| `LTO` | Thin/full LTO pre-link/post-link pipeline behavior, bitcode handoff, summaries, import/export, and WPD. | `src/bitcode/`, `docs/passes/lto_prelink.md` |
| `sanitizer/instrumentation` | SanitizerCoverage, TSan, entry/exit instrumentation, and related pass extension points. | Placeholder docs until IR/metadata support exists. |
| `tooling` | LLVM command-line options, time reports, pass-limit, diagnostics, host CPU discovery, and comparison harnesses. | `src/pipelines.zig`, tools, docs |

## Source-Backed Dependency Matrix

| Source anchor | Dependency | Category | Hard or optional | Local action |
| --- | --- | --- | --- | --- |
| `ziglang/src/Compilation/Config.zig:190` | Decides whether the LLVM library may be used to build LLVM modules. | tooling | hard policy input | Document and use as the boundary between LLVM backend and libLLVM dependency removal. |
| `ziglang/src/Compilation/Config.zig:202` | Chooses Clang or Aro for C frontend work. | C frontend | optional/handoff | Keep out of optimizer work; track only when C frontend behavior affects emitted IR fixtures. |
| `ziglang/src/Compilation/Config.zig:317` | Chooses whether Zig uses the LLVM backend for machine code generation. | target/data-layout, codegen | hard policy input | Use this as the roadmap boundary for native-backend handoff work. |
| `ziglang/src/Compilation/Config.zig:381` | Chooses LLD or Zig's own linker. | object/linker | optional/handoff | Keep final linker ownership with Zig; track only object handoff compatibility here. |
| `ziglang/src/target.zig:167` | Records targets where LLVM has non-experimental support. | target/data-layout, codegen | hard for LLVM-backed paths | Inventory target coverage before adding backend work. |
| `ziglang/src/target.zig:260` | Records targets where Zig supports LLD. | object/linker | optional/handoff | Use as linker inventory source; do not make it optimizer scope. |
| `ziglang/src/target.zig:478` | Records Clang assembler and target-option quirks. | C frontend, target/data-layout | optional/handoff | Inventory only unless target-option semantics change LLVM IR generation. |
| `ziglang/src/codegen/llvm.zig:1006` | Maps Zig optimize mode to LLVM codegen and pipeline options. | optimizer, codegen | hard for LLVM-backed release/debug modes | Keep pass pipeline inventory synchronized with this source. |
| `ziglang/src/codegen/llvm.zig:1057` | Builds `TargetMachine.EmitOptions`. | optimizer, codegen, debug info, LTO, tooling | hard for LLVM-backed emit paths | Treat `EmitOptions` as the root of pipeline, sanitizer, LTO, and output-file inventory. |
| `ziglang/src/codegen/llvm.zig:1121` | Calls `TargetMachine.emitToFile`. | optimizer, codegen, object/linker, LTO | hard for LLVM-backed emit paths | Use as the main LLVM backend integration boundary. |
| `ziglang/src/codegen/llvm/FuncGen.zig` | Lowers Zig AIR into LLVM IR builder operations. | IR semantics, target/data-layout, codegen, debug info | hard for LLVM backend correctness | Build the Zig-emitted IR corpus from representative AIR lowering areas before expanding passes. |
| `ziglang/src/codegen/llvm/bindings.zig:16` | `MemoryBuffer` and bitcode parsing input. | LTO, tooling | optional/handoff | Track for bitcode compatibility; not a native optimizer blocker. |
| `ziglang/src/codegen/llvm/bindings.zig:25` | LLVM context, bitcode parse, opt-bisect, debug-info diagnostics, integer type construction. | IR semantics, debug info, tooling, bitcode | hard for libLLVM-backed paths | Replace with local IR context/verifier/tooling surfaces where used by local tests. |
| `ziglang/src/codegen/llvm/bindings.zig:56` | TargetMachine creation, emit options, `emitToFile`, DataLayout creation. | target/data-layout, optimizer, codegen, object/linker, LTO | hard for LLVM-backed emit paths | Keep split across target, optimizer, codegen, MC/object, and bitcode tracks. |
| `ziglang/src/codegen/llvm/bindings.zig:185` | Target lookup from triple. | target/data-layout | hard for LLVM-backed emit paths | Keep target recognition source-backed. |
| `ziglang/src/codegen/llvm/bindings.zig:190` | TargetInfo/Target/TargetMC/AsmPrinter/AsmParser registration. | target/data-layout, codegen, object/linker, tooling | hard for LLVM-backed emit paths | Inventory by target family before broad backend work. |
| `ziglang/src/codegen/llvm/bindings.zig:310` | LLD COFF/ELF/Wasm entry points. | object/linker | optional/handoff | Out of optimizer scope; keep only dependency accounting here. |
| `ziglang/src/codegen/llvm/bindings.zig:318` | LLVM archive writer kind mapping. | object/linker | optional/handoff | Track under archive/linker work, not optimizer. |
| `ziglang/src/codegen/llvm/bindings.zig:336` | LLVM command-line option parsing. | tooling | optional | Defer unless local pipeline diagnostics need compatibility. |
| `ziglang/src/codegen/llvm/bindings.zig:339` | Host CPU name/features. | target/data-layout, tooling | optional/handoff | Defer until target feature modeling matters for accepted fixtures. |
| `ziglang/src/zig_llvm.cpp:225` | Implements Zig's LLVM emit path, pass pipeline construction, codegen pass manager, IR/bitcode/object/asm outputs. | optimizer, codegen, object/linker, LTO, tooling | hard for LLVM-backed emit paths | Treat as the authoritative source for pipeline and codegen boundary behavior. |
| `ziglang/src/zig_llvm.cpp:284` | Configures LLVM `PipelineTuningOptions`. | optimizer | hard for release/debug pipeline parity | Keep pass inventory tied to these options. |
| `ziglang/src/zig_llvm.cpp:322` | Registers Zig's pipeline-start extension callback. | optimizer, debug info | hard when assertions/debug metadata apply | Track verifier and AddDiscriminators behavior in pass inventory. |
| `ziglang/src/zig_llvm.cpp:335` | Registers optimizer-early sanitizer callbacks. | sanitizer/instrumentation, optimizer | optional mode-dependent | Keep sanitizer instrumentation placeholder until IR/metadata support exists. |
| `ziglang/src/zig_llvm.cpp:350` | Registers optimizer-last sanitizer/verifier callbacks. | sanitizer/instrumentation, optimizer | optional mode-dependent | Keep explicit in pipeline inventory. |
| `ziglang/src/zig_llvm.cpp:381` | Chooses O0, LTO pre-link, or per-module default pipeline. | optimizer, LTO | hard for pipeline parity | Use as the source of mode-specific pipeline rows. |
| `ziglang/src/zig_llvm.cpp:389` | Runs legacy codegen pass manager after new-PM optimization. | codegen | hard for object/asm output | Keep codegen and MC/object work separate from optimizer parity. |
| `ziglang/src/zig_llvm.cpp:413` | Emits textual LLVM IR after optimization/codegen setup. | IR semantics, tooling | optional/comparison | Useful for fixture comparison; not final architecture. |
| `ziglang/src/zig_llvm.cpp:419` | Writes bitcode for LTO and explicit bitcode output. | LTO | optional/handoff | Track under optional bitcode/LTO. |
| `ziglang/src/zig_llvm.cpp:462` | Installs broken-debug-info diagnostic handler. | debug info | optional mode-dependent | Inventory until debug metadata preservation becomes active. |
| `ziglang/src/zig_llvm.cpp:475` | Writes LLVM-compatible archives. | object/linker | optional/handoff | Defer unless archive tooling enters local scope. |
| `ziglang/src/zig_llvm.cpp:510` | Calls LLD COFF/ELF/Wasm drivers. | object/linker | optional/handoff | Not this repository's optimizer scope. |
| `ziglang/src/link/Lld.zig:265` | Builds and invokes LLD jobs. | object/linker | optional/handoff | Keep command-shaping notes separate from optimizer work. |
| `ziglang/src/link/Lld.zig:285` | Writes archives through `ZigLLVMWriteArchive`. | object/linker | optional/handoff | Defer to linker/archive roadmap if needed. |
| `ziglang/src/link/Lld.zig:369` | Shapes COFF LLD invocation. | object/linker | optional/handoff | Not optimizer scope. |
| `ziglang/src/link/Lld.zig:758` | Shapes ELF LLD invocation. | object/linker | optional/handoff | Not optimizer scope. |
| `ziglang/src/link/Lld.zig:1351` | Shapes Wasm LLD invocation. | object/linker | optional/handoff | Not optimizer scope. |

## API Inventory Cross-Index

| API group | Primary inventory | Category | Local replacement status | Next required action |
| --- | --- | --- | --- | --- |
| LLVM context, module lifetime, scalar type construction | `zig_llvm_api_inventory.md` | IR semantics | partial local text IR module and integer IR | Expand only for Zig-emitted fixtures. |
| Bitcode parse/write | `zig_llvm_api_inventory.md` | LTO | missing/deferred | Keep optional compatibility track separate from optimizer work. |
| TargetMachine create/emit/DataLayout | `zig_llvm_api_inventory.md` | target/data-layout, optimizer, codegen | DataLayout and tiny x86_64 emit bootstrap only | Do not expand codegen without a handoff or validation slice. |
| Target registration and host CPU features | `zig_llvm_api_inventory.md` | target/data-layout | target recognition foundation only | Add target-feature inventory before implementation. |
| LLD and archive bindings | `zig_llvm_api_inventory.md` | object/linker | mostly out of scope | Keep as dependency accounting unless linker roadmap activates. |
| Debug-info diagnostics | `zig_llvm_api_inventory.md` | debug info | missing/deferred | Track metadata preservation before implementing debug emission. |
| PassBuilder pipelines and extension points | `zig_llvm_pass_pipeline_inventory.md` | optimizer, sanitizer/instrumentation, LTO | priorities and placeholders recorded | Pull optimizer work from pipeline inventory only. |

## Pass Pipeline Cross-Index

| Pipeline area | Primary inventory section | Category | Local replacement status | Next required action |
| --- | --- | --- | --- | --- |
| Debug O0 mandatory pipeline | `zig_llvm_pass_pipeline_inventory.md` | optimizer, sanitizer/instrumentation | verifier and always-inline surface mostly placeholder/foundation | Keep O0 fixtures narrow and source-backed. |
| Release O3/Oz default pipeline | `zig_llvm_pass_pipeline_inventory.md` | optimizer | scalar/memory/loop foundations plus many placeholders | Close algorithm parity gaps before broadening pass count. |
| LTO pre-link pipeline | `zig_llvm_pass_pipeline_inventory.md` | LTO, optimizer | placeholder/deferred | Do not implement post-link or summary work until bitcode need is selected. |
| Sanitizer and coverage extension points | `zig_llvm_pass_pipeline_inventory.md` | sanitizer/instrumentation, debug info | placeholder | Keep explicit, but out of optimizer foundation. |
| Vector and coroutine passes | `zig_llvm_pass_pipeline_inventory.md` | optimizer, IR semantics | placeholder/deferred | Require vector/coroutine IR surface first. |

## Hard Dependencies Versus Optional Handoff Paths

| Dependency | Classification | Reason |
| --- | --- | --- |
| Zig-emitted LLVM IR semantics from `FuncGen.zig` | hard dependency | Local optimizer and verifier work must understand the IR Zig actually emits. |
| PassBuilder pipeline invoked by `ZigLLVMTargetMachineEmitToFile` | hard dependency | Optimizer work must come from Zig's real LLVM pipeline, not a generic pass list. |
| Target triple, DataLayout, ABI, and target feature facts | hard dependency | LLVM-compatible IR and optimizer legality depend on these facts. |
| LLVM backend codegen and MC/object emission | optional handoff/study path | Zig has native backends; local codegen work should validate boundaries before becoming broad replacement work. |
| LLD invocation and archive writing | optional handoff path | Linker replacement is separate from optimizer reproduction. |
| Clang driver, C frontend, preprocessor, and `translate-c` | optional handoff path | Aro and separate Zig work own this area unless it changes optimizer input. |
| Debug metadata, sanitizer instrumentation, and profile metadata | optional mode-dependent path | Important for full Zig behavior, but should follow IR/metadata foundations. |
| Bitcode and LTO | optional compatibility path | Useful for LLVM handoff without libLLVM, but not required for native optimizer slices. |

## Not This Repository Unless Activated By A Source-Backed Slice

| Area | Source anchor | Default disposition | Activation condition |
| --- | --- | --- | --- |
| Full LLD replacement | `ziglang/src/link/Lld.zig` | not optimizer scope | Activate only from a linker-specific roadmap. |
| `zig ar` and archive tooling | `ziglang/src/zig_llvm-ar.cpp`, `ziglang/src/zig_llvm.cpp:475` | dependency accounting only | Activate only if archive output affects local validation fixtures. |
| Clang driver compatibility for `zig cc`/`zig c++` | `ziglang/src/zig_clang_driver.cpp` | not optimizer scope | Activate only if a C frontend fixture is needed to produce optimizer input. |
| Clang `cc1` and assembler entry points | `ziglang/src/zig_clang_cc1_main.cpp`, `ziglang/src/zig_clang_cc1as_main.cpp` | not optimizer scope | Activate only for C frontend or assembler compatibility work. |
| `translate-c` and preprocessing | `ziglang/src/Compilation/Config.zig:202` | handoff to Clang/Aro work | Activate only when emitted IR or ABI behavior changes optimizer requirements. |
| Full native backend replacement | `ziglang/src/codegen/*` | not local default goal | Activate only through native-backend handoff study. |
| General-purpose multi-target object writer | `ziglang/src/zig_llvm.cpp:389` | validation only | Activate only when target-backed MC/object fixtures require it. |

## Gap Table

| Gap | Category | Why it matters | Current action |
| --- | --- | --- | --- |
| Real Zig-emitted IR corpus is intentionally small. | IR semantics | Optimizer work can still drift if future passes are not tied to a source-backed fixture. | Extend the Epic 2 corpus only when a new parser, verifier, optimizer, target, or metadata slice needs that IR construct. |
| API inventory is grouped, not mechanically exhaustive by every builder call in `FuncGen.zig`. | IR semantics, target/data-layout | Missing builder operations can hide required IR constructs. | Add source-generated or manually audited AIR-to-IR rows as fixtures are added. |
| Pass inventory records pass names and priorities, but many local passes are subsets/placeholders. | optimizer | Same-named local passes can be mistaken for LLVM algorithm parity. | Use `llvm_algorithm_parity_gap_closure_plan.md` before claiming reproduction. |
| Target features and host CPU detection are inventoried but not implemented. | target/data-layout | LLVM legality and cost decisions depend on features. | Defer until accepted fixtures require target feature checks. |
| Debug metadata, sanitizer coverage, TSan, and profile metadata are mostly placeholders. | debug info, sanitizer/instrumentation | Zig modes can request these through LLVM extension points. | Keep mode-dependent placeholders and do not silently drop metadata once parsed. |
| LTO and bitcode are not represented enough for real replacement. | LTO | Zig may keep LLVM IR/bitcode handoff without linking libLLVM. | Track separately from optimizer implementation. |
| Linker/archive/Clang dependencies are visible but not local implementation goals. | object/linker, C frontend | They are part of Zig's LLVM removal issue but separate from optimizer work. | Keep them in "not this repository" tables unless activated. |

## Maintenance

Refresh this inventory whenever Zig's LLVM integration changes:

```sh
rg -n "LLVM|llvm|ZigLLVM|ZigLLD|Clang|clang|PassBuilder|TargetMachine|emitToFile|WriteArchive" ziglang/src -g '*.zig' -g '*.cpp' -g '*.h'
rg -n "buildO0DefaultPipeline|buildPerModuleDefaultPipeline|buildLTOPreLinkDefaultPipeline|PipelineTuningOptions|register.*EPCallback" ziglang/src/zig_llvm.cpp llvm-project-22/llvm/lib/Passes llvm-project-22/llvm/include/llvm/Passes
opt-22 -passes='default<O0>' -print-pipeline-passes -disable-output /dev/null
opt-22 --enable-merge-functions -passes='default<O3>' -print-pipeline-passes -disable-output /dev/null
opt-22 --enable-merge-functions -passes='default<Oz>' -print-pipeline-passes -disable-output /dev/null
opt-22 --enable-merge-functions -passes='lto-pre-link<O3>' -print-pipeline-passes -disable-output /dev/null
opt-22 --enable-merge-functions -passes='lto-pre-link<Oz>' -print-pipeline-passes -disable-output /dev/null
```

Refresh checklist:

- [ ] Re-run the source searches above.
- [ ] Update `zig_llvm_api_inventory.md` when bindings, `FuncGen.zig`, target
      policy, or LLD/Clang boundaries change.
- [ ] Update `zig_llvm_pass_pipeline_inventory.md` when `zig_llvm.cpp` pipeline
      construction, extension points, tuning options, sanitizer options, or LTO
      mode handling changes.
- [ ] Update this index when a dependency changes category, owner, hard/optional
      status, or local action.
- [ ] Update the [unsupported IR reference](../ir/unsupported.md) and fixture docs when a new Zig-emitted IR
      construct is discovered.
- [ ] Keep all file references relative to `prog`; do not write machine-local
      absolute paths in docs or commit messages.
