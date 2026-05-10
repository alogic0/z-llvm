target triple = "x86_64-unknown-linux-gnu"

define i32 @callee() {
entry:
  ret i32 7
}

define i32 @call_internal() {
entry:
  %r = call i32 @callee()
  ret i32 %r
}

