# Half math and native scalar square roots

Ordinary half intrinsics promote through exact binary32 arguments and round
their results to half. Fused multiply-add promotes all three arguments to
binary64, calls the binary64 fused operation and rounds directly to half.
This matches LLVM22's baseline x86-64 lowering and avoids intermediate half
or float rounding of a fused result.

Only used results with exact ordinary intrinsic signatures are opened. The
shared math matcher rejects constrained intrinsics, indirect calls, unsupported
attributes, calling conventions and musttail envelopes. Original IR remains
immutable; temporary instructions live in the private candidate. Canonical
helper/alias recursion guards remain in the shared library-outlining stage.

Float and double square-root intrinsics use SQRTSS/SQRTSD through existing typed
value materialization and XMM clobber/preservation contracts. They leave errno
unchanged, like LLVM's native instructions. They preserve arithmetic EFLAGS.
Machine encoding, assembly, sizes and verification describe the same operations.
Extended80 numerical arithmetic and square root remain separate boundaries.

The Zig half generator creates fourteen functions with 917,504 observations per
execution: every half input pattern for every operation, with varied additional
FMA operands. Integer representation decoding and round-to-nearest-even provide
independent widening/narrowing oracles. Two additional native square-root
functions cover 8,192 float/double cases. Both populations protect input page
boundaries, validate exact stores and errno, preserve inputs and keep results
live across real caller-clobber instructions. Both routes and all three modes
retain independent LLVM references and injected-failure controls.
