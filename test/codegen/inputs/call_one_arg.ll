target triple = "x86_64-unknown-linux-gnu"

declare i32 @callee(i32)

define i32 @call_one_arg(i32 %a) {
entry:
  %r = call i32 @callee(i32 %a)
  ret i32 %r
}

