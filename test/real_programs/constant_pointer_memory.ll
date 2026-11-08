target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@constant_input = private constant [128 x i8] c"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF", align 16
@constant_output = internal global [128 x i8] zeroinitializer, align 64
@constant_alias = internal alias [128 x i8], ptr @constant_alias_next
@constant_alias_next = internal alias [128 x i8], ptr @constant_input
@constant_middle = external constant i8
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
declare void @llvm.memcpy.inline.p0.p0.i64(ptr, ptr, i64, i1)

define ptr @constant_pointer_output() {
entry:
  ret ptr @constant_output
}

define i64 @constant_pointer_copy3(ptr %destination, i64 %live) {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %destination, ptr noundef nonnull align 1 dereferenceable(3) getelementptr inbounds nuw (i8, ptr @constant_input, i64 9), i64 3, i1 false)
  ret i64 %live
}

define i64 @constant_pointer_copy7(ptr %source, i64 %live) {
entry:
  call void @llvm.memcpy.inline.p0.p0.i64(ptr align 1 getelementptr nuw (i8, ptr @constant_output, i64 11), ptr align 1 %source, i64 7, i1 false)
  ret i64 %live
}

define i64 @constant_pointer_alias(ptr %destination, i64 %live) {
entry:
  %keep = xor i64 %live, 123456789
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %destination, ptr align 1 getelementptr inbounds nuw (i8, ptr @constant_alias, i64 17), i64 31, i1 false)
  ret i64 %keep
}

define i64 @constant_pointer_negative(ptr %destination, i64 %live) {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %destination, ptr align 1 getelementptr nusw (i8, ptr @constant_middle, i64 -7), i64 1, i1 false)
  ret i64 %live
}

define i64 @constant_pointer_dynamic(i64 %a, i64 %length, i64 %b, ptr %destination, i64 %live) {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %destination, ptr align 1 getelementptr inbounds nuw (i8, ptr @constant_input, i64 23), i64 %length, i1 false)
  %first = xor i64 %a, %live
  %result = xor i64 %first, %b
  ret i64 %result
}

define i64 @constant_pointer_both(i64 %live) {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 getelementptr inbounds nuw (i8, ptr @constant_output, i64 1), ptr align 1 getelementptr inbounds nusw (i8, ptr @constant_input, i64 3), i64 64, i1 false)
  ret i64 %live
}
