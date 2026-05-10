target triple = "x86_64-unknown-linux-gnu"

define i32 @stack_slot(i32 %a) {
entry:
  %slot = alloca i32
  store i32 %a, ptr %slot
  %v = load i32, ptr %slot
  ret i32 %v
}

