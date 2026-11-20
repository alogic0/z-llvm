# Module-Level ASM

LLVM mapping:

```text
llvm-project-22/llvm/docs/LangRef.rst: module-level inline assembly
llvm-project-22/llvm/lib/AsmParser/LLParser.cpp: top-level `module asm`
llvm-project-22/llvm/lib/IR/Module.cpp: module inline-asm storage/printing
```

Implemented local boundary:

```text
parse top-level `module asm "..."` records before semicolon comment stripping
preserve the full raw record line opaquely in module order
print module asm after source/target records and before globals/functions
verify only that the record is a syntactically closed top-level string
keep optimizer passes from interpreting or dropping module asm records
```

The accepted source-backed fixture is
`test/zig/expected/behavior_asm_module_asm.reduced.ll`, reduced from
`ziglang/test/behavior/asm.zig`.

Non-goals:

```text
no target assembly parser
no `.globl`, `.type`, `.set`, or symbol alias resolution
no MC/object lowering of module asm
no GlobalDCE rooting based on assembly text
no native codegen semantics for module asm
```
