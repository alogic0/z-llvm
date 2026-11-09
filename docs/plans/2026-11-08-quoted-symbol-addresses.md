# Quoted symbol addresses and cumulative policy acceptance

Status: complete and accepted at `a9e9c0f1`, following `b51fc4aa`.
Fresh and cached full runs pass all 17 gates; all 1,501 canonical records match.
Baseline compiler acceptance is `b43dd3dc`,
documented at `4ed60955`: 7,441 of 8,928 compiler definitions and 284 of 455
runtime definitions select, with 17 gates and 61 native populations passing.
The subsequent `1d725945` setting requires 20 GB at admission and an
11,410,065,408-byte execution reserve; this plan completes its full fresh/cache
validation.

At baseline, all 225 readonly-table first failures referred to two quoted private
integer arrays: 213 used `[4 x i64]`, and twelve used `[8 x i64]`. Their final
GEPs already carried byte offsets. The shared address parser rejected quoted
names, and its constant GEP field splitting did not respect quoted commas. Global lookup and alias
closure must use the existing canonical identifier contract. ELF emission
already has a shared decoder that retains escapes until the object boundary.

1. Reuse complete identifier validation and quote-aware field parsing for
   symbolic addresses. Preserve borrowed LLVM spellings through normalization;
   decode names once at the existing MC boundary. Keep width, layout, addend,
   global-property and unresolved-alias admission unchanged.
2. Use canonical names for verifier symbol maps, module global lookup and alias
   closure. Preserve quotes in structured construction, matching textual IR.
   Validate names before canonical-map insertion, and encode AIR's literal symbol
   bytes once at its IR construction boundary. Cover
   equivalent quoted/escaped references, literal backslashes, punctuation,
   checked offsets, runtime indexes, pointer initializers and alias relocations.
   Verify malformed names fail closed, private rewrites preserve input IR, and
   failed selection rolls back.
3. Add an independent native population and exercise direct/release routes in
   Fast/Safe/Small with Debug and ReleaseFast compiler builds. Preserve every
   existing fixture and population.
4. Replay both complete original inputs and compare all function identities.
   Preserve all 7,441 compiler and 284 runtime successes; report actual gains
   and newly exposed failures. Audit complete production event streams.
5. Freeze source and compiler identities. Run units, structural checks,
   readiness and relevant object/link checks, then one fresh and one cached
   full 17-gate run with explicit owned roots. Compare the two runs and all
   preceding execution populations, reviewing executable metadata separately.
   This also validates the user-directed space setting. Existing full results
   cannot establish the new symbol semantics or the changed headroom policy.
6. Publish retained evidence and update accepted status only after all checks.
   Keep compiler build identities distinct if the suite rebuilds default Debug.

Evidence root: `local-state/validations/quoted-symbols-20261108/`. Record exact
Tier-3 commands there before starting them. Use Zig tools. Preserve original
inputs, baseline artifacts and compiler snapshots, current AIR, diagnostic
worktrees and all thirteen scratch files. Retire only verified idle rebuildable
project caches before validation if needed. Create no archives. Selection
counts do not establish whole-compiler object emission or self-hosting.

The new `quoted_symbols` population checks seven functions and 1,024 observations
per executable. The development run passes both routes in all three release
modes. Verifier regression tests reject equivalent duplicate names and mismatched
call signatures; direct/text construction preserves identical name spellings.
AIR conversion separately covers punctuation, literal quotes/backslashes and
direct-call/returned-global identity. All 1,979 development units and 23 structural
checks pass after this adapter correction.
The diagnostic readonly-table negative now uses an unsupported 32-bit pointer
layout because quoted names on the default 64-bit layout are admitted.

Final acceptance selects 7,657 of 8,928 compiler definitions and 284 of 455
runtime definitions, preserving every prior success. All 225 targeted table
failures advance: 216 functions select and nine reach later limitations.
Production replays and complete event audits agree with the census. Each full
run preserves all 61 prior native populations and adds the quoted-symbol
population, totaling 1,955,844 local and 977,922 reference observations.
Units, structural checks, readiness, both input corpora, fixed programs, fault
controls and preservation audits pass. The accepted record seals 1,057 files;
no archives were created. See the [evidence](../evidence/quoted_symbol_addresses.md)
and [receipt](../evidence/quoted_symbol_addresses_acceptance_20261108.json).
