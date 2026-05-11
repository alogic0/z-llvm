# Alias Metadata Policy

LLVM references:

```text
llvm-project-22/llvm/include/llvm/IR/Metadata.h
llvm-project-22/llvm/lib/Analysis/TypeBasedAliasAnalysis.cpp
llvm-project-22/llvm/lib/Analysis/ScopedNoAliasAA.cpp
llvm-project-22/llvm/include/llvm/Analysis/AliasAnalysis.h
```

Upstream entry points to check:

```text
MD_tbaa
MD_alias_scope
MD_noalias
TypeBasedAAResult
ScopedNoAliasAAResult
AAResults::alias
AAResults::getModRefInfo
```

## Local Policy

Alias metadata is accepted only as opaque instruction metadata on the supported
forms:

```text
!tbaa
!alias.scope
!noalias
```

The parser preserves these attachments textually, the printer emits them back
unchanged, and the verifier does not interpret the metadata graph.

No local optimization pass may use alias metadata as a no-alias proof until the
project implements an explicit metadata verifier and an LLVM-compared alias
analysis slice. Alias queries therefore continue to use only structural
MemoryLocation facts, DataLayout-backed byte ranges, globals, aliases, volatile
and atomic barriers, and call memory effects.

## Current Pass Boundary

```text
DCE/ADCE: metadata is ignored; side effects decide deletion.
DSE: metadata is ignored; structural alias and overwrite facts decide removal.
EarlyCSE/GVN: metadata is ignored; MemorySSA and structural alias facts decide load availability.
LICM: metadata is ignored; invariant load hoisting requires a structural no-clobber proof.
```

This is intentionally more conservative than LLVM. LLVM can combine BasicAA,
TBAA, scoped-noalias metadata, and other AA providers through `AAResults`.

## Fixture Coverage

```text
unit tests: instruction metadata round trip and unsupported metadata rejection
parse-preserve fixture: alias_metadata_preserve
opt comparison: not used for metadata interpretation; local fixture verifies no metadata is dropped
```

## Known Gaps

```text
no TBAA graph validation
no scoped-noalias domain/scope graph validation
no metadata-driven no_alias result
no metadata-aware mod/ref classification
no address-space metadata policy
unsupported instruction metadata kinds are rejected unless separately admitted
```
