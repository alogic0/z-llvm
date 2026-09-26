target triple = "x86_64-unknown-linux-gnu"
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)

define ptr @fill_offset(ptr %dst, i32 %value, i64 %len, i64 %offset) {
entry:
  %byte = trunc i32 %value to i8
  %p = getelementptr i8, ptr %dst, i64 %offset
  call void @llvm.memset.p0.i64(ptr %p, i8 %byte, i64 %len, i1 false)
  ret ptr %p
}

define i64 @fill_pressure(ptr %dst, i32 %value, i64 %len, i64 %x, i64 %y, i64 %z) {
entry:
  %a = add i64 %x, %y
  %b = xor i64 %a, %z
  %byte = trunc i32 %value to i8
  call void @llvm.memset.p0.i64(ptr %dst, i8 %byte, i64 %len, i1 false)
  %c = add i64 %b, %len
  %d = xor i64 %c, %x
  %e = add i64 %d, %y
  %r = xor i64 %e, %z
  ret i64 %r
}

define ptr @fill_constants(ptr %dst) {
entry:
  call void @llvm.memset.p0.i64(ptr %dst, i8 -1, i64 17, i1 false)
  call void @llvm.memset.p0.i64(ptr %dst, i8 0, i64 0, i1 false)
  ret ptr %dst
}

define ptr @fill_twice(ptr %dst, ptr %other, i32 %value, i64 %len) {
entry:
  %byte = trunc i32 %value to i8
  call void @llvm.memset.p0.i64(ptr %other, i8 %byte, i64 %len, i1 false)
  call void @llvm.memset.p0.i64(ptr %dst, i8 42, i64 %len, i1 false)
  ret ptr %other
}

define ptr @pointer_identity(ptr %p) {
entry:
  ret ptr %p
}

define ptr @pointer_null() {
entry:
  ret ptr null
}
