# Next Steps

This file is the active work queue only. Durable roadmap checklists and history
live under `docs/roadmap/`.

Future checklist items must include upstream LLVM mapping before they can be
marked complete. See [development_cycle.md](development_cycle.md) and
[stub_replacement_cycle.md](stub_replacement_cycle.md).

## Structural Debt Status

The release pass pipeline surface is now registry-driven in `src/pipelines.zig`.
Each registered pass records its upstream path and status:
`implemented`, `placeholder`, `conservative`, `boundary-noop`, or
`out-of-scope`. `addPass` rejects unknown pass names, and
`zig build release-pipeline-policy` prints machine-readable counts for active
release pipelines. The accepted Zig ReleaseFast/ReleaseSafe/ReleaseSmall
pipelines have no placeholders; `release-o3` and `release-oz` now also have
zero ambiguous placeholders, with remaining non-transforming surfaces counted as
explicit boundary-noop or out-of-scope entries. LTO prelink still has one
placeholder (`name-anon-globals`) plus explicit boundary counts. A placeholder
means "known upstream pass surface, no local algorithm or final policy yet," not
implemented release coverage.
`docs/roadmap/release_placeholder_classification.md` now classifies the active
Release O3/Oz placeholders by x86_64 replacement relevance. `inferattrs`,
`aggressive-instcombine`, and `lower-constant-intrinsics` have conservative
local subsets; `add-discriminators`, `forceattrs`, `mergefunc`, and
`annotation-remarks` are explicit boundary-noop or out-of-scope surfaces until
source-backed rows require implementation.

Release optimizer evidence has a focused real-AIR gate:
`zig build distribution-air-release-broad`. It runs the broad x86_64
ReleaseFast/ReleaseSafe/ReleaseSmall real-AIR corpus through local z_llvm
optimization/codegen, object emission, Zig native linker handoff, and executable
classification. The current broad release row counts are documented in
`docs/roadmap/x86_64_distribution_replacement_matrix.md`; this gate is the
development-loop proof for broad release optimizer behavior and remains outside
`distribution-all`.

Debug variable-location salvage remains a deliberate boundary. The pass manager
now scans for `llvm.dbg.value`/variable-location intrinsics once per
pass-manager run, skips transform passes from the cached result, reports
`skipped_transform_passes` in the normal summary, and still runs mandatory
verifier passes. Full salvage is still future work, not an implicit transform
claim.

The uncurated AIR build topology is generated through one helper over typed
`mode/corpus/variant` tuples, while preserving the public build step names for
discovery, object progress, object inspection, native-link progress,
executable progress, and strict-finish gates. Mode, corpus, and variant
routing now use `build.zig` enums instead of runtime string comparisons, so new
gate variants must enter through the shared metadata path. Use focused row/gate
commands and `zig build structural-smoke` during iteration; keep
`distribution-all` as a milestone confirmation gate.

Remaining intentional facade surfaces are now explicit tables instead of
scattered string comparisons where practical. Structured-direct surfaces that
must run the local fold pipeline live in
`src/main_flow_ir_writer.zig` as `structured_direct_fold_pipeline_surfaces`,
with a reason per surface. DescriptorV2 is no longer a monolithic location for
all behavior: types, programs, verifier, lowering, canonicalization, and API
facades live in the split `src/semantic_descriptor_v2_*.zig` files, while
IR-writer case routing lives under `src/main_flow_ir_writer*.zig`.

## Active Cycle

Compiler-core refactor plan:
The body-aware compiler-core inventory shows the five highest repeated
unsupported categories are `aggregate-abi`, `unknown-opcode`, `vector`, `x87`,
and `packed-aggregate`. Treat this as a refactor slice before expanding more
compiler-core lowering. The goal is to remove duplicated classifiers and
selected fixture logic in the layers that will receive the next implementation
work.
The ranked inventory report is
`docs/roadmap/x86_64_compiler_core_inventory_priorities.md`; it is count-only
evidence, not a replacement claim.

Execution order:

1. Registry slice: `src/zig_air_capabilities.zig` now provides the shared AIR
   opcode capability registry for inventory, typed AIR diagnostics, and
   lowering eligibility. It records category, explicit status
   (`lowerable`, `boundary`, `inventory-only`, `ignored-metadata`, or
   `unknown`), owning layer (`semantic-lowering`, `cfg-lowering`,
   `abi-planner`, `backend`, etc.), lowerer kind, inventory-known status,
   metadata-ignore status, straight-line lowering eligibility, typed-v2
   lowering eligibility, and first boundary/fallback reason. The first local
   string allowlists were removed from inventory and lowering code; generic
   typed-CFG eligibility now reads the registry capability object instead of
   asking scattered boolean helpers.
   Typed-v2 fallback diagnostics now also use registry status/boundary reasons
   instead of reporting a generic local `unsupported_opcode` bucket.
   The first data-kind capability API now classifies opcode/data-kind pairs and
   standalone data-kind surfaces into owner categories, and inventory consumes
   that object for unknown-opcode reporting. The typed-v2 dispatch now treats
   registry lowerability as the front-door gate and routes accepted
   instructions through `LowererKind` groups before reaching local opcode
   lowerers. Typed semantic-domain operations are now also selected by
   registry-owned operation IDs for scalar, memory, optional, error-union, and
   pointer/aggregate op families; typed CFG operations (`block`, `cond_br`,
   `ret`/`ret_safe`, and `unreach`) use the same registry-owned routing. Next
   work: keep moving per-operation validation and value materialization from
   local shape checks into the normalized model and shared capability helpers.
   Call tail-kind policy and inventory call recognition now also delegate to
   the shared capability registry instead of local opcode tables.
2. Normalized typed-AIR slice: `src/zig_air_model.zig` now provides the first
   reusable typed function view over structured-air v1/v2 bodies,
   instructions, and opcode capabilities. The generic typed-CFG block
   classifier is the first consumer, so future CFG/semantic lowerers can move
   from raw opcode/data-kind string checks toward one function/body/instruction
   model without changing accepted frontier behavior. The typed-v2 fallback
   scanner now also uses this view for body, instruction, and capability
   lookup. Generic-CFG branch/guard classification now has view-backed helper
   paths for return, noreturn, void-branch, and branch-body checks, with the
   obsolete raw return-body parser helpers removed. The typed lowering context
   now carries the typed view and uses it for block-body lookup, void guard
   checks, return checks, noreturn panic paths, and branch-value extraction.
   Terminal error-union conditional checks also use the same model. Local
   typed-opcode scans are moving into `TypedFunctionView` as reusable
   predicates, and the semantic typed-v2 dispatcher is now split into
   registry-selected scalar, memory, optional, error-union, and
   pointer/aggregate domains so future model-backed lowering does not grow
   another monolithic opcode chain. Branch-merge body lowering now also uses
   the view for child instruction lookup and metadata capability checks instead
   of indexing raw structured-air records directly, the main generic typed-v2
   lowering loop now resolves instructions through the same view, and terminal
   error-union `cond_br` recognition is owned by `TypedFunctionView`. Typed
   block-target operand parsing now lives in `src/zig_air_model.zig`. Typed
   instruction detail and operand-text lookup now follow the same model-owned
   pattern, including the legacy operand-key fallback. Typed direct/extern
   callee parsing now also lives in the model.
   Typed void-guard and generic CFG block predicates now live on
   `TypedFunctionView`; fallback diagnostics in `src/zig_air_lowering.zig`
   call the model predicates directly. The unused
   parser-side typed CFG/void-guard wrappers and raw helper copies have been
   removed. `src/zig_air_lowering_typed_v2.zig` now also reads typed detail,
   operand text, and callee records from the model helpers instead of parser
   wrappers. The obsolete parser typed-record wrappers for block targets,
   instruction details, operand text, and callees have been removed. Typed
   instruction index/opcode
   lookup is also now model-owned, with typed-v2 helpers reading through
   `src/zig_air_model.zig`; the obsolete parser lookup wrappers have been
   removed. Lowering modules now ask `src/zig_air_capabilities.zig` directly,
   so there is no parser facade for ignored, straight-line, arithmetic, shift,
   cast, field-pointer, call, or typed-v2 lowerable opcode checks.
   Typed branch-to-i32-constant queries now also live in
   `src/zig_air_model.zig`, so optional-payload fallback and dense-switch
   result extraction no longer scan raw typed-v2 records locally. The
   opcode-filtered typed i32 operand query used by optional-pointer add
   lowering is model-owned as well. Typed-v2 lowering now also calls the
   model-owned opcode and return-opcode count helpers directly instead of
   keeping pass-through wrappers, and the remaining typed-v2 field-pointer,
   callee-name, and store-count wrappers have been removed. The legacy typed
   compatibility path now uses the same model-owned count helpers rather than
   local duplicates. Return-opcode recognition is now capability-registry
   owned and consumed by the AIR model instead of repeated `ret`/`ret_safe`
   string pairs; unreach and CFG opcode recognition (`block`, `br`,
   `cond_br`) follow the same capability-owned path, and
   `cfgLoweringOpForOpcode` now consumes those helpers instead of keeping a
   separate string-dispatch table. Typed-v2 lowerability, lowerer selection,
   and capability-owner routing now use the same predicates for these opcodes,
   so the registry no longer has duplicate local CFG/return checks. The AIR
   lowering fallback scanner and legacy typed lowering path now also use these
   capability predicates for block/branch/return/unreach identity rather than
   repeating local string comparisons. Typed block lowering, branch-merge
   materialization, void-guard panic blocks, and legacy select block
   materialization now use the same predicates as well, leaving operand counts
   and CFG shape validation local but opcode identity registry-owned.
   Semantic-domain routing now delegates to the registry's per-domain
   operation IDs instead of carrying a second opcode allowlist for scalar,
   memory, optional, error-union, and pointer/aggregate domains. Capability
   owner routing now uses that same operation-ID classifier for
   semantic-lowering ownership, so semantic domain and owner decisions no
   longer drift independently. Common typed-v2 lowerability is now composed
   from the semantic operation classifier plus call and terminator predicates
   instead of maintaining a separate broad opcode list. Backend-runtime
   routing for `atomic_rmw` and `assembly` now also uses named capability
   predicates instead of duplicated owner/lowerer string checks, and
   `aggregate_init` straight-line eligibility has a named predicate as well.
   `src/zig_air_model.zig` now also owns the shared typed value
   structs (`ZigType`, `FunctionType`, `TypedValue`, and branch-merge values),
   function naming, raw instruction-position lookup, typed-v2 required-detail
   validation, and selected typed GEP/field-offset eligibility helpers. The
   typed void-constant operand check used by branch value lowering is now
   model-owned too, preserving fail-closed missing-detail behavior while
   removing another local `kind`/`type_text`/detail parse from lowering.
   Generic typed operand kind checks for `inst`, `const`, and `none` now live
   in the model as well, so `resolveTypedOperand` no longer parses operand
   kind strings directly. Typed call detail extraction (`call_signature`,
   `callee_text`, parsed direct/extern callee, and callee name) now returns a
   model-owned call-detail object consumed by call lowering. The legacy
   non-typed AIR lowering loop now also enters through registry semantic
   operation IDs for its accepted scalar, memory, and pointer/aggregate subset
   instead of carrying a second opcode dispatch chain. Typed runtime-nav
   symbol detail extraction and typed field-index parsing are now model-owned
   as well, and typed array-element table operand access has moved behind a
   model helper. Generic typed constant operand text resolution is model-owned
   too, leaving `resolveTypedOperand` to materialize values rather than parse
   operand detail keys directly. Checked int-from-float guard/runtime-call
   admission is also model-owned now: the lowering module consumes the
   model-provided operand type and low/high bound constants, then only builds
   the IR blocks and runtime call symbol. The typed-v2 mixed C/Zig add-may-panic
   wrapper now follows the same pattern: the model owns the guard/call/add
   admission and reports whether the add is checked, while lowering owns the
   IR/runtime symbol materialization. Typed runtime optional-pointer and
   pointer-load/store main wrappers now also use model-owned typed-v2 wrapper
   summaries, matching the older untyped runtime wrapper summaries. Typed
   pointer-to-pointer bitcast identity now uses a capability predicate rather
   than a local string comparison. Typed
   block-target operand parsing is now normalized through model-local block
   operand helpers instead of inline `kind`/`value` checks. Typed result and
   operand coverage now use a model-owned known-type sentinel helper, typed
   return-pointer recognition routes through the capability registry, aggregate
   pointer-path parsing reuses model-owned operand/field helpers, and branch
   constant/field-index checks no longer duplicate local operand parsing. The
   typed atomic payload checks and legacy aggregate-init validation now also
   enter through capability/model predicates, and legacy CFG/store/return
   matchers use shared capability predicates instead of local opcode literals.
   Legacy accumulator-loop and scalar-shape scans now use capability predicates
   for arg/alloc/loop/repeat/branch and exact add/compare families, reducing
   the compatibility path's remaining local opcode ownership. Array/struct
   aggregate scans now use shared aggregate/load/field-pointer predicates, and
   the legacy compatibility module reuses the model-owned opcode query helper
   instead of carrying its own duplicate implementation.
   The strict frontier gate was re-run after these refactors and now reports
   `generic_cfg_functions=663`, `structural_matcher_functions=0`,
   `legacy_air_text_lowering_functions=0`, and executable proof green across
   ReleaseFast, ReleaseSafe, and ReleaseSmall. Post-try continuation blocks
   containing `switch_br` now lower through the typed-v2/generic CFG path. The
   Zig type/function signature parsing and pointer-child text now live in
   `src/zig_air_types.zig`; AIR constants and symbol pointers live in
   `src/zig_air_values.zig`; instruction-reference parsing and balanced text
   helpers (`findMatching` and top-level comma splitting) live in
   `src/zig_air_text.zig`. The old `src/zig_air_lowering_parser.zig` facade has
   been removed. The IR-owned string allocation helper now lives in
   `src/zig_air_model.zig` as well. The legacy simple-select shape
   predicates have also moved to the model, so the parser is no longer the
   owner for CFG-shape decisions. AIR opcode-to-IR semantic mapping
   for scalar binary ops, integer/FP predicates, casts, and scalar type helpers
   now lives in `src/zig_air_semantics.zig`, so the parser no longer owns those
   lowering decisions either. Function calling-convention mapping is also
   model-owned. Shared typed value structs and `LowerError` are
   private/model-owned rather than parser-owned compatibility exports. The
   optional/error-union/pointer semantic dispatch now enters through the
   capability registry; error-union type-shape helpers now live in
   `src/zig_air_types.zig`; typed result/operand coverage checks now live in
   `src/zig_air_model.zig`; and global initializer/string-literal
   materialization helpers now live in `src/zig_air_values.zig`. The dead
   always-null structural-matcher facade has been removed, leaving the accepted
   release path's `shape_recognizer_functions=0` counter explicit. The
   root-source function ownership predicate now lives in `src/zig_air_roots.zig`
   so gate helpers do not import the full lowering module just to count root
   functions. Direct-call declaration reconciliation now lives in
   `src/zig_air_calls.zig`, separate from function-body lowering. The
   runtime/native-link boundary symbol policy now lives in
   `src/runtime_boundaries.zig` as prefix/suffix tables consumed by the
   uncurated AIR gates. The remaining legacy AIR instruction opcode query used
   by typed-v2 compatibility fallbacks now lives in `src/zig_air_model.zig`
   instead of the fallback module. Typed-v2 error switch and error-classifier
   admission now also enters through `src/zig_air_model.zig`; both selected
   error-switch-family `icmp`/`select`/`ret` bodies now build directly from the
   model-owned summaries instead of delegating to compatibility IR builders.
   Typed-v2 maybe-error also builds its selected `icmp`/`select`/`ret` body
   directly from the model-owned summary, replacing the old `.maybeError` suffix
   gate with structural opcode/type checks. Typed-v2 error-union payload
   admission also uses model summaries now, replacing the old
   `error_switch.error_switch` exclusion with structural opcode/type checks.
   Typed-v2 optional-pointer admission and
   selected null-check/load/phi IR construction now consume a model-owned
   summary containing the selected add immediate, fallback value, and
   checked-unwrap marker instead of delegating to the legacy optional-pointer
   compatibility lowerer. The simpler typed-v2 optional-payload
   row now also builds its selected `icmp`/`select`/`ret` IR directly from the
   model-owned fallback summary instead of delegating to the legacy
   optional-payload compatibility lowerer. Typed-v2 packed read/replace admission
   and selected bit-operation IR construction now also use model-owned summaries
   instead of delegating to the legacy packed-field compatibility lowerers.
   This does not change the separate packed/unaligned aggregate ABI boundary.
   Typed-v2 plain slice-loop admission and selected loop IR construction now use
   the model-owned plain slice summary directly, and typed-v2 conditional
   slice-loop admission now builds its selected loop skeleton directly from the
   model-owned conditional slice summary instead of delegating to the legacy
   conditional-slice compatibility lowerer. Typed-v2 accumulator-loop and
   conditional-slot-update admission has likewise moved to model-owned scalar
   control summaries, and both selected scalar-control bodies now emit their
   loop/add/sub/select IR directly from the typed-v2 path. Typed-v2 inline-asm
   memory-barrier admission now uses a
   model-owned summary too, and typed-v2 monotonic atomic-add admission now
   selects the `atomic_rmw` instruction through a model-owned summary.
   Typed-v2 runtime wrapper rows now call `src/zig_air_runtime_wrappers.zig`
   directly instead of routing through the legacy lowering module; both runtime
   wrapper paths now consume the typed-v2 parsed `FunctionType` instead of
   reparsing AIR type text, while the wrapper-shaped helper bodies themselves
   remain explicit compatibility surfaces. The typed-v2 mixed C/Zig panic-edge
   helper also consumes the parsed `FunctionType` instead of reparsing the AIR
   type text, and typed-v2 register aggregate construction now uses the same
   parsed `FunctionType` for its aggregate return plan.
   Typed-v2 dense integer-switch admission and branch-result extraction now
   use a model-owned summary as well. The
   remaining refactor is deeper normalization of each operation's operand/type
   validation and lowering inputs.
3. Type-layout slice: `src/zig_air_type_layout.zig` is now the shared
   aggregate layout decoder for accepted x86_64 release rows. `src/zig_air_types.zig`
   delegates named aggregate parsing to it instead of carrying the long
   fixture-path mapping block, and both direct aggregate values and nominal
   `%Type` names are normalized before lookup while pointer/function-pointer
   surfaces stay in normal pointer parsing. `src/zig_air_capabilities.zig` now also provides a
   shared type/surface capability API for aggregate, pointer, slice, optional,
   error-union, vector, X87/f128, varargs, and packed/unaligned surfaces.
   `src/distribution_zig_air_inventory.zig` uses it for category reporting,
   and `src/codegen/x86_64/sysv_abi.zig` uses the same recursive IR-type
   boundary classifier for vector, long-double, and packed aggregate ABI
   rejection. The first backend consumer slice now routes SysV aggregate
   classification, generic CFG aggregate GEP/field lookup, selected sret/byval
   leaf lookup, typed-v2 aggregate pointer-path discovery, typed-v2 aggregate
   field counting, typed-v2 aggregate copy-leaf planning, typed-v2 register
   aggregate construction recognition, and the compatibility ABI bridge through
   shared aggregate field/leaf layout helpers. Typed-v2 register aggregate
   eligibility now delegates to the x86_64 SysV aggregate classifier. The
   former ambiguous nominal `Pair` compatibility rule is removed: nominal
   `Pair` now normalizes to the two-`i32` field layout, and the remaining
   runtime aggregate-pair compatibility lowerers admit rows from normalized
   layout plus construction/call/return data flow rather than exact runtime
   aggregate-pair symbol names. `AggregateLayoutPlan` is now the normalized
   field/leaf plan used by pair layout admission, typed-v2 register aggregate
   construction admission, and sret/byval aggregate copy/make planning, while
   the SysV classifier consumes the same normalized aggregate type. The
   construction emitter still uses typed AIR pointer-path summaries for
   insertvalue index paths because the layout plan owns offsets/types rather
   than AIR instruction paths. `AggregateLayoutSummary` now records layout
   source, field count, scalar leaves, and construction/store/load evidence.
   The basename compatibility table has been removed, so no accepted aggregate
   row can enter through fallback-table ownership. The
   owned side now has descriptor-exported frontier facts, 0 remaining
   compatibility sidecar facts, and 0 temporary static source layout facts in
   `src/zig_air_aggregate_layout_facts.zig`. The finite
   `frontier_sysv_sret_byval.BigN` rows are descriptor-fact owned rather than
   generated nominal inference. The
   compatibility fallback side is removed; `PackedMixed` and `PackedReverseMixed` are
   boundary-owned through `src/zig_air_aggregate_layout_boundaries.zig`, not
   fallback-owned.
   Owned summaries are compared against lower-priority static or boundary
   evidence; a disagreement fails closed with nominal name, field-count,
   leaf-count, and construction/store/load evidence available through
   `aggregateLayoutMismatch`. Register aggregate construction no longer admits
   rows from nominal layout alone: it mechanically rebuilds a layout summary
   from typed AIR `ret_ptr`/field-or-element pointer/store/`ret_load` paths and
   compares that summary with `AggregateLayoutPlan` before accepting the row.
   Sret/byval aggregate copy and call-wrapper compatibility now also requires
   typed AIR data-flow evidence: copy rows must return the typed aggregate
   argument, and call-wrapper rows must prove that the typed aggregate argument
   feeds the single call and that the terminal aggregate return is the call
   result. This covers both one-aggregate-parameter direct wrappers and the
   existing multi-parameter stack-pressure wrappers without exact symbol-name
   admission.
   `aggregateLayoutPlan` now uses the checked summary path, so layout mismatch
   reaches plan-based lowerers as `AggregateLayoutMismatch` instead of being
   silently converted to an optional miss.
   The patched Zig hook now emits a narrow descriptor-owned
   `zllvm-aggregate-layout-facts-v1` section for supported aggregate semantic
   layouts found in function signatures and aggregate construction result
   types. z_llvm parses that section as an owned provider and gives it
   precedence over the checked-in sidecar provider; sidecars remain the
   temporary compatibility source for rows not yet proven from emitted facts.
   The hook contract still carries only semantic aggregate layout text and
   construction/store/load evidence flags; x86_64 SysV classification and ABI
   interpretation remain in z_llvm.
4. Boundary slice: move vector, X87/f128, packed/unaligned aggregate, varargs,
   and inline-asm rejection policy behind shared boundary classifiers. The
   dedicated frontier boundary gate should prove these remain fail-closed and
   targeted. Frontier ABI boundary category names, diagnostics, source-stage
   classifiers, codegen-error classifiers, and expected boundary row counts now
   live in `src/abi_boundaries.zig`; representative ABI boundary tests also
   use the registry-owned error values. `src/uncurated_air_gate.zig` consumes
   that registry for classification, counting, and local-fail expectations
   instead of owning ad hoc boundary metadata; expected boundary summary
   matching is registry-owned rather than field-by-field gate code. The
   boundary registry is now table-driven by source fragment, category,
   expected row count, source-level failure row count, and diagnostic policy;
   the boundary gate was re-run after this change and still reports
   `wrong_diagnostic_rows=0` across ReleaseFast, ReleaseSafe, and ReleaseSmall.
5. Aggregate ABI slice: route aggregate argument, return, sret, byval, field
   offset, and copy decisions through the shared type-layout result plus the
   SysV aggregate classifier. `src/codegen/x86_64/sysv_abi.zig` now also owns
   shared call signature rejection for callconv and varargs surfaces, and both
   the planner and older direct-call lowerer consume that helper. Do not add
   function-name-specific aggregate paths.
6. Unknown-opcode slice: split the compiler-core `unknown-opcode` inventory
   bucket into stable subcategories before implementing more lowering. The
   first split is now emitted as `unknown_opcode` and `top_unknown_opcode`
   records by `distribution-zig-air-inventory`: `error-union-try`,
   `pointer-address`, `aggregate-shape`, `safety-runtime`, call/memory/switch
   shape buckets, debug metadata, and `other`. The measured compiler-core
   module graph shows `error-union-try` as the dominant unknown-opcode
   subcategory in all three release modes. The second split now emits
   `top_unknown_opcode_pair` records keyed by `subcategory:opcode:data_kind`;
   the leading pairs are `unwrap_errunion_err:ty_op`,
   `wrap_errunion_err:ty_op`, `try:pl_op`, `ptr_add:bin_ty_pl`,
   `ptr_slice_len_ptr:ty_op`, and `slice_len:ty_op`. The first accepted
   source-backed error-union slice is now in `frontier_optionals_errors.zig`: it lowers
   `wrap_errunion_payload`, `wrap_errunion_err`, `is_non_err`,
   `unwrap_errunion_payload`, `unwrap_errunion_err`, a selected direct
   `try:pl_op` continuation, a nested two-`try` continuation where both error
   paths propagate the original error-union value and the hot path reuses call
   results without re-calling clobbered arguments, and a `try` continuation
   whose payload feeds a second branch before both arms re-wrap an adjusted
   payload, a `try` continuation whose payload is stored to and reloaded from
   a local slot before rewrapping, an error-branch `switch` over the unwrapped
   error tag, and a branch-local `try` arm that preserves the single
   error-union call result across the guard and payload return instead of
   reissuing the helper call.
   The `try_cold:pl_op` slice now routes through the same error-union semantic
   lowering as `try:pl_op`; the cold hint is treated as non-semantic for local
   CFG/codegen while retaining fail-closed typed-v2 ownership. Pointer-form
   `try_ptr` and `try_ptr_cold` are now source-backed as well: patched Zig
   emits typed-v2 pointer operands for
   `try_ptr`/`try_ptr_cold`/`unwrap_errunion_err_ptr`, z_llvm models the
   error-union pointer slot semantically, and the ok-path load resolves through
   a synthetic payload value instead of AIR text or row-name recovery. The
   pointer-form branch row now carries that synthetic payload through a
   post-try compare and both add/sub rewrap return arms through the supported
   signed payload-greater predicate used by that AIR shape.
   The nested pointer-form row also preserves the first synthetic payload into
   a second error-union helper call, then unwraps the second `try_ptr`
   continuation and rewraps the final adjusted payload. The pointer-form
   switch row now feeds the synthetic payload into a tagged integer switch and
   rewraps each selected arm. The direct payload-pointer row now proves the
   separate `unwrap_errunion_payload_ptr:ty_op` typed-v2 path: the exported
   instruction carries the error-union pointer operand and z_llvm lowers the
   ok arm to a synthetic payload value that feeds a nested compare plus
   ABI-parameter add/sub terminal returns without AIR text recovery.
   A second direct payload-pointer row combines the same pointer payload path
   with an error-arm switch over the extracted error tag, proving the shared
   error-tag switch return path applies to pointer-form payload success arms
   without a selected function-name gate. The typed-v2 union-tag payload switch
   recognizer now lives in `src/zig_air_model.zig` as a model-owned summary
   rather than in the lowering module. The summary now proves that both
   `set_union_tag` operations target the allocated union slot, both payload
   stores target the matching field pointers, the loaded union value comes from
   that slot, and the `get_union_tag`/`struct_field_val`/`switch_br` path uses
   that same loaded value. The summary now accepts either source switch-arm
   order when the exported case tag indexes prove the selected tag set, and the
   selected payload construction model now proves either tag arm may store the
   raw second argument or a constant add of that argument. The model also uses
   structured-air branch bodies to prove which tag each `cond_br` arm sets, so
   reordered union field/tag indexes no longer rely on the old `tag0 == true`
   assumption. The x86_64 lowering path consumes the summary fields while still
   emitting the same selected frontier IR.
   The catch/remap row now lowers a post-try catch body that switches over the
   unwrapped error tag, returns remapped error-union constants from the cold
   arms, and rewraps the hot payload after arithmetic through the same
   typed-v2 block/branch and generic CFG backend path.
   The `frontier_catch_error_value_switch` row adds the scalar-return variant:
   a direct error-union helper call feeds a catch-side `switch_br` over the
   unwrapped error tag, each error arm returns an `i32` expression using a live
   ABI parameter, and the success arm returns payload arithmetic. The x86_64
   generic CFG plan now spills the single live `i32` parameter across the helper
   call and materializes both switch-phi incoming values and the payload return
   without a selected function-name gate.
   The `frontier_wrap_error_switch_match` row adds the producer-side
   `wrap_errunion_err` switch shape: a masked integer switch returns either a
   wrapped payload or wrapped error constants through an `i64` error-union phi,
   and the x86_64 generic CFG switch-to-phi path now accepts an entry-local
   `arg & const` condition while still requiring all arms to branch to the
   proven merge phi.
   The `frontier_error_tag_branch` row adds the branch classifier variant:
   `unwrap_errunion_err` feeds an `i16` equality guard and two terminal
   constant returns, while the success arm reuses the same payload arithmetic
   path. The codegen plan verifies the helper call, error-bit extraction,
   branch condition, and terminal return blocks structurally.
   The `frontier_error_catch_default_merge` row adds the catch-to-value merge
   form: the success arm unwraps the payload into a merge phi, the catch arm
   contributes a live fallback `i32` parameter, and the merged value continues
   through arithmetic. The backend now spills that fallback parameter across
   the direct error-union helper call before materializing the phi result.
   The switch-local try row now lowers a switch arm whose nested value block
   contains a `try` call, returns the original error-union value on the error
   edge, and branches the rewrapped success payload into the outer switch phi;
   admission is based on typed-v2 block/value and generic CFG data flow, not a
   selected function-name gate.
   The two-arm branch row now lowers an `if` where both arms contain independent
   error-union `try` calls and rewrap their success payloads before returning;
   codegen validates two structural `BranchTryStage` arms and emits one shared
   framed epilogue without row-name admission.
   The two-arm switch row now lowers a masked integer `switch` whose explicit
   case and default arm each contain an independent `try`; typed-v2 lowers both
   arms into a switch merge phi, and generic CFG codegen validates both
   success-arm incoming values before emitting the shared epilogue.
   Branch-owned and switch-owned multi-arm try rows now share the same
   error-union try-stage emitter, so call/spill/error-edge emission is no
   longer duplicated per enclosing CFG shape.
   The counted-loop try row now lowers a loop-carried index/accumulator pair
   where the loop body computes a tag, calls a local error-union helper,
   unwraps the success payload into the accumulator, and returns a selected
   catch value on the error path. The typed-v2 lowerer qualifies the local
   helper symbol and preserves its fastcc call convention from the typed call
   signature; x86_64 generic CFG codegen validates the loop phis, helper call,
   error-tag guard, success payload extraction, and shared epilogue without a
   function-name gate.
   The post-loop branch variant now reuses that loop-try summary and adds a
   validated `icmp`/`cond_br` continuation after loop exit; generic CFG
   preserves the third threshold argument across the helper call and emits the
   two terminal add/sub return arms without a selected row-name path. The
   typed AIR model derives the threshold argument and terminal add/sub addends
   from the `cmp_gt`, accumulator reload, and return value data flow instead of
   fixed summary constants.
   The post-loop switch variant reuses the same loop-carried try summary, then
   normalizes `total & 3` into a typed switch terminator with two explicit cases
   and a default arm. Generic CFG validates the switch targets and terminal
   addends before emitting the x86_64 compare/jump sequence, so this remains a
   structural typed-v2 CFG path rather than a function-name admission. The
   typed AIR model now derives the switch mask and terminal addends from the
   `bit_and`, branch-to-block, load, and add value flow instead of storing fixed
   row constants in the summary.
   Typed error-union payload/catch ownership now has a model-owned
   `TypedErrorUnionFlow` summary in `src/zig_air_model.zig`. The summary
   records the error-union source instruction, success payload owner, error
   owner, visible call result owner, branch targets, and whether the payload is
   local or call-produced. The patched Zig hook now emits the narrow,
   versioned `zllvm-error-union-call-facts-v1` section in
   `error_union_call_facts_bytes`; it connects a direct error-union helper call
   in the caller to the callee's proven `error{...}!i32` result type, success
   argument equality, success payload constant, and error return name. z_llvm
   parses that fact into a provider, `lowerTypedV2ErrorUnionPayload` consumes it
   through the `TypedErrorUnionFlow` model, and the old selected broad-row
   `arg0 == 0 ? 7 : -1` compatibility emitter has been removed. Missing or
   incomplete facts fail closed with `UnsupportedAir` instead of recovering the
   relation from AIR text. Local error-union flows continue through generic
   typed-v2 CFG; broader non-`i32` payloads and helper bodies whose success or
   error relation is not proven by the v1 fact remain unsupported. The fact
   path now reports targeted typed-v2 fallback reasons such as
   `missing_error_union_call_fact_provider`, `missing_error_union_call_fact`,
   `missing_catch_i32_value`, and
   `unsupported_error_union_fact_result_type` rather than a generic
   `UnsupportedAir` bucket.
   Validation evidence for the hook cycle: `tmp/error_union_call_fact_descriptor.air`
   contains `zllvm-error-union-call-facts-v1` for
   `aggregates.error_union_payload -> maybeError`,
   `tmp/frontier_error_union_call_fact.log` is green at
   `source_rows=14`, `discovered_functions=672`, `executable_ok_rows=14`,
   and `local_fail=0` for ReleaseFast/ReleaseSafe/ReleaseSmall, and
   `tmp/broad_error_union_call_fact.log` is green at
   `source_rows=101`, `discovered_functions=152`, `executable_ok_rows=100`,
   `runtime_boundary_rows=1`, and `local_fail=0` for all three release modes.
   The follow-up diagnostic cycle is validated by
   `tmp/frontier_error_union_fact_diagnostic.log` and
   `tmp/broad_error_union_fact_diagnostic.log`, both green with the same strict
   counters.
   Together these prove the same pointer-slot model beyond simple branch
   continuations.
   These rows pass through typed AIR v2, generic CFG, z_llvm object
   emission, native link, and executable proof. Broader arbitrary
   nested/multi-block compiler-core `try` and pointer-form error-union shapes
   remain the next error-union sub-slice. The first accepted
   pointer/slice source-backed slice is now in
   `frontier_slice_pointer_arith.zig`: it lowers `ptr_add:bin_ty_pl`,
   constant `ptr_sub:bin_ty_pl`, and runtime `ptr_sub:bin_ty_pl` with one
   additive and one subtractive dynamic index term,
   `slice_len:ty_op`, `ptr_slice_len_ptr`, `slice_ptr`,
   `ptr_slice_ptr_ptr`, and `slice_elem_ptr` selected forms through typed AIR
   v2, generic CFG, z_llvm object emission, native link, and executable proof.
   The slice pointer address proof now includes `slice.ptr` plus constant
   offset plus runtime index feeding a store/reload, not just a derived load.
   It also covers a pointer-to-array slice expression (`values[0..]`) that Zig
   exports as typed `bitcast`/`ptr_add`/`ptr_elem_ptr` data, proving the
   address model handles this source-backed array-to-slice pointer form without
   a selected function-name path.
   The optional-pointer slice also admits `is_non_null_ptr` through the shared
   optional semantic classifier and lowers a source-backed `?*const i32` null
   fallback from typed-v2 branch/return constants. ReleaseSafe checked unwrap
   admission remains fail-closed to the explicit nested `unwrapNull`/`unreach`
   block shape.
   The optional scalar payload branch row now lowers from typed-v2 optional
   facts as well: z_llvm validates the `wrap_optional`/`is_non_null`/
   `optional_payload` data flow and the payload add/sub branch without a
   function-name gate, then emits a generic single-block CFG shape that is
   executable-proven in all three release modes. Its typed-v2
   arg/compare/condbr/return summary now lives in `src/zig_air_model.zig`,
   leaving the lowering module to materialize IR from model-owned
   threshold/fallback facts. Arbitrary optional payload control-flow remains
   future work.
7. Compiler-core frontier slice: only after the registries are shared, add
   small real Zig compiler-core frontier rows that exercise the highest ranked
   categories through typed AIR v2 and generic CFG. Keep the
   `compiler-core-module` gate inventory-only.

Acceptance criteria for this refactor:

- inventory, typed lowering, generic CFG eligibility, ABI planning, and
  boundary gates consult shared capability data instead of parallel string
  lists;
- existing strict broad/expanded/scale/frontier gates keep their current
  counters;
- no case IDs, source tags, wrapper/body maps, shape recognizers, legacy AIR
  text lowering, LLVM optimizer, LLVM TargetMachine, or LLD are introduced;
- the existing saved compiler-core inventory log remains the baseline until a
  capability classifier or lowering change can affect its counters;
- after such a change, `distribution-zig-air-inventory --
  --slice=compiler-core-module` still reports `instruction_payload_scan=1` and
  ranked top categories;
- implementation work remains separate from inventory claims.

Validation ladder for the refactor:

```text
# Baseline: use the existing saved compiler-core inventory log.
# Rerun this only after classifier/lowering changes can affect inventory:
# zig build distribution-zig-air-inventory -- --slice=compiler-core-module
zig build distribution-air-release-frontier-boundaries
zig build distribution-air-release-frontier
zig build test
git diff --check
```

Run broader distribution gates only if public build wiring or accepted release
gate behavior changes.

Remaining selected recognizer ownership to normalize:

The currently tracked recognizer families in this inventory have been moved
behind model summaries or helper modules. Further work should start from the
next measured compiler-core/frontier gap rather than adding new selected
compatibility bodies here.

This inventory is refactor-only: it does not expand accepted rows or weaken the
strict frontier counters. Each slice should move one recognizer family behind
model/capability helpers, then rerun `zig build test`; rerun
`distribution-air-release-frontier` when lowering dispatch behavior changes.

Completed slices from this inventory:

- `src/zig_air_model.zig` now owns untyped AIR value queries for arg
  index/type, alloc type, load source slot, store destination/value, binary
  refs, binary ref+integer constants, branch condition refs, return refs,
  compare-against-argument queries, cast-from-slot queries, binary-use
  queries, slot binary-update queries, and runtime-nav symbol extraction.
  `accumulatorLoopShape` and `conditionalSlotUpdateShape` now reuse those
  helpers instead of parsing those payloads locally.
- Optional/error-union selected recognizers now use model-owned semantic-op
  presence helpers for optional non-null/payload/wrap and error-union
  unwrap/is-non-error checks. The selected error-union payload, maybe-error,
  error-switch, and error-classifier compatibility recognizers now use
  model-owned structural summaries rather than function names such as
  `error_switch.error_switch`, `.maybeError`, or `.classify`.
- Optional pointer/payload compatibility predicates now use model-owned
  `optionalPointerSummary` and `optionalPayloadSummary` helpers. The summaries
  record selected optional condition/payload/wrap indexes, and the pointer
  summary additionally records connected load and terminal return indexes; the
  legacy lowerer no longer owns optional opcode-presence admission.
- Integer-switch compatibility admission now uses the model-owned
  `integerSwitchSummary` helper, and integer-switch construction now consumes
  a model-owned `integerSwitchPlan` for parsed case ranges, branch result
  values, and default result. The legacy lowerer no longer owns the
  block/switch/branch/default predicate or dense-switch range/result parsing.
- Aggregate/store/return selected recognizers now use model-owned return,
  store, memory-op, return-pointer, and field-index presence helpers. The
  aggregate pair/read/make compatibility recognizers now use model-owned
  structural summaries instead of `.pair_first`, `.pairFirst`, `.make_pair`,
  or `.makePair` suffix gates.
- Array/struct aggregate-sum compatibility predicates now use model-owned
  `arraySumSummary` and `structSumSummary` helpers. The legacy lowerer no
  longer parses aggregate-init payload text, field-index presence, `i32` load
  payload prefixes, or add/load counts locally for those selected rows.
- Packed read/replace compatibility predicates now use model-owned
  `packedReadFlagSummary` and `packedReplaceLowSummary` helpers. The summaries
  record the selected field pointer plus connected load/bitcast or store/trunc
  instruction indexes, so the legacy lowerer no longer owns the packed
  opcode-presence admission checks.
- Slice-sum compatibility admission now uses the model-owned `sliceSumSummary`
  helper. The summary records the selected slice construction, slice length
  pointer, slice element pointer, and loop instruction indexes; the legacy
  lowerer no longer owns the local slice opcode-presence check.
- Base64 table lookup, runtime optional-pointer wrapper, runtime
  pointer-load/store wrapper, and mixed C/Zig add-may-panic compatibility
  recognizers now use model-owned structural summaries. Legacy recognizer
  admission no longer depends on `.base64_table_lookup`,
  `runtime_optional_pointer_main.main`,
  `runtime_pointer_load_store_main.main`, or `.add_may_panic` names. The old
  runtime wrapper callee/global symbol names are registry-owned in
  `src/zig_air_runtime_wrappers.zig` rather than embedded at each use site,
  and both runtime-wrapper CFG construction bodies now live in that helper
  module behind legacy compatibility adapters.
- The selected aggregate pair, error-switch/classify, maybe-error,
  error-union payload, table-lookup, runtime-wrapper, and panic-edge
  compatibility recognizers now use model-owned data-flow summaries rather
  than broad opcode-presence checks. The summaries return concrete instruction
  indexes/value refs for producer-consumer paths such as ret-ptr-to-field
  stores, field-load-to-return, mask-to-intcast-to-table-load-to-return,
  error-union unwrap-to-switch, call-result-to-compare-to-condbr, and
  panic-predicate-to-cold-call/unreach plus hot load/add/return.
- Current scan status: `src/zig_air_lowering_legacy.zig` has no
  function-name-specific accepted recognizer gates for the aggregate,
  error/switch, table-lookup, runtime-wrapper, or panic-edge selected shapes.
  Runtime-wrapper CFG construction is helper-owned in
  `src/zig_air_runtime_wrappers.zig`; the legacy file keeps only compatibility
  adapters for those wrappers.
- Accepted model summaries are now fail-closed on terminal value paths:
  maybe-error, error-switch, error-classify, runtime optional-pointer wrapper,
  and runtime pointer load/store summaries require a proven terminal return or
  connected call/compare/branch/return path before admission. The unsafe
  first-call/first-block probes were narrowed to connected model queries, with
  negative tests for unrelated returns, unrelated call/compare/block paths, and
  panic calls whose `unreach` is not on the cold panic path.
- The next measured compiler-core source-backed pointer/slice slice is
  `ptr_add:bin_ty_pl`, `ptr_slice_len_ptr:ty_op`, `slice_len:ty_op`,
  `slice_ptr`, `ptr_slice_ptr_ptr`, and `slice_elem_ptr`:
  `frontier_slice_pointer_arith` now exports real rows for runtime and
  comptime pointer addition, chained pointer addition, constant pointer
  subtraction, runtime pointer subtraction from a runtime positive base index,
  loads/stores through derived pointers, slice pointer extraction, slice element pointer
  load/store, and slice length from a pointer-backed slice. The x86_64 generic
  CFG path now uses a reusable typed address model with base pointer, additive
  and subtractive dynamic index terms, constant byte offset, scalar width, and
  element-size checks;
  accepted rows prove i8, i16, i32, and i64 scalar pointer loads/stores. These
  rows lower through typed AIR v2 pointer/aggregate semantics, generic CFG
  pointer/slice return/load/store codegen, z_llvm object emission, Zig native
  link, and executable proof. This closes the selected frontier address forms
  only; unchecked `slice_elem_ptr` rows still prove pointer-address lowering
  without safety checks, while `frontier_checked_slice_elem_ptr_load` now proves
  the ReleaseSafe-style bounds guard, hot in-bounds load, cold `outOfBounds`
  trap path, and child-process executable death check in the accepted frontier.
  The older `GenericCfgDynamicI32Address` compatibility path is now owned in
  `core_memory_lowering` and remains only for additive multi-load i32 forms
  such as pair-sum rows where the typed address model still needs a reusable
  "load two addresses then combine" operation; scalar load/store and
  checked-slice hot paths route through `GenericCfgTypedAddress`.
  Two-term dynamic addressing now includes a source-backed `%rcx` subtractive
  index row (`frontier_ptr_sub_runtime_rcx_load`) where the emitter consumes the
  `%rcx` term before reusing `%rcx` as the final address register. Forms that
  would also require preserving `%r8` as an independent input while `%r8` is
  needed as the scratch register remain fail-closed. Pointer/slice semantic recognition now has a model-owned
  `PointerSliceAddressSummary` for pointer/slice op counts, base pointer,
  dynamic index, constant offset, scalar width, slice source, and
  bounds-check-like branch presence. Checked slice-element store now uses the
  same typed address resolver plus a two-guard bounds/panic CFG path and is
  accepted in the strict frontier proof.

Pointer/slice frontier exit:

- The pointer/slice frontier phase meets the exit condition for the current
  x86_64 release claim. Semantic recognition has a model-owned
  `PointerSliceAddressSummary`; representative source-backed rows cover
  pointer addition, slice pointer/length extraction, derived scalar loads and
  stores, and checked slice-element load/store.
- Accepted rows have strict object/native-link/executable proof across
  ReleaseFast, ReleaseSafe, and ReleaseSmall. The checked slice load proves both
  the in-bounds hot path and the cold `outOfBounds(index, len)` trap path; the
  checked slice store proves the in-bounds store/load path and the same cold
  trap path.
- `pointer_slice_boundary_rows=0` is now a regression guard. There is no active
  pointer/slice boundary row in the frontier boundary gate.

Aggregate/type-layout ownership start:

- `src/zig_air_type_layout.zig` now owns named aggregate decoding, field
  counting, field byte offsets, recursive leaf lookup, supported scalar-leaf
  collection, and aggregate-kind checks. The decoder is shared by
  `src/zig_air_types.zig`, `src/zig_air_capabilities.zig`,
  `src/codegen/x86_64/sysv_abi.zig`, and generic CFG C ABI aggregate lowering.
- Representative existing source-backed aggregate rows in
  `frontier_nested_records.zig`, `frontier_sysv_abi.zig`,
  `frontier_sysv_aggregate_classes.zig`, and
  `frontier_sysv_sret_byval.zig` continue to prove field access, construction,
  return lowering, sret/byval copies, and SysV ABI classification through
  object/native-link/executable proof across all release modes.
- Remaining aggregate/type-layout debt is narrower and explicit. Nominal
  `Pair` is layout-owned as `{ i32, i32 }`, aggregate-pair compatibility
  lowerers admit by normalized layout and data-flow structure rather than exact
  symbol names, and the basename compatibility fallback table is removed.
  `AggregateLayoutSummary.provider_kind` records descriptor-exported facts,
  sidecar-exported facts, static-source facts, or boundary-provider ownership.
- Zig-emitted aggregate layout facts:
  `../ziglang/src/codegen/llvm.zig` emits `zllvm-aggregate-layout-facts-v1`
  directly into `zllvm-air-export-v1` descriptors when `ZLLVM_AIR_EXPORT_PATH`
  is active. The z_llvm parser accepts an optional
  `aggregate_layout_facts_bytes` section, and the uncurated AIR gate installs
  descriptor facts ahead of the temporary sidecar provider for each source.
  The sidecar files are now header-only; the strict frontier gate stayed green
  from descriptor-emitted facts for nested records, SysV aggregate classes,
  and sret/byval BigN rows, and the broad pointer-memory rows no longer depend
  on sidecar aggregate facts.
- Current aggregate provider audit:
  `zig run tools/audit_aggregate_layout_providers.zig >
  tmp/aggregate_layout_provider_audit.log` now reports `exported_facts=0`,
  `static_source_facts=0`, `boundary_provider=2`, `generated_examples=0`,
  `sidecar_exported_facts=0`, and `descriptor_exported_facts=0` after
  retiring the final non-frontier sidecar facts. The same audit tool can now
  count descriptor-emitted facts explicitly with `--from-air=<descriptor>`:
  `zig run tools/audit_aggregate_layout_providers.zig -- --from-air=tmp/aggregate_hook_check.air >
  tmp/aggregate_layout_provider_descriptor_audit.log` reports
  `exported_facts=14`, `sidecar_exported_facts=0`,
  `descriptor_exported_facts=14`, `static_source_facts=0`, and
  `boundary_provider=2` for the saved SysV aggregate-class descriptor. This
  keeps sidecar/static ownership and Zig-emitted descriptor ownership visible
  as separate evidence buckets.
  The prior broad failure was not a missing aggregate fact: `pointers_memory.load_store`
  and `runtime_pointer_load_store_main.loadStore` were plain pointer-memory rows
  hitting aggregate ABI routing, and `runtime_aggregate_pair_main.main` needed
  register-aggregate pair lowering for `{ i32, i32 }`. Packed/unaligned
  aggregate layouts remain the 2 explicit boundary-provider rows.
- Function-local typed AIR construction evidence still validates register
  aggregate construction and sret/byval make admission on top of provider
  facts. Copy rows must return the typed aggregate argument, and call-wrapper
  rows must pass that aggregate argument to the single call and return that
  call result. The pre-existing strict broad executable blocker in
  `test/zig/inputs/aggregates.zig` is closed: typed-v2 slice-sum lowering now
  emits a real loop with index/sum phis, indexed GEP/load, accumulator update,
  and exit phi instead of returning `0` on both paths. The saved
  `tmp/broad_aggregates_slice_sum_fix.log` run reports all three release modes
  with `native_link_accepted_rows=100`, `executable_ok_rows=100`,
  `native_link_failures=0`, and `local_fail=0`.

Validation after these refactor slices is saved in
`tmp/frontier_counter_update.log` and
`tmp/frontier_boundary_counter_update.log`:

- `zig build distribution-air-release-frontier`: ReleaseFast, ReleaseSafe, and
  ReleaseSmall all report `source_rows=14`, `discovered_functions=669`,
  `generic_cfg_functions=669`, `structural_matcher_functions=0`,
  `legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`,
  `object_emitted_functions=669`, `native_link_accepted_rows=14`,
  `executable_ok_rows=14`, and `local_fail=0`.
- `zig build distribution-air-release-frontier-boundaries`: ReleaseFast,
  ReleaseSafe, and ReleaseSmall all report `varargs_boundary_rows=2`,
  `vector_boundary_rows=2`, `x87_boundary_rows=2`,
  `packed_aggregate_boundary_rows=2`, `tail_call_boundary_rows=1`,
  `callconv_boundary_rows=1`, `safety_edge_boundary_rows=0`,
  `pointer_slice_boundary_rows=0`,
  `unexpected_accept_rows=0`,
  `wrong_diagnostic_rows=0`, and `local_fail=0`.
- `zig build test` and `git diff --check` pass.

- Category: `aggregate-abi`.
  Inventory counts: ReleaseFast 2256445, ReleaseSafe 2338212,
  ReleaseSmall 2206792.
  Likely layers: semantic type lowering, SysV ABI planner, x86_64 aggregate
  backend.
  Current duplicated/selected-code location:
  `src/zig_air_type_layout.zig` now carries the shared named aggregate decoder
  and the former `src/zig_air_types.zig` fixture-path mapping block has been
  removed. `src/zig_air_lowering_typed_v2.zig` and
  `src/zig_air_lowering_typed_v2_fallbacks.zig` carry overlapping aggregate
  sret/byval construction; the x86_64 aggregate classifier, generic CFG
  aggregate GEP/field lookup, sret/byval leaf lookup, typed-v2 aggregate
  pointer-path discovery, typed-v2 aggregate field counting, typed-v2 aggregate
  copy-leaf planning, typed-v2 register aggregate construction recognition,
  and compatibility ABI bridge now share aggregate field/leaf layout queries
  through `src/zig_air_capabilities.zig`, `src/zig_air_model.zig`,
  `src/zig_air_aggregate_copy.zig`, `src/zig_air_aggregate_construction.zig`,
  and `src/codegen/x86_64/sysv_abi.zig`. The sret/byval aggregate copy/make
  planner now uses `AggregateLayoutPlan` for leaf counts, parameter matching,
  and copy/store offsets; typed-v2 register aggregate construction admission
  validates its source operands against the same plan before using typed AIR
  pointer paths for insertvalue indices. The former centralized ambiguous
  `Pair` rule and exact runtime aggregate-pair symbol-name admission have been
  replaced by normalized `{ i32, i32 }` layout and structural call/data-flow
  checks. `AggregateLayoutSummary` now records whether a layout came from
  exported aggregate facts, static source facts, a
  boundary; owned layout lookup now goes through a
  provider registry, and
  `AggregateLayoutSummary.provider_kind` records the provider that supplied the
  layout so future exported Zig field facts can replace the static
  source-fact provider module without changing lowering callers. Finite BigN
  rows are now descriptor-fact owned, and mismatch checking compares owned
  field/leaf counts against lower-priority static or boundary evidence.
  Register aggregate construction now also has
  mechanical typed-AIR
  inference for ret_ptr/field-or-element pointer/store/ret_load rows, including
  single-field array leaf reconstruction; register construction and direct sret
  make validation classify and plan from that inferred layout before provider
  facts when the store paths prove the shape. The same leaf/path validation now
  gates sret/byval make rows. Sret/byval copy rows mechanically validate that
  the terminal return is the typed aggregate argument, and sret/byval
  call-wrapper rows validate that the aggregate argument feeds the call and the
  aggregate terminal return is produced by that call. Remaining non-exported
  aggregate ownership work now requires exported field-layout facts or broader
  construction/store/load inference, not compatibility fallback table entries.
  Target reusable abstraction: a shared Zig/AIR type-layout decoder feeding the
  existing SysV aggregate classifier, with one aggregate ABI plan consumed by
  typed lowering, call planning, return lowering, and inventory classification.
  The inventory scanner now emits an `aggregate_surface` split that preserves
  the old aggregate totals while separating `opcode-shape`,
  `metadata-type-surface`, and `abi-type-surface` observations. This is
  validated for `runtime-libs` in
  `tmp/runtime_libs_aggregate_surface_inventory.log` and for the standalone
  compiler-core probe in
  `tmp/compiler_core_standalone_aggregate_surface_inventory.log`. The
  ReleaseFast `compiler-core-module` refresh with the new split completed in
  `tmp/compiler_core_module_releasefast_inventory.log` and reports
  `aggregate_opcode_shapes=410592`,
  `aggregate_metadata_type_surfaces=1325299`, and
  `aggregate_abi_type_surfaces=931146`. The module inventory runner disables
  the aggregate-layout fact side channel with
  `ZLLVM_DISABLE_AGGREGATE_LAYOUT_FACTS=1` so count-only refreshes scan AIR
  bodies without emitting the large aggregate fact stream.
  Use the per-mode form for normal cycles:
  `zig build distribution-zig-air-inventory --
  --slice=compiler-core-module --mode=ReleaseFast`. The all-mode refresh is
  milestone-cost, and empty or incomplete inventory logs are not evidence.
  Validation gate: compare against the saved compiler-core inventory baseline;
  rerun `zig build distribution-zig-air-inventory` with
  `-- --slice=compiler-core-module --mode=<mode>` only after
  classifier/lowering changes that can change inventory counters, then run
  focused aggregate rows through `zig build distribution-air-release-frontier`.

- Category: `unknown-opcode`.
  Inventory counts: ReleaseFast 367030, ReleaseSafe 407240,
  ReleaseSmall 333877.
  Likely layers: AIR export parser, semantic lowering, generic CFG lowering.
  Current duplicated/selected-code location:
  `src/zig_air_export.zig` owns broad opcode categories,
  `src/zig_air_capabilities.zig` now owns the inventory-known/lowerable opcode
  registry and the first unknown-opcode subcategory classifier, while
  accepted lowering modules now consume lowerability directly through
  `src/zig_air_capabilities.zig`.
  Target reusable abstraction: one AIR opcode registry that records category,
  supported data kinds, lowering status, and boundary reason; inventory,
  diagnostics, and typed lowering should query it instead of maintaining local
  string lists.
  Current subcategory counts:
  `error-union-try` 236821/238174/231997,
  `pointer-address` 50417/59226/49313,
  `aggregate-shape` 30599/64537/29881,
  `vector` 26154/not-refreshed/not-refreshed,
  `union-tag-shape` 14507/not-refreshed/not-refreshed,
  `optional-shape` 6454/not-refreshed/not-refreshed,
  `scalar-transform` 1842/not-refreshed/not-refreshed,
  `float-math` 87/not-refreshed/not-refreshed,
  `select-shape` 5/not-refreshed/not-refreshed,
  `other` 0/33949/22545, and
  `safety-runtime` 144/11354/141 for
  ReleaseFast/ReleaseSafe/ReleaseSmall. The concrete top-pair split identifies
  `unwrap_errunion_err:ty_op` 84377/84913/82350,
  `wrap_errunion_err:ty_op` 76608/77020/75165,
  `try:pl_op` 73606/73993/72265,
  `ptr_add:bin_ty_pl` 14273/19156/13966,
  `slice_len:ty_op` 13768/47605/13459, and
  `get_union_tag:opaque` 6057/not-refreshed/not-refreshed as the next
  measured semantic families. The first source-backed union/tag slice is now in
  `frontier_union_tags.zig`: Zig exports versioned `set_union_tag`,
  `get_union_tag`, and union-tag `switch_br` facts, and z_llvm lowers the
  selected tag/payload switch without AIR text fallback or function-name
  admission. Broader union ABI/layout support remains future work. The pointer
  and error-union shapes remain the first implementation families; optional
  wrapping, broader union/tag operations, and scalar transforms such as
  `byte_swap` are now separately measured instead of hidden in `other`. The
  pair report now prints the top 50 concrete pairs; the
  residual ReleaseFast `other` bucket is 0 rows after selected float math,
  select, and saturating shift opcodes were split into named categories; see
  `tmp/compiler_core_module_releasefast_final_unknown_classification.log`.
  Validation gate: compare against the saved compiler-core inventory baseline;
  rerun `zig build distribution-zig-air-inventory` with
  `-- --slice=compiler-core-module --mode=<mode>` only after
  registry/classifier changes, plus
  `zig build distribution-zig-air-uncurated-release`.

- Category: `vector`.
  Inventory counts: ReleaseFast 15820, ReleaseSafe 16024,
  ReleaseSmall 15808.
  Likely layers: type classification, SysV ABI planner, x86_64 backend.
  Current duplicated/selected-code location:
  `.vector` is rejected in multiple parser, lowering, and codegen switches,
  while `src/uncurated_air_gate.zig` maps vector boundaries through
  source-name-specific checks.
  Target reusable abstraction: a shared unsupported-type/boundary classifier
  for vector values, parameters, returns, and opcodes, later replaceable by a
  vector ABI/lowering plan without changing inventory or gate diagnostics.
  Validation gate: `zig build distribution-air-release-frontier-boundaries`.

- Category: `x87`.
  Inventory counts: ReleaseFast 6194, ReleaseSafe 6220, ReleaseSmall 6550.
  Likely layers: SysV ABI planner and x86_64 floating-point backend.
  Current duplicated/selected-code location:
  `x86_fp80` and `fp128` are rejected in parser/lowering/codegen switches, and
  frontier x87 rows are classified separately in
  `src/uncurated_air_gate.zig`.
  Target reusable abstraction: one long-double boundary policy shared by type
  parsing, ABI planning, diagnostics, and future x87/f128 lowering.
  Validation gate: `zig build distribution-air-release-frontier-boundaries`.

- Category: `packed-aggregate`.
  Inventory counts: ReleaseFast 5039, ReleaseSafe 5548, ReleaseSmall 4863.
  Likely layers: type layout, aggregate ABI planner, object/backend memory
  lowering.
  Current duplicated/selected-code location:
  inventory detects packed/unaligned aggregate text through
  `src/zig_air_capabilities.zig`; selected boundary accounting lives in
  `src/uncurated_air_gate.zig`; aggregate field offset, leaf lookup, copy
  planning, construction admission, classifier queries, generic CFG aggregate
  lowering, and compatibility ABI bridge checks now use shared layout helpers.
  Target reusable abstraction: a layout-capability result for aggregate fields
  that records aligned, packed, and unsupported offsets once, then feeds both
  inventory category reporting and backend load/store/copy lowering.
  Validation gate: `zig build distribution-air-release-frontier-boundaries`,
  followed by aggregate object/executable proof through
  `zig build distribution-air-release-frontier`.

Replacement goal:
Freeze the completed ReleaseSmall no-exclusion boundary. The x86_64 selected
146-row external IR-writer gate is green under `zig build distribution-all`, and
the two former ReleaseSmall explicit exclusions now have local object evidence:
`standalone_mix_o_files_base64.zig.ReleaseSmall.x86_64.optimized.ll`
(`@decode_base_64 -> @base64.decode_base_64`) and
`standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll`
(`@strFromFloatHelp -> @main.strFromFloatHelp`). No active local failure
remains for the captured ReleaseSmall boundary.

Current target:
External IR-writer cases are registry-driven, and the selected writer helper
layer now lives in `src/ir_writer_helpers.zig`. Reusable helpers cover function
headers, named blocks, unconditional and conditional branches, two-input phis,
loop headers/latches, GEP/load/store, table loads, pointer index advancement,
byte masks, shifts, truncation, calls, lifetime intrinsics, memcpy/memset,
aggregate/global declarations, local-exec TLS globals/accesses, stack slots,
inline-asm barrier calls, indirect writer calls, and checked arithmetic
panic-edge branches. Base64 full/reduced rows, full `strFromFloatHelp`,
selected loop/phi rows, ReleaseSafe checked loop edges, checked
aggregate/pointer rows, TLS rows, inline-asm boundary rows, ReleaseSmall mixed
C/Zig rows, and float binary/check rows use the shared helpers. Remaining
intentionally case-specific bodies are exact semantic fixtures whose body shape
is not duplicated elsewhere: base64's full decoder CFG, `strFromFloatHelp`'s
decimal/pow-table semantics, aggregate ABI pair packing, atomics, packed bits,
and optional/error-union scalar payload rows. Future helper candidates are
bounded to repeated semantic families only, such as generic compare/select main
checks and broader checked arithmetic variants.

Selected IR-writer rows now print and enforce:
`construction=ir-construction=zllvm-structured-builder`, plus
`llvm_text_parse=not-used` and
`codegen_ownership=codegen=generic-x86_64-lowering`, plus
`ownership=llvm-module=not-used;llvm-optimizer=not-used;llvm-targetmachine=not-used;object-emission=z_llvm;linker=zig-native-fno-lld`.
The x86_64 lowering layer now shares SysV direct-call frame helpers for the
aligned call prologue/epilogue and the one-slot live-parameter spill/reload
shape used by simple direct calls. The generic helper path also covers the
multiple stack-passed integer parameters/call arguments in the expanded ABI
frontier, i64 direct-call returns/pass-through, and mixed integer/f32/f64 call
arguments through separate SysV integer and SSE register streams; remaining raw
stack-frame emission is kept to custom multi-call, f128 comparison, and
explicit stack-slot boundary rows.
The source-owned DescriptorV2 path now runs a local z_llvm release
canonicalizer that rewrites eligible DescriptorV2 programs before structured
lowering. The current source-owned gate reports
`release_canonicalizer_rows=100`, `observed_int_fold_rows=57`,
`observed_fp_fold_rows=5`, `observed_dead_local_rows=41`,
`observed_select_fcmp_rows=7`, `applied_int_fold_rows=57`,
`applied_fp_fold_rows=5`, `applied_dead_local_rows=41`,
`applied_select_fcmp_rows=7`, `checked_rows=9`, and
`checks_preserved_rows=9`. The runner fails if eligible selected rows only
observe integer/FP/select/CFG opportunities without applying them, and
ReleaseSafe checked/runtime-call boundaries fail closed if preservation
regresses. Large semantic boundary rows such as full base64 and
`strFromFloatHelp` keep their current shape until their generic lowering is
ready for canonicalized CFG.
DescriptorV2 verifier negatives now cover unsupported vector and varargs
boundaries, malformed SysV aggregate/sret/byval ABI shapes, unsupported atomic
ordering, TLS/local-exec relocation mismatches, and ReleaseSafe checked-boundary
removal.
The gate fails if a selected row reports libLLVM module parse/print,
LLVM TargetMachine object emission, a minimal wrapper surface, a full-gate
structured-direct count other than 146, any structured row reports textual
LLVM parsing, any textual boundary row remains, or any structured-direct row
reports case-specific codegen ownership. This is a selected x86_64 release-row
claim only; the normal Zig/libLLVM fallback still exists when the external
writer env vars are unset.

Current strongest distribution claim gate:
`zig build distribution-x86_64-release-source-owned` is the source-owned
x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall replacement gate for the full
current source-backed inventory. Patched Zig still receives wrapper path,
optimize mode, target, output path, marker path, and diagnostic source fixture
metadata; the release source-owned runner no longer passes `ZLLVM_SOURCE_TAG`.
Patched Zig emits `zllvm-source-facts-v1` with frozen generic compiler facts:
root source path, mode, target, wrapper, diagnostic fixture, function inventory,
exported/main function signature, parameter and return types,
block/instruction counts, instruction-category summaries, globals, TLS, calls,
atomics, and inline-asm capability facts. The stream has
`facts_contract_version=1` and `facts_payload=generic-compiler-facts`; the hook
does not read or token-count wrapper source. z_llvm classifies those facts into
DescriptorV2, then verifies and lowers the
records directly rather than resolving a Zig-side wrapper/fixture/tag table or
expanding a body name. Every accepted row reports
descriptor-v2 semantic lowering into
structured-direct IR. Current measured output is `release_source_rows=100`,
`source_wrapper_rows=100`, `descriptor_owned_rows=100`,
`descriptor_v2_rows=100`, `real_descriptor_program_rows=100`,
`full_descriptor_program_rows=100`, `serialized_function_rows=100`,
`serialized_instruction_rows=100`, `serialized_global_rows=100`,
`semantic_serialized_rows=100`, `serialized_return_stub_rows=0`,
`descriptor_body_name_rows=0`, `zllvm_body_expansion_rows=0`,
`descriptor_program_body_expansion_rows=0`, `functions_for_body_rows=0`,
`globals_for_body_rows=0`,
`air_derived_descriptor_rows=100`, `static_descriptor_map_rows=0`,
`zig_emitted_descriptor_rows=100`, `runner_generated_descriptor_rows=0`,
`descriptor_file_consumed_rows=100`, `source_fact_stream_rows=100`,
`concrete_source_fact_rows=100`, `source_derived_descriptor_rows=100`,
`tag_table_descriptor_rows=0`, `body_enum_dispatch_rows=0`,
`surface_to_body_adapter_rows=0`, `canned_return_descriptor_rows=0`,
`manual_fixture_dispatch_rows=0`, `legacy_semantic_record_rows=0`, `semantic_record_rows=0`,
`external_writer_delegate_rows=0`, `semantic_lowering_rows=100`,
`manifest_structured_rows=0`, `case_id_rows=0`, `surface_dispatch_rows=0`,
`structured_direct_rows=100`, `generic_codegen_rows=100`, `fallback_rows=0`, and
`local_fail=0`. The gate requires
`fact_derived_classification_rows=100`,
`source_fact_program_rows=100`,
`source_fact_program_direct_rows=100`,
`source_fact_body_wrapper_rows=0`,
`root_source_classification_fallback_rows=0`, and
`body_enum_fallback_rows=0`. All accepted rows must have concrete facts, and
the 100-row source-owned inventory is now classified from those facts into
direct SourceFactProgram DescriptorV2 records without root-source/body-enum
fallback. A 7-family wrong-facts negative probe still rejects mismatched
wrapper/fact streams without using root source as the body selector.

The same 100-row boundary now has pre-link ELF object-format evidence:
`zig build distribution-native-link-object-inspection -- --release-source-owned`
emits each row through the patched-Zig source-owned z_llvm object path, then
checks the object with `readelf -W -h -S -s -r` and `objdump -dr`. Current
counters are `inspected=100`, `elf64_rel=100`, `relocation_rows=12`,
`tls_rows=8`, `undefined_import_rows=0`, `comdat_rows=0`, `eh_frame_rows=0`,
`unsupported_relocation_rows=0`, and `local_fail=0`. Final linking remains
Zig-owned; this is object-format proof, not a z_llvm linker implementation.
This gate mode validates the patched stage4 hook and runs `zig build` during
setup, so use it as milestone object-boundary confirmation rather than the
regular source-owned row inner loop.

The source-owned boundary now also has Zig native-link handoff accounting:
`zig build distribution-native-link -- --release-source-owned` emits through
the same patched-Zig source-owned object path, links with `zig build-exe
-fno-lld`, and runs every accepted executable row. Current counters are
`total=100`, `executable_abi_proof_rows=100`, `link_only_rows=0`,
`runtime_compiler_rt_libc_boundary_rows=0`,
`unsupported_zig_linker_feature_rows=0`,
`local_object_codegen_failures=0`, and `local_fail=0`. The companion probe,
`zig build probe-native-linker -- --release-source-owned`, reports
`accepted=100`, `runtime_compiler_rt_libc_boundary_rows=0`,
`unsupported_zig_linker_feature_rows=0`,
`local_object_codegen_failures=0`, and `failed=0`.

The Zig source-facts hook (`zllvm-source-facts-v1`) is frozen for this
milestone: patch it only for fact-contract version changes, not for row
expansion or surface classification. The separate AIR-export hook
(`zllvm-air-export-v1` / `structured_air-v2`) is not frozen; it may gain
generic data-kind and operand classification (for example the `fpext` ty_op
record) as the uncurated corpus exposes unclassified opcodes, but it must
never gain case- or row-specific behavior. Prefer closing classification gaps
on the z_llvm side when the exported AIR text already carries the
information.

Current real-AIR ownership milestone:
`zig build distribution-zig-air-uncurated-release` is the source-driven
ReleaseFast/ReleaseSafe x86_64 AIR gate over `test/zig/inputs/*.zig`. It asks
patched Zig for `zllvm-air-export-v1` plus `structured_air-v1` metadata and
lowers real compiler-owned AIR/liveness in z_llvm without case IDs, wrapper
maps, source-fact body classification, canned DescriptorV2 bodies, libLLVM
module parse/print, LLVM optimizer ownership, or LLVM TargetMachine codegen.
Current measured output for each mode is `source_rows=19`,
`discovered_functions=44`, `structured_functions=44`,
`generic_codegen_functions=44`, `unsupported_functions=0`,
`codegen_failures=0`, `case_id_rows=0`,
`source_fact_classification_rows=0`, and `local_fail=0`. ReleaseSafe is scoped
to the same root-source function inventory and accepts safe opcode variants
such as `ret_safe`, `store_safe`, and `intcast_safe` while keeping
safety/runtime shapes fail-closed. ReleaseSafe void guard blocks are now
lowered into real control flow (guard branch, cold noreturn panic block,
continuation block) instead of being elided, so the emitted object preserves
the safety check and its panic boundary. Object-format inspection and native-link
handoff for this uncurated AIR gate are the next evidence layer; they are not
part of the current inner-loop gate.

Broad real-AIR discovery progress:
`zig build distribution-zig-air-uncurated-releasefast-broad`,
`zig build distribution-zig-air-uncurated-releasesafe-broad`, and
`zig build distribution-zig-air-uncurated-releasesmall-broad` extend the
real-AIR discovery surface to `test/zig/inputs/*.zig` plus
`test/zig/integrated/*.zig`. All three release modes now report
`source_rows=101`, `discovered_functions=152`,
`structured_functions=152`, `generic_codegen_functions=152`,
`generic_cfg_functions=152`, `structural_matcher_functions=0`,
`structured_air_v1_functions=152`, `structured_air_v2_functions=152`,
`typed_air_type_functions=152`, `typed_air_operand_functions=152`,
`legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`, `generic_lowering_functions=152`,
`shape_recognizer_functions=0`, `unsupported_functions=0`,
`codegen_failures=0`, `case_id_rows=0`, `source_fact_classification_rows=0`,
and `local_fail=0`. Typed v2 is now the lowering authority for the
straight-line scalar, load/store, global pointer constants, stack-slot,
direct-call, runtime symbol pointer, simple block-result select, struct
field-sum, array aggregate-sum, base64 table-lookup, aggregate pair ABI
first/make-pair, error-union payload, maybe-error, optional scalar-payload,
optional pointer-payload, error-switch/classifier, runtime optional-pointer
wrapper main, runtime pointer load/store wrapper main, packed read/replace,
slice-sum, selected monotonic atomic add, empty inline-asm memory-barrier,
accumulator-loop, dense-switch, conditional slot-update, and mixed C/Zig
panic-edge runtime-boundary lowering. No broad functions now fall back to
legacy AIR text or shape-recognizer ownership; the closure is recorded in
`docs/roadmap/x86_64_air_shape_recognizer_audit.md`.

The last broad structural matcher fallback was
`test/zig/integrated/runtime_mix_c_add_may_panic_main.zig` /
`runtime_mix_c_add_may_panic_main.add_may_panic`. Its typed AIR shape is an
`icmp slt` guard, a cold panic block with `llvm.assume(i1 1)` followed by
`debug.defaultPanic(ptr, i64)`, and an ok block that loads
`runtime_mix_c_add_may_panic_main.zig_k`, adds the input, and returns. Generic
CFG now owns this through guarded global-add lowering with an explicit
ptr/length panic-call runtime boundary, and the selected mixed C/Zig helper is
only a fallback after the generic router rejects unsupported variants.
The release generic CFG slice-panic call lowering now derives supported message
lengths from the IR value: direct integer lengths and `{ ptr, i64 }` aggregate
slice constants are materialized into `%rsi` without a selected length constant.

The broad object progress gates now cover all three release modes without LLVM
TargetMachine. ReleaseFast, ReleaseSafe, and ReleaseSmall each report
`object_emitted_functions=152`, `object_failures=0`,
`llvm_targetmachine_rows=0`, and `local_fail=0`.

The broad object-inspection progress gates now validate the corresponding
source-module ELF objects with `readelf -W -h -S -s -r` and `objdump -dr`.
ReleaseFast, ReleaseSafe, and ReleaseSmall each report `inspected=101`,
`elf64_rel=101`, `relocation_rows=14`, `tls_rows=3`,
`undefined_import_rows=3`, `comdat_rows=0`, `eh_frame_rows=0`,
`unsupported_relocation_rows=0`, and `local_fail=0`.

The strict finish-line gate
`zig build distribution-zig-air-uncurated-release-broad-finish` runs the broad
ReleaseFast, ReleaseSafe, and ReleaseSmall typed-v2/object paths and fails
closed if any mode regresses from the 152-function generic lowering and object
emission target. `zig build distribution-air-release-broad` adds executable
proof and fails closed if any mode reports `structural_matcher_functions != 0`.
It remains outside `distribution-all` because it is a milestone confirmation
gate, not the regular inner loop.

Expanded corpus frontier:
`zig build distribution-zig-air-uncurated-releasefast-expanded`,
`zig build distribution-zig-air-uncurated-releasesafe-expanded`, and
`zig build distribution-zig-air-uncurated-releasesmall-expanded` are separate
from the closed broad baseline. The expanded bucket adds
`test/zig/expanded/*.zig`. The expanded slices, now including the
`expanded_numeric_casts.zig` int/float conversion bucket, the
`expanded_branch_arrays.zig` optional-control-flow bucket, and the
`expanded_cfg_memory_aggregates.zig` branch/memory/call CFG bucket, and the
`expanded_abi_frontier.zig` stack/mixed SysV ABI bucket, are green for
ReleaseFast, ReleaseSafe, and ReleaseSmall at `source_rows=109`,
`discovered_functions=199`, `generic_codegen_functions=199`,
`generic_cfg_functions=199`,
`legacy_air_text_lowering_functions=0`, `typed_v2_fallback_functions=0`,
`shape_recognizer_functions=0`, `unsupported_functions=0`,
`codegen_failures=0`, and `local_fail=0`. The numeric-cast slice closed real
replacement gaps: the local IR gained `sitofp`/`uitofp`/`fptrunc` cast ops
with verifier rules, the AIR `float_from_int` opcode mapping was corrected
from `fptosi`/`fptoui` to `sitofp`/`uitofp`, the patched Zig AIR export hook
now classifies `fpext` as a typed `ty_op` record, the x86_64 backend lowers
scalar int/float conversions
(`cvtsi2ss`/`cvtsi2sd`/`cvtsi2ssq`/`cvtsi2sdq`/`cvttss2si`/`cvttsd2si`/
`cvtsd2ss`/`cvtss2sd`), and the ReleaseSafe checked `@intFromFloat`
range-guard block lowers as a real `ucomiss`/`ucomisd` + `jae` panic-edge CFG
with an aligned noreturn `integerPartOutOfBounds` call. The expanded audit is
recorded in `docs/roadmap/x86_64_expanded_air_corpus.md`. The expanded finish
gate now adds object emission for all three release modes at
`object_emitted_functions=199`, `object_failures=0`,
`llvm_targetmachine_rows=0`, and `local_fail=0`; the expanded object-inspection
gates report `inspected=109`, `elf64_rel=109`, `relocation_rows=18`
(ReleaseSafe: 19 for the checked panic boundary), `tls_rows=4`,
`undefined_import_rows=3` (ReleaseSafe: 6), `comdat_rows=0`, `eh_frame_rows=0`,
`unsupported_relocation_rows=0`, and `local_fail=0`. The expanded native-link
progress gates are green: ReleaseFast and ReleaseSmall report
`native_link_accepted_rows=108`, `link_only_rows=108`,
`runtime_boundary_rows=1`, while ReleaseSafe reports
`native_link_accepted_rows=105`, `link_only_rows=105`,
`runtime_boundary_rows=4` after classifying `outOfBounds`,
`integerPartOutOfBounds`, `unwrapNull`, and `debug.defaultPanic` as named
runtime boundaries. All three native-link progress gates report
`unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`,
`llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. The expanded
executable progress gates are green for all three release modes:
`native_link_accepted_rows=108`, `executable_ok_rows=108`,
`link_only_rows=0`, `runtime_boundary_rows=1` (`debug.defaultPanic`),
`unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`,
`llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`. The focused
`zig build distribution-air-release-expanded` gate composes expanded
discovery, object progress, executable progress, and strict finish for
ReleaseFast, ReleaseSafe, and ReleaseSmall, and currently reports
`source_rows=109`, `discovered_functions=199`,
`generic_cfg_functions=199`, `structural_matcher_functions=0`,
`object_emitted_functions=199`, `native_link_accepted_rows=108`,
`executable_ok_rows=108`, `link_only_rows=0`, `runtime_boundary_rows=1`,
`llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0` per mode. The wider
branch-return and byte-table-return forms from the candidate bucket failed
closed with typed/control-flow and backend diagnostics and remain the next
explicit source-frontier work. The memory/CFG bucket now exports the branch
pointer-load, pointer-select load, branch store, computed store, branch-call,
alloca-stored extern-struct field offset 0/4 load, and branch field-update rows
with executable ABI checks. The nested optional-pointer branch payload row is
now exported and executable: typed v2 lowers pointer `optional_payload` and
`is_non_null`, preserves the ReleaseSafe void guard/panic edge, and the generic
x86_64 CFG path lowers the guarded branch with a phi/immediate return.
The conditional slice-loop update row is now exported and executable: typed v2
validates the nested loop body, inner conditional block, indexed pointer load,
limit compare, and accumulator update, and generic x86_64 CFG emits the counted
loop with conditional accumulation. The ABI frontier row is now exported and
executable: typed v2 accepts qualified
helper function types such as `noinline fn (...)`, and the reusable SysV
direct-call/frame helpers cover multiple stack-passed integer parameters/call
arguments, named stack-parameter forwarding for stack-passed call arguments,
incoming stack-parameter assignment into outgoing call registers,
f32/f64 direct-call returns, i64 direct-call returns/pass-through,
mixed integer/f32/f64 call argument assignment, and selected two-i32 aggregate
argument/return rows. Milestone 1 is closed for this selected practical SysV
ABI subset. Remaining non-selected ABI boundaries are full aggregate
classification beyond the selected INTEGER and selected normal MEMORY
aggregate forms, arbitrary non-selected sret/byval copies, varargs, vectors, and broader live-across-call scheduling
involving stack-passed `i32` values or broader SSE pressure;
focused unit tests now fail closed for these unsupported classes.
The first broader SysV closure wave adds `frontier_sysv_abi.zig` with small
INTEGER/INTEGER aggregate return in `%rax`/`%rdx`, small aggregate field reads
from the SysV integer register pair, and a selected up-to-six-live-i32
direct-call frame that covers all six SysV GPR argument registers,
spilling and reloading caller parameters through aligned frame slots; more
than six stack-passed live `i32` parameters are now read from the restored
incoming stack argument area for a post-call add-tree return. The same frontier
source now proves eight, twelve, and eighteen stack-passed scalar `i32` call arguments
with immediate `%rsp` cleanup, plus forwarding of named incoming stack-passed
`i32` parameters into outgoing stack-argument slots and outgoing GPR argument
registers, seven/eight/twelve/thirteen/fourteen/eighteen/twenty/twenty-four/thirty-two stack-passed live `i32` values,
and deep post-call stack `i32`/`i64` reloads through disp32 incoming stack offsets. It also proves a selected
two-call/six-live GPR frame through the generic CFG void-call path. The follow-up
`frontier_sysv_sret_byval.zig` row adds selected MEMORY aggregate ABI evidence:
`{ i64, i64, i64 }`, `{ i64, i64, i64, i64 }`, and
`{ i64, i64, i64, i64, i64 }` returns through a hidden sret pointer in `%rdi`
with user arguments shifted through the SysV GPR stream. The follow-up Big6 and
Big7 rows add `{ i64, i64, i64, i64, i64, i64 }` and
`{ i64, i64, i64, i64, i64, i64, i64 }` return/copy proof and exercise
multiple stack-passed user fields after the hidden sret pointer. The normal
integer-leaf MEMORY sret/byval typed builder now generates field names and ABI
attrs instead of using a fixed field-count table. The same selected normal
MEMORY aggregate forms use by-value stack-passed aggregate field reads and
byval-to-sret copies for all scalar integer leaves through layout-derived
offsets, including the nested two-Big3 aggregate row and the mixed-width
`{ i64, i32, i64, i32 }` copy row plus the array-backed `{ [5 x i64] }`
copy/read rows. The `BigDouble` row adds the first double-leaf MEMORY
byval-to-sret copy proof through typed-v2 leaves and XMM `movsd` stack/sret
stores.
Boundaries still outside this
wave are full
SysV aggregate classification beyond the selected INTEGER and selected normal MEMORY classes,
arbitrary non-selected sret/byval copies, varargs, vectors, and wider
spill/reload pressure.

Scale corpus frontier:
`zig build distribution-zig-air-uncurated-releasefast-scale`,
`zig build distribution-zig-air-uncurated-releasesafe-scale`, and
`zig build distribution-zig-air-uncurated-releasesmall-scale` add
`test/zig/scale/*.zig` on top of the expanded corpus without weakening the
closed broad or expanded baselines. The first scale bucket covers broader
SysV call shapes, memory loops, branch-local pointer memory, extern-struct
field updates, direct calls across branches, globals, and TLS. All three
release modes currently report `source_rows=112`, `discovered_functions=216`,
`generic_codegen_functions=216`, `generic_cfg_functions=216`,
`structural_matcher_functions=0`, `legacy_air_text_lowering_functions=0`,
`typed_v2_fallback_functions=0`, `shape_recognizer_functions=0`,
`unsupported_functions=0`, `codegen_failures=0`,
`object_emitted_functions=216`, `object_failures=0`,
`llvm_targetmachine_rows=0`, and `local_fail=0`. The scale gate is fail-closed
but intentionally remains a frontier outside `distribution-all`. The scale
object-inspection gates are green for all three modes at `inspected=112`,
`elf64_rel=112`, `unsupported_relocation_rows=0`, and `local_fail=0`
(`relocation_rows=20`, `undefined_import_rows=3` for ReleaseFast/ReleaseSmall;
`relocation_rows=21`, `undefined_import_rows=6` for ReleaseSafe). Scale
native-link progress is green with Zig native `-fno-lld`: ReleaseFast and
ReleaseSmall report `native_link_accepted_rows=111`, `link_only_rows=111`,
`runtime_boundary_rows=1`, while ReleaseSafe reports
`native_link_accepted_rows=108`, `link_only_rows=108`,
`runtime_boundary_rows=4` for the named safety/runtime boundaries. Scale
executable gates are green for all three modes at
`native_link_accepted_rows=111`, `executable_ok_rows=111`,
`link_only_rows=0`, `runtime_boundary_rows=1`, `llvm_targetmachine_rows=0`,
`lld_rows=0`, and `local_fail=0`. The focused
`zig build distribution-air-release-scale` gate composes scale discovery,
object progress, and executable progress for ReleaseFast, ReleaseSafe, and
ReleaseSmall. It is a green frontier/progress gate with fail-closed local
failure classification, not yet a strict counter-locked finish gate. It
currently reports `source_rows=112`,
`discovered_functions=216`, `generic_cfg_functions=216`,
`structural_matcher_functions=0`, `object_emitted_functions=216`,
`native_link_accepted_rows=111`, `executable_ok_rows=111`,
`link_only_rows=0`, `runtime_boundary_rows=1`, `llvm_targetmachine_rows=0`,
`lld_rows=0`, and `local_fail=0` per mode.
The new strict `zig build distribution-air-release-scale-finish` gate locks
those same per-mode counters with `--strict-finish`, so the cumulative scale
baseline is now counter-locked separately from the progress command.

Volatile memory roundtrips, broader aggregate field stores, broader global/TLS
addressing, and larger loop-memory dependencies remain named future generic CFG
memory/aggregate candidates.

Next corpus frontier:
`zig build distribution-zig-air-uncurated-release-frontier` is a new isolated
x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall real-source bucket under
`test/zig/frontier/*.zig`. It is deliberately separate from the cumulative
broad, expanded, and scale gates: inputs covers `test/zig/inputs`, broad adds
`test/zig/integrated`, expanded adds `test/zig/expanded`, scale adds
`test/zig/scale`, and frontier covers only the new frontier directory. The
frontier gate reports `source_rows=14`, `discovered_functions=681`,
`generic_codegen_functions=681`, `generic_cfg_functions=681`,
`structural_matcher_functions=0`, `legacy_air_text_lowering_functions=0`,
`typed_v2_fallback_functions=0`, `shape_recognizer_functions=0`,
`unsupported_functions=0`, `codegen_failures=0`,
`object_emitted_functions=681`, `object_failures=0`,
`llvm_targetmachine_rows=0`, and `local_fail=0` for ReleaseFast, ReleaseSafe,
and ReleaseSmall. Frontier object inspection is green at `inspected=13`,
`elf64_rel=13`, `relocation_rows=5`, `tls_rows=1`,
`undefined_import_rows=1`, `unsupported_relocation_rows=0`, and
`local_fail=0`; native-link and executable gates are also green at
`native_link_accepted_rows=14`, `executable_ok_rows=14`,
`link_only_rows=0`, `runtime_boundary_rows=0`, `llvm_targetmachine_rows=0`,
`lld_rows=0`, and `local_fail=0`.

The new strict `zig build distribution-air-release-frontier` gate runs this
isolated frontier corpus in ReleaseFast, ReleaseSafe, and ReleaseSmall with
object progress, executable progress, and strict counter checks. It requires
`source_rows=14`, `discovered_functions=681`,
`generic_cfg_functions=681`, `structural_matcher_functions=0`,
`object_emitted_functions=681`, `native_link_accepted_rows=14`,
`executable_ok_rows=14`, `link_only_rows=0`, `runtime_boundary_rows=0`,
`unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`,
`llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0` for each mode.
This proof includes the selected slice-panic runtime-call row through the
general slice runtime-call helper subset plus frontier safety-edge rows for
checked signed/unsigned add, bounds loads, optional-pointer unwrap/null panic, and
checked int-from-float `integerPartOutOfBounds`. The strict executable harness
now uses child-process death checks for non-constant panic-slice calls and the
explicit checked-overflow panic rows, plus ReleaseSafe bounds/null/int-conversion
panic rows. The strict release helper
subset now lowers panic-slice lengths from direct constants, `{ ptr, i64 }`
slice aggregates, i64 parameters, loaded i64 globals/parameter pointers, and
simple i64 add/sub forms across the guarded panic CFG. Selected multi-input
length selection now lowers through typed AIR `select` values, and selected
loaded payload pointer objects are materialized when the payload remains a
`{ ptr, i64 }` panic slice. Arbitrary phi/control-flow length selection and
computed payload pointers remain future work. Current executable probes also
keep stable non-panic paths and link trap stubs for cold runtime symbols.

Strict release baselines are now split by corpus topology: broad is cumulative
`test/zig/inputs` + `test/zig/integrated`, expanded adds
`test/zig/expanded`, scale adds `test/zig/scale`, and frontier is isolated to
`test/zig/frontier`.

The memory/aggregate frontier moved several previously rejected classes into
accepted rows: nested counted loops with inner memory dependencies, selected
nested extern-struct field GEP paths, selected dynamic pointer addition /
pointer-element GEP loads, and branch-local global/TLS add/sub updates. The
first SysV ABI closure-wave row adds small INTEGER/INTEGER aggregate return,
small aggregate argument field reads, nested INTEGER aggregate add-chain
field reads, nested mixed aggregate field reads/construction and direct plus
pointer-callee register-class nested mixed aggregate pass-through returns,
stack-sourced nested mixed aggregate pass-through returns after GPR/SSE
exhaustion, stack-sourced SSE/SSE `[2]f64` pass-through returns,
stack-sourced single-eightbyte SSE `{ f32, f32 }` pass-through returns,
stack-sourced reversed mixed SSE/INTEGER pass-through returns,
array-in-struct INTEGER aggregate sums, selected stack-passed register
aggregate field reads after GPR exhaustion, and the selected
up-to-six-live direct-call spill frame plus stack-passed live `i32`
post-call rows plus mixed GPR/SSE outgoing stack-argument calls where both
`i32`/`i64` and `float`/`double` streams overflow for direct and function-pointer calls,
including disp32 stack reload evidence, with executable proof. The selected sret/byval
frontier row now covers `{ i64, i64, i64 }`, `{ i64, i64, i64, i64 }`, and
`{ i64, i64, i64, i64, i64 }` hidden-sret returns plus stack-passed MEMORY
aggregate field-read and byval-to-sret copy proof using layout-derived offsets;
the Big6/Big7/Big8 follow-up extends that normal i64 MEMORY proof through
`{ i64, i64, i64, i64, i64, i64, i64, i64 }`, exercises multiple stack-passed
user fields after the hidden sret pointer, and the nested MEMORY follow-up
copies and reads `{ { i64, i64, i64 }, { i64, i64, i64 } }` through recursive
leaf byte offsets. The mixed-width MEMORY follow-up copies
`{ i64, i32, i64, i32 }` through the same layout-derived byte offsets while
using narrow `i32` stores for `i32` leaves. The array-backed MEMORY follow-up
copies `{ [5 x i64] }` leaves and reads edge array fields through the same
byte-offset paths. The BigN parser follow-up removes the fixed Big3..Big8 type
enumeration and proves the same flat normal integer-leaf sret/byval path
through `Big20` construction, field-read, and copy rows. The `BigDouble`
follow-up adds the first double-leaf byval-to-sret MEMORY aggregate copy row,
and `BigPtrDouble` proves the same layout-derived copy path for pointer,
`double`, and `i64` leaves in one MEMORY aggregate. `BigPtrFloat` proves
pointer, `float`, and `i64` leaves through the same MEMORY copy path.
`BigFloat` adds five-`f32`
MEMORY aggregate copy proof through dedicated `movss` stack loads, while
`BigFloatArray` proves array-contained `f32` leaves and `BigDoubleArray`
proves array-contained `f64` leaves through recursive
byval-to-sret copy. `BigArrayMixed` combines array-contained `i32`, array-contained
`f64`, and pointer leaves. `BigNestedArrayMixed` nests those array-backed
`f32`/`f64` leaves with pointer and `i64` leaves in one MEMORY aggregate,
and proves the same layout-derived direct and pointer-callee copy path.
`BigStructArrayMixed` proves arrays whose elements are aggregate leaves
(`{ i32, double }`) through the same recursive byval-to-sret copy path.
`BigDeepMixed` composes nested array-backed float/double leaves,
array-of-aggregate records, recursively nested scalar leaves, pointer arrays,
and a trailing integer code through the same direct and pointer-callee
byval-to-sret copy path.
`BigNarrow` proves nested `i8`/`i16`/`i32`/`i64`
supported-leaf copies use width-correct byte/word stack loads and hidden-sret
stores through the same layout-derived path. `Big32`, `Big40`, `Big48`, `Big64`,
`Big80`, `Big81`, `Big96`, `Big128`, `Big160`, `Big192`, `Big224`, and `Big256` extend the same direct byval-to-sret copy path through
exact-qword payloads beyond byte-offset byval loads, including disp32
source-pointer reloads through the current 256-stack-argument planner cap and
stack-sourced `Big40`/`Big48`/`Big64`/`Big80`/`Big81`/`Big96`/`Big128`/`Big160`/`Big192`/`Big224`/`Big256` payload copies from the caller stack
argument area. The accepted frontier now also proves Big80, Big81, Big96, and
Big128, Big160, Big192, Big224, and Big256 indirect byval-to-sret forwarding through the same planner-owned
stack-copy path. The Big81 row adds a non-qword tail to that pointer-callee
proof. The accepted frontier also proves the Big80, Big81, Big96, Big128, Big160, Big192, Big224, and Big256 stack-source forwarding
paths, so the dedicated boundary gate now reports
`stack_pressure_boundary_rows=0`.
`ScalarArray` now also proves the same direct and pointer-callee
byval-to-sret copy path for mixed array-contained integer leaves,
array-contained `double` leaves, and a pointer leaf through layout-derived
MEMORY offsets; `ScalarMixed` and `ScalarNested` extend that direct and
pointer-callee copy proof to top-level and recursively nested supported scalar
leaves. Direct and indirect MEMORY
aggregate calls are now proven for Big3, Big4, Big5, BigDouble,
BigDoubleArray, BigArrayMixed, BigNestedArrayMixed, BigFloat, BigFloatArray,
BigStructArrayMixed, BigDeepMixed, BigPtrDouble, BigPtrFloat, BigNested, BigMixed,
BigNarrow, BigArray, ScalarMixed, ScalarNested, and ScalarArray by preserving
the hidden sret pointer, forwarding pointer callees through `%rax`, and copying
incoming by-value stack slots to outgoing stack slots before the call.

Source-backed ABI and pointer/slice boundaries are now measured separately from accepted
frontier rows. `zig build distribution-air-release-frontier-boundaries` runs
the dedicated `test/zig/frontier_boundaries/*.zig` rows in ReleaseFast,
ReleaseSafe, and ReleaseSmall and currently reports `varargs_boundary_rows=2`,
`vector_boundary_rows=2`, `x87_boundary_rows=2`,
`packed_aggregate_boundary_rows=2`, `tail_call_boundary_rows=1`,
`callconv_boundary_rows=1`, `stack_pressure_boundary_rows=0`,
`safety_edge_boundary_rows=0`,
`pointer_slice_boundary_rows=0`,
`unexpected_accept_rows=0`, `wrong_diagnostic_rows=0`, and `local_fail=0` per
mode. Varargs, vectors, X87/long double, packed/unaligned aggregates, tail
calls, and non-default call conventions are therefore source-backed fail-closed
boundaries, not vague docs-only gaps and not accepted executable proof. Checked
slice-element bounds have moved into the accepted frontier with executable hot
and trap-path proof for both load and store; the pointer/slice boundary counter
is held at zero as a regression guard. Stack-pressure byval forwarding is
currently accepted for the Big80 frontier rows, with the boundary counter held
at zero as a regression guard.
Typed AIR v2 pointer-callee lowering now resolves operand 0 into a callee value
for `frontier_indirect_stack_arg_to_registers`, copies it to `%rax`, loads
incoming stack-passed `i32` parameters into outgoing GPR call slots, and emits
`callq *%rax` without source-name-specific call lowering; the follow-up
`frontier_indirect_stack_arg_forward` and
`frontier_indirect_eight_stack_arg_forward` prove the same indirect path while
forwarding 12 and 14 `i32` arguments, including outgoing stack slots.
The aggregate call-planner follow-up forwards stack-passed INTEGER register
aggregates into outgoing helper calls by loading the caller stack eightbytes
into the destination GPR aggregate slots. The mixed stack aggregate follow-up
now covers both stack-to-register and stack-to-stack pressure for
`{ i64, double }`, splitting the caller-stack aggregate into the outgoing GPR
and SSE argument streams and returning both stack eightbyte fields from the
helper. The nested mixed stack follow-up extends the same path to
`{ { i32, i32 }, double }`, using the generic stack-to-`%eax` field load for
layout-derived `i32` aggregate fields. The stack f32 aggregate follow-up adds
generic stack-to-XMM `movss` loads for `[4]f32` SSE/SSE aggregate helper calls
after the SSE argument stream is exhausted. The shifted `[2]f64` follow-up
removes the `%xmm0`/`%xmm1` field-return assumption by moving higher XMM
argument registers through the generic XMM move path. The deep stack
INTEGER aggregate follow-up removes the disp8-only stack-source assumption for
stack aggregate forwarding: `frontier_deep_stack_array_pair_call_sum_after_six`
places `[2]i64` past the disp8 incoming stack window and forwards it into
outgoing stack aggregate slots through the same planner path. The deep
stack-sourced SSE/SSE follow-up adds the companion `[2]f64` proof:
`frontier_deep_stack_array_double_call_sum` exhausts the SSE argument stream,
reloads the aggregate from disp32 stack-source offsets, and forwards it into
the helper's XMM aggregate argument registers.
The single-eightbyte SSE follow-up adds `frontier_stack_float_pair_forward_after_pressure`,
which exhausts the SSE argument stream and reloads the stack-passed `{ f32, f32 }`
payload into `%xmm0` for a pass-through aggregate return.
The companion pointer-callee row, `frontier_stack_float_pair_indirect_forward_after_pressure`,
uses the same stack-source reload into `%xmm0` before `callq *%rax` and proves
the function-pointer path uses the same planner-owned aggregate assignment.
The shifted mixed aggregate follow-up removes the exact-register-slot
requirement for the GPR half of selected in-register aggregate pass-through
calls: `{ i64, double }` can now move its INTEGER eightbyte from `%rsi` to
`%rdi` while reusing the existing `%xmm0` SSE half.
The reversed mixed follow-up adds the mirrored SSE move: `{ double, i64 }` can
move its floating eightbyte from `%xmm1` to `%xmm0` with the generic XMM move
helper while reusing the existing GPR half.
The indirect FP follow-up extends the same pointer-callee path to selected
`f32`/`f64` calls, assigning five SSE arguments and returning through `%xmm0`.
The scalar integer follow-up fixes 64-bit call argument movement and stack
loads, proving incoming stack-passed `i64` values can feed outgoing GPR call
slots and indirect `%rax` calls can forward `i64` register and stack arguments.
The indirect aggregate follow-up routes selected pointer-callee register
aggregate calls through the same SysV planner: INTEGER/INTEGER `Pair64`
arguments and returns flow through `%rdi`/`%rsi` and `%rax`/`%rdx`, while
SSE/SSE `[2]f64` aggregate arguments and returns flow through `%xmm0`/`%xmm1`,
with executable C ABI checks in all three release modes.
The mixed aggregate
class frontier row adds `{ i64, double }`, selected `{ i32, double }`, and
selected `{ i32, i32, double }` INTEGER/SSE field reads plus register aggregate
returns in `%rax`/`%xmm0` through the independent SysV GPR/SSE streams,
including adjacent `i32` lane packing into `%rax`; a noinline helper-call row
returns the same register aggregate directly from a private helper. The SSE aggregate frontier row
adds `{ double, double }`, `[2]f64` array-in-struct, and nested
`{ { double }, { double } }` SSE/SSE field reads plus register aggregate
return in `%xmm0`/`%xmm1`; the single-eightbyte `{ f32, f32 }` row extracts
low/high f32 lanes from `%xmm0` and constructs the packed return with the
generic SSE aggregate return path, and now forwards the same f32 pair through
direct, shifted, and pointer-callee helper calls while lowering the helper's
f32 field-add body generically. It also forwards a stack-passed `[2]f64` SSE/SSE
aggregate into a private helper by loading incoming stack eightbytes into
outgoing XMM aggregate slots. The reversed mixed aggregate frontier row adds
`{ double, i64 }`, selected `{ double, i32 }`, and selected
`{ double, i32, i32 }` SSE/INTEGER field reads plus register aggregate returns
in `%xmm0`/`%rax`, including high-lane `i32` extraction and adjacent `i32` lane
packing into `%rax`. The indirect reversed mixed follow-up routes the same
SSE/INTEGER aggregate argument and return classes through pointer-callee SysV
call planning with executable proof. The nested mixed aggregate row adds
`{ { i32, i32 }, double }` typed AIR v2 field pointers with `align(...)`
qualifiers, lowers integer and floating fields through layout-backed offsets
from independent INTEGER/SSE classes, and constructs the aggregate in
`%rax`/`%xmm0`. The shifted nested mixed helper-call row proves both GPR and
SSE halves of an INTEGER/SSE aggregate can move into a private helper call
through the same register aggregate pass-through helper. The follow-up
pointer-callee nested mixed rows use the same planner path for
`{ { i32, i32 }, double }` arguments and returns: one row calls a function
pointer that consumes the aggregate, and another returns that aggregate through
a function pointer without function-name-specific lowering.
The `[4]f32` array-in-struct frontier rows extend the same SSE/SSE class
beyond double leaves: typed AIR v2 array-element field paths read all four
`float` lanes from `%xmm0`/`%xmm1`, construction packs the low/high f32 lanes
into both return registers, and direct plus pointer-callee helper calls spill
and reload the paired SSE eightbytes while lowering the helper's four-field
f32 sum body generically.
The nested INTEGER helper-call row passes `{ { i32, i32 }, { i32, i32 } }`
through the SysV GPR pair to a private helper and returns the helper's scalar
result without aggregate-specific wrapper dispatch; the nested construction
row traces typed AIR v2 field paths for four scalar `i32` leaves and returns
the aggregate in `%rax`/`%rdx`. The array-in-struct construction rows trace
typed AIR v2 pointer-element stores for `[2]i64` and `[2]f64` and return the
elements in `%rax`/`%rdx` or `%xmm0`/`%xmm1`.
The SSE live-across-call frontier rows add selected
one-live `f32`/`f64` spill/reload around an external C ABI `void` helper call,
two- through six-live `f32`/`f64` spill/reload frames across no-argument helper
calls before post-call `fadd` returns, selected direct two-/three-/six-live
one-/two-/five-FP-argument helper-call spill/reload frames,
selected two-live no-argument
pointer-callee `f32`/`f64` spill/reload frames before a post-call `fadd`
return, selected two-live one-FP-argument pointer-callee spill/reload frames,
selected three-/four-/six-live two-/three-/five-FP-argument pointer-callee
spill/reload frames, selected repeated pointer-callee stack-passed FP addend
frames that keep six register-backed addends, two stack-passed addends, and the
callee pointer in distinct frame slots, selected direct and pointer-callee
one-FP-argument helper calls that preserve six register-backed FP addends plus
two stack-passed FP addends,
selected direct and pointer-callee no-argument `void` calls that preserve six
register-backed FP addends plus up to eighteen stack-passed FP addends,
selected direct and pointer-callee f32/f64 call-result preservation across a
later FP helper call with a constant ninth FP stack argument,
and the same shared scalar
planner now preserves live `i32` GPR parameters across direct and pointer-callee
`f64`-argument `void` calls before the post-call integer add. The FP argument
frontier now also proves selected
named `f32`/`f64` external-call pass-through through `%xmm0..%xmm4`; immediate
FP constant materialization now uses generic XMM loads through `%xmm0..%xmm7`.
The ordered call-result frontier row spills a first `i32` C ABI call result and
the live `i32` parameter across a later side-effecting `void` call before the
post-call add; the executable harness uses helper state to prove source-order
preservation. The follow-up two-result row keeps the first `i32` call result in
a frame slot while a second `i32` call receives its own planned scalar argument,
then combines both call results plus the saved live parameter after the second
call. The pointer-callee follow-up preserves the second call target and
argument across the first call, reloads the callee through the shared 64-bit
frame spill/reload path, and uses the same SysV planner for the indirect `i32`
call. The later-void follow-up preserves both ordered `i32` call results and
the live parameter across a subsequent side-effecting `void` call, then reloads
both frame slots for the final add tree. The indirect later-void follow-up
preserves that later `void` call target across both earlier calls, reloads it
through the 64-bit frame spill/reload path before `callq *%rax`, then reloads
both saved `i32` results. The FP multi-call follow-up keeps two live
`f32`/`f64` parameters across two direct no-argument `void` calls before the
post-call `fadd` return. The repeated pointer-callee FP follow-up preserves the
callee pointer in the frame and reloads it before each indirect `callq *%rax`
while keeping the same two live FP values across both calls. The mixed GPR/SSE follow-up spills
an `i32` parameter and one `f32`/`f64` parameter across direct and pointer-callee
`void` calls, reloads the integer through `%edi`, converts it with `sitofp`,
and adds the preserved FP value.
The indirect-first follow-up routes the first ordered `i32` result call through
a function pointer while preserving the later ordered result and side-effecting
`void` call sequence through the same generic SysV call-target and frame
spill/reload path.
The FP result follow-up preserves a direct or pointer-callee C ABI `f32`/`f64`
call result plus a live FP addend across a later direct or pointer-callee
side-effecting `void` call, then reloads both XMM frame slots for the final
post-call `fadd`.
The two-result FP follow-up preserves a first direct or pointer-callee C ABI
`f32`/`f64` call result across a second direct or pointer-callee FP result call,
then reloads the saved XMM slot for the final `fadd`.
The mixed-width FP live-addend follow-up preserves the later FP argument, the
first FP result, any second pointer callee, and one independent live `double`,
`float`, or `i64` addend across both non-void calls before the final `double`
add; the live-`float` rows now cover both `f32`-then-`f64` and reversed
`f64`-then-`f32` result order.
The `i64` two-result follow-up preserves a first C ABI `i64` call result in a
frame slot, preserves later pointer callees when present, lowers both direct
and pointer-callee `i64` calls through the shared SysV scalar planner, and adds
the saved stack value back into `%rax`.
The i64 live-across-void follow-up preserves a direct or pointer-callee C ABI
`i64` result plus a live `i64` addend across a later direct or pointer-callee
side-effecting `void` call, then reloads `%rax` from the frame for the final
add.
The two-result i64/later-void follow-up preserves the second call's live
argument before the first call, stores both `%rax` results in aligned frame
slots, and reloads them after a later direct or pointer-callee `void` call.
The mixed-width follow-up preserves direct or pointer-callee `f32`/`f64` result
pairs in either order, reloads and extends the `f32` result with `cvtss2sd`,
then performs the final `f64` add.
The mixed numeric frontier also lowers typed AIR v2 `sitofp` plus `fadd` or
`fmul`/`fadd` pipelines for `i32` to `f32`/`f64`, including `mulss`/`mulsd`
codegen and executable C ABI checks.
The
remaining frontier backlog is private helper graphs with stack-passed live values beyond the current
selected direct-call/void-call model, broader live SSE values
beyond the selected one- through six-live `f32`/`f64` no-argument-call shapes,
selected direct two-/three-/six-live FP-argument call shapes,
two-live no-argument and one-FP-argument pointer-callee shapes,
three-/four-/six-live two-/three-/five-FP-argument pointer-callee shapes, and
or arbitrary mixed/non-void live values across calls beyond the selected
direct/indirect/later-void, indirect-later-void, and indirect-first ordered
`i32` result rows,
alternate safety-guard control flow, broader unknown aggregate/pointer/TLS
forms outside the selected scalar subset, full aggregate ABI lowering beyond
selected INTEGER/INTEGER, nested mixed INTEGER/SSE field reads/construction,
selected nested/array INTEGER construction returns,
selected mixed INTEGER/SSE and SSE/INTEGER low/high `i32`, `i64`, and `double`
field reads plus selected packed mixed construction returns, SSE/SSE field
reads including single-eightbyte `{ f32, f32 }` direct/shifted/indirect call
pass-through, `[2]f64` array-in-struct,
and nested `{ { double }, { double } }`, selected stack-passed register
aggregate field reads, and generated normal
MEMORY integer-leaf field/copy forms currently proven through thirty-two flat
fields, a nested two-Big3 aggregate, a mixed-width
`{ i64, i32, i64, i32 }` copy, and array-backed `{ [5 x i64] }` copy/read rows,
arbitrary non-selected sret/byval copies,
varargs, vectors, stack-passed live-value scheduling beyond the current selected
model, and
broader SSE live-across-call frames beyond the selected one-live through
six-live `f32`/`f64` no-argument-call shapes, selected direct
two-/three-/six-live FP-argument call shapes, selected stack-passed `f32`/`f64`
addend sums after a no-argument call,
selected direct/pointer-callee f32/f64 result live-across-later constant-stack-argument FP call frames,
selected two-live repeated no-argument direct and pointer-callee call shapes,
selected mixed one-GPR/one-SSE i32/i64 direct and pointer-callee call shapes,
selected one-FP-argument pointer-callee call shapes,
and selected three-/four-/six-live two-/three-/five-FP-argument pointer-callee
call shapes. The accepted frontier rows use typed
structured AIR v2 and generic CFG only; no case IDs, wrapper maps, source tags,
legacy AIR text lowering, shape recognizers, structural matcher fallback, LLVM
optimizer, LLVM TargetMachine, or LLD are involved.

Broad ReleaseFast also has a native Zig linker progress gate outside
`distribution-all`:
`zig build distribution-zig-air-uncurated-releasefast-broad-native-link` links
the z_llvm object for each broad source module with a tiny C `main` harness via
`zig build-exe -fno-lld`. It reports `native_link_accepted_rows=100`,
`executable_ok_rows=0`, `link_only_rows=100`, `runtime_boundary_rows=1`
(`debug.defaultPanic`), `unsupported_zig_linker_feature_rows=0`,
`native_link_failures=0`, `llvm_targetmachine_rows=0`, `lld_rows=0`, and
`local_fail=0`. This is link-only progress evidence, not executable ABI proof.

The broad release executable progress gates add stable C-ABI harnesses for the
runnable pure input modules and integrated wrapper `main` exports. The patched
Zig `zllvm-air-export-v1` hook now emits generic global/TLS initializer bytes,
and z_llvm materializes those initializers before object emission.
ReleaseFast, ReleaseSafe, and ReleaseSmall each report
`native_link_accepted_rows=100`, `executable_ok_rows=100`,
`link_only_rows=0`, `runtime_boundary_rows=1` (`debug.defaultPanic`),
`unsupported_zig_linker_feature_rows=0`, `native_link_failures=0`,
`llvm_targetmachine_rows=0`, `lld_rows=0`, and `local_fail=0`.

The closed link-only set was:
`test/zig/inputs/aggregate_abi.zig` and
`test/zig/inputs/atomics_inline_asm_debug.zig` (missing C ABI harnesses),
`test/zig/inputs/globals_comptime.zig`, `test/zig/inputs/tls_concurrency.zig`,
`test/zig/integrated/runtime_mix_c_add_zig_main.zig`,
`test/zig/integrated/runtime_optional_pointer_main.zig`,
`test/zig/integrated/runtime_pointer_load_store_main.zig`, and
`test/zig/integrated/runtime_tls_bump_main.zig` (global/TLS initializer
materialization). No accepted broad executable row remains link-only.

Captured loop-sum codegen regression closure:
The structural accumulator-loop matcher introduced when name-based dispatch
was removed (`Lower compiler AIR accumulator loops`) only accepted the
canonical four-block AIR shape, which silently orphaned three captured
loop-sum rows inside `zig build distribution-all`: the ReleaseFast 8x-unrolled
`control_flow_calls_loop_sum.ll` fixture, the ReleaseSafe checked 3x-unrolled
loop inside `control_flow_calls_checked.ll`, and the reduced Debug
`debug_loop_sum.reduced.ll` row with a signed loop bound. The backend now has
structural matchers for the unrolled shape (zero guard, unroll preheaders,
8-step body, lcssa split, epilogue loop) and the checked unrolled shape
(per-step `llvm.sadd.with.overflow.i32` with overflow panic edges and the
third-step out-of-bounds guard), and the canonical matcher accepts the signed
`slt` loop bound alongside `ult`. The external IR-writer loop-sum rows in the
integrated `--ir-writer` gate needed the same closure: structural matchers now
cover the writer's guarded do-while shape and its checked variant (loop-header
out-of-bounds guard, checked-add block, continue block). All rows lower
through the same counted-loop emission as before; `zig build distribution-all`
is green again end to end.

Regression distribution claim gates:
`zig build distribution-x86_64-selected-zllvm` is the stable compact selected
x86_64 release replacement gate. It emits one machine-readable `selected-zllvm`
line with row counts, structured direct/textual boundary counts,
`generic_codegen_rows`, `case_specific_codegen_rows`,
`minimal-ret0`, ownership, and first-failure fields. The current measured
split is `structured_direct_rows=146`, `textual_boundary_rows=0`,
`generic_codegen_rows=146`, and `case_specific_codegen_rows=0`.
Failure diagnostics and reproducibility inputs live in
`docs/x86_64_selected_zllvm_diagnostics.md`.

Broad source-backed gate:
`zig build distribution-x86_64-source-backed-structured` is the discovery-based
x86_64 release fixture gate. It walks the ReleaseFast, ReleaseSafe,
ReleaseSmall, and former ReleaseSmall exclusion `.ll` fixture directories,
runs every discovered source-backed structured-direct row, and fails on any
skip, fallback, textual LLVM parse, non-generic codegen, or local failure.
Current measured output is `discovered_fixtures=55`,
`accepted_fixtures=55`, `source_backed_rows=90`,
`structured_direct_rows=90`, `generic_codegen_rows=90`,
`skipped_with_reason=0`, `fallback_rows=0`, and `local_fail=0`.

Source-wrapper structured-direct gate:
`zig build distribution-zig-source-structured-direct` starts from standalone
Zig source wrappers instead of using `ZLLVM_CASE_ID` as the primary selector.
Patched Zig passes wrapper path, optimize mode, target, output path, and marker
path; z_llvm resolves the structured module from wrapper/source metadata for
the unambiguous wrapper/mode subset. Current measured output is
`source_wrappers=49`, `structured_direct_rows=49`, `case_id_rows=0`,
`generic_codegen_rows=49`, `manifest_structured_rows=0`,
`semantic_record_rows=48`, `external_writer_delegate_rows=1`,
`case_specific_rows=0`, `fallback_rows=0`, and `local_fail=0`.

Source-wrapper discovery bucket:
The source-owned gate now scans `test/zig/integrated/*.zig` directly as a
separate discovery bucket, not as additional case-id selected rows. Current
measured output is `discovered_source_wrappers=82`,
`descriptor_supported_wrappers=82`, `out_of_scope_wrappers=0`, and
`unsupported_with_reason=0`; the formerly out-of-scope release wrappers are now
part of the source-owned inventory.

Ownership ladder:
The current replacement evidence is split into four explicit rungs:
selected case-id registry proof, broad source-backed structured proof,
source-wrapper compatibility proof, and source-owned DescriptorV2 proof. The
source-owned rung is now strongest: all 100 current source-owned release rows
start from a Zig-emitted `zllvm-source-facts-v1` fact stream, not a Zig-emitted
DescriptorV2 body. z_llvm classifies those facts into DescriptorV2 and parses
the resulting serialized semantic records directly. They report
`lowering=semantic-descriptor-v2`, with
`descriptor_owned_rows=100`, `descriptor_v2_rows=100`,
`real_descriptor_program_rows=100`, `full_descriptor_program_rows=100`,
`serialized_function_rows=100`, `serialized_instruction_rows=100`,
`serialized_global_rows=100`, `descriptor_body_name_rows=0`,
`zllvm_body_expansion_rows=0`, `descriptor_program_body_expansion_rows=0`,
`functions_for_body_rows=0`, `globals_for_body_rows=0`,
`semantic_serialized_rows=100`, `serialized_return_stub_rows=0`,
`air_derived_descriptor_rows=100`, `static_descriptor_map_rows=0`,
`zig_emitted_descriptor_rows=100`,
`runner_generated_descriptor_rows=0`, `descriptor_file_consumed_rows=100`,
`source_fact_stream_rows=100`, `concrete_source_fact_rows=100`,
`source_derived_descriptor_rows=100`, `tag_table_descriptor_rows=0`,
`body_enum_dispatch_rows=0`,
`surface_to_body_adapter_rows=0`,
`canned_return_descriptor_rows=0`, `manual_fixture_dispatch_rows=0`,
`legacy_semantic_record_rows=0`, `semantic_record_rows=0`, `surface_dispatch_rows=0`,
`external_writer_delegate_rows=0`, and no manifest-shaped structured rows in
that gate. Serialized AIR-shaped transport is proven for all 100 rows because
those rows emit semantic DescriptorV2 records and the gate rejects any
serialized return stub. Current provenance counters show
`air_extracted_descriptor_rows=100`, `template_descriptor_rows=0`,
`wrapper_body_map_rows=0`, `source_tag_body_map_rows=0`,
`zig_compile_context_descriptor_rows=100`, `env_source_tag_selector_rows=0`,
`wrapper_body_selector_rows=0`, `source_tag_body_selector_rows=0`, and
`fixture_metadata_selector_rows=0`, and `source_tag_env_present_rows=0`, so
source tag, wrapper basename, fixture
metadata, body-template, and body-enum ownership are no longer accepted by that
gate. Every source-owned row now uses the extracted-record path with
compile-context fact provenance, direct SourceFactProgram DescriptorV2
construction, and no body-map selector, root-source classification fallback, or
body-enum fallback.
The narrower source-wrapper compatibility
proof remains a separate regression rung; that compatibility gate now has 48
semantic record rows and one external writer delegate because it intentionally
covers only unambiguous wrapper/mode inputs.
The detailed source-wrapper milestone is recorded in
`docs/roadmap/x86_64_source_wrapper_semantic_lowering.md`; the source-owned
template inventory is recorded in
`docs/roadmap/x86_64_source_owned_descriptor_template_inventory.md`.

Next target:
The current x86_64 ReleaseFast/ReleaseSafe/ReleaseSmall fixture inventory is
fully accounted locally. Future expansion should add new fixtures or corpus
inputs through reusable structured-builder and generic x86_64 lowering helpers;
the broad gate should report the first unsupported fixture class exactly if a
new row cannot be closed cleanly.

Promoted structural frontier - generic x86_64 CFG lowering:
The generic CFG backend route is active behind a strict eligibility check. It
validates every instruction and terminator before routing, keeps the old
structural matchers as fallback, and fails closed instead of silently falling
back when an eligible row cannot use the generic path. Coverage now includes
the loop-sum family, simple single-block scalar integer returns, scalar
`icmp eq/ne` plus `select` returns, parameter-pointer load/store branch CFGs,
load-after-store merge returns, pointer-select loads, direct-call branch merge
CFGs, single-block global/TLS i32 load/update forms, single-block scalar FP
binary/compare/select/literal returns, single-block volatile i32 roundtrips,
single-block packed read/replace bit helpers, scalar numeric conversion casts,
signed-min `icmp slt`/`select` classifiers, nested `i8` equality error-switch
and error-union classifier selects, boolean-parameter branch-mix add/sub
selects, constant-return `i8 switch` CFGs, void `i32` global/TLS store helpers,
small aggregate pair SysV pack/unpack helpers, and checked guard CFGs for
checked `@intFromFloat` and guarded table lookup/bounds paths. Gates report
`generic_cfg_functions` and `structural_matcher_functions`: broad reports
ReleaseFast `152/0`, ReleaseSafe `152/0`, ReleaseSmall `152/0`; frontier
reports ReleaseFast `166/0`, ReleaseSafe `166/0`, ReleaseSmall `166/0`; expanded
reports ReleaseFast `199/0`, ReleaseSafe `199/0`, ReleaseSmall `199/0`.
The scale frontier reports ReleaseFast `216/0`, ReleaseSafe `216/0`, and
ReleaseSmall `216/0`.
Former structural aggregate field-offset rows now include alloca-stored pointer
field loads at offsets 0 and 4 plus branch-local field-0 updates. The
conditional slice-loop row has also moved into generic CFG as a conservative
loop-memory dependency subset, expanded optional-pointer load-plus-add payload
blocks now use the generic optional-pointer CFG path, and
the f32 pipeline row with an unused scalar bool parameter now uses generic FP
binary CFG lowering. The base64 byte-table lookup leaf now routes through a
shape-based generic byte-table helper. `runtime_hidden_access_main.updateHidden`
now uses the same generic void global-store path as ordinary single-block
store helpers. Source-facing and expanded small aggregate pair pack/unpack
helpers, plus runtime aggregate pair leaf helpers, now route through the
generic aggregate-ABI CFG admission path. Selected monotonic atomic add and
empty inline-asm memory-barrier leaves now route through the generic
effect-barrier CFG admission path while preserving atomic/asm barrier
semantics. Empty no-op `ret void` helpers now route through the generic void CFG
path, and no-arg void-call wrapper mains returning `i32 0` now use a
shape-driven generic CFG admission instead of a wrapper-name-specific lowerer.
Scalar `shift_mix`, scalar multiply-by-constant, and i64 constant-return leaves
now route through the generic scalar/i64 CFG admission paths, including
`control_flow_calls.callee`, `globals_comptime.comptime_const`, and the
selected i64 wrapper-family mains that reduce to those leaves. Constant FP/bool
and integer-return sibling-wrapper call/check mains now use a generic CFG
admission rather than selected runtime wrapper tables, and sibling update/get
wrapper mains now use generic direct-call lowering instead of hidden-global
structural lowering. Constant direct-call wrapper mains with optional identity
casts now use generic direct-call lowering, covering mixed C/Zig and TLS bump
wrapper checks. Pointer-literal sibling call/check wrapper mains now validate
`ptr @global`/`ptr null` arguments through the same generic admission, moving
the slice-sum, struct-sum, and volatile roundtrip wrapper checks out of the
structural bucket. Two-call aggregate wrapper chains that pass an i64 return
into an i32 helper now emit real calls through generic CFG, moving
`runtime_aggregate_pair_main.main` out of the structural bucket. Multi-block
call/global-load checks with a boolean merge now emit real sibling calls and
RIP-relative global-address arguments through generic CFG, moving
`runtime_pointer_load_store_main.main` out of the structural bucket. Multi-block
two-call optional-pointer wrapper checks now validate `ptr @global` and
`ptr null` sibling call arguments through generic CFG, moving
`runtime_optional_pointer_main.main` out of the structural bucket. The mixed
C/Zig panic-edge/runtime-boundary arithmetic leaf now also routes through
generic CFG after proving the negative guard, `debug.defaultPanic` noreturn
edge, global-load/add return, and checked overflow edge. The broad and expanded
release gates currently have no structural matcher backend rows.

Source coverage discovery:
The current release-mode captured IR inventory was checked with `find` over
`test/distribution/releasefast_x86_64/inputs`,
`test/distribution/releasesafe_x86_64/inputs`,
`test/distribution/releasesmall_x86_64/inputs`, and the ReleaseSmall
`exclusions` directory. It contains 55 x86_64 release-mode `.ll` fixtures:
27 ReleaseFast, 9 ReleaseSafe, and 19 ReleaseSmall/former-boundary fixtures.
The fixed external IR-writer gate includes 146 selected rows. The separate
broad source-backed gate now adds 90 rows that cover every currently discovered
release fixture family: integer add/wrap and cmp/shift, control-flow loop and
call-chain, branch-mix and dense switch, pointer memory, optional pointer,
packed bits, aggregate struct/array/optional/error/slice shapes, FP
constants/compare/math/extended ops, globals, TLS, atomics, inline asm,
aggregate ABI, ReleaseSafe checked globals/pointers/branches/calls/TLS and
aggregate rows, ReleaseSmall hidden-global, mixed C/Zig, i64, compile-asm,
table-load rows, start trampolines, getauxval pointer walking, f128 sret/byval
ABI shapes, logical-pointer unreachable stubs, address-space volatile stores,
raw `_start` loops, and libfuzzer futex/name/run boundaries. The selected
writer gate is
`total=146 executable_ok=146 link_only_ok=0 local_fail=0`, with
`scalar_runtime_rows=146 minimal_wrapper_rows=0`.

Coverage classification:
The covered source-backed rows reuse existing helper families for loops/phis,
calls, aggregates, pointer/memory, checked arithmetic, TLS/globals, FP, and
runtime boundaries. No current release-mode fixture remains skipped. Future
helper candidates should be created only when a newly discovered fixture exposes
a real repeated family. The detailed inventory is recorded in
`docs/roadmap/x86_64_selected_ir_writer_source_coverage.md`.

Zig evidence:
The completed `releasefast_runtime_cond_branch` and
`releasefast_runtime_phi_merge` rows are paired with
`test/zig/inputs/switch_control.zig`; `releasefast_runtime_loop_sum` is paired
with `test/zig/inputs/control_flow_calls.zig`; `releasefast_runtime_switch` is
paired with `test/zig/inputs/switch_control.zig`;
`releasefast_runtime_global_update` is paired with
`test/zig/inputs/globals_comptime.zig`; `releasefast_runtime_call_chain` is
paired with `test/zig/inputs/control_flow_calls.zig`;
`releasesmall_runtime_i64_call` is paired with
`test/zig/inputs/i64_arithmetic.zig`. The `releasefast_runtime_tls_read` and
`releasefast_runtime_tls_bump` rows cover selected local-exec TLS read/update
evidence. The `releasefast_runtime_atomic_add` row covers selected monotonic
atomic add evidence. The `releasefast_runtime_inline_asm_barrier` row covers
the selected side-effecting memory-barrier inline asm shape. The
`releasefast_runtime_aggregate_pair` row covers the selected two-i32 aggregate
ABI shape from `test/zig/inputs/aggregate_abi.zig`. The next source-backed
`releasefast_runtime_float_less` row covers the selected
`float_less(a: f32, b: f32) bool` family from
`test/zig/inputs/float_compare.zig`, and `releasefast_runtime_float_mul`
now covers `float_mul(a: f64, b: f64) f64` from the same fixture. The next
`releasefast_runtime_float_add` row now covers
`float_add(a: f32, b: f32) f32`, and the next
`releasefast_runtime_float_select` row covers
`float_select(a: f64, b: f64, flag: bool) f64` from
`test/zig/inputs/floats_math.zig`. The external-writer completed
`releasefast_runtime_float_sub` row now covers
`float_sub(a: f32, b: f32) f32`, and the next
`releasefast_runtime_double_div` row covers
`double_div(a: f64, b: f64) f64` from
`test/zig/inputs/fp_extended_ops.zig`. The completed
`releasefast_runtime_float_rem` row uses the same fixture's selected
`float_rem(a: f32, b: f32) f32` family that appears in captured ReleaseFast
x86_64 IR and selected x86_64 FP object/codegen evidence.
The `releasesmall_runtime_base64_decode_base_64_full` row is now promoted to
whole-function ReleaseSmall boundary closure for base64. The external IR writer
emits the full `@base64.decode_base_64` body with named blocks, loop phis,
source/table loads from a real 256-byte decode table, byte masks, shifts,
truncation, output stores, pointer index advancement, success exit, and fail
exit. Its executable `@main` validates `TWFu -> Man`, `TWE= -> Ma`,
`TQ== -> M`, and invalid `!!!! -> -1`; the x86_64 backend lowers the decoder
through the real table-driven loop path rather than the former selected
boundary shortcut.

`strFromFloatHelp` full-function closure is promoted from
`test/distribution/releasesmall_x86_64/exclusions/standalone_emit_llvm_no_bin_str_from_float_help.ll`.
The tracked helper is 1005 lines overall, with `@main.strFromFloatHelp`
running from line 37 through line 670 before the helper callees. The full
function has the initial double bitcast/exponent branch, pow5/inv-pow5 table
paths, `fmt.float.mulShift64` calls, multiple-of-power-of-5 calls, decimal
length/write loops, fixed/scientific formatting branches, writer buffer
copies, and final buffer-print writer dispatch. The
`releasesmall_runtime_str_from_float_help` executable row now calls the helper
from `@main`, covers stack slots, lifetime markers, double bitcast/exponent
classification, pow5/inv-pow5 table loads, decimal loop CFG, `i128`
arithmetic/truncation, `llvm.assume`, `llvm.memcpy`/`llvm.memset`, fastcc
pointer helper calls, and the writer-vtable indirect-call boundary. The proof
label is `whole-function:str-from-float-help`, and
`zig build distribution-releasesmall-boundary` now reports both former
ReleaseSmall exclusions as `[local-object]`.
The completed `releasefast_runtime_pointer_load_store` row is paired with
`pointers_memory.load_store(p: *i32, q: *i32) i32` from
`test/zig/inputs/pointers_memory.zig`, which exercises a pointer load, integer
add, pointer store, and re-load through the external writer path.
The completed `releasefast_runtime_volatile_roundtrip` row from the same
fixture is `pointers_memory.volatile_roundtrip(p: *volatile i32, value: i32)
i32`, which exercises selected volatile store/load preservation through the
external writer path.
The completed `releasefast_runtime_optional_pointer` row is paired with
`optional_pointer.optional_ptr_value(p: ?*const i32) i32` from
`test/zig/inputs/optional_pointer.zig`, which exercises pointer null-check
control flow and a selected non-null `i32` load.
The completed `releasefast_runtime_packed_read_flag` row is paired with
`packed_bits.read_flag(raw: u8) bool` from
`test/zig/inputs/packed_bits.zig`, which exercises selected packed-bitfield
read/bit-test behavior.
The completed `releasefast_runtime_packed_replace_low` row from the same
fixture is `packed_bits.replace_low(raw: u8, value: u8) u8`, which exercises
selected packed low-bit replacement with mask/or integer operations.
The completed `releasefast_runtime_struct_sum` row is paired with
`aggregates.struct_sum(pair: *const Pair) i32` from
`test/zig/inputs/aggregates.zig`, which exercises two `i32` field loads from
an extern struct pointer and a scalar add. The completed
`aggregates.array_sum(a: i32, b: i32, c: i32) i32` from the same fixture,
which appears in captured ReleaseFast x86_64 IR as a scalarized
three-argument add chain, is now covered by
`releasefast_runtime_array_sum`. The next source-backed shape is
`aggregates.optional_payload(flag: i32, value: i32) i32` from the same fixture,
which appears in captured ReleaseFast x86_64 IR as an `icmp eq` and `select`
over a scalar optional payload and is now covered by
`releasefast_runtime_optional_payload`. The next source-backed shape is
`aggregates.error_union_payload(flag: i32) i32`, which appears in captured
ReleaseFast x86_64 IR as an `icmp eq` and `select` over the success payload
and catch fallback and is now covered by
`releasefast_runtime_error_union_payload`. The next source-backed shape is
`aggregates.slice_sum(ptr: [*]const i32, len: usize) i32`, which appears in
captured ReleaseFast x86_64 IR as a loop with phi values, indexed GEP, `i32`
load, add, and loop-exit branch and is now covered by
`releasefast_runtime_slice_sum`. The next source-backed shape is
`fp_constants.float_literal() f32` / `fp_constants.double_literal() f64`,
which appears in captured ReleaseFast x86_64 IR as direct `ret float` and
`ret double` constants and is now covered by
`releasefast_runtime_fp_constants`. The next source-backed shape is
`globals_comptime.comptime_const(value: i32) i32`, which appears in captured
ReleaseFast x86_64 IR as an `i32` multiply by the comptime-known scale value
and is now covered by `releasefast_runtime_comptime_const`. The next
source-backed shape is
`atomics_inline_asm_debug.debug_location(value: i32) i32`, which appears in
captured ReleaseFast x86_64 IR as selected `add nsw i32 %0, 1` plus a direct
return and is now covered by `releasefast_runtime_debug_location`. The next
source-backed shape is
`atomics_inline_asm_debug.debug_location(value: i32) i32` under ReleaseSafe,
which appears in captured ReleaseSafe x86_64 IR as `llvm.sadd.with.overflow`
plus an integer-overflow panic edge and is now covered by
`releasesafe_runtime_debug_location`. The next source-backed shape is
`globals_comptime.comptime_const(value: i32) i32` under ReleaseSafe, which
appears in captured ReleaseSafe x86_64 IR as checked multiply-by-five with an
integer-overflow panic edge and is now covered by
`releasesafe_runtime_comptime_const`. The next source-backed shape is
`globals_comptime.update_global(value: i32) i32` under ReleaseSafe, which
appears in captured ReleaseSafe x86_64 IR as a private `i32` global load,
checked add with `llvm.sadd.with.overflow.i32`, overflow branch to the same
integer-overflow panic edge, non-overflow store back to the private global,
and returned updated value and is now covered by
`releasesafe_runtime_global_update`. The next source-backed shape is
`pointers_memory.load_store(p: *i32, q: *i32) i32` under ReleaseSafe, which
appears in captured ReleaseSafe x86_64 IR as an `i32` pointer load, checked
add-one with `llvm.sadd.with.overflow.i32`, overflow branch to the same
integer-overflow panic edge, non-overflow pointer store, and returned updated
value and is now covered by `releasesafe_runtime_pointer_load_store`. The
next source-backed shape is `switch_control.branch_mix(a: i32, b: i32, flag:
bool) i32` under ReleaseSafe, which appears in captured ReleaseSafe x86_64 IR
as a flag branch, checked add path, checked subtract path, merge phi, and two
integer-overflow panic edges and is now covered by
`releasesafe_runtime_branch_mix`. The next source-backed shape is
`control_flow_calls.call_chain(value: i32) i32` under ReleaseSafe, which
appears in captured ReleaseSafe x86_64 IR as a selected checked callee-range
guard followed by `shl nsw` and `or` result construction and is now covered
by `releasesafe_runtime_call_chain`. The next source-backed shape is
`tls_concurrency.bump_tls(value: i32) i32` under ReleaseSafe, which appears in
captured ReleaseSafe x86_64 IR as a local-exec TLS load, checked add with
`llvm.sadd.with.overflow.i32`, overflow panic edge, TLS store, and returned
updated value and is now covered by `releasesafe_runtime_tls_bump`. The next
source-backed shape is `aggregates.array_sum(a: i32, b: i32, c: i32) i32`
under ReleaseSafe, which appears in captured ReleaseSafe x86_64 IR as two
checked `llvm.sadd.with.overflow.i32` operations and two integer-overflow
panic edges and is now covered by `releasesafe_runtime_array_sum`. The next
source-backed shape is `aggregates.struct_sum(pair: *const Pair) i32` under
ReleaseSafe, which appears in captured ReleaseSafe x86_64 IR as two `i32`
field loads, one checked `llvm.sadd.with.overflow.i32` operation, and one
integer-overflow panic edge and is now covered by
`releasesafe_runtime_struct_sum`. The next source-backed shape is
`aggregates.slice_sum(ptr: [*]const i32, len: usize) i32` under ReleaseSafe,
which appears in captured ReleaseSafe x86_64 IR as a loop with phi values,
indexed GEP/load, checked `llvm.sadd.with.overflow.i32` operation in the loop
body, and an integer-overflow panic edge and is now covered by
`releasesafe_runtime_slice_sum`. The next source-backed shape is
`control_flow_calls.loop_sum(count: i32) i32` under ReleaseSafe, which appears
in captured ReleaseSafe x86_64 IR as a counted loop with phi values, checked
`llvm.sadd.with.overflow.i32` operations, integer-overflow panic edges, and
the selected integer-out-of-bounds panic edge and is now covered by
`releasesafe_runtime_loop_sum`. The next source-backed shape is
`globals_comptime.read_global() i32` under ReleaseSafe, which appears in
captured ReleaseSafe x86_64 IR as a private global `i32` load and direct
return through the ReleaseSafe accepted pipeline and is now covered by
`releasesafe_runtime_read_global`. The next source-backed shape is
`tls_concurrency.read_tls() i32` under ReleaseSafe, which appears in captured
ReleaseSafe x86_64 IR as a direct local-exec TLS `i32` load and return and
is now covered by `releasesafe_runtime_tls_read`. The next source-backed
shape is `tiny_scalar.sideEffectFree() void` under ReleaseSafe, which appears
in captured ReleaseSafe x86_64 IR as a private void function with a direct
`ret void` and is now covered by
`releasesafe_runtime_side_effect_free`. The next source-backed shape is the
ReleaseSmall `standalone_extern_exports_hidden_access` row, which exposes a
private hidden `i32` global through `getHidden() i32` and
`updateHidden(value: i32) void` aliases and is now covered by
`releasesmall_runtime_hidden_access`. The next source-backed shape is the
ReleaseSmall `standalone_mix_c_files_add_zig` row, which loads Zig-owned
`main.zig_k`, combines it with an argument, then combines that value with a
C-owned TLS `C_k` input and is now covered by
`releasesmall_runtime_mix_c_add_zig`. The next source-backed shape is the
ReleaseSmall `standalone_mix_c_files_add_may_panic` row, which branches on a
negative argument, calls the selected panic runtime edge on that path, and
otherwise loads `main.zig_k`, adds the non-negative argument, and returns the
sum and is now covered by `releasesmall_runtime_mix_c_add_may_panic`. The
next source-backed shape is the ReleaseSmall
`no_compile_panic_for_unchecked_arith_umul_fix_sat_i64` row, which calls
`llvm.umul.fix.sat.i64(i64 0, i64 2, i32 0)` and returns the `i64` result
and is now covered by `releasesmall_runtime_umul_fix_sat_i64`. The next
source-backed shape is the ReleaseSmall `inherit_want_safety_i64_return` row,
which returns `i64 4` through an `entry` alias and is now covered by
`releasesmall_runtime_inherit_want_safety_i64`. The next source-backed shape
is the ReleaseSmall `standalone_compile_asm_main_unreachable` row, which
aliases `@main` to `@main.main` and lowers to an empty noreturn
`unreachable` stub with three `i32` parameters and is now covered by
`releasesmall_runtime_compile_asm_unreachable`. The next measured ReleaseSmall
boundary is the `standalone_emit_llvm_no_bin_main` row, whose selected alias is
`@strFromFloatHelp -> @main.strFromFloatHelp`, a multi-block float-format
helper. That boundary now has a reduced external writer prologue slice covered
by `releasesmall_runtime_str_from_float_help`. The next measured ReleaseSmall
boundary is the `standalone_mix_o_files_base64` row, whose selected alias is
`@decode_base_64 -> @base64.decode_base_64`, a table-driven multi-block
decoder. That boundary now has a reduced table-load/OR/validity step covered
by `releasesmall_runtime_base64_decode_step`. The next selected slice from the
same decoder is the decoded-word store step around block `%164`, which stores
the combined i32 word to the output pointer and returns to the narrow decode
loop and is now covered by `releasesmall_runtime_base64_store_step`. The next
selected slice from the same decoder is the residual byte emit path around
block `%189`, which masks the residual bit count, shifts/truncates the i12
accumulator to i8, stores one output byte, and advances the output index and
is now covered by `releasesmall_runtime_base64_residual_byte_step`. The next
selected slice from the same decoder is the padding-tail byte check around
block `%206`, which loads a remaining source byte and accepts only `=`
padding, and is now covered by
`releasesmall_runtime_base64_padding_tail_step`. The next selected slice from
the same decoder is the padding-tail loop walk around block `%205`, which
advances across accepted trailing padding bytes, and is now covered by
`releasesmall_runtime_base64_padding_loop_step`. The next selected slice from
the same decoder is the entry padding length adjustment in `.critedge.i`,
which loads the last two source bytes, compares each with `=`, sign-extends
the boolean results to `i64`, and adds them to the computed output length,
and is now covered by
`releasesmall_runtime_base64_padding_length_step`. The next selected slice
from the same decoder is the chunk-loop guard in block `%18`, which advances
the source/output indexes by 16 and 15 bytes, compares both against the input
and output bounds, combines the predicates with `select`, and branches into
the wide decode loop only when both are in range, and is now covered by
`releasesmall_runtime_base64_chunk_guard_step`. The next selected slice from
the same decoder is the wide decode source-byte stride in block `%24`, which
computes a source byte address, loads an `i8`, zero-extends it to `i64`, uses
that index for a table GEP, and loads the selected table word, and is now
covered by `releasesmall_runtime_base64_source_stride_step`. The next selected
slice from the same decoder is the four-byte source bundle for one wide decode
word in block `%24`, and is now covered by
`releasesmall_runtime_base64_source_bundle_step`. The next selected slice from
the same decoder is the next four-byte source bundle in block `%73`, and is
now covered by `releasesmall_runtime_base64_next_source_bundle_step`. The next
selected slice from the same decoder is the third four-byte source bundle in
block `%97`, and is now covered by
`releasesmall_runtime_base64_third_source_bundle_step`. The next selected
slice from the same decoder is the wide `i128` bit-buffer combine and output
store in block `%121`, and is now covered by
`releasesmall_runtime_base64_bit_buffer_store_step`. The next selected slice
from the same decoder is the source/output index advance and backedge at the
end of block `%121`, and is now covered by
`releasesmall_runtime_base64_loop_advance_step`. The next selected slice from
the same decoder is the residual/preheader guard before block `%139`, and is
now covered by `releasesmall_runtime_base64_residual_guard_step`. The next
selected slice from the same decoder is the residual four-byte source/table
bundle in block `%139`, and is now covered by
`releasesmall_runtime_base64_residual_bundle_step`. The next selected slice is
the residual output store and `-4` backedge, and is now covered by
`releasesmall_runtime_base64_residual_store_step`. The next selected slice is
the residual remaining-length calculation in block `%162`, and is now covered
by `releasesmall_runtime_base64_residual_length_step`. The next selected slice
is the residual byte-loop/table check in block `%169`, and is now covered by
`releasesmall_runtime_base64_residual_table_check_step`. The next selected
slice is the residual accumulator update in block `%176`, and is now covered
by `releasesmall_runtime_base64_residual_accumulator_step`. The next selected
slice is the residual loop-index advance in block `%187`.

LLVM fallback removed or reduced:
Reduce the integrated preopt object-emission gap for the selected
ReleaseFast `f64` divide row. The current failing wrapper is
`test/zig/integrated/runtime_double_div_main.zig`, paired with
`test/zig/inputs/fp_extended_ops.zig`, after patched Zig writes preopt IR,
z_llvm runs the ReleaseFast accepted pipeline, and z_llvm attempts local
x86_64 object emission.

Mode/target/stage row:
ReleaseFast / x86_64-linux-gnu / integrated Zig preopt hook -> accepted
optimizer pipeline -> local object -> Zig native-link executable proof.

Upstream mapping:
LLVM lowers the completed slice-sum source row to a loop in
`test/distribution/releasefast_x86_64/inputs/aggregates_slice_sum.ll` with:
`%.010 = phi i32 [ 0, %2 ], [ %5, %.lr.ph ]`,
`%.089 = phi i64 [ 0, %2 ], [ %6, %.lr.ph ]`,
`%3 = getelementptr [4 x i8], ptr %0, i64 %.089`,
`%4 = load i32, ptr %3, align 4`, `%5 = add nsw i32 %4, %.010`,
and a loop-exit compare/branch.
The next selected aggregate ABI row lowers in
`test/distribution/releasefast_x86_64/inputs/aggregate_abi_pair.ll` to
`aggregate_abi.pair_first(i64 %0)`, which truncates the low i32 half and
returns it, and `aggregate_abi.make_pair(i32 %0, i32 %1)`, which zexts,
shifts, ORs, and returns an i64 packed two-i32 pair. The integrated preopt
wrapper source returns the first field from `makePair(1, 2)`, and is now
covered by `releasefast_runtime_aggregate_pair`. The next selected float row
lowers in `test/distribution/releasefast_x86_64/inputs/float_compare_basic.ll`
to `float_compare.float_less(float %0, float %1)` with
`%3 = fcmp olt float %0, %1` and `ret i1 %3`; the integrated wrapper checks
`floatLess(1.0, 2.0)` and returns 0 on success, and is now covered by
`releasefast_runtime_float_less`. The next selected float row lowers in the
same fixture to `float_compare.float_mul(double %0, double %1)` with
`%3 = fmul double %0, %1` and `ret double %3`; the integrated wrapper checks
`floatMul(3.0, 2.0) == 6.0` and returns 0 on success, and is now covered by
`releasefast_runtime_float_mul`. The next selected float row lowers in
`test/distribution/releasefast_x86_64/inputs/floats_math_basic.ll` to
`floats_math.float_add(float %0, float %1)` with
`%3 = fadd float %0, %1` and `ret float %3`; the integrated wrapper checks
`floatAdd(1.0, 2.0) == 3.0` and returns 0 on success, and is now covered by
`releasefast_runtime_float_add`. The next selected float row lowers in the
same fixture to `floats_math.float_select(double %0, double %1, i1 %2)` with
`%. = select i1 %2, double %0, double %1` and `ret double %.`; the
integrated wrapper checks the selected branch result and returns 0 on success,
and is now covered by `releasefast_runtime_float_select`. The next selected
float row lowers in
`test/distribution/releasefast_x86_64/inputs/fp_extended_ops_basic.ll` to
`fp_extended_ops.float_sub(float %0, float %1)` with
`%3 = fsub float %0, %1` and `ret float %3`; the integrated wrapper checks
`floatSub(5.0, 2.0) == 3.0` and returns 0 on success, and is now covered by
`releasefast_runtime_float_sub`. The next selected row lowers in the same
fixture to `fp_extended_ops.double_div(double %0, double %1)` with
`%3 = fdiv double %0, %1` and `ret double %3`; the integrated wrapper checks
`doubleDiv(6.0, 2.0) == 3.0` and returns 0 on success.
The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/atomics_debug_location_checked.ll`
to `llvm.sadd.with.overflow.i32`, an overflow branch to
`debug.FullPanic((function 'defaultPanic')).integerOverflow`, and a non-overflow
`extractvalue` return and is now covered by
`releasesafe_runtime_debug_location`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/globals_comptime_checked.ll` to
`llvm.smul.with.overflow.i32(i32 %0, i32 5)`, an overflow branch to the same
integer-overflow panic edge, and a non-overflow `extractvalue` return and is
now covered by `releasesafe_runtime_comptime_const`. Source behavior is
represented by Zig's `globals_comptime` fixture. The next selected row lowers
in the same file to private global load from
`@globals_comptime.global_counter`, `llvm.sadd.with.overflow.i32`, overflow
branch to the same panic edge, non-overflow `store i32` back to the private
global, and `ret i32` of the updated value and is now covered by
`releasesafe_runtime_global_update`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/pointers_memory_checked.ll` to
`load i32, ptr %0`, `llvm.sadd.with.overflow.i32(i32 %3, i32 1)`, an overflow
branch to the same panic edge, non-overflow `store i32 %8, ptr %1`, and
`ret i32 %8` and is now covered by
`releasesafe_runtime_pointer_load_store`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/switch_control_branch_mix_checked.ll`
to a branch on the `i1` flag, `llvm.sadd.with.overflow.i32` for the true path,
`llvm.ssub.with.overflow.i32` for the false path, a merge `phi`, and two
integer-overflow panic edges and is now covered by
`releasesafe_runtime_branch_mix`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/control_flow_calls_checked.ll` to
`add i32 %0, 1073741824`, `icmp slt`, a panic edge on negative, and
non-overflow result construction with `shl nsw i32 %0, 1` and
`or disjoint i32 %5, 1` and is now covered by
`releasesafe_runtime_call_chain`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/tls_concurrency_checked.ll` to a
private `thread_local` `@tls_concurrency.tls_counter`, TLS load,
`llvm.sadd.with.overflow.i32`, overflow panic edge, non-overflow TLS store,
and `ret i32` of the updated value and is now covered by
`releasesafe_runtime_tls_bump`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/aggregates_checked_sums.ll` to
`aggregates.array_sum` with checked add of `%0 + %1`, overflow branch, checked
add of that result plus `%2`, a second overflow branch, and `ret i32` of the
second extractvalue result and is now covered by
`releasesafe_runtime_array_sum`. The next selected row lowers in the same file
to `aggregates.struct_sum` with `load i32, ptr %0`,
`getelementptr i8, ptr %0, i64 4`, `load i32, ptr %3`,
`llvm.sadd.with.overflow.i32(i32 %2, i32 %4)`, an integer-overflow panic edge,
and `ret i32` of the extractvalue result and is now covered by
`releasesafe_runtime_struct_sum`. The next selected row lowers in the same
file to `aggregates.slice_sum` with two loop phi values, indexed GEP/load,
`llvm.sadd.with.overflow.i32` in the loop body, an integer-overflow panic edge,
and loop-exit branch to the final sum and is now covered by
`releasesafe_runtime_slice_sum`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/control_flow_calls_checked.ll` to
`control_flow_calls.loop_sum` with counted-loop phi values, checked add
operations in the loop body, integer-overflow panic edges, and the selected
integer-out-of-bounds panic edge and is now covered by
`releasesafe_runtime_loop_sum`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/globals_comptime_checked.ll` to
`globals_comptime.read_global` with `load i32, ptr @globals_comptime.global_counter`
and direct `ret i32` and is now covered by
`releasesafe_runtime_read_global`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/tls_concurrency_checked.ll` to
`tls_concurrency.read_tls` with a direct load from
`@tls_concurrency.tls_counter` and `ret i32` and is now covered by
`releasesafe_runtime_tls_read`. The next selected row lowers in
`test/distribution/releasesafe_x86_64/inputs/tiny_scalar_checked_add.ll` to
`tiny_scalar.sideEffectFree` with a direct `ret void` and is now covered by
`releasesafe_runtime_side_effect_free`. The next selected row lowers in
`test/distribution/releasesmall_x86_64/inputs/standalone_extern_exports_hidden_access.ll`
to `exports.getHidden` and `exports.updateHidden` over private
`@exports.hidden` storage and is now covered by
`releasesmall_runtime_hidden_access`. The next selected row lowers in
`test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_zig.ll`
to `main.add_zig`, which loads private `@main.zig_k`, adds the incoming
argument, loads `@C_k`, and returns the combined sum and is now covered by
`releasesmall_runtime_mix_c_add_zig`. The next selected row lowers in
`test/distribution/releasesmall_x86_64/inputs/standalone_mix_c_files_add_may_panic.ll`
to `main.add_may_panic`, which branches on `icmp slt i32 %0, 0`, calls
`debug.defaultPanic` on the panic edge, and returns `@main.zig_k + %0` on the
non-panicking edge and is now covered by
`releasesmall_runtime_mix_c_add_may_panic`. The next selected row lowers in
`test/distribution/releasesmall_x86_64/inputs/no_compile_panic_for_unchecked_arith_umul_fix_sat_i64.ll`
to a selected `llvm.umul.fix.sat.i64` intrinsic call and `ret i64` and is now
covered by `releasesmall_runtime_umul_fix_sat_i64`. The next selected row
lowers in
`test/distribution/releasesmall_x86_64/inputs/inherit_want_safety_i64_return.ll`
to `inherit_want_safety.entry` with direct `ret i64 4` and is now covered by
`releasesmall_runtime_inherit_want_safety_i64`. The next selected row lowers
in
`test/distribution/releasesmall_x86_64/inputs/standalone_compile_asm_main_unreachable.ll`
to `@main = alias void (i32, i32, i32), ptr @main.main`, where
`main.main` contains only `unreachable`, and is now covered by
`releasesmall_runtime_compile_asm_unreachable`. The next selected row is the
ReleaseSmall boundary exclusion
`standalone_emit_llvm_no_bin_main.zig.ReleaseSmall.x86_64.optimized.ll`,
where `@strFromFloatHelp` aliases `@main.strFromFloatHelp`, a multi-block
float-format helper. The reduced prologue slice covers the selected double
bitcast, exponent extraction, special-value branch, and `ret void`/`unreachable`
edge and is now covered by `releasesmall_runtime_str_from_float_help`. The
next selected boundary row is
`test/distribution/releasesmall_x86_64/exclusions/standalone_mix_o_files_base64_decode_base_64.ll`,
where `@decode_base_64` aliases `@base64.decode_base_64`, a table-driven
multi-block decoder. The reduced decode-step slice covers four selected table
GEP/load pairs, i32 OR combination, `icmp ult i32 %word, 16777216`, and a
runtime exit-code select and is now covered by
`releasesmall_runtime_base64_decode_step`. The next selected slice is the
store step from the same fixture around `%165 = getelementptr [1 x i8], ptr %0,
i64 %.1.i` and `store i32 %161, ptr %165, align 1` and is now covered by
`releasesmall_runtime_base64_store_step`. The next selected slice is the
residual byte emit path around `%190 = and i4 %183, 7`,
`%194 = lshr i12 %192, %193`, `%195 = trunc i12 %194 to i8`, and
`store i8 %195, ptr %191, align 1` and is now covered by
`releasesmall_runtime_base64_residual_byte_step`. The accepted ReleaseSmall
pipeline folds the selected constant residual chain to `store i8 63`, and the
object gate lowers that optimized shape. The padding-tail byte check around
`%207 = getelementptr [1 x i8], ptr %203, i64 %.0301.i`,
`%208 = load i8, ptr %207, align 1`, and
`%.not318.i = icmp eq i8 %208, 61` is now covered by
`releasesmall_runtime_base64_padding_tail_step`. The next selected slice from
the same block is the padding-tail loop walk around `%.0301.i = phi i64`,
`%exitcond348.not.i = icmp eq i64 %.0301.i, %204`, `%209 = add i64 %.0301.i,
1`, and the backedge branch on `%.not318.i`, and is now covered by
`releasesmall_runtime_base64_padding_loop_step`. The next selected slice is
the entry padding length adjustment around `%10 = load i8, ptr %9`,
`%11 = icmp eq i8 %10, 61`, `%12 = sext i1 %11 to i64`,
`%spec.select.i = add i64 %7, %12`, `%14 = load i8, ptr %13`,
`%15 = icmp eq i8 %14, 61`, `%16 = sext i1 %15 to i64`, and
`%spec.select21.i = add i64 %spec.select.i, %16`, and is now covered by
`releasesmall_runtime_base64_padding_length_step`. The next selected slice is
the chunk-loop guard around `%19 = add nuw i64 %.0304.i, 16`,
`%20 = icmp ult i64 %19, %3`, `%21 = add nuw i64 %.0303.i, 15`,
`%22 = icmp ult i64 %21, %.sroa.0.0.ph`, `%23 = select i1 %20, i1 %22,
 i1 0`, and `br i1 %23, label %24, label %.preheader.i`, and is now covered
by `releasesmall_runtime_base64_chunk_guard_step`. The next selected slice is
the source-byte stride around `%50 = getelementptr i8, ptr %25, i64 4`,
`%51 = load i8, ptr %50, align 1`, `%52 = zext i8 %51 to i64`,
`%53 = getelementptr [4 x i8], ptr @__anon_1321, i64 %52`, and
`%54 = load i32, ptr %53, align 4`, and is now covered by
`releasesmall_runtime_base64_source_stride_step`. The next selected slice is
the four-byte source bundle around `%50` through `%72`: four source byte
GEP/load/zext/table-load operations, three `or i32` combines, and
`%.not321.i = icmp ult i32 %72, 16777216`, and is now covered by
`releasesmall_runtime_base64_source_bundle_step`. The next selected slice is
the next four-byte source bundle around `%74` through `%96`: four source byte
GEP/load/zext/table-load operations, three `or i32` combines, and
`%.not322.i = icmp ult i32 %96, 16777216`, and is now covered by
`releasesmall_runtime_base64_next_source_bundle_step`. The next selected slice
is the third four-byte source bundle around `%98` through `%120`: four source
byte GEP/load/zext/table-load operations, three `or i32` combines, and
`%.not323.i = icmp ult i32 %120, 16777216`, and is now covered by
`releasesmall_runtime_base64_third_source_bundle_step`. The next selected
slice is the bit-buffer combine and output store around `%122 = zext nneg i32
%120 to i128`, `%123 = zext nneg i32 %72 to i128`,
`%124 = shl nsw nuw i128 %123, 24`, `%125 = or disjoint i128 %124, %48`,
`%126 = zext nneg i32 %96 to i128`, `%127 = shl nsw nuw i128 %126, 48`,
`%128 = or disjoint i128 %125, %127`, `%129 = shl nsw nuw i128 %122, 72`,
`%130 = or disjoint i128 %128, %129`, and `store i128 %130, ptr %131`, and
is now covered by `releasesmall_runtime_base64_bit_buffer_store_step`. The
next selected slice is the loop advance and backedge around
`%132 = add nuw i64 %.0303.i, 12`,
`%indvars.iv.next.i = add i64 %indvars.iv.i, -16`, and `br label %18`, and
is now covered by `releasesmall_runtime_base64_loop_advance_step`. The next
selected slice is the residual/preheader guard around
`%133 = add nuw i64 %.1305.i, 4`, `%134 = icmp ult i64 %133, %3`,
`%135 = add nuw i64 %.1.i, 3`, `%136 = icmp ult i64 %135, %.sroa.0.0.ph`,
`%137 = select i1 %134, i1 %136, i1 0`,
`%138 = getelementptr [1 x i8], ptr %2, i64 %.1305.i`, and the branch on
`%137`, and is now covered by
`releasesmall_runtime_base64_residual_guard_step`. The next selected slice is
the residual four-byte source/table bundle around `%140 = load i8, ptr %138`,
`%141 = zext i8 %140 to i64`,
`%142 = getelementptr [4 x i8], ptr @__anon_1321, i64 %141`,
`%143 = load i32, ptr %142`, the three following byte/table loads at offsets
1, 2, and 3, `%149 = or i32 %148, %143`, `%155 = or i32 %149, %154`,
`%161 = or i32 %155, %160`, and the validity branch on
`%.not319.i = icmp ult i32 %161, 16777216`, and is now covered by
`releasesmall_runtime_base64_residual_bundle_step`. The next selected slice is
the residual success store/backedge around
`%165 = getelementptr [1 x i8], ptr %0, i64 %.1.i`,
`store i32 %161, ptr %165, align 1`,
`%indvars.iv.next346.i = add i64 %indvars.iv345.i, -4`, and
`br label %.preheader.i`, and is now covered by
`releasesmall_runtime_base64_residual_store_step`. The next selected slice is
the residual remaining-length calculation around
`%163 = sub nuw i64 %3, %.1305.i` and `br label %168`, and is now covered by
`releasesmall_runtime_base64_residual_length_step`. The next selected slice is
the residual byte-loop/table check around `%.2.i` and `%.0302.i` phi values,
`%exitcond.i = icmp eq i64 %.0302.i, %indvars.iv345.i`,
`%170 = getelementptr [1 x i8], ptr %138, i64 %.0302.i`,
`%171 = load i8, ptr %170`, `%172 = zext i8 %171 to i64`,
`%173 = getelementptr [1 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 4096), i64 %172`,
`%174 = load i8, ptr %173`, `%175 = icmp eq i8 %174, -1`, and the branch on
`%175`, and is now covered by
`releasesmall_runtime_base64_residual_table_check_step`. The next selected
slice is the residual accumulator update around the `i16` load/trunc to `i12`,
`%178 = shl i12 %177, 6`, `%179 = zext i8 %174 to i12`,
`%180 = add nuw i12 %178, %179`, `store i12 %180`, the bit-count
`%181 = trunc i8 ... to i4`, `%182 = add nuw i4 %181, 6`, and `store i4
%182`, and is now covered by
`releasesmall_runtime_base64_residual_accumulator_step`. The next selected
slice is the residual loop-index advance around
`%.3.i = phi i64 [ %196, %189 ], [ %.2.i, %176 ]`,
`%188 = add nuw i64 %.0302.i, 1`, and `br label %168`, and is now covered
by `releasesmall_runtime_base64_residual_loop_advance_step`. The next selected
slice is the residual padding check around `%186 = add nuw i64 %.0302.i,
%.1305.i`, `%.not313.i = icmp eq i8 %171, 61`, and the branch on
`%.not313.i`, and is now covered by
`releasesmall_runtime_base64_residual_padding_check_step`. The next selected
slice is the residual final mask/remaining-padding guard around
`%.not316.not361.i = icmp uge i64 %.0302.i22, %163`, `%198 = trunc i16 ...
to i12`, `%.mask314.i = and i8 ... , 7`, `%199 = zext nneg i8 %.mask314.i
to i12`, `%notmask.i = shl nsw i12 -1, %199`, `%200 = xor i12 %notmask.i,
-1`, `%201 = and i12 %198, %200`, `%.not315.i = icmp ne i12 %201, 0`,
`%brmerge.i = or i1 %.not316.not361.i, %.not315.i`, and the branch on
`%brmerge.i`, and is now covered by
`releasesmall_runtime_base64_residual_final_mask_step`. The next selected
slice is the residual final padding loop around
`%203 = getelementptr [1 x i8], ptr %2, i64 %.sroa.0285.0.i`,
`%204 = sub nuw i64 %3, %.sroa.0285.0.i`,
`%exitcond348.not.i = icmp eq i64 %.0301.i, %204`,
`%207 = getelementptr [1 x i8], ptr %203, i64 %.0301.i`,
`%208 = load i8, ptr %207`, `%.not318.i = icmp eq i8 %208, 61`,
`%209 = add i64 %.0301.i, 1`, and the branch on `%.not318.i`, and is now
covered by `releasesmall_runtime_base64_residual_padding_loop_step`. The next
selected slice is the decode exit/lifetime cleanup around
`base64.Base64Decoder.decode.exit`, the two `llvm.lifetime.end.p0` calls, and
`ret i64 %.sroa.0.0.ph`, and is now covered by
`releasesmall_runtime_base64_decode_exit_step`. The selected Debug executable,
Debug unwind/DWARF boundary, Debug native-link gate, and Debug native-link
probe completed cleanly; the broad Debug native-link probe is clean with
`total=10 accepted=6 accounted=4 local_fail=0 excluded=0`. The combined
native-link boundary2 gate is clean across ReleaseFast, ReleaseSafe,
ReleaseSmall, and Debug with `local_fail=0` for every mode. The top-level
distribution gate then exposed the integrated postopt
`releasefast_runtime_volatile_roundtrip` local object gap; that row now
passes. The integrated `releasefast_runtime_aggregate_pair` row now passes
with the expected source-level exit code 1, and
`releasesmall_runtime_hidden_access` now passes with the expected source-level
exit code 7. `releasesmall_runtime_mix_c_add_zig` now passes with the
expected source-level exit code 7, and
`releasesmall_runtime_mix_c_add_may_panic` now passes with the expected
source-level exit code 5. `releasesmall_runtime_inherit_want_safety_i64` now
passes with the expected source-level exit code 4. The selected integrated
postopt object gate is clean with
`total=146 executable_ok=146 link_only_ok=0 local_fail=0`. The top-level
distribution gate then exposed the next selected blocker:
integrated preopt `releasefast_runtime_pointer_load_store` object emission
failure with `UnsupportedCodegenControlFlow`; that row now passes. The next
selected blocker is integrated preopt
`releasefast_runtime_volatile_roundtrip`, which failed object emission with
`UnsupportedCodegenCallingConvention`; that row now passes through the
preopt path. The next selected blocker is integrated preopt
`releasefast_runtime_optional_pointer`, which failed object emission with
`UnsupportedCodegenControlFlow`; that row now passes through the preopt
path. The next selected blocker is integrated preopt
`releasefast_runtime_packed_read_flag`, which failed object emission with
`UnsupportedCodegenCallingConvention`; that row now passes through the
preopt path. The next selected blocker is integrated preopt
`releasefast_runtime_packed_replace_low`, which failed object emission with
`UnsupportedCodegenCallingConvention`; that row now passes through the
preopt path. The next selected blocker is integrated preopt
`releasefast_runtime_struct_sum`, which failed object emission with
`UnsupportedCodegenCallingConvention`; that row now passes through the
preopt path with selected wrapper/helper lowering. The private aggregate
global data relocation exposed while implementing the wrapper remains out of
scope for that slice. The next selected blocker is integrated preopt
`releasefast_runtime_array_sum`, which failed object emission with
`UnsupportedCodegenCallingConvention`; that row now passes through the
preopt path. The next selected blocker is integrated preopt
`releasefast_runtime_optional_payload`, which failed object emission with
`UnsupportedCodegenCallingConvention`; that row now passes through the
preopt path. The next selected blocker is integrated preopt
`releasefast_runtime_error_union_payload`, which failed object emission with
`UnsupportedCodegenCallingConvention`; that row now passes through the
preopt path. The next selected blocker is integrated preopt
`releasefast_runtime_slice_sum`, which failed object emission with
`UnsupportedCodegenCallingConvention`; that row now passes through the
preopt path with selected wrapper/helper lowering. The next selected blocker
is integrated preopt `releasefast_runtime_aggregate_pair`, which failed object
emission with `UnsupportedCodegenType`; that row now passes through the
preopt path with selected wrapper/helper lowering. The next selected blocker
is integrated preopt `releasefast_runtime_float_less`, which fails object
emission with `UnsupportedCodegenCallingConvention`; that row now passes
through the preopt path with selected wrapper lowering. The next selected
blocker is integrated preopt `releasefast_runtime_float_mul`, which fails
object emission with `UnsupportedCodegenCallingConvention`; that row now
passes through the preopt path with selected wrapper lowering. The next
selected blocker is integrated preopt `releasefast_runtime_float_add`, which
fails object emission with `UnsupportedCodegenCallingConvention`; that row now
passes through the preopt path with selected wrapper lowering. The next
selected blocker is integrated preopt `releasefast_runtime_float_select`,
which fails object emission with `UnsupportedCodegenCallingConvention`; that
row now passes through the preopt path with selected wrapper lowering. The
next selected blocker is integrated preopt `releasefast_runtime_float_sub`,
which fails object emission with `UnsupportedCodegenCallingConvention`; that
row now passes through the preopt path with selected wrapper lowering and is
closed by the shared selected float preopt helper. The next selected blocker
is integrated preopt `releasefast_runtime_double_div`,
which fails object emission with `UnsupportedCodegenCallingConvention`; that
row now passes through the preopt path with selected wrapper lowering and is
closed by the shared selected float preopt helper. The next selected blocker
is integrated preopt `releasefast_runtime_float_rem`, which fails object
emission with `UnsupportedCodegenCallingConvention`; that row now passes
through the preopt path with selected wrapper lowering and is closed by the
shared selected float preopt helper. The broad integrated preopt gate then
exposed `releasesafe_runtime_pointer_load_store`,
`releasesafe_runtime_side_effect_free`,
`releasesmall_runtime_hidden_access`,
`releasesmall_runtime_mix_c_add_zig`, and
`releasesmall_runtime_mix_c_add_may_panic` as follow-on selected blockers;
those rows now pass, and the measured integrated preopt gate has no remaining
blocker.

Completed float-sub mapping:
`runtime_float_sub_main.main` calls the selected `fastcc` helper with
`float 5.000000e+00` and `float 2.000000e+00`, compares the result with
`float 3.000000e+00`, selects `i32 0` on equality and `i32 1` otherwise,
and returns the source-level executable result. The private helper remains
covered by the selected `fsub float` lowering.

Completed double-div mapping:
`runtime_double_div_main.main` calls the selected `fastcc` helper with
`double 6.000000e+00` and `double 2.000000e+00`, compares the result with
`double 3.000000e+00`, selects `i32 0` on equality and `i32 1` otherwise,
and returns the source-level executable result. The private helper remains
covered by the selected `fdiv double` lowering.

Completed float-rem mapping:
`runtime_float_rem_main.main` calls the selected `fastcc` helper with
`float 5.500000e+00` and `float 2.000000e+00`, compares the result with
`float 1.500000e+00`, selects `i32 0` on equality and `i32 1` otherwise,
and returns the source-level executable result. The private helper remains
covered by the selected `frem float` lowering.

Known boundary:
No measured blocker remains in `zig build distribution-zig-integrated-preopt`.
Full decoder coverage, arbitrary loops, all table forms, all bit-buffer
behavior, all stores, all padding validation, private aggregate-global data
relocations, and broader object/linker behavior remain out of scope for the
selected rows closed here.

Validation gate:
Run `zig build distribution-zig-integrated-preopt` as the measured integrated
preopt gate. If a new blocker appears after future row additions, promote the
first sorted failure with exact case_id, wrapper, mode, pipeline, and error.

Commit:
Commit the selected integrated preopt FP helper closures and follow-on
ReleaseSmall mix-C closures with the policy in `docs/commit_policy.md`.

## Current Evidence

Latest local validation:

```text
zig build test
zig build readiness
zig build distribution-all
zig build distribution-native-link-object-inspection
zig build distribution-native-link-object-inspection -- --release-source-owned
zig build distribution-native-link
zig build distribution-native-link -- --release-source-owned
zig build probe-native-linker
zig build probe-native-linker -- --release-source-owned
zig build distribution-zig-source-native-link
zig build distribution-zig-integrated-object
zig build distribution-zig-integrated-preopt
zig build distribution-zig-ir-writer-tiny-scalar
zig build distribution-zig-ir-writer
zig build probe-native-linker-broad -- --mode=ReleaseFast
zig build probe-native-linker-broad -- --mode=ReleaseSafe
zig build probe-native-linker-broad -- --mode=ReleaseSmall
zig build probe-native-linker-broad -- --mode=Debug
zig build distribution-native-link-boundary2
zig build distribution-debug-executable
zig build distribution-debug-unwind
zig build distribution-native-link-debug
zig build probe-native-linker-debug
zig build probe-native-linker-broad -- --mode=Debug
zig build distribution-native-link-boundary2
```

The focused gates passed after the script runner cleanup, shared tool helper
refactor, selected native-linker proof expansion, native-linker object
inspection, native-linker compatibility probe addition, exact broad-probe
category split, ReleaseSmall base64 table
lookup reduction, and the experimental patched-Zig object-emission hook. The
Zig source integration gate passes: 10 source rows go from stage4 Zig-emitted
LLVM IR through local `z_llvm` object emission and Zig native linking, with 9
executable proofs and 1 ReleaseSafe link-only panic-runtime boundary. The Zig
integrated object-emission gate uses paired C ABI wrapper objects and a patched
`../ziglang` hook so the selected rows go through Zig's `build-obj` object
boundary before `z_llvm --emit=obj` and `zig build-exe -fno-lld`. The
integrated preopt gate also passes for the same 10 rows: patched Zig writes
pre-optimization IR before LLVM's `module_pm.run(...)`, `z_llvm` runs the
accepted Zig-mode pipeline and emits the object, and Zig native linking
finishes the selected wrappers. The external z_llvm IR writer gate now
also passes: the first ReleaseFast tiny-scalar row and the full 146-row
integrated set go through `ZIG_USE_ZLLVM_IR_WRITER=1` with
`ZLLVM_IR_WRITER_MODE=external`, `z_llvm --emit=ir-writer`, the accepted
`z_llvm` preopt pipeline, local object emission, and Zig native linking. The
writer now has 146 runtime-surface selected rows and 0 minimal-wrapper hook
proofs. Its construction ownership is measured per row: all 146 rows are built
through `src/structured_ir_builder.zig` into z_llvm-owned internal IR modules.
Runtime surfaces cover tiny scalar add,
integer arithmetic,
error-switch-style compare/select, direct call, global load, i64 arithmetic,
ReleaseSmall i64 call-return, table indexed load, and the ReleaseSafe checked-add panic-runtime
boundary, plus ReleaseFast runtime conditional branch, phi/merge, loop, and
dense-switch rows, plus the mutable global update, ABI-argument direct-call,
selected pointer load/store row, local-exec TLS read/update rows, the selected
volatile roundtrip row, local-exec TLS read/update rows, the selected atomic
add row, optional pointer row, and the selected inline-asm memory barrier row,
plus the selected packed read-flag row, selected packed replace-low row,
selected aggregate pair ABI row, selected struct field-sum row, selected
scalarized array-sum row, selected optional scalar payload row, selected
error-union payload row, selected pointer-indexed slice-sum row,
selected ordered `f32` less-than row, selected `f64` multiply row, selected
`f32` add row, selected `f64` select row, selected `f32` subtract row, and
selected `f64` divide row, selected `f32` remainder row, and selected f32/f64
literal-return row, selected comptime constant multiply row, and selected
add-immediate return row, plus the selected ReleaseSafe checked add-immediate,
checked comptime-const, checked global-update, and checked pointer-load/store
panic-edge rows, plus the selected checked branch-mix and checked call-chain
rows, selected checked TLS bump row, selected checked array-sum row, and
selected checked struct-sum row, selected checked slice-sum row, and selected
checked loop-sum row, plus the selected ReleaseSafe read-global row. Broad
native-link probes are link-only evidence: every current ReleaseFast,
ReleaseSafe, ReleaseSmall, and Debug row is accepted, accounted for by an exact
Zig runtime/TLS/compiler-rt category, or explicitly excluded as a documented
boundary. No broad probe currently reports an unclassified local object/link
failure.

Current distribution evidence is recorded in
[x86_64_distribution_object_dashboard.md](roadmap/x86_64_distribution_object_dashboard.md)
and
[x86_64_distribution_replacement_matrix.md](roadmap/x86_64_distribution_replacement_matrix.md).
The selected native-link distribution slice is recorded in
[x86_64_native_link_distribution_slice.md](roadmap/x86_64_native_link_distribution_slice.md):
the captured release-mode claim is recorded in
[x86_64_captured_release_native_link_claim.md](roadmap/x86_64_captured_release_native_link_claim.md).
The Zig source integration slice is recorded in
[x86_64_zig_source_native_link_slice.md](roadmap/x86_64_zig_source_native_link_slice.md).
The experimental patched-Zig object-emission slice is recorded in
[x86_64_zig_integrated_object_emit_slice.md](roadmap/x86_64_zig_integrated_object_emit_slice.md).
The structured-builder construction milestone is recorded in
[x86_64_structured_ir_builder_milestone.md](roadmap/x86_64_structured_ir_builder_milestone.md).

```text
ReleaseFast  x86_64 asm/object: conservative boundary, 17/17 captured rows object-clean
ReleaseSafe  x86_64 asm/object: conservative boundary, 17/17 captured rows object-clean
ReleaseSmall x86_64 asm/object: conservative boundary, 465/465 captured rows object-clean,
             0 explicit exclusions
Debug        x86_64 asm/object: conservative boundary, adjusted continuous 463-row subset
             object-clean, 2 explicit exclusions
musl         selected x86_64 object/executable subset gates pass
linking      final executable/library/archive/linker-script ownership remains Zig-owned
native link  45 selected ABI-stable objects link and run through
             `zig build-exe -fno-lld`; probe accepted=45 failed=0
             per-mode: ReleaseFast 27/27, ReleaseSafe 9/9,
             ReleaseSmall 8/8, Debug 1/1
source link  Zig source -> stage4 LLVM IR -> z_llvm object -> Zig native link:
             total=10 executable_ok=9 link_only_ok=1 local_fail=0
             ReleaseFast executable=5, ReleaseSafe executable=1 plus
             1 panic-runtime link-only boundary, ReleaseSmall executable=3
integrated   patched Zig build-obj -> optimized IR -> z_llvm object
             -> Zig native link:
             total=10 executable_ok=9 link_only_ok=1 local_fail=0
             each wrapper records covered_fixture, mode, and proof
preopt       patched Zig build-obj -> preopt IR -> z_llvm accepted pipeline
             -> z_llvm object -> Zig native link:
             total=10 executable_ok=9 link_only_ok=1 local_fail=0
             ReleaseFast narrow gate also passes with --mode=ReleaseFast
ir writer    patched Zig build-obj -> external z_llvm IR writer subset
             -> z_llvm accepted pipeline -> z_llvm object -> Zig native link:
             tiny-scalar total=1 executable_ok=1 local_fail=0,
             scalar_runtime_rows=1 minimal_wrapper_rows=0
             full set total=146 executable_ok=146 link_only_ok=0 local_fail=0
             scalar_runtime_rows=146 structured_direct_rows=146
             structured_textual_rows=0 textual_boundary_rows=0
             generic_codegen_rows=146 case_specific_codegen_rows=0
             minimal_wrapper_rows=0
             ownership=structured-direct:146; structured-textual:0;
                       textual-boundary:0
             ownership=llvm-module=not-used; llvm-optimizer=not-used;
                       llvm-targetmachine=not-used; object-emission=z_llvm;
                       linker=zig-native-fno-lld
             surface-counts scalar-add-ret=2 integer-arithmetic=3
             error-switch-select=4 direct-call=1 global-load=3
             i64-arithmetic=1 i64-call-return=1 table-indexed-load=2
             checked-add-runtime-boundary=2 runtime-condbr=2
             runtime-phi-merge=1 runtime-loop-sum=2 runtime-switch=2
             checked-loop-sum-boundary=1
             global-update=2 pointer-load-store=2 volatile-roundtrip=1
             optional-pointer=2 packed-read-flag=2 abi-arg-call=2
             packed-replace-low=2 tls-read=4 tls-bump=2 atomic-add=2
             inline-asm-barrier=2 aggregate-pair-abi=2
             float-less=2 float-mul=1 float-add=2 float-select=1
             float-sub=2 double-div=1 float-rem=1 struct-field-sum=2
             array-scalar-sum=2 optional-scalar-payload=2
             error-union-payload=2
             slice-loop-sum=2 fp-literal-return=2
             comptime-const-mul=2
             void-noop-call=1
             hidden-global-access=2
             mixed-c-zig-add=2
             mixed-c-zig-panic-add=2
             umul-fix-sat-i64=2
             inherit-i64-return=2
             compile-asm-unreachable=2
             str-from-float-help=1
             base64-decode-base64-full=1
             base64-decode-step=1
             base64-store-step=1
             base64-residual-byte-step=1
             base64-padding-tail-step=1
             base64-padding-loop-step=1
             base64-padding-length-step=1
             base64-chunk-guard-step=1
             base64-source-stride-step=1
             base64-source-bundle-step=1
             base64-next-source-bundle-step=1
             base64-third-source-bundle-step=1
             base64-bit-buffer-store-step=1
             base64-loop-advance-step=1
             base64-residual-guard-step=1
             base64-residual-bundle-step=1
             base64-residual-store-step=1
             base64-residual-length-step=1
             base64-residual-table-check-step=1
             base64-residual-accumulator-step=1
             base64-residual-loop-advance-step=1
             base64-residual-padding-check-step=1
             base64-residual-final-mask-step=1
             base64-residual-padding-loop-step=1
             base64-decode-exit-step=1
             add-imm-return=2
             checked-add-imm-boundary=2
             checked-comptime-const-boundary=1
             checked-global-update-boundary=2
             checked-pointer-load-store-boundary=2
             checked-branch-mix-boundary=2
             checked-call-chain-boundary=2
             checked-tls-bump-boundary=2
             checked-array-sum-boundary=2
             checked-struct-sum-boundary=2
             checked-slice-loop-sum-boundary=2
             minimal-ret0=0
broad link   link-only native-link boundary2:
             ReleaseFast total=17 accepted=16 accounted=1 local_fail=0
             ReleaseSafe total=17 accepted=8 accounted=9 local_fail=0
             ReleaseSmall total=465 accepted=273 accounted=192 local_fail=0,
             0 explicit exclusions, accounted_total=465
             Debug total=10 accepted=6 accounted=4 local_fail=0
AArch64      object emission remains an explicit target boundary
```

There is no current measured first failure in the selected x86_64 distribution
subset. The broad native-link boundary2 gate also has no unclassified local
failure; remaining broad rows are Zig-owned runtime/TLS/compiler-rt boundaries,
so they are not active `z_llvm` implementation slices.

## Next Selection Rule

Do not start generic pass parity work from this file. To open the next active
cycle, first produce or identify one measured replacement gap from Zig-backed
evidence, then replace this section with a single implementation slice using
the template below.

Preferred next probes, in order:

1. Refresh only stale x86_64 distribution evidence if a codegen, object,
   handoff, manifest, or fixture change affects it.
2. Expand one named x86_64 distribution subset only when there is a concrete
   source-backed input directory or manifest row beyond the current captured
   boundary.
3. Promote the first parse, verify, optimize, handoff, object, executable ABI,
   relocation, or boundary failure from that probe.
4. For native-linker work, run `zig build probe-native-linker` or
   `zig build distribution-native-link-boundary2` before selecting
   implementation. The first unclassified local failure becomes a local object
   compatibility slice unless evidence proves Zig runtime, TLS, compiler-rt,
   or linker ownership.
5. If no blocker appears, update the dashboard or matrix only when the clean
   evidence changes a row status or named boundary.

Use this template for the next active slice:

```text
Replacement goal:
Zig evidence:
LLVM fallback removed or reduced:
Mode/target/stage row:
Upstream mapping:
Known boundary:
Validation gate:
Commit:
```

Use `unknown` only while selecting a slice. Before implementation is marked
complete, replace every `unknown` with a concrete answer or document why the
slice is preparatory infrastructure only.
# Uncurated Zig AIR Milestone

The frozen `zllvm-air-export-v1` hook now exports compiler-owned functions,
instruction text, types, globals, calls, and liveness from patched Zig. It also
exports a `structured_air-v1` section with reachable AIR body records,
instruction tags, block branch records, conditional-branch records, and repeat
metadata. z_llvm parses that contract and lowers an uncurated x86_64
ReleaseFast subset without case IDs, wrapper maps, source-fact body
classification, or canned DescriptorV2 bodies. Operand and type details still
come from the legacy AIR text stream where the structured contract does not yet
carry a stable typed record.

Current measured gate:

```text
gate=zig build distribution-zig-air-uncurated-releasefast
source_rows=19
discovered_functions=44
structured_functions=44
generic_codegen_functions=44
unsupported_functions=0
codegen_failures=0
case_id_rows=0
source_fact_classification_rows=0
top_unsupported_construct=-
top_unsupported_count=0
local_fail=0
```

This milestone closed the previous `block` control-flow blockers for optional
pointer, optional payload, error-union payload, aggregate ABI helper,
error-switch payload, inline-asm barrier, broad optional/pointer wrapper CFG,
mixed C/Zig panic-edge, packed-bit, TLS wrapper, slice, and FP wrapper rows.
The uncurated gates still print every unsupported function with its
opcode/reason so future expansion cannot silently fall back.
