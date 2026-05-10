target triple = "x86_64-unknown-linux-gnu"

declare i32 @callee(i32, i32)

define i32 @call_two_args(i32 %a, i32 %b) {
entry:
  %r = call i32 @callee(i32 %a, i32 %b)
  ret i32 %r
}

