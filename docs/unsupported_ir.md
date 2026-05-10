# Unsupported LLVM IR Constructs

This document tracks LLVM IR syntax and semantics that `z_llvm` does not support yet.

The current parser is intentionally small. It accepts only the LLVM-compatible subset needed by the reproduced algorithms so far:

```text
define iN @name(...)
define void @name(...)
function linkage on definitions: internal, private, external, default
function visibility on definitions: hidden, protected, default
function calling conventions on definitions: ccc, fastcc, coldcc
function header attributes preserved as raw text
parameter attributes preserved as raw text
source_filename module record
target datalayout module record
target triple module record
scalar global definitions with integer or undef initializers
scalar constant global definitions with integer or undef initializers
raw global suffix attributes preserved as text
integer parameters
ptr parameters
named basic blocks
add/sub/mul integer instructions
and/or/xor integer instructions
shl/lshr/ashr integer instructions
udiv/sdiv/urem/srem integer instructions
trunc/zext/sext integer cast instructions
freeze instructions
icmp eq/ne/sgt/sge/slt/sle/ugt/uge/ult/ule integer instructions
select instructions
phi instructions
alloca instructions
load instructions
store instructions
getelementptr instructions
instruction flags: nsw, nuw, exact
load/store align and volatile spelling
narrow atomic load/store spelling as a conservative barrier
ret
ret void
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
bitcast/ptrtoint/inttoptr/fptrunc/fpext/fptoui/fptosi/uitofp/sitofp/addrspacecast
switch
landingpad/cleanupret/catchret
atomicrmw/cmpxchg/fence
inline asm
```

## Unsupported Attributes and Metadata

```text
function attributes are preserved but not semantically interpreted
parameter attributes are preserved but not semantically interpreted
global attributes are preserved but not semantically interpreted
fast-math flags
full alignment semantics
full volatile semantics
full atomic ordering semantics
calling conventions beyond parse-preserve support
TBAA
noalias / alias.scope
debug metadata
branch weights / profile metadata
module flags
target datalayout semantics beyond default pointer/integer alignment queries
target triple semantics beyond initial target matrix recognition
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
UnsupportedGlobalVariable
InvalidGlobalVariable
UnsupportedFunctionDeclaration
UnsupportedAttributeGroup
UnsupportedModuleMetadata
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
  ret void
  br
  conditional br
  unreachable

Value subset:
  named SSA values
  integer constants
  undef constants

Module IR subset:
  source_filename
  target datalayout
  target triple
  scalar global and constant definitions with integer/undef initializers
  raw global suffix attributes
  initial target matrix recognition: x86_64-linux-gnu, x86_64-linux-musl, aarch64-linux-gnu, wasm32-wasi
  function linkage on definitions
  function visibility on definitions
  function calling conventions on definitions: ccc, fastcc, coldcc
  raw function header attributes
  raw parameter attributes
  void return type

Scalar IR subset:
  integer casts: trunc, zext, sext
  integer division/remainder spelling: udiv, sdiv, urem, srem
  instruction flags preserved: nsw, nuw, exact
  freeze spelling preserved for scalar integers

InstSimplify subset:
  local scalar simplification helper for InstCombine
  constant integer cast folding
  defined constant division/remainder folding
  shared scalar expression equivalence for GVN and EarlyCSE

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
bitcast and pointer casts
unsafe or poison-sensitive division/remainder simplification
using instruction flags such as nsw/nuw/exact in transforms
aggregate, string, TLS, COMDAT, alias, and declaration globals
semantic global variable use in optimizations
visibility and attributes with semantic effects
calling convention ABI semantics
function declarations
attribute groups
module metadata
full atomic operations and ordering semantics
```

These unlock better comparisons with LLVM `opt` and the next algorithms: richer InstCombine folds, SROA slice splitting, memory-aware LICM, and ABI-aware lowering.

## Unsupported Codegen Constructs

The `--emit=asm` path is intentionally smaller than the IR parser:

```text
only x86_64-linux target triples
only one-block leaf functions
only i32 return values or void returns
only first and second i32 parameters
only return constant, return parameter, and add first two parameters
no branches
no memory operations
no calls
no stack frame
no object emission
```
