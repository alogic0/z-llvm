declare i8 @llvm.smin.i8(i8, i8)
declare i8 @llvm.smax.i8(i8, i8)
declare void @boundary_fill(ptr)

define i8 @boundary_min() {
entry:
  %r = call i8 @llvm.smin.i8(i8 255, i8 1)
  ret i8 %r
}

define i8 @boundary_max() {
entry:
  %r = call i8 @llvm.smax.i8(i8 255, i8 1)
  ret i8 %r
}

define i128 @boundary_udiv127() {
entry:
  %r = udiv i127 -1, 2
  %wide = zext i127 %r to i128
  ret i128 %wide
}

define i128 @boundary_urem127() {
entry:
  %r = urem i127 -1, 2
  %wide = zext i127 %r to i128
  ret i128 %wide
}

define i128 @boundary_udiv128() {
entry:
  %r = udiv i128 -1, 1
  ret i128 %r
}

define i8 @boundary_alloca(i64 %n) {
entry:
  %count = add i64 %n, 1
  %buf = alloca i8, i64 %count, align 16
  call void @boundary_fill(ptr %buf)
  %last = getelementptr i8, ptr %buf, i64 %n
  %result = load i8, ptr %last
  ret i8 %result
}

define i8 @boundary_folded_alloca() {
entry:
  %count = add i64 31, 1
  %buf = alloca i8, i64 %count, align 16
  call void @boundary_fill(ptr %buf)
  %last = getelementptr i8, ptr %buf, i64 31
  %result = load i8, ptr %last
  ret i8 %result
}
