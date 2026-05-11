# Named Type Definitions

LLVM mapping:

```text
llvm-project-22/llvm/docs/LangRef.rst: identified structure type definitions
llvm-project-22/llvm/lib/AsmParser/LLParser.cpp: top-level `%name = type ...`
llvm-project-22/llvm/lib/IR/Type.cpp: identified struct type storage/printing
```

Implemented local boundary:

```text
parse top-level `%name = type { ... }` records before top-level fallback
preserve the full raw record line opaquely in module order
print named type definitions after source/target records and module asm
verify unique named type names and non-empty opaque bodies
allow textual references such as `%os.linux.rlimit` to round-trip as opaque types
keep optimizer passes from using named type bodies for layout or ABI facts
```

The accepted source-backed fixture is
`test/zig/expected/named_type_definitions.reduced.ll`, reduced from the named
type records observed in `ziglang/test/cases/hello_world.zig`.

Non-goals:

```text
no recursive type completion validation
no opaque struct type declarations
no packed struct or arbitrary type-alias support
no DataLayout-backed aggregate layout from named type bodies
no ABI lowering semantics for named type references
```
