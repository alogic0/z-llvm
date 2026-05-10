# Unsupported LLVM IR Constructs

This document tracks LLVM IR syntax and semantics that `z_llvm` does not support yet.

The current parser is intentionally small. It accepts only the LLVM-compatible subset needed by the reproduced algorithms so far:

```text
define iN @name(...)
integer parameters
ptr parameters
named basic blocks
add/sub/mul integer instructions
and/or/xor integer instructions
shl/lshr/ashr integer instructions
icmp eq/ne/sgt/sge/slt/sle/ugt/uge/ult/ule integer instructions
select instructions
phi instructions
alloca instructions
load instructions
store instructions
getelementptr instructions
ret
br label %target
br i1 <value>, label %then, label %else
unreachable
integer constants
i1 true/false constants, normalized to 1/0 internally
undef constants
named SSA values
```

## Unsupported Types

```text
void
float/double/fp80/fp128
arrays
vectors
structs
packed structs
function pointer types
token/metadata types
```

## Unsupported Instructions

```text
fcmp
phi token/blockaddress values
call/invoke/callbr
cast instructions
division/remainder
switch
landingpad/cleanupret/catchret
atomicrmw/cmpxchg/fence
inline asm
```

## Unsupported Attributes and Metadata

```text
function attributes
parameter attributes
instruction flags: nsw, nuw, exact, fast-math flags
alignment
volatile
atomic ordering
TBAA
noalias / alias.scope
debug metadata
branch weights / profile metadata
module flags
target datalayout
target triple
```

## Current Parser Errors

The parser reports coarse errors today. Important ones:

```text
EmptyModule
NestedFunction
UnclosedFunction
UnexpectedFunctionEnd
LineOutsideFunction
FunctionWithoutBlocks
BlockWithoutTerminator
DuplicateBlock
DuplicateDefinition
UnknownValue
UnknownBlock
TypeMismatch
ReturnTypeMismatch
BranchConditionTypeMismatch
UnsupportedType
UnsupportedInstruction
InvalidFunctionHeader
InvalidFunctionName
InvalidParameter
InvalidValueName
InvalidInstruction
InvalidRet
InvalidBr
InvalidLabel
```

## Reproduced LLVM Functionality So Far

```text
InstCombine subset:
  identity arithmetic and integer constant folding for add/sub/mul
  bitwise and shift identity folding
  relational icmp constant and same-operand folding
  commutative binary constant canonicalization

DCE subset:
  unused pure instruction removal using def-use counts

ADCE subset:
  unused side-effect-free instruction chain removal

SimplifyCFG subset:
  constant conditional branch folding
  same-target conditional branch folding
  unreachable block removal
  phi-free empty branch block threading

Def-use subset:
  per-function use counts for named SSA values, including load/store operands

Memory IR subset:
  opaque ptr type
  alloca/load/store/getelementptr parsing, printing, and verification
  load/store align and volatile spelling
  narrow atomic load/store spelling as a conservative barrier

Memory legality subset:
  shared memory-effect classification for pure, readonly load, write, and volatile/atomic barrier instructions
  conservative alias/mod-ref scaffolding for known stack slots and load/store instructions

Control-flow IR subset:
  ret
  br
  conditional br
  unreachable

Value subset:
  named SSA values
  integer constants
  undef constants

Select subset:
  scalar i1 condition
  matching scalar result arms

SROA subset:
  zero-offset GEP alloca forwarding before stack promotion

GVN subset:
  dominating repeated pure-expression elimination
  memory instructions rejected from scalar value numbering

LoopInfo subset:
  natural-loop discovery from dominator backedges
  unique preheader query
  loop exiting block query
  loop exit block query

LICM subset:
  pure loop-invariant instruction hoisting to an existing preheader
  memory-effect API blocks load/store/volatile/atomic hoisting
  no memory LICM, store sinking, preheader creation, or MemorySSA promotion yet
```

## Next Unsupported Areas To Remove

The next useful parser expansions are:

```text
call
cast instructions
division/remainder
instruction flags such as nsw/nuw
target triple and datalayout records
full atomic operations and ordering semantics
```

These unlock better comparisons with LLVM `opt` and the next algorithms: richer InstCombine folds, SROA slice splitting, memory-aware LICM, and ABI-aware lowering.
