target triple = "x86_64-unknown-linux-gnu"

define i32 @bitwise_args(i32 %a, i32 %b) {
entry:
  %v = xor i32 %a, %b
  ret i32 %v
}
