declare void @llvm.lifetime.start.p0(ptr)
declare void @llvm.lifetime.end.p0(ptr)
declare void @lifetime_fill(ptr, i64)
declare i64 @lifetime_check(ptr, i64)
define i64 @lifetime_sequential(i64 %seed) {
entry:
 %a0 = alloca [8192 x i8], align 16
 %a1 = alloca [8192 x i8], align 16
 %a2 = alloca [8192 x i8], align 16
 %a3 = alloca [8192 x i8], align 16
 %a4 = alloca [8192 x i8], align 16
 %a5 = alloca [8192 x i8], align 16
 %a6 = alloca [8192 x i8], align 16
 %a7 = alloca [8192 x i8], align 16
 %a8 = alloca [8192 x i8], align 16
 call void @llvm.lifetime.start.p0(ptr %a0)
 call void @lifetime_fill(ptr %a0, i64 %seed)
 call void @llvm.lifetime.start.p0(ptr %a1)
 %s1 = add i64 %seed, 1
 call void @lifetime_fill(ptr %a1, i64 %s1)
 %c1 = call i64 @lifetime_check(ptr %a1, i64 %s1)
 %g1 = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %e1 = or i64 %c1, %g1
 %b1 = or i64 0, %e1
 call void @llvm.lifetime.end.p0(ptr %a1)
 call void @llvm.lifetime.start.p0(ptr %a2)
 %s2 = add i64 %seed, 2
 call void @lifetime_fill(ptr %a2, i64 %s2)
 %c2 = call i64 @lifetime_check(ptr %a2, i64 %s2)
 %g2 = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %e2 = or i64 %c2, %g2
 %b2 = or i64 %b1, %e2
 call void @llvm.lifetime.end.p0(ptr %a2)
 call void @llvm.lifetime.start.p0(ptr %a3)
 %s3 = add i64 %seed, 3
 call void @lifetime_fill(ptr %a3, i64 %s3)
 %c3 = call i64 @lifetime_check(ptr %a3, i64 %s3)
 %g3 = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %e3 = or i64 %c3, %g3
 %b3 = or i64 %b2, %e3
 call void @llvm.lifetime.end.p0(ptr %a3)
 call void @llvm.lifetime.start.p0(ptr %a4)
 %s4 = add i64 %seed, 4
 call void @lifetime_fill(ptr %a4, i64 %s4)
 %c4 = call i64 @lifetime_check(ptr %a4, i64 %s4)
 %g4 = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %e4 = or i64 %c4, %g4
 %b4 = or i64 %b3, %e4
 call void @llvm.lifetime.end.p0(ptr %a4)
 call void @llvm.lifetime.start.p0(ptr %a5)
 %s5 = add i64 %seed, 5
 call void @lifetime_fill(ptr %a5, i64 %s5)
 %c5 = call i64 @lifetime_check(ptr %a5, i64 %s5)
 %g5 = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %e5 = or i64 %c5, %g5
 %b5 = or i64 %b4, %e5
 call void @llvm.lifetime.end.p0(ptr %a5)
 call void @llvm.lifetime.start.p0(ptr %a6)
 %s6 = add i64 %seed, 6
 call void @lifetime_fill(ptr %a6, i64 %s6)
 %c6 = call i64 @lifetime_check(ptr %a6, i64 %s6)
 %g6 = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %e6 = or i64 %c6, %g6
 %b6 = or i64 %b5, %e6
 call void @llvm.lifetime.end.p0(ptr %a6)
 call void @llvm.lifetime.start.p0(ptr %a7)
 %s7 = add i64 %seed, 7
 call void @lifetime_fill(ptr %a7, i64 %s7)
 %c7 = call i64 @lifetime_check(ptr %a7, i64 %s7)
 %g7 = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %e7 = or i64 %c7, %g7
 %b7 = or i64 %b6, %e7
 call void @llvm.lifetime.end.p0(ptr %a7)
 call void @llvm.lifetime.start.p0(ptr %a8)
 %s8 = add i64 %seed, 8
 call void @lifetime_fill(ptr %a8, i64 %s8)
 %c8 = call i64 @lifetime_check(ptr %a8, i64 %s8)
 %g8 = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %e8 = or i64 %c8, %g8
 %b8 = or i64 %b7, %e8
 call void @llvm.lifetime.end.p0(ptr %a8)
 call void @llvm.lifetime.end.p0(ptr %a0)
 ret i64 %b8
}
define i64 @lifetime_branches(i64 %seed) {
entry:
 %a0 = alloca [8192 x i8], align 16
 %a1 = alloca [8192 x i8], align 16
 %a2 = alloca [8192 x i8], align 16
 %a3 = alloca [8192 x i8], align 16
 %a4 = alloca [8192 x i8], align 16
 %a5 = alloca [8192 x i8], align 16
 %a6 = alloca [8192 x i8], align 16
 %a7 = alloca [8192 x i8], align 16
 %a8 = alloca [8192 x i8], align 16
 call void @llvm.lifetime.start.p0(ptr %a0)
 call void @lifetime_fill(ptr %a0, i64 %seed)
 br label %loop
loop:
 %index = phi i64 [ 0, %entry ], [ %next, %join ]
 %bad = phi i64 [ 0, %entry ], [ %combined, %join ]
 %bit = and i64 %index, 1
 %side = icmp eq i64 %bit, 0
 br i1 %side, label %left, label %right
left:
 call void @llvm.lifetime.start.p0(ptr %a1)
 call void @lifetime_fill(ptr %a1, i64 %index)
 %lc = call i64 @lifetime_check(ptr %a1, i64 %index)
 br label %join
right:
 call void @llvm.lifetime.start.p0(ptr %a2)
 call void @lifetime_fill(ptr %a2, i64 %index)
 %rc = call i64 @lifetime_check(ptr %a2, i64 %index)
 br label %join
join:
 %test = phi i64 [ %lc, %left ], [ %rc, %right ]
 call void @llvm.lifetime.end.p0(ptr %a1)
 call void @llvm.lifetime.end.p0(ptr %a2)
 %guard = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %partial = or i64 %test, %guard
 %combined = or i64 %bad, %partial
 %next = add i64 %index, 1
 %again = icmp ult i64 %next, 8
 br i1 %again, label %loop, label %exit
exit:
 call void @llvm.lifetime.start.p0(ptr %a3)
 %s3 = add i64 %seed, 3
 call void @lifetime_fill(ptr %a3, i64 %s3)
 %c3 = call i64 @lifetime_check(ptr %a3, i64 %s3)
 %g3 = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %e3 = or i64 %c3, %g3
 %b3 = or i64 %combined, %e3
 call void @llvm.lifetime.end.p0(ptr %a3)
 call void @llvm.lifetime.start.p0(ptr %a4)
 %s4 = add i64 %seed, 4
 call void @lifetime_fill(ptr %a4, i64 %s4)
 %c4 = call i64 @lifetime_check(ptr %a4, i64 %s4)
 %g4 = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %e4 = or i64 %c4, %g4
 %b4 = or i64 %b3, %e4
 call void @llvm.lifetime.end.p0(ptr %a4)
 call void @llvm.lifetime.start.p0(ptr %a5)
 %s5 = add i64 %seed, 5
 call void @lifetime_fill(ptr %a5, i64 %s5)
 %c5 = call i64 @lifetime_check(ptr %a5, i64 %s5)
 %g5 = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %e5 = or i64 %c5, %g5
 %b5 = or i64 %b4, %e5
 call void @llvm.lifetime.end.p0(ptr %a5)
 call void @llvm.lifetime.start.p0(ptr %a6)
 %s6 = add i64 %seed, 6
 call void @lifetime_fill(ptr %a6, i64 %s6)
 %c6 = call i64 @lifetime_check(ptr %a6, i64 %s6)
 %g6 = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %e6 = or i64 %c6, %g6
 %b6 = or i64 %b5, %e6
 call void @llvm.lifetime.end.p0(ptr %a6)
 call void @llvm.lifetime.start.p0(ptr %a7)
 %s7 = add i64 %seed, 7
 call void @lifetime_fill(ptr %a7, i64 %s7)
 %c7 = call i64 @lifetime_check(ptr %a7, i64 %s7)
 %g7 = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %e7 = or i64 %c7, %g7
 %b7 = or i64 %b6, %e7
 call void @llvm.lifetime.end.p0(ptr %a7)
 call void @llvm.lifetime.start.p0(ptr %a8)
 %s8 = add i64 %seed, 8
 call void @lifetime_fill(ptr %a8, i64 %s8)
 %c8 = call i64 @lifetime_check(ptr %a8, i64 %s8)
 %g8 = call i64 @lifetime_check(ptr %a0, i64 %seed)
 %e8 = or i64 %c8, %g8
 %b8 = or i64 %b7, %e8
 call void @llvm.lifetime.end.p0(ptr %a8)
 call void @llvm.lifetime.end.p0(ptr %a0)
 ret i64 %b8
}
