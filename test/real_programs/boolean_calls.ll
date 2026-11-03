target datalayout = "e-p:64:64-i64:64"
target triple = "x86_64-unknown-linux-gnu"

declare fastcc i1 @bool_return_dirty(i64)
declare fastcc i1 @bool_return_dirty_ptr(ptr)
declare i64 @bool_return_seed(i64)

define i64 @boolean_call_scalar(i64 %bits, i64 %live, ptr %output) {
entry:
  %boolean = call fastcc i1 @bool_return_dirty(i64 %bits)
  %wide = zext i1 %boolean to i64
  store i64 %wide, ptr %output, align 8
  %result = xor i64 %wide, %live
  ret i64 %result
}

define i64 @boolean_call_branch(i64 %bits, i64 %live, ptr %output) {
entry:
  %boolean = call fastcc i1 @bool_return_dirty(i64 %bits)
  br i1 %boolean, label %yes, label %no
yes:
  store i64 1, ptr %output, align 8
  %true_result = xor i64 %live, 170
  ret i64 %true_result
no:
  store i64 0, ptr %output, align 8
  %false_result = xor i64 %live, 85
  ret i64 %false_result
}

define i64 @boolean_call_stack_pointer(i64 %bits, i64 %live, ptr %output) {
entry:
  %slot = alloca i64, align 8
  store i64 %bits, ptr %slot, align 8
  %boolean = call fastcc i1 @bool_return_dirty_ptr(ptr noundef nonnull align 8 %slot)
  %wide = zext i1 %boolean to i64
  store i64 %wide, ptr %output, align 8
  %result = xor i64 %wide, %live
  ret i64 %result
}

define i64 @boolean_call_live_return(i64 %bits, i64 %live, ptr %output) {
entry:
  %saved = call i64 @bool_return_seed(i64 %live)
  %boolean = call fastcc i1 @bool_return_dirty(i64 %bits)
  %wide = zext i1 %boolean to i64
  store i64 %wide, ptr %output, align 8
  %combined = xor i64 %saved, %wide
  %result = xor i64 %combined, %live
  ret i64 %result
}
