# Fibonacci completion and compiler contracts

Status: active, authorized after the earlier request to stop. The accepted
compiler remains `9a8cc1c9` until a new checkpoint passes full integration.

Steps 1–5 have focused validation: the unchanged pinned program executes all
six assertions in Fast, Safe and Small, and all 1,568 Safe definitions emit.
See the [implementation and evidence](../evidence/fibonacci_completion.md).
Step 6, full integration acceptance, is next. Step 7 remains the subsequent
execution-breadth milestone.

The starting unchanged ReleaseSafe input contains 1,568 definitions. The accepted
compiler emits 1,522 and rejects 46; Fast and Small execute all six assertions.
The retained input is
`local-state/validations/fibonacci-20261104/narrow-safe-frontier/capture/object-input.ll`
(SHA-256 `147ebba2de9f96cae9e6ce53fedd53b6fa082bc46048e51433652e5887a4f60c`).

1. Classify and close the remaining shared semantic families: inline assembly,
   vectors, i65/i96 arithmetic and ABI boundaries, and CFG/value transfers. Keep
   unsupported forms fail-closed. Preserve the upstream source and captured IR.
2. Put mandatory semantic normalization before instruction selection, check its
   output invariants, and test repeatability and preservation of source IR.
   Keep optional instruction-form legalization separate.
3. Make fixed-register effects explicit for new machine operations. Add executable
   combinations of widths, aliases, PHIs, calls and pressure alongside each repair.
4. Make explicit optimization options apply consistently to ordinary object and
   assembly emission, with a shared compilation entry point and route tests.
5. Execute the unchanged pinned Fibonacci program in Fast, Safe and Small through
   a permanent regression. Require LLVM-equivalent status, stdout and stderr.
6. Run all integration gates on the completed source checkpoint. Report emission
   and execution separately, and keep historical performance measurements separate.
7. Add substantially different unchanged programs and more callable compiler-core
   functions as the next execution milestone.

Use the existing start threshold and runtime disk reserve. Keep diagnostics and
small provenance records; do not create archives or remove original scratch files.
The older i65/i96 worktree is diagnostic material, not accepted implementation.
