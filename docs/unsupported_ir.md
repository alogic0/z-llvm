# Unsupported LLVM IR Constructs

This document tracks LLVM IR syntax and semantics that `z_llvm` does not support yet.

The current parser is intentionally small. It accepts only the LLVM-compatible subset needed by the reproduced algorithms so far:

```text
define iN @name(...)
integer parameters
named basic blocks
add/sub/mul integer instructions
icmp eq/ne integer instructions
phi instructions
ret
br label %target
br i1 <value>, label %then, label %else
integer constants
named SSA values
```

## Unsupported Types

```text
void
float/double/fp80/fp128
pointers
opaque pointers
arrays
vectors
structs
packed structs
function pointer types
token/metadata types
```

## Unsupported Instructions

```text
icmp predicates except eq/ne
fcmp
phi token/blockaddress values
select
alloca
load/store
getelementptr
call/invoke/callbr
cast instructions
division/remainder
bitwise operations
shifts
switch
unreachable
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

DCE subset:
  unused pure add/sub/mul removal using def-use counts

SimplifyCFG subset:
  constant conditional branch folding
  same-target conditional branch folding
  unreachable block removal

Def-use subset:
  per-function use counts for named SSA values
```

## Next Unsupported Areas To Remove

The next useful parser expansions are:

```text
icmp predicates beyond eq/ne
phi
unreachable terminator
alloca/load/store
call
instruction flags such as nsw/nuw
target triple and datalayout records
```

These unlock better comparisons with LLVM `opt` and the next algorithms: `early-cse`, `mem2reg`, dominator tree construction, and LICM.
