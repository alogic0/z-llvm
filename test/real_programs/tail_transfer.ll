target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
declare i64 @tail_transfer_clobber(ptr,i64,i64,i64,i64,i64,i64,i64,i64,i64)
define internal signext i8 @tail_transfer_a_0(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call signext i8 @tail_transfer_b_0(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal signext i8 @tail_transfer_b_0(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call signext i8 @tail_transfer_a_0(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_0(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call signext i8 @tail_transfer_a_0(ptr @tail_transfer_b_0,ptr @tail_transfer_a_0,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out)
 %answer = sext i8 %r to i64
 ret i64 %answer
}
define internal signext i8 @tail_transfer_a_1(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call signext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal signext i8 @tail_transfer_b_1(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call signext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_1(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call signext i8 @tail_transfer_a_1(ptr @tail_transfer_b_1,ptr @tail_transfer_a_1,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out)
 %answer = sext i8 %r to i64
 ret i64 %answer
}
define internal fastcc signext i8 @tail_transfer_a_2(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i8 @tail_transfer_b_2(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal fastcc signext i8 @tail_transfer_b_2(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i8 @tail_transfer_a_2(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_2(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call fastcc signext i8 @tail_transfer_a_2(ptr @tail_transfer_b_2,ptr @tail_transfer_a_2,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out)
 %answer = sext i8 %r to i64
 ret i64 %answer
}
define internal fastcc signext i8 @tail_transfer_a_3(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal fastcc signext i8 @tail_transfer_b_3(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_3(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call fastcc signext i8 @tail_transfer_a_3(ptr @tail_transfer_b_3,ptr @tail_transfer_a_3,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out)
 %answer = sext i8 %r to i64
 ret i64 %answer
}
define internal void @tail_transfer_a_4(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void @tail_transfer_b_4(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_4(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void @tail_transfer_a_4(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_4(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 call void @tail_transfer_a_4(ptr @tail_transfer_b_4,ptr @tail_transfer_a_4,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal void @tail_transfer_a_5(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_5(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_5(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 call void @tail_transfer_a_5(ptr @tail_transfer_b_5,ptr @tail_transfer_a_5,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_6(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_b_6(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_6(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_a_6(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_6(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 call fastcc void @tail_transfer_a_6(ptr @tail_transfer_b_6,ptr @tail_transfer_a_6,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_7(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_7(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_7(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 call fastcc void @tail_transfer_a_7(ptr @tail_transfer_b_7,ptr @tail_transfer_a_7,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal ptr @tail_transfer_a_8(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_b_8(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_8(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_a_8(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_8(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call ptr @tail_transfer_a_8(ptr @tail_transfer_b_8,ptr @tail_transfer_a_8,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal ptr @tail_transfer_a_9(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_9(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_9(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call ptr @tail_transfer_a_9(ptr @tail_transfer_b_9,ptr @tail_transfer_a_9,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_10(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_b_10(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_10(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_a_10(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_10(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call fastcc ptr @tail_transfer_a_10(ptr @tail_transfer_b_10,ptr @tail_transfer_a_10,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_11(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_11(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_11(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call fastcc ptr @tail_transfer_a_11(ptr @tail_transfer_b_11,ptr @tail_transfer_a_11,i64 %n,i8 signext %a,i8 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal zeroext i8 @tail_transfer_a_12(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call zeroext i8 @tail_transfer_b_12(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal zeroext i8 @tail_transfer_b_12(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call zeroext i8 @tail_transfer_a_12(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_12(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call zeroext i8 @tail_transfer_a_12(ptr @tail_transfer_b_12,ptr @tail_transfer_a_12,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out)
 %answer = zext i8 %r to i64
 ret i64 %answer
}
define internal zeroext i8 @tail_transfer_a_13(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call zeroext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal zeroext i8 @tail_transfer_b_13(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call zeroext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_13(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call zeroext i8 @tail_transfer_a_13(ptr @tail_transfer_b_13,ptr @tail_transfer_a_13,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out)
 %answer = zext i8 %r to i64
 ret i64 %answer
}
define internal fastcc zeroext i8 @tail_transfer_a_14(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i8 @tail_transfer_b_14(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal fastcc zeroext i8 @tail_transfer_b_14(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i8 @tail_transfer_a_14(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_14(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call fastcc zeroext i8 @tail_transfer_a_14(ptr @tail_transfer_b_14,ptr @tail_transfer_a_14,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out)
 %answer = zext i8 %r to i64
 ret i64 %answer
}
define internal fastcc zeroext i8 @tail_transfer_a_15(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal fastcc zeroext i8 @tail_transfer_b_15(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_15(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call fastcc zeroext i8 @tail_transfer_a_15(ptr @tail_transfer_b_15,ptr @tail_transfer_a_15,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out)
 %answer = zext i8 %r to i64
 ret i64 %answer
}
define internal void @tail_transfer_a_16(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void @tail_transfer_b_16(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_16(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void @tail_transfer_a_16(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_16(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 call void @tail_transfer_a_16(ptr @tail_transfer_b_16,ptr @tail_transfer_a_16,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal void @tail_transfer_a_17(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_17(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_17(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 call void @tail_transfer_a_17(ptr @tail_transfer_b_17,ptr @tail_transfer_a_17,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_18(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_b_18(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_18(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_a_18(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_18(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 call fastcc void @tail_transfer_a_18(ptr @tail_transfer_b_18,ptr @tail_transfer_a_18,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_19(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_19(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_19(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 call fastcc void @tail_transfer_a_19(ptr @tail_transfer_b_19,ptr @tail_transfer_a_19,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal ptr @tail_transfer_a_20(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_b_20(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_20(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_a_20(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_20(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call ptr @tail_transfer_a_20(ptr @tail_transfer_b_20,ptr @tail_transfer_a_20,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal ptr @tail_transfer_a_21(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_21(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_21(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call ptr @tail_transfer_a_21(ptr @tail_transfer_b_21,ptr @tail_transfer_a_21,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_22(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_b_22(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_22(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_a_22(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_22(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call fastcc ptr @tail_transfer_a_22(ptr @tail_transfer_b_22,ptr @tail_transfer_a_22,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_23(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_23(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_23(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i8
 %r = call fastcc ptr @tail_transfer_a_23(ptr @tail_transfer_b_23,ptr @tail_transfer_a_23,i64 %n,i8 zeroext %a,i8 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal signext i16 @tail_transfer_a_24(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call signext i16 @tail_transfer_b_24(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal signext i16 @tail_transfer_b_24(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call signext i16 @tail_transfer_a_24(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_24(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call signext i16 @tail_transfer_a_24(ptr @tail_transfer_b_24,ptr @tail_transfer_a_24,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out)
 %answer = sext i16 %r to i64
 ret i64 %answer
}
define internal signext i16 @tail_transfer_a_25(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call signext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal signext i16 @tail_transfer_b_25(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call signext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_25(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call signext i16 @tail_transfer_a_25(ptr @tail_transfer_b_25,ptr @tail_transfer_a_25,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out)
 %answer = sext i16 %r to i64
 ret i64 %answer
}
define internal fastcc signext i16 @tail_transfer_a_26(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i16 @tail_transfer_b_26(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal fastcc signext i16 @tail_transfer_b_26(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i16 @tail_transfer_a_26(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_26(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call fastcc signext i16 @tail_transfer_a_26(ptr @tail_transfer_b_26,ptr @tail_transfer_a_26,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out)
 %answer = sext i16 %r to i64
 ret i64 %answer
}
define internal fastcc signext i16 @tail_transfer_a_27(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal fastcc signext i16 @tail_transfer_b_27(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_27(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call fastcc signext i16 @tail_transfer_a_27(ptr @tail_transfer_b_27,ptr @tail_transfer_a_27,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out)
 %answer = sext i16 %r to i64
 ret i64 %answer
}
define internal void @tail_transfer_a_28(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void @tail_transfer_b_28(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_28(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void @tail_transfer_a_28(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_28(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 call void @tail_transfer_a_28(ptr @tail_transfer_b_28,ptr @tail_transfer_a_28,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal void @tail_transfer_a_29(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_29(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_29(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 call void @tail_transfer_a_29(ptr @tail_transfer_b_29,ptr @tail_transfer_a_29,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_30(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_b_30(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_30(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_a_30(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_30(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 call fastcc void @tail_transfer_a_30(ptr @tail_transfer_b_30,ptr @tail_transfer_a_30,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_31(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_31(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_31(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 call fastcc void @tail_transfer_a_31(ptr @tail_transfer_b_31,ptr @tail_transfer_a_31,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal ptr @tail_transfer_a_32(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_b_32(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_32(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_a_32(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_32(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call ptr @tail_transfer_a_32(ptr @tail_transfer_b_32,ptr @tail_transfer_a_32,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal ptr @tail_transfer_a_33(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_33(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_33(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call ptr @tail_transfer_a_33(ptr @tail_transfer_b_33,ptr @tail_transfer_a_33,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_34(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_b_34(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_34(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_a_34(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_34(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call fastcc ptr @tail_transfer_a_34(ptr @tail_transfer_b_34,ptr @tail_transfer_a_34,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_35(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_35(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_35(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call fastcc ptr @tail_transfer_a_35(ptr @tail_transfer_b_35,ptr @tail_transfer_a_35,i64 %n,i16 signext %a,i16 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal zeroext i16 @tail_transfer_a_36(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call zeroext i16 @tail_transfer_b_36(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal zeroext i16 @tail_transfer_b_36(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call zeroext i16 @tail_transfer_a_36(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_36(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call zeroext i16 @tail_transfer_a_36(ptr @tail_transfer_b_36,ptr @tail_transfer_a_36,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out)
 %answer = zext i16 %r to i64
 ret i64 %answer
}
define internal zeroext i16 @tail_transfer_a_37(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call zeroext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal zeroext i16 @tail_transfer_b_37(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call zeroext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_37(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call zeroext i16 @tail_transfer_a_37(ptr @tail_transfer_b_37,ptr @tail_transfer_a_37,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out)
 %answer = zext i16 %r to i64
 ret i64 %answer
}
define internal fastcc zeroext i16 @tail_transfer_a_38(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i16 @tail_transfer_b_38(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal fastcc zeroext i16 @tail_transfer_b_38(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i16 @tail_transfer_a_38(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_38(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call fastcc zeroext i16 @tail_transfer_a_38(ptr @tail_transfer_b_38,ptr @tail_transfer_a_38,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out)
 %answer = zext i16 %r to i64
 ret i64 %answer
}
define internal fastcc zeroext i16 @tail_transfer_a_39(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal fastcc zeroext i16 @tail_transfer_b_39(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_39(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call fastcc zeroext i16 @tail_transfer_a_39(ptr @tail_transfer_b_39,ptr @tail_transfer_a_39,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out)
 %answer = zext i16 %r to i64
 ret i64 %answer
}
define internal void @tail_transfer_a_40(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void @tail_transfer_b_40(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_40(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void @tail_transfer_a_40(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_40(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 call void @tail_transfer_a_40(ptr @tail_transfer_b_40,ptr @tail_transfer_a_40,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal void @tail_transfer_a_41(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_41(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_41(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 call void @tail_transfer_a_41(ptr @tail_transfer_b_41,ptr @tail_transfer_a_41,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_42(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_b_42(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_42(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_a_42(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_42(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 call fastcc void @tail_transfer_a_42(ptr @tail_transfer_b_42,ptr @tail_transfer_a_42,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_43(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_43(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_43(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 call fastcc void @tail_transfer_a_43(ptr @tail_transfer_b_43,ptr @tail_transfer_a_43,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal ptr @tail_transfer_a_44(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_b_44(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_44(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_a_44(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_44(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call ptr @tail_transfer_a_44(ptr @tail_transfer_b_44,ptr @tail_transfer_a_44,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal ptr @tail_transfer_a_45(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_45(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_45(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call ptr @tail_transfer_a_45(ptr @tail_transfer_b_45,ptr @tail_transfer_a_45,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_46(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_b_46(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_46(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_a_46(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_46(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call fastcc ptr @tail_transfer_a_46(ptr @tail_transfer_b_46,ptr @tail_transfer_a_46,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_47(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_47(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_47(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i16
 %r = call fastcc ptr @tail_transfer_a_47(ptr @tail_transfer_b_47,ptr @tail_transfer_a_47,i64 %n,i16 zeroext %a,i16 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal i32 @tail_transfer_a_48(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call i32 @tail_transfer_b_48(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret i32 %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i32
 ret i32 %ret
}
define internal i32 @tail_transfer_b_48(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call i32 @tail_transfer_a_48(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret i32 %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i32
 ret i32 %ret
}
define i64 @tail_transfer_probe_48(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i32
 %b = trunc i64 %rawb to i32
 %r = call i32 @tail_transfer_a_48(ptr @tail_transfer_b_48,ptr @tail_transfer_a_48,i64 %n,i32 %a,i32 %b,ptr %out)
 %answer = zext i32 %r to i64
 ret i64 %answer
}
define internal i32 @tail_transfer_a_49(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call i32 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret i32 %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i32
 ret i32 %ret
}
define internal i32 @tail_transfer_b_49(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call i32 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret i32 %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i32
 ret i32 %ret
}
define i64 @tail_transfer_probe_49(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i32
 %b = trunc i64 %rawb to i32
 %r = call i32 @tail_transfer_a_49(ptr @tail_transfer_b_49,ptr @tail_transfer_a_49,i64 %n,i32 %a,i32 %b,ptr %out)
 %answer = zext i32 %r to i64
 ret i64 %answer
}
define internal fastcc i32 @tail_transfer_a_50(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call fastcc i32 @tail_transfer_b_50(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret i32 %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i32
 ret i32 %ret
}
define internal fastcc i32 @tail_transfer_b_50(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call fastcc i32 @tail_transfer_a_50(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret i32 %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i32
 ret i32 %ret
}
define i64 @tail_transfer_probe_50(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i32
 %b = trunc i64 %rawb to i32
 %r = call fastcc i32 @tail_transfer_a_50(ptr @tail_transfer_b_50,ptr @tail_transfer_a_50,i64 %n,i32 %a,i32 %b,ptr %out)
 %answer = zext i32 %r to i64
 ret i64 %answer
}
define internal fastcc i32 @tail_transfer_a_51(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call fastcc i32 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret i32 %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i32
 ret i32 %ret
}
define internal fastcc i32 @tail_transfer_b_51(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call fastcc i32 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret i32 %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i32
 ret i32 %ret
}
define i64 @tail_transfer_probe_51(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i32
 %b = trunc i64 %rawb to i32
 %r = call fastcc i32 @tail_transfer_a_51(ptr @tail_transfer_b_51,ptr @tail_transfer_a_51,i64 %n,i32 %a,i32 %b,ptr %out)
 %answer = zext i32 %r to i64
 ret i64 %answer
}
define internal void @tail_transfer_a_52(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 musttail call void @tail_transfer_b_52(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret void
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_52(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 musttail call void @tail_transfer_a_52(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret void
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_52(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i32
 %b = trunc i64 %rawb to i32
 call void @tail_transfer_a_52(ptr @tail_transfer_b_52,ptr @tail_transfer_a_52,i64 %n,i32 %a,i32 %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal void @tail_transfer_a_53(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret void
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_53(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret void
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_53(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i32
 %b = trunc i64 %rawb to i32
 call void @tail_transfer_a_53(ptr @tail_transfer_b_53,ptr @tail_transfer_a_53,i64 %n,i32 %a,i32 %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_54(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_b_54(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret void
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_54(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_a_54(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret void
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_54(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i32
 %b = trunc i64 %rawb to i32
 call fastcc void @tail_transfer_a_54(ptr @tail_transfer_b_54,ptr @tail_transfer_a_54,i64 %n,i32 %a,i32 %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_55(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret void
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_55(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret void
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_55(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i32
 %b = trunc i64 %rawb to i32
 call fastcc void @tail_transfer_a_55(ptr @tail_transfer_b_55,ptr @tail_transfer_a_55,i64 %n,i32 %a,i32 %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal ptr @tail_transfer_a_56(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_b_56(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_56(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_a_56(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_56(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i32
 %b = trunc i64 %rawb to i32
 %r = call ptr @tail_transfer_a_56(ptr @tail_transfer_b_56,ptr @tail_transfer_a_56,i64 %n,i32 %a,i32 %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal ptr @tail_transfer_a_57(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_57(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_57(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i32
 %b = trunc i64 %rawb to i32
 %r = call ptr @tail_transfer_a_57(ptr @tail_transfer_b_57,ptr @tail_transfer_a_57,i64 %n,i32 %a,i32 %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_58(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_b_58(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_58(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_a_58(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_58(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i32
 %b = trunc i64 %rawb to i32
 %r = call fastcc ptr @tail_transfer_a_58(ptr @tail_transfer_b_58,ptr @tail_transfer_a_58,i64 %n,i32 %a,i32 %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_59(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_59(ptr %nextfn,ptr %otherfn,i64 %n,i32 %a,i32 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i32 %a to i64
 %bw = zext i32 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i32
 %nb = trunc i64 %b1 to i32
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i32 %na,i32 %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i32 %a to i64
 %eb = zext i32 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_59(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i32
 %b = trunc i64 %rawb to i32
 %r = call fastcc ptr @tail_transfer_a_59(ptr @tail_transfer_b_59,ptr @tail_transfer_a_59,i64 %n,i32 %a,i32 %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal i64 @tail_transfer_a_60(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %count = sub i64 %n,1
 %r = musttail call i64 @tail_transfer_b_60(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret i64 %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret i64 %hash
}
define internal i64 @tail_transfer_b_60(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %count = sub i64 %n,1
 %r = musttail call i64 @tail_transfer_a_60(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret i64 %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret i64 %hash
}
define i64 @tail_transfer_probe_60(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %r = call i64 @tail_transfer_a_60(ptr @tail_transfer_b_60,ptr @tail_transfer_a_60,i64 %n,i64 %rawa,i64 %rawb,ptr %out)
 ret i64 %r
}
define internal i64 @tail_transfer_a_61(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %count = sub i64 %n,1
 %r = musttail call i64 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret i64 %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret i64 %hash
}
define internal i64 @tail_transfer_b_61(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %count = sub i64 %n,1
 %r = musttail call i64 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret i64 %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret i64 %hash
}
define i64 @tail_transfer_probe_61(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %r = call i64 @tail_transfer_a_61(ptr @tail_transfer_b_61,ptr @tail_transfer_a_61,i64 %n,i64 %rawa,i64 %rawb,ptr %out)
 ret i64 %r
}
define internal fastcc i64 @tail_transfer_a_62(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %count = sub i64 %n,1
 %r = musttail call fastcc i64 @tail_transfer_b_62(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret i64 %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret i64 %hash
}
define internal fastcc i64 @tail_transfer_b_62(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %count = sub i64 %n,1
 %r = musttail call fastcc i64 @tail_transfer_a_62(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret i64 %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret i64 %hash
}
define i64 @tail_transfer_probe_62(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %r = call fastcc i64 @tail_transfer_a_62(ptr @tail_transfer_b_62,ptr @tail_transfer_a_62,i64 %n,i64 %rawa,i64 %rawb,ptr %out)
 ret i64 %r
}
define internal fastcc i64 @tail_transfer_a_63(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %count = sub i64 %n,1
 %r = musttail call fastcc i64 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret i64 %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret i64 %hash
}
define internal fastcc i64 @tail_transfer_b_63(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %count = sub i64 %n,1
 %r = musttail call fastcc i64 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret i64 %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret i64 %hash
}
define i64 @tail_transfer_probe_63(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %r = call fastcc i64 @tail_transfer_a_63(ptr @tail_transfer_b_63,ptr @tail_transfer_a_63,i64 %n,i64 %rawa,i64 %rawb,ptr %out)
 ret i64 %r
}
define internal void @tail_transfer_a_64(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %count = sub i64 %n,1
 musttail call void @tail_transfer_b_64(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret void
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_64(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %count = sub i64 %n,1
 musttail call void @tail_transfer_a_64(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret void
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_64(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 call void @tail_transfer_a_64(ptr @tail_transfer_b_64,ptr @tail_transfer_a_64,i64 %n,i64 %rawa,i64 %rawb,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal void @tail_transfer_a_65(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret void
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_65(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret void
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_65(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 call void @tail_transfer_a_65(ptr @tail_transfer_b_65,ptr @tail_transfer_a_65,i64 %n,i64 %rawa,i64 %rawb,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_66(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_b_66(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret void
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_66(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_a_66(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret void
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_66(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 call fastcc void @tail_transfer_a_66(ptr @tail_transfer_b_66,ptr @tail_transfer_a_66,i64 %n,i64 %rawa,i64 %rawb,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_67(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret void
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_67(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret void
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_67(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 call fastcc void @tail_transfer_a_67(ptr @tail_transfer_b_67,ptr @tail_transfer_a_67,i64 %n,i64 %rawa,i64 %rawb,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal ptr @tail_transfer_a_68(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_b_68(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret ptr %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_68(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_a_68(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret ptr %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_68(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %r = call ptr @tail_transfer_a_68(ptr @tail_transfer_b_68,ptr @tail_transfer_a_68,i64 %n,i64 %rawa,i64 %rawb,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal ptr @tail_transfer_a_69(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret ptr %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_69(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret ptr %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_69(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %r = call ptr @tail_transfer_a_69(ptr @tail_transfer_b_69,ptr @tail_transfer_a_69,i64 %n,i64 %rawa,i64 %rawb,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_70(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_b_70(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret ptr %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_70(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_a_70(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret ptr %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_70(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %r = call fastcc ptr @tail_transfer_a_70(ptr @tail_transfer_b_70,ptr @tail_transfer_a_70,i64 %n,i64 %rawa,i64 %rawb,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_71(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret ptr %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_71(ptr %nextfn,ptr %otherfn,i64 %n,i64 %a,i64 %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = add i64 %a,0
 %bw = add i64 %b,0
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i64 %a1,i64 %b1,ptr %out)
 ret ptr %r
exit:
 %ea = add i64 %a,0
 %eb = add i64 %b,0
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_71(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %r = call fastcc ptr @tail_transfer_a_71(ptr @tail_transfer_b_71,ptr @tail_transfer_a_71,i64 %n,i64 %rawa,i64 %rawb,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal signext i8 @tail_transfer_a_72(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call signext i8 @tail_transfer_b_72(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal signext i8 @tail_transfer_b_72(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call signext i8 @tail_transfer_a_72(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_72(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call signext i8 @tail_transfer_a_72(ptr @tail_transfer_b_72,ptr @tail_transfer_a_72,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out)
 %answer = sext i8 %r to i64
 ret i64 %answer
}
define internal signext i8 @tail_transfer_a_73(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call signext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal signext i8 @tail_transfer_b_73(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call signext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_73(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call signext i8 @tail_transfer_a_73(ptr @tail_transfer_b_73,ptr @tail_transfer_a_73,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out)
 %answer = sext i8 %r to i64
 ret i64 %answer
}
define internal fastcc signext i8 @tail_transfer_a_74(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i8 @tail_transfer_b_74(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal fastcc signext i8 @tail_transfer_b_74(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i8 @tail_transfer_a_74(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_74(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call fastcc signext i8 @tail_transfer_a_74(ptr @tail_transfer_b_74,ptr @tail_transfer_a_74,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out)
 %answer = sext i8 %r to i64
 ret i64 %answer
}
define internal fastcc signext i8 @tail_transfer_a_75(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal fastcc signext i8 @tail_transfer_b_75(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_75(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call fastcc signext i8 @tail_transfer_a_75(ptr @tail_transfer_b_75,ptr @tail_transfer_a_75,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out)
 %answer = sext i8 %r to i64
 ret i64 %answer
}
define internal void @tail_transfer_a_76(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void @tail_transfer_b_76(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_76(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void @tail_transfer_a_76(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_76(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 call void @tail_transfer_a_76(ptr @tail_transfer_b_76,ptr @tail_transfer_a_76,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal void @tail_transfer_a_77(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_77(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_77(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 call void @tail_transfer_a_77(ptr @tail_transfer_b_77,ptr @tail_transfer_a_77,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_78(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_b_78(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_78(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_a_78(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_78(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 call fastcc void @tail_transfer_a_78(ptr @tail_transfer_b_78,ptr @tail_transfer_a_78,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_79(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_79(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_79(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 call fastcc void @tail_transfer_a_79(ptr @tail_transfer_b_79,ptr @tail_transfer_a_79,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal ptr @tail_transfer_a_80(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_b_80(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_80(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_a_80(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_80(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call ptr @tail_transfer_a_80(ptr @tail_transfer_b_80,ptr @tail_transfer_a_80,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal ptr @tail_transfer_a_81(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_81(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_81(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call ptr @tail_transfer_a_81(ptr @tail_transfer_b_81,ptr @tail_transfer_a_81,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_82(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_b_82(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_82(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_a_82(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_82(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call fastcc ptr @tail_transfer_a_82(ptr @tail_transfer_b_82,ptr @tail_transfer_a_82,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_83(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_83(ptr %nextfn,ptr %otherfn,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 signext %na,i16 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_83(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call fastcc ptr @tail_transfer_a_83(ptr @tail_transfer_b_83,ptr @tail_transfer_a_83,i64 %n,i8 signext %a,i16 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal zeroext i8 @tail_transfer_a_84(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call zeroext i8 @tail_transfer_b_84(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal zeroext i8 @tail_transfer_b_84(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call zeroext i8 @tail_transfer_a_84(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_84(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call zeroext i8 @tail_transfer_a_84(ptr @tail_transfer_b_84,ptr @tail_transfer_a_84,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out)
 %answer = zext i8 %r to i64
 ret i64 %answer
}
define internal zeroext i8 @tail_transfer_a_85(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call zeroext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal zeroext i8 @tail_transfer_b_85(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call zeroext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_85(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call zeroext i8 @tail_transfer_a_85(ptr @tail_transfer_b_85,ptr @tail_transfer_a_85,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out)
 %answer = zext i8 %r to i64
 ret i64 %answer
}
define internal fastcc zeroext i8 @tail_transfer_a_86(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i8 @tail_transfer_b_86(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal fastcc zeroext i8 @tail_transfer_b_86(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i8 @tail_transfer_a_86(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_86(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call fastcc zeroext i8 @tail_transfer_a_86(ptr @tail_transfer_b_86,ptr @tail_transfer_a_86,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out)
 %answer = zext i8 %r to i64
 ret i64 %answer
}
define internal fastcc zeroext i8 @tail_transfer_a_87(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define internal fastcc zeroext i8 @tail_transfer_b_87(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i8 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret i8 %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i8
 ret i8 %ret
}
define i64 @tail_transfer_probe_87(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call fastcc zeroext i8 @tail_transfer_a_87(ptr @tail_transfer_b_87,ptr @tail_transfer_a_87,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out)
 %answer = zext i8 %r to i64
 ret i64 %answer
}
define internal void @tail_transfer_a_88(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void @tail_transfer_b_88(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_88(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void @tail_transfer_a_88(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_88(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 call void @tail_transfer_a_88(ptr @tail_transfer_b_88,ptr @tail_transfer_a_88,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal void @tail_transfer_a_89(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_89(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_89(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 call void @tail_transfer_a_89(ptr @tail_transfer_b_89,ptr @tail_transfer_a_89,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_90(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_b_90(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_90(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_a_90(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_90(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 call fastcc void @tail_transfer_a_90(ptr @tail_transfer_b_90,ptr @tail_transfer_a_90,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_91(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_91(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_91(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 call fastcc void @tail_transfer_a_91(ptr @tail_transfer_b_91,ptr @tail_transfer_a_91,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal ptr @tail_transfer_a_92(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_b_92(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_92(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_a_92(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_92(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call ptr @tail_transfer_a_92(ptr @tail_transfer_b_92,ptr @tail_transfer_a_92,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal ptr @tail_transfer_a_93(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_93(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_93(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call ptr @tail_transfer_a_93(ptr @tail_transfer_b_93,ptr @tail_transfer_a_93,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_94(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_b_94(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_94(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_a_94(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_94(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call fastcc ptr @tail_transfer_a_94(ptr @tail_transfer_b_94,ptr @tail_transfer_a_94,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_95(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_95(ptr %nextfn,ptr %otherfn,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i8 %a to i64
 %bw = zext i16 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i8
 %nb = trunc i64 %b1 to i16
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i8 zeroext %na,i16 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i8 %a to i64
 %eb = zext i16 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_95(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i8
 %b = trunc i64 %rawb to i16
 %r = call fastcc ptr @tail_transfer_a_95(ptr @tail_transfer_b_95,ptr @tail_transfer_a_95,i64 %n,i8 zeroext %a,i16 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal signext i16 @tail_transfer_a_96(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call signext i16 @tail_transfer_b_96(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal signext i16 @tail_transfer_b_96(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call signext i16 @tail_transfer_a_96(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_96(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call signext i16 @tail_transfer_a_96(ptr @tail_transfer_b_96,ptr @tail_transfer_a_96,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out)
 %answer = sext i16 %r to i64
 ret i64 %answer
}
define internal signext i16 @tail_transfer_a_97(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call signext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal signext i16 @tail_transfer_b_97(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call signext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_97(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call signext i16 @tail_transfer_a_97(ptr @tail_transfer_b_97,ptr @tail_transfer_a_97,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out)
 %answer = sext i16 %r to i64
 ret i64 %answer
}
define internal fastcc signext i16 @tail_transfer_a_98(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i16 @tail_transfer_b_98(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal fastcc signext i16 @tail_transfer_b_98(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i16 @tail_transfer_a_98(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_98(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call fastcc signext i16 @tail_transfer_a_98(ptr @tail_transfer_b_98,ptr @tail_transfer_a_98,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out)
 %answer = sext i16 %r to i64
 ret i64 %answer
}
define internal fastcc signext i16 @tail_transfer_a_99(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal fastcc signext i16 @tail_transfer_b_99(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc signext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_99(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call fastcc signext i16 @tail_transfer_a_99(ptr @tail_transfer_b_99,ptr @tail_transfer_a_99,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out)
 %answer = sext i16 %r to i64
 ret i64 %answer
}
define internal void @tail_transfer_a_100(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void @tail_transfer_b_100(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_100(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void @tail_transfer_a_100(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_100(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 call void @tail_transfer_a_100(ptr @tail_transfer_b_100,ptr @tail_transfer_a_100,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal void @tail_transfer_a_101(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_101(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_101(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 call void @tail_transfer_a_101(ptr @tail_transfer_b_101,ptr @tail_transfer_a_101,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_102(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_b_102(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_102(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_a_102(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_102(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 call fastcc void @tail_transfer_a_102(ptr @tail_transfer_b_102,ptr @tail_transfer_a_102,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_103(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_103(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_103(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 call fastcc void @tail_transfer_a_103(ptr @tail_transfer_b_103,ptr @tail_transfer_a_103,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal ptr @tail_transfer_a_104(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_b_104(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_104(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_a_104(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_104(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call ptr @tail_transfer_a_104(ptr @tail_transfer_b_104,ptr @tail_transfer_a_104,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal ptr @tail_transfer_a_105(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_105(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_105(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call ptr @tail_transfer_a_105(ptr @tail_transfer_b_105,ptr @tail_transfer_a_105,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_106(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_b_106(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_106(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_a_106(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_106(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call fastcc ptr @tail_transfer_a_106(ptr @tail_transfer_b_106,ptr @tail_transfer_a_106,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_107(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_107(ptr %nextfn,ptr %otherfn,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 signext %na,i8 zeroext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_107(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call fastcc ptr @tail_transfer_a_107(ptr @tail_transfer_b_107,ptr @tail_transfer_a_107,i64 %n,i16 signext %a,i8 zeroext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal zeroext i16 @tail_transfer_a_108(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call zeroext i16 @tail_transfer_b_108(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal zeroext i16 @tail_transfer_b_108(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call zeroext i16 @tail_transfer_a_108(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_108(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call zeroext i16 @tail_transfer_a_108(ptr @tail_transfer_b_108,ptr @tail_transfer_a_108,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out)
 %answer = zext i16 %r to i64
 ret i64 %answer
}
define internal zeroext i16 @tail_transfer_a_109(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call zeroext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal zeroext i16 @tail_transfer_b_109(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call zeroext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_109(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call zeroext i16 @tail_transfer_a_109(ptr @tail_transfer_b_109,ptr @tail_transfer_a_109,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out)
 %answer = zext i16 %r to i64
 ret i64 %answer
}
define internal fastcc zeroext i16 @tail_transfer_a_110(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i16 @tail_transfer_b_110(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal fastcc zeroext i16 @tail_transfer_b_110(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i16 @tail_transfer_a_110(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_110(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call fastcc zeroext i16 @tail_transfer_a_110(ptr @tail_transfer_b_110,ptr @tail_transfer_a_110,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out)
 %answer = zext i16 %r to i64
 ret i64 %answer
}
define internal fastcc zeroext i16 @tail_transfer_a_111(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define internal fastcc zeroext i16 @tail_transfer_b_111(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc zeroext i16 %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret i16 %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 %ret = trunc i64 %hash to i16
 ret i16 %ret
}
define i64 @tail_transfer_probe_111(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call fastcc zeroext i16 @tail_transfer_a_111(ptr @tail_transfer_b_111,ptr @tail_transfer_a_111,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out)
 %answer = zext i16 %r to i64
 ret i64 %answer
}
define internal void @tail_transfer_a_112(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void @tail_transfer_b_112(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_112(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void @tail_transfer_a_112(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_112(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 call void @tail_transfer_a_112(ptr @tail_transfer_b_112,ptr @tail_transfer_a_112,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal void @tail_transfer_a_113(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal void @tail_transfer_b_113(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_113(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 call void @tail_transfer_a_113(ptr @tail_transfer_b_113,ptr @tail_transfer_a_113,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_114(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_b_114(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_114(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void @tail_transfer_a_114(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_114(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 call fastcc void @tail_transfer_a_114(ptr @tail_transfer_b_114,ptr @tail_transfer_a_114,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal fastcc void @tail_transfer_a_115(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret void
}
define internal fastcc void @tail_transfer_b_115(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 musttail call fastcc void %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret void
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret void
}
define i64 @tail_transfer_probe_115(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 call fastcc void @tail_transfer_a_115(ptr @tail_transfer_b_115,ptr @tail_transfer_a_115,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out)
 %p2 = getelementptr i8,ptr %out,i64 16
 %answer = load i64,ptr %p2,align 1
 ret i64 %answer
}
define internal ptr @tail_transfer_a_116(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_b_116(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_116(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr @tail_transfer_a_116(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_116(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call ptr @tail_transfer_a_116(ptr @tail_transfer_b_116,ptr @tail_transfer_a_116,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal ptr @tail_transfer_a_117(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal ptr @tail_transfer_b_117(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_117(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call ptr @tail_transfer_a_117(ptr @tail_transfer_b_117,ptr @tail_transfer_a_117,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_118(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_b_118(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_118(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr @tail_transfer_a_118(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_118(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call fastcc ptr @tail_transfer_a_118(ptr @tail_transfer_b_118,ptr @tail_transfer_a_118,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
define internal fastcc ptr @tail_transfer_a_119(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,17
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 1,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a0 = add i64 %aw,17
 %a1 = add i64 %a0,%clobber
 %b1 = xor i64 %bw,%aw
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 1,ptr %o3,align 1
 ret ptr %out
}
define internal fastcc ptr @tail_transfer_b_119(ptr %nextfn,ptr %otherfn,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out) noinline {
entry:
 %local = alloca [16 x i64],align 16
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %aw = zext i16 %a to i64
 %bw = zext i8 %b to i64
 %saved = add i64 %n,34
 store i64 %saved,ptr %local,align 8
 %clobber = call i64 @tail_transfer_clobber(ptr %local,i64 %aw,i64 %bw,i64 %n,i64 2,i64 1,i64 3,i64 5,i64 7,i64 9)
 %a1 = xor i64 %bw,%clobber
 %b1 = add i64 %aw,31
 %na = trunc i64 %a1 to i16
 %nb = trunc i64 %b1 to i8
 %count = sub i64 %n,1
 %r = musttail call fastcc ptr %nextfn(ptr %otherfn,ptr %nextfn,i64 %count,i16 zeroext %na,i8 signext %nb,ptr %out)
 ret ptr %r
exit:
 %ea = zext i16 %a to i64
 %eb = zext i8 %b to i64
 %product = mul i64 %ea,1099511628211
 %hash = xor i64 %product,%eb
 store i64 %ea,ptr %out,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %eb,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %hash,ptr %o2,align 1
 %o3 = getelementptr i8,ptr %out,i64 24
 store i64 2,ptr %o3,align 1
 ret ptr %out
}
define i64 @tail_transfer_probe_119(ptr %input,ptr %out,i64 %n) {
entry:
 %rawa = load i64,ptr %input,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %rawb = load i64,ptr %p1,align 1
 %a = trunc i64 %rawa to i16
 %b = trunc i64 %rawb to i8
 %r = call fastcc ptr @tail_transfer_a_119(ptr @tail_transfer_b_119,ptr @tail_transfer_a_119,i64 %n,i16 zeroext %a,i8 signext %b,ptr %out)
 %answer = ptrtoint ptr %r to i64
 ret i64 %answer
}
