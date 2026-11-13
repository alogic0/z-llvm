target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
%UnusedVaList = type { i32,i32,ptr,ptr }
declare void @llvm.va_start.p0(ptr)
declare void @llvm.va_end.p0(ptr)
declare void @llvm.va_copy.p0(ptr,ptr)
declare void @llvm.memcpy.p0.p0.i64(ptr,ptr,i64,i1)
define i32 @unused_variadic_body_0(i32 %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_1(i32 %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_2(i32 %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_3(i32 %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_4(i32 %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_5(i32 %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_6(i32 %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_7(i32 %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_8(i32 %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_9(i32 %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_10(i32 %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_11(i32 %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_12(i32 %0,i32 %1,i32 %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_13(i32 %0,i32 %1,i32 %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_14(i32 %0,i32 %1,i32 %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_15(i32 %0,i32 %1,i32 %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_16(i32 %0,i32 %1,i32 %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_17(i32 %0,i32 %1,i32 %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_18(i32 %0,i32 %1,i32 %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_19(i32 %0,i32 %1,i32 %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_20(i32 %0,i32 %1,i32 %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_21(i32 %0,i32 %1,i32 %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_22(i32 %0,i32 %1,i32 %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_23(i32 %0,i32 %1,i32 %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_24(i32 %0,i32 %1,i32 %2,i32 %3,i32 %4,i32 %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_25(i32 %0,i32 %1,i32 %2,i32 %3,i32 %4,i32 %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_26(i32 %0,i32 %1,i32 %2,i32 %3,i32 %4,i32 %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_27(i32 %0,i32 %1,i32 %2,i32 %3,i32 %4,i32 %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_28(i32 %0,i32 %1,i32 %2,i32 %3,i32 %4,i32 %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_29(i32 %0,i32 %1,i32 %2,i32 %3,i32 %4,i32 %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_30(i32 %0,i32 %1,i32 %2,i32 %3,i32 %4,i32 %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_31(i32 %0,i32 %1,i32 %2,i32 %3,i32 %4,i32 %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_32(i32 %0,i32 %1,i32 %2,i32 %3,i32 %4,i32 %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_33(i32 %0,i32 %1,i32 %2,i32 %3,i32 %4,i32 %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_34(i32 %0,i32 %1,i32 %2,i32 %3,i32 %4,i32 %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_35(i32 %0,i32 %1,i32 %2,i32 %3,i32 %4,i32 %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_36(i64 %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_37(i64 %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_38(i64 %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_39(i64 %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_40(i64 %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_41(i64 %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_42(i64 %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_43(i64 %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_44(i64 %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_45(i64 %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_46(i64 %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_47(i64 %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_48(i64 %0,i64 %1,i64 %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_49(i64 %0,i64 %1,i64 %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_50(i64 %0,i64 %1,i64 %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_51(i64 %0,i64 %1,i64 %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_52(i64 %0,i64 %1,i64 %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_53(i64 %0,i64 %1,i64 %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_54(i64 %0,i64 %1,i64 %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_55(i64 %0,i64 %1,i64 %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_56(i64 %0,i64 %1,i64 %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_57(i64 %0,i64 %1,i64 %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_58(i64 %0,i64 %1,i64 %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_59(i64 %0,i64 %1,i64 %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_60(i64 %0,i64 %1,i64 %2,i64 %3,i64 %4,i64 %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_61(i64 %0,i64 %1,i64 %2,i64 %3,i64 %4,i64 %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_62(i64 %0,i64 %1,i64 %2,i64 %3,i64 %4,i64 %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_63(i64 %0,i64 %1,i64 %2,i64 %3,i64 %4,i64 %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_64(i64 %0,i64 %1,i64 %2,i64 %3,i64 %4,i64 %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_65(i64 %0,i64 %1,i64 %2,i64 %3,i64 %4,i64 %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_66(i64 %0,i64 %1,i64 %2,i64 %3,i64 %4,i64 %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_67(i64 %0,i64 %1,i64 %2,i64 %3,i64 %4,i64 %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_68(i64 %0,i64 %1,i64 %2,i64 %3,i64 %4,i64 %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_69(i64 %0,i64 %1,i64 %2,i64 %3,i64 %4,i64 %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_70(i64 %0,i64 %1,i64 %2,i64 %3,i64 %4,i64 %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_71(i64 %0,i64 %1,i64 %2,i64 %3,i64 %4,i64 %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_72(ptr %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_73(ptr %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_74(ptr %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_75(ptr %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_76(ptr %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_77(ptr %0,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_78(ptr %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_79(ptr %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_80(ptr %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_81(ptr %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_82(ptr %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_83(ptr %0,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_84(ptr %0,ptr %1,ptr %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_85(ptr %0,ptr %1,ptr %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_86(ptr %0,ptr %1,ptr %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_87(ptr %0,ptr %1,ptr %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_88(ptr %0,ptr %1,ptr %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_89(ptr %0,ptr %1,ptr %2,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_90(ptr %0,ptr %1,ptr %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_91(ptr %0,ptr %1,ptr %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_92(ptr %0,ptr %1,ptr %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_93(ptr %0,ptr %1,ptr %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_94(ptr %0,ptr %1,ptr %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_95(ptr %0,ptr %1,ptr %2,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_96(ptr %0,ptr %1,ptr %2,ptr %3,ptr %4,ptr %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_97(ptr %0,ptr %1,ptr %2,ptr %3,ptr %4,ptr %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_98(ptr %0,ptr %1,ptr %2,ptr %3,ptr %4,ptr %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_99(ptr %0,ptr %1,ptr %2,ptr %3,ptr %4,ptr %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_100(ptr %0,ptr %1,ptr %2,ptr %3,ptr %4,ptr %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_101(ptr %0,ptr %1,ptr %2,ptr %3,ptr %4,ptr %5,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_102(ptr %0,ptr %1,ptr %2,ptr %3,ptr %4,ptr %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_103(ptr %0,ptr %1,ptr %2,ptr %3,ptr %4,ptr %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_104(ptr %0,ptr %1,ptr %2,ptr %3,ptr %4,ptr %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 8 dereferenceable(24) %copy,ptr nonnull align 8 dereferenceable(24) %list,i64 24,i1 false)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
define i32 @unused_variadic_body_105(ptr %0,ptr %1,ptr %2,ptr %3,ptr %4,ptr %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 %second = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %second
}
define i32 @unused_variadic_body_106(ptr %0,ptr %1,ptr %2,ptr %3,ptr %4,ptr %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %a = va_arg ptr %copy,ptr
 %b = va_arg ptr %copy,ptr
 %first = load i32,ptr %a,align 1
 %second = load i32,ptr %b,align 1
 %answer = add i32 %first,%second
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %answer
}
define i32 @unused_variadic_body_107(ptr %0,ptr %1,ptr %2,ptr %3,ptr %4,ptr %5,double %fp_unused,...) noinline {
entry:
 %list = alloca %UnusedVaList,align 8
 %copy = alloca %UnusedVaList,align 8
 call void @llvm.va_start.p0(ptr nonnull %list)
 call void @llvm.va_copy.p0(ptr nonnull %copy,ptr nonnull %list)
 %first = va_arg ptr %copy,i32
 call void @llvm.va_end.p0(ptr nonnull %copy)
 ret i32 %first
}
