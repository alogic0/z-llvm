# LLVM-Compatible IR Verifier Foundation

This document records the first verifier milestone for the local
LLVM-compatible IR layer. The verifier is the required semantic gate before
optimizer passes consume a module.

## Compiler Policy

`z_llvm` itself is built and tested with the `zig` executable on `PATH`.
Authoritative Zig-emitted LLVM IR fixtures must come from
`../ziglang/build/stage4/bin/zig`, and fixture refreshes must record both the
stage4 Zig version and the matching `../ziglang` source revision. Do not use
stage3 output for authoritative verifier fixtures unless the fixture is
explicitly about bootstrap behavior.

## Upstream Mapping

LLVM source files:

```text
llvm-project-22/llvm/lib/IR/Verifier.cpp
llvm-project-22/llvm/include/llvm/IR/Verifier.h
llvm-project-22/llvm/include/llvm/IR/Instructions.h
llvm-project-22/llvm/include/llvm/IR/CallingConv.h
llvm-project-22/llvm/include/llvm/IR/DataLayout.h
```

LLVM entry points and concepts:

```text
llvm::verifyModule
llvm::verifyFunction
llvm::VerifierPass
llvm::VerifierAnalysis
Verifier::visitFunction
Verifier::visitBasicBlock
Verifier::visitPHINode
Verifier::visitTerminator
Verifier::visitCallBase
```

Local implementation:

```text
src/ir/verifier.zig
src/ir/core.zig
src/target/triple.zig
src/target/datalayout.zig
```

## Implemented Milestone

The first milestone implements an LLVM-shaped verifier subset for the IR this
project currently parses:

- module-level duplicate global, declaration, and function definition checks;
- target triple and DataLayout syntax validation hooks;
- function non-empty body checks;
- duplicate block-label rejection;
- entry block predecessor rejection;
- branch target validation and predecessor/successor matrix construction;
- reachability and dominance matrix construction for local SSA checks;
- every block has a terminator;
- PHI nodes must appear before non-PHI instructions;
- PHI incoming blocks must exactly match CFG predecessors;
- PHI incoming values must match result type and be valid on the predecessor
  edge;
- named values must exist, match the expected type, and dominate ordinary uses;
- same-block uses must occur after the defining instruction;
- scalar binary, cast, freeze, icmp, select, alloca, load, store, GEP, call, and
  return type checks;
- direct calls must resolve to a declaration or definition with matching return
  type, argument types, and calling convention;
- memory alignment must be nonzero and power-of-two;
- atomic ordering strings must be from the local known LLVM ordering set.

The verifier uses local matrices instead of LLVM's `DominatorTree` analysis.
That is a deliberate foundation choice: the accepted IR is small enough that the
verifier can compute simple CFG facts directly, while later optimizer epics can
replace or share those facts through analysis managers.

## Fixture Coverage

Unit-test coverage:

```text
zig build test
```

Covered accepted cases:

- normalized Zig-emitted tiny scalar LLVM IR verifies;
- matching function declaration and definition;
- direct calls with matching declaration signatures and calling conventions;
- scalar globals, target records, source filename, linkage, visibility, and raw
  header/parameter attributes preserved by parse/print tests.

Covered rejected cases:

- direct call signature mismatch;
- direct call calling-convention mismatch;
- use before definition in the same block;
- value used in a merge block without dominating that use;
- PHI incoming block is not an exact predecessor;
- PHI missing an incoming predecessor;
- duplicate PHI incoming predecessor;
- PHI after a non-PHI instruction;
- branch back to the entry block;
- invalid non-power-of-two memory alignment.

LLVM comparison command for hand-written verifier fixtures:

```sh
opt-22 -passes=verify <fixture.ll> -S -o /tmp/llvm_verify.ll
```

Local command:

```sh
zig build test
```

## Known Gaps

The verifier is not yet a full reproduction of LLVM `Verifier.cpp`.

Known deferred areas:

- aggregate, vector, token, label, metadata, and function-pointer type
  verification;
- attribute group semantics and target feature validation;
- full `DataLayout` semantic checks, including address-space-specific pointer
  layouts and structured GEP offset rules;
- debug metadata, module flag, TBAA, profile, and loop metadata validation;
- intrinsics, inline asm, invokes, landingpads, exceptions, coroutine tokens,
  atomics beyond basic ordering spelling, and volatile operation legality;
- post-dominator and control-dependence checks required by full ADCE-like
  algorithms;
- MemorySSA and complete AliasAnalysis/ModRef validation.

Unsupported cases should stay explicit in `docs/unsupported_ir.md` and in the
Zig-emitted corpus manifest before parser or optimizer work depends on them.
