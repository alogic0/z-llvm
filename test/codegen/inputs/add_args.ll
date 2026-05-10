target triple = "x86_64-unknown-linux-gnu"

define i32 @add_args(i32 %a, i32 %b) {
entry:
  %sum = add i32 %a, %b
  ret i32 %sum
}
