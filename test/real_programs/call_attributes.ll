target triple = "x86_64-unknown-linux-gnu"

declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1 immarg)
declare void @llvm.memmove.p0.p0.i64(ptr, ptr, i64, i1 immarg)
declare void @attributes_touch(ptr, i32)
declare ptr @attributes_identity(ptr)
declare i32 @attributes_i32(i32)
declare i64 @attributes_i64(i64)

define i64 @attributes_copy(ptr %dst, ptr %src, i64 %length, i64 %cookie) {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr noundef nonnull noalias writeonly align 1 captures(none) %dst, ptr noundef nonnull readonly align 1 captures(none) %src, i64 noundef range(i64 0, 65) %length, i1 false)
  %r = xor i64 %cookie, %length
  ret i64 %r
}

define i64 @attributes_move(ptr %dst, ptr %src, i64 %length, i64 %cookie) {
entry:
  call void @llvm.memmove.p0.p0.i64(ptr noundef nonnull writeonly align 1 captures(none) %dst, ptr noundef nonnull readonly align 1 captures(none) %src, i64 range(i64 0, 65) noundef %length, i1 false)
  %r = xor i64 %cookie, %length
  ret i64 %r
}

define i64 @attributes_write(ptr %dst, i32 %value, i64 %cookie) {
entry:
  call void @attributes_touch(ptr dead_on_unwind noalias writeonly align 1 captures(none) %dst, i32 noundef %value)
  %p = call noundef nonnull align 1 dereferenceable(4) ptr @attributes_identity(ptr noundef nonnull %dst)
  %v = load i32, ptr %p, align 1
  %wide = zext i32 %v to i64
  %r = xor i64 %wide, %cookie
  ret i64 %r
}

define i32 @attributes_range32(i32 %value, i32 %cookie) {
entry:
  %v = call noundef range(i32 -16, 16) i32 @attributes_i32(i32 noundef range(i32 -16, 16) %value)
  %r = xor i32 %v, %cookie
  ret i32 %r
}

define i64 @attributes_range64(i64 %value, i64 %a, i64 %b, i64 %c, i64 %d, i64 %e) {
entry:
  %v = call noundef range(i64 -16, 16) i64 @attributes_i64(i64 range(i64 -16, 16) noundef %value)
  %r0 = xor i64 %v, %a
  %r1 = add i64 %r0, %b
  %r2 = xor i64 %r1, %c
  %r3 = add i64 %r2, %d
  %r4 = xor i64 %r3, %e
  ret i64 %r4
}
