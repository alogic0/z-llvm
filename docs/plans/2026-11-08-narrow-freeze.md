# Narrow integer freeze

Status: implementation and validation in progress.
Baseline: `29e034a7`, accepted compiler selection 7,713/8,928 and runtime
selection 284/455. The user explicitly authorized this bounded next slice.

The diagnostic replay of the 94 recorded freeze-width failures finds i1 (24),
i3 (two), i8 (64), i10 (one) and i16 (three). Their existing locations are
EAX (22), a 32-bit scratch register (one) and scalar spill slots (71).

1. Completed: preserve defined i1 through i32 values as aliases of compatible 32-bit
   registers and scalar spill slots. Preserve the existing i64/i128 contract.
   Keep undef/poison, pointer/FP freeze and incompatible carriers explicit.
2. Completed: execute dirty-upper-bit, shared-alias, branch, PHI, spill and call cases;
   check failed-selection rollback and retained rejection diagnostics. Add an
   independent native population compared with LLVM in all three release modes
   through both direct and release routes.
3. Replay the unchanged complete compiler and runtime inputs. Preserve every
   prior selection, classify all 94 transitions and publish actual additions.
4. Freeze the implementation and compiler identities, pass Debug/ReleaseSafe
   units and structural checks, readiness, production event audits and the full
   serial integration gate. Preserve the twelve-function core cohort, ratchet
   130, all previous native populations and all original inputs/scratch files.

Focused validation passes 1,989 units and 23 structural checks in both Debug
and ReleaseSafe. The ten-function native population passes all modes and both
routes with final Debug and ReleaseFast compilers: 15,360 local observations
and 7,680 LLVM references per compiler. The previous binary rejects all ten;
the independent oracle detects a wrong low-bit result. Four historical limb
near-miss snippets now execute through ordinary composed lowering and exclude
the specialized limb pseudo instructions. The source guard retains its frozen
bypass inventory; only the existing alias function's fingerprint changes.

Tier-3 trigger: this changes shared scalar selection and register/spill aliases
and closes a codegen capability. Previous integration results predate this
behavior. Reuse the authenticated quoted-symbols AIR generation; the producer
and cache infrastructure are unchanged, so no fresh/cache pair is required.
Record the exact command before admission in the evidence root:
`local-state/validations/narrow-freeze-20261108/`.

Upstream semantics: LLVM LangRef's freeze instruction returns a defined input
unchanged; `SelectionDAGBuilder::visitFreeze` preserves its value types. The
pinned Zig-produced module supplies the observed widths. This slice does not
choose arbitrary values for undef/poison. See local LLVM 22 `LangRef.rst` and
`SelectionDAGBuilder.cpp`, and retain their hashes with the final evidence.
