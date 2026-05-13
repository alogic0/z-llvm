target triple = "x86_64-unknown-linux-gnu"

define i32 @scalar_add_zero(i32 %a) {
entry:
  %r = add i32 %a, 0
  ret i32 %r
}
