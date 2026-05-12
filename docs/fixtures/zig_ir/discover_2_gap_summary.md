# Discover 2 Gap Summary

Source report: `tmp/zig_ir/discover_2/report.tsv`

## Original Buckets

| Count | Status | Error | Classification |
| ---: | --- | --- | --- |
| 122 | verify-fail | `StreamTooLong` | Reclassified as `input-too-large` by the discovery harness. The normal CLI keeps its 1 MiB read limit. |
| 11 | parse-fail | `UnsupportedGlobalVariable` | Closed for source-backed pointer global initializers, anonymous aggregate global types, and opaque aggregate initializers. |
| 6 | verify-fail | `UnsupportedCallAttribute` | Closed for source-backed declaration/call parameter attributes used by Zig-emitted IR. |
| 3 | verify-fail | `UnsupportedNamedTypeDefinition` | Closed for quoted identified type names and packed structure bodies. |
| 2 | verify-fail | `UnsupportedVarArgs` | Closed for varargs declarations and source-backed fixed plus varargs calls. |
| 1 | verify-fail | `InvalidCharacter` | Closed for address-space pointer store syntax and large alignment values. |
| 1 | parse-fail | `UnsupportedType` | Closed for source-backed `trunc nuw` cast flag parsing. |
| 1 | parse-fail | `UnsupportedGlobalAlias` | Closed for quoted global alias targets and `weak_odr` aliases. |
| 1 | parse-fail | `InvalidCharacter` | Closed for constant-expression call operands and volatile stores with large alignment. |

## Reduced Fixture

Fixture: `test/zig/expected/discover2_gap_closure.reduced.ll`

Verifier-preserve expected output:
`test/opt/expected/z_llvm/discover2_gap_closure_verify_preserve.ll`

Fixture table row:
`discover2_gap_closure_verify_preserve`

The fixture covers:

- pointer globals such as `constant ptr @external_variable`;
- anonymous aggregate global types and opaque aggregate initializers;
- quoted identified type names and packed structure bodies;
- quoted and `weak_odr` aliases;
- varargs declarations and calls with source-backed parameter attributes;
- `metadata !N` call operands and `!prof` instruction metadata;
- call operands using `getelementptr`, `ptrtoint`, and `range(type lo, hi)`;
- address-space stores such as `ptr addrspace(257) null`;
- large alignments such as `align 4294967296`;
- switch multi-edge PHI incoming counts.

## LLVM Reference Mapping

Parser behavior follows the source-backed subset of:

- `llvm/lib/AsmParser/LLParser.cpp`: globals, aliases, named type definitions,
  declarations, calls, call operands, parameter attributes, and metadata
  attachments.
  - Function-level anchors: `parseGlobal`, `parseAlias`, `parseNamedType`,
    `parseFunctionHeader`, `parseFunctionType`, `parseCall`, `parseParameterList`,
    `parseOptionalParamAttrs`, `parseOptionalOperandBundles`,
    `parseValID`, `parseType`, `parseInstruction`, and `parseMetadata`.
- `llvm/lib/IR/AsmWriter.cpp`: printing globals, aliases, named types,
  declarations, calls, and metadata.
  - Function-level anchors: `AssemblyWriter::printGlobal`,
    `AssemblyWriter::printAlias`, `AssemblyWriter::printTypeIdentities`,
    `AssemblyWriter::printFunction`, `AssemblyWriter::printInstruction`,
    `AssemblyWriter::printInstructionLine`, `writeOperand`, and
    `writeParamOperand`.
- `llvm/lib/IR/Verifier.cpp`: global initializer rules, alias target checks,
  parameter attribute placement, varargs call shape, metadata operands, and PHI
  incoming validation.
  - Function-level anchors: `Verifier::visitGlobalVariable`,
    `Verifier::visitGlobalAlias`, `Verifier::visitFunction`,
    `Verifier::visitCallBase`, `Verifier::visitPHINode`,
    `Verifier::visitTruncInst`, and `Verifier::verifyAttributeTypes`.
- `llvm/lib/IR/Attributes.cpp`: attribute spelling and payload validation.
  - Function-level anchors: `Attribute::get`, `Attribute::getWithAlignment`,
    `Attribute::getWithDereferenceableBytes`, `Attribute::getWithCaptureInfo`,
    and `Attribute::getWithRange`.
- `llvm/lib/IR/Type.cpp`: identified and packed structure type spelling.
  - Function-level anchors: `StructType::create`, `StructType::setBody`,
    `StructType::isPacked`, and `Type::print`.
- `llvm/docs/LangRef.rst`: global variables, aliases, varargs, attributes,
  cast flags, address spaces, alignment, metadata operands, constant
  expressions, and PHI incoming semantics.

## Focused Validation

Representative `discover_2` rows accepted by the local verifier:

- `cases/address_of_extern_var_as_const.zig.ReleaseFast.x86_64.ll`
- `cases/safety/noreturn_returned.zig.ReleaseFast.x86_64.ll`
- `behavior/export_keyword.zig.ReleaseFast.x86_64.ll`
- `cases/f_segment_address_space_reading_and_writing.zig.ReleaseFast.x86_64.ll`
- `cases/f32_passed_to_variadic_fn.zig.ReleaseFast.x86_64.ll`
- `standalone/issue_11595_main.zig.ReleaseFast.x86_64.ll`
- `cases/array_in_anon_struct.zig.ReleaseFast.x86_64.ll`

Normal gates for this closure are recorded in the archived cycle file.
