target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@copy_destination = internal global [128 x i8] zeroinitializer, align 64
@copy_source = private constant [128 x i8] c"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF", align 16
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

define ptr @global_copy_destination() {
entry:
  ret ptr @copy_destination
}

define ptr @global_copy_source() {
entry:
  ret ptr @copy_source
}

define i64 @global_copy2(ptr %destination, i64 %live) {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %destination, ptr align 1 getelementptr (i8, ptr @copy_source, i64 5), i64 2, i1 false)
  ret i64 %live
}

define i64 @global_copy12(ptr %source, i64 %live) {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 getelementptr (i8, ptr @copy_destination, i64 17), ptr align 1 %source, i64 12, i1 false)
  ret i64 %live
}

define i64 @global_copy16(ptr %source, i64 %live) {
entry:
  %pair = alloca { ptr, i64 }, align 8
  %first = insertvalue { ptr, i64 } undef, ptr %source, 0
  %complete = insertvalue { ptr, i64 } %first, i64 %live, 1
  store { ptr, i64 } %complete, ptr %pair, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 getelementptr (i8, ptr @copy_destination, i64 32), ptr align 8 %pair, i64 16, i1 false)
  ret i64 %live
}

define i64 @global_copy80(i64 %live) {
entry:
  %keep = xor i64 %live, 123456789
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 getelementptr (i8, ptr @copy_destination, i64 48), ptr align 1 getelementptr (i8, ptr @copy_source, i64 7), i64 80, i1 false)
  ret i64 %keep
}

define i64 @global_store_scalars(i32 %value, i64 %live) {
entry:
  store i16 65535, ptr getelementptr (i8, ptr @copy_destination, i64 5), align 1
  %byte = trunc i32 %value to i8
  store i8 %byte, ptr getelementptr (i8, ptr @copy_destination, i64 17), align 1
  store i32 %value, ptr getelementptr (i8, ptr @copy_destination, i64 32), align 4
  ret i64 %live
}
