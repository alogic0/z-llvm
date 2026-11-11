# Integer intrinsic and call boundaries

Unsigned i128 multiply-with-overflow uses a private wrapping product and exact
unsigned quotient comparison. A nonzero multiplier overflows precisely when
dividing the wrapped product by that multiplier does not recover the original
operand. Zero selects a safe divisor and an explicit false overflow result.
Existing pair arithmetic and runtime-helper transfer contracts execute these
operations; canonical and aliased helper bodies remain closed to recursive
outlining. The guarded signed-multiply and frame functions, all frozen source
guards, and Source/UseForm interfaces remain unchanged.

The two-argument target intByteSize method uses ordinary narrow ABI handling:
pointer context and integer argument are independently preserved, and the i16
return is masked before exposing the original SSA result. The one-argument
legacy action retains its existing authority. Memset accepts only the shared
validated advisory integer attributes, including typed ranges, and keeps its
exact-byte and nonvolatile boundaries.

The maintained Zig generator covers signed/unsigned i128 products, the target
method call, and named/constant range-attributed memset lengths. The independent
C oracle multiplies 32-bit limbs and checks low product bits and signed or
unsigned overflow separately. Its 40,960 observations per execution also check
narrow return values, pointer context, zero-length stores, guards and live values
across real caller clobbers, with LLVM references and injected faults.
