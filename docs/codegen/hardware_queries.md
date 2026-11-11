# Native CPU queries

The optional legalization pipeline recognizes the exact side-effecting CPUID and XGETBV assembly signatures used by the pinned upstream compiler. CPUID accepts two i32 inputs and four i32 outputs; XGETBV accepts the exact ECX-zeroing form and returns its low i32 result. Different constraints, memory effects, operands or return shapes remain unsupported.

The private IR marks these operations explicitly. Ordinary parsed calls cannot acquire that marker by choosing a symbol name. The verifier checks the private signature. CPUID aggregate outputs become a packed i128 value with exact extraction shifts; literal input bits become named i32 values before the existing typed transfer path. Source IR stays immutable.

The selector preserves live caller-clobbered homes, prepares EAX/ECX through the shared typed transfer transaction and defines the result through the existing fixed-pair binder. The CPUID machine macro saves and restores RBX and has zero net stack displacement. XGETBV clears ECX, defines EAX and declares RCX/RDX and flags clobbered. The source program remains responsible for guarding instruction availability.

The generated hardware_queries canary compares all four CPUID outputs with an independent C assembly oracle and queries XCR0 only when CPUID reports OSXSAVE. The child pins itself to an allowed processor, avoiding APIC-ID changes between observations. It checks live i128 values, exact output writes, prefix/suffix guards, an RBX sentinel and stack preservation, with three injected failure modes through the standard native runner. Maintained generation uses tools/generate_hardware_queries_canary.zig.

This capability covers these exact CPU query forms. It does not provide general inline assembly or prove whole-compiler object emission, startup or self-rebuild.
