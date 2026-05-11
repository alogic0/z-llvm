target triple = "x86_64-unknown-linux-gnu"

declare i32 @callee(i32)

define i32 @call_stack_slot(i32 %a) {
entry:
  %slot = alloca i32
  store i32 %a, ptr %slot
  %v = load i32, ptr %slot
  %r = call i32 @callee(i32 %v)
  ret i32 %r
}
