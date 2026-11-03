target datalayout = "e-m:e-p:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@module_entry = alias i64 (i64), ptr @module_entry_alias
@module_entry_alias = internal alias i64 (i64), ptr @module_entry_impl
@module_fib = alias i32 (i32), ptr @module_fib_impl
@module_callback_alias = hidden alias ptr, ptr @module_callback
@module_callback = global ptr @module_callback_first, align 8
@module_callback_first = internal alias i64 (i64), ptr @module_callback_second
@module_callback_second = internal alias i64 (i64), ptr @debug.module_callback_impl
@module_private_slot = internal constant ptr @module_slot_impl, align 8
@module_dead_alias = internal alias <2 x i64> (<2 x i64>), ptr @module_dead
@module_dead_data = internal global double 1.0

declare i64 @module_external_word(i64)

define internal i64 @module_entry_impl(i64 %x) noinline {
entry:
  %v = call i64 @module_middle(i64 %x)
  %r = xor i64 %v, 918273645
  ret i64 %r
}

define internal i64 @module_middle(i64 %x) noinline {
entry:
  %v = call i64 @module_leaf(i64 %x)
  %r = add i64 %v, %x
  ret i64 %r
}

define internal i64 @module_leaf(i64 %x) noinline {
entry:
  %v = call i64 @module_external_word(i64 %x)
  %r = add i64 %v, 17
  ret i64 %r
}

define internal i64 @debug.module_callback_impl(i64 %x) noinline {
entry:
  %r = xor i64 %x, 123456789
  ret i64 %r
}

define internal i64 @module_slot_impl(i64 %x) noinline {
entry:
  %r = add i64 %x, 987654321
  ret i64 %r
}

define hidden ptr @module_get_slot() noinline {
entry:
  %p = getelementptr i8, ptr @module_private_slot, i64 0
  ret ptr %p
}

define internal i32 @module_fib_impl(i32 %n) noinline {
entry:
  %base = icmp ult i32 %n, 2
  br i1 %base, label %small, label %recurse
small:
  ret i32 %n
recurse:
  %a = sub i32 %n, 1
  %b = sub i32 %n, 2
  %left = call i32 @module_fib_impl(i32 %a)
  %right = call i32 @module_fib_impl(i32 %b)
  %sum = add i32 %left, %right
  ret i32 %sum
}

define internal <2 x i64> @module_dead(<2 x i64> %x) {
entry:
  ret <2 x i64> %x
}
