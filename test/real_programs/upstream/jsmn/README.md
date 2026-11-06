# Unchanged upstream JSON-dump program

These files are byte-for-byte copies of `jsmn` v1.1.0, revision
`fdcef3ebf886fa210d14956d3c068a653e76a24e`, from
[the upstream repository](https://github.com/zserge/jsmn/tree/fdcef3ebf886fa210d14956d3c068a653e76a24e).
The upstream MIT license is retained in `LICENSE` and `jsmn.h`.
The manifest `../../jsmn_jsondump.json` authenticates all three source/license
files and freezes the runtime corpus. No source substitutions or compiler-specific
edits are applied.

The example grows its input buffer and token array, mutates parser/token state,
and recursively prints JSON read from stdin. Its default parser is permissive;
the corpus tests the documented example's observations, not strict JSON validity.
Empty or incomplete input prints `fread(): unexpected EOF` and exits 2.
Expected output is frozen independently of either compiled executable, including
the example's indentation and raw escape spelling. Large inputs cross `BUFSIZ`
boundaries and repeatedly exhaust and grow the initial two-token allocation.

The original diagnostic corpus split an unquoted number at the 8,192-byte read
boundary. LLVM revealed that the permissive upstream parser prematurely finishes
that primitive and prints it as two tokens. The frozen growth case uses quoted
values, whose incomplete-token handling is defined across read boundaries; the
initial diagnostic is retained with the implementation evidence.

The C release-mode gate does not enable sanitizers or exercise allocator failure.
It does not claim complete JSON conformance or replace unchanged Zig programs.
