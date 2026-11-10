# Binary128 payloads and numerical calls

The generic x86-64 selector uses a private `<2 x double>` bit carrier for native
binary128 values on the primary little-endian SysV LP64 target. LLVM assigns
`fp128` and these complete 128-bit vectors to the same XMM argument and return
class. The carrier preserves every bit; its lanes are never used as two numeric
doubles when implementing a binary128 operation. Public definitions, declarations,
attributes and operand types remain immutable.

`floating_payloads.zig` maps ordinary memory, GEP stride, PHIs, selects, direct
calls and returns through existing vector storage and ABI contracts. Literal
`0xL` values retain LLVM's low-word-first spelling, including signed zeros and
NaN payloads. A scalar i128 bitcast reinterprets through an owned sixteen-byte
home and the existing vector/pair load and store paths. A freeze stabilizes the
two stored 64-bit words before loading the complete carrier. This retains every
defined source bit and chooses a stable permitted value for undefined or poison
inputs. Private storage is initialized before use and cannot alias source memory.

Source-only memory metadata is omitted from rewritten instructions. Volatile,
atomic and explicit address-space accesses keep their separate boundaries.
Only validated `noundef` promises are accepted on binary128 parameters and
returns. Indirect, variadic and mandatory-tail quad calls stay outside this
transport contract, as do stack vector arguments beyond the existing XMM bounds.

`binary128_arithmetic.zig` first rewrites logical numerical operations to the
same standard compiler-rt calls used by LLVM. The payload stage then transports
their arguments and results without changing the numerical interpretation:

| Logical operation | Runtime contract |
| --- | --- |
| Add, subtract, multiply, divide | `__addtf3`, `__subtf3`, `__multf3`, `__divtf3` |
| Float/double extension | `__extendsftf2`, `__extenddftf2` |
| Float/double truncation | `__trunctfsf2`, `__trunctfdf2` |
| Signed/unsigned i32/i64 to quad | `__floatsitf`, `__floatunsitf`, `__floatditf`, `__floatunditf` |
| Quad to signed/unsigned i32/i64 | `__fixtfsi`, `__fixunstfsi`, `__fixtfdi`, `__fixunstfdi` |

All sixteen ordinary floating comparison predicates use `__letf2`, `__getf2`,
`__eqtf2` and `__unordtf2`. Their SysV `CMP_RESULT` is a 64-bit long. The first
ordering helper reports unordered as positive; the second reports it as negative.
Ordered-not-equal and unordered-equal combine ordering and unordered checks, so
NaNs and both signed zeros retain LLVM predicate semantics. Constant `true` and
`false` predicates materialize a native-width value before defining the boolean,
discharging mandatory width normalization without an immediate source request.
Ordinary floating assumptions are not attached to new calls. Constrained
floating intrinsics retain their own unsupported boundary.

Machine verification classifies a public `fp128` return as a complete XMM0 value.
It requires all 128 defined bits; EAX and a 64-bit XMM definition cannot satisfy
the return contract. The original parameter binder, transfer authorities,
transaction representation and source guards are unchanged.

The parser's synthetic `fsub -0.000000e+00` spelling of `fneg` is deliberately
excluded from the new arithmetic rewrite. Its existing bitwise fallback flips
only the sign bit, preserving signaling/quiet NaN representations and payloads.
The same ambiguous subtraction spelling stays outside the new generic contract.
Original binary128 inputs define all 128 incoming XMM bits for verification.

The legacy IR-writer root policy can omit runtime helpers. Self-contained
structured modules explicitly enable direct-definition closure. Once their roots
are selected, a work queue includes module definitions actually referenced by emitted
direct calls or jumps, recursively and once each. External declarations remain
external. This retains newly selected calls and their supplied definitions;
it does not synthesize a runtime implementation. Explicit reachable selection
continues to use its existing dependency graph. Imported ordinary Zig IR keeps
its existing external runtime/linker ownership policy; it does not enable this
structured-module option.
The integrated runner's supplied panic fallbacks use weak symbols so a module's
own strong definition takes precedence, with no duplicate-symbol link failure.

Upstream mapping, pinned LLVM 22 sources:

- `llvm-project-22/llvm/lib/Target/X86/X86CallingConv.td`, `CC_X86_64_C` and
  `RetCC_X86_64_C`, assign native f128 and 128-bit vectors to XMM registers.
- `llvm-project-22/llvm/include/llvm/IR/RuntimeLibcalls.td` maps binary128
  arithmetic and scalar conversions to the runtime symbols above.
- `llvm-project-22/compiler-rt/lib/builtins/comparetf2.c` documents ordered and
  unordered comparison results; `fp_compare_impl.inc` defines the LP64 return
  representation. The pinned Zig `lib/compiler_rt/comparef.zig` uses the same
  long-width ordering and unordered result ABI.
- `llvm-project-22/llvm/docs/LangRef.rst` defines exact bitcasts, freezes,
  ordinary floating operations, all comparison predicates and poison stored to
  memory. The original source's undefined behavior is not strengthened.

`tools/generate_binary128_payload_canary.zig` generates 39 LLVM functions and
an independent C oracle. The canary checks 5,041 observations per execution:
raw payloads, all sixteen predicates over signed finite values, subnormals,
infinities and NaNs, direct/fastcc boundaries, eight XMM inputs, caller clobbers,
owned and ordinary memory, a protected page edge, numerical operations and
conversions. Return, four field and two guard faults calibrate the checker.
Whole-input selection counts and acceptance are recorded separately.
A separately generated negation probe compares the preserved structural fallback
against LLVM for eight raw patterns, including signed and signaling NaNs.

Remainder, other quad intrinsics, x87 arithmetic, half/extended conversions,
i128 numerical conversions and additional ABI envelopes remain in scope for
the all-8,928 plan. This contract supplies no complete-object or startup claim.
