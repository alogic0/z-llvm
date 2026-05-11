# Cycle 11: Alias And Memory Precision For Source-Backed Rows

## Goal

Improve alias and memory reasoning only where current or newly captured Zig rows
show missed optimization or over-conservative behavior that matters for the
local release pipeline.

## Source Anchors

- Corpus rows: pointer/memory, globals, TLS, aggregate, and future rows
- Local code: `src/analysis/alias.zig`, `src/analysis/memory_effect.zig`,
      DSE, GVN, EarlyCSE, LICM
- LLVM reference: BasicAA, MemorySSA, MemoryDependence where fixture-relevant

## Plan

- [x] Identify source-backed rows where local alias conservatism blocks a
      fixture-equivalent transform.
- [x] Add reduced opt fixtures for must-alias, no-alias, volatile, atomic, TLS,
      unknown call, and aggregate-pointer cases.
- [x] Extend alias/mod-ref APIs before adding pass-local special cases.
- [x] Wire improvements through DSE, GVN, EarlyCSE, and LICM only after shared
      tests prove the API shape.
- [x] Mark MemorySSA-level behavior as future unless implemented directly.
- [x] Document which LLVM alias results are matched and which remain local-only
      conservative.

## Exit Criteria

- [x] One concrete source-backed memory precision gap is closed.
- [x] Shared alias/memory APIs carry the new reasoning, not duplicated pass code.
- [x] Each changed pass has opt fixtures compared with `opt-22` or documented as
      local-conservative.

## Completed Slice

Cycle 11 closes a source-backed aggregate pointer precision gap: GEPs from a
pointer parameter, such as the `aggregates.struct_sum` lowering shape, now use
the parameter as a conservative `MemoryLocation` root for same-parameter access
ranges. The shared alias/mod-ref API can prove non-overlapping access-sized
ranges are `no_mod_ref`, enabling the local-conservative
`early_cse_param_gep_noalias_forward` fixture without adding pass-local special
cases. `opt-22` keeps that load in the direct EarlyCSE fixture, so this is not
claimed as LLVM-equivalent EarlyCSE behavior. Distinct pointer parameters still
remain `may_alias`; full MemorySSA walking, capture analysis, partial alias
results, and metadata-aware aliasing remain future work.
