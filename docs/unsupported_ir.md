# Unsupported LLVM IR Constructs

This document tracks LLVM IR syntax and semantics that `z_llvm` does not support yet.

The finish-oriented unsupported/future status is tracked in
[`roadmap/finish_gap_burndown_table.md`](roadmap/finish_gap_burndown_table.md).
As of Cycle 01, unsupported constructs must be tied to one of four statuses:
active next step, later measured blocker, conservative accepted boundary, or
out of scope.

The current parser is intentionally small. It accepts only the LLVM-compatible subset needed by the reproduced algorithms so far:

```text
define iN @name(...)
define void @name(...)
declare iN @name(...)
declare void @name(...)
function linkage on definitions: internal, private, external, default
function linkage on declarations: internal, private, external, default
function visibility on definitions: hidden, protected, default
function visibility on declarations: hidden, protected, default
function calling conventions on definitions: ccc, fastcc, coldcc
function calling conventions on declarations/calls: ccc, fastcc, coldcc
function header attributes preserved as raw text
function declaration attributes preserved as raw text
parameter attributes preserved as raw text
declaration parameter attributes preserved as raw text
source_filename module record
target datalayout module record
target triple module record
opaque module asm records
opaque named type definitions in the `%name = type { ... }` spelling
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
direct call instructions
instruction flags: nsw, nuw, exact
load/store align and volatile spelling
narrow atomic load/store spelling as a conservative barrier
ret
ret void
br label %target
br i1 <value>, label %then, label %else
unreachable
integer constants
observed decimal `float` and `double` constants, preserved as raw FP literals
i1 true/false constants, normalized to 1/0 internally
undef constants
named SSA values
```

## Unsupported Types

```text
fp80/fp128
floating-point operations beyond scalar `fadd`/`fsub`/`fmul`/`fdiv`/`frem`
FP arithmetic semantics for NaN, infinity, signed zero, and subnormals beyond
literal classification and preservation
fast-math optimization semantics, constrained FP intrinsics, and FP exception
semantics
arrays
scalable vectors and unsupported vector element types
structs
named type completion and named aggregate layout semantics
packed structs
full optional and error-union ABI lowering beyond observed scalar/null-pointer
fixtures
function pointer types
token types
general metadata values outside declaration signatures and preserved debug
intrinsic operands
```

Fixed vectors are accepted only for a narrow parser/verifier surface:

```text
<N x iM>, <N x float>, <N x double>, and <N x ptr> types
vector function signatures and returns
undef, zeroinitializer, named values, and typed vector constants
integer binary instructions with matching vector operand types
FP vector binary instructions remain unsupported until vector FP semantics are
modeled separately
extractelement, insertelement, and shufflevector parser/verifier preservation
```

Vectorizer passes, target-cost decisions, native lowering, scalable vectors,
vector-condition select forms, vector comparisons, and vector optimization
remain unsupported. The only current vector-valued select transform is the
target-independent identical-arm fold for scalar `i1` conditions. Accepted lane
operations are parser/verifier-only except for DCE of unused pure lane ops and
the same-constant-lane extract-after-insert fold documented in
`docs/ir_vectors.md`.

## Finish Burn-Down Corpus Status

The current manifest has four future rows relevant to the finish
definition:

```text
tiny_scalar_debug: future
  Later measured blocker. Reduced Debug metadata rows already define the
  accepted Debug boundary; the broad raw row is activated only by reducing a
  concrete uncovered Debug construct from source-backed output.

tiny_scalar_release_safe: future
  Later measured blocker. Reduced ReleaseSafe safety/runtime-call rows already
  define the accepted safety boundary; the broad raw row is activated only by
  reducing a concrete uncovered safety or runtime-call construct.

tiny_scalar_release_small: future,legacy-bootstrap
  Closed by Cycle 02. This historical unstripped raw row predates the accepted
  stripped tiny_scalar_release_small_captured row and is retained only as future
  evidence, not as an unsupported finish blocker.

vector_future_release_fast: parse,verify,future
  Conservative accepted boundary. Fixed-vector syntax is parsed and verified,
  but vectorizers and target-cost-driven transforms remain out of scope for the
  current finish line. Activate only after vector FP semantics,
  vector-condition legality, scalable-vector policy, TargetTransformInfo-style
  costs, and native vector lowering are selected as implementation
  requirements.
```

## Unsupported Instructions

```text
vector/constrained `fcmp`; scalar `fcmp` predicates parse and verify only
phi token/blockaddress values
indirect call
call attributes beyond the supported calling convention spelling
inline asm lowering and constraint validation
invoke/callbr
bitcast/ptrtoint/inttoptr/fptrunc/fpext/fptoui/fptosi/uitofp/sitofp/addrspacecast
switch
landingpad/resume/cleanupret/catchret/catchswitch/catchpad/cleanuppad and
personality functions
atomic optimization semantics
inline asm
```

## Unsupported Attributes and Metadata

```text
function attributes are mostly preserved textually; only readnone/readonly and
memory(none)/memory(read)/memory(argmem: read) affect local call memory effects
parameter attributes are preserved but not semantically interpreted
global attributes are preserved but not semantically interpreted
fast-math flags on non-FP operations or unsupported FP/vector operations
full alignment semantics
full volatile semantics
full atomic ordering and syncscope semantics beyond parse/verify preservation
atomic ordering interpretation and atomic-specific optimization
calling conventions beyond parse-preserve support
TBAA interpretation beyond opaque `!tbaa` instruction attachment preservation
noalias / alias.scope interpretation beyond opaque instruction attachment
preservation
debug metadata beyond the small verified DI graph subset, opaque `!dbg`
preservation for instructions, simple branches, call sites, loop PHIs,
reduced lexical-block fixtures, and raw `llvm.dbg.value` or
`llvm.dbg.declare` operands
lexical debug scopes beyond opaque `DILexicalBlock` metadata preservation
debug value and debug declare salvage semantics; debug-location-only transforms
may drop `!dbg` locations with removed instructions, but variable-location
intrinsics keep transform pipelines disabled; debug assign intrinsics still
report `UnsupportedDebugIntrinsic`
branch weights / profile metadata beyond opaque branch attachment preservation
panic/runtime lowering beyond declared opaque runtime call preservation in
reduced ReleaseSafe safety fixtures
sanitizer coverage, TSan, UBSan, `llvm.ubsan.*`, and `llvm.trap`
instrumentation calls
module flags
target datalayout semantics beyond default pointer/integer alignment queries
target triple semantics beyond initial target matrix recognition
ABI classification beyond void, scalar integer, pointer, and whole-function scalar signatures
call codegen beyond i32 direct calls with register arguments, external PLT32
relocations, one deterministic spill, and one fixed stack slot feeding the
first call argument
stack-frame codegen beyond one fixed i32 alloca/store/load/return slot or the
bounded stack-memory-to-call handoff shape
AIR-like lowering beyond scalar binary/cast, basic terminator, stack-memory, and canonical-loop functions
AIR-like standalone CLI/text input mode
raw Zig-emitted LLVM IR before normalization
inline asm calls and constraint/memory-clobber semantics
module-level asm target syntax, symbol alias resolution, MC/object lowering,
and codegen semantics beyond opaque parser/printer preservation
exact Zig-emitted scalar instruction flag parity in AIR-like fixtures
target-aware pipeline integration beyond CLI target/datalayout record injection
mode pipeline descriptors are dependency-ordered approximations, not full LLVM pipeline-equivalent implementations
target diagnostics beyond invalid triple/datalayout and unsupported asm target checks
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
InvalidFunctionDeclaration
InvalidCall
UnsupportedIndirectCall
UnsupportedCallAttribute
UnsupportedInstrumentationCall
UnsupportedInlineAsm for non-sideeffect or malformed inline asm
UnsupportedCallTerminator
UnsupportedVarArgs
UnsupportedAttributeGroup
UnsupportedModuleMetadata
ValueDoesNotDominateUse
PhiIncomingNotPredecessor
DuplicatePhiIncoming
MissingPhiIncoming
PhiAfterNonPhi
```

## Reproduced LLVM Functionality So Far

```text
Verifier subset:
  block terminator presence
  branch target existence
  direct call declaration/function reference and signature checks
  load/store attribute validation for the accepted memory spelling
  named SSA type checks
  named SSA dominance checks
  same-block use-before-def rejection
  phi incoming predecessor exactness
  phi incoming value checks on predecessor edges
  phi-before-non-phi ordering

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
  conservative alias/mod-ref scaffolding for known stack slots, globals,
  parameter GEP ranges, partial-overlap ranges, and load/store instructions

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
  scalar ABI classification for void returns, integer returns/parameters, pointer returns/parameters, and whole-function signatures
  AIR-like helper lowering for scalar binary/cast functions, basic terminators, stack memory, and canonical loops
  AIR-like pre/post optimization driver using named pipelines
  zig-scalar-foundation pipeline alias and CLI target/datalayout record injection
  debug-o0, release-o3, release-oz, lto-prelink-o3, and lto-prelink-oz pipeline descriptors with explicit no-op placeholders
  no LLVM bitcode writer/parser, LTO bitcode handoff, ThinLTO summary index,
  combined index, import/export, WPD, CFI, or post-link LTO behavior
  explicit CLI diagnostics for invalid target datalayout and unsupported asm targets
  normalized Zig-emitted scalar function signature fixture
  AIR-like project-lowered and project-optimized fixture pair for tiny scalar signatures
  function linkage on definitions
  function linkage on declarations
  function visibility on definitions
  function visibility on declarations
  function calling conventions on definitions: ccc, fastcc, coldcc
  function calling conventions on declarations/calls: ccc, fastcc, coldcc
  raw function header attributes
  raw function declaration attributes
  raw parameter attributes
  raw declaration parameter attributes
  void return type

Call IR subset:
  direct external declaration and direct internal function callees
  scalar integer/pointer arguments
  scalar integer/pointer/void returns
  parser/printer/verifier coverage for direct calls
  unknown memory-effect classification for optimizer legality

Scalar IR subset:
  integer casts: trunc, zext, sext
  integer division/remainder spelling: udiv, sdiv, urem, srem
  instruction flags preserved: nsw, nuw, exact
  freeze spelling preserved for scalar integers
  freeze of integer constants folded by InstSimplify/InstCombine
  strict fcmp false/true and constant ord/uno orderedness folding for scalar FP
  constants
  fast-math `nsz`/`nnan` scalar folds and `fast`-only FP expression CSE/value
  numbering

InstSimplify subset:
  local scalar simplification helper for InstCombine
  constant integer cast folding
  defined constant division/remainder folding
  safe variable division/remainder identity folding
  freeze-constant folding
  strict fcmp false/true folding
  strict fcmp ord/uno folding only for classified scalar FP constants
  fast-math `fadd nsz x, +0.0` and `fcmp nnan oeq x, x` folding
  shared scalar expression equivalence for GVN and EarlyCSE

SROA subset:
  zero-offset GEP alloca forwarding
  nested zero-offset GEP alloca forwarding
  non-zero aggregate/vector slice rewriting remains unsupported

DSE subset:
  single-block overwritten stack-store removal
  intervening loads, calls, volatile/atomic memory, unknown pointers, and
  may-alias accesses are conservative barriers

Select subset:
  scalar i1 condition
  matching scalar result arms

SROA subset:
  zero-offset GEP alloca forwarding before stack promotion

GVN subset:
  dominating repeated pure-expression elimination
  memory instructions rejected from scalar value numbering
  FP value numbering only under the local `fast` legality boundary

SCCP subset:
  integer and FP constants in the local lattice
  FP constants feed already-legal InstSimplify folds only
  no general APFloat arithmetic lattice

LoopInfo subset:
  natural-loop discovery from dominator backedges
  unique preheader query
  loop exiting block query
  loop exit block query
  latch-list, backedge, loop-depth, and loop-invariant value helpers
  LCSSA-form check without LCSSA phi insertion

LICM subset:
  pure loop-invariant instruction hoisting to an existing preheader
  dominance and hoist-destination use checks for supported scalar motion
  memory-effect API blocks load/store/volatile/atomic hoisting
  no memory LICM, store sinking, LCSSA formation, preheader creation, or
  MemorySSA promotion yet
```

## Next Unsupported Areas To Remove

The next useful parser expansions are:

```text
call
bitcast and pointer casts
unsafe or poison-sensitive division/remainder simplification
using instruction flags such as nsw/nuw/exact in transforms
aggregate, string, TLS, COMDAT, alias, and declaration globals
unknown TLS model spellings
semantic global variable use in optimizations
visibility and attributes with semantic effects
calling convention ABI semantics
LLVM EH IR; Zig error-union control-flow is tracked separately from invoke,
landingpad, and resume support
aggregate, floating-point, vector, varargs, register, and stack ABI
classification; `byval` and `sret` are pointer-parameter text preservation
only, without ABI lowering semantics
full AIR parser and full Zig AIR semantics
AIR-like non-canonical loops, calls, select, overflow operations, intrinsics, aggregates, comptime, errors, async, and debug info
raw Zig-emitted aliases, debug metadata, attribute groups, and target-feature strings before normalization
function declarations
attribute groups
interpreted module metadata
full atomic operations and ordering semantics
```

These unlock better comparisons with LLVM `opt` and the next algorithms: richer InstCombine folds, SROA slice splitting, memory-aware LICM, and ABI-aware lowering.

## Unsupported Codegen Constructs

The `--emit=asm` and `--emit=obj` paths are intentionally smaller than the IR parser:

```text
only x86_64-linux target triples
one-block leaf functions, plus a narrow three-block conditional-return shape
only i32 return values or void returns
only register-passed i1/i32 parameters
only return constant, return parameter, add/sub/and/or/xor parameter expressions, and simple conditional returns
no general branches
no memory operations
no calls
no stack frame
object emission is ELF64 relocatable only, with .text/.symtab/.strtab/.shstrtab and no relocations
```
