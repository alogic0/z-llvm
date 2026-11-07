# Identifier identity

`src/ir/identifiers.zig` compares complete supported identifier spellings without
the leading `@` or `%`. Named identifiers decode quotes and hexadecimal escapes.
Numbered slots compare by their `u32` value, including leading zeroes, and remain
distinct from quoted numeric names. Unsupported spellings have no established
identity: a false comparison proves inequality only after both inputs pass
`isValid`.

The upstream mapping is `llvm/lib/AsmParser/LLLexer.cpp` in the local
`llvm-project-22` checkout, revision
`c0262e742787e5997a6df2b4b56830df00a6ff11`: `LexVar`, `ReadVarName`, `LexUIntID`
and `UnEscapeLexed` distinguish named/numbered tokens and decode named spellings.
The existing local grammar is narrower than LLVM's lexer; empty quoted names,
literal backslashes, raw line breaks and unsupported escapes remain outside this
helper's contract. This optimization does not extend accepted syntax.

Identical spellings need one validation. Different unquoted spellings need no
decoding unless both start with a digit and might denote the same numbered slot.
All remaining comparisons use the existing parser and decoded-byte comparison.
There is no cache, allocation, target-specific rule or change to temporary-name
ordering. This reduces repeated work in reachability, selection and the shared
legalizers used by Zig's x86_64 object route; fallback boundaries are unchanged.

`src/tests/ir_identifiers.zig` checks ordered pairs across spelling classes and
malformed inputs. `scalar_forms_tests.zig` checks collisions with parameter,
block and instruction-result aliases while preserving the first free serial.
`test/opt/inputs/symbol_spelling.ll` and its harness remain part of the LLVM 22
optimizer differential checks run by readiness. The existing semantic evidence
is [symbol identity acceptance](evidence/symbol_identity_acceptance_20261103.json).
