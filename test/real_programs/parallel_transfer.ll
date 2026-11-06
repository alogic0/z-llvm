target triple = "x86_64-unknown-linux-gnu"
@parallel_global = internal global [32840 x i8] zeroinitializer, align 8
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1 immarg)
declare void @llvm.memmove.p0.p0.i64(ptr, ptr, i64, i1 immarg)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1 immarg)
declare i64 @parallel_sink(i64, i64, i64, i64, i64, i64)
declare i64 @parallel_mixed_sink(i32, i64, i32)

define ptr @parallel_global_base() {
entry:
  ret ptr @parallel_global
}

define ptr @parallel_global_stride(i8 %index) {
entry:
  %wide = zext i8 %index to i64
  %pointer = getelementptr [128 x i8], ptr getelementptr (i8, ptr @parallel_global, i64 72), i64 %wide
  ret ptr %pointer
}

define i64 @parallel_left_ops(i64 %value, i64 %shift) {
entry:
  %product = mul i64 16, %value
  %difference = sub i64 19, %value
  %shifted = lshr i64 -1, %shift
  %combined = xor i64 %product, %difference
  %result = xor i64 %combined, %shifted
  ret i64 %result
}

define void @parallel_copy_swap(ptr %source, ptr %destination, i64 %length) {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr %destination, ptr %source, i64 %length, i1 false)
  ret void
}

define void @parallel_fill_rotate(i64 %length, ptr %destination, i8 %byte) {
entry:
  call void @llvm.memset.p0.i64(ptr %destination, i8 %byte, i64 %length, i1 false)
  ret void
}

define void @parallel_move_swap(ptr %source, ptr %destination, i64 %length) {
entry:
  call void @llvm.memmove.p0.p0.i64(ptr %destination, ptr %source, i64 %length, i1 false)
  ret void
}

define i64 @parallel_call_swap(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f) {
entry:
  %answer = call i64 @parallel_sink(i64 %b, i64 %a, i64 %c, i64 %f, i64 %d, i64 %e)
  %alias = xor i64 %a, %f
  %result = add i64 %answer, %alias
  ret i64 %result
}

define i64 @parallel_call_fanout(i64 %a, i64 %b, i64 %c) {
entry:
  %answer = call i64 @parallel_sink(i64 %c, i64 %a, i64 %b, i64 %a, i64 %c, i64 %b)
  ret i64 %answer
}

define i64 @parallel_call_mixed(i64 %a, i64 %b) {
entry:
  %lo = trunc i64 %a to i32
  %other = trunc i64 %b to i32
  %answer = call i64 @parallel_mixed_sink(i32 %other, i64 %a, i32 %lo)
  %result = add i64 %answer, %b
  ret i64 %result
}

define i64 @parallel_phi_rotate(i64 %a, i64 %b, i64 %c, i32 %count) {
entry:
  br label %loop
loop:
  %x = phi i64 [ %a, %entry ], [ %y, %body ]
  %y = phi i64 [ %b, %entry ], [ %z, %body ]
  %z = phi i64 [ %c, %entry ], [ %x, %body ]
  %i = phi i32 [ 0, %entry ], [ %next, %body ]
  %done = icmp eq i32 %i, %count
  br i1 %done, label %exit, label %body
body:
  %next = add i32 %i, 1
  br label %loop
exit:
  %middle = mul i64 %y, 3
  %high = mul i64 %z, 7
  %part = add i64 %x, %middle
  %answer = add i64 %part, %high
  ret i64 %answer
}
