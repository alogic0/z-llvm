target triple = "x86_64-unknown-linux-gnu"
define i64 @whole_compiler_invalid(i64 %x) {
entry:
  %result = deliberately_invalid_opcode i64 %x
  ret i64 %result
}
