target triple = "x86_64-unknown-linux-gnu"

declare i32 @callee()

define i32 @call_no_args() {
entry:
  %r = call i32 @callee()
  ret i32 %r
}

