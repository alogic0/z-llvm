# Typed i52 truncation bridges

Private integer normalization bridges otherwise unsupported truncations to or
from i52 through the existing clean 64-bit actions. A source i53 truncated to
i52 first receives an unsigned word carrier, then the established i64-to-i52
truncation. An i52 truncated to i2 first uses the existing i52-to-i64 extension,
then an ordinary word truncation. The same rule applies to other integer widths
up to 64. Established i52 cast actions retain priority.

Every original result retains its declared type and identity. Loads, stores,
allocation sizes and public ABI types retain their original extents. The
mandatory normalization predicate is unchanged, and the optional view retains
the original-form retry. The source function is borrowed without mutation.

The generated `integer_truncation` native canary exercises sixteen width
combinations, dirty upper input bits, preserved original inputs, live scalar
arguments and an incoming stack argument. Unaligned stores write only the
declared byte extent. The C oracle checks every defined result bit and both
guards while allowing LLVM's unspecified padding bits in the final stored byte.
Separate controls corrupt the return, a stored value and a suffix guard.
