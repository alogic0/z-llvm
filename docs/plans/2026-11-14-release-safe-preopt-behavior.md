# ReleaseSafe behavior through the local preopt pipeline

Date: 2026-11-14
Status: proposed successor to the compiler-throughput slice; not implemented.

## Objective

Run the unchanged pinned upstream Zig behavior suite in ReleaseSafe through
the existing local preopt optimizer and local object emitter. Match every named
reference outcome, including reference skips, and independently audit every
delivered compiler-runtime/test object. Establish this complete workload without
executing LLVM's optimization or object-emission passes on the accepted route.

Keep the accepted postopt compiler/self-rebuild proof and fixed populations
unchanged. LLVM IR construction, bitcode parsing, target/analysis setup and
declared providers remain dependencies. This milestone does not remove libLLVM
or establish arbitrary LLVM optimizer parity.

## Observed starting point

The pinned frontend already has a preopt object hook. In ziglang/src/zig_llvm.cpp,
zigLLVMResolveZllvmHook accepts preopt for ReleaseFast, ReleaseSafe and ReleaseSmall,
mapping ReleaseSafe to zig-release-safe-accepted. Debug is explicitly unsupported.
The preopt branch in ZigLLVMTargetMachineEmitToFile prints the module before
module_pm.run, then invokes z_llvm optimization and object emission separately.
LLVM target/analysis objects are still constructed earlier in that function.

The existing preopt child commands have a fixed 64 MiB input limit. The accepted
Debug postopt behavior input alone is 67,658,559 bytes, so complete new inputs
need measured, explicit admission rather than assuming those helper defaults fit.
The current run_upstream_behavior runner fixes local captures to postopt; its
capture proxy and object auditor cannot count optimizer text output as an object.

## Delivery

1. Freeze the same upstream source pin, frontend binary, target x86_64 Linux GNU,
   CPU baseline and unchanged behavior.zig input. Choose one accepted compiler
   generation and retain its normal LLVM ReleaseSafe reference report. Keep its
   exact named pass/skip identities; do not replace the fixed postopt corpora.
2. Add an explicit local pipeline selection to the maintained behavior runner,
   with postopt as the unchanged default. Reject preopt with the LLVM route or
   unsupported modes. Retain both optimizer and object commands, inputs, outputs,
   hashes, actual statuses and stage-specific diagnostics in separate captures.
3. Capture the complete preopt behavior and runtime modules before repairing
   anything. Record their own hashes, byte sizes, definitions, declarations,
   aliases and globals. Use bounded byte limits derived from verified retained
   files. Keep the public CLI default and existing ABI/frame limits unchanged.
4. Diagnose failures in the shared parser, verifier, optimizer or selector that
   owns them. For each adopted repair, retain a minimal real-input reproduction,
   an independent LLVM/native comparison and adjacent rejection/negative controls.
   Keep LLVM verification as a validation reference, separate from the accepted
   compilation route. Do not stub, omit, substitute or silently fall back.
5. Complete the unchanged ReleaseSafe suite through preopt. Require all named
   outcomes to match the reference, complete optimizer inputs/outputs to verify,
   and every delivered local object to pass census, ownership, ELF and ordered
   event audits. Explicitly account for runtime modules as separate populations.
6. Prove route ownership with retained commands and a negative control that
   forces the local optimizer to fail before object delivery. Require a failed
   compile and no successful object/fallback credit. Bind any frontend ownership
   instrumentation to a separate source/build identity, preserving the pinned
   reference checkout and binary.
7. Apply docs/validation_tiers.md. Run required focused checks for each changed
   subsystem and cumulative Tier 3 before acceptance. Preserve prior native
   command outcomes/artifacts, fixed original objects and postopt behavior.
   Publish the new source/input identities and exact remaining LLVM dependencies.

## Acceptance and stop boundary

- One complete ReleaseSafe behavior result, with all 2,097 named reference
  outcomes compared if the unchanged reference retains that population.
- Every optimizer and object invocation completes with actual exit zero; all
  newly captured modules have their own complete inventories and object audits.
- No LLVM optimizer/object pass execution or fallback delivery in the accepted
  preopt route; IR construction and provider dependencies stay explicit.
- Required preservation checks, negative controls and cumulative integration pass.

Stop after this single-mode acceptance. Other modes, complete compiler preopt
build/self-rebuild, LLVM IR-builder replacement and provider-library removal are
separate milestones. Update the active handoff from measured results before
selecting the next one.
