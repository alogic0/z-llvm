# Integer operands containing symbolic addresses

Private pointer-value legalization accepts an i64 integer operand only when the
existing `symbol_address.fromIntegerValue` contract proves an exact integral
64-bit `ptrtoint` expression. The shared grammar retains quoted symbol identity
and a checked signed byte addend. Other widths, address spaces, non-integral
layouts and unsupported expressions remain outside the contract.

The rewrite creates ordinary byte-GEP and ptrtoint SSA values before the binary
instruction. Both operand positions use the same contract. The original opcode,
flags, operand order and result identity are retained; the source IR is immutable.
The existing typed pointer and integer authorities own emission and preservation.

The six-function `integer_symbolic_operands` population checks subtraction in
both positions, positive and negative offsets, two symbolic operands, a quoted
symbol spelling and six simultaneously live integer inputs. Its C oracle computes results
from the linked symbol's actual address and checks offsets and unchanged
global bytes, without comparing process-dependent addresses between executables.
All arithmetic uses the original unsigned 64-bit wrapping interpretation. Alias
emission retains its existing explicit complete-module dependency policy.

## LLVM 22 mapping

`llvm-project-22/llvm/lib/CodeGen/SelectionDAG/SelectionDAGBuilder.cpp` handles
constant expressions through `getValue` and typed pointer/integer conversions,
then uses those values as ordinary operands to binary DAG nodes. The target data
layout determines pointer and index width. The shared symbolic-address contract
here retains its closed 64-bit integral layout and signed-addend limits.

This native population proves its address arithmetic and linkage cases. Complete
compiler selection still requires the unchanged-input census and independent
production replay; complete objects, startup and self-rebuild remain separate.
