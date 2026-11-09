# Private call values and pointer promises

Explicit `undef` and `poison` call arguments of integer widths i1 through i128
become zero in the private selector view. Pointer arguments become null.
This chooses a concrete LLVM refinement and prevents consumption of uninitialized
machine state. Defined arguments retain their values, types and attributes.

The mandatory normalization runs before legacy recognition and optional narrow
ABI widening. Only affected argument lists are cloned; source instructions,
call facts, parameter lists and public signatures remain borrowed and unchanged.
Removed instructions and unsupported argument types retain their boundaries.
The normalized invariant is checked before selection.

The SysV attribute checker also accepts validated pointer `readnone`,
`captures(address)`, `captures(address_is_null)` and `initializes(...)` promises.
They require no machine ABI change. Initialization ranges must be nonempty,
signed i64 intervals with increasing endpoints, sorted with neither overlap
nor adjacency. Unsigned decimal spellings preserve their signed i64 bit patterns.
Malformed payloads, duplicate attributes and unsupported ABI forms reject.
Source promises remain intact; admission does not synthesize initializing stores.

The native `call_values` population covers twelve selected LLVM functions and
eight public driver cases. Undefined arguments go to LLVM-defined helpers that
ignore those parameters and declare no `noundef` promise. Defined neighboring
arguments, values across clobbering calls, initialization bytes, pointer address
and nullness results, and surrounding guards provide fully defined observations.

Both routes and all three release modes pass with frozen Debug and ReleaseFast
compilers. A separate narrow-argument probe covers i1/i8/i16. An independent
defined-argument mutation is rejected by the driver. See the
[accepted evidence](../evidence/call_values_pointer_promises.md).
