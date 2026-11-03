target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare void @integer_pointer_clobber()
declare i64 @integer_pointer_echo(i64)

define i64 @integer_pointer_roundtrip(i64 %bits, i64 %live, ptr %output) {
entry:
  %slot = alloca ptr, align 8
  %pointer = inttoptr i64 %bits to ptr
  store ptr %pointer, ptr %slot, align 8
  %loaded = load ptr, ptr %slot, align 8
  store ptr %loaded, ptr %output, align 8
  %restored = ptrtoint ptr %loaded to i64
  %both = add i64 %restored, %bits
  %result = xor i64 %both, %live
  ret i64 %result
}

define i64 @integer_pointer_spilled(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, ptr %output) {
entry:
  %slot = alloca ptr, align 8
  call void @integer_pointer_clobber()
  %pa = inttoptr i64 %a to ptr
  %pb = inttoptr i64 %b to ptr
  %pc = inttoptr i64 %c to ptr
  %pd = inttoptr i64 %d to ptr
  %pe = inttoptr i64 %e to ptr
  store ptr %pa, ptr %slot, align 8
  %saved = load ptr, ptr %slot, align 8
  %o1 = getelementptr i8, ptr %output, i64 8
  %o2 = getelementptr i8, ptr %output, i64 16
  %o3 = getelementptr i8, ptr %output, i64 24
  %o4 = getelementptr i8, ptr %output, i64 32
  store ptr %saved, ptr %output, align 8
  store ptr %pb, ptr %o1, align 8
  store ptr %pc, ptr %o2, align 8
  store ptr %pd, ptr %o3, align 8
  store ptr %pe, ptr %o4, align 8
  %restored = ptrtoint ptr %saved to i64
  %result = xor i64 %restored, %e
  ret i64 %result
}

define i64 @integer_pointer_returned(i64 %bits, i64 %live, ptr %output) {
entry:
  %slot = alloca ptr, align 8
  %a = call i64 @integer_pointer_echo(i64 %bits)
  %b = call i64 @integer_pointer_echo(i64 %live)
  %pa = inttoptr i64 %a to ptr
  %pb = inttoptr i64 %b to ptr
  store ptr %pa, ptr %slot, align 8
  %saved = load ptr, ptr %slot, align 8
  %o1 = getelementptr i8, ptr %output, i64 8
  store ptr %saved, ptr %output, align 8
  store ptr %pb, ptr %o1, align 8
  %ra = ptrtoint ptr %saved to i64
  %rb = ptrtoint ptr %pb to i64
  %result = xor i64 %ra, %rb
  ret i64 %result
}

define ptr @integer_pointer_identity(i64 %bits) {
entry:
  %pointer = inttoptr i64 %bits to ptr
  ret ptr %pointer
}
