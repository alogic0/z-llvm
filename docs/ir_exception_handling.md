# Error Handling And LLVM EH IR

This project treats Zig error-union/control-flow lowering and LLVM exception
handling as separate surfaces.

## Zig Error Lowering

Accepted Zig error-like shapes are ordinary scalar and control-flow IR:

```text
integer or pointer values carrying error payload/state
branches over scalar conditions
PHIs at normal CFG joins
calls that return scalar values through normal return paths
```

These forms belong to the parser, verifier, SimplifyCFG, SCCP, DCE, and normal
handoff validation cycles. They do not require LLVM EH pad semantics.

## LLVM EH IR

LLVM exception handling uses distinct CFG and verifier rules:

```text
invoke
landingpad
resume
catchswitch / catchpad / catchret
cleanuppad / cleanupret
personality functions
EH pad dominance and unwind edges
```

The local parser rejects these constructs explicitly. They are not optimizer
inputs until CFG ownership, verifier rules, PHI semantics, and pass legality are
designed for EH edges.

## Current Rejection Coverage

```text
unit test: invoke returns UnsupportedCallTerminator
unit test: landingpad returns UnsupportedExceptionHandling
unit test: resume returns UnsupportedExceptionHandling
unit test: catchswitch returns UnsupportedExceptionHandling
unit test: cleanupret returns UnsupportedExceptionHandling
unit test: catchpad returns UnsupportedExceptionHandling
unit test: cleanuppad returns UnsupportedExceptionHandling
unit test: personality function attributes return UnsupportedExceptionHandling
```

Current source-backed classification:

```text
accepted Zig error-union shapes lower as ordinary scalar/control-flow IR
current accepted Zig corpus rows do not require LLVM EH pad CFG semantics
future rows that contain invoke, landingpad, resume, catch/cleanup pads, or
personality functions must stay unsupported until EH CFG/verifier support exists
```

## Upstream Mapping

LLVM source anchors:

```text
llvm-project-22/llvm/include/llvm/IR/Instructions.h
llvm-project-22/llvm/lib/IR/Verifier.cpp
llvm-project-22/llvm/lib/Transforms/Utils/Local.cpp
```

LLVM optimizers must preserve EH pad structure, unwind destinations,
personality functions, and exceptional control-flow dominance. The local
project deliberately fails closed instead of treating EH as ordinary branches.
