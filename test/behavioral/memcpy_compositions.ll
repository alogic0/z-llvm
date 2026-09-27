target triple = "x86_64-unknown-linux-gnu"
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

define ptr @copy_plain(ptr %dst, ptr %src, i64 %len) {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %src, i64 %len, i1 false)
  ret ptr %dst
}

define ptr @copy_offset(ptr %dst, ptr %src, i64 %len, i64 %offset) {
entry:
  %d = getelementptr i8, ptr %dst, i64 %offset
  %s = getelementptr i8, ptr %src, i64 %offset
  call void @llvm.memcpy.p0.p0.i64(ptr %d, ptr %s, i64 %len, i1 false)
  ret ptr %d
}

define i64 @copy_pressure(ptr %dst, ptr %src, i64 %len, i64 %x, i64 %y, i64 %z) {
entry:
  %keep = load <16 x i8>, ptr %src, align 1
  %a = add i64 %x, %y
  %b = xor i64 %a, %z
  call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %src, i64 %len, i1 false)
  %tail = getelementptr i8, ptr %dst, i64 %len
  store <16 x i8> %keep, ptr %tail, align 1
  %c = add i64 %b, %len
  %d = xor i64 %c, %x
  %e = add i64 %d, %y
  %r = xor i64 %e, %z
  ret i64 %r
}

define ptr @copy_twice(ptr %dst, ptr %src, ptr %other, i64 %len) {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr %other, ptr %src, i64 %len, i1 false)
  call void @llvm.memcpy.p0.p0.i64(ptr %dst, ptr %other, i64 %len, i1 false)
  ret ptr %other
}

define i32 @copy_byte(ptr %dst, ptr %src) {
entry:
  %v = load i8, ptr %src, align 1
  store i8 %v, ptr %dst, align 1
  %r = zext i8 %v to i32
  ret i32 %r
}

define ptr @copy_vector(ptr %dst, ptr %src) {
entry:
  %v = load <16 x i8>, ptr %src, align 1
  store <16 x i8> %v, ptr %dst, align 1
  ret ptr %dst
}

define i64 @copy_alignment(ptr %src) {
entry:
  %bits = ptrtoint ptr %src to i64
  %alignment = and i64 %bits, 15
  ret i64 %alignment
}
