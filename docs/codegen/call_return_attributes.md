# Validated extension and nullable memory attributes

The shared IR verifier accepts `dereferenceable_or_null(N)` only on pointers,
with an exact decimal u64 payload and no duplicate instance. Zero is valid.
The attribute preserves the possibility of null. Its ordinary pointer register
representation does not change. Duplicate or conflicting integer extension
tokens are rejected; a single `signext` remains valid IR syntax.

SysV admission accepts `zeroext` on integer widths 1–31 through the existing
clean private 32-bit carrier. Incoming parameters, outgoing arguments, returned
call values and own-function returns retain their original low-width payload.
Receive masks discard unspecified bits before publishing a logical value;
outgoing widening establishes the clean carrier. Attributes are omitted only
on the private widened view, and remain present on the original source IR.
Signed extension and 32/64-bit extension attributes retain their existing
unsupported ABI boundary.

Nullable memory promises use the same verified pointer facts at function and
call boundaries. They do not introduce a nonnull assumption, widen an access
or bypass the ordinary call, pointer or storage authorities.

## LLVM 22 mapping and native proof

`llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td`, `CC_X86_64_C`, promotes
small integer arguments to 32-bit locations. `RetCC_X86Common` uses AL, AX and
EAX return containers, with i1 promoted to a byte. Integer type legalization
also supplies containers for odd widths. `X86ISelLoweringCall.cpp` owns the
corresponding call/return lowering.

The private 32-bit carrier may define more bits than a foreign callee promises.
Native probes therefore inspect the legalized AL/AX/EAX return container and
exclude unspecified bits above it. Padding inside that container remains
observable, including boolean, i7, i23 and i31 extension bits. No claim requires
a foreign narrow return to clear all of EAX or RAX.

The fifteen-function `call_return_attributes` population checks six widths
(1, 7, 8, 16, 23 and 31), eight simultaneous arguments with two stack positions,
actual caller-register clobbers, clean argument carriers, masked received values
and generated callees' return containers. Pointer cases cover 16/140-byte
promises with both null and valid pointers, guarded loads after null checks,
unchanged memory, and pointer-return forwarding. The C providers satisfy every
extension and extent promise. Each execution checks 520 observations. Five
faults exercise results, argument checks, guards, extension padding and pointer
identity.

The initial raw-return prototype incorrectly inspected unspecified high bits
of LLVM's byte return. Its failure and read-only disassembly remain retained.
The corrected probe observes the actual ABI container in both compilers.
The complete unchanged-input census and independent production replay accept
compiler coverage; these populations alone establish no startup or self-rebuild.
