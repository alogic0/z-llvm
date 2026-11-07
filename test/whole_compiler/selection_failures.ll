target triple = "x86_64-unknown-linux-gnu"
define <2 x i64> @whole_compiler_first(<2 x i64> %x) {
entry:
  ret <2 x i64> %x
}
define <2 x i64> @whole_compiler_second(<2 x i64> %x) {
entry:
  ret <2 x i64> %x
}
define i64 @whole_compiler_accepted(i64 %x) {
entry:
  ret i64 %x
}
