# Integer intrinsic slice

The current capability slice is complete at `f955509fa34bbdbdf5649db307796cdaa868e9e9`,
tree `07be9fd65123184c60ba7ea05454d497a0b21986`.
The user requested that work stop after this slice; the
[all-8,928 goal](../plans/2026-11-08-complete-compiler-selection.md) is paused.
The accepted whole-compiler count remains **8,664/8,928** at
`bb74a371`. This slice does not supply a complete current compiler census or
production replay. See the [validation record](integer_intrinsic_slice_20261109.json).

Private owned IR expansions add signed saturating addition and subtraction at
8/16/32/64/96 bits, exact `llvm.scmp.i32.i32`, `llvm.ctlz.i128`, and
poison-enabled scalar absolute value at 32/64 bits. They also cover the observed
`llvm.umul.fix.sat.i16` scale-zero form and `llvm.ushl.sat.i64` shift-by-one
form. Original IR, public signatures and native ABI remain unchanged; there are
no new machine opcodes. Wider signed carriers clamp before narrowing, and both
speculative halves of the i128 leading-zero expansion are defined at zero.

Validation at this source passes:

- All 17 serial integration gates and 76 native populations: 2,200,836 local
  observations against 1,100,418 references. The 74 officially accepted
  populations and the preceding frame slice's 75 populations are checked
  separately.
- The new 43-function native population with frozen Debug and ReleaseFast
  compilers: 67,584 local observations against 33,792 references per build.
  Eight valid-IR mutants are detected by both LLVM and local execution, for
  sixteen detections.
- 2,043 unit tests per Debug/ReleaseSafe mode and 24 fresh structural checks
  per mode. Debug units reuse a valid same-source cached result; ReleaseSafe
  units execute freshly. All nine readiness commands, including the required
  ABI differential, and the captured-object check pass.
- All 36 compiler-core selected objects and observation records match the
  accepted checkpoint; linked executable sizes match. Fast/Safe reference
  wrappers grow by 32 or 40 bytes in the isolated run; Small reference sizes
  match. These size and hash changes are recorded separately. Both corpora,
  five fixed programs and all 54 core fault controls pass. Corpus selected
  identities and owners are preserved.

Current-source targeted original-function probes examine nineteen definitions:
eleven select, including eight new successes and three preserved successes;
eight expose later boundaries. Two large-function successes from the preceding
development version remain explicitly versioned evidence. The complete runtime
census retains 285/455 with no lost success. None of these probes advances the
accepted whole-compiler count.

The first full attempt matched all three while-loop execution modes, then
rejected `ValidationToolsChanged` after a concurrent edit in the main worktree.
That attempt is retained without complete-run credit. The complete retry uses an
isolated checkout of `f955509f`, with all 1,816 frozen source files verified.
Fast/Safe binaries are copied unchanged; Debug is rebuilt and exercised in the
isolated checkout. The checked full command and collectors exit zero. Source,
compiler, original input, frontend and thirteen scratch-file hashes verify.
The retained 116-file
report set matches the preceding checkpoint; its helper exits normally and
removes its FIFO. Development evidence and the invalidated attempt are sealed
read-only under
`local-state/validations/compiler-selection-completion-20261108/batch-07/`.
The completed full retry is sealed separately under
`local-state/validations/compiler-selection-completion-20261108/batch-07-isolated/`.
The JSON record identifies both manifests, covering 1,691 artifacts, and their
verified digests.
Authenticated AIR cache payloads and earlier evidence are preserved.
