target triple = "x86_64-unknown-linux-gnu"
declare void @llvm.memset.inline.p0.i64(ptr, i8, i64 immarg, i1 immarg)

define i64 @inline_set_0(ptr %out, i8 %byte, i64 %keep) {
entry:
  call void @llvm.memset.inline.p0.i64(ptr %out, i8 %byte, i64 0, i1 false)
  %wide = zext i8 %byte to i64
  %r = xor i64 %keep, %wide
  %answer = xor i64 %r, 0
  ret i64 %answer
}
define i64 @inline_set_1(ptr %out, i8 %byte, i64 %keep) {
entry:
  call void @llvm.memset.inline.p0.i64(ptr %out, i8 %byte, i64 1, i1 false)
  %wide = zext i8 %byte to i64
  %r = xor i64 %keep, %wide
  %answer = xor i64 %r, 1
  ret i64 %answer
}
define i64 @inline_set_2(ptr %out, i8 %byte, i64 %keep) {
entry:
  call void @llvm.memset.inline.p0.i64(ptr %out, i8 %byte, i64 2, i1 false)
  %wide = zext i8 %byte to i64
  %r = xor i64 %keep, %wide
  %answer = xor i64 %r, 2
  ret i64 %answer
}
define i64 @inline_set_4(ptr %out, i8 %byte, i64 %keep) {
entry:
  call void @llvm.memset.inline.p0.i64(ptr %out, i8 %byte, i64 4, i1 false)
  %wide = zext i8 %byte to i64
  %r = xor i64 %keep, %wide
  %answer = xor i64 %r, 4
  ret i64 %answer
}
define i64 @inline_set_8(ptr %out, i8 %byte, i64 %keep) {
entry:
  call void @llvm.memset.inline.p0.i64(ptr %out, i8 %byte, i64 8, i1 false)
  %wide = zext i8 %byte to i64
  %r = xor i64 %keep, %wide
  %answer = xor i64 %r, 8
  ret i64 %answer
}
define i64 @inline_set_16(ptr %out, i8 %byte, i64 %keep) {
entry:
  call void @llvm.memset.inline.p0.i64(ptr %out, i8 %byte, i64 16, i1 false)
  %wide = zext i8 %byte to i64
  %r = xor i64 %keep, %wide
  %answer = xor i64 %r, 16
  ret i64 %answer
}
define i64 @inline_set_33(ptr %out, i8 %byte, i64 %keep) {
entry:
  call void @llvm.memset.inline.p0.i64(ptr %out, i8 %byte, i64 33, i1 false)
  %wide = zext i8 %byte to i64
  %r = xor i64 %keep, %wide
  %answer = xor i64 %r, 33
  ret i64 %answer
}
define i64 @inline_set_256(ptr %out, i8 %byte, i64 %keep) {
entry:
  call void @llvm.memset.inline.p0.i64(ptr %out, i8 %byte, i64 256, i1 false)
  %wide = zext i8 %byte to i64
  %r = xor i64 %keep, %wide
  %answer = xor i64 %r, 256
  ret i64 %answer
}
