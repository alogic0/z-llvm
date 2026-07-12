# x86_64 FP Selector Foundation

This note records the floating-point ABI and ownership rules used by the
composed x86_64 selector. It is the INBOX-17 foundation for the soft-float
compiler-rt family beginning at `compiler_rt.trunc.__trunch`.

## Existing Ownership

- `src/codegen/x86_64/sysv_abi.zig` owns SysV argument and return
  classification. The selector consumes those rules; it does not maintain a
  second ABI table.
- `src/codegen/x86_64/machine.zig` already owns scalar SSE operations, XMM
  copies, and 32-bit/64-bit XMM frame spills and reloads.
- `generic_cfg/core_single_block_fp.zig` and `air_patterns_fp.zig` remain the
  existing specialized lowering paths. The composed selector extends the
  shared value-location model rather than replacing or duplicating them.
- The composed selector retains one value-location map and one frame-index
  authority for integer and FP values.

## SysV Representations

| IR type | ABI class and boundary representation | Composed selector status |
| --- | --- | --- |
| `half` | SSE; low 16 bits of the assigned XMM register, XMM0 for return | `fp16` / width-tagged XMM location |
| `float` | SSE; low 32 bits of the assigned XMM register, XMM0 for return | `fp32` / width-tagged XMM location |
| `double` | SSE; low 64 bits of the assigned XMM register, XMM0 for return | `fp64` / width-tagged XMM location |
| `x86_fp80` | x87/stack ABI boundary; not an SSE scalar | Existing specialized x87 paths only; composed selection fails closed |
| `fp128` | Generic SysV classifier currently treats scalar fp128 as a memory boundary | Existing specialized paths do not establish a generic composed ABI; composed selection fails closed |

GPR and XMM allocation are independent. XMM0-XMM7 are allocatable scalar FP
locations and are caller-clobbered at a call boundary. A supported scalar FP
return must be materialized in XMM0. Calls spill every live FP value that must
survive before clobbering its XMM register.

Each composed FP spill uses one existing 8-byte frame object. `half` and
`float` use the 32-bit XMM spill/reload forms; `double` uses the 64-bit forms.
The location retains the semantic width, so a reload cannot change register
class or reinterpret a low lane. Frame allocation and alignment remain owned
by the existing composed frame planner.

Unsupported widths, x87 values, fp128 values, stack-passed half call
arguments, and unimplemented mixed-class operations reject with a typed ABI,
value, or emitter diagnostic. They must not fall back to GPR allocation or
infer a representation from a symbol name.
