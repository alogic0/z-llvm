target triple = "x86_64-unknown-linux-gnu"
declare void @llvm.va_start.p0(ptr)
declare void @llvm.va_end.p0(ptr)
declare void @llvm.va_copy.p0(ptr, ptr)
declare i64 @va_c_consume(ptr)
define i64 @va_sum_u64(i32 %count, ...) {
entry:
  %list = alloca [24 x i8], align 8
  call void @llvm.va_start.p0(ptr %list)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %next, %loop ]
  %sum = phi i64 [ 0, %entry ], [ %added, %loop ]
  %value = va_arg ptr %list, i64
  %added = add i64 %sum, %value
  %next = add i32 %i, 1
  %again = icmp ult i32 %next, %count
  br i1 %again, label %loop, label %exit
exit:
  call void @llvm.va_end.p0(ptr %list)
  ret i64 %added
}
define double @va_sum_f64(i32 %count, ...) {
entry:
  %list = alloca [24 x i8], align 8
  call void @llvm.va_start.p0(ptr %list)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %next, %loop ]
  %sum = phi double [ 0.000000e+00, %entry ], [ %added, %loop ]
  %value = va_arg ptr %list, double
  %added = fadd double %sum, %value
  %next = add i32 %i, 1
  %again = icmp ult i32 %next, %count
  br i1 %again, label %loop, label %exit
exit:
  call void @llvm.va_end.p0(ptr %list)
  ret double %added
}
define double @va_mixed(i32 %count, i64 %fixed_gp, double %fixed_fp, ...) {
entry:
  %list = alloca [24 x i8], align 8
  call void @llvm.va_start.p0(ptr %list)
  %fixed = uitofp i64 %fixed_gp to double
  %base = fadd double %fixed, %fixed_fp
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %next, %loop ]
  %sum = phi double [ %base, %entry ], [ %added, %loop ]
  %integer = va_arg ptr %list, i64
  %floating = va_arg ptr %list, double
  %converted = uitofp i64 %integer to double
  %pair = fadd double %converted, %floating
  %added = fadd double %sum, %pair
  %next = add i32 %i, 1
  %again = icmp ult i32 %next, %count
  br i1 %again, label %loop, label %exit
exit:
  call void @llvm.va_end.p0(ptr %list)
  ret double %added
}
define i64 @va_consume_record(ptr %list) {
entry:
  %a = va_arg ptr %list, i64
  %b = va_arg ptr %list, i64
  %sum = add i64 %a, %b
  ret i64 %sum
}
define i64 @va_copy_pair(i64 %fixed, ...) {
entry:
  %a = alloca [24 x i8], align 8
  %b = alloca [24 x i8], align 8
  call void @llvm.va_start.p0(ptr %a)
  call void @llvm.va_copy.p0(ptr %b, ptr %a)
  %sum = call i64 @va_consume_record(ptr %a)
  %weighted = mul i64 %sum, 17
  %c = call i64 @va_c_consume(ptr %b)
  %answer = add i64 %weighted, %c
  call void @llvm.va_end.p0(ptr %a)
  call void @llvm.va_end.p0(ptr %b)
  ret i64 %answer
}
define i64 @va_unfixed(...) {
entry:
  %list = alloca [24 x i8], align 8
  call void @llvm.va_start.p0(ptr %list)
  %a = va_arg ptr %list, i64
  %b = va_arg ptr %list, i64
  %sum = add i64 %a, %b
  call void @llvm.va_end.p0(ptr %list)
  ret i64 %sum
}
define i64 @va_call_unfixed(i64 %a, i64 %b) {
entry:
  %sum = call i64 (...) @va_unfixed(i64 %a, i64 %b)
  ret i64 %sum
}
