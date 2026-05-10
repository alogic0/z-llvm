target triple = "x86_64-unknown-linux-gnu"

declare i32 @callee()

define i32 @call_return_used(i32 %a) {
entry:
  %r = call i32 @callee()
  %sum = add i32 %r, %a
  ret i32 %sum
}

