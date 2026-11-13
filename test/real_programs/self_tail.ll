target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define internal i8 @self_tail_body_0(i64 %n,i8 %p0,i8 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p0,34
 %answer = musttail call i8 @self_tail_body_0(i64 %next,i8 %left0,i8 %left1,ptr %out)
 ret i8 %answer
right:
 %right0 = xor i8 %p1,31
 %right1 = xor i8 %p0,62
 %right_answer = musttail call i8 @self_tail_body_0(i64 %next,i8 %right0,i8 %right1,ptr %out)
 ret i8 %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 %truncated = trunc i64 %r1 to i8
 ret i8 %truncated
}
define i64 @self_tail_probe_0(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %returned = call i8 @self_tail_body_0(i64 %count,i8 %v0,i8 %v1,ptr %out)
 %result = zext i8 %returned to i64
 ret i64 %result
}
define internal fastcc i8 @self_tail_body_1(i64 %n,i8 %p0,i8 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p0,34
 %answer = musttail call fastcc i8 @self_tail_body_1(i64 %next,i8 %left0,i8 %left1,ptr %out)
 ret i8 %answer
right:
 %right0 = xor i8 %p1,31
 %right1 = xor i8 %p0,62
 %right_answer = musttail call fastcc i8 @self_tail_body_1(i64 %next,i8 %right0,i8 %right1,ptr %out)
 ret i8 %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 %truncated = trunc i64 %r1 to i8
 ret i8 %truncated
}
define i64 @self_tail_probe_1(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %returned = call fastcc i8 @self_tail_body_1(i64 %count,i8 %v0,i8 %v1,ptr %out)
 %result = zext i8 %returned to i64
 ret i64 %result
}
define internal i8 @self_tail_body_2(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p0,85
 %answer = musttail call i8 @self_tail_body_2(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,ptr %out)
 ret i8 %answer
right:
 %right0 = xor i8 %p4,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right_answer = musttail call i8 @self_tail_body_2(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,ptr %out)
 ret i8 %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 %truncated = trunc i64 %r4 to i8
 ret i8 %truncated
}
define i64 @self_tail_probe_2(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %returned = call i8 @self_tail_body_2(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,ptr %out)
 %result = zext i8 %returned to i64
 ret i64 %result
}
define internal fastcc i8 @self_tail_body_3(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p0,85
 %answer = musttail call fastcc i8 @self_tail_body_3(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,ptr %out)
 ret i8 %answer
right:
 %right0 = xor i8 %p4,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right_answer = musttail call fastcc i8 @self_tail_body_3(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,ptr %out)
 ret i8 %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 %truncated = trunc i64 %r4 to i8
 ret i8 %truncated
}
define i64 @self_tail_probe_3(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %returned = call fastcc i8 @self_tail_body_3(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,ptr %out)
 %result = zext i8 %returned to i64
 ret i64 %result
}
define internal i8 @self_tail_body_4(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p0,136
 %answer = musttail call i8 @self_tail_body_4(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,ptr %out)
 ret i8 %answer
right:
 %right0 = xor i8 %p7,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right_answer = musttail call i8 @self_tail_body_4(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,ptr %out)
 ret i8 %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 %truncated = trunc i64 %r7 to i8
 ret i8 %truncated
}
define i64 @self_tail_probe_4(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %returned = call i8 @self_tail_body_4(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,ptr %out)
 %result = zext i8 %returned to i64
 ret i64 %result
}
define internal fastcc i8 @self_tail_body_5(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p0,136
 %answer = musttail call fastcc i8 @self_tail_body_5(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,ptr %out)
 ret i8 %answer
right:
 %right0 = xor i8 %p7,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right_answer = musttail call fastcc i8 @self_tail_body_5(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,ptr %out)
 ret i8 %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 %truncated = trunc i64 %r7 to i8
 ret i8 %truncated
}
define i64 @self_tail_probe_5(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %returned = call fastcc i8 @self_tail_body_5(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,ptr %out)
 %result = zext i8 %returned to i64
 ret i64 %result
}
define internal i8 @self_tail_body_6(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,i8 %p8,i8 %p9,i8 %p10,i8 %p11,i8 %p12,i8 %p13,i8 %p14,i8 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p8,136
 %left8 = add i8 %p9,153
 %left9 = add i8 %p10,170
 %left10 = add i8 %p11,187
 %left11 = add i8 %p12,204
 %left12 = add i8 %p13,221
 %left13 = add i8 %p14,238
 %left14 = add i8 %p15,255
 %left15 = add i8 %p0,16
 %answer = musttail call i8 @self_tail_body_6(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,i8 %left8,i8 %left9,i8 %left10,i8 %left11,i8 %left12,i8 %left13,i8 %left14,i8 %left15,ptr %out)
 ret i8 %answer
right:
 %right0 = xor i8 %p15,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right8 = xor i8 %p7,23
 %right9 = xor i8 %p8,54
 %right10 = xor i8 %p9,85
 %right11 = xor i8 %p10,116
 %right12 = xor i8 %p11,147
 %right13 = xor i8 %p12,178
 %right14 = xor i8 %p13,209
 %right15 = xor i8 %p14,240
 %right_answer = musttail call i8 @self_tail_body_6(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,i8 %right8,i8 %right9,i8 %right10,i8 %right11,i8 %right12,i8 %right13,i8 %right14,i8 %right15,ptr %out)
 ret i8 %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i8 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i8 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i8 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i8 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i8 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i8 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i8 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i8 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 %truncated = trunc i64 %r15 to i8
 ret i8 %truncated
}
define i64 @self_tail_probe_6(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i8
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i8
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i8
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i8
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i8
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i8
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i8
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i8
 %returned = call i8 @self_tail_body_6(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,i8 %v8,i8 %v9,i8 %v10,i8 %v11,i8 %v12,i8 %v13,i8 %v14,i8 %v15,ptr %out)
 %result = zext i8 %returned to i64
 ret i64 %result
}
define internal fastcc i8 @self_tail_body_7(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,i8 %p8,i8 %p9,i8 %p10,i8 %p11,i8 %p12,i8 %p13,i8 %p14,i8 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p8,136
 %left8 = add i8 %p9,153
 %left9 = add i8 %p10,170
 %left10 = add i8 %p11,187
 %left11 = add i8 %p12,204
 %left12 = add i8 %p13,221
 %left13 = add i8 %p14,238
 %left14 = add i8 %p15,255
 %left15 = add i8 %p0,16
 %answer = musttail call fastcc i8 @self_tail_body_7(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,i8 %left8,i8 %left9,i8 %left10,i8 %left11,i8 %left12,i8 %left13,i8 %left14,i8 %left15,ptr %out)
 ret i8 %answer
right:
 %right0 = xor i8 %p15,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right8 = xor i8 %p7,23
 %right9 = xor i8 %p8,54
 %right10 = xor i8 %p9,85
 %right11 = xor i8 %p10,116
 %right12 = xor i8 %p11,147
 %right13 = xor i8 %p12,178
 %right14 = xor i8 %p13,209
 %right15 = xor i8 %p14,240
 %right_answer = musttail call fastcc i8 @self_tail_body_7(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,i8 %right8,i8 %right9,i8 %right10,i8 %right11,i8 %right12,i8 %right13,i8 %right14,i8 %right15,ptr %out)
 ret i8 %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i8 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i8 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i8 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i8 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i8 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i8 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i8 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i8 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 %truncated = trunc i64 %r15 to i8
 ret i8 %truncated
}
define i64 @self_tail_probe_7(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i8
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i8
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i8
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i8
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i8
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i8
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i8
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i8
 %returned = call fastcc i8 @self_tail_body_7(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,i8 %v8,i8 %v9,i8 %v10,i8 %v11,i8 %v12,i8 %v13,i8 %v14,i8 %v15,ptr %out)
 %result = zext i8 %returned to i64
 ret i64 %result
}
define internal i8 @self_tail_body_8(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,i8 %p8,i8 %p9,i8 %p10,i8 %p11,i8 %p12,i8 %p13,i8 %p14,i8 %p15,i8 %p16,i8 %p17,i8 %p18,i8 %p19,i8 %p20,i8 %p21,i8 %p22,i8 %p23,i8 %p24,i8 %p25,i8 %p26,i8 %p27,i8 %p28,i8 %p29,i8 %p30,i8 %p31,i8 %p32,i8 %p33,i8 %p34,i8 %p35,i8 %p36,i8 %p37,i8 %p38,i8 %p39,i8 %p40,i8 %p41,i8 %p42,i8 %p43,i8 %p44,i8 %p45,i8 %p46,i8 %p47,i8 %p48,i8 %p49,i8 %p50,i8 %p51,i8 %p52,i8 %p53,i8 %p54,i8 %p55,i8 %p56,i8 %p57,i8 %p58,i8 %p59,i8 %p60,i8 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p8,136
 %left8 = add i8 %p9,153
 %left9 = add i8 %p10,170
 %left10 = add i8 %p11,187
 %left11 = add i8 %p12,204
 %left12 = add i8 %p13,221
 %left13 = add i8 %p14,238
 %left14 = add i8 %p15,255
 %left15 = add i8 %p16,16
 %left16 = add i8 %p17,33
 %left17 = add i8 %p18,50
 %left18 = add i8 %p19,67
 %left19 = add i8 %p20,84
 %left20 = add i8 %p21,101
 %left21 = add i8 %p22,118
 %left22 = add i8 %p23,135
 %left23 = add i8 %p24,152
 %left24 = add i8 %p25,169
 %left25 = add i8 %p26,186
 %left26 = add i8 %p27,203
 %left27 = add i8 %p28,220
 %left28 = add i8 %p29,237
 %left29 = add i8 %p30,254
 %left30 = add i8 %p31,15
 %left31 = add i8 %p32,32
 %left32 = add i8 %p33,49
 %left33 = add i8 %p34,66
 %left34 = add i8 %p35,83
 %left35 = add i8 %p36,100
 %left36 = add i8 %p37,117
 %left37 = add i8 %p38,134
 %left38 = add i8 %p39,151
 %left39 = add i8 %p40,168
 %left40 = add i8 %p41,185
 %left41 = add i8 %p42,202
 %left42 = add i8 %p43,219
 %left43 = add i8 %p44,236
 %left44 = add i8 %p45,253
 %left45 = add i8 %p46,14
 %left46 = add i8 %p47,31
 %left47 = add i8 %p48,48
 %left48 = add i8 %p49,65
 %left49 = add i8 %p50,82
 %left50 = add i8 %p51,99
 %left51 = add i8 %p52,116
 %left52 = add i8 %p53,133
 %left53 = add i8 %p54,150
 %left54 = add i8 %p55,167
 %left55 = add i8 %p56,184
 %left56 = add i8 %p57,201
 %left57 = add i8 %p58,218
 %left58 = add i8 %p59,235
 %left59 = add i8 %p60,252
 %left60 = add i8 %p61,13
 %left61 = add i8 %p0,30
 %answer = musttail call i8 @self_tail_body_8(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,i8 %left8,i8 %left9,i8 %left10,i8 %left11,i8 %left12,i8 %left13,i8 %left14,i8 %left15,i8 %left16,i8 %left17,i8 %left18,i8 %left19,i8 %left20,i8 %left21,i8 %left22,i8 %left23,i8 %left24,i8 %left25,i8 %left26,i8 %left27,i8 %left28,i8 %left29,i8 %left30,i8 %left31,i8 %left32,i8 %left33,i8 %left34,i8 %left35,i8 %left36,i8 %left37,i8 %left38,i8 %left39,i8 %left40,i8 %left41,i8 %left42,i8 %left43,i8 %left44,i8 %left45,i8 %left46,i8 %left47,i8 %left48,i8 %left49,i8 %left50,i8 %left51,i8 %left52,i8 %left53,i8 %left54,i8 %left55,i8 %left56,i8 %left57,i8 %left58,i8 %left59,i8 %left60,i8 %left61,ptr %out)
 ret i8 %answer
right:
 %right0 = xor i8 %p61,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right8 = xor i8 %p7,23
 %right9 = xor i8 %p8,54
 %right10 = xor i8 %p9,85
 %right11 = xor i8 %p10,116
 %right12 = xor i8 %p11,147
 %right13 = xor i8 %p12,178
 %right14 = xor i8 %p13,209
 %right15 = xor i8 %p14,240
 %right16 = xor i8 %p15,15
 %right17 = xor i8 %p16,46
 %right18 = xor i8 %p17,77
 %right19 = xor i8 %p18,108
 %right20 = xor i8 %p19,139
 %right21 = xor i8 %p20,170
 %right22 = xor i8 %p21,201
 %right23 = xor i8 %p22,232
 %right24 = xor i8 %p23,7
 %right25 = xor i8 %p24,38
 %right26 = xor i8 %p25,69
 %right27 = xor i8 %p26,100
 %right28 = xor i8 %p27,131
 %right29 = xor i8 %p28,162
 %right30 = xor i8 %p29,193
 %right31 = xor i8 %p30,224
 %right32 = xor i8 %p31,255
 %right33 = xor i8 %p32,30
 %right34 = xor i8 %p33,61
 %right35 = xor i8 %p34,92
 %right36 = xor i8 %p35,123
 %right37 = xor i8 %p36,154
 %right38 = xor i8 %p37,185
 %right39 = xor i8 %p38,216
 %right40 = xor i8 %p39,247
 %right41 = xor i8 %p40,22
 %right42 = xor i8 %p41,53
 %right43 = xor i8 %p42,84
 %right44 = xor i8 %p43,115
 %right45 = xor i8 %p44,146
 %right46 = xor i8 %p45,177
 %right47 = xor i8 %p46,208
 %right48 = xor i8 %p47,239
 %right49 = xor i8 %p48,14
 %right50 = xor i8 %p49,45
 %right51 = xor i8 %p50,76
 %right52 = xor i8 %p51,107
 %right53 = xor i8 %p52,138
 %right54 = xor i8 %p53,169
 %right55 = xor i8 %p54,200
 %right56 = xor i8 %p55,231
 %right57 = xor i8 %p56,6
 %right58 = xor i8 %p57,37
 %right59 = xor i8 %p58,68
 %right60 = xor i8 %p59,99
 %right61 = xor i8 %p60,130
 %right_answer = musttail call i8 @self_tail_body_8(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,i8 %right8,i8 %right9,i8 %right10,i8 %right11,i8 %right12,i8 %right13,i8 %right14,i8 %right15,i8 %right16,i8 %right17,i8 %right18,i8 %right19,i8 %right20,i8 %right21,i8 %right22,i8 %right23,i8 %right24,i8 %right25,i8 %right26,i8 %right27,i8 %right28,i8 %right29,i8 %right30,i8 %right31,i8 %right32,i8 %right33,i8 %right34,i8 %right35,i8 %right36,i8 %right37,i8 %right38,i8 %right39,i8 %right40,i8 %right41,i8 %right42,i8 %right43,i8 %right44,i8 %right45,i8 %right46,i8 %right47,i8 %right48,i8 %right49,i8 %right50,i8 %right51,i8 %right52,i8 %right53,i8 %right54,i8 %right55,i8 %right56,i8 %right57,i8 %right58,i8 %right59,i8 %right60,i8 %right61,ptr %out)
 ret i8 %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i8 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i8 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i8 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i8 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i8 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i8 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i8 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i8 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i8 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i8 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i8 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i8 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i8 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i8 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i8 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i8 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i8 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i8 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i8 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i8 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i8 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i8 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i8 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i8 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i8 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i8 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i8 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i8 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i8 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i8 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i8 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i8 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i8 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i8 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i8 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i8 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i8 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i8 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i8 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i8 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i8 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i8 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i8 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i8 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i8 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i8 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i8 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i8 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i8 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i8 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i8 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i8 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i8 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i8 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 %truncated = trunc i64 %r61 to i8
 ret i8 %truncated
}
define i64 @self_tail_probe_8(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i8
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i8
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i8
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i8
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i8
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i8
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i8
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i8
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i8
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i8
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i8
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i8
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i8
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i8
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i8
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i8
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i8
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i8
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i8
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i8
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i8
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i8
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i8
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i8
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i8
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i8
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i8
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i8
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i8
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i8
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i8
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i8
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i8
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i8
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i8
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i8
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i8
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i8
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i8
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i8
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i8
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i8
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i8
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i8
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i8
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i8
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i8
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i8
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i8
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i8
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i8
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i8
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i8
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i8
 %returned = call i8 @self_tail_body_8(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,i8 %v8,i8 %v9,i8 %v10,i8 %v11,i8 %v12,i8 %v13,i8 %v14,i8 %v15,i8 %v16,i8 %v17,i8 %v18,i8 %v19,i8 %v20,i8 %v21,i8 %v22,i8 %v23,i8 %v24,i8 %v25,i8 %v26,i8 %v27,i8 %v28,i8 %v29,i8 %v30,i8 %v31,i8 %v32,i8 %v33,i8 %v34,i8 %v35,i8 %v36,i8 %v37,i8 %v38,i8 %v39,i8 %v40,i8 %v41,i8 %v42,i8 %v43,i8 %v44,i8 %v45,i8 %v46,i8 %v47,i8 %v48,i8 %v49,i8 %v50,i8 %v51,i8 %v52,i8 %v53,i8 %v54,i8 %v55,i8 %v56,i8 %v57,i8 %v58,i8 %v59,i8 %v60,i8 %v61,ptr %out)
 %result = zext i8 %returned to i64
 ret i64 %result
}
define internal fastcc i8 @self_tail_body_9(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,i8 %p8,i8 %p9,i8 %p10,i8 %p11,i8 %p12,i8 %p13,i8 %p14,i8 %p15,i8 %p16,i8 %p17,i8 %p18,i8 %p19,i8 %p20,i8 %p21,i8 %p22,i8 %p23,i8 %p24,i8 %p25,i8 %p26,i8 %p27,i8 %p28,i8 %p29,i8 %p30,i8 %p31,i8 %p32,i8 %p33,i8 %p34,i8 %p35,i8 %p36,i8 %p37,i8 %p38,i8 %p39,i8 %p40,i8 %p41,i8 %p42,i8 %p43,i8 %p44,i8 %p45,i8 %p46,i8 %p47,i8 %p48,i8 %p49,i8 %p50,i8 %p51,i8 %p52,i8 %p53,i8 %p54,i8 %p55,i8 %p56,i8 %p57,i8 %p58,i8 %p59,i8 %p60,i8 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p8,136
 %left8 = add i8 %p9,153
 %left9 = add i8 %p10,170
 %left10 = add i8 %p11,187
 %left11 = add i8 %p12,204
 %left12 = add i8 %p13,221
 %left13 = add i8 %p14,238
 %left14 = add i8 %p15,255
 %left15 = add i8 %p16,16
 %left16 = add i8 %p17,33
 %left17 = add i8 %p18,50
 %left18 = add i8 %p19,67
 %left19 = add i8 %p20,84
 %left20 = add i8 %p21,101
 %left21 = add i8 %p22,118
 %left22 = add i8 %p23,135
 %left23 = add i8 %p24,152
 %left24 = add i8 %p25,169
 %left25 = add i8 %p26,186
 %left26 = add i8 %p27,203
 %left27 = add i8 %p28,220
 %left28 = add i8 %p29,237
 %left29 = add i8 %p30,254
 %left30 = add i8 %p31,15
 %left31 = add i8 %p32,32
 %left32 = add i8 %p33,49
 %left33 = add i8 %p34,66
 %left34 = add i8 %p35,83
 %left35 = add i8 %p36,100
 %left36 = add i8 %p37,117
 %left37 = add i8 %p38,134
 %left38 = add i8 %p39,151
 %left39 = add i8 %p40,168
 %left40 = add i8 %p41,185
 %left41 = add i8 %p42,202
 %left42 = add i8 %p43,219
 %left43 = add i8 %p44,236
 %left44 = add i8 %p45,253
 %left45 = add i8 %p46,14
 %left46 = add i8 %p47,31
 %left47 = add i8 %p48,48
 %left48 = add i8 %p49,65
 %left49 = add i8 %p50,82
 %left50 = add i8 %p51,99
 %left51 = add i8 %p52,116
 %left52 = add i8 %p53,133
 %left53 = add i8 %p54,150
 %left54 = add i8 %p55,167
 %left55 = add i8 %p56,184
 %left56 = add i8 %p57,201
 %left57 = add i8 %p58,218
 %left58 = add i8 %p59,235
 %left59 = add i8 %p60,252
 %left60 = add i8 %p61,13
 %left61 = add i8 %p0,30
 %answer = musttail call fastcc i8 @self_tail_body_9(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,i8 %left8,i8 %left9,i8 %left10,i8 %left11,i8 %left12,i8 %left13,i8 %left14,i8 %left15,i8 %left16,i8 %left17,i8 %left18,i8 %left19,i8 %left20,i8 %left21,i8 %left22,i8 %left23,i8 %left24,i8 %left25,i8 %left26,i8 %left27,i8 %left28,i8 %left29,i8 %left30,i8 %left31,i8 %left32,i8 %left33,i8 %left34,i8 %left35,i8 %left36,i8 %left37,i8 %left38,i8 %left39,i8 %left40,i8 %left41,i8 %left42,i8 %left43,i8 %left44,i8 %left45,i8 %left46,i8 %left47,i8 %left48,i8 %left49,i8 %left50,i8 %left51,i8 %left52,i8 %left53,i8 %left54,i8 %left55,i8 %left56,i8 %left57,i8 %left58,i8 %left59,i8 %left60,i8 %left61,ptr %out)
 ret i8 %answer
right:
 %right0 = xor i8 %p61,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right8 = xor i8 %p7,23
 %right9 = xor i8 %p8,54
 %right10 = xor i8 %p9,85
 %right11 = xor i8 %p10,116
 %right12 = xor i8 %p11,147
 %right13 = xor i8 %p12,178
 %right14 = xor i8 %p13,209
 %right15 = xor i8 %p14,240
 %right16 = xor i8 %p15,15
 %right17 = xor i8 %p16,46
 %right18 = xor i8 %p17,77
 %right19 = xor i8 %p18,108
 %right20 = xor i8 %p19,139
 %right21 = xor i8 %p20,170
 %right22 = xor i8 %p21,201
 %right23 = xor i8 %p22,232
 %right24 = xor i8 %p23,7
 %right25 = xor i8 %p24,38
 %right26 = xor i8 %p25,69
 %right27 = xor i8 %p26,100
 %right28 = xor i8 %p27,131
 %right29 = xor i8 %p28,162
 %right30 = xor i8 %p29,193
 %right31 = xor i8 %p30,224
 %right32 = xor i8 %p31,255
 %right33 = xor i8 %p32,30
 %right34 = xor i8 %p33,61
 %right35 = xor i8 %p34,92
 %right36 = xor i8 %p35,123
 %right37 = xor i8 %p36,154
 %right38 = xor i8 %p37,185
 %right39 = xor i8 %p38,216
 %right40 = xor i8 %p39,247
 %right41 = xor i8 %p40,22
 %right42 = xor i8 %p41,53
 %right43 = xor i8 %p42,84
 %right44 = xor i8 %p43,115
 %right45 = xor i8 %p44,146
 %right46 = xor i8 %p45,177
 %right47 = xor i8 %p46,208
 %right48 = xor i8 %p47,239
 %right49 = xor i8 %p48,14
 %right50 = xor i8 %p49,45
 %right51 = xor i8 %p50,76
 %right52 = xor i8 %p51,107
 %right53 = xor i8 %p52,138
 %right54 = xor i8 %p53,169
 %right55 = xor i8 %p54,200
 %right56 = xor i8 %p55,231
 %right57 = xor i8 %p56,6
 %right58 = xor i8 %p57,37
 %right59 = xor i8 %p58,68
 %right60 = xor i8 %p59,99
 %right61 = xor i8 %p60,130
 %right_answer = musttail call fastcc i8 @self_tail_body_9(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,i8 %right8,i8 %right9,i8 %right10,i8 %right11,i8 %right12,i8 %right13,i8 %right14,i8 %right15,i8 %right16,i8 %right17,i8 %right18,i8 %right19,i8 %right20,i8 %right21,i8 %right22,i8 %right23,i8 %right24,i8 %right25,i8 %right26,i8 %right27,i8 %right28,i8 %right29,i8 %right30,i8 %right31,i8 %right32,i8 %right33,i8 %right34,i8 %right35,i8 %right36,i8 %right37,i8 %right38,i8 %right39,i8 %right40,i8 %right41,i8 %right42,i8 %right43,i8 %right44,i8 %right45,i8 %right46,i8 %right47,i8 %right48,i8 %right49,i8 %right50,i8 %right51,i8 %right52,i8 %right53,i8 %right54,i8 %right55,i8 %right56,i8 %right57,i8 %right58,i8 %right59,i8 %right60,i8 %right61,ptr %out)
 ret i8 %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i8 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i8 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i8 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i8 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i8 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i8 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i8 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i8 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i8 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i8 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i8 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i8 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i8 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i8 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i8 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i8 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i8 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i8 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i8 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i8 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i8 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i8 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i8 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i8 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i8 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i8 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i8 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i8 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i8 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i8 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i8 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i8 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i8 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i8 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i8 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i8 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i8 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i8 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i8 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i8 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i8 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i8 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i8 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i8 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i8 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i8 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i8 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i8 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i8 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i8 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i8 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i8 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i8 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i8 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 %truncated = trunc i64 %r61 to i8
 ret i8 %truncated
}
define i64 @self_tail_probe_9(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i8
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i8
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i8
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i8
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i8
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i8
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i8
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i8
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i8
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i8
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i8
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i8
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i8
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i8
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i8
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i8
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i8
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i8
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i8
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i8
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i8
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i8
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i8
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i8
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i8
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i8
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i8
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i8
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i8
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i8
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i8
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i8
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i8
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i8
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i8
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i8
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i8
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i8
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i8
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i8
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i8
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i8
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i8
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i8
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i8
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i8
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i8
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i8
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i8
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i8
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i8
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i8
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i8
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i8
 %returned = call fastcc i8 @self_tail_body_9(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,i8 %v8,i8 %v9,i8 %v10,i8 %v11,i8 %v12,i8 %v13,i8 %v14,i8 %v15,i8 %v16,i8 %v17,i8 %v18,i8 %v19,i8 %v20,i8 %v21,i8 %v22,i8 %v23,i8 %v24,i8 %v25,i8 %v26,i8 %v27,i8 %v28,i8 %v29,i8 %v30,i8 %v31,i8 %v32,i8 %v33,i8 %v34,i8 %v35,i8 %v36,i8 %v37,i8 %v38,i8 %v39,i8 %v40,i8 %v41,i8 %v42,i8 %v43,i8 %v44,i8 %v45,i8 %v46,i8 %v47,i8 %v48,i8 %v49,i8 %v50,i8 %v51,i8 %v52,i8 %v53,i8 %v54,i8 %v55,i8 %v56,i8 %v57,i8 %v58,i8 %v59,i8 %v60,i8 %v61,ptr %out)
 %result = zext i8 %returned to i64
 ret i64 %result
}
define internal i16 @self_tail_body_10(i64 %n,i16 %p0,i16 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p0,34
 %answer = musttail call i16 @self_tail_body_10(i64 %next,i16 %left0,i16 %left1,ptr %out)
 ret i16 %answer
right:
 %right0 = xor i16 %p1,31
 %right1 = xor i16 %p0,62
 %right_answer = musttail call i16 @self_tail_body_10(i64 %next,i16 %right0,i16 %right1,ptr %out)
 ret i16 %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 %truncated = trunc i64 %r1 to i16
 ret i16 %truncated
}
define i64 @self_tail_probe_10(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %returned = call i16 @self_tail_body_10(i64 %count,i16 %v0,i16 %v1,ptr %out)
 %result = zext i16 %returned to i64
 ret i64 %result
}
define internal fastcc i16 @self_tail_body_11(i64 %n,i16 %p0,i16 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p0,34
 %answer = musttail call fastcc i16 @self_tail_body_11(i64 %next,i16 %left0,i16 %left1,ptr %out)
 ret i16 %answer
right:
 %right0 = xor i16 %p1,31
 %right1 = xor i16 %p0,62
 %right_answer = musttail call fastcc i16 @self_tail_body_11(i64 %next,i16 %right0,i16 %right1,ptr %out)
 ret i16 %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 %truncated = trunc i64 %r1 to i16
 ret i16 %truncated
}
define i64 @self_tail_probe_11(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %returned = call fastcc i16 @self_tail_body_11(i64 %count,i16 %v0,i16 %v1,ptr %out)
 %result = zext i16 %returned to i64
 ret i64 %result
}
define internal i16 @self_tail_body_12(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p0,85
 %answer = musttail call i16 @self_tail_body_12(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,ptr %out)
 ret i16 %answer
right:
 %right0 = xor i16 %p4,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right_answer = musttail call i16 @self_tail_body_12(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,ptr %out)
 ret i16 %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 %truncated = trunc i64 %r4 to i16
 ret i16 %truncated
}
define i64 @self_tail_probe_12(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %returned = call i16 @self_tail_body_12(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,ptr %out)
 %result = zext i16 %returned to i64
 ret i64 %result
}
define internal fastcc i16 @self_tail_body_13(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p0,85
 %answer = musttail call fastcc i16 @self_tail_body_13(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,ptr %out)
 ret i16 %answer
right:
 %right0 = xor i16 %p4,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right_answer = musttail call fastcc i16 @self_tail_body_13(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,ptr %out)
 ret i16 %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 %truncated = trunc i64 %r4 to i16
 ret i16 %truncated
}
define i64 @self_tail_probe_13(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %returned = call fastcc i16 @self_tail_body_13(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,ptr %out)
 %result = zext i16 %returned to i64
 ret i64 %result
}
define internal i16 @self_tail_body_14(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p0,136
 %answer = musttail call i16 @self_tail_body_14(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,ptr %out)
 ret i16 %answer
right:
 %right0 = xor i16 %p7,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right_answer = musttail call i16 @self_tail_body_14(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,ptr %out)
 ret i16 %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 %truncated = trunc i64 %r7 to i16
 ret i16 %truncated
}
define i64 @self_tail_probe_14(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %returned = call i16 @self_tail_body_14(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,ptr %out)
 %result = zext i16 %returned to i64
 ret i64 %result
}
define internal fastcc i16 @self_tail_body_15(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p0,136
 %answer = musttail call fastcc i16 @self_tail_body_15(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,ptr %out)
 ret i16 %answer
right:
 %right0 = xor i16 %p7,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right_answer = musttail call fastcc i16 @self_tail_body_15(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,ptr %out)
 ret i16 %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 %truncated = trunc i64 %r7 to i16
 ret i16 %truncated
}
define i64 @self_tail_probe_15(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %returned = call fastcc i16 @self_tail_body_15(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,ptr %out)
 %result = zext i16 %returned to i64
 ret i64 %result
}
define internal i16 @self_tail_body_16(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,i16 %p8,i16 %p9,i16 %p10,i16 %p11,i16 %p12,i16 %p13,i16 %p14,i16 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p8,136
 %left8 = add i16 %p9,153
 %left9 = add i16 %p10,170
 %left10 = add i16 %p11,187
 %left11 = add i16 %p12,204
 %left12 = add i16 %p13,221
 %left13 = add i16 %p14,238
 %left14 = add i16 %p15,255
 %left15 = add i16 %p0,272
 %answer = musttail call i16 @self_tail_body_16(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,i16 %left8,i16 %left9,i16 %left10,i16 %left11,i16 %left12,i16 %left13,i16 %left14,i16 %left15,ptr %out)
 ret i16 %answer
right:
 %right0 = xor i16 %p15,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right8 = xor i16 %p7,279
 %right9 = xor i16 %p8,310
 %right10 = xor i16 %p9,341
 %right11 = xor i16 %p10,372
 %right12 = xor i16 %p11,403
 %right13 = xor i16 %p12,434
 %right14 = xor i16 %p13,465
 %right15 = xor i16 %p14,496
 %right_answer = musttail call i16 @self_tail_body_16(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,i16 %right8,i16 %right9,i16 %right10,i16 %right11,i16 %right12,i16 %right13,i16 %right14,i16 %right15,ptr %out)
 ret i16 %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i16 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i16 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i16 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i16 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i16 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i16 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i16 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i16 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 %truncated = trunc i64 %r15 to i16
 ret i16 %truncated
}
define i64 @self_tail_probe_16(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i16
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i16
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i16
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i16
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i16
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i16
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i16
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i16
 %returned = call i16 @self_tail_body_16(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,i16 %v8,i16 %v9,i16 %v10,i16 %v11,i16 %v12,i16 %v13,i16 %v14,i16 %v15,ptr %out)
 %result = zext i16 %returned to i64
 ret i64 %result
}
define internal fastcc i16 @self_tail_body_17(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,i16 %p8,i16 %p9,i16 %p10,i16 %p11,i16 %p12,i16 %p13,i16 %p14,i16 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p8,136
 %left8 = add i16 %p9,153
 %left9 = add i16 %p10,170
 %left10 = add i16 %p11,187
 %left11 = add i16 %p12,204
 %left12 = add i16 %p13,221
 %left13 = add i16 %p14,238
 %left14 = add i16 %p15,255
 %left15 = add i16 %p0,272
 %answer = musttail call fastcc i16 @self_tail_body_17(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,i16 %left8,i16 %left9,i16 %left10,i16 %left11,i16 %left12,i16 %left13,i16 %left14,i16 %left15,ptr %out)
 ret i16 %answer
right:
 %right0 = xor i16 %p15,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right8 = xor i16 %p7,279
 %right9 = xor i16 %p8,310
 %right10 = xor i16 %p9,341
 %right11 = xor i16 %p10,372
 %right12 = xor i16 %p11,403
 %right13 = xor i16 %p12,434
 %right14 = xor i16 %p13,465
 %right15 = xor i16 %p14,496
 %right_answer = musttail call fastcc i16 @self_tail_body_17(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,i16 %right8,i16 %right9,i16 %right10,i16 %right11,i16 %right12,i16 %right13,i16 %right14,i16 %right15,ptr %out)
 ret i16 %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i16 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i16 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i16 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i16 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i16 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i16 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i16 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i16 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 %truncated = trunc i64 %r15 to i16
 ret i16 %truncated
}
define i64 @self_tail_probe_17(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i16
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i16
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i16
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i16
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i16
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i16
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i16
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i16
 %returned = call fastcc i16 @self_tail_body_17(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,i16 %v8,i16 %v9,i16 %v10,i16 %v11,i16 %v12,i16 %v13,i16 %v14,i16 %v15,ptr %out)
 %result = zext i16 %returned to i64
 ret i64 %result
}
define internal i16 @self_tail_body_18(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,i16 %p8,i16 %p9,i16 %p10,i16 %p11,i16 %p12,i16 %p13,i16 %p14,i16 %p15,i16 %p16,i16 %p17,i16 %p18,i16 %p19,i16 %p20,i16 %p21,i16 %p22,i16 %p23,i16 %p24,i16 %p25,i16 %p26,i16 %p27,i16 %p28,i16 %p29,i16 %p30,i16 %p31,i16 %p32,i16 %p33,i16 %p34,i16 %p35,i16 %p36,i16 %p37,i16 %p38,i16 %p39,i16 %p40,i16 %p41,i16 %p42,i16 %p43,i16 %p44,i16 %p45,i16 %p46,i16 %p47,i16 %p48,i16 %p49,i16 %p50,i16 %p51,i16 %p52,i16 %p53,i16 %p54,i16 %p55,i16 %p56,i16 %p57,i16 %p58,i16 %p59,i16 %p60,i16 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p8,136
 %left8 = add i16 %p9,153
 %left9 = add i16 %p10,170
 %left10 = add i16 %p11,187
 %left11 = add i16 %p12,204
 %left12 = add i16 %p13,221
 %left13 = add i16 %p14,238
 %left14 = add i16 %p15,255
 %left15 = add i16 %p16,272
 %left16 = add i16 %p17,289
 %left17 = add i16 %p18,306
 %left18 = add i16 %p19,323
 %left19 = add i16 %p20,340
 %left20 = add i16 %p21,357
 %left21 = add i16 %p22,374
 %left22 = add i16 %p23,391
 %left23 = add i16 %p24,408
 %left24 = add i16 %p25,425
 %left25 = add i16 %p26,442
 %left26 = add i16 %p27,459
 %left27 = add i16 %p28,476
 %left28 = add i16 %p29,493
 %left29 = add i16 %p30,510
 %left30 = add i16 %p31,527
 %left31 = add i16 %p32,544
 %left32 = add i16 %p33,561
 %left33 = add i16 %p34,578
 %left34 = add i16 %p35,595
 %left35 = add i16 %p36,612
 %left36 = add i16 %p37,629
 %left37 = add i16 %p38,646
 %left38 = add i16 %p39,663
 %left39 = add i16 %p40,680
 %left40 = add i16 %p41,697
 %left41 = add i16 %p42,714
 %left42 = add i16 %p43,731
 %left43 = add i16 %p44,748
 %left44 = add i16 %p45,765
 %left45 = add i16 %p46,782
 %left46 = add i16 %p47,799
 %left47 = add i16 %p48,816
 %left48 = add i16 %p49,833
 %left49 = add i16 %p50,850
 %left50 = add i16 %p51,867
 %left51 = add i16 %p52,884
 %left52 = add i16 %p53,901
 %left53 = add i16 %p54,918
 %left54 = add i16 %p55,935
 %left55 = add i16 %p56,952
 %left56 = add i16 %p57,969
 %left57 = add i16 %p58,986
 %left58 = add i16 %p59,1003
 %left59 = add i16 %p60,1020
 %left60 = add i16 %p61,1037
 %left61 = add i16 %p0,1054
 %answer = musttail call i16 @self_tail_body_18(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,i16 %left8,i16 %left9,i16 %left10,i16 %left11,i16 %left12,i16 %left13,i16 %left14,i16 %left15,i16 %left16,i16 %left17,i16 %left18,i16 %left19,i16 %left20,i16 %left21,i16 %left22,i16 %left23,i16 %left24,i16 %left25,i16 %left26,i16 %left27,i16 %left28,i16 %left29,i16 %left30,i16 %left31,i16 %left32,i16 %left33,i16 %left34,i16 %left35,i16 %left36,i16 %left37,i16 %left38,i16 %left39,i16 %left40,i16 %left41,i16 %left42,i16 %left43,i16 %left44,i16 %left45,i16 %left46,i16 %left47,i16 %left48,i16 %left49,i16 %left50,i16 %left51,i16 %left52,i16 %left53,i16 %left54,i16 %left55,i16 %left56,i16 %left57,i16 %left58,i16 %left59,i16 %left60,i16 %left61,ptr %out)
 ret i16 %answer
right:
 %right0 = xor i16 %p61,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right8 = xor i16 %p7,279
 %right9 = xor i16 %p8,310
 %right10 = xor i16 %p9,341
 %right11 = xor i16 %p10,372
 %right12 = xor i16 %p11,403
 %right13 = xor i16 %p12,434
 %right14 = xor i16 %p13,465
 %right15 = xor i16 %p14,496
 %right16 = xor i16 %p15,527
 %right17 = xor i16 %p16,558
 %right18 = xor i16 %p17,589
 %right19 = xor i16 %p18,620
 %right20 = xor i16 %p19,651
 %right21 = xor i16 %p20,682
 %right22 = xor i16 %p21,713
 %right23 = xor i16 %p22,744
 %right24 = xor i16 %p23,775
 %right25 = xor i16 %p24,806
 %right26 = xor i16 %p25,837
 %right27 = xor i16 %p26,868
 %right28 = xor i16 %p27,899
 %right29 = xor i16 %p28,930
 %right30 = xor i16 %p29,961
 %right31 = xor i16 %p30,992
 %right32 = xor i16 %p31,1023
 %right33 = xor i16 %p32,1054
 %right34 = xor i16 %p33,1085
 %right35 = xor i16 %p34,1116
 %right36 = xor i16 %p35,1147
 %right37 = xor i16 %p36,1178
 %right38 = xor i16 %p37,1209
 %right39 = xor i16 %p38,1240
 %right40 = xor i16 %p39,1271
 %right41 = xor i16 %p40,1302
 %right42 = xor i16 %p41,1333
 %right43 = xor i16 %p42,1364
 %right44 = xor i16 %p43,1395
 %right45 = xor i16 %p44,1426
 %right46 = xor i16 %p45,1457
 %right47 = xor i16 %p46,1488
 %right48 = xor i16 %p47,1519
 %right49 = xor i16 %p48,1550
 %right50 = xor i16 %p49,1581
 %right51 = xor i16 %p50,1612
 %right52 = xor i16 %p51,1643
 %right53 = xor i16 %p52,1674
 %right54 = xor i16 %p53,1705
 %right55 = xor i16 %p54,1736
 %right56 = xor i16 %p55,1767
 %right57 = xor i16 %p56,1798
 %right58 = xor i16 %p57,1829
 %right59 = xor i16 %p58,1860
 %right60 = xor i16 %p59,1891
 %right61 = xor i16 %p60,1922
 %right_answer = musttail call i16 @self_tail_body_18(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,i16 %right8,i16 %right9,i16 %right10,i16 %right11,i16 %right12,i16 %right13,i16 %right14,i16 %right15,i16 %right16,i16 %right17,i16 %right18,i16 %right19,i16 %right20,i16 %right21,i16 %right22,i16 %right23,i16 %right24,i16 %right25,i16 %right26,i16 %right27,i16 %right28,i16 %right29,i16 %right30,i16 %right31,i16 %right32,i16 %right33,i16 %right34,i16 %right35,i16 %right36,i16 %right37,i16 %right38,i16 %right39,i16 %right40,i16 %right41,i16 %right42,i16 %right43,i16 %right44,i16 %right45,i16 %right46,i16 %right47,i16 %right48,i16 %right49,i16 %right50,i16 %right51,i16 %right52,i16 %right53,i16 %right54,i16 %right55,i16 %right56,i16 %right57,i16 %right58,i16 %right59,i16 %right60,i16 %right61,ptr %out)
 ret i16 %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i16 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i16 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i16 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i16 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i16 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i16 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i16 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i16 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i16 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i16 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i16 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i16 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i16 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i16 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i16 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i16 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i16 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i16 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i16 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i16 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i16 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i16 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i16 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i16 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i16 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i16 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i16 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i16 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i16 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i16 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i16 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i16 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i16 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i16 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i16 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i16 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i16 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i16 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i16 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i16 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i16 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i16 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i16 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i16 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i16 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i16 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i16 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i16 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i16 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i16 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i16 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i16 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i16 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i16 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 %truncated = trunc i64 %r61 to i16
 ret i16 %truncated
}
define i64 @self_tail_probe_18(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i16
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i16
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i16
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i16
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i16
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i16
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i16
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i16
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i16
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i16
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i16
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i16
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i16
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i16
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i16
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i16
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i16
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i16
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i16
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i16
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i16
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i16
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i16
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i16
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i16
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i16
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i16
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i16
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i16
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i16
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i16
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i16
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i16
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i16
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i16
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i16
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i16
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i16
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i16
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i16
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i16
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i16
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i16
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i16
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i16
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i16
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i16
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i16
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i16
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i16
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i16
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i16
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i16
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i16
 %returned = call i16 @self_tail_body_18(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,i16 %v8,i16 %v9,i16 %v10,i16 %v11,i16 %v12,i16 %v13,i16 %v14,i16 %v15,i16 %v16,i16 %v17,i16 %v18,i16 %v19,i16 %v20,i16 %v21,i16 %v22,i16 %v23,i16 %v24,i16 %v25,i16 %v26,i16 %v27,i16 %v28,i16 %v29,i16 %v30,i16 %v31,i16 %v32,i16 %v33,i16 %v34,i16 %v35,i16 %v36,i16 %v37,i16 %v38,i16 %v39,i16 %v40,i16 %v41,i16 %v42,i16 %v43,i16 %v44,i16 %v45,i16 %v46,i16 %v47,i16 %v48,i16 %v49,i16 %v50,i16 %v51,i16 %v52,i16 %v53,i16 %v54,i16 %v55,i16 %v56,i16 %v57,i16 %v58,i16 %v59,i16 %v60,i16 %v61,ptr %out)
 %result = zext i16 %returned to i64
 ret i64 %result
}
define internal fastcc i16 @self_tail_body_19(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,i16 %p8,i16 %p9,i16 %p10,i16 %p11,i16 %p12,i16 %p13,i16 %p14,i16 %p15,i16 %p16,i16 %p17,i16 %p18,i16 %p19,i16 %p20,i16 %p21,i16 %p22,i16 %p23,i16 %p24,i16 %p25,i16 %p26,i16 %p27,i16 %p28,i16 %p29,i16 %p30,i16 %p31,i16 %p32,i16 %p33,i16 %p34,i16 %p35,i16 %p36,i16 %p37,i16 %p38,i16 %p39,i16 %p40,i16 %p41,i16 %p42,i16 %p43,i16 %p44,i16 %p45,i16 %p46,i16 %p47,i16 %p48,i16 %p49,i16 %p50,i16 %p51,i16 %p52,i16 %p53,i16 %p54,i16 %p55,i16 %p56,i16 %p57,i16 %p58,i16 %p59,i16 %p60,i16 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p8,136
 %left8 = add i16 %p9,153
 %left9 = add i16 %p10,170
 %left10 = add i16 %p11,187
 %left11 = add i16 %p12,204
 %left12 = add i16 %p13,221
 %left13 = add i16 %p14,238
 %left14 = add i16 %p15,255
 %left15 = add i16 %p16,272
 %left16 = add i16 %p17,289
 %left17 = add i16 %p18,306
 %left18 = add i16 %p19,323
 %left19 = add i16 %p20,340
 %left20 = add i16 %p21,357
 %left21 = add i16 %p22,374
 %left22 = add i16 %p23,391
 %left23 = add i16 %p24,408
 %left24 = add i16 %p25,425
 %left25 = add i16 %p26,442
 %left26 = add i16 %p27,459
 %left27 = add i16 %p28,476
 %left28 = add i16 %p29,493
 %left29 = add i16 %p30,510
 %left30 = add i16 %p31,527
 %left31 = add i16 %p32,544
 %left32 = add i16 %p33,561
 %left33 = add i16 %p34,578
 %left34 = add i16 %p35,595
 %left35 = add i16 %p36,612
 %left36 = add i16 %p37,629
 %left37 = add i16 %p38,646
 %left38 = add i16 %p39,663
 %left39 = add i16 %p40,680
 %left40 = add i16 %p41,697
 %left41 = add i16 %p42,714
 %left42 = add i16 %p43,731
 %left43 = add i16 %p44,748
 %left44 = add i16 %p45,765
 %left45 = add i16 %p46,782
 %left46 = add i16 %p47,799
 %left47 = add i16 %p48,816
 %left48 = add i16 %p49,833
 %left49 = add i16 %p50,850
 %left50 = add i16 %p51,867
 %left51 = add i16 %p52,884
 %left52 = add i16 %p53,901
 %left53 = add i16 %p54,918
 %left54 = add i16 %p55,935
 %left55 = add i16 %p56,952
 %left56 = add i16 %p57,969
 %left57 = add i16 %p58,986
 %left58 = add i16 %p59,1003
 %left59 = add i16 %p60,1020
 %left60 = add i16 %p61,1037
 %left61 = add i16 %p0,1054
 %answer = musttail call fastcc i16 @self_tail_body_19(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,i16 %left8,i16 %left9,i16 %left10,i16 %left11,i16 %left12,i16 %left13,i16 %left14,i16 %left15,i16 %left16,i16 %left17,i16 %left18,i16 %left19,i16 %left20,i16 %left21,i16 %left22,i16 %left23,i16 %left24,i16 %left25,i16 %left26,i16 %left27,i16 %left28,i16 %left29,i16 %left30,i16 %left31,i16 %left32,i16 %left33,i16 %left34,i16 %left35,i16 %left36,i16 %left37,i16 %left38,i16 %left39,i16 %left40,i16 %left41,i16 %left42,i16 %left43,i16 %left44,i16 %left45,i16 %left46,i16 %left47,i16 %left48,i16 %left49,i16 %left50,i16 %left51,i16 %left52,i16 %left53,i16 %left54,i16 %left55,i16 %left56,i16 %left57,i16 %left58,i16 %left59,i16 %left60,i16 %left61,ptr %out)
 ret i16 %answer
right:
 %right0 = xor i16 %p61,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right8 = xor i16 %p7,279
 %right9 = xor i16 %p8,310
 %right10 = xor i16 %p9,341
 %right11 = xor i16 %p10,372
 %right12 = xor i16 %p11,403
 %right13 = xor i16 %p12,434
 %right14 = xor i16 %p13,465
 %right15 = xor i16 %p14,496
 %right16 = xor i16 %p15,527
 %right17 = xor i16 %p16,558
 %right18 = xor i16 %p17,589
 %right19 = xor i16 %p18,620
 %right20 = xor i16 %p19,651
 %right21 = xor i16 %p20,682
 %right22 = xor i16 %p21,713
 %right23 = xor i16 %p22,744
 %right24 = xor i16 %p23,775
 %right25 = xor i16 %p24,806
 %right26 = xor i16 %p25,837
 %right27 = xor i16 %p26,868
 %right28 = xor i16 %p27,899
 %right29 = xor i16 %p28,930
 %right30 = xor i16 %p29,961
 %right31 = xor i16 %p30,992
 %right32 = xor i16 %p31,1023
 %right33 = xor i16 %p32,1054
 %right34 = xor i16 %p33,1085
 %right35 = xor i16 %p34,1116
 %right36 = xor i16 %p35,1147
 %right37 = xor i16 %p36,1178
 %right38 = xor i16 %p37,1209
 %right39 = xor i16 %p38,1240
 %right40 = xor i16 %p39,1271
 %right41 = xor i16 %p40,1302
 %right42 = xor i16 %p41,1333
 %right43 = xor i16 %p42,1364
 %right44 = xor i16 %p43,1395
 %right45 = xor i16 %p44,1426
 %right46 = xor i16 %p45,1457
 %right47 = xor i16 %p46,1488
 %right48 = xor i16 %p47,1519
 %right49 = xor i16 %p48,1550
 %right50 = xor i16 %p49,1581
 %right51 = xor i16 %p50,1612
 %right52 = xor i16 %p51,1643
 %right53 = xor i16 %p52,1674
 %right54 = xor i16 %p53,1705
 %right55 = xor i16 %p54,1736
 %right56 = xor i16 %p55,1767
 %right57 = xor i16 %p56,1798
 %right58 = xor i16 %p57,1829
 %right59 = xor i16 %p58,1860
 %right60 = xor i16 %p59,1891
 %right61 = xor i16 %p60,1922
 %right_answer = musttail call fastcc i16 @self_tail_body_19(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,i16 %right8,i16 %right9,i16 %right10,i16 %right11,i16 %right12,i16 %right13,i16 %right14,i16 %right15,i16 %right16,i16 %right17,i16 %right18,i16 %right19,i16 %right20,i16 %right21,i16 %right22,i16 %right23,i16 %right24,i16 %right25,i16 %right26,i16 %right27,i16 %right28,i16 %right29,i16 %right30,i16 %right31,i16 %right32,i16 %right33,i16 %right34,i16 %right35,i16 %right36,i16 %right37,i16 %right38,i16 %right39,i16 %right40,i16 %right41,i16 %right42,i16 %right43,i16 %right44,i16 %right45,i16 %right46,i16 %right47,i16 %right48,i16 %right49,i16 %right50,i16 %right51,i16 %right52,i16 %right53,i16 %right54,i16 %right55,i16 %right56,i16 %right57,i16 %right58,i16 %right59,i16 %right60,i16 %right61,ptr %out)
 ret i16 %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i16 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i16 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i16 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i16 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i16 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i16 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i16 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i16 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i16 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i16 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i16 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i16 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i16 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i16 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i16 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i16 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i16 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i16 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i16 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i16 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i16 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i16 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i16 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i16 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i16 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i16 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i16 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i16 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i16 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i16 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i16 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i16 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i16 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i16 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i16 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i16 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i16 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i16 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i16 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i16 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i16 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i16 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i16 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i16 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i16 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i16 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i16 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i16 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i16 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i16 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i16 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i16 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i16 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i16 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 %truncated = trunc i64 %r61 to i16
 ret i16 %truncated
}
define i64 @self_tail_probe_19(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i16
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i16
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i16
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i16
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i16
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i16
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i16
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i16
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i16
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i16
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i16
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i16
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i16
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i16
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i16
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i16
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i16
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i16
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i16
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i16
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i16
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i16
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i16
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i16
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i16
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i16
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i16
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i16
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i16
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i16
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i16
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i16
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i16
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i16
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i16
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i16
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i16
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i16
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i16
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i16
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i16
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i16
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i16
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i16
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i16
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i16
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i16
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i16
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i16
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i16
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i16
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i16
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i16
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i16
 %returned = call fastcc i16 @self_tail_body_19(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,i16 %v8,i16 %v9,i16 %v10,i16 %v11,i16 %v12,i16 %v13,i16 %v14,i16 %v15,i16 %v16,i16 %v17,i16 %v18,i16 %v19,i16 %v20,i16 %v21,i16 %v22,i16 %v23,i16 %v24,i16 %v25,i16 %v26,i16 %v27,i16 %v28,i16 %v29,i16 %v30,i16 %v31,i16 %v32,i16 %v33,i16 %v34,i16 %v35,i16 %v36,i16 %v37,i16 %v38,i16 %v39,i16 %v40,i16 %v41,i16 %v42,i16 %v43,i16 %v44,i16 %v45,i16 %v46,i16 %v47,i16 %v48,i16 %v49,i16 %v50,i16 %v51,i16 %v52,i16 %v53,i16 %v54,i16 %v55,i16 %v56,i16 %v57,i16 %v58,i16 %v59,i16 %v60,i16 %v61,ptr %out)
 %result = zext i16 %returned to i64
 ret i64 %result
}
define internal i32 @self_tail_body_20(i64 %n,i32 %p0,i32 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p0,34
 %answer = musttail call i32 @self_tail_body_20(i64 %next,i32 %left0,i32 %left1,ptr %out)
 ret i32 %answer
right:
 %right0 = xor i32 %p1,31
 %right1 = xor i32 %p0,62
 %right_answer = musttail call i32 @self_tail_body_20(i64 %next,i32 %right0,i32 %right1,ptr %out)
 ret i32 %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 %truncated = trunc i64 %r1 to i32
 ret i32 %truncated
}
define i64 @self_tail_probe_20(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %returned = call i32 @self_tail_body_20(i64 %count,i32 %v0,i32 %v1,ptr %out)
 %result = zext i32 %returned to i64
 ret i64 %result
}
define internal fastcc i32 @self_tail_body_21(i64 %n,i32 %p0,i32 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p0,34
 %answer = musttail call fastcc i32 @self_tail_body_21(i64 %next,i32 %left0,i32 %left1,ptr %out)
 ret i32 %answer
right:
 %right0 = xor i32 %p1,31
 %right1 = xor i32 %p0,62
 %right_answer = musttail call fastcc i32 @self_tail_body_21(i64 %next,i32 %right0,i32 %right1,ptr %out)
 ret i32 %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 %truncated = trunc i64 %r1 to i32
 ret i32 %truncated
}
define i64 @self_tail_probe_21(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %returned = call fastcc i32 @self_tail_body_21(i64 %count,i32 %v0,i32 %v1,ptr %out)
 %result = zext i32 %returned to i64
 ret i64 %result
}
define internal i32 @self_tail_body_22(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p0,85
 %answer = musttail call i32 @self_tail_body_22(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,ptr %out)
 ret i32 %answer
right:
 %right0 = xor i32 %p4,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right_answer = musttail call i32 @self_tail_body_22(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,ptr %out)
 ret i32 %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 %truncated = trunc i64 %r4 to i32
 ret i32 %truncated
}
define i64 @self_tail_probe_22(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %returned = call i32 @self_tail_body_22(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,ptr %out)
 %result = zext i32 %returned to i64
 ret i64 %result
}
define internal fastcc i32 @self_tail_body_23(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p0,85
 %answer = musttail call fastcc i32 @self_tail_body_23(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,ptr %out)
 ret i32 %answer
right:
 %right0 = xor i32 %p4,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right_answer = musttail call fastcc i32 @self_tail_body_23(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,ptr %out)
 ret i32 %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 %truncated = trunc i64 %r4 to i32
 ret i32 %truncated
}
define i64 @self_tail_probe_23(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %returned = call fastcc i32 @self_tail_body_23(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,ptr %out)
 %result = zext i32 %returned to i64
 ret i64 %result
}
define internal i32 @self_tail_body_24(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p0,136
 %answer = musttail call i32 @self_tail_body_24(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,ptr %out)
 ret i32 %answer
right:
 %right0 = xor i32 %p7,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right_answer = musttail call i32 @self_tail_body_24(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,ptr %out)
 ret i32 %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 %truncated = trunc i64 %r7 to i32
 ret i32 %truncated
}
define i64 @self_tail_probe_24(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %returned = call i32 @self_tail_body_24(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,ptr %out)
 %result = zext i32 %returned to i64
 ret i64 %result
}
define internal fastcc i32 @self_tail_body_25(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p0,136
 %answer = musttail call fastcc i32 @self_tail_body_25(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,ptr %out)
 ret i32 %answer
right:
 %right0 = xor i32 %p7,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right_answer = musttail call fastcc i32 @self_tail_body_25(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,ptr %out)
 ret i32 %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 %truncated = trunc i64 %r7 to i32
 ret i32 %truncated
}
define i64 @self_tail_probe_25(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %returned = call fastcc i32 @self_tail_body_25(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,ptr %out)
 %result = zext i32 %returned to i64
 ret i64 %result
}
define internal i32 @self_tail_body_26(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,i32 %p8,i32 %p9,i32 %p10,i32 %p11,i32 %p12,i32 %p13,i32 %p14,i32 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p8,136
 %left8 = add i32 %p9,153
 %left9 = add i32 %p10,170
 %left10 = add i32 %p11,187
 %left11 = add i32 %p12,204
 %left12 = add i32 %p13,221
 %left13 = add i32 %p14,238
 %left14 = add i32 %p15,255
 %left15 = add i32 %p0,272
 %answer = musttail call i32 @self_tail_body_26(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,i32 %left8,i32 %left9,i32 %left10,i32 %left11,i32 %left12,i32 %left13,i32 %left14,i32 %left15,ptr %out)
 ret i32 %answer
right:
 %right0 = xor i32 %p15,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right8 = xor i32 %p7,279
 %right9 = xor i32 %p8,310
 %right10 = xor i32 %p9,341
 %right11 = xor i32 %p10,372
 %right12 = xor i32 %p11,403
 %right13 = xor i32 %p12,434
 %right14 = xor i32 %p13,465
 %right15 = xor i32 %p14,496
 %right_answer = musttail call i32 @self_tail_body_26(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,i32 %right8,i32 %right9,i32 %right10,i32 %right11,i32 %right12,i32 %right13,i32 %right14,i32 %right15,ptr %out)
 ret i32 %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i32 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i32 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i32 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i32 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i32 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i32 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i32 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i32 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 %truncated = trunc i64 %r15 to i32
 ret i32 %truncated
}
define i64 @self_tail_probe_26(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i32
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i32
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i32
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i32
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i32
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i32
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i32
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i32
 %returned = call i32 @self_tail_body_26(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,i32 %v8,i32 %v9,i32 %v10,i32 %v11,i32 %v12,i32 %v13,i32 %v14,i32 %v15,ptr %out)
 %result = zext i32 %returned to i64
 ret i64 %result
}
define internal fastcc i32 @self_tail_body_27(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,i32 %p8,i32 %p9,i32 %p10,i32 %p11,i32 %p12,i32 %p13,i32 %p14,i32 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p8,136
 %left8 = add i32 %p9,153
 %left9 = add i32 %p10,170
 %left10 = add i32 %p11,187
 %left11 = add i32 %p12,204
 %left12 = add i32 %p13,221
 %left13 = add i32 %p14,238
 %left14 = add i32 %p15,255
 %left15 = add i32 %p0,272
 %answer = musttail call fastcc i32 @self_tail_body_27(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,i32 %left8,i32 %left9,i32 %left10,i32 %left11,i32 %left12,i32 %left13,i32 %left14,i32 %left15,ptr %out)
 ret i32 %answer
right:
 %right0 = xor i32 %p15,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right8 = xor i32 %p7,279
 %right9 = xor i32 %p8,310
 %right10 = xor i32 %p9,341
 %right11 = xor i32 %p10,372
 %right12 = xor i32 %p11,403
 %right13 = xor i32 %p12,434
 %right14 = xor i32 %p13,465
 %right15 = xor i32 %p14,496
 %right_answer = musttail call fastcc i32 @self_tail_body_27(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,i32 %right8,i32 %right9,i32 %right10,i32 %right11,i32 %right12,i32 %right13,i32 %right14,i32 %right15,ptr %out)
 ret i32 %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i32 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i32 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i32 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i32 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i32 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i32 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i32 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i32 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 %truncated = trunc i64 %r15 to i32
 ret i32 %truncated
}
define i64 @self_tail_probe_27(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i32
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i32
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i32
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i32
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i32
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i32
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i32
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i32
 %returned = call fastcc i32 @self_tail_body_27(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,i32 %v8,i32 %v9,i32 %v10,i32 %v11,i32 %v12,i32 %v13,i32 %v14,i32 %v15,ptr %out)
 %result = zext i32 %returned to i64
 ret i64 %result
}
define internal i32 @self_tail_body_28(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,i32 %p8,i32 %p9,i32 %p10,i32 %p11,i32 %p12,i32 %p13,i32 %p14,i32 %p15,i32 %p16,i32 %p17,i32 %p18,i32 %p19,i32 %p20,i32 %p21,i32 %p22,i32 %p23,i32 %p24,i32 %p25,i32 %p26,i32 %p27,i32 %p28,i32 %p29,i32 %p30,i32 %p31,i32 %p32,i32 %p33,i32 %p34,i32 %p35,i32 %p36,i32 %p37,i32 %p38,i32 %p39,i32 %p40,i32 %p41,i32 %p42,i32 %p43,i32 %p44,i32 %p45,i32 %p46,i32 %p47,i32 %p48,i32 %p49,i32 %p50,i32 %p51,i32 %p52,i32 %p53,i32 %p54,i32 %p55,i32 %p56,i32 %p57,i32 %p58,i32 %p59,i32 %p60,i32 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p8,136
 %left8 = add i32 %p9,153
 %left9 = add i32 %p10,170
 %left10 = add i32 %p11,187
 %left11 = add i32 %p12,204
 %left12 = add i32 %p13,221
 %left13 = add i32 %p14,238
 %left14 = add i32 %p15,255
 %left15 = add i32 %p16,272
 %left16 = add i32 %p17,289
 %left17 = add i32 %p18,306
 %left18 = add i32 %p19,323
 %left19 = add i32 %p20,340
 %left20 = add i32 %p21,357
 %left21 = add i32 %p22,374
 %left22 = add i32 %p23,391
 %left23 = add i32 %p24,408
 %left24 = add i32 %p25,425
 %left25 = add i32 %p26,442
 %left26 = add i32 %p27,459
 %left27 = add i32 %p28,476
 %left28 = add i32 %p29,493
 %left29 = add i32 %p30,510
 %left30 = add i32 %p31,527
 %left31 = add i32 %p32,544
 %left32 = add i32 %p33,561
 %left33 = add i32 %p34,578
 %left34 = add i32 %p35,595
 %left35 = add i32 %p36,612
 %left36 = add i32 %p37,629
 %left37 = add i32 %p38,646
 %left38 = add i32 %p39,663
 %left39 = add i32 %p40,680
 %left40 = add i32 %p41,697
 %left41 = add i32 %p42,714
 %left42 = add i32 %p43,731
 %left43 = add i32 %p44,748
 %left44 = add i32 %p45,765
 %left45 = add i32 %p46,782
 %left46 = add i32 %p47,799
 %left47 = add i32 %p48,816
 %left48 = add i32 %p49,833
 %left49 = add i32 %p50,850
 %left50 = add i32 %p51,867
 %left51 = add i32 %p52,884
 %left52 = add i32 %p53,901
 %left53 = add i32 %p54,918
 %left54 = add i32 %p55,935
 %left55 = add i32 %p56,952
 %left56 = add i32 %p57,969
 %left57 = add i32 %p58,986
 %left58 = add i32 %p59,1003
 %left59 = add i32 %p60,1020
 %left60 = add i32 %p61,1037
 %left61 = add i32 %p0,1054
 %answer = musttail call i32 @self_tail_body_28(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,i32 %left8,i32 %left9,i32 %left10,i32 %left11,i32 %left12,i32 %left13,i32 %left14,i32 %left15,i32 %left16,i32 %left17,i32 %left18,i32 %left19,i32 %left20,i32 %left21,i32 %left22,i32 %left23,i32 %left24,i32 %left25,i32 %left26,i32 %left27,i32 %left28,i32 %left29,i32 %left30,i32 %left31,i32 %left32,i32 %left33,i32 %left34,i32 %left35,i32 %left36,i32 %left37,i32 %left38,i32 %left39,i32 %left40,i32 %left41,i32 %left42,i32 %left43,i32 %left44,i32 %left45,i32 %left46,i32 %left47,i32 %left48,i32 %left49,i32 %left50,i32 %left51,i32 %left52,i32 %left53,i32 %left54,i32 %left55,i32 %left56,i32 %left57,i32 %left58,i32 %left59,i32 %left60,i32 %left61,ptr %out)
 ret i32 %answer
right:
 %right0 = xor i32 %p61,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right8 = xor i32 %p7,279
 %right9 = xor i32 %p8,310
 %right10 = xor i32 %p9,341
 %right11 = xor i32 %p10,372
 %right12 = xor i32 %p11,403
 %right13 = xor i32 %p12,434
 %right14 = xor i32 %p13,465
 %right15 = xor i32 %p14,496
 %right16 = xor i32 %p15,527
 %right17 = xor i32 %p16,558
 %right18 = xor i32 %p17,589
 %right19 = xor i32 %p18,620
 %right20 = xor i32 %p19,651
 %right21 = xor i32 %p20,682
 %right22 = xor i32 %p21,713
 %right23 = xor i32 %p22,744
 %right24 = xor i32 %p23,775
 %right25 = xor i32 %p24,806
 %right26 = xor i32 %p25,837
 %right27 = xor i32 %p26,868
 %right28 = xor i32 %p27,899
 %right29 = xor i32 %p28,930
 %right30 = xor i32 %p29,961
 %right31 = xor i32 %p30,992
 %right32 = xor i32 %p31,1023
 %right33 = xor i32 %p32,1054
 %right34 = xor i32 %p33,1085
 %right35 = xor i32 %p34,1116
 %right36 = xor i32 %p35,1147
 %right37 = xor i32 %p36,1178
 %right38 = xor i32 %p37,1209
 %right39 = xor i32 %p38,1240
 %right40 = xor i32 %p39,1271
 %right41 = xor i32 %p40,1302
 %right42 = xor i32 %p41,1333
 %right43 = xor i32 %p42,1364
 %right44 = xor i32 %p43,1395
 %right45 = xor i32 %p44,1426
 %right46 = xor i32 %p45,1457
 %right47 = xor i32 %p46,1488
 %right48 = xor i32 %p47,1519
 %right49 = xor i32 %p48,1550
 %right50 = xor i32 %p49,1581
 %right51 = xor i32 %p50,1612
 %right52 = xor i32 %p51,1643
 %right53 = xor i32 %p52,1674
 %right54 = xor i32 %p53,1705
 %right55 = xor i32 %p54,1736
 %right56 = xor i32 %p55,1767
 %right57 = xor i32 %p56,1798
 %right58 = xor i32 %p57,1829
 %right59 = xor i32 %p58,1860
 %right60 = xor i32 %p59,1891
 %right61 = xor i32 %p60,1922
 %right_answer = musttail call i32 @self_tail_body_28(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,i32 %right8,i32 %right9,i32 %right10,i32 %right11,i32 %right12,i32 %right13,i32 %right14,i32 %right15,i32 %right16,i32 %right17,i32 %right18,i32 %right19,i32 %right20,i32 %right21,i32 %right22,i32 %right23,i32 %right24,i32 %right25,i32 %right26,i32 %right27,i32 %right28,i32 %right29,i32 %right30,i32 %right31,i32 %right32,i32 %right33,i32 %right34,i32 %right35,i32 %right36,i32 %right37,i32 %right38,i32 %right39,i32 %right40,i32 %right41,i32 %right42,i32 %right43,i32 %right44,i32 %right45,i32 %right46,i32 %right47,i32 %right48,i32 %right49,i32 %right50,i32 %right51,i32 %right52,i32 %right53,i32 %right54,i32 %right55,i32 %right56,i32 %right57,i32 %right58,i32 %right59,i32 %right60,i32 %right61,ptr %out)
 ret i32 %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i32 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i32 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i32 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i32 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i32 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i32 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i32 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i32 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i32 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i32 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i32 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i32 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i32 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i32 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i32 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i32 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i32 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i32 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i32 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i32 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i32 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i32 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i32 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i32 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i32 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i32 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i32 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i32 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i32 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i32 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i32 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i32 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i32 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i32 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i32 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i32 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i32 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i32 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i32 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i32 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i32 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i32 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i32 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i32 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i32 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i32 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i32 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i32 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i32 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i32 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i32 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i32 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i32 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i32 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 %truncated = trunc i64 %r61 to i32
 ret i32 %truncated
}
define i64 @self_tail_probe_28(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i32
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i32
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i32
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i32
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i32
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i32
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i32
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i32
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i32
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i32
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i32
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i32
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i32
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i32
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i32
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i32
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i32
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i32
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i32
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i32
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i32
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i32
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i32
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i32
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i32
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i32
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i32
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i32
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i32
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i32
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i32
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i32
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i32
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i32
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i32
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i32
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i32
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i32
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i32
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i32
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i32
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i32
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i32
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i32
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i32
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i32
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i32
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i32
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i32
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i32
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i32
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i32
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i32
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i32
 %returned = call i32 @self_tail_body_28(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,i32 %v8,i32 %v9,i32 %v10,i32 %v11,i32 %v12,i32 %v13,i32 %v14,i32 %v15,i32 %v16,i32 %v17,i32 %v18,i32 %v19,i32 %v20,i32 %v21,i32 %v22,i32 %v23,i32 %v24,i32 %v25,i32 %v26,i32 %v27,i32 %v28,i32 %v29,i32 %v30,i32 %v31,i32 %v32,i32 %v33,i32 %v34,i32 %v35,i32 %v36,i32 %v37,i32 %v38,i32 %v39,i32 %v40,i32 %v41,i32 %v42,i32 %v43,i32 %v44,i32 %v45,i32 %v46,i32 %v47,i32 %v48,i32 %v49,i32 %v50,i32 %v51,i32 %v52,i32 %v53,i32 %v54,i32 %v55,i32 %v56,i32 %v57,i32 %v58,i32 %v59,i32 %v60,i32 %v61,ptr %out)
 %result = zext i32 %returned to i64
 ret i64 %result
}
define internal fastcc i32 @self_tail_body_29(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,i32 %p8,i32 %p9,i32 %p10,i32 %p11,i32 %p12,i32 %p13,i32 %p14,i32 %p15,i32 %p16,i32 %p17,i32 %p18,i32 %p19,i32 %p20,i32 %p21,i32 %p22,i32 %p23,i32 %p24,i32 %p25,i32 %p26,i32 %p27,i32 %p28,i32 %p29,i32 %p30,i32 %p31,i32 %p32,i32 %p33,i32 %p34,i32 %p35,i32 %p36,i32 %p37,i32 %p38,i32 %p39,i32 %p40,i32 %p41,i32 %p42,i32 %p43,i32 %p44,i32 %p45,i32 %p46,i32 %p47,i32 %p48,i32 %p49,i32 %p50,i32 %p51,i32 %p52,i32 %p53,i32 %p54,i32 %p55,i32 %p56,i32 %p57,i32 %p58,i32 %p59,i32 %p60,i32 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p8,136
 %left8 = add i32 %p9,153
 %left9 = add i32 %p10,170
 %left10 = add i32 %p11,187
 %left11 = add i32 %p12,204
 %left12 = add i32 %p13,221
 %left13 = add i32 %p14,238
 %left14 = add i32 %p15,255
 %left15 = add i32 %p16,272
 %left16 = add i32 %p17,289
 %left17 = add i32 %p18,306
 %left18 = add i32 %p19,323
 %left19 = add i32 %p20,340
 %left20 = add i32 %p21,357
 %left21 = add i32 %p22,374
 %left22 = add i32 %p23,391
 %left23 = add i32 %p24,408
 %left24 = add i32 %p25,425
 %left25 = add i32 %p26,442
 %left26 = add i32 %p27,459
 %left27 = add i32 %p28,476
 %left28 = add i32 %p29,493
 %left29 = add i32 %p30,510
 %left30 = add i32 %p31,527
 %left31 = add i32 %p32,544
 %left32 = add i32 %p33,561
 %left33 = add i32 %p34,578
 %left34 = add i32 %p35,595
 %left35 = add i32 %p36,612
 %left36 = add i32 %p37,629
 %left37 = add i32 %p38,646
 %left38 = add i32 %p39,663
 %left39 = add i32 %p40,680
 %left40 = add i32 %p41,697
 %left41 = add i32 %p42,714
 %left42 = add i32 %p43,731
 %left43 = add i32 %p44,748
 %left44 = add i32 %p45,765
 %left45 = add i32 %p46,782
 %left46 = add i32 %p47,799
 %left47 = add i32 %p48,816
 %left48 = add i32 %p49,833
 %left49 = add i32 %p50,850
 %left50 = add i32 %p51,867
 %left51 = add i32 %p52,884
 %left52 = add i32 %p53,901
 %left53 = add i32 %p54,918
 %left54 = add i32 %p55,935
 %left55 = add i32 %p56,952
 %left56 = add i32 %p57,969
 %left57 = add i32 %p58,986
 %left58 = add i32 %p59,1003
 %left59 = add i32 %p60,1020
 %left60 = add i32 %p61,1037
 %left61 = add i32 %p0,1054
 %answer = musttail call fastcc i32 @self_tail_body_29(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,i32 %left8,i32 %left9,i32 %left10,i32 %left11,i32 %left12,i32 %left13,i32 %left14,i32 %left15,i32 %left16,i32 %left17,i32 %left18,i32 %left19,i32 %left20,i32 %left21,i32 %left22,i32 %left23,i32 %left24,i32 %left25,i32 %left26,i32 %left27,i32 %left28,i32 %left29,i32 %left30,i32 %left31,i32 %left32,i32 %left33,i32 %left34,i32 %left35,i32 %left36,i32 %left37,i32 %left38,i32 %left39,i32 %left40,i32 %left41,i32 %left42,i32 %left43,i32 %left44,i32 %left45,i32 %left46,i32 %left47,i32 %left48,i32 %left49,i32 %left50,i32 %left51,i32 %left52,i32 %left53,i32 %left54,i32 %left55,i32 %left56,i32 %left57,i32 %left58,i32 %left59,i32 %left60,i32 %left61,ptr %out)
 ret i32 %answer
right:
 %right0 = xor i32 %p61,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right8 = xor i32 %p7,279
 %right9 = xor i32 %p8,310
 %right10 = xor i32 %p9,341
 %right11 = xor i32 %p10,372
 %right12 = xor i32 %p11,403
 %right13 = xor i32 %p12,434
 %right14 = xor i32 %p13,465
 %right15 = xor i32 %p14,496
 %right16 = xor i32 %p15,527
 %right17 = xor i32 %p16,558
 %right18 = xor i32 %p17,589
 %right19 = xor i32 %p18,620
 %right20 = xor i32 %p19,651
 %right21 = xor i32 %p20,682
 %right22 = xor i32 %p21,713
 %right23 = xor i32 %p22,744
 %right24 = xor i32 %p23,775
 %right25 = xor i32 %p24,806
 %right26 = xor i32 %p25,837
 %right27 = xor i32 %p26,868
 %right28 = xor i32 %p27,899
 %right29 = xor i32 %p28,930
 %right30 = xor i32 %p29,961
 %right31 = xor i32 %p30,992
 %right32 = xor i32 %p31,1023
 %right33 = xor i32 %p32,1054
 %right34 = xor i32 %p33,1085
 %right35 = xor i32 %p34,1116
 %right36 = xor i32 %p35,1147
 %right37 = xor i32 %p36,1178
 %right38 = xor i32 %p37,1209
 %right39 = xor i32 %p38,1240
 %right40 = xor i32 %p39,1271
 %right41 = xor i32 %p40,1302
 %right42 = xor i32 %p41,1333
 %right43 = xor i32 %p42,1364
 %right44 = xor i32 %p43,1395
 %right45 = xor i32 %p44,1426
 %right46 = xor i32 %p45,1457
 %right47 = xor i32 %p46,1488
 %right48 = xor i32 %p47,1519
 %right49 = xor i32 %p48,1550
 %right50 = xor i32 %p49,1581
 %right51 = xor i32 %p50,1612
 %right52 = xor i32 %p51,1643
 %right53 = xor i32 %p52,1674
 %right54 = xor i32 %p53,1705
 %right55 = xor i32 %p54,1736
 %right56 = xor i32 %p55,1767
 %right57 = xor i32 %p56,1798
 %right58 = xor i32 %p57,1829
 %right59 = xor i32 %p58,1860
 %right60 = xor i32 %p59,1891
 %right61 = xor i32 %p60,1922
 %right_answer = musttail call fastcc i32 @self_tail_body_29(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,i32 %right8,i32 %right9,i32 %right10,i32 %right11,i32 %right12,i32 %right13,i32 %right14,i32 %right15,i32 %right16,i32 %right17,i32 %right18,i32 %right19,i32 %right20,i32 %right21,i32 %right22,i32 %right23,i32 %right24,i32 %right25,i32 %right26,i32 %right27,i32 %right28,i32 %right29,i32 %right30,i32 %right31,i32 %right32,i32 %right33,i32 %right34,i32 %right35,i32 %right36,i32 %right37,i32 %right38,i32 %right39,i32 %right40,i32 %right41,i32 %right42,i32 %right43,i32 %right44,i32 %right45,i32 %right46,i32 %right47,i32 %right48,i32 %right49,i32 %right50,i32 %right51,i32 %right52,i32 %right53,i32 %right54,i32 %right55,i32 %right56,i32 %right57,i32 %right58,i32 %right59,i32 %right60,i32 %right61,ptr %out)
 ret i32 %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i32 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i32 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i32 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i32 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i32 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i32 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i32 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i32 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i32 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i32 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i32 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i32 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i32 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i32 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i32 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i32 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i32 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i32 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i32 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i32 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i32 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i32 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i32 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i32 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i32 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i32 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i32 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i32 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i32 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i32 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i32 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i32 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i32 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i32 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i32 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i32 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i32 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i32 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i32 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i32 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i32 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i32 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i32 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i32 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i32 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i32 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i32 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i32 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i32 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i32 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i32 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i32 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i32 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i32 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 %truncated = trunc i64 %r61 to i32
 ret i32 %truncated
}
define i64 @self_tail_probe_29(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i32
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i32
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i32
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i32
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i32
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i32
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i32
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i32
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i32
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i32
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i32
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i32
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i32
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i32
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i32
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i32
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i32
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i32
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i32
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i32
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i32
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i32
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i32
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i32
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i32
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i32
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i32
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i32
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i32
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i32
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i32
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i32
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i32
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i32
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i32
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i32
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i32
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i32
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i32
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i32
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i32
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i32
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i32
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i32
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i32
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i32
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i32
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i32
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i32
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i32
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i32
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i32
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i32
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i32
 %returned = call fastcc i32 @self_tail_body_29(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,i32 %v8,i32 %v9,i32 %v10,i32 %v11,i32 %v12,i32 %v13,i32 %v14,i32 %v15,i32 %v16,i32 %v17,i32 %v18,i32 %v19,i32 %v20,i32 %v21,i32 %v22,i32 %v23,i32 %v24,i32 %v25,i32 %v26,i32 %v27,i32 %v28,i32 %v29,i32 %v30,i32 %v31,i32 %v32,i32 %v33,i32 %v34,i32 %v35,i32 %v36,i32 %v37,i32 %v38,i32 %v39,i32 %v40,i32 %v41,i32 %v42,i32 %v43,i32 %v44,i32 %v45,i32 %v46,i32 %v47,i32 %v48,i32 %v49,i32 %v50,i32 %v51,i32 %v52,i32 %v53,i32 %v54,i32 %v55,i32 %v56,i32 %v57,i32 %v58,i32 %v59,i32 %v60,i32 %v61,ptr %out)
 %result = zext i32 %returned to i64
 ret i64 %result
}
define internal i64 @self_tail_body_30(i64 %n,i64 %p0,i64 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p0,34
 %answer = musttail call i64 @self_tail_body_30(i64 %next,i64 %left0,i64 %left1,ptr %out)
 ret i64 %answer
right:
 %right0 = xor i64 %p1,31
 %right1 = xor i64 %p0,62
 %right_answer = musttail call i64 @self_tail_body_30(i64 %next,i64 %right0,i64 %right1,ptr %out)
 ret i64 %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p1,ptr %o2,align 1
 ret i64 %r1
}
define i64 @self_tail_probe_30(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %returned = call i64 @self_tail_body_30(i64 %count,i64 %raw0,i64 %raw1,ptr %out)
 ret i64 %returned
}
define internal fastcc i64 @self_tail_body_31(i64 %n,i64 %p0,i64 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p0,34
 %answer = musttail call fastcc i64 @self_tail_body_31(i64 %next,i64 %left0,i64 %left1,ptr %out)
 ret i64 %answer
right:
 %right0 = xor i64 %p1,31
 %right1 = xor i64 %p0,62
 %right_answer = musttail call fastcc i64 @self_tail_body_31(i64 %next,i64 %right0,i64 %right1,ptr %out)
 ret i64 %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p1,ptr %o2,align 1
 ret i64 %r1
}
define i64 @self_tail_probe_31(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %returned = call fastcc i64 @self_tail_body_31(i64 %count,i64 %raw0,i64 %raw1,ptr %out)
 ret i64 %returned
}
define internal i64 @self_tail_body_32(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p0,85
 %answer = musttail call i64 @self_tail_body_32(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,ptr %out)
 ret i64 %answer
right:
 %right0 = xor i64 %p4,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right_answer = musttail call i64 @self_tail_body_32(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,ptr %out)
 ret i64 %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p4,ptr %o2,align 1
 ret i64 %r4
}
define i64 @self_tail_probe_32(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %returned = call i64 @self_tail_body_32(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,ptr %out)
 ret i64 %returned
}
define internal fastcc i64 @self_tail_body_33(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p0,85
 %answer = musttail call fastcc i64 @self_tail_body_33(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,ptr %out)
 ret i64 %answer
right:
 %right0 = xor i64 %p4,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right_answer = musttail call fastcc i64 @self_tail_body_33(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,ptr %out)
 ret i64 %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p4,ptr %o2,align 1
 ret i64 %r4
}
define i64 @self_tail_probe_33(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %returned = call fastcc i64 @self_tail_body_33(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,ptr %out)
 ret i64 %returned
}
define internal i64 @self_tail_body_34(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p0,136
 %answer = musttail call i64 @self_tail_body_34(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,ptr %out)
 ret i64 %answer
right:
 %right0 = xor i64 %p7,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right_answer = musttail call i64 @self_tail_body_34(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,ptr %out)
 ret i64 %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p7,ptr %o2,align 1
 ret i64 %r7
}
define i64 @self_tail_probe_34(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %returned = call i64 @self_tail_body_34(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,ptr %out)
 ret i64 %returned
}
define internal fastcc i64 @self_tail_body_35(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p0,136
 %answer = musttail call fastcc i64 @self_tail_body_35(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,ptr %out)
 ret i64 %answer
right:
 %right0 = xor i64 %p7,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right_answer = musttail call fastcc i64 @self_tail_body_35(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,ptr %out)
 ret i64 %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p7,ptr %o2,align 1
 ret i64 %r7
}
define i64 @self_tail_probe_35(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %returned = call fastcc i64 @self_tail_body_35(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,ptr %out)
 ret i64 %returned
}
define internal i64 @self_tail_body_36(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,i64 %p8,i64 %p9,i64 %p10,i64 %p11,i64 %p12,i64 %p13,i64 %p14,i64 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p8,136
 %left8 = add i64 %p9,153
 %left9 = add i64 %p10,170
 %left10 = add i64 %p11,187
 %left11 = add i64 %p12,204
 %left12 = add i64 %p13,221
 %left13 = add i64 %p14,238
 %left14 = add i64 %p15,255
 %left15 = add i64 %p0,272
 %answer = musttail call i64 @self_tail_body_36(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,i64 %left8,i64 %left9,i64 %left10,i64 %left11,i64 %left12,i64 %left13,i64 %left14,i64 %left15,ptr %out)
 ret i64 %answer
right:
 %right0 = xor i64 %p15,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right8 = xor i64 %p7,279
 %right9 = xor i64 %p8,310
 %right10 = xor i64 %p9,341
 %right11 = xor i64 %p10,372
 %right12 = xor i64 %p11,403
 %right13 = xor i64 %p12,434
 %right14 = xor i64 %p13,465
 %right15 = xor i64 %p14,496
 %right_answer = musttail call i64 @self_tail_body_36(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,i64 %right8,i64 %right9,i64 %right10,i64 %right11,i64 %right12,i64 %right13,i64 %right14,i64 %right15,ptr %out)
 ret i64 %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%p8
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%p9
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%p10
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%p11
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%p12
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%p13
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%p14
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%p15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p15,ptr %o2,align 1
 ret i64 %r15
}
define i64 @self_tail_probe_36(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %returned = call i64 @self_tail_body_36(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,i64 %raw8,i64 %raw9,i64 %raw10,i64 %raw11,i64 %raw12,i64 %raw13,i64 %raw14,i64 %raw15,ptr %out)
 ret i64 %returned
}
define internal fastcc i64 @self_tail_body_37(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,i64 %p8,i64 %p9,i64 %p10,i64 %p11,i64 %p12,i64 %p13,i64 %p14,i64 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p8,136
 %left8 = add i64 %p9,153
 %left9 = add i64 %p10,170
 %left10 = add i64 %p11,187
 %left11 = add i64 %p12,204
 %left12 = add i64 %p13,221
 %left13 = add i64 %p14,238
 %left14 = add i64 %p15,255
 %left15 = add i64 %p0,272
 %answer = musttail call fastcc i64 @self_tail_body_37(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,i64 %left8,i64 %left9,i64 %left10,i64 %left11,i64 %left12,i64 %left13,i64 %left14,i64 %left15,ptr %out)
 ret i64 %answer
right:
 %right0 = xor i64 %p15,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right8 = xor i64 %p7,279
 %right9 = xor i64 %p8,310
 %right10 = xor i64 %p9,341
 %right11 = xor i64 %p10,372
 %right12 = xor i64 %p11,403
 %right13 = xor i64 %p12,434
 %right14 = xor i64 %p13,465
 %right15 = xor i64 %p14,496
 %right_answer = musttail call fastcc i64 @self_tail_body_37(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,i64 %right8,i64 %right9,i64 %right10,i64 %right11,i64 %right12,i64 %right13,i64 %right14,i64 %right15,ptr %out)
 ret i64 %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%p8
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%p9
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%p10
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%p11
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%p12
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%p13
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%p14
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%p15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p15,ptr %o2,align 1
 ret i64 %r15
}
define i64 @self_tail_probe_37(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %returned = call fastcc i64 @self_tail_body_37(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,i64 %raw8,i64 %raw9,i64 %raw10,i64 %raw11,i64 %raw12,i64 %raw13,i64 %raw14,i64 %raw15,ptr %out)
 ret i64 %returned
}
define internal i64 @self_tail_body_38(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,i64 %p8,i64 %p9,i64 %p10,i64 %p11,i64 %p12,i64 %p13,i64 %p14,i64 %p15,i64 %p16,i64 %p17,i64 %p18,i64 %p19,i64 %p20,i64 %p21,i64 %p22,i64 %p23,i64 %p24,i64 %p25,i64 %p26,i64 %p27,i64 %p28,i64 %p29,i64 %p30,i64 %p31,i64 %p32,i64 %p33,i64 %p34,i64 %p35,i64 %p36,i64 %p37,i64 %p38,i64 %p39,i64 %p40,i64 %p41,i64 %p42,i64 %p43,i64 %p44,i64 %p45,i64 %p46,i64 %p47,i64 %p48,i64 %p49,i64 %p50,i64 %p51,i64 %p52,i64 %p53,i64 %p54,i64 %p55,i64 %p56,i64 %p57,i64 %p58,i64 %p59,i64 %p60,i64 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p8,136
 %left8 = add i64 %p9,153
 %left9 = add i64 %p10,170
 %left10 = add i64 %p11,187
 %left11 = add i64 %p12,204
 %left12 = add i64 %p13,221
 %left13 = add i64 %p14,238
 %left14 = add i64 %p15,255
 %left15 = add i64 %p16,272
 %left16 = add i64 %p17,289
 %left17 = add i64 %p18,306
 %left18 = add i64 %p19,323
 %left19 = add i64 %p20,340
 %left20 = add i64 %p21,357
 %left21 = add i64 %p22,374
 %left22 = add i64 %p23,391
 %left23 = add i64 %p24,408
 %left24 = add i64 %p25,425
 %left25 = add i64 %p26,442
 %left26 = add i64 %p27,459
 %left27 = add i64 %p28,476
 %left28 = add i64 %p29,493
 %left29 = add i64 %p30,510
 %left30 = add i64 %p31,527
 %left31 = add i64 %p32,544
 %left32 = add i64 %p33,561
 %left33 = add i64 %p34,578
 %left34 = add i64 %p35,595
 %left35 = add i64 %p36,612
 %left36 = add i64 %p37,629
 %left37 = add i64 %p38,646
 %left38 = add i64 %p39,663
 %left39 = add i64 %p40,680
 %left40 = add i64 %p41,697
 %left41 = add i64 %p42,714
 %left42 = add i64 %p43,731
 %left43 = add i64 %p44,748
 %left44 = add i64 %p45,765
 %left45 = add i64 %p46,782
 %left46 = add i64 %p47,799
 %left47 = add i64 %p48,816
 %left48 = add i64 %p49,833
 %left49 = add i64 %p50,850
 %left50 = add i64 %p51,867
 %left51 = add i64 %p52,884
 %left52 = add i64 %p53,901
 %left53 = add i64 %p54,918
 %left54 = add i64 %p55,935
 %left55 = add i64 %p56,952
 %left56 = add i64 %p57,969
 %left57 = add i64 %p58,986
 %left58 = add i64 %p59,1003
 %left59 = add i64 %p60,1020
 %left60 = add i64 %p61,1037
 %left61 = add i64 %p0,1054
 %answer = musttail call i64 @self_tail_body_38(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,i64 %left8,i64 %left9,i64 %left10,i64 %left11,i64 %left12,i64 %left13,i64 %left14,i64 %left15,i64 %left16,i64 %left17,i64 %left18,i64 %left19,i64 %left20,i64 %left21,i64 %left22,i64 %left23,i64 %left24,i64 %left25,i64 %left26,i64 %left27,i64 %left28,i64 %left29,i64 %left30,i64 %left31,i64 %left32,i64 %left33,i64 %left34,i64 %left35,i64 %left36,i64 %left37,i64 %left38,i64 %left39,i64 %left40,i64 %left41,i64 %left42,i64 %left43,i64 %left44,i64 %left45,i64 %left46,i64 %left47,i64 %left48,i64 %left49,i64 %left50,i64 %left51,i64 %left52,i64 %left53,i64 %left54,i64 %left55,i64 %left56,i64 %left57,i64 %left58,i64 %left59,i64 %left60,i64 %left61,ptr %out)
 ret i64 %answer
right:
 %right0 = xor i64 %p61,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right8 = xor i64 %p7,279
 %right9 = xor i64 %p8,310
 %right10 = xor i64 %p9,341
 %right11 = xor i64 %p10,372
 %right12 = xor i64 %p11,403
 %right13 = xor i64 %p12,434
 %right14 = xor i64 %p13,465
 %right15 = xor i64 %p14,496
 %right16 = xor i64 %p15,527
 %right17 = xor i64 %p16,558
 %right18 = xor i64 %p17,589
 %right19 = xor i64 %p18,620
 %right20 = xor i64 %p19,651
 %right21 = xor i64 %p20,682
 %right22 = xor i64 %p21,713
 %right23 = xor i64 %p22,744
 %right24 = xor i64 %p23,775
 %right25 = xor i64 %p24,806
 %right26 = xor i64 %p25,837
 %right27 = xor i64 %p26,868
 %right28 = xor i64 %p27,899
 %right29 = xor i64 %p28,930
 %right30 = xor i64 %p29,961
 %right31 = xor i64 %p30,992
 %right32 = xor i64 %p31,1023
 %right33 = xor i64 %p32,1054
 %right34 = xor i64 %p33,1085
 %right35 = xor i64 %p34,1116
 %right36 = xor i64 %p35,1147
 %right37 = xor i64 %p36,1178
 %right38 = xor i64 %p37,1209
 %right39 = xor i64 %p38,1240
 %right40 = xor i64 %p39,1271
 %right41 = xor i64 %p40,1302
 %right42 = xor i64 %p41,1333
 %right43 = xor i64 %p42,1364
 %right44 = xor i64 %p43,1395
 %right45 = xor i64 %p44,1426
 %right46 = xor i64 %p45,1457
 %right47 = xor i64 %p46,1488
 %right48 = xor i64 %p47,1519
 %right49 = xor i64 %p48,1550
 %right50 = xor i64 %p49,1581
 %right51 = xor i64 %p50,1612
 %right52 = xor i64 %p51,1643
 %right53 = xor i64 %p52,1674
 %right54 = xor i64 %p53,1705
 %right55 = xor i64 %p54,1736
 %right56 = xor i64 %p55,1767
 %right57 = xor i64 %p56,1798
 %right58 = xor i64 %p57,1829
 %right59 = xor i64 %p58,1860
 %right60 = xor i64 %p59,1891
 %right61 = xor i64 %p60,1922
 %right_answer = musttail call i64 @self_tail_body_38(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,i64 %right8,i64 %right9,i64 %right10,i64 %right11,i64 %right12,i64 %right13,i64 %right14,i64 %right15,i64 %right16,i64 %right17,i64 %right18,i64 %right19,i64 %right20,i64 %right21,i64 %right22,i64 %right23,i64 %right24,i64 %right25,i64 %right26,i64 %right27,i64 %right28,i64 %right29,i64 %right30,i64 %right31,i64 %right32,i64 %right33,i64 %right34,i64 %right35,i64 %right36,i64 %right37,i64 %right38,i64 %right39,i64 %right40,i64 %right41,i64 %right42,i64 %right43,i64 %right44,i64 %right45,i64 %right46,i64 %right47,i64 %right48,i64 %right49,i64 %right50,i64 %right51,i64 %right52,i64 %right53,i64 %right54,i64 %right55,i64 %right56,i64 %right57,i64 %right58,i64 %right59,i64 %right60,i64 %right61,ptr %out)
 ret i64 %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%p8
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%p9
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%p10
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%p11
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%p12
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%p13
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%p14
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%p15
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%p16
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%p17
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%p18
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%p19
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%p20
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%p21
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%p22
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%p23
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%p24
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%p25
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%p26
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%p27
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%p28
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%p29
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%p30
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%p31
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%p32
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%p33
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%p34
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%p35
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%p36
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%p37
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%p38
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%p39
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%p40
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%p41
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%p42
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%p43
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%p44
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%p45
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%p46
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%p47
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%p48
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%p49
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%p50
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%p51
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%p52
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%p53
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%p54
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%p55
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%p56
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%p57
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%p58
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%p59
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%p60
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%p61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p61,ptr %o2,align 1
 ret i64 %r61
}
define i64 @self_tail_probe_38(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %returned = call i64 @self_tail_body_38(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,i64 %raw8,i64 %raw9,i64 %raw10,i64 %raw11,i64 %raw12,i64 %raw13,i64 %raw14,i64 %raw15,i64 %raw16,i64 %raw17,i64 %raw18,i64 %raw19,i64 %raw20,i64 %raw21,i64 %raw22,i64 %raw23,i64 %raw24,i64 %raw25,i64 %raw26,i64 %raw27,i64 %raw28,i64 %raw29,i64 %raw30,i64 %raw31,i64 %raw32,i64 %raw33,i64 %raw34,i64 %raw35,i64 %raw36,i64 %raw37,i64 %raw38,i64 %raw39,i64 %raw40,i64 %raw41,i64 %raw42,i64 %raw43,i64 %raw44,i64 %raw45,i64 %raw46,i64 %raw47,i64 %raw48,i64 %raw49,i64 %raw50,i64 %raw51,i64 %raw52,i64 %raw53,i64 %raw54,i64 %raw55,i64 %raw56,i64 %raw57,i64 %raw58,i64 %raw59,i64 %raw60,i64 %raw61,ptr %out)
 ret i64 %returned
}
define internal fastcc i64 @self_tail_body_39(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,i64 %p8,i64 %p9,i64 %p10,i64 %p11,i64 %p12,i64 %p13,i64 %p14,i64 %p15,i64 %p16,i64 %p17,i64 %p18,i64 %p19,i64 %p20,i64 %p21,i64 %p22,i64 %p23,i64 %p24,i64 %p25,i64 %p26,i64 %p27,i64 %p28,i64 %p29,i64 %p30,i64 %p31,i64 %p32,i64 %p33,i64 %p34,i64 %p35,i64 %p36,i64 %p37,i64 %p38,i64 %p39,i64 %p40,i64 %p41,i64 %p42,i64 %p43,i64 %p44,i64 %p45,i64 %p46,i64 %p47,i64 %p48,i64 %p49,i64 %p50,i64 %p51,i64 %p52,i64 %p53,i64 %p54,i64 %p55,i64 %p56,i64 %p57,i64 %p58,i64 %p59,i64 %p60,i64 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p8,136
 %left8 = add i64 %p9,153
 %left9 = add i64 %p10,170
 %left10 = add i64 %p11,187
 %left11 = add i64 %p12,204
 %left12 = add i64 %p13,221
 %left13 = add i64 %p14,238
 %left14 = add i64 %p15,255
 %left15 = add i64 %p16,272
 %left16 = add i64 %p17,289
 %left17 = add i64 %p18,306
 %left18 = add i64 %p19,323
 %left19 = add i64 %p20,340
 %left20 = add i64 %p21,357
 %left21 = add i64 %p22,374
 %left22 = add i64 %p23,391
 %left23 = add i64 %p24,408
 %left24 = add i64 %p25,425
 %left25 = add i64 %p26,442
 %left26 = add i64 %p27,459
 %left27 = add i64 %p28,476
 %left28 = add i64 %p29,493
 %left29 = add i64 %p30,510
 %left30 = add i64 %p31,527
 %left31 = add i64 %p32,544
 %left32 = add i64 %p33,561
 %left33 = add i64 %p34,578
 %left34 = add i64 %p35,595
 %left35 = add i64 %p36,612
 %left36 = add i64 %p37,629
 %left37 = add i64 %p38,646
 %left38 = add i64 %p39,663
 %left39 = add i64 %p40,680
 %left40 = add i64 %p41,697
 %left41 = add i64 %p42,714
 %left42 = add i64 %p43,731
 %left43 = add i64 %p44,748
 %left44 = add i64 %p45,765
 %left45 = add i64 %p46,782
 %left46 = add i64 %p47,799
 %left47 = add i64 %p48,816
 %left48 = add i64 %p49,833
 %left49 = add i64 %p50,850
 %left50 = add i64 %p51,867
 %left51 = add i64 %p52,884
 %left52 = add i64 %p53,901
 %left53 = add i64 %p54,918
 %left54 = add i64 %p55,935
 %left55 = add i64 %p56,952
 %left56 = add i64 %p57,969
 %left57 = add i64 %p58,986
 %left58 = add i64 %p59,1003
 %left59 = add i64 %p60,1020
 %left60 = add i64 %p61,1037
 %left61 = add i64 %p0,1054
 %answer = musttail call fastcc i64 @self_tail_body_39(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,i64 %left8,i64 %left9,i64 %left10,i64 %left11,i64 %left12,i64 %left13,i64 %left14,i64 %left15,i64 %left16,i64 %left17,i64 %left18,i64 %left19,i64 %left20,i64 %left21,i64 %left22,i64 %left23,i64 %left24,i64 %left25,i64 %left26,i64 %left27,i64 %left28,i64 %left29,i64 %left30,i64 %left31,i64 %left32,i64 %left33,i64 %left34,i64 %left35,i64 %left36,i64 %left37,i64 %left38,i64 %left39,i64 %left40,i64 %left41,i64 %left42,i64 %left43,i64 %left44,i64 %left45,i64 %left46,i64 %left47,i64 %left48,i64 %left49,i64 %left50,i64 %left51,i64 %left52,i64 %left53,i64 %left54,i64 %left55,i64 %left56,i64 %left57,i64 %left58,i64 %left59,i64 %left60,i64 %left61,ptr %out)
 ret i64 %answer
right:
 %right0 = xor i64 %p61,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right8 = xor i64 %p7,279
 %right9 = xor i64 %p8,310
 %right10 = xor i64 %p9,341
 %right11 = xor i64 %p10,372
 %right12 = xor i64 %p11,403
 %right13 = xor i64 %p12,434
 %right14 = xor i64 %p13,465
 %right15 = xor i64 %p14,496
 %right16 = xor i64 %p15,527
 %right17 = xor i64 %p16,558
 %right18 = xor i64 %p17,589
 %right19 = xor i64 %p18,620
 %right20 = xor i64 %p19,651
 %right21 = xor i64 %p20,682
 %right22 = xor i64 %p21,713
 %right23 = xor i64 %p22,744
 %right24 = xor i64 %p23,775
 %right25 = xor i64 %p24,806
 %right26 = xor i64 %p25,837
 %right27 = xor i64 %p26,868
 %right28 = xor i64 %p27,899
 %right29 = xor i64 %p28,930
 %right30 = xor i64 %p29,961
 %right31 = xor i64 %p30,992
 %right32 = xor i64 %p31,1023
 %right33 = xor i64 %p32,1054
 %right34 = xor i64 %p33,1085
 %right35 = xor i64 %p34,1116
 %right36 = xor i64 %p35,1147
 %right37 = xor i64 %p36,1178
 %right38 = xor i64 %p37,1209
 %right39 = xor i64 %p38,1240
 %right40 = xor i64 %p39,1271
 %right41 = xor i64 %p40,1302
 %right42 = xor i64 %p41,1333
 %right43 = xor i64 %p42,1364
 %right44 = xor i64 %p43,1395
 %right45 = xor i64 %p44,1426
 %right46 = xor i64 %p45,1457
 %right47 = xor i64 %p46,1488
 %right48 = xor i64 %p47,1519
 %right49 = xor i64 %p48,1550
 %right50 = xor i64 %p49,1581
 %right51 = xor i64 %p50,1612
 %right52 = xor i64 %p51,1643
 %right53 = xor i64 %p52,1674
 %right54 = xor i64 %p53,1705
 %right55 = xor i64 %p54,1736
 %right56 = xor i64 %p55,1767
 %right57 = xor i64 %p56,1798
 %right58 = xor i64 %p57,1829
 %right59 = xor i64 %p58,1860
 %right60 = xor i64 %p59,1891
 %right61 = xor i64 %p60,1922
 %right_answer = musttail call fastcc i64 @self_tail_body_39(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,i64 %right8,i64 %right9,i64 %right10,i64 %right11,i64 %right12,i64 %right13,i64 %right14,i64 %right15,i64 %right16,i64 %right17,i64 %right18,i64 %right19,i64 %right20,i64 %right21,i64 %right22,i64 %right23,i64 %right24,i64 %right25,i64 %right26,i64 %right27,i64 %right28,i64 %right29,i64 %right30,i64 %right31,i64 %right32,i64 %right33,i64 %right34,i64 %right35,i64 %right36,i64 %right37,i64 %right38,i64 %right39,i64 %right40,i64 %right41,i64 %right42,i64 %right43,i64 %right44,i64 %right45,i64 %right46,i64 %right47,i64 %right48,i64 %right49,i64 %right50,i64 %right51,i64 %right52,i64 %right53,i64 %right54,i64 %right55,i64 %right56,i64 %right57,i64 %right58,i64 %right59,i64 %right60,i64 %right61,ptr %out)
 ret i64 %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%p8
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%p9
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%p10
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%p11
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%p12
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%p13
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%p14
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%p15
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%p16
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%p17
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%p18
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%p19
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%p20
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%p21
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%p22
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%p23
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%p24
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%p25
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%p26
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%p27
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%p28
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%p29
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%p30
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%p31
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%p32
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%p33
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%p34
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%p35
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%p36
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%p37
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%p38
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%p39
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%p40
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%p41
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%p42
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%p43
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%p44
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%p45
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%p46
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%p47
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%p48
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%p49
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%p50
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%p51
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%p52
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%p53
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%p54
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%p55
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%p56
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%p57
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%p58
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%p59
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%p60
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%p61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p61,ptr %o2,align 1
 ret i64 %r61
}
define i64 @self_tail_probe_39(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %returned = call fastcc i64 @self_tail_body_39(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,i64 %raw8,i64 %raw9,i64 %raw10,i64 %raw11,i64 %raw12,i64 %raw13,i64 %raw14,i64 %raw15,i64 %raw16,i64 %raw17,i64 %raw18,i64 %raw19,i64 %raw20,i64 %raw21,i64 %raw22,i64 %raw23,i64 %raw24,i64 %raw25,i64 %raw26,i64 %raw27,i64 %raw28,i64 %raw29,i64 %raw30,i64 %raw31,i64 %raw32,i64 %raw33,i64 %raw34,i64 %raw35,i64 %raw36,i64 %raw37,i64 %raw38,i64 %raw39,i64 %raw40,i64 %raw41,i64 %raw42,i64 %raw43,i64 %raw44,i64 %raw45,i64 %raw46,i64 %raw47,i64 %raw48,i64 %raw49,i64 %raw50,i64 %raw51,i64 %raw52,i64 %raw53,i64 %raw54,i64 %raw55,i64 %raw56,i64 %raw57,i64 %raw58,i64 %raw59,i64 %raw60,i64 %raw61,ptr %out)
 ret i64 %returned
}
define internal void @self_tail_body_40(i64 %n,i8 %p0,i8 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p0,34
 musttail call void @self_tail_body_40(i64 %next,i8 %left0,i8 %left1,ptr %out)
 ret void
right:
 %right0 = xor i8 %p1,31
 %right1 = xor i8 %p0,62
 musttail call void @self_tail_body_40(i64 %next,i8 %right0,i8 %right1,ptr %out)
 ret void
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_40(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 call void @self_tail_body_40(i64 %count,i8 %v0,i8 %v1,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,255
 ret i64 %result
}
define internal fastcc void @self_tail_body_41(i64 %n,i8 %p0,i8 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p0,34
 musttail call fastcc void @self_tail_body_41(i64 %next,i8 %left0,i8 %left1,ptr %out)
 ret void
right:
 %right0 = xor i8 %p1,31
 %right1 = xor i8 %p0,62
 musttail call fastcc void @self_tail_body_41(i64 %next,i8 %right0,i8 %right1,ptr %out)
 ret void
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_41(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 call fastcc void @self_tail_body_41(i64 %count,i8 %v0,i8 %v1,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,255
 ret i64 %result
}
define internal void @self_tail_body_42(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p0,85
 musttail call void @self_tail_body_42(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,ptr %out)
 ret void
right:
 %right0 = xor i8 %p4,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 musttail call void @self_tail_body_42(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,ptr %out)
 ret void
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_42(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 call void @self_tail_body_42(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,255
 ret i64 %result
}
define internal fastcc void @self_tail_body_43(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p0,85
 musttail call fastcc void @self_tail_body_43(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,ptr %out)
 ret void
right:
 %right0 = xor i8 %p4,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 musttail call fastcc void @self_tail_body_43(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,ptr %out)
 ret void
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_43(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 call fastcc void @self_tail_body_43(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,255
 ret i64 %result
}
define internal void @self_tail_body_44(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p0,136
 musttail call void @self_tail_body_44(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,ptr %out)
 ret void
right:
 %right0 = xor i8 %p7,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 musttail call void @self_tail_body_44(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,ptr %out)
 ret void
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_44(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 call void @self_tail_body_44(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,255
 ret i64 %result
}
define internal fastcc void @self_tail_body_45(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p0,136
 musttail call fastcc void @self_tail_body_45(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,ptr %out)
 ret void
right:
 %right0 = xor i8 %p7,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 musttail call fastcc void @self_tail_body_45(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,ptr %out)
 ret void
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_45(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 call fastcc void @self_tail_body_45(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,255
 ret i64 %result
}
define internal void @self_tail_body_46(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,i8 %p8,i8 %p9,i8 %p10,i8 %p11,i8 %p12,i8 %p13,i8 %p14,i8 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p8,136
 %left8 = add i8 %p9,153
 %left9 = add i8 %p10,170
 %left10 = add i8 %p11,187
 %left11 = add i8 %p12,204
 %left12 = add i8 %p13,221
 %left13 = add i8 %p14,238
 %left14 = add i8 %p15,255
 %left15 = add i8 %p0,16
 musttail call void @self_tail_body_46(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,i8 %left8,i8 %left9,i8 %left10,i8 %left11,i8 %left12,i8 %left13,i8 %left14,i8 %left15,ptr %out)
 ret void
right:
 %right0 = xor i8 %p15,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right8 = xor i8 %p7,23
 %right9 = xor i8 %p8,54
 %right10 = xor i8 %p9,85
 %right11 = xor i8 %p10,116
 %right12 = xor i8 %p11,147
 %right13 = xor i8 %p12,178
 %right14 = xor i8 %p13,209
 %right15 = xor i8 %p14,240
 musttail call void @self_tail_body_46(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,i8 %right8,i8 %right9,i8 %right10,i8 %right11,i8 %right12,i8 %right13,i8 %right14,i8 %right15,ptr %out)
 ret void
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i8 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i8 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i8 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i8 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i8 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i8 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i8 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i8 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_46(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i8
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i8
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i8
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i8
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i8
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i8
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i8
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i8
 call void @self_tail_body_46(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,i8 %v8,i8 %v9,i8 %v10,i8 %v11,i8 %v12,i8 %v13,i8 %v14,i8 %v15,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,255
 ret i64 %result
}
define internal fastcc void @self_tail_body_47(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,i8 %p8,i8 %p9,i8 %p10,i8 %p11,i8 %p12,i8 %p13,i8 %p14,i8 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p8,136
 %left8 = add i8 %p9,153
 %left9 = add i8 %p10,170
 %left10 = add i8 %p11,187
 %left11 = add i8 %p12,204
 %left12 = add i8 %p13,221
 %left13 = add i8 %p14,238
 %left14 = add i8 %p15,255
 %left15 = add i8 %p0,16
 musttail call fastcc void @self_tail_body_47(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,i8 %left8,i8 %left9,i8 %left10,i8 %left11,i8 %left12,i8 %left13,i8 %left14,i8 %left15,ptr %out)
 ret void
right:
 %right0 = xor i8 %p15,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right8 = xor i8 %p7,23
 %right9 = xor i8 %p8,54
 %right10 = xor i8 %p9,85
 %right11 = xor i8 %p10,116
 %right12 = xor i8 %p11,147
 %right13 = xor i8 %p12,178
 %right14 = xor i8 %p13,209
 %right15 = xor i8 %p14,240
 musttail call fastcc void @self_tail_body_47(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,i8 %right8,i8 %right9,i8 %right10,i8 %right11,i8 %right12,i8 %right13,i8 %right14,i8 %right15,ptr %out)
 ret void
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i8 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i8 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i8 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i8 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i8 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i8 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i8 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i8 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_47(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i8
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i8
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i8
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i8
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i8
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i8
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i8
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i8
 call fastcc void @self_tail_body_47(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,i8 %v8,i8 %v9,i8 %v10,i8 %v11,i8 %v12,i8 %v13,i8 %v14,i8 %v15,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,255
 ret i64 %result
}
define internal void @self_tail_body_48(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,i8 %p8,i8 %p9,i8 %p10,i8 %p11,i8 %p12,i8 %p13,i8 %p14,i8 %p15,i8 %p16,i8 %p17,i8 %p18,i8 %p19,i8 %p20,i8 %p21,i8 %p22,i8 %p23,i8 %p24,i8 %p25,i8 %p26,i8 %p27,i8 %p28,i8 %p29,i8 %p30,i8 %p31,i8 %p32,i8 %p33,i8 %p34,i8 %p35,i8 %p36,i8 %p37,i8 %p38,i8 %p39,i8 %p40,i8 %p41,i8 %p42,i8 %p43,i8 %p44,i8 %p45,i8 %p46,i8 %p47,i8 %p48,i8 %p49,i8 %p50,i8 %p51,i8 %p52,i8 %p53,i8 %p54,i8 %p55,i8 %p56,i8 %p57,i8 %p58,i8 %p59,i8 %p60,i8 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p8,136
 %left8 = add i8 %p9,153
 %left9 = add i8 %p10,170
 %left10 = add i8 %p11,187
 %left11 = add i8 %p12,204
 %left12 = add i8 %p13,221
 %left13 = add i8 %p14,238
 %left14 = add i8 %p15,255
 %left15 = add i8 %p16,16
 %left16 = add i8 %p17,33
 %left17 = add i8 %p18,50
 %left18 = add i8 %p19,67
 %left19 = add i8 %p20,84
 %left20 = add i8 %p21,101
 %left21 = add i8 %p22,118
 %left22 = add i8 %p23,135
 %left23 = add i8 %p24,152
 %left24 = add i8 %p25,169
 %left25 = add i8 %p26,186
 %left26 = add i8 %p27,203
 %left27 = add i8 %p28,220
 %left28 = add i8 %p29,237
 %left29 = add i8 %p30,254
 %left30 = add i8 %p31,15
 %left31 = add i8 %p32,32
 %left32 = add i8 %p33,49
 %left33 = add i8 %p34,66
 %left34 = add i8 %p35,83
 %left35 = add i8 %p36,100
 %left36 = add i8 %p37,117
 %left37 = add i8 %p38,134
 %left38 = add i8 %p39,151
 %left39 = add i8 %p40,168
 %left40 = add i8 %p41,185
 %left41 = add i8 %p42,202
 %left42 = add i8 %p43,219
 %left43 = add i8 %p44,236
 %left44 = add i8 %p45,253
 %left45 = add i8 %p46,14
 %left46 = add i8 %p47,31
 %left47 = add i8 %p48,48
 %left48 = add i8 %p49,65
 %left49 = add i8 %p50,82
 %left50 = add i8 %p51,99
 %left51 = add i8 %p52,116
 %left52 = add i8 %p53,133
 %left53 = add i8 %p54,150
 %left54 = add i8 %p55,167
 %left55 = add i8 %p56,184
 %left56 = add i8 %p57,201
 %left57 = add i8 %p58,218
 %left58 = add i8 %p59,235
 %left59 = add i8 %p60,252
 %left60 = add i8 %p61,13
 %left61 = add i8 %p0,30
 musttail call void @self_tail_body_48(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,i8 %left8,i8 %left9,i8 %left10,i8 %left11,i8 %left12,i8 %left13,i8 %left14,i8 %left15,i8 %left16,i8 %left17,i8 %left18,i8 %left19,i8 %left20,i8 %left21,i8 %left22,i8 %left23,i8 %left24,i8 %left25,i8 %left26,i8 %left27,i8 %left28,i8 %left29,i8 %left30,i8 %left31,i8 %left32,i8 %left33,i8 %left34,i8 %left35,i8 %left36,i8 %left37,i8 %left38,i8 %left39,i8 %left40,i8 %left41,i8 %left42,i8 %left43,i8 %left44,i8 %left45,i8 %left46,i8 %left47,i8 %left48,i8 %left49,i8 %left50,i8 %left51,i8 %left52,i8 %left53,i8 %left54,i8 %left55,i8 %left56,i8 %left57,i8 %left58,i8 %left59,i8 %left60,i8 %left61,ptr %out)
 ret void
right:
 %right0 = xor i8 %p61,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right8 = xor i8 %p7,23
 %right9 = xor i8 %p8,54
 %right10 = xor i8 %p9,85
 %right11 = xor i8 %p10,116
 %right12 = xor i8 %p11,147
 %right13 = xor i8 %p12,178
 %right14 = xor i8 %p13,209
 %right15 = xor i8 %p14,240
 %right16 = xor i8 %p15,15
 %right17 = xor i8 %p16,46
 %right18 = xor i8 %p17,77
 %right19 = xor i8 %p18,108
 %right20 = xor i8 %p19,139
 %right21 = xor i8 %p20,170
 %right22 = xor i8 %p21,201
 %right23 = xor i8 %p22,232
 %right24 = xor i8 %p23,7
 %right25 = xor i8 %p24,38
 %right26 = xor i8 %p25,69
 %right27 = xor i8 %p26,100
 %right28 = xor i8 %p27,131
 %right29 = xor i8 %p28,162
 %right30 = xor i8 %p29,193
 %right31 = xor i8 %p30,224
 %right32 = xor i8 %p31,255
 %right33 = xor i8 %p32,30
 %right34 = xor i8 %p33,61
 %right35 = xor i8 %p34,92
 %right36 = xor i8 %p35,123
 %right37 = xor i8 %p36,154
 %right38 = xor i8 %p37,185
 %right39 = xor i8 %p38,216
 %right40 = xor i8 %p39,247
 %right41 = xor i8 %p40,22
 %right42 = xor i8 %p41,53
 %right43 = xor i8 %p42,84
 %right44 = xor i8 %p43,115
 %right45 = xor i8 %p44,146
 %right46 = xor i8 %p45,177
 %right47 = xor i8 %p46,208
 %right48 = xor i8 %p47,239
 %right49 = xor i8 %p48,14
 %right50 = xor i8 %p49,45
 %right51 = xor i8 %p50,76
 %right52 = xor i8 %p51,107
 %right53 = xor i8 %p52,138
 %right54 = xor i8 %p53,169
 %right55 = xor i8 %p54,200
 %right56 = xor i8 %p55,231
 %right57 = xor i8 %p56,6
 %right58 = xor i8 %p57,37
 %right59 = xor i8 %p58,68
 %right60 = xor i8 %p59,99
 %right61 = xor i8 %p60,130
 musttail call void @self_tail_body_48(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,i8 %right8,i8 %right9,i8 %right10,i8 %right11,i8 %right12,i8 %right13,i8 %right14,i8 %right15,i8 %right16,i8 %right17,i8 %right18,i8 %right19,i8 %right20,i8 %right21,i8 %right22,i8 %right23,i8 %right24,i8 %right25,i8 %right26,i8 %right27,i8 %right28,i8 %right29,i8 %right30,i8 %right31,i8 %right32,i8 %right33,i8 %right34,i8 %right35,i8 %right36,i8 %right37,i8 %right38,i8 %right39,i8 %right40,i8 %right41,i8 %right42,i8 %right43,i8 %right44,i8 %right45,i8 %right46,i8 %right47,i8 %right48,i8 %right49,i8 %right50,i8 %right51,i8 %right52,i8 %right53,i8 %right54,i8 %right55,i8 %right56,i8 %right57,i8 %right58,i8 %right59,i8 %right60,i8 %right61,ptr %out)
 ret void
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i8 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i8 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i8 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i8 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i8 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i8 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i8 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i8 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i8 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i8 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i8 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i8 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i8 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i8 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i8 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i8 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i8 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i8 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i8 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i8 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i8 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i8 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i8 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i8 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i8 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i8 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i8 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i8 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i8 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i8 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i8 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i8 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i8 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i8 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i8 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i8 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i8 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i8 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i8 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i8 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i8 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i8 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i8 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i8 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i8 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i8 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i8 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i8 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i8 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i8 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i8 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i8 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i8 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i8 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_48(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i8
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i8
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i8
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i8
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i8
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i8
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i8
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i8
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i8
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i8
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i8
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i8
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i8
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i8
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i8
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i8
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i8
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i8
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i8
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i8
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i8
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i8
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i8
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i8
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i8
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i8
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i8
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i8
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i8
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i8
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i8
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i8
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i8
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i8
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i8
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i8
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i8
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i8
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i8
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i8
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i8
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i8
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i8
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i8
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i8
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i8
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i8
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i8
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i8
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i8
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i8
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i8
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i8
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i8
 call void @self_tail_body_48(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,i8 %v8,i8 %v9,i8 %v10,i8 %v11,i8 %v12,i8 %v13,i8 %v14,i8 %v15,i8 %v16,i8 %v17,i8 %v18,i8 %v19,i8 %v20,i8 %v21,i8 %v22,i8 %v23,i8 %v24,i8 %v25,i8 %v26,i8 %v27,i8 %v28,i8 %v29,i8 %v30,i8 %v31,i8 %v32,i8 %v33,i8 %v34,i8 %v35,i8 %v36,i8 %v37,i8 %v38,i8 %v39,i8 %v40,i8 %v41,i8 %v42,i8 %v43,i8 %v44,i8 %v45,i8 %v46,i8 %v47,i8 %v48,i8 %v49,i8 %v50,i8 %v51,i8 %v52,i8 %v53,i8 %v54,i8 %v55,i8 %v56,i8 %v57,i8 %v58,i8 %v59,i8 %v60,i8 %v61,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,255
 ret i64 %result
}
define internal fastcc void @self_tail_body_49(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,i8 %p8,i8 %p9,i8 %p10,i8 %p11,i8 %p12,i8 %p13,i8 %p14,i8 %p15,i8 %p16,i8 %p17,i8 %p18,i8 %p19,i8 %p20,i8 %p21,i8 %p22,i8 %p23,i8 %p24,i8 %p25,i8 %p26,i8 %p27,i8 %p28,i8 %p29,i8 %p30,i8 %p31,i8 %p32,i8 %p33,i8 %p34,i8 %p35,i8 %p36,i8 %p37,i8 %p38,i8 %p39,i8 %p40,i8 %p41,i8 %p42,i8 %p43,i8 %p44,i8 %p45,i8 %p46,i8 %p47,i8 %p48,i8 %p49,i8 %p50,i8 %p51,i8 %p52,i8 %p53,i8 %p54,i8 %p55,i8 %p56,i8 %p57,i8 %p58,i8 %p59,i8 %p60,i8 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p8,136
 %left8 = add i8 %p9,153
 %left9 = add i8 %p10,170
 %left10 = add i8 %p11,187
 %left11 = add i8 %p12,204
 %left12 = add i8 %p13,221
 %left13 = add i8 %p14,238
 %left14 = add i8 %p15,255
 %left15 = add i8 %p16,16
 %left16 = add i8 %p17,33
 %left17 = add i8 %p18,50
 %left18 = add i8 %p19,67
 %left19 = add i8 %p20,84
 %left20 = add i8 %p21,101
 %left21 = add i8 %p22,118
 %left22 = add i8 %p23,135
 %left23 = add i8 %p24,152
 %left24 = add i8 %p25,169
 %left25 = add i8 %p26,186
 %left26 = add i8 %p27,203
 %left27 = add i8 %p28,220
 %left28 = add i8 %p29,237
 %left29 = add i8 %p30,254
 %left30 = add i8 %p31,15
 %left31 = add i8 %p32,32
 %left32 = add i8 %p33,49
 %left33 = add i8 %p34,66
 %left34 = add i8 %p35,83
 %left35 = add i8 %p36,100
 %left36 = add i8 %p37,117
 %left37 = add i8 %p38,134
 %left38 = add i8 %p39,151
 %left39 = add i8 %p40,168
 %left40 = add i8 %p41,185
 %left41 = add i8 %p42,202
 %left42 = add i8 %p43,219
 %left43 = add i8 %p44,236
 %left44 = add i8 %p45,253
 %left45 = add i8 %p46,14
 %left46 = add i8 %p47,31
 %left47 = add i8 %p48,48
 %left48 = add i8 %p49,65
 %left49 = add i8 %p50,82
 %left50 = add i8 %p51,99
 %left51 = add i8 %p52,116
 %left52 = add i8 %p53,133
 %left53 = add i8 %p54,150
 %left54 = add i8 %p55,167
 %left55 = add i8 %p56,184
 %left56 = add i8 %p57,201
 %left57 = add i8 %p58,218
 %left58 = add i8 %p59,235
 %left59 = add i8 %p60,252
 %left60 = add i8 %p61,13
 %left61 = add i8 %p0,30
 musttail call fastcc void @self_tail_body_49(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,i8 %left8,i8 %left9,i8 %left10,i8 %left11,i8 %left12,i8 %left13,i8 %left14,i8 %left15,i8 %left16,i8 %left17,i8 %left18,i8 %left19,i8 %left20,i8 %left21,i8 %left22,i8 %left23,i8 %left24,i8 %left25,i8 %left26,i8 %left27,i8 %left28,i8 %left29,i8 %left30,i8 %left31,i8 %left32,i8 %left33,i8 %left34,i8 %left35,i8 %left36,i8 %left37,i8 %left38,i8 %left39,i8 %left40,i8 %left41,i8 %left42,i8 %left43,i8 %left44,i8 %left45,i8 %left46,i8 %left47,i8 %left48,i8 %left49,i8 %left50,i8 %left51,i8 %left52,i8 %left53,i8 %left54,i8 %left55,i8 %left56,i8 %left57,i8 %left58,i8 %left59,i8 %left60,i8 %left61,ptr %out)
 ret void
right:
 %right0 = xor i8 %p61,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right8 = xor i8 %p7,23
 %right9 = xor i8 %p8,54
 %right10 = xor i8 %p9,85
 %right11 = xor i8 %p10,116
 %right12 = xor i8 %p11,147
 %right13 = xor i8 %p12,178
 %right14 = xor i8 %p13,209
 %right15 = xor i8 %p14,240
 %right16 = xor i8 %p15,15
 %right17 = xor i8 %p16,46
 %right18 = xor i8 %p17,77
 %right19 = xor i8 %p18,108
 %right20 = xor i8 %p19,139
 %right21 = xor i8 %p20,170
 %right22 = xor i8 %p21,201
 %right23 = xor i8 %p22,232
 %right24 = xor i8 %p23,7
 %right25 = xor i8 %p24,38
 %right26 = xor i8 %p25,69
 %right27 = xor i8 %p26,100
 %right28 = xor i8 %p27,131
 %right29 = xor i8 %p28,162
 %right30 = xor i8 %p29,193
 %right31 = xor i8 %p30,224
 %right32 = xor i8 %p31,255
 %right33 = xor i8 %p32,30
 %right34 = xor i8 %p33,61
 %right35 = xor i8 %p34,92
 %right36 = xor i8 %p35,123
 %right37 = xor i8 %p36,154
 %right38 = xor i8 %p37,185
 %right39 = xor i8 %p38,216
 %right40 = xor i8 %p39,247
 %right41 = xor i8 %p40,22
 %right42 = xor i8 %p41,53
 %right43 = xor i8 %p42,84
 %right44 = xor i8 %p43,115
 %right45 = xor i8 %p44,146
 %right46 = xor i8 %p45,177
 %right47 = xor i8 %p46,208
 %right48 = xor i8 %p47,239
 %right49 = xor i8 %p48,14
 %right50 = xor i8 %p49,45
 %right51 = xor i8 %p50,76
 %right52 = xor i8 %p51,107
 %right53 = xor i8 %p52,138
 %right54 = xor i8 %p53,169
 %right55 = xor i8 %p54,200
 %right56 = xor i8 %p55,231
 %right57 = xor i8 %p56,6
 %right58 = xor i8 %p57,37
 %right59 = xor i8 %p58,68
 %right60 = xor i8 %p59,99
 %right61 = xor i8 %p60,130
 musttail call fastcc void @self_tail_body_49(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,i8 %right8,i8 %right9,i8 %right10,i8 %right11,i8 %right12,i8 %right13,i8 %right14,i8 %right15,i8 %right16,i8 %right17,i8 %right18,i8 %right19,i8 %right20,i8 %right21,i8 %right22,i8 %right23,i8 %right24,i8 %right25,i8 %right26,i8 %right27,i8 %right28,i8 %right29,i8 %right30,i8 %right31,i8 %right32,i8 %right33,i8 %right34,i8 %right35,i8 %right36,i8 %right37,i8 %right38,i8 %right39,i8 %right40,i8 %right41,i8 %right42,i8 %right43,i8 %right44,i8 %right45,i8 %right46,i8 %right47,i8 %right48,i8 %right49,i8 %right50,i8 %right51,i8 %right52,i8 %right53,i8 %right54,i8 %right55,i8 %right56,i8 %right57,i8 %right58,i8 %right59,i8 %right60,i8 %right61,ptr %out)
 ret void
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i8 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i8 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i8 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i8 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i8 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i8 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i8 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i8 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i8 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i8 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i8 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i8 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i8 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i8 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i8 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i8 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i8 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i8 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i8 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i8 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i8 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i8 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i8 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i8 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i8 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i8 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i8 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i8 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i8 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i8 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i8 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i8 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i8 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i8 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i8 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i8 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i8 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i8 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i8 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i8 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i8 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i8 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i8 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i8 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i8 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i8 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i8 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i8 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i8 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i8 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i8 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i8 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i8 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i8 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_49(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i8
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i8
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i8
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i8
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i8
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i8
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i8
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i8
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i8
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i8
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i8
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i8
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i8
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i8
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i8
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i8
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i8
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i8
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i8
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i8
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i8
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i8
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i8
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i8
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i8
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i8
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i8
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i8
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i8
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i8
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i8
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i8
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i8
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i8
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i8
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i8
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i8
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i8
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i8
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i8
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i8
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i8
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i8
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i8
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i8
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i8
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i8
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i8
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i8
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i8
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i8
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i8
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i8
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i8
 call fastcc void @self_tail_body_49(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,i8 %v8,i8 %v9,i8 %v10,i8 %v11,i8 %v12,i8 %v13,i8 %v14,i8 %v15,i8 %v16,i8 %v17,i8 %v18,i8 %v19,i8 %v20,i8 %v21,i8 %v22,i8 %v23,i8 %v24,i8 %v25,i8 %v26,i8 %v27,i8 %v28,i8 %v29,i8 %v30,i8 %v31,i8 %v32,i8 %v33,i8 %v34,i8 %v35,i8 %v36,i8 %v37,i8 %v38,i8 %v39,i8 %v40,i8 %v41,i8 %v42,i8 %v43,i8 %v44,i8 %v45,i8 %v46,i8 %v47,i8 %v48,i8 %v49,i8 %v50,i8 %v51,i8 %v52,i8 %v53,i8 %v54,i8 %v55,i8 %v56,i8 %v57,i8 %v58,i8 %v59,i8 %v60,i8 %v61,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,255
 ret i64 %result
}
define internal void @self_tail_body_50(i64 %n,i16 %p0,i16 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p0,34
 musttail call void @self_tail_body_50(i64 %next,i16 %left0,i16 %left1,ptr %out)
 ret void
right:
 %right0 = xor i16 %p1,31
 %right1 = xor i16 %p0,62
 musttail call void @self_tail_body_50(i64 %next,i16 %right0,i16 %right1,ptr %out)
 ret void
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_50(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 call void @self_tail_body_50(i64 %count,i16 %v0,i16 %v1,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,65535
 ret i64 %result
}
define internal fastcc void @self_tail_body_51(i64 %n,i16 %p0,i16 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p0,34
 musttail call fastcc void @self_tail_body_51(i64 %next,i16 %left0,i16 %left1,ptr %out)
 ret void
right:
 %right0 = xor i16 %p1,31
 %right1 = xor i16 %p0,62
 musttail call fastcc void @self_tail_body_51(i64 %next,i16 %right0,i16 %right1,ptr %out)
 ret void
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_51(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 call fastcc void @self_tail_body_51(i64 %count,i16 %v0,i16 %v1,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,65535
 ret i64 %result
}
define internal void @self_tail_body_52(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p0,85
 musttail call void @self_tail_body_52(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,ptr %out)
 ret void
right:
 %right0 = xor i16 %p4,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 musttail call void @self_tail_body_52(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,ptr %out)
 ret void
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_52(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 call void @self_tail_body_52(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,65535
 ret i64 %result
}
define internal fastcc void @self_tail_body_53(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p0,85
 musttail call fastcc void @self_tail_body_53(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,ptr %out)
 ret void
right:
 %right0 = xor i16 %p4,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 musttail call fastcc void @self_tail_body_53(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,ptr %out)
 ret void
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_53(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 call fastcc void @self_tail_body_53(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,65535
 ret i64 %result
}
define internal void @self_tail_body_54(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p0,136
 musttail call void @self_tail_body_54(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,ptr %out)
 ret void
right:
 %right0 = xor i16 %p7,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 musttail call void @self_tail_body_54(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,ptr %out)
 ret void
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_54(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 call void @self_tail_body_54(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,65535
 ret i64 %result
}
define internal fastcc void @self_tail_body_55(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p0,136
 musttail call fastcc void @self_tail_body_55(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,ptr %out)
 ret void
right:
 %right0 = xor i16 %p7,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 musttail call fastcc void @self_tail_body_55(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,ptr %out)
 ret void
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_55(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 call fastcc void @self_tail_body_55(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,65535
 ret i64 %result
}
define internal void @self_tail_body_56(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,i16 %p8,i16 %p9,i16 %p10,i16 %p11,i16 %p12,i16 %p13,i16 %p14,i16 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p8,136
 %left8 = add i16 %p9,153
 %left9 = add i16 %p10,170
 %left10 = add i16 %p11,187
 %left11 = add i16 %p12,204
 %left12 = add i16 %p13,221
 %left13 = add i16 %p14,238
 %left14 = add i16 %p15,255
 %left15 = add i16 %p0,272
 musttail call void @self_tail_body_56(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,i16 %left8,i16 %left9,i16 %left10,i16 %left11,i16 %left12,i16 %left13,i16 %left14,i16 %left15,ptr %out)
 ret void
right:
 %right0 = xor i16 %p15,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right8 = xor i16 %p7,279
 %right9 = xor i16 %p8,310
 %right10 = xor i16 %p9,341
 %right11 = xor i16 %p10,372
 %right12 = xor i16 %p11,403
 %right13 = xor i16 %p12,434
 %right14 = xor i16 %p13,465
 %right15 = xor i16 %p14,496
 musttail call void @self_tail_body_56(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,i16 %right8,i16 %right9,i16 %right10,i16 %right11,i16 %right12,i16 %right13,i16 %right14,i16 %right15,ptr %out)
 ret void
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i16 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i16 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i16 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i16 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i16 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i16 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i16 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i16 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_56(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i16
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i16
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i16
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i16
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i16
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i16
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i16
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i16
 call void @self_tail_body_56(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,i16 %v8,i16 %v9,i16 %v10,i16 %v11,i16 %v12,i16 %v13,i16 %v14,i16 %v15,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,65535
 ret i64 %result
}
define internal fastcc void @self_tail_body_57(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,i16 %p8,i16 %p9,i16 %p10,i16 %p11,i16 %p12,i16 %p13,i16 %p14,i16 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p8,136
 %left8 = add i16 %p9,153
 %left9 = add i16 %p10,170
 %left10 = add i16 %p11,187
 %left11 = add i16 %p12,204
 %left12 = add i16 %p13,221
 %left13 = add i16 %p14,238
 %left14 = add i16 %p15,255
 %left15 = add i16 %p0,272
 musttail call fastcc void @self_tail_body_57(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,i16 %left8,i16 %left9,i16 %left10,i16 %left11,i16 %left12,i16 %left13,i16 %left14,i16 %left15,ptr %out)
 ret void
right:
 %right0 = xor i16 %p15,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right8 = xor i16 %p7,279
 %right9 = xor i16 %p8,310
 %right10 = xor i16 %p9,341
 %right11 = xor i16 %p10,372
 %right12 = xor i16 %p11,403
 %right13 = xor i16 %p12,434
 %right14 = xor i16 %p13,465
 %right15 = xor i16 %p14,496
 musttail call fastcc void @self_tail_body_57(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,i16 %right8,i16 %right9,i16 %right10,i16 %right11,i16 %right12,i16 %right13,i16 %right14,i16 %right15,ptr %out)
 ret void
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i16 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i16 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i16 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i16 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i16 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i16 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i16 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i16 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_57(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i16
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i16
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i16
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i16
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i16
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i16
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i16
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i16
 call fastcc void @self_tail_body_57(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,i16 %v8,i16 %v9,i16 %v10,i16 %v11,i16 %v12,i16 %v13,i16 %v14,i16 %v15,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,65535
 ret i64 %result
}
define internal void @self_tail_body_58(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,i16 %p8,i16 %p9,i16 %p10,i16 %p11,i16 %p12,i16 %p13,i16 %p14,i16 %p15,i16 %p16,i16 %p17,i16 %p18,i16 %p19,i16 %p20,i16 %p21,i16 %p22,i16 %p23,i16 %p24,i16 %p25,i16 %p26,i16 %p27,i16 %p28,i16 %p29,i16 %p30,i16 %p31,i16 %p32,i16 %p33,i16 %p34,i16 %p35,i16 %p36,i16 %p37,i16 %p38,i16 %p39,i16 %p40,i16 %p41,i16 %p42,i16 %p43,i16 %p44,i16 %p45,i16 %p46,i16 %p47,i16 %p48,i16 %p49,i16 %p50,i16 %p51,i16 %p52,i16 %p53,i16 %p54,i16 %p55,i16 %p56,i16 %p57,i16 %p58,i16 %p59,i16 %p60,i16 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p8,136
 %left8 = add i16 %p9,153
 %left9 = add i16 %p10,170
 %left10 = add i16 %p11,187
 %left11 = add i16 %p12,204
 %left12 = add i16 %p13,221
 %left13 = add i16 %p14,238
 %left14 = add i16 %p15,255
 %left15 = add i16 %p16,272
 %left16 = add i16 %p17,289
 %left17 = add i16 %p18,306
 %left18 = add i16 %p19,323
 %left19 = add i16 %p20,340
 %left20 = add i16 %p21,357
 %left21 = add i16 %p22,374
 %left22 = add i16 %p23,391
 %left23 = add i16 %p24,408
 %left24 = add i16 %p25,425
 %left25 = add i16 %p26,442
 %left26 = add i16 %p27,459
 %left27 = add i16 %p28,476
 %left28 = add i16 %p29,493
 %left29 = add i16 %p30,510
 %left30 = add i16 %p31,527
 %left31 = add i16 %p32,544
 %left32 = add i16 %p33,561
 %left33 = add i16 %p34,578
 %left34 = add i16 %p35,595
 %left35 = add i16 %p36,612
 %left36 = add i16 %p37,629
 %left37 = add i16 %p38,646
 %left38 = add i16 %p39,663
 %left39 = add i16 %p40,680
 %left40 = add i16 %p41,697
 %left41 = add i16 %p42,714
 %left42 = add i16 %p43,731
 %left43 = add i16 %p44,748
 %left44 = add i16 %p45,765
 %left45 = add i16 %p46,782
 %left46 = add i16 %p47,799
 %left47 = add i16 %p48,816
 %left48 = add i16 %p49,833
 %left49 = add i16 %p50,850
 %left50 = add i16 %p51,867
 %left51 = add i16 %p52,884
 %left52 = add i16 %p53,901
 %left53 = add i16 %p54,918
 %left54 = add i16 %p55,935
 %left55 = add i16 %p56,952
 %left56 = add i16 %p57,969
 %left57 = add i16 %p58,986
 %left58 = add i16 %p59,1003
 %left59 = add i16 %p60,1020
 %left60 = add i16 %p61,1037
 %left61 = add i16 %p0,1054
 musttail call void @self_tail_body_58(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,i16 %left8,i16 %left9,i16 %left10,i16 %left11,i16 %left12,i16 %left13,i16 %left14,i16 %left15,i16 %left16,i16 %left17,i16 %left18,i16 %left19,i16 %left20,i16 %left21,i16 %left22,i16 %left23,i16 %left24,i16 %left25,i16 %left26,i16 %left27,i16 %left28,i16 %left29,i16 %left30,i16 %left31,i16 %left32,i16 %left33,i16 %left34,i16 %left35,i16 %left36,i16 %left37,i16 %left38,i16 %left39,i16 %left40,i16 %left41,i16 %left42,i16 %left43,i16 %left44,i16 %left45,i16 %left46,i16 %left47,i16 %left48,i16 %left49,i16 %left50,i16 %left51,i16 %left52,i16 %left53,i16 %left54,i16 %left55,i16 %left56,i16 %left57,i16 %left58,i16 %left59,i16 %left60,i16 %left61,ptr %out)
 ret void
right:
 %right0 = xor i16 %p61,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right8 = xor i16 %p7,279
 %right9 = xor i16 %p8,310
 %right10 = xor i16 %p9,341
 %right11 = xor i16 %p10,372
 %right12 = xor i16 %p11,403
 %right13 = xor i16 %p12,434
 %right14 = xor i16 %p13,465
 %right15 = xor i16 %p14,496
 %right16 = xor i16 %p15,527
 %right17 = xor i16 %p16,558
 %right18 = xor i16 %p17,589
 %right19 = xor i16 %p18,620
 %right20 = xor i16 %p19,651
 %right21 = xor i16 %p20,682
 %right22 = xor i16 %p21,713
 %right23 = xor i16 %p22,744
 %right24 = xor i16 %p23,775
 %right25 = xor i16 %p24,806
 %right26 = xor i16 %p25,837
 %right27 = xor i16 %p26,868
 %right28 = xor i16 %p27,899
 %right29 = xor i16 %p28,930
 %right30 = xor i16 %p29,961
 %right31 = xor i16 %p30,992
 %right32 = xor i16 %p31,1023
 %right33 = xor i16 %p32,1054
 %right34 = xor i16 %p33,1085
 %right35 = xor i16 %p34,1116
 %right36 = xor i16 %p35,1147
 %right37 = xor i16 %p36,1178
 %right38 = xor i16 %p37,1209
 %right39 = xor i16 %p38,1240
 %right40 = xor i16 %p39,1271
 %right41 = xor i16 %p40,1302
 %right42 = xor i16 %p41,1333
 %right43 = xor i16 %p42,1364
 %right44 = xor i16 %p43,1395
 %right45 = xor i16 %p44,1426
 %right46 = xor i16 %p45,1457
 %right47 = xor i16 %p46,1488
 %right48 = xor i16 %p47,1519
 %right49 = xor i16 %p48,1550
 %right50 = xor i16 %p49,1581
 %right51 = xor i16 %p50,1612
 %right52 = xor i16 %p51,1643
 %right53 = xor i16 %p52,1674
 %right54 = xor i16 %p53,1705
 %right55 = xor i16 %p54,1736
 %right56 = xor i16 %p55,1767
 %right57 = xor i16 %p56,1798
 %right58 = xor i16 %p57,1829
 %right59 = xor i16 %p58,1860
 %right60 = xor i16 %p59,1891
 %right61 = xor i16 %p60,1922
 musttail call void @self_tail_body_58(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,i16 %right8,i16 %right9,i16 %right10,i16 %right11,i16 %right12,i16 %right13,i16 %right14,i16 %right15,i16 %right16,i16 %right17,i16 %right18,i16 %right19,i16 %right20,i16 %right21,i16 %right22,i16 %right23,i16 %right24,i16 %right25,i16 %right26,i16 %right27,i16 %right28,i16 %right29,i16 %right30,i16 %right31,i16 %right32,i16 %right33,i16 %right34,i16 %right35,i16 %right36,i16 %right37,i16 %right38,i16 %right39,i16 %right40,i16 %right41,i16 %right42,i16 %right43,i16 %right44,i16 %right45,i16 %right46,i16 %right47,i16 %right48,i16 %right49,i16 %right50,i16 %right51,i16 %right52,i16 %right53,i16 %right54,i16 %right55,i16 %right56,i16 %right57,i16 %right58,i16 %right59,i16 %right60,i16 %right61,ptr %out)
 ret void
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i16 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i16 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i16 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i16 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i16 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i16 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i16 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i16 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i16 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i16 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i16 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i16 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i16 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i16 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i16 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i16 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i16 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i16 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i16 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i16 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i16 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i16 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i16 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i16 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i16 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i16 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i16 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i16 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i16 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i16 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i16 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i16 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i16 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i16 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i16 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i16 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i16 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i16 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i16 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i16 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i16 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i16 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i16 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i16 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i16 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i16 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i16 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i16 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i16 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i16 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i16 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i16 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i16 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i16 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_58(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i16
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i16
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i16
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i16
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i16
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i16
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i16
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i16
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i16
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i16
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i16
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i16
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i16
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i16
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i16
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i16
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i16
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i16
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i16
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i16
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i16
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i16
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i16
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i16
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i16
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i16
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i16
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i16
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i16
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i16
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i16
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i16
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i16
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i16
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i16
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i16
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i16
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i16
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i16
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i16
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i16
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i16
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i16
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i16
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i16
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i16
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i16
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i16
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i16
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i16
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i16
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i16
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i16
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i16
 call void @self_tail_body_58(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,i16 %v8,i16 %v9,i16 %v10,i16 %v11,i16 %v12,i16 %v13,i16 %v14,i16 %v15,i16 %v16,i16 %v17,i16 %v18,i16 %v19,i16 %v20,i16 %v21,i16 %v22,i16 %v23,i16 %v24,i16 %v25,i16 %v26,i16 %v27,i16 %v28,i16 %v29,i16 %v30,i16 %v31,i16 %v32,i16 %v33,i16 %v34,i16 %v35,i16 %v36,i16 %v37,i16 %v38,i16 %v39,i16 %v40,i16 %v41,i16 %v42,i16 %v43,i16 %v44,i16 %v45,i16 %v46,i16 %v47,i16 %v48,i16 %v49,i16 %v50,i16 %v51,i16 %v52,i16 %v53,i16 %v54,i16 %v55,i16 %v56,i16 %v57,i16 %v58,i16 %v59,i16 %v60,i16 %v61,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,65535
 ret i64 %result
}
define internal fastcc void @self_tail_body_59(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,i16 %p8,i16 %p9,i16 %p10,i16 %p11,i16 %p12,i16 %p13,i16 %p14,i16 %p15,i16 %p16,i16 %p17,i16 %p18,i16 %p19,i16 %p20,i16 %p21,i16 %p22,i16 %p23,i16 %p24,i16 %p25,i16 %p26,i16 %p27,i16 %p28,i16 %p29,i16 %p30,i16 %p31,i16 %p32,i16 %p33,i16 %p34,i16 %p35,i16 %p36,i16 %p37,i16 %p38,i16 %p39,i16 %p40,i16 %p41,i16 %p42,i16 %p43,i16 %p44,i16 %p45,i16 %p46,i16 %p47,i16 %p48,i16 %p49,i16 %p50,i16 %p51,i16 %p52,i16 %p53,i16 %p54,i16 %p55,i16 %p56,i16 %p57,i16 %p58,i16 %p59,i16 %p60,i16 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p8,136
 %left8 = add i16 %p9,153
 %left9 = add i16 %p10,170
 %left10 = add i16 %p11,187
 %left11 = add i16 %p12,204
 %left12 = add i16 %p13,221
 %left13 = add i16 %p14,238
 %left14 = add i16 %p15,255
 %left15 = add i16 %p16,272
 %left16 = add i16 %p17,289
 %left17 = add i16 %p18,306
 %left18 = add i16 %p19,323
 %left19 = add i16 %p20,340
 %left20 = add i16 %p21,357
 %left21 = add i16 %p22,374
 %left22 = add i16 %p23,391
 %left23 = add i16 %p24,408
 %left24 = add i16 %p25,425
 %left25 = add i16 %p26,442
 %left26 = add i16 %p27,459
 %left27 = add i16 %p28,476
 %left28 = add i16 %p29,493
 %left29 = add i16 %p30,510
 %left30 = add i16 %p31,527
 %left31 = add i16 %p32,544
 %left32 = add i16 %p33,561
 %left33 = add i16 %p34,578
 %left34 = add i16 %p35,595
 %left35 = add i16 %p36,612
 %left36 = add i16 %p37,629
 %left37 = add i16 %p38,646
 %left38 = add i16 %p39,663
 %left39 = add i16 %p40,680
 %left40 = add i16 %p41,697
 %left41 = add i16 %p42,714
 %left42 = add i16 %p43,731
 %left43 = add i16 %p44,748
 %left44 = add i16 %p45,765
 %left45 = add i16 %p46,782
 %left46 = add i16 %p47,799
 %left47 = add i16 %p48,816
 %left48 = add i16 %p49,833
 %left49 = add i16 %p50,850
 %left50 = add i16 %p51,867
 %left51 = add i16 %p52,884
 %left52 = add i16 %p53,901
 %left53 = add i16 %p54,918
 %left54 = add i16 %p55,935
 %left55 = add i16 %p56,952
 %left56 = add i16 %p57,969
 %left57 = add i16 %p58,986
 %left58 = add i16 %p59,1003
 %left59 = add i16 %p60,1020
 %left60 = add i16 %p61,1037
 %left61 = add i16 %p0,1054
 musttail call fastcc void @self_tail_body_59(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,i16 %left8,i16 %left9,i16 %left10,i16 %left11,i16 %left12,i16 %left13,i16 %left14,i16 %left15,i16 %left16,i16 %left17,i16 %left18,i16 %left19,i16 %left20,i16 %left21,i16 %left22,i16 %left23,i16 %left24,i16 %left25,i16 %left26,i16 %left27,i16 %left28,i16 %left29,i16 %left30,i16 %left31,i16 %left32,i16 %left33,i16 %left34,i16 %left35,i16 %left36,i16 %left37,i16 %left38,i16 %left39,i16 %left40,i16 %left41,i16 %left42,i16 %left43,i16 %left44,i16 %left45,i16 %left46,i16 %left47,i16 %left48,i16 %left49,i16 %left50,i16 %left51,i16 %left52,i16 %left53,i16 %left54,i16 %left55,i16 %left56,i16 %left57,i16 %left58,i16 %left59,i16 %left60,i16 %left61,ptr %out)
 ret void
right:
 %right0 = xor i16 %p61,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right8 = xor i16 %p7,279
 %right9 = xor i16 %p8,310
 %right10 = xor i16 %p9,341
 %right11 = xor i16 %p10,372
 %right12 = xor i16 %p11,403
 %right13 = xor i16 %p12,434
 %right14 = xor i16 %p13,465
 %right15 = xor i16 %p14,496
 %right16 = xor i16 %p15,527
 %right17 = xor i16 %p16,558
 %right18 = xor i16 %p17,589
 %right19 = xor i16 %p18,620
 %right20 = xor i16 %p19,651
 %right21 = xor i16 %p20,682
 %right22 = xor i16 %p21,713
 %right23 = xor i16 %p22,744
 %right24 = xor i16 %p23,775
 %right25 = xor i16 %p24,806
 %right26 = xor i16 %p25,837
 %right27 = xor i16 %p26,868
 %right28 = xor i16 %p27,899
 %right29 = xor i16 %p28,930
 %right30 = xor i16 %p29,961
 %right31 = xor i16 %p30,992
 %right32 = xor i16 %p31,1023
 %right33 = xor i16 %p32,1054
 %right34 = xor i16 %p33,1085
 %right35 = xor i16 %p34,1116
 %right36 = xor i16 %p35,1147
 %right37 = xor i16 %p36,1178
 %right38 = xor i16 %p37,1209
 %right39 = xor i16 %p38,1240
 %right40 = xor i16 %p39,1271
 %right41 = xor i16 %p40,1302
 %right42 = xor i16 %p41,1333
 %right43 = xor i16 %p42,1364
 %right44 = xor i16 %p43,1395
 %right45 = xor i16 %p44,1426
 %right46 = xor i16 %p45,1457
 %right47 = xor i16 %p46,1488
 %right48 = xor i16 %p47,1519
 %right49 = xor i16 %p48,1550
 %right50 = xor i16 %p49,1581
 %right51 = xor i16 %p50,1612
 %right52 = xor i16 %p51,1643
 %right53 = xor i16 %p52,1674
 %right54 = xor i16 %p53,1705
 %right55 = xor i16 %p54,1736
 %right56 = xor i16 %p55,1767
 %right57 = xor i16 %p56,1798
 %right58 = xor i16 %p57,1829
 %right59 = xor i16 %p58,1860
 %right60 = xor i16 %p59,1891
 %right61 = xor i16 %p60,1922
 musttail call fastcc void @self_tail_body_59(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,i16 %right8,i16 %right9,i16 %right10,i16 %right11,i16 %right12,i16 %right13,i16 %right14,i16 %right15,i16 %right16,i16 %right17,i16 %right18,i16 %right19,i16 %right20,i16 %right21,i16 %right22,i16 %right23,i16 %right24,i16 %right25,i16 %right26,i16 %right27,i16 %right28,i16 %right29,i16 %right30,i16 %right31,i16 %right32,i16 %right33,i16 %right34,i16 %right35,i16 %right36,i16 %right37,i16 %right38,i16 %right39,i16 %right40,i16 %right41,i16 %right42,i16 %right43,i16 %right44,i16 %right45,i16 %right46,i16 %right47,i16 %right48,i16 %right49,i16 %right50,i16 %right51,i16 %right52,i16 %right53,i16 %right54,i16 %right55,i16 %right56,i16 %right57,i16 %right58,i16 %right59,i16 %right60,i16 %right61,ptr %out)
 ret void
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i16 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i16 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i16 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i16 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i16 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i16 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i16 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i16 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i16 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i16 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i16 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i16 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i16 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i16 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i16 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i16 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i16 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i16 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i16 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i16 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i16 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i16 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i16 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i16 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i16 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i16 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i16 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i16 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i16 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i16 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i16 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i16 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i16 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i16 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i16 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i16 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i16 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i16 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i16 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i16 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i16 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i16 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i16 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i16 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i16 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i16 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i16 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i16 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i16 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i16 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i16 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i16 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i16 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i16 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_59(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i16
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i16
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i16
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i16
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i16
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i16
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i16
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i16
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i16
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i16
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i16
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i16
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i16
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i16
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i16
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i16
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i16
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i16
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i16
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i16
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i16
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i16
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i16
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i16
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i16
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i16
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i16
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i16
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i16
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i16
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i16
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i16
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i16
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i16
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i16
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i16
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i16
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i16
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i16
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i16
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i16
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i16
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i16
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i16
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i16
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i16
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i16
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i16
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i16
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i16
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i16
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i16
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i16
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i16
 call fastcc void @self_tail_body_59(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,i16 %v8,i16 %v9,i16 %v10,i16 %v11,i16 %v12,i16 %v13,i16 %v14,i16 %v15,i16 %v16,i16 %v17,i16 %v18,i16 %v19,i16 %v20,i16 %v21,i16 %v22,i16 %v23,i16 %v24,i16 %v25,i16 %v26,i16 %v27,i16 %v28,i16 %v29,i16 %v30,i16 %v31,i16 %v32,i16 %v33,i16 %v34,i16 %v35,i16 %v36,i16 %v37,i16 %v38,i16 %v39,i16 %v40,i16 %v41,i16 %v42,i16 %v43,i16 %v44,i16 %v45,i16 %v46,i16 %v47,i16 %v48,i16 %v49,i16 %v50,i16 %v51,i16 %v52,i16 %v53,i16 %v54,i16 %v55,i16 %v56,i16 %v57,i16 %v58,i16 %v59,i16 %v60,i16 %v61,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,65535
 ret i64 %result
}
define internal void @self_tail_body_60(i64 %n,i32 %p0,i32 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p0,34
 musttail call void @self_tail_body_60(i64 %next,i32 %left0,i32 %left1,ptr %out)
 ret void
right:
 %right0 = xor i32 %p1,31
 %right1 = xor i32 %p0,62
 musttail call void @self_tail_body_60(i64 %next,i32 %right0,i32 %right1,ptr %out)
 ret void
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_60(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 call void @self_tail_body_60(i64 %count,i32 %v0,i32 %v1,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,4294967295
 ret i64 %result
}
define internal fastcc void @self_tail_body_61(i64 %n,i32 %p0,i32 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p0,34
 musttail call fastcc void @self_tail_body_61(i64 %next,i32 %left0,i32 %left1,ptr %out)
 ret void
right:
 %right0 = xor i32 %p1,31
 %right1 = xor i32 %p0,62
 musttail call fastcc void @self_tail_body_61(i64 %next,i32 %right0,i32 %right1,ptr %out)
 ret void
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_61(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 call fastcc void @self_tail_body_61(i64 %count,i32 %v0,i32 %v1,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,4294967295
 ret i64 %result
}
define internal void @self_tail_body_62(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p0,85
 musttail call void @self_tail_body_62(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,ptr %out)
 ret void
right:
 %right0 = xor i32 %p4,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 musttail call void @self_tail_body_62(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,ptr %out)
 ret void
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_62(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 call void @self_tail_body_62(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,4294967295
 ret i64 %result
}
define internal fastcc void @self_tail_body_63(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p0,85
 musttail call fastcc void @self_tail_body_63(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,ptr %out)
 ret void
right:
 %right0 = xor i32 %p4,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 musttail call fastcc void @self_tail_body_63(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,ptr %out)
 ret void
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_63(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 call fastcc void @self_tail_body_63(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,4294967295
 ret i64 %result
}
define internal void @self_tail_body_64(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p0,136
 musttail call void @self_tail_body_64(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,ptr %out)
 ret void
right:
 %right0 = xor i32 %p7,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 musttail call void @self_tail_body_64(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,ptr %out)
 ret void
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_64(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 call void @self_tail_body_64(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,4294967295
 ret i64 %result
}
define internal fastcc void @self_tail_body_65(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p0,136
 musttail call fastcc void @self_tail_body_65(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,ptr %out)
 ret void
right:
 %right0 = xor i32 %p7,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 musttail call fastcc void @self_tail_body_65(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,ptr %out)
 ret void
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_65(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 call fastcc void @self_tail_body_65(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,4294967295
 ret i64 %result
}
define internal void @self_tail_body_66(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,i32 %p8,i32 %p9,i32 %p10,i32 %p11,i32 %p12,i32 %p13,i32 %p14,i32 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p8,136
 %left8 = add i32 %p9,153
 %left9 = add i32 %p10,170
 %left10 = add i32 %p11,187
 %left11 = add i32 %p12,204
 %left12 = add i32 %p13,221
 %left13 = add i32 %p14,238
 %left14 = add i32 %p15,255
 %left15 = add i32 %p0,272
 musttail call void @self_tail_body_66(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,i32 %left8,i32 %left9,i32 %left10,i32 %left11,i32 %left12,i32 %left13,i32 %left14,i32 %left15,ptr %out)
 ret void
right:
 %right0 = xor i32 %p15,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right8 = xor i32 %p7,279
 %right9 = xor i32 %p8,310
 %right10 = xor i32 %p9,341
 %right11 = xor i32 %p10,372
 %right12 = xor i32 %p11,403
 %right13 = xor i32 %p12,434
 %right14 = xor i32 %p13,465
 %right15 = xor i32 %p14,496
 musttail call void @self_tail_body_66(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,i32 %right8,i32 %right9,i32 %right10,i32 %right11,i32 %right12,i32 %right13,i32 %right14,i32 %right15,ptr %out)
 ret void
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i32 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i32 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i32 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i32 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i32 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i32 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i32 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i32 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_66(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i32
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i32
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i32
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i32
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i32
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i32
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i32
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i32
 call void @self_tail_body_66(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,i32 %v8,i32 %v9,i32 %v10,i32 %v11,i32 %v12,i32 %v13,i32 %v14,i32 %v15,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,4294967295
 ret i64 %result
}
define internal fastcc void @self_tail_body_67(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,i32 %p8,i32 %p9,i32 %p10,i32 %p11,i32 %p12,i32 %p13,i32 %p14,i32 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p8,136
 %left8 = add i32 %p9,153
 %left9 = add i32 %p10,170
 %left10 = add i32 %p11,187
 %left11 = add i32 %p12,204
 %left12 = add i32 %p13,221
 %left13 = add i32 %p14,238
 %left14 = add i32 %p15,255
 %left15 = add i32 %p0,272
 musttail call fastcc void @self_tail_body_67(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,i32 %left8,i32 %left9,i32 %left10,i32 %left11,i32 %left12,i32 %left13,i32 %left14,i32 %left15,ptr %out)
 ret void
right:
 %right0 = xor i32 %p15,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right8 = xor i32 %p7,279
 %right9 = xor i32 %p8,310
 %right10 = xor i32 %p9,341
 %right11 = xor i32 %p10,372
 %right12 = xor i32 %p11,403
 %right13 = xor i32 %p12,434
 %right14 = xor i32 %p13,465
 %right15 = xor i32 %p14,496
 musttail call fastcc void @self_tail_body_67(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,i32 %right8,i32 %right9,i32 %right10,i32 %right11,i32 %right12,i32 %right13,i32 %right14,i32 %right15,ptr %out)
 ret void
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i32 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i32 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i32 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i32 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i32 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i32 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i32 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i32 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_67(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i32
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i32
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i32
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i32
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i32
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i32
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i32
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i32
 call fastcc void @self_tail_body_67(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,i32 %v8,i32 %v9,i32 %v10,i32 %v11,i32 %v12,i32 %v13,i32 %v14,i32 %v15,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,4294967295
 ret i64 %result
}
define internal void @self_tail_body_68(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,i32 %p8,i32 %p9,i32 %p10,i32 %p11,i32 %p12,i32 %p13,i32 %p14,i32 %p15,i32 %p16,i32 %p17,i32 %p18,i32 %p19,i32 %p20,i32 %p21,i32 %p22,i32 %p23,i32 %p24,i32 %p25,i32 %p26,i32 %p27,i32 %p28,i32 %p29,i32 %p30,i32 %p31,i32 %p32,i32 %p33,i32 %p34,i32 %p35,i32 %p36,i32 %p37,i32 %p38,i32 %p39,i32 %p40,i32 %p41,i32 %p42,i32 %p43,i32 %p44,i32 %p45,i32 %p46,i32 %p47,i32 %p48,i32 %p49,i32 %p50,i32 %p51,i32 %p52,i32 %p53,i32 %p54,i32 %p55,i32 %p56,i32 %p57,i32 %p58,i32 %p59,i32 %p60,i32 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p8,136
 %left8 = add i32 %p9,153
 %left9 = add i32 %p10,170
 %left10 = add i32 %p11,187
 %left11 = add i32 %p12,204
 %left12 = add i32 %p13,221
 %left13 = add i32 %p14,238
 %left14 = add i32 %p15,255
 %left15 = add i32 %p16,272
 %left16 = add i32 %p17,289
 %left17 = add i32 %p18,306
 %left18 = add i32 %p19,323
 %left19 = add i32 %p20,340
 %left20 = add i32 %p21,357
 %left21 = add i32 %p22,374
 %left22 = add i32 %p23,391
 %left23 = add i32 %p24,408
 %left24 = add i32 %p25,425
 %left25 = add i32 %p26,442
 %left26 = add i32 %p27,459
 %left27 = add i32 %p28,476
 %left28 = add i32 %p29,493
 %left29 = add i32 %p30,510
 %left30 = add i32 %p31,527
 %left31 = add i32 %p32,544
 %left32 = add i32 %p33,561
 %left33 = add i32 %p34,578
 %left34 = add i32 %p35,595
 %left35 = add i32 %p36,612
 %left36 = add i32 %p37,629
 %left37 = add i32 %p38,646
 %left38 = add i32 %p39,663
 %left39 = add i32 %p40,680
 %left40 = add i32 %p41,697
 %left41 = add i32 %p42,714
 %left42 = add i32 %p43,731
 %left43 = add i32 %p44,748
 %left44 = add i32 %p45,765
 %left45 = add i32 %p46,782
 %left46 = add i32 %p47,799
 %left47 = add i32 %p48,816
 %left48 = add i32 %p49,833
 %left49 = add i32 %p50,850
 %left50 = add i32 %p51,867
 %left51 = add i32 %p52,884
 %left52 = add i32 %p53,901
 %left53 = add i32 %p54,918
 %left54 = add i32 %p55,935
 %left55 = add i32 %p56,952
 %left56 = add i32 %p57,969
 %left57 = add i32 %p58,986
 %left58 = add i32 %p59,1003
 %left59 = add i32 %p60,1020
 %left60 = add i32 %p61,1037
 %left61 = add i32 %p0,1054
 musttail call void @self_tail_body_68(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,i32 %left8,i32 %left9,i32 %left10,i32 %left11,i32 %left12,i32 %left13,i32 %left14,i32 %left15,i32 %left16,i32 %left17,i32 %left18,i32 %left19,i32 %left20,i32 %left21,i32 %left22,i32 %left23,i32 %left24,i32 %left25,i32 %left26,i32 %left27,i32 %left28,i32 %left29,i32 %left30,i32 %left31,i32 %left32,i32 %left33,i32 %left34,i32 %left35,i32 %left36,i32 %left37,i32 %left38,i32 %left39,i32 %left40,i32 %left41,i32 %left42,i32 %left43,i32 %left44,i32 %left45,i32 %left46,i32 %left47,i32 %left48,i32 %left49,i32 %left50,i32 %left51,i32 %left52,i32 %left53,i32 %left54,i32 %left55,i32 %left56,i32 %left57,i32 %left58,i32 %left59,i32 %left60,i32 %left61,ptr %out)
 ret void
right:
 %right0 = xor i32 %p61,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right8 = xor i32 %p7,279
 %right9 = xor i32 %p8,310
 %right10 = xor i32 %p9,341
 %right11 = xor i32 %p10,372
 %right12 = xor i32 %p11,403
 %right13 = xor i32 %p12,434
 %right14 = xor i32 %p13,465
 %right15 = xor i32 %p14,496
 %right16 = xor i32 %p15,527
 %right17 = xor i32 %p16,558
 %right18 = xor i32 %p17,589
 %right19 = xor i32 %p18,620
 %right20 = xor i32 %p19,651
 %right21 = xor i32 %p20,682
 %right22 = xor i32 %p21,713
 %right23 = xor i32 %p22,744
 %right24 = xor i32 %p23,775
 %right25 = xor i32 %p24,806
 %right26 = xor i32 %p25,837
 %right27 = xor i32 %p26,868
 %right28 = xor i32 %p27,899
 %right29 = xor i32 %p28,930
 %right30 = xor i32 %p29,961
 %right31 = xor i32 %p30,992
 %right32 = xor i32 %p31,1023
 %right33 = xor i32 %p32,1054
 %right34 = xor i32 %p33,1085
 %right35 = xor i32 %p34,1116
 %right36 = xor i32 %p35,1147
 %right37 = xor i32 %p36,1178
 %right38 = xor i32 %p37,1209
 %right39 = xor i32 %p38,1240
 %right40 = xor i32 %p39,1271
 %right41 = xor i32 %p40,1302
 %right42 = xor i32 %p41,1333
 %right43 = xor i32 %p42,1364
 %right44 = xor i32 %p43,1395
 %right45 = xor i32 %p44,1426
 %right46 = xor i32 %p45,1457
 %right47 = xor i32 %p46,1488
 %right48 = xor i32 %p47,1519
 %right49 = xor i32 %p48,1550
 %right50 = xor i32 %p49,1581
 %right51 = xor i32 %p50,1612
 %right52 = xor i32 %p51,1643
 %right53 = xor i32 %p52,1674
 %right54 = xor i32 %p53,1705
 %right55 = xor i32 %p54,1736
 %right56 = xor i32 %p55,1767
 %right57 = xor i32 %p56,1798
 %right58 = xor i32 %p57,1829
 %right59 = xor i32 %p58,1860
 %right60 = xor i32 %p59,1891
 %right61 = xor i32 %p60,1922
 musttail call void @self_tail_body_68(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,i32 %right8,i32 %right9,i32 %right10,i32 %right11,i32 %right12,i32 %right13,i32 %right14,i32 %right15,i32 %right16,i32 %right17,i32 %right18,i32 %right19,i32 %right20,i32 %right21,i32 %right22,i32 %right23,i32 %right24,i32 %right25,i32 %right26,i32 %right27,i32 %right28,i32 %right29,i32 %right30,i32 %right31,i32 %right32,i32 %right33,i32 %right34,i32 %right35,i32 %right36,i32 %right37,i32 %right38,i32 %right39,i32 %right40,i32 %right41,i32 %right42,i32 %right43,i32 %right44,i32 %right45,i32 %right46,i32 %right47,i32 %right48,i32 %right49,i32 %right50,i32 %right51,i32 %right52,i32 %right53,i32 %right54,i32 %right55,i32 %right56,i32 %right57,i32 %right58,i32 %right59,i32 %right60,i32 %right61,ptr %out)
 ret void
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i32 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i32 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i32 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i32 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i32 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i32 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i32 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i32 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i32 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i32 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i32 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i32 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i32 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i32 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i32 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i32 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i32 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i32 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i32 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i32 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i32 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i32 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i32 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i32 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i32 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i32 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i32 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i32 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i32 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i32 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i32 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i32 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i32 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i32 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i32 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i32 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i32 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i32 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i32 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i32 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i32 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i32 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i32 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i32 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i32 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i32 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i32 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i32 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i32 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i32 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i32 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i32 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i32 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i32 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_68(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i32
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i32
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i32
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i32
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i32
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i32
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i32
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i32
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i32
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i32
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i32
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i32
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i32
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i32
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i32
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i32
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i32
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i32
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i32
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i32
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i32
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i32
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i32
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i32
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i32
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i32
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i32
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i32
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i32
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i32
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i32
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i32
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i32
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i32
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i32
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i32
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i32
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i32
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i32
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i32
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i32
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i32
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i32
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i32
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i32
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i32
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i32
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i32
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i32
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i32
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i32
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i32
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i32
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i32
 call void @self_tail_body_68(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,i32 %v8,i32 %v9,i32 %v10,i32 %v11,i32 %v12,i32 %v13,i32 %v14,i32 %v15,i32 %v16,i32 %v17,i32 %v18,i32 %v19,i32 %v20,i32 %v21,i32 %v22,i32 %v23,i32 %v24,i32 %v25,i32 %v26,i32 %v27,i32 %v28,i32 %v29,i32 %v30,i32 %v31,i32 %v32,i32 %v33,i32 %v34,i32 %v35,i32 %v36,i32 %v37,i32 %v38,i32 %v39,i32 %v40,i32 %v41,i32 %v42,i32 %v43,i32 %v44,i32 %v45,i32 %v46,i32 %v47,i32 %v48,i32 %v49,i32 %v50,i32 %v51,i32 %v52,i32 %v53,i32 %v54,i32 %v55,i32 %v56,i32 %v57,i32 %v58,i32 %v59,i32 %v60,i32 %v61,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,4294967295
 ret i64 %result
}
define internal fastcc void @self_tail_body_69(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,i32 %p8,i32 %p9,i32 %p10,i32 %p11,i32 %p12,i32 %p13,i32 %p14,i32 %p15,i32 %p16,i32 %p17,i32 %p18,i32 %p19,i32 %p20,i32 %p21,i32 %p22,i32 %p23,i32 %p24,i32 %p25,i32 %p26,i32 %p27,i32 %p28,i32 %p29,i32 %p30,i32 %p31,i32 %p32,i32 %p33,i32 %p34,i32 %p35,i32 %p36,i32 %p37,i32 %p38,i32 %p39,i32 %p40,i32 %p41,i32 %p42,i32 %p43,i32 %p44,i32 %p45,i32 %p46,i32 %p47,i32 %p48,i32 %p49,i32 %p50,i32 %p51,i32 %p52,i32 %p53,i32 %p54,i32 %p55,i32 %p56,i32 %p57,i32 %p58,i32 %p59,i32 %p60,i32 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p8,136
 %left8 = add i32 %p9,153
 %left9 = add i32 %p10,170
 %left10 = add i32 %p11,187
 %left11 = add i32 %p12,204
 %left12 = add i32 %p13,221
 %left13 = add i32 %p14,238
 %left14 = add i32 %p15,255
 %left15 = add i32 %p16,272
 %left16 = add i32 %p17,289
 %left17 = add i32 %p18,306
 %left18 = add i32 %p19,323
 %left19 = add i32 %p20,340
 %left20 = add i32 %p21,357
 %left21 = add i32 %p22,374
 %left22 = add i32 %p23,391
 %left23 = add i32 %p24,408
 %left24 = add i32 %p25,425
 %left25 = add i32 %p26,442
 %left26 = add i32 %p27,459
 %left27 = add i32 %p28,476
 %left28 = add i32 %p29,493
 %left29 = add i32 %p30,510
 %left30 = add i32 %p31,527
 %left31 = add i32 %p32,544
 %left32 = add i32 %p33,561
 %left33 = add i32 %p34,578
 %left34 = add i32 %p35,595
 %left35 = add i32 %p36,612
 %left36 = add i32 %p37,629
 %left37 = add i32 %p38,646
 %left38 = add i32 %p39,663
 %left39 = add i32 %p40,680
 %left40 = add i32 %p41,697
 %left41 = add i32 %p42,714
 %left42 = add i32 %p43,731
 %left43 = add i32 %p44,748
 %left44 = add i32 %p45,765
 %left45 = add i32 %p46,782
 %left46 = add i32 %p47,799
 %left47 = add i32 %p48,816
 %left48 = add i32 %p49,833
 %left49 = add i32 %p50,850
 %left50 = add i32 %p51,867
 %left51 = add i32 %p52,884
 %left52 = add i32 %p53,901
 %left53 = add i32 %p54,918
 %left54 = add i32 %p55,935
 %left55 = add i32 %p56,952
 %left56 = add i32 %p57,969
 %left57 = add i32 %p58,986
 %left58 = add i32 %p59,1003
 %left59 = add i32 %p60,1020
 %left60 = add i32 %p61,1037
 %left61 = add i32 %p0,1054
 musttail call fastcc void @self_tail_body_69(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,i32 %left8,i32 %left9,i32 %left10,i32 %left11,i32 %left12,i32 %left13,i32 %left14,i32 %left15,i32 %left16,i32 %left17,i32 %left18,i32 %left19,i32 %left20,i32 %left21,i32 %left22,i32 %left23,i32 %left24,i32 %left25,i32 %left26,i32 %left27,i32 %left28,i32 %left29,i32 %left30,i32 %left31,i32 %left32,i32 %left33,i32 %left34,i32 %left35,i32 %left36,i32 %left37,i32 %left38,i32 %left39,i32 %left40,i32 %left41,i32 %left42,i32 %left43,i32 %left44,i32 %left45,i32 %left46,i32 %left47,i32 %left48,i32 %left49,i32 %left50,i32 %left51,i32 %left52,i32 %left53,i32 %left54,i32 %left55,i32 %left56,i32 %left57,i32 %left58,i32 %left59,i32 %left60,i32 %left61,ptr %out)
 ret void
right:
 %right0 = xor i32 %p61,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right8 = xor i32 %p7,279
 %right9 = xor i32 %p8,310
 %right10 = xor i32 %p9,341
 %right11 = xor i32 %p10,372
 %right12 = xor i32 %p11,403
 %right13 = xor i32 %p12,434
 %right14 = xor i32 %p13,465
 %right15 = xor i32 %p14,496
 %right16 = xor i32 %p15,527
 %right17 = xor i32 %p16,558
 %right18 = xor i32 %p17,589
 %right19 = xor i32 %p18,620
 %right20 = xor i32 %p19,651
 %right21 = xor i32 %p20,682
 %right22 = xor i32 %p21,713
 %right23 = xor i32 %p22,744
 %right24 = xor i32 %p23,775
 %right25 = xor i32 %p24,806
 %right26 = xor i32 %p25,837
 %right27 = xor i32 %p26,868
 %right28 = xor i32 %p27,899
 %right29 = xor i32 %p28,930
 %right30 = xor i32 %p29,961
 %right31 = xor i32 %p30,992
 %right32 = xor i32 %p31,1023
 %right33 = xor i32 %p32,1054
 %right34 = xor i32 %p33,1085
 %right35 = xor i32 %p34,1116
 %right36 = xor i32 %p35,1147
 %right37 = xor i32 %p36,1178
 %right38 = xor i32 %p37,1209
 %right39 = xor i32 %p38,1240
 %right40 = xor i32 %p39,1271
 %right41 = xor i32 %p40,1302
 %right42 = xor i32 %p41,1333
 %right43 = xor i32 %p42,1364
 %right44 = xor i32 %p43,1395
 %right45 = xor i32 %p44,1426
 %right46 = xor i32 %p45,1457
 %right47 = xor i32 %p46,1488
 %right48 = xor i32 %p47,1519
 %right49 = xor i32 %p48,1550
 %right50 = xor i32 %p49,1581
 %right51 = xor i32 %p50,1612
 %right52 = xor i32 %p51,1643
 %right53 = xor i32 %p52,1674
 %right54 = xor i32 %p53,1705
 %right55 = xor i32 %p54,1736
 %right56 = xor i32 %p55,1767
 %right57 = xor i32 %p56,1798
 %right58 = xor i32 %p57,1829
 %right59 = xor i32 %p58,1860
 %right60 = xor i32 %p59,1891
 %right61 = xor i32 %p60,1922
 musttail call fastcc void @self_tail_body_69(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,i32 %right8,i32 %right9,i32 %right10,i32 %right11,i32 %right12,i32 %right13,i32 %right14,i32 %right15,i32 %right16,i32 %right17,i32 %right18,i32 %right19,i32 %right20,i32 %right21,i32 %right22,i32 %right23,i32 %right24,i32 %right25,i32 %right26,i32 %right27,i32 %right28,i32 %right29,i32 %right30,i32 %right31,i32 %right32,i32 %right33,i32 %right34,i32 %right35,i32 %right36,i32 %right37,i32 %right38,i32 %right39,i32 %right40,i32 %right41,i32 %right42,i32 %right43,i32 %right44,i32 %right45,i32 %right46,i32 %right47,i32 %right48,i32 %right49,i32 %right50,i32 %right51,i32 %right52,i32 %right53,i32 %right54,i32 %right55,i32 %right56,i32 %right57,i32 %right58,i32 %right59,i32 %right60,i32 %right61,ptr %out)
 ret void
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i32 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i32 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i32 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i32 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i32 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i32 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i32 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i32 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i32 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i32 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i32 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i32 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i32 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i32 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i32 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i32 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i32 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i32 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i32 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i32 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i32 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i32 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i32 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i32 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i32 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i32 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i32 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i32 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i32 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i32 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i32 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i32 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i32 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i32 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i32 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i32 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i32 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i32 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i32 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i32 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i32 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i32 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i32 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i32 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i32 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i32 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i32 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i32 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i32 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i32 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i32 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i32 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i32 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i32 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_69(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i32
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i32
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i32
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i32
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i32
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i32
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i32
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i32
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i32
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i32
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i32
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i32
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i32
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i32
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i32
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i32
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i32
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i32
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i32
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i32
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i32
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i32
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i32
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i32
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i32
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i32
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i32
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i32
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i32
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i32
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i32
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i32
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i32
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i32
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i32
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i32
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i32
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i32
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i32
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i32
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i32
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i32
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i32
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i32
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i32
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i32
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i32
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i32
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i32
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i32
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i32
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i32
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i32
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i32
 call fastcc void @self_tail_body_69(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,i32 %v8,i32 %v9,i32 %v10,i32 %v11,i32 %v12,i32 %v13,i32 %v14,i32 %v15,i32 %v16,i32 %v17,i32 %v18,i32 %v19,i32 %v20,i32 %v21,i32 %v22,i32 %v23,i32 %v24,i32 %v25,i32 %v26,i32 %v27,i32 %v28,i32 %v29,i32 %v30,i32 %v31,i32 %v32,i32 %v33,i32 %v34,i32 %v35,i32 %v36,i32 %v37,i32 %v38,i32 %v39,i32 %v40,i32 %v41,i32 %v42,i32 %v43,i32 %v44,i32 %v45,i32 %v46,i32 %v47,i32 %v48,i32 %v49,i32 %v50,i32 %v51,i32 %v52,i32 %v53,i32 %v54,i32 %v55,i32 %v56,i32 %v57,i32 %v58,i32 %v59,i32 %v60,i32 %v61,ptr %out)
 %loaded = load i64,ptr %out,align 1
 %result = and i64 %loaded,4294967295
 ret i64 %result
}
define internal void @self_tail_body_70(i64 %n,i64 %p0,i64 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p0,34
 musttail call void @self_tail_body_70(i64 %next,i64 %left0,i64 %left1,ptr %out)
 ret void
right:
 %right0 = xor i64 %p1,31
 %right1 = xor i64 %p0,62
 musttail call void @self_tail_body_70(i64 %next,i64 %right0,i64 %right1,ptr %out)
 ret void
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p1,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_70(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 call void @self_tail_body_70(i64 %count,i64 %raw0,i64 %raw1,ptr %out)
 %loaded = load i64,ptr %out,align 1
 ret i64 %loaded
}
define internal fastcc void @self_tail_body_71(i64 %n,i64 %p0,i64 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p0,34
 musttail call fastcc void @self_tail_body_71(i64 %next,i64 %left0,i64 %left1,ptr %out)
 ret void
right:
 %right0 = xor i64 %p1,31
 %right1 = xor i64 %p0,62
 musttail call fastcc void @self_tail_body_71(i64 %next,i64 %right0,i64 %right1,ptr %out)
 ret void
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p1,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_71(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 call fastcc void @self_tail_body_71(i64 %count,i64 %raw0,i64 %raw1,ptr %out)
 %loaded = load i64,ptr %out,align 1
 ret i64 %loaded
}
define internal void @self_tail_body_72(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p0,85
 musttail call void @self_tail_body_72(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,ptr %out)
 ret void
right:
 %right0 = xor i64 %p4,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 musttail call void @self_tail_body_72(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,ptr %out)
 ret void
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p4,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_72(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 call void @self_tail_body_72(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,ptr %out)
 %loaded = load i64,ptr %out,align 1
 ret i64 %loaded
}
define internal fastcc void @self_tail_body_73(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p0,85
 musttail call fastcc void @self_tail_body_73(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,ptr %out)
 ret void
right:
 %right0 = xor i64 %p4,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 musttail call fastcc void @self_tail_body_73(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,ptr %out)
 ret void
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p4,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_73(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 call fastcc void @self_tail_body_73(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,ptr %out)
 %loaded = load i64,ptr %out,align 1
 ret i64 %loaded
}
define internal void @self_tail_body_74(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p0,136
 musttail call void @self_tail_body_74(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,ptr %out)
 ret void
right:
 %right0 = xor i64 %p7,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 musttail call void @self_tail_body_74(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,ptr %out)
 ret void
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p7,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_74(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 call void @self_tail_body_74(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,ptr %out)
 %loaded = load i64,ptr %out,align 1
 ret i64 %loaded
}
define internal fastcc void @self_tail_body_75(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p0,136
 musttail call fastcc void @self_tail_body_75(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,ptr %out)
 ret void
right:
 %right0 = xor i64 %p7,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 musttail call fastcc void @self_tail_body_75(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,ptr %out)
 ret void
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p7,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_75(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 call fastcc void @self_tail_body_75(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,ptr %out)
 %loaded = load i64,ptr %out,align 1
 ret i64 %loaded
}
define internal void @self_tail_body_76(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,i64 %p8,i64 %p9,i64 %p10,i64 %p11,i64 %p12,i64 %p13,i64 %p14,i64 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p8,136
 %left8 = add i64 %p9,153
 %left9 = add i64 %p10,170
 %left10 = add i64 %p11,187
 %left11 = add i64 %p12,204
 %left12 = add i64 %p13,221
 %left13 = add i64 %p14,238
 %left14 = add i64 %p15,255
 %left15 = add i64 %p0,272
 musttail call void @self_tail_body_76(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,i64 %left8,i64 %left9,i64 %left10,i64 %left11,i64 %left12,i64 %left13,i64 %left14,i64 %left15,ptr %out)
 ret void
right:
 %right0 = xor i64 %p15,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right8 = xor i64 %p7,279
 %right9 = xor i64 %p8,310
 %right10 = xor i64 %p9,341
 %right11 = xor i64 %p10,372
 %right12 = xor i64 %p11,403
 %right13 = xor i64 %p12,434
 %right14 = xor i64 %p13,465
 %right15 = xor i64 %p14,496
 musttail call void @self_tail_body_76(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,i64 %right8,i64 %right9,i64 %right10,i64 %right11,i64 %right12,i64 %right13,i64 %right14,i64 %right15,ptr %out)
 ret void
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%p8
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%p9
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%p10
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%p11
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%p12
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%p13
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%p14
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%p15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p15,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_76(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 call void @self_tail_body_76(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,i64 %raw8,i64 %raw9,i64 %raw10,i64 %raw11,i64 %raw12,i64 %raw13,i64 %raw14,i64 %raw15,ptr %out)
 %loaded = load i64,ptr %out,align 1
 ret i64 %loaded
}
define internal fastcc void @self_tail_body_77(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,i64 %p8,i64 %p9,i64 %p10,i64 %p11,i64 %p12,i64 %p13,i64 %p14,i64 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p8,136
 %left8 = add i64 %p9,153
 %left9 = add i64 %p10,170
 %left10 = add i64 %p11,187
 %left11 = add i64 %p12,204
 %left12 = add i64 %p13,221
 %left13 = add i64 %p14,238
 %left14 = add i64 %p15,255
 %left15 = add i64 %p0,272
 musttail call fastcc void @self_tail_body_77(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,i64 %left8,i64 %left9,i64 %left10,i64 %left11,i64 %left12,i64 %left13,i64 %left14,i64 %left15,ptr %out)
 ret void
right:
 %right0 = xor i64 %p15,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right8 = xor i64 %p7,279
 %right9 = xor i64 %p8,310
 %right10 = xor i64 %p9,341
 %right11 = xor i64 %p10,372
 %right12 = xor i64 %p11,403
 %right13 = xor i64 %p12,434
 %right14 = xor i64 %p13,465
 %right15 = xor i64 %p14,496
 musttail call fastcc void @self_tail_body_77(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,i64 %right8,i64 %right9,i64 %right10,i64 %right11,i64 %right12,i64 %right13,i64 %right14,i64 %right15,ptr %out)
 ret void
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%p8
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%p9
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%p10
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%p11
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%p12
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%p13
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%p14
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%p15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p15,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_77(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 call fastcc void @self_tail_body_77(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,i64 %raw8,i64 %raw9,i64 %raw10,i64 %raw11,i64 %raw12,i64 %raw13,i64 %raw14,i64 %raw15,ptr %out)
 %loaded = load i64,ptr %out,align 1
 ret i64 %loaded
}
define internal void @self_tail_body_78(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,i64 %p8,i64 %p9,i64 %p10,i64 %p11,i64 %p12,i64 %p13,i64 %p14,i64 %p15,i64 %p16,i64 %p17,i64 %p18,i64 %p19,i64 %p20,i64 %p21,i64 %p22,i64 %p23,i64 %p24,i64 %p25,i64 %p26,i64 %p27,i64 %p28,i64 %p29,i64 %p30,i64 %p31,i64 %p32,i64 %p33,i64 %p34,i64 %p35,i64 %p36,i64 %p37,i64 %p38,i64 %p39,i64 %p40,i64 %p41,i64 %p42,i64 %p43,i64 %p44,i64 %p45,i64 %p46,i64 %p47,i64 %p48,i64 %p49,i64 %p50,i64 %p51,i64 %p52,i64 %p53,i64 %p54,i64 %p55,i64 %p56,i64 %p57,i64 %p58,i64 %p59,i64 %p60,i64 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p8,136
 %left8 = add i64 %p9,153
 %left9 = add i64 %p10,170
 %left10 = add i64 %p11,187
 %left11 = add i64 %p12,204
 %left12 = add i64 %p13,221
 %left13 = add i64 %p14,238
 %left14 = add i64 %p15,255
 %left15 = add i64 %p16,272
 %left16 = add i64 %p17,289
 %left17 = add i64 %p18,306
 %left18 = add i64 %p19,323
 %left19 = add i64 %p20,340
 %left20 = add i64 %p21,357
 %left21 = add i64 %p22,374
 %left22 = add i64 %p23,391
 %left23 = add i64 %p24,408
 %left24 = add i64 %p25,425
 %left25 = add i64 %p26,442
 %left26 = add i64 %p27,459
 %left27 = add i64 %p28,476
 %left28 = add i64 %p29,493
 %left29 = add i64 %p30,510
 %left30 = add i64 %p31,527
 %left31 = add i64 %p32,544
 %left32 = add i64 %p33,561
 %left33 = add i64 %p34,578
 %left34 = add i64 %p35,595
 %left35 = add i64 %p36,612
 %left36 = add i64 %p37,629
 %left37 = add i64 %p38,646
 %left38 = add i64 %p39,663
 %left39 = add i64 %p40,680
 %left40 = add i64 %p41,697
 %left41 = add i64 %p42,714
 %left42 = add i64 %p43,731
 %left43 = add i64 %p44,748
 %left44 = add i64 %p45,765
 %left45 = add i64 %p46,782
 %left46 = add i64 %p47,799
 %left47 = add i64 %p48,816
 %left48 = add i64 %p49,833
 %left49 = add i64 %p50,850
 %left50 = add i64 %p51,867
 %left51 = add i64 %p52,884
 %left52 = add i64 %p53,901
 %left53 = add i64 %p54,918
 %left54 = add i64 %p55,935
 %left55 = add i64 %p56,952
 %left56 = add i64 %p57,969
 %left57 = add i64 %p58,986
 %left58 = add i64 %p59,1003
 %left59 = add i64 %p60,1020
 %left60 = add i64 %p61,1037
 %left61 = add i64 %p0,1054
 musttail call void @self_tail_body_78(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,i64 %left8,i64 %left9,i64 %left10,i64 %left11,i64 %left12,i64 %left13,i64 %left14,i64 %left15,i64 %left16,i64 %left17,i64 %left18,i64 %left19,i64 %left20,i64 %left21,i64 %left22,i64 %left23,i64 %left24,i64 %left25,i64 %left26,i64 %left27,i64 %left28,i64 %left29,i64 %left30,i64 %left31,i64 %left32,i64 %left33,i64 %left34,i64 %left35,i64 %left36,i64 %left37,i64 %left38,i64 %left39,i64 %left40,i64 %left41,i64 %left42,i64 %left43,i64 %left44,i64 %left45,i64 %left46,i64 %left47,i64 %left48,i64 %left49,i64 %left50,i64 %left51,i64 %left52,i64 %left53,i64 %left54,i64 %left55,i64 %left56,i64 %left57,i64 %left58,i64 %left59,i64 %left60,i64 %left61,ptr %out)
 ret void
right:
 %right0 = xor i64 %p61,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right8 = xor i64 %p7,279
 %right9 = xor i64 %p8,310
 %right10 = xor i64 %p9,341
 %right11 = xor i64 %p10,372
 %right12 = xor i64 %p11,403
 %right13 = xor i64 %p12,434
 %right14 = xor i64 %p13,465
 %right15 = xor i64 %p14,496
 %right16 = xor i64 %p15,527
 %right17 = xor i64 %p16,558
 %right18 = xor i64 %p17,589
 %right19 = xor i64 %p18,620
 %right20 = xor i64 %p19,651
 %right21 = xor i64 %p20,682
 %right22 = xor i64 %p21,713
 %right23 = xor i64 %p22,744
 %right24 = xor i64 %p23,775
 %right25 = xor i64 %p24,806
 %right26 = xor i64 %p25,837
 %right27 = xor i64 %p26,868
 %right28 = xor i64 %p27,899
 %right29 = xor i64 %p28,930
 %right30 = xor i64 %p29,961
 %right31 = xor i64 %p30,992
 %right32 = xor i64 %p31,1023
 %right33 = xor i64 %p32,1054
 %right34 = xor i64 %p33,1085
 %right35 = xor i64 %p34,1116
 %right36 = xor i64 %p35,1147
 %right37 = xor i64 %p36,1178
 %right38 = xor i64 %p37,1209
 %right39 = xor i64 %p38,1240
 %right40 = xor i64 %p39,1271
 %right41 = xor i64 %p40,1302
 %right42 = xor i64 %p41,1333
 %right43 = xor i64 %p42,1364
 %right44 = xor i64 %p43,1395
 %right45 = xor i64 %p44,1426
 %right46 = xor i64 %p45,1457
 %right47 = xor i64 %p46,1488
 %right48 = xor i64 %p47,1519
 %right49 = xor i64 %p48,1550
 %right50 = xor i64 %p49,1581
 %right51 = xor i64 %p50,1612
 %right52 = xor i64 %p51,1643
 %right53 = xor i64 %p52,1674
 %right54 = xor i64 %p53,1705
 %right55 = xor i64 %p54,1736
 %right56 = xor i64 %p55,1767
 %right57 = xor i64 %p56,1798
 %right58 = xor i64 %p57,1829
 %right59 = xor i64 %p58,1860
 %right60 = xor i64 %p59,1891
 %right61 = xor i64 %p60,1922
 musttail call void @self_tail_body_78(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,i64 %right8,i64 %right9,i64 %right10,i64 %right11,i64 %right12,i64 %right13,i64 %right14,i64 %right15,i64 %right16,i64 %right17,i64 %right18,i64 %right19,i64 %right20,i64 %right21,i64 %right22,i64 %right23,i64 %right24,i64 %right25,i64 %right26,i64 %right27,i64 %right28,i64 %right29,i64 %right30,i64 %right31,i64 %right32,i64 %right33,i64 %right34,i64 %right35,i64 %right36,i64 %right37,i64 %right38,i64 %right39,i64 %right40,i64 %right41,i64 %right42,i64 %right43,i64 %right44,i64 %right45,i64 %right46,i64 %right47,i64 %right48,i64 %right49,i64 %right50,i64 %right51,i64 %right52,i64 %right53,i64 %right54,i64 %right55,i64 %right56,i64 %right57,i64 %right58,i64 %right59,i64 %right60,i64 %right61,ptr %out)
 ret void
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%p8
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%p9
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%p10
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%p11
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%p12
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%p13
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%p14
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%p15
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%p16
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%p17
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%p18
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%p19
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%p20
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%p21
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%p22
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%p23
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%p24
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%p25
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%p26
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%p27
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%p28
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%p29
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%p30
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%p31
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%p32
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%p33
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%p34
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%p35
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%p36
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%p37
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%p38
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%p39
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%p40
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%p41
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%p42
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%p43
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%p44
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%p45
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%p46
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%p47
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%p48
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%p49
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%p50
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%p51
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%p52
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%p53
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%p54
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%p55
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%p56
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%p57
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%p58
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%p59
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%p60
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%p61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p61,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_78(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 call void @self_tail_body_78(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,i64 %raw8,i64 %raw9,i64 %raw10,i64 %raw11,i64 %raw12,i64 %raw13,i64 %raw14,i64 %raw15,i64 %raw16,i64 %raw17,i64 %raw18,i64 %raw19,i64 %raw20,i64 %raw21,i64 %raw22,i64 %raw23,i64 %raw24,i64 %raw25,i64 %raw26,i64 %raw27,i64 %raw28,i64 %raw29,i64 %raw30,i64 %raw31,i64 %raw32,i64 %raw33,i64 %raw34,i64 %raw35,i64 %raw36,i64 %raw37,i64 %raw38,i64 %raw39,i64 %raw40,i64 %raw41,i64 %raw42,i64 %raw43,i64 %raw44,i64 %raw45,i64 %raw46,i64 %raw47,i64 %raw48,i64 %raw49,i64 %raw50,i64 %raw51,i64 %raw52,i64 %raw53,i64 %raw54,i64 %raw55,i64 %raw56,i64 %raw57,i64 %raw58,i64 %raw59,i64 %raw60,i64 %raw61,ptr %out)
 %loaded = load i64,ptr %out,align 1
 ret i64 %loaded
}
define internal fastcc void @self_tail_body_79(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,i64 %p8,i64 %p9,i64 %p10,i64 %p11,i64 %p12,i64 %p13,i64 %p14,i64 %p15,i64 %p16,i64 %p17,i64 %p18,i64 %p19,i64 %p20,i64 %p21,i64 %p22,i64 %p23,i64 %p24,i64 %p25,i64 %p26,i64 %p27,i64 %p28,i64 %p29,i64 %p30,i64 %p31,i64 %p32,i64 %p33,i64 %p34,i64 %p35,i64 %p36,i64 %p37,i64 %p38,i64 %p39,i64 %p40,i64 %p41,i64 %p42,i64 %p43,i64 %p44,i64 %p45,i64 %p46,i64 %p47,i64 %p48,i64 %p49,i64 %p50,i64 %p51,i64 %p52,i64 %p53,i64 %p54,i64 %p55,i64 %p56,i64 %p57,i64 %p58,i64 %p59,i64 %p60,i64 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p8,136
 %left8 = add i64 %p9,153
 %left9 = add i64 %p10,170
 %left10 = add i64 %p11,187
 %left11 = add i64 %p12,204
 %left12 = add i64 %p13,221
 %left13 = add i64 %p14,238
 %left14 = add i64 %p15,255
 %left15 = add i64 %p16,272
 %left16 = add i64 %p17,289
 %left17 = add i64 %p18,306
 %left18 = add i64 %p19,323
 %left19 = add i64 %p20,340
 %left20 = add i64 %p21,357
 %left21 = add i64 %p22,374
 %left22 = add i64 %p23,391
 %left23 = add i64 %p24,408
 %left24 = add i64 %p25,425
 %left25 = add i64 %p26,442
 %left26 = add i64 %p27,459
 %left27 = add i64 %p28,476
 %left28 = add i64 %p29,493
 %left29 = add i64 %p30,510
 %left30 = add i64 %p31,527
 %left31 = add i64 %p32,544
 %left32 = add i64 %p33,561
 %left33 = add i64 %p34,578
 %left34 = add i64 %p35,595
 %left35 = add i64 %p36,612
 %left36 = add i64 %p37,629
 %left37 = add i64 %p38,646
 %left38 = add i64 %p39,663
 %left39 = add i64 %p40,680
 %left40 = add i64 %p41,697
 %left41 = add i64 %p42,714
 %left42 = add i64 %p43,731
 %left43 = add i64 %p44,748
 %left44 = add i64 %p45,765
 %left45 = add i64 %p46,782
 %left46 = add i64 %p47,799
 %left47 = add i64 %p48,816
 %left48 = add i64 %p49,833
 %left49 = add i64 %p50,850
 %left50 = add i64 %p51,867
 %left51 = add i64 %p52,884
 %left52 = add i64 %p53,901
 %left53 = add i64 %p54,918
 %left54 = add i64 %p55,935
 %left55 = add i64 %p56,952
 %left56 = add i64 %p57,969
 %left57 = add i64 %p58,986
 %left58 = add i64 %p59,1003
 %left59 = add i64 %p60,1020
 %left60 = add i64 %p61,1037
 %left61 = add i64 %p0,1054
 musttail call fastcc void @self_tail_body_79(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,i64 %left8,i64 %left9,i64 %left10,i64 %left11,i64 %left12,i64 %left13,i64 %left14,i64 %left15,i64 %left16,i64 %left17,i64 %left18,i64 %left19,i64 %left20,i64 %left21,i64 %left22,i64 %left23,i64 %left24,i64 %left25,i64 %left26,i64 %left27,i64 %left28,i64 %left29,i64 %left30,i64 %left31,i64 %left32,i64 %left33,i64 %left34,i64 %left35,i64 %left36,i64 %left37,i64 %left38,i64 %left39,i64 %left40,i64 %left41,i64 %left42,i64 %left43,i64 %left44,i64 %left45,i64 %left46,i64 %left47,i64 %left48,i64 %left49,i64 %left50,i64 %left51,i64 %left52,i64 %left53,i64 %left54,i64 %left55,i64 %left56,i64 %left57,i64 %left58,i64 %left59,i64 %left60,i64 %left61,ptr %out)
 ret void
right:
 %right0 = xor i64 %p61,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right8 = xor i64 %p7,279
 %right9 = xor i64 %p8,310
 %right10 = xor i64 %p9,341
 %right11 = xor i64 %p10,372
 %right12 = xor i64 %p11,403
 %right13 = xor i64 %p12,434
 %right14 = xor i64 %p13,465
 %right15 = xor i64 %p14,496
 %right16 = xor i64 %p15,527
 %right17 = xor i64 %p16,558
 %right18 = xor i64 %p17,589
 %right19 = xor i64 %p18,620
 %right20 = xor i64 %p19,651
 %right21 = xor i64 %p20,682
 %right22 = xor i64 %p21,713
 %right23 = xor i64 %p22,744
 %right24 = xor i64 %p23,775
 %right25 = xor i64 %p24,806
 %right26 = xor i64 %p25,837
 %right27 = xor i64 %p26,868
 %right28 = xor i64 %p27,899
 %right29 = xor i64 %p28,930
 %right30 = xor i64 %p29,961
 %right31 = xor i64 %p30,992
 %right32 = xor i64 %p31,1023
 %right33 = xor i64 %p32,1054
 %right34 = xor i64 %p33,1085
 %right35 = xor i64 %p34,1116
 %right36 = xor i64 %p35,1147
 %right37 = xor i64 %p36,1178
 %right38 = xor i64 %p37,1209
 %right39 = xor i64 %p38,1240
 %right40 = xor i64 %p39,1271
 %right41 = xor i64 %p40,1302
 %right42 = xor i64 %p41,1333
 %right43 = xor i64 %p42,1364
 %right44 = xor i64 %p43,1395
 %right45 = xor i64 %p44,1426
 %right46 = xor i64 %p45,1457
 %right47 = xor i64 %p46,1488
 %right48 = xor i64 %p47,1519
 %right49 = xor i64 %p48,1550
 %right50 = xor i64 %p49,1581
 %right51 = xor i64 %p50,1612
 %right52 = xor i64 %p51,1643
 %right53 = xor i64 %p52,1674
 %right54 = xor i64 %p53,1705
 %right55 = xor i64 %p54,1736
 %right56 = xor i64 %p55,1767
 %right57 = xor i64 %p56,1798
 %right58 = xor i64 %p57,1829
 %right59 = xor i64 %p58,1860
 %right60 = xor i64 %p59,1891
 %right61 = xor i64 %p60,1922
 musttail call fastcc void @self_tail_body_79(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,i64 %right8,i64 %right9,i64 %right10,i64 %right11,i64 %right12,i64 %right13,i64 %right14,i64 %right15,i64 %right16,i64 %right17,i64 %right18,i64 %right19,i64 %right20,i64 %right21,i64 %right22,i64 %right23,i64 %right24,i64 %right25,i64 %right26,i64 %right27,i64 %right28,i64 %right29,i64 %right30,i64 %right31,i64 %right32,i64 %right33,i64 %right34,i64 %right35,i64 %right36,i64 %right37,i64 %right38,i64 %right39,i64 %right40,i64 %right41,i64 %right42,i64 %right43,i64 %right44,i64 %right45,i64 %right46,i64 %right47,i64 %right48,i64 %right49,i64 %right50,i64 %right51,i64 %right52,i64 %right53,i64 %right54,i64 %right55,i64 %right56,i64 %right57,i64 %right58,i64 %right59,i64 %right60,i64 %right61,ptr %out)
 ret void
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%p8
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%p9
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%p10
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%p11
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%p12
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%p13
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%p14
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%p15
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%p16
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%p17
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%p18
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%p19
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%p20
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%p21
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%p22
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%p23
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%p24
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%p25
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%p26
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%p27
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%p28
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%p29
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%p30
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%p31
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%p32
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%p33
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%p34
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%p35
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%p36
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%p37
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%p38
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%p39
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%p40
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%p41
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%p42
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%p43
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%p44
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%p45
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%p46
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%p47
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%p48
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%p49
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%p50
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%p51
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%p52
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%p53
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%p54
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%p55
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%p56
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%p57
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%p58
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%p59
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%p60
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%p61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p61,ptr %o2,align 1
 ret void
}
define i64 @self_tail_probe_79(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 call fastcc void @self_tail_body_79(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,i64 %raw8,i64 %raw9,i64 %raw10,i64 %raw11,i64 %raw12,i64 %raw13,i64 %raw14,i64 %raw15,i64 %raw16,i64 %raw17,i64 %raw18,i64 %raw19,i64 %raw20,i64 %raw21,i64 %raw22,i64 %raw23,i64 %raw24,i64 %raw25,i64 %raw26,i64 %raw27,i64 %raw28,i64 %raw29,i64 %raw30,i64 %raw31,i64 %raw32,i64 %raw33,i64 %raw34,i64 %raw35,i64 %raw36,i64 %raw37,i64 %raw38,i64 %raw39,i64 %raw40,i64 %raw41,i64 %raw42,i64 %raw43,i64 %raw44,i64 %raw45,i64 %raw46,i64 %raw47,i64 %raw48,i64 %raw49,i64 %raw50,i64 %raw51,i64 %raw52,i64 %raw53,i64 %raw54,i64 %raw55,i64 %raw56,i64 %raw57,i64 %raw58,i64 %raw59,i64 %raw60,i64 %raw61,ptr %out)
 %loaded = load i64,ptr %out,align 1
 ret i64 %loaded
}
define internal ptr @self_tail_body_80(i64 %n,i8 %p0,i8 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p0,34
 %answer = musttail call ptr @self_tail_body_80(i64 %next,i8 %left0,i8 %left1,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i8 %p1,31
 %right1 = xor i8 %p0,62
 %right_answer = musttail call ptr @self_tail_body_80(i64 %next,i8 %right0,i8 %right1,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_80(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %returned = call ptr @self_tail_body_80(i64 %count,i8 %v0,i8 %v1,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_81(i64 %n,i8 %p0,i8 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p0,34
 %answer = musttail call fastcc ptr @self_tail_body_81(i64 %next,i8 %left0,i8 %left1,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i8 %p1,31
 %right1 = xor i8 %p0,62
 %right_answer = musttail call fastcc ptr @self_tail_body_81(i64 %next,i8 %right0,i8 %right1,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_81(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %returned = call fastcc ptr @self_tail_body_81(i64 %count,i8 %v0,i8 %v1,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_82(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p0,85
 %answer = musttail call ptr @self_tail_body_82(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i8 %p4,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right_answer = musttail call ptr @self_tail_body_82(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_82(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %returned = call ptr @self_tail_body_82(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_83(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p0,85
 %answer = musttail call fastcc ptr @self_tail_body_83(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i8 %p4,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right_answer = musttail call fastcc ptr @self_tail_body_83(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_83(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %returned = call fastcc ptr @self_tail_body_83(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_84(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p0,136
 %answer = musttail call ptr @self_tail_body_84(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i8 %p7,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right_answer = musttail call ptr @self_tail_body_84(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_84(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %returned = call ptr @self_tail_body_84(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_85(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p0,136
 %answer = musttail call fastcc ptr @self_tail_body_85(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i8 %p7,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right_answer = musttail call fastcc ptr @self_tail_body_85(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_85(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %returned = call fastcc ptr @self_tail_body_85(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_86(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,i8 %p8,i8 %p9,i8 %p10,i8 %p11,i8 %p12,i8 %p13,i8 %p14,i8 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p8,136
 %left8 = add i8 %p9,153
 %left9 = add i8 %p10,170
 %left10 = add i8 %p11,187
 %left11 = add i8 %p12,204
 %left12 = add i8 %p13,221
 %left13 = add i8 %p14,238
 %left14 = add i8 %p15,255
 %left15 = add i8 %p0,16
 %answer = musttail call ptr @self_tail_body_86(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,i8 %left8,i8 %left9,i8 %left10,i8 %left11,i8 %left12,i8 %left13,i8 %left14,i8 %left15,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i8 %p15,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right8 = xor i8 %p7,23
 %right9 = xor i8 %p8,54
 %right10 = xor i8 %p9,85
 %right11 = xor i8 %p10,116
 %right12 = xor i8 %p11,147
 %right13 = xor i8 %p12,178
 %right14 = xor i8 %p13,209
 %right15 = xor i8 %p14,240
 %right_answer = musttail call ptr @self_tail_body_86(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,i8 %right8,i8 %right9,i8 %right10,i8 %right11,i8 %right12,i8 %right13,i8 %right14,i8 %right15,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i8 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i8 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i8 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i8 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i8 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i8 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i8 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i8 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_86(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i8
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i8
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i8
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i8
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i8
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i8
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i8
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i8
 %returned = call ptr @self_tail_body_86(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,i8 %v8,i8 %v9,i8 %v10,i8 %v11,i8 %v12,i8 %v13,i8 %v14,i8 %v15,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_87(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,i8 %p8,i8 %p9,i8 %p10,i8 %p11,i8 %p12,i8 %p13,i8 %p14,i8 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p8,136
 %left8 = add i8 %p9,153
 %left9 = add i8 %p10,170
 %left10 = add i8 %p11,187
 %left11 = add i8 %p12,204
 %left12 = add i8 %p13,221
 %left13 = add i8 %p14,238
 %left14 = add i8 %p15,255
 %left15 = add i8 %p0,16
 %answer = musttail call fastcc ptr @self_tail_body_87(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,i8 %left8,i8 %left9,i8 %left10,i8 %left11,i8 %left12,i8 %left13,i8 %left14,i8 %left15,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i8 %p15,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right8 = xor i8 %p7,23
 %right9 = xor i8 %p8,54
 %right10 = xor i8 %p9,85
 %right11 = xor i8 %p10,116
 %right12 = xor i8 %p11,147
 %right13 = xor i8 %p12,178
 %right14 = xor i8 %p13,209
 %right15 = xor i8 %p14,240
 %right_answer = musttail call fastcc ptr @self_tail_body_87(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,i8 %right8,i8 %right9,i8 %right10,i8 %right11,i8 %right12,i8 %right13,i8 %right14,i8 %right15,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i8 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i8 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i8 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i8 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i8 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i8 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i8 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i8 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_87(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i8
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i8
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i8
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i8
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i8
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i8
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i8
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i8
 %returned = call fastcc ptr @self_tail_body_87(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,i8 %v8,i8 %v9,i8 %v10,i8 %v11,i8 %v12,i8 %v13,i8 %v14,i8 %v15,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_88(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,i8 %p8,i8 %p9,i8 %p10,i8 %p11,i8 %p12,i8 %p13,i8 %p14,i8 %p15,i8 %p16,i8 %p17,i8 %p18,i8 %p19,i8 %p20,i8 %p21,i8 %p22,i8 %p23,i8 %p24,i8 %p25,i8 %p26,i8 %p27,i8 %p28,i8 %p29,i8 %p30,i8 %p31,i8 %p32,i8 %p33,i8 %p34,i8 %p35,i8 %p36,i8 %p37,i8 %p38,i8 %p39,i8 %p40,i8 %p41,i8 %p42,i8 %p43,i8 %p44,i8 %p45,i8 %p46,i8 %p47,i8 %p48,i8 %p49,i8 %p50,i8 %p51,i8 %p52,i8 %p53,i8 %p54,i8 %p55,i8 %p56,i8 %p57,i8 %p58,i8 %p59,i8 %p60,i8 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p8,136
 %left8 = add i8 %p9,153
 %left9 = add i8 %p10,170
 %left10 = add i8 %p11,187
 %left11 = add i8 %p12,204
 %left12 = add i8 %p13,221
 %left13 = add i8 %p14,238
 %left14 = add i8 %p15,255
 %left15 = add i8 %p16,16
 %left16 = add i8 %p17,33
 %left17 = add i8 %p18,50
 %left18 = add i8 %p19,67
 %left19 = add i8 %p20,84
 %left20 = add i8 %p21,101
 %left21 = add i8 %p22,118
 %left22 = add i8 %p23,135
 %left23 = add i8 %p24,152
 %left24 = add i8 %p25,169
 %left25 = add i8 %p26,186
 %left26 = add i8 %p27,203
 %left27 = add i8 %p28,220
 %left28 = add i8 %p29,237
 %left29 = add i8 %p30,254
 %left30 = add i8 %p31,15
 %left31 = add i8 %p32,32
 %left32 = add i8 %p33,49
 %left33 = add i8 %p34,66
 %left34 = add i8 %p35,83
 %left35 = add i8 %p36,100
 %left36 = add i8 %p37,117
 %left37 = add i8 %p38,134
 %left38 = add i8 %p39,151
 %left39 = add i8 %p40,168
 %left40 = add i8 %p41,185
 %left41 = add i8 %p42,202
 %left42 = add i8 %p43,219
 %left43 = add i8 %p44,236
 %left44 = add i8 %p45,253
 %left45 = add i8 %p46,14
 %left46 = add i8 %p47,31
 %left47 = add i8 %p48,48
 %left48 = add i8 %p49,65
 %left49 = add i8 %p50,82
 %left50 = add i8 %p51,99
 %left51 = add i8 %p52,116
 %left52 = add i8 %p53,133
 %left53 = add i8 %p54,150
 %left54 = add i8 %p55,167
 %left55 = add i8 %p56,184
 %left56 = add i8 %p57,201
 %left57 = add i8 %p58,218
 %left58 = add i8 %p59,235
 %left59 = add i8 %p60,252
 %left60 = add i8 %p61,13
 %left61 = add i8 %p0,30
 %answer = musttail call ptr @self_tail_body_88(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,i8 %left8,i8 %left9,i8 %left10,i8 %left11,i8 %left12,i8 %left13,i8 %left14,i8 %left15,i8 %left16,i8 %left17,i8 %left18,i8 %left19,i8 %left20,i8 %left21,i8 %left22,i8 %left23,i8 %left24,i8 %left25,i8 %left26,i8 %left27,i8 %left28,i8 %left29,i8 %left30,i8 %left31,i8 %left32,i8 %left33,i8 %left34,i8 %left35,i8 %left36,i8 %left37,i8 %left38,i8 %left39,i8 %left40,i8 %left41,i8 %left42,i8 %left43,i8 %left44,i8 %left45,i8 %left46,i8 %left47,i8 %left48,i8 %left49,i8 %left50,i8 %left51,i8 %left52,i8 %left53,i8 %left54,i8 %left55,i8 %left56,i8 %left57,i8 %left58,i8 %left59,i8 %left60,i8 %left61,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i8 %p61,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right8 = xor i8 %p7,23
 %right9 = xor i8 %p8,54
 %right10 = xor i8 %p9,85
 %right11 = xor i8 %p10,116
 %right12 = xor i8 %p11,147
 %right13 = xor i8 %p12,178
 %right14 = xor i8 %p13,209
 %right15 = xor i8 %p14,240
 %right16 = xor i8 %p15,15
 %right17 = xor i8 %p16,46
 %right18 = xor i8 %p17,77
 %right19 = xor i8 %p18,108
 %right20 = xor i8 %p19,139
 %right21 = xor i8 %p20,170
 %right22 = xor i8 %p21,201
 %right23 = xor i8 %p22,232
 %right24 = xor i8 %p23,7
 %right25 = xor i8 %p24,38
 %right26 = xor i8 %p25,69
 %right27 = xor i8 %p26,100
 %right28 = xor i8 %p27,131
 %right29 = xor i8 %p28,162
 %right30 = xor i8 %p29,193
 %right31 = xor i8 %p30,224
 %right32 = xor i8 %p31,255
 %right33 = xor i8 %p32,30
 %right34 = xor i8 %p33,61
 %right35 = xor i8 %p34,92
 %right36 = xor i8 %p35,123
 %right37 = xor i8 %p36,154
 %right38 = xor i8 %p37,185
 %right39 = xor i8 %p38,216
 %right40 = xor i8 %p39,247
 %right41 = xor i8 %p40,22
 %right42 = xor i8 %p41,53
 %right43 = xor i8 %p42,84
 %right44 = xor i8 %p43,115
 %right45 = xor i8 %p44,146
 %right46 = xor i8 %p45,177
 %right47 = xor i8 %p46,208
 %right48 = xor i8 %p47,239
 %right49 = xor i8 %p48,14
 %right50 = xor i8 %p49,45
 %right51 = xor i8 %p50,76
 %right52 = xor i8 %p51,107
 %right53 = xor i8 %p52,138
 %right54 = xor i8 %p53,169
 %right55 = xor i8 %p54,200
 %right56 = xor i8 %p55,231
 %right57 = xor i8 %p56,6
 %right58 = xor i8 %p57,37
 %right59 = xor i8 %p58,68
 %right60 = xor i8 %p59,99
 %right61 = xor i8 %p60,130
 %right_answer = musttail call ptr @self_tail_body_88(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,i8 %right8,i8 %right9,i8 %right10,i8 %right11,i8 %right12,i8 %right13,i8 %right14,i8 %right15,i8 %right16,i8 %right17,i8 %right18,i8 %right19,i8 %right20,i8 %right21,i8 %right22,i8 %right23,i8 %right24,i8 %right25,i8 %right26,i8 %right27,i8 %right28,i8 %right29,i8 %right30,i8 %right31,i8 %right32,i8 %right33,i8 %right34,i8 %right35,i8 %right36,i8 %right37,i8 %right38,i8 %right39,i8 %right40,i8 %right41,i8 %right42,i8 %right43,i8 %right44,i8 %right45,i8 %right46,i8 %right47,i8 %right48,i8 %right49,i8 %right50,i8 %right51,i8 %right52,i8 %right53,i8 %right54,i8 %right55,i8 %right56,i8 %right57,i8 %right58,i8 %right59,i8 %right60,i8 %right61,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i8 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i8 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i8 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i8 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i8 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i8 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i8 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i8 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i8 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i8 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i8 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i8 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i8 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i8 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i8 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i8 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i8 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i8 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i8 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i8 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i8 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i8 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i8 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i8 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i8 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i8 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i8 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i8 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i8 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i8 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i8 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i8 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i8 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i8 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i8 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i8 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i8 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i8 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i8 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i8 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i8 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i8 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i8 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i8 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i8 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i8 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i8 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i8 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i8 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i8 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i8 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i8 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i8 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i8 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_88(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i8
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i8
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i8
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i8
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i8
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i8
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i8
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i8
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i8
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i8
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i8
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i8
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i8
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i8
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i8
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i8
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i8
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i8
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i8
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i8
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i8
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i8
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i8
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i8
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i8
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i8
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i8
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i8
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i8
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i8
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i8
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i8
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i8
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i8
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i8
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i8
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i8
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i8
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i8
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i8
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i8
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i8
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i8
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i8
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i8
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i8
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i8
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i8
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i8
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i8
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i8
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i8
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i8
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i8
 %returned = call ptr @self_tail_body_88(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,i8 %v8,i8 %v9,i8 %v10,i8 %v11,i8 %v12,i8 %v13,i8 %v14,i8 %v15,i8 %v16,i8 %v17,i8 %v18,i8 %v19,i8 %v20,i8 %v21,i8 %v22,i8 %v23,i8 %v24,i8 %v25,i8 %v26,i8 %v27,i8 %v28,i8 %v29,i8 %v30,i8 %v31,i8 %v32,i8 %v33,i8 %v34,i8 %v35,i8 %v36,i8 %v37,i8 %v38,i8 %v39,i8 %v40,i8 %v41,i8 %v42,i8 %v43,i8 %v44,i8 %v45,i8 %v46,i8 %v47,i8 %v48,i8 %v49,i8 %v50,i8 %v51,i8 %v52,i8 %v53,i8 %v54,i8 %v55,i8 %v56,i8 %v57,i8 %v58,i8 %v59,i8 %v60,i8 %v61,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_89(i64 %n,i8 %p0,i8 %p1,i8 %p2,i8 %p3,i8 %p4,i8 %p5,i8 %p6,i8 %p7,i8 %p8,i8 %p9,i8 %p10,i8 %p11,i8 %p12,i8 %p13,i8 %p14,i8 %p15,i8 %p16,i8 %p17,i8 %p18,i8 %p19,i8 %p20,i8 %p21,i8 %p22,i8 %p23,i8 %p24,i8 %p25,i8 %p26,i8 %p27,i8 %p28,i8 %p29,i8 %p30,i8 %p31,i8 %p32,i8 %p33,i8 %p34,i8 %p35,i8 %p36,i8 %p37,i8 %p38,i8 %p39,i8 %p40,i8 %p41,i8 %p42,i8 %p43,i8 %p44,i8 %p45,i8 %p46,i8 %p47,i8 %p48,i8 %p49,i8 %p50,i8 %p51,i8 %p52,i8 %p53,i8 %p54,i8 %p55,i8 %p56,i8 %p57,i8 %p58,i8 %p59,i8 %p60,i8 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i8 %p1,17
 %left1 = add i8 %p2,34
 %left2 = add i8 %p3,51
 %left3 = add i8 %p4,68
 %left4 = add i8 %p5,85
 %left5 = add i8 %p6,102
 %left6 = add i8 %p7,119
 %left7 = add i8 %p8,136
 %left8 = add i8 %p9,153
 %left9 = add i8 %p10,170
 %left10 = add i8 %p11,187
 %left11 = add i8 %p12,204
 %left12 = add i8 %p13,221
 %left13 = add i8 %p14,238
 %left14 = add i8 %p15,255
 %left15 = add i8 %p16,16
 %left16 = add i8 %p17,33
 %left17 = add i8 %p18,50
 %left18 = add i8 %p19,67
 %left19 = add i8 %p20,84
 %left20 = add i8 %p21,101
 %left21 = add i8 %p22,118
 %left22 = add i8 %p23,135
 %left23 = add i8 %p24,152
 %left24 = add i8 %p25,169
 %left25 = add i8 %p26,186
 %left26 = add i8 %p27,203
 %left27 = add i8 %p28,220
 %left28 = add i8 %p29,237
 %left29 = add i8 %p30,254
 %left30 = add i8 %p31,15
 %left31 = add i8 %p32,32
 %left32 = add i8 %p33,49
 %left33 = add i8 %p34,66
 %left34 = add i8 %p35,83
 %left35 = add i8 %p36,100
 %left36 = add i8 %p37,117
 %left37 = add i8 %p38,134
 %left38 = add i8 %p39,151
 %left39 = add i8 %p40,168
 %left40 = add i8 %p41,185
 %left41 = add i8 %p42,202
 %left42 = add i8 %p43,219
 %left43 = add i8 %p44,236
 %left44 = add i8 %p45,253
 %left45 = add i8 %p46,14
 %left46 = add i8 %p47,31
 %left47 = add i8 %p48,48
 %left48 = add i8 %p49,65
 %left49 = add i8 %p50,82
 %left50 = add i8 %p51,99
 %left51 = add i8 %p52,116
 %left52 = add i8 %p53,133
 %left53 = add i8 %p54,150
 %left54 = add i8 %p55,167
 %left55 = add i8 %p56,184
 %left56 = add i8 %p57,201
 %left57 = add i8 %p58,218
 %left58 = add i8 %p59,235
 %left59 = add i8 %p60,252
 %left60 = add i8 %p61,13
 %left61 = add i8 %p0,30
 %answer = musttail call fastcc ptr @self_tail_body_89(i64 %next,i8 %left0,i8 %left1,i8 %left2,i8 %left3,i8 %left4,i8 %left5,i8 %left6,i8 %left7,i8 %left8,i8 %left9,i8 %left10,i8 %left11,i8 %left12,i8 %left13,i8 %left14,i8 %left15,i8 %left16,i8 %left17,i8 %left18,i8 %left19,i8 %left20,i8 %left21,i8 %left22,i8 %left23,i8 %left24,i8 %left25,i8 %left26,i8 %left27,i8 %left28,i8 %left29,i8 %left30,i8 %left31,i8 %left32,i8 %left33,i8 %left34,i8 %left35,i8 %left36,i8 %left37,i8 %left38,i8 %left39,i8 %left40,i8 %left41,i8 %left42,i8 %left43,i8 %left44,i8 %left45,i8 %left46,i8 %left47,i8 %left48,i8 %left49,i8 %left50,i8 %left51,i8 %left52,i8 %left53,i8 %left54,i8 %left55,i8 %left56,i8 %left57,i8 %left58,i8 %left59,i8 %left60,i8 %left61,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i8 %p61,31
 %right1 = xor i8 %p0,62
 %right2 = xor i8 %p1,93
 %right3 = xor i8 %p2,124
 %right4 = xor i8 %p3,155
 %right5 = xor i8 %p4,186
 %right6 = xor i8 %p5,217
 %right7 = xor i8 %p6,248
 %right8 = xor i8 %p7,23
 %right9 = xor i8 %p8,54
 %right10 = xor i8 %p9,85
 %right11 = xor i8 %p10,116
 %right12 = xor i8 %p11,147
 %right13 = xor i8 %p12,178
 %right14 = xor i8 %p13,209
 %right15 = xor i8 %p14,240
 %right16 = xor i8 %p15,15
 %right17 = xor i8 %p16,46
 %right18 = xor i8 %p17,77
 %right19 = xor i8 %p18,108
 %right20 = xor i8 %p19,139
 %right21 = xor i8 %p20,170
 %right22 = xor i8 %p21,201
 %right23 = xor i8 %p22,232
 %right24 = xor i8 %p23,7
 %right25 = xor i8 %p24,38
 %right26 = xor i8 %p25,69
 %right27 = xor i8 %p26,100
 %right28 = xor i8 %p27,131
 %right29 = xor i8 %p28,162
 %right30 = xor i8 %p29,193
 %right31 = xor i8 %p30,224
 %right32 = xor i8 %p31,255
 %right33 = xor i8 %p32,30
 %right34 = xor i8 %p33,61
 %right35 = xor i8 %p34,92
 %right36 = xor i8 %p35,123
 %right37 = xor i8 %p36,154
 %right38 = xor i8 %p37,185
 %right39 = xor i8 %p38,216
 %right40 = xor i8 %p39,247
 %right41 = xor i8 %p40,22
 %right42 = xor i8 %p41,53
 %right43 = xor i8 %p42,84
 %right44 = xor i8 %p43,115
 %right45 = xor i8 %p44,146
 %right46 = xor i8 %p45,177
 %right47 = xor i8 %p46,208
 %right48 = xor i8 %p47,239
 %right49 = xor i8 %p48,14
 %right50 = xor i8 %p49,45
 %right51 = xor i8 %p50,76
 %right52 = xor i8 %p51,107
 %right53 = xor i8 %p52,138
 %right54 = xor i8 %p53,169
 %right55 = xor i8 %p54,200
 %right56 = xor i8 %p55,231
 %right57 = xor i8 %p56,6
 %right58 = xor i8 %p57,37
 %right59 = xor i8 %p58,68
 %right60 = xor i8 %p59,99
 %right61 = xor i8 %p60,130
 %right_answer = musttail call fastcc ptr @self_tail_body_89(i64 %next,i8 %right0,i8 %right1,i8 %right2,i8 %right3,i8 %right4,i8 %right5,i8 %right6,i8 %right7,i8 %right8,i8 %right9,i8 %right10,i8 %right11,i8 %right12,i8 %right13,i8 %right14,i8 %right15,i8 %right16,i8 %right17,i8 %right18,i8 %right19,i8 %right20,i8 %right21,i8 %right22,i8 %right23,i8 %right24,i8 %right25,i8 %right26,i8 %right27,i8 %right28,i8 %right29,i8 %right30,i8 %right31,i8 %right32,i8 %right33,i8 %right34,i8 %right35,i8 %right36,i8 %right37,i8 %right38,i8 %right39,i8 %right40,i8 %right41,i8 %right42,i8 %right43,i8 %right44,i8 %right45,i8 %right46,i8 %right47,i8 %right48,i8 %right49,i8 %right50,i8 %right51,i8 %right52,i8 %right53,i8 %right54,i8 %right55,i8 %right56,i8 %right57,i8 %right58,i8 %right59,i8 %right60,i8 %right61,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i8 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i8 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i8 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i8 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i8 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i8 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i8 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i8 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i8 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i8 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i8 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i8 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i8 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i8 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i8 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i8 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i8 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i8 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i8 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i8 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i8 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i8 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i8 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i8 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i8 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i8 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i8 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i8 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i8 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i8 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i8 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i8 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i8 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i8 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i8 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i8 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i8 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i8 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i8 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i8 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i8 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i8 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i8 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i8 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i8 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i8 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i8 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i8 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i8 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i8 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i8 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i8 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i8 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i8 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i8 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i8 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i8 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i8 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i8 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i8 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i8 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i8 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_89(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i8
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i8
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i8
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i8
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i8
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i8
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i8
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i8
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i8
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i8
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i8
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i8
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i8
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i8
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i8
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i8
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i8
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i8
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i8
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i8
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i8
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i8
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i8
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i8
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i8
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i8
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i8
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i8
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i8
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i8
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i8
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i8
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i8
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i8
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i8
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i8
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i8
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i8
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i8
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i8
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i8
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i8
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i8
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i8
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i8
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i8
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i8
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i8
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i8
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i8
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i8
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i8
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i8
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i8
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i8
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i8
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i8
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i8
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i8
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i8
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i8
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i8
 %returned = call fastcc ptr @self_tail_body_89(i64 %count,i8 %v0,i8 %v1,i8 %v2,i8 %v3,i8 %v4,i8 %v5,i8 %v6,i8 %v7,i8 %v8,i8 %v9,i8 %v10,i8 %v11,i8 %v12,i8 %v13,i8 %v14,i8 %v15,i8 %v16,i8 %v17,i8 %v18,i8 %v19,i8 %v20,i8 %v21,i8 %v22,i8 %v23,i8 %v24,i8 %v25,i8 %v26,i8 %v27,i8 %v28,i8 %v29,i8 %v30,i8 %v31,i8 %v32,i8 %v33,i8 %v34,i8 %v35,i8 %v36,i8 %v37,i8 %v38,i8 %v39,i8 %v40,i8 %v41,i8 %v42,i8 %v43,i8 %v44,i8 %v45,i8 %v46,i8 %v47,i8 %v48,i8 %v49,i8 %v50,i8 %v51,i8 %v52,i8 %v53,i8 %v54,i8 %v55,i8 %v56,i8 %v57,i8 %v58,i8 %v59,i8 %v60,i8 %v61,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_90(i64 %n,i16 %p0,i16 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p0,34
 %answer = musttail call ptr @self_tail_body_90(i64 %next,i16 %left0,i16 %left1,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i16 %p1,31
 %right1 = xor i16 %p0,62
 %right_answer = musttail call ptr @self_tail_body_90(i64 %next,i16 %right0,i16 %right1,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_90(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %returned = call ptr @self_tail_body_90(i64 %count,i16 %v0,i16 %v1,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_91(i64 %n,i16 %p0,i16 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p0,34
 %answer = musttail call fastcc ptr @self_tail_body_91(i64 %next,i16 %left0,i16 %left1,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i16 %p1,31
 %right1 = xor i16 %p0,62
 %right_answer = musttail call fastcc ptr @self_tail_body_91(i64 %next,i16 %right0,i16 %right1,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_91(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %returned = call fastcc ptr @self_tail_body_91(i64 %count,i16 %v0,i16 %v1,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_92(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p0,85
 %answer = musttail call ptr @self_tail_body_92(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i16 %p4,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right_answer = musttail call ptr @self_tail_body_92(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_92(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %returned = call ptr @self_tail_body_92(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_93(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p0,85
 %answer = musttail call fastcc ptr @self_tail_body_93(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i16 %p4,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right_answer = musttail call fastcc ptr @self_tail_body_93(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_93(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %returned = call fastcc ptr @self_tail_body_93(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_94(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p0,136
 %answer = musttail call ptr @self_tail_body_94(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i16 %p7,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right_answer = musttail call ptr @self_tail_body_94(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_94(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %returned = call ptr @self_tail_body_94(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_95(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p0,136
 %answer = musttail call fastcc ptr @self_tail_body_95(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i16 %p7,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right_answer = musttail call fastcc ptr @self_tail_body_95(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_95(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %returned = call fastcc ptr @self_tail_body_95(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_96(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,i16 %p8,i16 %p9,i16 %p10,i16 %p11,i16 %p12,i16 %p13,i16 %p14,i16 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p8,136
 %left8 = add i16 %p9,153
 %left9 = add i16 %p10,170
 %left10 = add i16 %p11,187
 %left11 = add i16 %p12,204
 %left12 = add i16 %p13,221
 %left13 = add i16 %p14,238
 %left14 = add i16 %p15,255
 %left15 = add i16 %p0,272
 %answer = musttail call ptr @self_tail_body_96(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,i16 %left8,i16 %left9,i16 %left10,i16 %left11,i16 %left12,i16 %left13,i16 %left14,i16 %left15,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i16 %p15,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right8 = xor i16 %p7,279
 %right9 = xor i16 %p8,310
 %right10 = xor i16 %p9,341
 %right11 = xor i16 %p10,372
 %right12 = xor i16 %p11,403
 %right13 = xor i16 %p12,434
 %right14 = xor i16 %p13,465
 %right15 = xor i16 %p14,496
 %right_answer = musttail call ptr @self_tail_body_96(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,i16 %right8,i16 %right9,i16 %right10,i16 %right11,i16 %right12,i16 %right13,i16 %right14,i16 %right15,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i16 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i16 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i16 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i16 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i16 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i16 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i16 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i16 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_96(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i16
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i16
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i16
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i16
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i16
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i16
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i16
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i16
 %returned = call ptr @self_tail_body_96(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,i16 %v8,i16 %v9,i16 %v10,i16 %v11,i16 %v12,i16 %v13,i16 %v14,i16 %v15,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_97(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,i16 %p8,i16 %p9,i16 %p10,i16 %p11,i16 %p12,i16 %p13,i16 %p14,i16 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p8,136
 %left8 = add i16 %p9,153
 %left9 = add i16 %p10,170
 %left10 = add i16 %p11,187
 %left11 = add i16 %p12,204
 %left12 = add i16 %p13,221
 %left13 = add i16 %p14,238
 %left14 = add i16 %p15,255
 %left15 = add i16 %p0,272
 %answer = musttail call fastcc ptr @self_tail_body_97(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,i16 %left8,i16 %left9,i16 %left10,i16 %left11,i16 %left12,i16 %left13,i16 %left14,i16 %left15,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i16 %p15,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right8 = xor i16 %p7,279
 %right9 = xor i16 %p8,310
 %right10 = xor i16 %p9,341
 %right11 = xor i16 %p10,372
 %right12 = xor i16 %p11,403
 %right13 = xor i16 %p12,434
 %right14 = xor i16 %p13,465
 %right15 = xor i16 %p14,496
 %right_answer = musttail call fastcc ptr @self_tail_body_97(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,i16 %right8,i16 %right9,i16 %right10,i16 %right11,i16 %right12,i16 %right13,i16 %right14,i16 %right15,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i16 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i16 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i16 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i16 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i16 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i16 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i16 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i16 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_97(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i16
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i16
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i16
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i16
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i16
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i16
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i16
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i16
 %returned = call fastcc ptr @self_tail_body_97(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,i16 %v8,i16 %v9,i16 %v10,i16 %v11,i16 %v12,i16 %v13,i16 %v14,i16 %v15,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_98(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,i16 %p8,i16 %p9,i16 %p10,i16 %p11,i16 %p12,i16 %p13,i16 %p14,i16 %p15,i16 %p16,i16 %p17,i16 %p18,i16 %p19,i16 %p20,i16 %p21,i16 %p22,i16 %p23,i16 %p24,i16 %p25,i16 %p26,i16 %p27,i16 %p28,i16 %p29,i16 %p30,i16 %p31,i16 %p32,i16 %p33,i16 %p34,i16 %p35,i16 %p36,i16 %p37,i16 %p38,i16 %p39,i16 %p40,i16 %p41,i16 %p42,i16 %p43,i16 %p44,i16 %p45,i16 %p46,i16 %p47,i16 %p48,i16 %p49,i16 %p50,i16 %p51,i16 %p52,i16 %p53,i16 %p54,i16 %p55,i16 %p56,i16 %p57,i16 %p58,i16 %p59,i16 %p60,i16 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p8,136
 %left8 = add i16 %p9,153
 %left9 = add i16 %p10,170
 %left10 = add i16 %p11,187
 %left11 = add i16 %p12,204
 %left12 = add i16 %p13,221
 %left13 = add i16 %p14,238
 %left14 = add i16 %p15,255
 %left15 = add i16 %p16,272
 %left16 = add i16 %p17,289
 %left17 = add i16 %p18,306
 %left18 = add i16 %p19,323
 %left19 = add i16 %p20,340
 %left20 = add i16 %p21,357
 %left21 = add i16 %p22,374
 %left22 = add i16 %p23,391
 %left23 = add i16 %p24,408
 %left24 = add i16 %p25,425
 %left25 = add i16 %p26,442
 %left26 = add i16 %p27,459
 %left27 = add i16 %p28,476
 %left28 = add i16 %p29,493
 %left29 = add i16 %p30,510
 %left30 = add i16 %p31,527
 %left31 = add i16 %p32,544
 %left32 = add i16 %p33,561
 %left33 = add i16 %p34,578
 %left34 = add i16 %p35,595
 %left35 = add i16 %p36,612
 %left36 = add i16 %p37,629
 %left37 = add i16 %p38,646
 %left38 = add i16 %p39,663
 %left39 = add i16 %p40,680
 %left40 = add i16 %p41,697
 %left41 = add i16 %p42,714
 %left42 = add i16 %p43,731
 %left43 = add i16 %p44,748
 %left44 = add i16 %p45,765
 %left45 = add i16 %p46,782
 %left46 = add i16 %p47,799
 %left47 = add i16 %p48,816
 %left48 = add i16 %p49,833
 %left49 = add i16 %p50,850
 %left50 = add i16 %p51,867
 %left51 = add i16 %p52,884
 %left52 = add i16 %p53,901
 %left53 = add i16 %p54,918
 %left54 = add i16 %p55,935
 %left55 = add i16 %p56,952
 %left56 = add i16 %p57,969
 %left57 = add i16 %p58,986
 %left58 = add i16 %p59,1003
 %left59 = add i16 %p60,1020
 %left60 = add i16 %p61,1037
 %left61 = add i16 %p0,1054
 %answer = musttail call ptr @self_tail_body_98(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,i16 %left8,i16 %left9,i16 %left10,i16 %left11,i16 %left12,i16 %left13,i16 %left14,i16 %left15,i16 %left16,i16 %left17,i16 %left18,i16 %left19,i16 %left20,i16 %left21,i16 %left22,i16 %left23,i16 %left24,i16 %left25,i16 %left26,i16 %left27,i16 %left28,i16 %left29,i16 %left30,i16 %left31,i16 %left32,i16 %left33,i16 %left34,i16 %left35,i16 %left36,i16 %left37,i16 %left38,i16 %left39,i16 %left40,i16 %left41,i16 %left42,i16 %left43,i16 %left44,i16 %left45,i16 %left46,i16 %left47,i16 %left48,i16 %left49,i16 %left50,i16 %left51,i16 %left52,i16 %left53,i16 %left54,i16 %left55,i16 %left56,i16 %left57,i16 %left58,i16 %left59,i16 %left60,i16 %left61,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i16 %p61,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right8 = xor i16 %p7,279
 %right9 = xor i16 %p8,310
 %right10 = xor i16 %p9,341
 %right11 = xor i16 %p10,372
 %right12 = xor i16 %p11,403
 %right13 = xor i16 %p12,434
 %right14 = xor i16 %p13,465
 %right15 = xor i16 %p14,496
 %right16 = xor i16 %p15,527
 %right17 = xor i16 %p16,558
 %right18 = xor i16 %p17,589
 %right19 = xor i16 %p18,620
 %right20 = xor i16 %p19,651
 %right21 = xor i16 %p20,682
 %right22 = xor i16 %p21,713
 %right23 = xor i16 %p22,744
 %right24 = xor i16 %p23,775
 %right25 = xor i16 %p24,806
 %right26 = xor i16 %p25,837
 %right27 = xor i16 %p26,868
 %right28 = xor i16 %p27,899
 %right29 = xor i16 %p28,930
 %right30 = xor i16 %p29,961
 %right31 = xor i16 %p30,992
 %right32 = xor i16 %p31,1023
 %right33 = xor i16 %p32,1054
 %right34 = xor i16 %p33,1085
 %right35 = xor i16 %p34,1116
 %right36 = xor i16 %p35,1147
 %right37 = xor i16 %p36,1178
 %right38 = xor i16 %p37,1209
 %right39 = xor i16 %p38,1240
 %right40 = xor i16 %p39,1271
 %right41 = xor i16 %p40,1302
 %right42 = xor i16 %p41,1333
 %right43 = xor i16 %p42,1364
 %right44 = xor i16 %p43,1395
 %right45 = xor i16 %p44,1426
 %right46 = xor i16 %p45,1457
 %right47 = xor i16 %p46,1488
 %right48 = xor i16 %p47,1519
 %right49 = xor i16 %p48,1550
 %right50 = xor i16 %p49,1581
 %right51 = xor i16 %p50,1612
 %right52 = xor i16 %p51,1643
 %right53 = xor i16 %p52,1674
 %right54 = xor i16 %p53,1705
 %right55 = xor i16 %p54,1736
 %right56 = xor i16 %p55,1767
 %right57 = xor i16 %p56,1798
 %right58 = xor i16 %p57,1829
 %right59 = xor i16 %p58,1860
 %right60 = xor i16 %p59,1891
 %right61 = xor i16 %p60,1922
 %right_answer = musttail call ptr @self_tail_body_98(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,i16 %right8,i16 %right9,i16 %right10,i16 %right11,i16 %right12,i16 %right13,i16 %right14,i16 %right15,i16 %right16,i16 %right17,i16 %right18,i16 %right19,i16 %right20,i16 %right21,i16 %right22,i16 %right23,i16 %right24,i16 %right25,i16 %right26,i16 %right27,i16 %right28,i16 %right29,i16 %right30,i16 %right31,i16 %right32,i16 %right33,i16 %right34,i16 %right35,i16 %right36,i16 %right37,i16 %right38,i16 %right39,i16 %right40,i16 %right41,i16 %right42,i16 %right43,i16 %right44,i16 %right45,i16 %right46,i16 %right47,i16 %right48,i16 %right49,i16 %right50,i16 %right51,i16 %right52,i16 %right53,i16 %right54,i16 %right55,i16 %right56,i16 %right57,i16 %right58,i16 %right59,i16 %right60,i16 %right61,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i16 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i16 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i16 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i16 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i16 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i16 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i16 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i16 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i16 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i16 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i16 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i16 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i16 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i16 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i16 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i16 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i16 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i16 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i16 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i16 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i16 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i16 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i16 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i16 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i16 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i16 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i16 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i16 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i16 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i16 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i16 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i16 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i16 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i16 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i16 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i16 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i16 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i16 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i16 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i16 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i16 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i16 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i16 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i16 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i16 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i16 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i16 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i16 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i16 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i16 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i16 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i16 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i16 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i16 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_98(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i16
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i16
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i16
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i16
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i16
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i16
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i16
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i16
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i16
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i16
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i16
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i16
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i16
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i16
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i16
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i16
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i16
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i16
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i16
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i16
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i16
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i16
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i16
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i16
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i16
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i16
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i16
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i16
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i16
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i16
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i16
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i16
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i16
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i16
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i16
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i16
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i16
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i16
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i16
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i16
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i16
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i16
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i16
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i16
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i16
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i16
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i16
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i16
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i16
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i16
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i16
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i16
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i16
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i16
 %returned = call ptr @self_tail_body_98(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,i16 %v8,i16 %v9,i16 %v10,i16 %v11,i16 %v12,i16 %v13,i16 %v14,i16 %v15,i16 %v16,i16 %v17,i16 %v18,i16 %v19,i16 %v20,i16 %v21,i16 %v22,i16 %v23,i16 %v24,i16 %v25,i16 %v26,i16 %v27,i16 %v28,i16 %v29,i16 %v30,i16 %v31,i16 %v32,i16 %v33,i16 %v34,i16 %v35,i16 %v36,i16 %v37,i16 %v38,i16 %v39,i16 %v40,i16 %v41,i16 %v42,i16 %v43,i16 %v44,i16 %v45,i16 %v46,i16 %v47,i16 %v48,i16 %v49,i16 %v50,i16 %v51,i16 %v52,i16 %v53,i16 %v54,i16 %v55,i16 %v56,i16 %v57,i16 %v58,i16 %v59,i16 %v60,i16 %v61,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_99(i64 %n,i16 %p0,i16 %p1,i16 %p2,i16 %p3,i16 %p4,i16 %p5,i16 %p6,i16 %p7,i16 %p8,i16 %p9,i16 %p10,i16 %p11,i16 %p12,i16 %p13,i16 %p14,i16 %p15,i16 %p16,i16 %p17,i16 %p18,i16 %p19,i16 %p20,i16 %p21,i16 %p22,i16 %p23,i16 %p24,i16 %p25,i16 %p26,i16 %p27,i16 %p28,i16 %p29,i16 %p30,i16 %p31,i16 %p32,i16 %p33,i16 %p34,i16 %p35,i16 %p36,i16 %p37,i16 %p38,i16 %p39,i16 %p40,i16 %p41,i16 %p42,i16 %p43,i16 %p44,i16 %p45,i16 %p46,i16 %p47,i16 %p48,i16 %p49,i16 %p50,i16 %p51,i16 %p52,i16 %p53,i16 %p54,i16 %p55,i16 %p56,i16 %p57,i16 %p58,i16 %p59,i16 %p60,i16 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i16 %p1,17
 %left1 = add i16 %p2,34
 %left2 = add i16 %p3,51
 %left3 = add i16 %p4,68
 %left4 = add i16 %p5,85
 %left5 = add i16 %p6,102
 %left6 = add i16 %p7,119
 %left7 = add i16 %p8,136
 %left8 = add i16 %p9,153
 %left9 = add i16 %p10,170
 %left10 = add i16 %p11,187
 %left11 = add i16 %p12,204
 %left12 = add i16 %p13,221
 %left13 = add i16 %p14,238
 %left14 = add i16 %p15,255
 %left15 = add i16 %p16,272
 %left16 = add i16 %p17,289
 %left17 = add i16 %p18,306
 %left18 = add i16 %p19,323
 %left19 = add i16 %p20,340
 %left20 = add i16 %p21,357
 %left21 = add i16 %p22,374
 %left22 = add i16 %p23,391
 %left23 = add i16 %p24,408
 %left24 = add i16 %p25,425
 %left25 = add i16 %p26,442
 %left26 = add i16 %p27,459
 %left27 = add i16 %p28,476
 %left28 = add i16 %p29,493
 %left29 = add i16 %p30,510
 %left30 = add i16 %p31,527
 %left31 = add i16 %p32,544
 %left32 = add i16 %p33,561
 %left33 = add i16 %p34,578
 %left34 = add i16 %p35,595
 %left35 = add i16 %p36,612
 %left36 = add i16 %p37,629
 %left37 = add i16 %p38,646
 %left38 = add i16 %p39,663
 %left39 = add i16 %p40,680
 %left40 = add i16 %p41,697
 %left41 = add i16 %p42,714
 %left42 = add i16 %p43,731
 %left43 = add i16 %p44,748
 %left44 = add i16 %p45,765
 %left45 = add i16 %p46,782
 %left46 = add i16 %p47,799
 %left47 = add i16 %p48,816
 %left48 = add i16 %p49,833
 %left49 = add i16 %p50,850
 %left50 = add i16 %p51,867
 %left51 = add i16 %p52,884
 %left52 = add i16 %p53,901
 %left53 = add i16 %p54,918
 %left54 = add i16 %p55,935
 %left55 = add i16 %p56,952
 %left56 = add i16 %p57,969
 %left57 = add i16 %p58,986
 %left58 = add i16 %p59,1003
 %left59 = add i16 %p60,1020
 %left60 = add i16 %p61,1037
 %left61 = add i16 %p0,1054
 %answer = musttail call fastcc ptr @self_tail_body_99(i64 %next,i16 %left0,i16 %left1,i16 %left2,i16 %left3,i16 %left4,i16 %left5,i16 %left6,i16 %left7,i16 %left8,i16 %left9,i16 %left10,i16 %left11,i16 %left12,i16 %left13,i16 %left14,i16 %left15,i16 %left16,i16 %left17,i16 %left18,i16 %left19,i16 %left20,i16 %left21,i16 %left22,i16 %left23,i16 %left24,i16 %left25,i16 %left26,i16 %left27,i16 %left28,i16 %left29,i16 %left30,i16 %left31,i16 %left32,i16 %left33,i16 %left34,i16 %left35,i16 %left36,i16 %left37,i16 %left38,i16 %left39,i16 %left40,i16 %left41,i16 %left42,i16 %left43,i16 %left44,i16 %left45,i16 %left46,i16 %left47,i16 %left48,i16 %left49,i16 %left50,i16 %left51,i16 %left52,i16 %left53,i16 %left54,i16 %left55,i16 %left56,i16 %left57,i16 %left58,i16 %left59,i16 %left60,i16 %left61,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i16 %p61,31
 %right1 = xor i16 %p0,62
 %right2 = xor i16 %p1,93
 %right3 = xor i16 %p2,124
 %right4 = xor i16 %p3,155
 %right5 = xor i16 %p4,186
 %right6 = xor i16 %p5,217
 %right7 = xor i16 %p6,248
 %right8 = xor i16 %p7,279
 %right9 = xor i16 %p8,310
 %right10 = xor i16 %p9,341
 %right11 = xor i16 %p10,372
 %right12 = xor i16 %p11,403
 %right13 = xor i16 %p12,434
 %right14 = xor i16 %p13,465
 %right15 = xor i16 %p14,496
 %right16 = xor i16 %p15,527
 %right17 = xor i16 %p16,558
 %right18 = xor i16 %p17,589
 %right19 = xor i16 %p18,620
 %right20 = xor i16 %p19,651
 %right21 = xor i16 %p20,682
 %right22 = xor i16 %p21,713
 %right23 = xor i16 %p22,744
 %right24 = xor i16 %p23,775
 %right25 = xor i16 %p24,806
 %right26 = xor i16 %p25,837
 %right27 = xor i16 %p26,868
 %right28 = xor i16 %p27,899
 %right29 = xor i16 %p28,930
 %right30 = xor i16 %p29,961
 %right31 = xor i16 %p30,992
 %right32 = xor i16 %p31,1023
 %right33 = xor i16 %p32,1054
 %right34 = xor i16 %p33,1085
 %right35 = xor i16 %p34,1116
 %right36 = xor i16 %p35,1147
 %right37 = xor i16 %p36,1178
 %right38 = xor i16 %p37,1209
 %right39 = xor i16 %p38,1240
 %right40 = xor i16 %p39,1271
 %right41 = xor i16 %p40,1302
 %right42 = xor i16 %p41,1333
 %right43 = xor i16 %p42,1364
 %right44 = xor i16 %p43,1395
 %right45 = xor i16 %p44,1426
 %right46 = xor i16 %p45,1457
 %right47 = xor i16 %p46,1488
 %right48 = xor i16 %p47,1519
 %right49 = xor i16 %p48,1550
 %right50 = xor i16 %p49,1581
 %right51 = xor i16 %p50,1612
 %right52 = xor i16 %p51,1643
 %right53 = xor i16 %p52,1674
 %right54 = xor i16 %p53,1705
 %right55 = xor i16 %p54,1736
 %right56 = xor i16 %p55,1767
 %right57 = xor i16 %p56,1798
 %right58 = xor i16 %p57,1829
 %right59 = xor i16 %p58,1860
 %right60 = xor i16 %p59,1891
 %right61 = xor i16 %p60,1922
 %right_answer = musttail call fastcc ptr @self_tail_body_99(i64 %next,i16 %right0,i16 %right1,i16 %right2,i16 %right3,i16 %right4,i16 %right5,i16 %right6,i16 %right7,i16 %right8,i16 %right9,i16 %right10,i16 %right11,i16 %right12,i16 %right13,i16 %right14,i16 %right15,i16 %right16,i16 %right17,i16 %right18,i16 %right19,i16 %right20,i16 %right21,i16 %right22,i16 %right23,i16 %right24,i16 %right25,i16 %right26,i16 %right27,i16 %right28,i16 %right29,i16 %right30,i16 %right31,i16 %right32,i16 %right33,i16 %right34,i16 %right35,i16 %right36,i16 %right37,i16 %right38,i16 %right39,i16 %right40,i16 %right41,i16 %right42,i16 %right43,i16 %right44,i16 %right45,i16 %right46,i16 %right47,i16 %right48,i16 %right49,i16 %right50,i16 %right51,i16 %right52,i16 %right53,i16 %right54,i16 %right55,i16 %right56,i16 %right57,i16 %right58,i16 %right59,i16 %right60,i16 %right61,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i16 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i16 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i16 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i16 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i16 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i16 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i16 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i16 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i16 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i16 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i16 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i16 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i16 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i16 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i16 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i16 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i16 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i16 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i16 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i16 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i16 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i16 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i16 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i16 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i16 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i16 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i16 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i16 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i16 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i16 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i16 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i16 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i16 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i16 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i16 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i16 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i16 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i16 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i16 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i16 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i16 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i16 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i16 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i16 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i16 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i16 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i16 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i16 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i16 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i16 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i16 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i16 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i16 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i16 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i16 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i16 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i16 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i16 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i16 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i16 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i16 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i16 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_99(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i16
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i16
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i16
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i16
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i16
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i16
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i16
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i16
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i16
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i16
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i16
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i16
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i16
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i16
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i16
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i16
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i16
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i16
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i16
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i16
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i16
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i16
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i16
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i16
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i16
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i16
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i16
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i16
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i16
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i16
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i16
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i16
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i16
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i16
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i16
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i16
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i16
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i16
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i16
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i16
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i16
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i16
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i16
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i16
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i16
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i16
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i16
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i16
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i16
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i16
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i16
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i16
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i16
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i16
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i16
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i16
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i16
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i16
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i16
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i16
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i16
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i16
 %returned = call fastcc ptr @self_tail_body_99(i64 %count,i16 %v0,i16 %v1,i16 %v2,i16 %v3,i16 %v4,i16 %v5,i16 %v6,i16 %v7,i16 %v8,i16 %v9,i16 %v10,i16 %v11,i16 %v12,i16 %v13,i16 %v14,i16 %v15,i16 %v16,i16 %v17,i16 %v18,i16 %v19,i16 %v20,i16 %v21,i16 %v22,i16 %v23,i16 %v24,i16 %v25,i16 %v26,i16 %v27,i16 %v28,i16 %v29,i16 %v30,i16 %v31,i16 %v32,i16 %v33,i16 %v34,i16 %v35,i16 %v36,i16 %v37,i16 %v38,i16 %v39,i16 %v40,i16 %v41,i16 %v42,i16 %v43,i16 %v44,i16 %v45,i16 %v46,i16 %v47,i16 %v48,i16 %v49,i16 %v50,i16 %v51,i16 %v52,i16 %v53,i16 %v54,i16 %v55,i16 %v56,i16 %v57,i16 %v58,i16 %v59,i16 %v60,i16 %v61,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_100(i64 %n,i32 %p0,i32 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p0,34
 %answer = musttail call ptr @self_tail_body_100(i64 %next,i32 %left0,i32 %left1,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i32 %p1,31
 %right1 = xor i32 %p0,62
 %right_answer = musttail call ptr @self_tail_body_100(i64 %next,i32 %right0,i32 %right1,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_100(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %returned = call ptr @self_tail_body_100(i64 %count,i32 %v0,i32 %v1,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_101(i64 %n,i32 %p0,i32 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p0,34
 %answer = musttail call fastcc ptr @self_tail_body_101(i64 %next,i32 %left0,i32 %left1,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i32 %p1,31
 %right1 = xor i32 %p0,62
 %right_answer = musttail call fastcc ptr @self_tail_body_101(i64 %next,i32 %right0,i32 %right1,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide1,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_101(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %returned = call fastcc ptr @self_tail_body_101(i64 %count,i32 %v0,i32 %v1,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_102(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p0,85
 %answer = musttail call ptr @self_tail_body_102(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i32 %p4,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right_answer = musttail call ptr @self_tail_body_102(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_102(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %returned = call ptr @self_tail_body_102(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_103(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p0,85
 %answer = musttail call fastcc ptr @self_tail_body_103(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i32 %p4,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right_answer = musttail call fastcc ptr @self_tail_body_103(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide4,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_103(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %returned = call fastcc ptr @self_tail_body_103(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_104(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p0,136
 %answer = musttail call ptr @self_tail_body_104(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i32 %p7,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right_answer = musttail call ptr @self_tail_body_104(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_104(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %returned = call ptr @self_tail_body_104(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_105(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p0,136
 %answer = musttail call fastcc ptr @self_tail_body_105(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i32 %p7,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right_answer = musttail call fastcc ptr @self_tail_body_105(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide7,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_105(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %returned = call fastcc ptr @self_tail_body_105(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_106(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,i32 %p8,i32 %p9,i32 %p10,i32 %p11,i32 %p12,i32 %p13,i32 %p14,i32 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p8,136
 %left8 = add i32 %p9,153
 %left9 = add i32 %p10,170
 %left10 = add i32 %p11,187
 %left11 = add i32 %p12,204
 %left12 = add i32 %p13,221
 %left13 = add i32 %p14,238
 %left14 = add i32 %p15,255
 %left15 = add i32 %p0,272
 %answer = musttail call ptr @self_tail_body_106(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,i32 %left8,i32 %left9,i32 %left10,i32 %left11,i32 %left12,i32 %left13,i32 %left14,i32 %left15,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i32 %p15,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right8 = xor i32 %p7,279
 %right9 = xor i32 %p8,310
 %right10 = xor i32 %p9,341
 %right11 = xor i32 %p10,372
 %right12 = xor i32 %p11,403
 %right13 = xor i32 %p12,434
 %right14 = xor i32 %p13,465
 %right15 = xor i32 %p14,496
 %right_answer = musttail call ptr @self_tail_body_106(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,i32 %right8,i32 %right9,i32 %right10,i32 %right11,i32 %right12,i32 %right13,i32 %right14,i32 %right15,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i32 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i32 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i32 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i32 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i32 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i32 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i32 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i32 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_106(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i32
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i32
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i32
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i32
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i32
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i32
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i32
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i32
 %returned = call ptr @self_tail_body_106(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,i32 %v8,i32 %v9,i32 %v10,i32 %v11,i32 %v12,i32 %v13,i32 %v14,i32 %v15,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_107(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,i32 %p8,i32 %p9,i32 %p10,i32 %p11,i32 %p12,i32 %p13,i32 %p14,i32 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p8,136
 %left8 = add i32 %p9,153
 %left9 = add i32 %p10,170
 %left10 = add i32 %p11,187
 %left11 = add i32 %p12,204
 %left12 = add i32 %p13,221
 %left13 = add i32 %p14,238
 %left14 = add i32 %p15,255
 %left15 = add i32 %p0,272
 %answer = musttail call fastcc ptr @self_tail_body_107(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,i32 %left8,i32 %left9,i32 %left10,i32 %left11,i32 %left12,i32 %left13,i32 %left14,i32 %left15,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i32 %p15,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right8 = xor i32 %p7,279
 %right9 = xor i32 %p8,310
 %right10 = xor i32 %p9,341
 %right11 = xor i32 %p10,372
 %right12 = xor i32 %p11,403
 %right13 = xor i32 %p12,434
 %right14 = xor i32 %p13,465
 %right15 = xor i32 %p14,496
 %right_answer = musttail call fastcc ptr @self_tail_body_107(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,i32 %right8,i32 %right9,i32 %right10,i32 %right11,i32 %right12,i32 %right13,i32 %right14,i32 %right15,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i32 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i32 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i32 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i32 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i32 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i32 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i32 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i32 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide15,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_107(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i32
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i32
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i32
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i32
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i32
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i32
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i32
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i32
 %returned = call fastcc ptr @self_tail_body_107(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,i32 %v8,i32 %v9,i32 %v10,i32 %v11,i32 %v12,i32 %v13,i32 %v14,i32 %v15,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_108(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,i32 %p8,i32 %p9,i32 %p10,i32 %p11,i32 %p12,i32 %p13,i32 %p14,i32 %p15,i32 %p16,i32 %p17,i32 %p18,i32 %p19,i32 %p20,i32 %p21,i32 %p22,i32 %p23,i32 %p24,i32 %p25,i32 %p26,i32 %p27,i32 %p28,i32 %p29,i32 %p30,i32 %p31,i32 %p32,i32 %p33,i32 %p34,i32 %p35,i32 %p36,i32 %p37,i32 %p38,i32 %p39,i32 %p40,i32 %p41,i32 %p42,i32 %p43,i32 %p44,i32 %p45,i32 %p46,i32 %p47,i32 %p48,i32 %p49,i32 %p50,i32 %p51,i32 %p52,i32 %p53,i32 %p54,i32 %p55,i32 %p56,i32 %p57,i32 %p58,i32 %p59,i32 %p60,i32 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p8,136
 %left8 = add i32 %p9,153
 %left9 = add i32 %p10,170
 %left10 = add i32 %p11,187
 %left11 = add i32 %p12,204
 %left12 = add i32 %p13,221
 %left13 = add i32 %p14,238
 %left14 = add i32 %p15,255
 %left15 = add i32 %p16,272
 %left16 = add i32 %p17,289
 %left17 = add i32 %p18,306
 %left18 = add i32 %p19,323
 %left19 = add i32 %p20,340
 %left20 = add i32 %p21,357
 %left21 = add i32 %p22,374
 %left22 = add i32 %p23,391
 %left23 = add i32 %p24,408
 %left24 = add i32 %p25,425
 %left25 = add i32 %p26,442
 %left26 = add i32 %p27,459
 %left27 = add i32 %p28,476
 %left28 = add i32 %p29,493
 %left29 = add i32 %p30,510
 %left30 = add i32 %p31,527
 %left31 = add i32 %p32,544
 %left32 = add i32 %p33,561
 %left33 = add i32 %p34,578
 %left34 = add i32 %p35,595
 %left35 = add i32 %p36,612
 %left36 = add i32 %p37,629
 %left37 = add i32 %p38,646
 %left38 = add i32 %p39,663
 %left39 = add i32 %p40,680
 %left40 = add i32 %p41,697
 %left41 = add i32 %p42,714
 %left42 = add i32 %p43,731
 %left43 = add i32 %p44,748
 %left44 = add i32 %p45,765
 %left45 = add i32 %p46,782
 %left46 = add i32 %p47,799
 %left47 = add i32 %p48,816
 %left48 = add i32 %p49,833
 %left49 = add i32 %p50,850
 %left50 = add i32 %p51,867
 %left51 = add i32 %p52,884
 %left52 = add i32 %p53,901
 %left53 = add i32 %p54,918
 %left54 = add i32 %p55,935
 %left55 = add i32 %p56,952
 %left56 = add i32 %p57,969
 %left57 = add i32 %p58,986
 %left58 = add i32 %p59,1003
 %left59 = add i32 %p60,1020
 %left60 = add i32 %p61,1037
 %left61 = add i32 %p0,1054
 %answer = musttail call ptr @self_tail_body_108(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,i32 %left8,i32 %left9,i32 %left10,i32 %left11,i32 %left12,i32 %left13,i32 %left14,i32 %left15,i32 %left16,i32 %left17,i32 %left18,i32 %left19,i32 %left20,i32 %left21,i32 %left22,i32 %left23,i32 %left24,i32 %left25,i32 %left26,i32 %left27,i32 %left28,i32 %left29,i32 %left30,i32 %left31,i32 %left32,i32 %left33,i32 %left34,i32 %left35,i32 %left36,i32 %left37,i32 %left38,i32 %left39,i32 %left40,i32 %left41,i32 %left42,i32 %left43,i32 %left44,i32 %left45,i32 %left46,i32 %left47,i32 %left48,i32 %left49,i32 %left50,i32 %left51,i32 %left52,i32 %left53,i32 %left54,i32 %left55,i32 %left56,i32 %left57,i32 %left58,i32 %left59,i32 %left60,i32 %left61,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i32 %p61,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right8 = xor i32 %p7,279
 %right9 = xor i32 %p8,310
 %right10 = xor i32 %p9,341
 %right11 = xor i32 %p10,372
 %right12 = xor i32 %p11,403
 %right13 = xor i32 %p12,434
 %right14 = xor i32 %p13,465
 %right15 = xor i32 %p14,496
 %right16 = xor i32 %p15,527
 %right17 = xor i32 %p16,558
 %right18 = xor i32 %p17,589
 %right19 = xor i32 %p18,620
 %right20 = xor i32 %p19,651
 %right21 = xor i32 %p20,682
 %right22 = xor i32 %p21,713
 %right23 = xor i32 %p22,744
 %right24 = xor i32 %p23,775
 %right25 = xor i32 %p24,806
 %right26 = xor i32 %p25,837
 %right27 = xor i32 %p26,868
 %right28 = xor i32 %p27,899
 %right29 = xor i32 %p28,930
 %right30 = xor i32 %p29,961
 %right31 = xor i32 %p30,992
 %right32 = xor i32 %p31,1023
 %right33 = xor i32 %p32,1054
 %right34 = xor i32 %p33,1085
 %right35 = xor i32 %p34,1116
 %right36 = xor i32 %p35,1147
 %right37 = xor i32 %p36,1178
 %right38 = xor i32 %p37,1209
 %right39 = xor i32 %p38,1240
 %right40 = xor i32 %p39,1271
 %right41 = xor i32 %p40,1302
 %right42 = xor i32 %p41,1333
 %right43 = xor i32 %p42,1364
 %right44 = xor i32 %p43,1395
 %right45 = xor i32 %p44,1426
 %right46 = xor i32 %p45,1457
 %right47 = xor i32 %p46,1488
 %right48 = xor i32 %p47,1519
 %right49 = xor i32 %p48,1550
 %right50 = xor i32 %p49,1581
 %right51 = xor i32 %p50,1612
 %right52 = xor i32 %p51,1643
 %right53 = xor i32 %p52,1674
 %right54 = xor i32 %p53,1705
 %right55 = xor i32 %p54,1736
 %right56 = xor i32 %p55,1767
 %right57 = xor i32 %p56,1798
 %right58 = xor i32 %p57,1829
 %right59 = xor i32 %p58,1860
 %right60 = xor i32 %p59,1891
 %right61 = xor i32 %p60,1922
 %right_answer = musttail call ptr @self_tail_body_108(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,i32 %right8,i32 %right9,i32 %right10,i32 %right11,i32 %right12,i32 %right13,i32 %right14,i32 %right15,i32 %right16,i32 %right17,i32 %right18,i32 %right19,i32 %right20,i32 %right21,i32 %right22,i32 %right23,i32 %right24,i32 %right25,i32 %right26,i32 %right27,i32 %right28,i32 %right29,i32 %right30,i32 %right31,i32 %right32,i32 %right33,i32 %right34,i32 %right35,i32 %right36,i32 %right37,i32 %right38,i32 %right39,i32 %right40,i32 %right41,i32 %right42,i32 %right43,i32 %right44,i32 %right45,i32 %right46,i32 %right47,i32 %right48,i32 %right49,i32 %right50,i32 %right51,i32 %right52,i32 %right53,i32 %right54,i32 %right55,i32 %right56,i32 %right57,i32 %right58,i32 %right59,i32 %right60,i32 %right61,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i32 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i32 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i32 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i32 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i32 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i32 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i32 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i32 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i32 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i32 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i32 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i32 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i32 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i32 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i32 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i32 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i32 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i32 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i32 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i32 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i32 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i32 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i32 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i32 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i32 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i32 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i32 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i32 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i32 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i32 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i32 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i32 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i32 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i32 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i32 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i32 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i32 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i32 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i32 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i32 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i32 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i32 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i32 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i32 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i32 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i32 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i32 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i32 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i32 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i32 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i32 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i32 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i32 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i32 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_108(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i32
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i32
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i32
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i32
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i32
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i32
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i32
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i32
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i32
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i32
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i32
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i32
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i32
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i32
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i32
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i32
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i32
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i32
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i32
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i32
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i32
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i32
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i32
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i32
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i32
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i32
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i32
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i32
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i32
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i32
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i32
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i32
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i32
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i32
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i32
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i32
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i32
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i32
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i32
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i32
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i32
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i32
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i32
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i32
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i32
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i32
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i32
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i32
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i32
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i32
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i32
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i32
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i32
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i32
 %returned = call ptr @self_tail_body_108(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,i32 %v8,i32 %v9,i32 %v10,i32 %v11,i32 %v12,i32 %v13,i32 %v14,i32 %v15,i32 %v16,i32 %v17,i32 %v18,i32 %v19,i32 %v20,i32 %v21,i32 %v22,i32 %v23,i32 %v24,i32 %v25,i32 %v26,i32 %v27,i32 %v28,i32 %v29,i32 %v30,i32 %v31,i32 %v32,i32 %v33,i32 %v34,i32 %v35,i32 %v36,i32 %v37,i32 %v38,i32 %v39,i32 %v40,i32 %v41,i32 %v42,i32 %v43,i32 %v44,i32 %v45,i32 %v46,i32 %v47,i32 %v48,i32 %v49,i32 %v50,i32 %v51,i32 %v52,i32 %v53,i32 %v54,i32 %v55,i32 %v56,i32 %v57,i32 %v58,i32 %v59,i32 %v60,i32 %v61,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_109(i64 %n,i32 %p0,i32 %p1,i32 %p2,i32 %p3,i32 %p4,i32 %p5,i32 %p6,i32 %p7,i32 %p8,i32 %p9,i32 %p10,i32 %p11,i32 %p12,i32 %p13,i32 %p14,i32 %p15,i32 %p16,i32 %p17,i32 %p18,i32 %p19,i32 %p20,i32 %p21,i32 %p22,i32 %p23,i32 %p24,i32 %p25,i32 %p26,i32 %p27,i32 %p28,i32 %p29,i32 %p30,i32 %p31,i32 %p32,i32 %p33,i32 %p34,i32 %p35,i32 %p36,i32 %p37,i32 %p38,i32 %p39,i32 %p40,i32 %p41,i32 %p42,i32 %p43,i32 %p44,i32 %p45,i32 %p46,i32 %p47,i32 %p48,i32 %p49,i32 %p50,i32 %p51,i32 %p52,i32 %p53,i32 %p54,i32 %p55,i32 %p56,i32 %p57,i32 %p58,i32 %p59,i32 %p60,i32 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i32 %p1,17
 %left1 = add i32 %p2,34
 %left2 = add i32 %p3,51
 %left3 = add i32 %p4,68
 %left4 = add i32 %p5,85
 %left5 = add i32 %p6,102
 %left6 = add i32 %p7,119
 %left7 = add i32 %p8,136
 %left8 = add i32 %p9,153
 %left9 = add i32 %p10,170
 %left10 = add i32 %p11,187
 %left11 = add i32 %p12,204
 %left12 = add i32 %p13,221
 %left13 = add i32 %p14,238
 %left14 = add i32 %p15,255
 %left15 = add i32 %p16,272
 %left16 = add i32 %p17,289
 %left17 = add i32 %p18,306
 %left18 = add i32 %p19,323
 %left19 = add i32 %p20,340
 %left20 = add i32 %p21,357
 %left21 = add i32 %p22,374
 %left22 = add i32 %p23,391
 %left23 = add i32 %p24,408
 %left24 = add i32 %p25,425
 %left25 = add i32 %p26,442
 %left26 = add i32 %p27,459
 %left27 = add i32 %p28,476
 %left28 = add i32 %p29,493
 %left29 = add i32 %p30,510
 %left30 = add i32 %p31,527
 %left31 = add i32 %p32,544
 %left32 = add i32 %p33,561
 %left33 = add i32 %p34,578
 %left34 = add i32 %p35,595
 %left35 = add i32 %p36,612
 %left36 = add i32 %p37,629
 %left37 = add i32 %p38,646
 %left38 = add i32 %p39,663
 %left39 = add i32 %p40,680
 %left40 = add i32 %p41,697
 %left41 = add i32 %p42,714
 %left42 = add i32 %p43,731
 %left43 = add i32 %p44,748
 %left44 = add i32 %p45,765
 %left45 = add i32 %p46,782
 %left46 = add i32 %p47,799
 %left47 = add i32 %p48,816
 %left48 = add i32 %p49,833
 %left49 = add i32 %p50,850
 %left50 = add i32 %p51,867
 %left51 = add i32 %p52,884
 %left52 = add i32 %p53,901
 %left53 = add i32 %p54,918
 %left54 = add i32 %p55,935
 %left55 = add i32 %p56,952
 %left56 = add i32 %p57,969
 %left57 = add i32 %p58,986
 %left58 = add i32 %p59,1003
 %left59 = add i32 %p60,1020
 %left60 = add i32 %p61,1037
 %left61 = add i32 %p0,1054
 %answer = musttail call fastcc ptr @self_tail_body_109(i64 %next,i32 %left0,i32 %left1,i32 %left2,i32 %left3,i32 %left4,i32 %left5,i32 %left6,i32 %left7,i32 %left8,i32 %left9,i32 %left10,i32 %left11,i32 %left12,i32 %left13,i32 %left14,i32 %left15,i32 %left16,i32 %left17,i32 %left18,i32 %left19,i32 %left20,i32 %left21,i32 %left22,i32 %left23,i32 %left24,i32 %left25,i32 %left26,i32 %left27,i32 %left28,i32 %left29,i32 %left30,i32 %left31,i32 %left32,i32 %left33,i32 %left34,i32 %left35,i32 %left36,i32 %left37,i32 %left38,i32 %left39,i32 %left40,i32 %left41,i32 %left42,i32 %left43,i32 %left44,i32 %left45,i32 %left46,i32 %left47,i32 %left48,i32 %left49,i32 %left50,i32 %left51,i32 %left52,i32 %left53,i32 %left54,i32 %left55,i32 %left56,i32 %left57,i32 %left58,i32 %left59,i32 %left60,i32 %left61,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i32 %p61,31
 %right1 = xor i32 %p0,62
 %right2 = xor i32 %p1,93
 %right3 = xor i32 %p2,124
 %right4 = xor i32 %p3,155
 %right5 = xor i32 %p4,186
 %right6 = xor i32 %p5,217
 %right7 = xor i32 %p6,248
 %right8 = xor i32 %p7,279
 %right9 = xor i32 %p8,310
 %right10 = xor i32 %p9,341
 %right11 = xor i32 %p10,372
 %right12 = xor i32 %p11,403
 %right13 = xor i32 %p12,434
 %right14 = xor i32 %p13,465
 %right15 = xor i32 %p14,496
 %right16 = xor i32 %p15,527
 %right17 = xor i32 %p16,558
 %right18 = xor i32 %p17,589
 %right19 = xor i32 %p18,620
 %right20 = xor i32 %p19,651
 %right21 = xor i32 %p20,682
 %right22 = xor i32 %p21,713
 %right23 = xor i32 %p22,744
 %right24 = xor i32 %p23,775
 %right25 = xor i32 %p24,806
 %right26 = xor i32 %p25,837
 %right27 = xor i32 %p26,868
 %right28 = xor i32 %p27,899
 %right29 = xor i32 %p28,930
 %right30 = xor i32 %p29,961
 %right31 = xor i32 %p30,992
 %right32 = xor i32 %p31,1023
 %right33 = xor i32 %p32,1054
 %right34 = xor i32 %p33,1085
 %right35 = xor i32 %p34,1116
 %right36 = xor i32 %p35,1147
 %right37 = xor i32 %p36,1178
 %right38 = xor i32 %p37,1209
 %right39 = xor i32 %p38,1240
 %right40 = xor i32 %p39,1271
 %right41 = xor i32 %p40,1302
 %right42 = xor i32 %p41,1333
 %right43 = xor i32 %p42,1364
 %right44 = xor i32 %p43,1395
 %right45 = xor i32 %p44,1426
 %right46 = xor i32 %p45,1457
 %right47 = xor i32 %p46,1488
 %right48 = xor i32 %p47,1519
 %right49 = xor i32 %p48,1550
 %right50 = xor i32 %p49,1581
 %right51 = xor i32 %p50,1612
 %right52 = xor i32 %p51,1643
 %right53 = xor i32 %p52,1674
 %right54 = xor i32 %p53,1705
 %right55 = xor i32 %p54,1736
 %right56 = xor i32 %p55,1767
 %right57 = xor i32 %p56,1798
 %right58 = xor i32 %p57,1829
 %right59 = xor i32 %p58,1860
 %right60 = xor i32 %p59,1891
 %right61 = xor i32 %p60,1922
 %right_answer = musttail call fastcc ptr @self_tail_body_109(i64 %next,i32 %right0,i32 %right1,i32 %right2,i32 %right3,i32 %right4,i32 %right5,i32 %right6,i32 %right7,i32 %right8,i32 %right9,i32 %right10,i32 %right11,i32 %right12,i32 %right13,i32 %right14,i32 %right15,i32 %right16,i32 %right17,i32 %right18,i32 %right19,i32 %right20,i32 %right21,i32 %right22,i32 %right23,i32 %right24,i32 %right25,i32 %right26,i32 %right27,i32 %right28,i32 %right29,i32 %right30,i32 %right31,i32 %right32,i32 %right33,i32 %right34,i32 %right35,i32 %right36,i32 %right37,i32 %right38,i32 %right39,i32 %right40,i32 %right41,i32 %right42,i32 %right43,i32 %right44,i32 %right45,i32 %right46,i32 %right47,i32 %right48,i32 %right49,i32 %right50,i32 %right51,i32 %right52,i32 %right53,i32 %right54,i32 %right55,i32 %right56,i32 %right57,i32 %right58,i32 %right59,i32 %right60,i32 %right61,ptr %out)
 ret ptr %right_answer
exit:
 %wide0 = zext i32 %p0 to i64
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%wide0
 %wide1 = zext i32 %p1 to i64
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%wide1
 %wide2 = zext i32 %p2 to i64
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%wide2
 %wide3 = zext i32 %p3 to i64
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%wide3
 %wide4 = zext i32 %p4 to i64
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%wide4
 %wide5 = zext i32 %p5 to i64
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%wide5
 %wide6 = zext i32 %p6 to i64
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%wide6
 %wide7 = zext i32 %p7 to i64
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%wide7
 %wide8 = zext i32 %p8 to i64
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%wide8
 %wide9 = zext i32 %p9 to i64
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%wide9
 %wide10 = zext i32 %p10 to i64
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%wide10
 %wide11 = zext i32 %p11 to i64
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%wide11
 %wide12 = zext i32 %p12 to i64
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%wide12
 %wide13 = zext i32 %p13 to i64
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%wide13
 %wide14 = zext i32 %p14 to i64
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%wide14
 %wide15 = zext i32 %p15 to i64
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%wide15
 %wide16 = zext i32 %p16 to i64
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%wide16
 %wide17 = zext i32 %p17 to i64
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%wide17
 %wide18 = zext i32 %p18 to i64
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%wide18
 %wide19 = zext i32 %p19 to i64
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%wide19
 %wide20 = zext i32 %p20 to i64
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%wide20
 %wide21 = zext i32 %p21 to i64
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%wide21
 %wide22 = zext i32 %p22 to i64
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%wide22
 %wide23 = zext i32 %p23 to i64
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%wide23
 %wide24 = zext i32 %p24 to i64
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%wide24
 %wide25 = zext i32 %p25 to i64
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%wide25
 %wide26 = zext i32 %p26 to i64
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%wide26
 %wide27 = zext i32 %p27 to i64
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%wide27
 %wide28 = zext i32 %p28 to i64
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%wide28
 %wide29 = zext i32 %p29 to i64
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%wide29
 %wide30 = zext i32 %p30 to i64
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%wide30
 %wide31 = zext i32 %p31 to i64
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%wide31
 %wide32 = zext i32 %p32 to i64
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%wide32
 %wide33 = zext i32 %p33 to i64
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%wide33
 %wide34 = zext i32 %p34 to i64
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%wide34
 %wide35 = zext i32 %p35 to i64
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%wide35
 %wide36 = zext i32 %p36 to i64
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%wide36
 %wide37 = zext i32 %p37 to i64
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%wide37
 %wide38 = zext i32 %p38 to i64
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%wide38
 %wide39 = zext i32 %p39 to i64
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%wide39
 %wide40 = zext i32 %p40 to i64
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%wide40
 %wide41 = zext i32 %p41 to i64
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%wide41
 %wide42 = zext i32 %p42 to i64
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%wide42
 %wide43 = zext i32 %p43 to i64
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%wide43
 %wide44 = zext i32 %p44 to i64
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%wide44
 %wide45 = zext i32 %p45 to i64
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%wide45
 %wide46 = zext i32 %p46 to i64
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%wide46
 %wide47 = zext i32 %p47 to i64
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%wide47
 %wide48 = zext i32 %p48 to i64
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%wide48
 %wide49 = zext i32 %p49 to i64
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%wide49
 %wide50 = zext i32 %p50 to i64
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%wide50
 %wide51 = zext i32 %p51 to i64
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%wide51
 %wide52 = zext i32 %p52 to i64
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%wide52
 %wide53 = zext i32 %p53 to i64
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%wide53
 %wide54 = zext i32 %p54 to i64
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%wide54
 %wide55 = zext i32 %p55 to i64
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%wide55
 %wide56 = zext i32 %p56 to i64
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%wide56
 %wide57 = zext i32 %p57 to i64
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%wide57
 %wide58 = zext i32 %p58 to i64
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%wide58
 %wide59 = zext i32 %p59 to i64
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%wide59
 %wide60 = zext i32 %p60 to i64
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%wide60
 %wide61 = zext i32 %p61 to i64
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%wide61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %wide61,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_109(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %v0 = trunc i64 %raw0 to i32
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %v1 = trunc i64 %raw1 to i32
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %v2 = trunc i64 %raw2 to i32
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %v3 = trunc i64 %raw3 to i32
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %v4 = trunc i64 %raw4 to i32
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %v5 = trunc i64 %raw5 to i32
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %v6 = trunc i64 %raw6 to i32
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %v7 = trunc i64 %raw7 to i32
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %v8 = trunc i64 %raw8 to i32
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %v9 = trunc i64 %raw9 to i32
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %v10 = trunc i64 %raw10 to i32
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %v11 = trunc i64 %raw11 to i32
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %v12 = trunc i64 %raw12 to i32
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %v13 = trunc i64 %raw13 to i32
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %v14 = trunc i64 %raw14 to i32
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %v15 = trunc i64 %raw15 to i32
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %v16 = trunc i64 %raw16 to i32
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %v17 = trunc i64 %raw17 to i32
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %v18 = trunc i64 %raw18 to i32
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %v19 = trunc i64 %raw19 to i32
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %v20 = trunc i64 %raw20 to i32
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %v21 = trunc i64 %raw21 to i32
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %v22 = trunc i64 %raw22 to i32
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %v23 = trunc i64 %raw23 to i32
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %v24 = trunc i64 %raw24 to i32
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %v25 = trunc i64 %raw25 to i32
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %v26 = trunc i64 %raw26 to i32
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %v27 = trunc i64 %raw27 to i32
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %v28 = trunc i64 %raw28 to i32
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %v29 = trunc i64 %raw29 to i32
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %v30 = trunc i64 %raw30 to i32
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %v31 = trunc i64 %raw31 to i32
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %v32 = trunc i64 %raw32 to i32
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %v33 = trunc i64 %raw33 to i32
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %v34 = trunc i64 %raw34 to i32
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %v35 = trunc i64 %raw35 to i32
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %v36 = trunc i64 %raw36 to i32
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %v37 = trunc i64 %raw37 to i32
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %v38 = trunc i64 %raw38 to i32
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %v39 = trunc i64 %raw39 to i32
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %v40 = trunc i64 %raw40 to i32
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %v41 = trunc i64 %raw41 to i32
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %v42 = trunc i64 %raw42 to i32
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %v43 = trunc i64 %raw43 to i32
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %v44 = trunc i64 %raw44 to i32
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %v45 = trunc i64 %raw45 to i32
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %v46 = trunc i64 %raw46 to i32
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %v47 = trunc i64 %raw47 to i32
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %v48 = trunc i64 %raw48 to i32
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %v49 = trunc i64 %raw49 to i32
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %v50 = trunc i64 %raw50 to i32
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %v51 = trunc i64 %raw51 to i32
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %v52 = trunc i64 %raw52 to i32
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %v53 = trunc i64 %raw53 to i32
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %v54 = trunc i64 %raw54 to i32
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %v55 = trunc i64 %raw55 to i32
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %v56 = trunc i64 %raw56 to i32
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %v57 = trunc i64 %raw57 to i32
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %v58 = trunc i64 %raw58 to i32
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %v59 = trunc i64 %raw59 to i32
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %v60 = trunc i64 %raw60 to i32
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %v61 = trunc i64 %raw61 to i32
 %returned = call fastcc ptr @self_tail_body_109(i64 %count,i32 %v0,i32 %v1,i32 %v2,i32 %v3,i32 %v4,i32 %v5,i32 %v6,i32 %v7,i32 %v8,i32 %v9,i32 %v10,i32 %v11,i32 %v12,i32 %v13,i32 %v14,i32 %v15,i32 %v16,i32 %v17,i32 %v18,i32 %v19,i32 %v20,i32 %v21,i32 %v22,i32 %v23,i32 %v24,i32 %v25,i32 %v26,i32 %v27,i32 %v28,i32 %v29,i32 %v30,i32 %v31,i32 %v32,i32 %v33,i32 %v34,i32 %v35,i32 %v36,i32 %v37,i32 %v38,i32 %v39,i32 %v40,i32 %v41,i32 %v42,i32 %v43,i32 %v44,i32 %v45,i32 %v46,i32 %v47,i32 %v48,i32 %v49,i32 %v50,i32 %v51,i32 %v52,i32 %v53,i32 %v54,i32 %v55,i32 %v56,i32 %v57,i32 %v58,i32 %v59,i32 %v60,i32 %v61,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_110(i64 %n,i64 %p0,i64 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p0,34
 %answer = musttail call ptr @self_tail_body_110(i64 %next,i64 %left0,i64 %left1,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i64 %p1,31
 %right1 = xor i64 %p0,62
 %right_answer = musttail call ptr @self_tail_body_110(i64 %next,i64 %right0,i64 %right1,ptr %out)
 ret ptr %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p1,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_110(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %returned = call ptr @self_tail_body_110(i64 %count,i64 %raw0,i64 %raw1,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_111(i64 %n,i64 %p0,i64 %p1,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p0,34
 %answer = musttail call fastcc ptr @self_tail_body_111(i64 %next,i64 %left0,i64 %left1,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i64 %p1,31
 %right1 = xor i64 %p0,62
 %right_answer = musttail call fastcc ptr @self_tail_body_111(i64 %next,i64 %right0,i64 %right1,ptr %out)
 ret ptr %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r1,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p1,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_111(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %returned = call fastcc ptr @self_tail_body_111(i64 %count,i64 %raw0,i64 %raw1,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_112(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p0,85
 %answer = musttail call ptr @self_tail_body_112(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i64 %p4,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right_answer = musttail call ptr @self_tail_body_112(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,ptr %out)
 ret ptr %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p4,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_112(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %returned = call ptr @self_tail_body_112(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_113(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p0,85
 %answer = musttail call fastcc ptr @self_tail_body_113(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i64 %p4,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right_answer = musttail call fastcc ptr @self_tail_body_113(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,ptr %out)
 ret ptr %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r4,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p4,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_113(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %returned = call fastcc ptr @self_tail_body_113(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_114(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p0,136
 %answer = musttail call ptr @self_tail_body_114(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i64 %p7,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right_answer = musttail call ptr @self_tail_body_114(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,ptr %out)
 ret ptr %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p7,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_114(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %returned = call ptr @self_tail_body_114(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_115(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p0,136
 %answer = musttail call fastcc ptr @self_tail_body_115(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i64 %p7,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right_answer = musttail call fastcc ptr @self_tail_body_115(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,ptr %out)
 ret ptr %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r7,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p7,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_115(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %returned = call fastcc ptr @self_tail_body_115(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_116(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,i64 %p8,i64 %p9,i64 %p10,i64 %p11,i64 %p12,i64 %p13,i64 %p14,i64 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p8,136
 %left8 = add i64 %p9,153
 %left9 = add i64 %p10,170
 %left10 = add i64 %p11,187
 %left11 = add i64 %p12,204
 %left12 = add i64 %p13,221
 %left13 = add i64 %p14,238
 %left14 = add i64 %p15,255
 %left15 = add i64 %p0,272
 %answer = musttail call ptr @self_tail_body_116(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,i64 %left8,i64 %left9,i64 %left10,i64 %left11,i64 %left12,i64 %left13,i64 %left14,i64 %left15,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i64 %p15,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right8 = xor i64 %p7,279
 %right9 = xor i64 %p8,310
 %right10 = xor i64 %p9,341
 %right11 = xor i64 %p10,372
 %right12 = xor i64 %p11,403
 %right13 = xor i64 %p12,434
 %right14 = xor i64 %p13,465
 %right15 = xor i64 %p14,496
 %right_answer = musttail call ptr @self_tail_body_116(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,i64 %right8,i64 %right9,i64 %right10,i64 %right11,i64 %right12,i64 %right13,i64 %right14,i64 %right15,ptr %out)
 ret ptr %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%p8
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%p9
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%p10
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%p11
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%p12
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%p13
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%p14
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%p15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p15,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_116(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %returned = call ptr @self_tail_body_116(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,i64 %raw8,i64 %raw9,i64 %raw10,i64 %raw11,i64 %raw12,i64 %raw13,i64 %raw14,i64 %raw15,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_117(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,i64 %p8,i64 %p9,i64 %p10,i64 %p11,i64 %p12,i64 %p13,i64 %p14,i64 %p15,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p8,136
 %left8 = add i64 %p9,153
 %left9 = add i64 %p10,170
 %left10 = add i64 %p11,187
 %left11 = add i64 %p12,204
 %left12 = add i64 %p13,221
 %left13 = add i64 %p14,238
 %left14 = add i64 %p15,255
 %left15 = add i64 %p0,272
 %answer = musttail call fastcc ptr @self_tail_body_117(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,i64 %left8,i64 %left9,i64 %left10,i64 %left11,i64 %left12,i64 %left13,i64 %left14,i64 %left15,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i64 %p15,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right8 = xor i64 %p7,279
 %right9 = xor i64 %p8,310
 %right10 = xor i64 %p9,341
 %right11 = xor i64 %p10,372
 %right12 = xor i64 %p11,403
 %right13 = xor i64 %p12,434
 %right14 = xor i64 %p13,465
 %right15 = xor i64 %p14,496
 %right_answer = musttail call fastcc ptr @self_tail_body_117(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,i64 %right8,i64 %right9,i64 %right10,i64 %right11,i64 %right12,i64 %right13,i64 %right14,i64 %right15,ptr %out)
 ret ptr %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%p8
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%p9
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%p10
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%p11
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%p12
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%p13
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%p14
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%p15
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r15,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p15,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_117(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %returned = call fastcc ptr @self_tail_body_117(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,i64 %raw8,i64 %raw9,i64 %raw10,i64 %raw11,i64 %raw12,i64 %raw13,i64 %raw14,i64 %raw15,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal ptr @self_tail_body_118(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,i64 %p8,i64 %p9,i64 %p10,i64 %p11,i64 %p12,i64 %p13,i64 %p14,i64 %p15,i64 %p16,i64 %p17,i64 %p18,i64 %p19,i64 %p20,i64 %p21,i64 %p22,i64 %p23,i64 %p24,i64 %p25,i64 %p26,i64 %p27,i64 %p28,i64 %p29,i64 %p30,i64 %p31,i64 %p32,i64 %p33,i64 %p34,i64 %p35,i64 %p36,i64 %p37,i64 %p38,i64 %p39,i64 %p40,i64 %p41,i64 %p42,i64 %p43,i64 %p44,i64 %p45,i64 %p46,i64 %p47,i64 %p48,i64 %p49,i64 %p50,i64 %p51,i64 %p52,i64 %p53,i64 %p54,i64 %p55,i64 %p56,i64 %p57,i64 %p58,i64 %p59,i64 %p60,i64 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p8,136
 %left8 = add i64 %p9,153
 %left9 = add i64 %p10,170
 %left10 = add i64 %p11,187
 %left11 = add i64 %p12,204
 %left12 = add i64 %p13,221
 %left13 = add i64 %p14,238
 %left14 = add i64 %p15,255
 %left15 = add i64 %p16,272
 %left16 = add i64 %p17,289
 %left17 = add i64 %p18,306
 %left18 = add i64 %p19,323
 %left19 = add i64 %p20,340
 %left20 = add i64 %p21,357
 %left21 = add i64 %p22,374
 %left22 = add i64 %p23,391
 %left23 = add i64 %p24,408
 %left24 = add i64 %p25,425
 %left25 = add i64 %p26,442
 %left26 = add i64 %p27,459
 %left27 = add i64 %p28,476
 %left28 = add i64 %p29,493
 %left29 = add i64 %p30,510
 %left30 = add i64 %p31,527
 %left31 = add i64 %p32,544
 %left32 = add i64 %p33,561
 %left33 = add i64 %p34,578
 %left34 = add i64 %p35,595
 %left35 = add i64 %p36,612
 %left36 = add i64 %p37,629
 %left37 = add i64 %p38,646
 %left38 = add i64 %p39,663
 %left39 = add i64 %p40,680
 %left40 = add i64 %p41,697
 %left41 = add i64 %p42,714
 %left42 = add i64 %p43,731
 %left43 = add i64 %p44,748
 %left44 = add i64 %p45,765
 %left45 = add i64 %p46,782
 %left46 = add i64 %p47,799
 %left47 = add i64 %p48,816
 %left48 = add i64 %p49,833
 %left49 = add i64 %p50,850
 %left50 = add i64 %p51,867
 %left51 = add i64 %p52,884
 %left52 = add i64 %p53,901
 %left53 = add i64 %p54,918
 %left54 = add i64 %p55,935
 %left55 = add i64 %p56,952
 %left56 = add i64 %p57,969
 %left57 = add i64 %p58,986
 %left58 = add i64 %p59,1003
 %left59 = add i64 %p60,1020
 %left60 = add i64 %p61,1037
 %left61 = add i64 %p0,1054
 %answer = musttail call ptr @self_tail_body_118(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,i64 %left8,i64 %left9,i64 %left10,i64 %left11,i64 %left12,i64 %left13,i64 %left14,i64 %left15,i64 %left16,i64 %left17,i64 %left18,i64 %left19,i64 %left20,i64 %left21,i64 %left22,i64 %left23,i64 %left24,i64 %left25,i64 %left26,i64 %left27,i64 %left28,i64 %left29,i64 %left30,i64 %left31,i64 %left32,i64 %left33,i64 %left34,i64 %left35,i64 %left36,i64 %left37,i64 %left38,i64 %left39,i64 %left40,i64 %left41,i64 %left42,i64 %left43,i64 %left44,i64 %left45,i64 %left46,i64 %left47,i64 %left48,i64 %left49,i64 %left50,i64 %left51,i64 %left52,i64 %left53,i64 %left54,i64 %left55,i64 %left56,i64 %left57,i64 %left58,i64 %left59,i64 %left60,i64 %left61,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i64 %p61,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right8 = xor i64 %p7,279
 %right9 = xor i64 %p8,310
 %right10 = xor i64 %p9,341
 %right11 = xor i64 %p10,372
 %right12 = xor i64 %p11,403
 %right13 = xor i64 %p12,434
 %right14 = xor i64 %p13,465
 %right15 = xor i64 %p14,496
 %right16 = xor i64 %p15,527
 %right17 = xor i64 %p16,558
 %right18 = xor i64 %p17,589
 %right19 = xor i64 %p18,620
 %right20 = xor i64 %p19,651
 %right21 = xor i64 %p20,682
 %right22 = xor i64 %p21,713
 %right23 = xor i64 %p22,744
 %right24 = xor i64 %p23,775
 %right25 = xor i64 %p24,806
 %right26 = xor i64 %p25,837
 %right27 = xor i64 %p26,868
 %right28 = xor i64 %p27,899
 %right29 = xor i64 %p28,930
 %right30 = xor i64 %p29,961
 %right31 = xor i64 %p30,992
 %right32 = xor i64 %p31,1023
 %right33 = xor i64 %p32,1054
 %right34 = xor i64 %p33,1085
 %right35 = xor i64 %p34,1116
 %right36 = xor i64 %p35,1147
 %right37 = xor i64 %p36,1178
 %right38 = xor i64 %p37,1209
 %right39 = xor i64 %p38,1240
 %right40 = xor i64 %p39,1271
 %right41 = xor i64 %p40,1302
 %right42 = xor i64 %p41,1333
 %right43 = xor i64 %p42,1364
 %right44 = xor i64 %p43,1395
 %right45 = xor i64 %p44,1426
 %right46 = xor i64 %p45,1457
 %right47 = xor i64 %p46,1488
 %right48 = xor i64 %p47,1519
 %right49 = xor i64 %p48,1550
 %right50 = xor i64 %p49,1581
 %right51 = xor i64 %p50,1612
 %right52 = xor i64 %p51,1643
 %right53 = xor i64 %p52,1674
 %right54 = xor i64 %p53,1705
 %right55 = xor i64 %p54,1736
 %right56 = xor i64 %p55,1767
 %right57 = xor i64 %p56,1798
 %right58 = xor i64 %p57,1829
 %right59 = xor i64 %p58,1860
 %right60 = xor i64 %p59,1891
 %right61 = xor i64 %p60,1922
 %right_answer = musttail call ptr @self_tail_body_118(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,i64 %right8,i64 %right9,i64 %right10,i64 %right11,i64 %right12,i64 %right13,i64 %right14,i64 %right15,i64 %right16,i64 %right17,i64 %right18,i64 %right19,i64 %right20,i64 %right21,i64 %right22,i64 %right23,i64 %right24,i64 %right25,i64 %right26,i64 %right27,i64 %right28,i64 %right29,i64 %right30,i64 %right31,i64 %right32,i64 %right33,i64 %right34,i64 %right35,i64 %right36,i64 %right37,i64 %right38,i64 %right39,i64 %right40,i64 %right41,i64 %right42,i64 %right43,i64 %right44,i64 %right45,i64 %right46,i64 %right47,i64 %right48,i64 %right49,i64 %right50,i64 %right51,i64 %right52,i64 %right53,i64 %right54,i64 %right55,i64 %right56,i64 %right57,i64 %right58,i64 %right59,i64 %right60,i64 %right61,ptr %out)
 ret ptr %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%p8
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%p9
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%p10
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%p11
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%p12
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%p13
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%p14
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%p15
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%p16
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%p17
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%p18
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%p19
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%p20
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%p21
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%p22
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%p23
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%p24
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%p25
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%p26
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%p27
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%p28
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%p29
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%p30
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%p31
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%p32
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%p33
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%p34
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%p35
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%p36
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%p37
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%p38
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%p39
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%p40
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%p41
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%p42
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%p43
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%p44
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%p45
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%p46
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%p47
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%p48
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%p49
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%p50
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%p51
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%p52
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%p53
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%p54
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%p55
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%p56
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%p57
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%p58
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%p59
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%p60
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%p61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p61,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_118(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %returned = call ptr @self_tail_body_118(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,i64 %raw8,i64 %raw9,i64 %raw10,i64 %raw11,i64 %raw12,i64 %raw13,i64 %raw14,i64 %raw15,i64 %raw16,i64 %raw17,i64 %raw18,i64 %raw19,i64 %raw20,i64 %raw21,i64 %raw22,i64 %raw23,i64 %raw24,i64 %raw25,i64 %raw26,i64 %raw27,i64 %raw28,i64 %raw29,i64 %raw30,i64 %raw31,i64 %raw32,i64 %raw33,i64 %raw34,i64 %raw35,i64 %raw36,i64 %raw37,i64 %raw38,i64 %raw39,i64 %raw40,i64 %raw41,i64 %raw42,i64 %raw43,i64 %raw44,i64 %raw45,i64 %raw46,i64 %raw47,i64 %raw48,i64 %raw49,i64 %raw50,i64 %raw51,i64 %raw52,i64 %raw53,i64 %raw54,i64 %raw55,i64 %raw56,i64 %raw57,i64 %raw58,i64 %raw59,i64 %raw60,i64 %raw61,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
define internal fastcc ptr @self_tail_body_119(i64 %n,i64 %p0,i64 %p1,i64 %p2,i64 %p3,i64 %p4,i64 %p5,i64 %p6,i64 %p7,i64 %p8,i64 %p9,i64 %p10,i64 %p11,i64 %p12,i64 %p13,i64 %p14,i64 %p15,i64 %p16,i64 %p17,i64 %p18,i64 %p19,i64 %p20,i64 %p21,i64 %p22,i64 %p23,i64 %p24,i64 %p25,i64 %p26,i64 %p27,i64 %p28,i64 %p29,i64 %p30,i64 %p31,i64 %p32,i64 %p33,i64 %p34,i64 %p35,i64 %p36,i64 %p37,i64 %p38,i64 %p39,i64 %p40,i64 %p41,i64 %p42,i64 %p43,i64 %p44,i64 %p45,i64 %p46,i64 %p47,i64 %p48,i64 %p49,i64 %p50,i64 %p51,i64 %p52,i64 %p53,i64 %p54,i64 %p55,i64 %p56,i64 %p57,i64 %p58,i64 %p59,i64 %p60,i64 %p61,ptr %out) noinline {
entry:
 %done = icmp eq i64 %n,0
 br i1 %done,label %exit,label %step
step:
 %next = sub i64 %n,1
 %odd = and i64 %n,1
 %choice = icmp ne i64 %odd,0
 br i1 %choice,label %left,label %right
left:
 %left0 = add i64 %p1,17
 %left1 = add i64 %p2,34
 %left2 = add i64 %p3,51
 %left3 = add i64 %p4,68
 %left4 = add i64 %p5,85
 %left5 = add i64 %p6,102
 %left6 = add i64 %p7,119
 %left7 = add i64 %p8,136
 %left8 = add i64 %p9,153
 %left9 = add i64 %p10,170
 %left10 = add i64 %p11,187
 %left11 = add i64 %p12,204
 %left12 = add i64 %p13,221
 %left13 = add i64 %p14,238
 %left14 = add i64 %p15,255
 %left15 = add i64 %p16,272
 %left16 = add i64 %p17,289
 %left17 = add i64 %p18,306
 %left18 = add i64 %p19,323
 %left19 = add i64 %p20,340
 %left20 = add i64 %p21,357
 %left21 = add i64 %p22,374
 %left22 = add i64 %p23,391
 %left23 = add i64 %p24,408
 %left24 = add i64 %p25,425
 %left25 = add i64 %p26,442
 %left26 = add i64 %p27,459
 %left27 = add i64 %p28,476
 %left28 = add i64 %p29,493
 %left29 = add i64 %p30,510
 %left30 = add i64 %p31,527
 %left31 = add i64 %p32,544
 %left32 = add i64 %p33,561
 %left33 = add i64 %p34,578
 %left34 = add i64 %p35,595
 %left35 = add i64 %p36,612
 %left36 = add i64 %p37,629
 %left37 = add i64 %p38,646
 %left38 = add i64 %p39,663
 %left39 = add i64 %p40,680
 %left40 = add i64 %p41,697
 %left41 = add i64 %p42,714
 %left42 = add i64 %p43,731
 %left43 = add i64 %p44,748
 %left44 = add i64 %p45,765
 %left45 = add i64 %p46,782
 %left46 = add i64 %p47,799
 %left47 = add i64 %p48,816
 %left48 = add i64 %p49,833
 %left49 = add i64 %p50,850
 %left50 = add i64 %p51,867
 %left51 = add i64 %p52,884
 %left52 = add i64 %p53,901
 %left53 = add i64 %p54,918
 %left54 = add i64 %p55,935
 %left55 = add i64 %p56,952
 %left56 = add i64 %p57,969
 %left57 = add i64 %p58,986
 %left58 = add i64 %p59,1003
 %left59 = add i64 %p60,1020
 %left60 = add i64 %p61,1037
 %left61 = add i64 %p0,1054
 %answer = musttail call fastcc ptr @self_tail_body_119(i64 %next,i64 %left0,i64 %left1,i64 %left2,i64 %left3,i64 %left4,i64 %left5,i64 %left6,i64 %left7,i64 %left8,i64 %left9,i64 %left10,i64 %left11,i64 %left12,i64 %left13,i64 %left14,i64 %left15,i64 %left16,i64 %left17,i64 %left18,i64 %left19,i64 %left20,i64 %left21,i64 %left22,i64 %left23,i64 %left24,i64 %left25,i64 %left26,i64 %left27,i64 %left28,i64 %left29,i64 %left30,i64 %left31,i64 %left32,i64 %left33,i64 %left34,i64 %left35,i64 %left36,i64 %left37,i64 %left38,i64 %left39,i64 %left40,i64 %left41,i64 %left42,i64 %left43,i64 %left44,i64 %left45,i64 %left46,i64 %left47,i64 %left48,i64 %left49,i64 %left50,i64 %left51,i64 %left52,i64 %left53,i64 %left54,i64 %left55,i64 %left56,i64 %left57,i64 %left58,i64 %left59,i64 %left60,i64 %left61,ptr %out)
 ret ptr %answer
right:
 %right0 = xor i64 %p61,31
 %right1 = xor i64 %p0,62
 %right2 = xor i64 %p1,93
 %right3 = xor i64 %p2,124
 %right4 = xor i64 %p3,155
 %right5 = xor i64 %p4,186
 %right6 = xor i64 %p5,217
 %right7 = xor i64 %p6,248
 %right8 = xor i64 %p7,279
 %right9 = xor i64 %p8,310
 %right10 = xor i64 %p9,341
 %right11 = xor i64 %p10,372
 %right12 = xor i64 %p11,403
 %right13 = xor i64 %p12,434
 %right14 = xor i64 %p13,465
 %right15 = xor i64 %p14,496
 %right16 = xor i64 %p15,527
 %right17 = xor i64 %p16,558
 %right18 = xor i64 %p17,589
 %right19 = xor i64 %p18,620
 %right20 = xor i64 %p19,651
 %right21 = xor i64 %p20,682
 %right22 = xor i64 %p21,713
 %right23 = xor i64 %p22,744
 %right24 = xor i64 %p23,775
 %right25 = xor i64 %p24,806
 %right26 = xor i64 %p25,837
 %right27 = xor i64 %p26,868
 %right28 = xor i64 %p27,899
 %right29 = xor i64 %p28,930
 %right30 = xor i64 %p29,961
 %right31 = xor i64 %p30,992
 %right32 = xor i64 %p31,1023
 %right33 = xor i64 %p32,1054
 %right34 = xor i64 %p33,1085
 %right35 = xor i64 %p34,1116
 %right36 = xor i64 %p35,1147
 %right37 = xor i64 %p36,1178
 %right38 = xor i64 %p37,1209
 %right39 = xor i64 %p38,1240
 %right40 = xor i64 %p39,1271
 %right41 = xor i64 %p40,1302
 %right42 = xor i64 %p41,1333
 %right43 = xor i64 %p42,1364
 %right44 = xor i64 %p43,1395
 %right45 = xor i64 %p44,1426
 %right46 = xor i64 %p45,1457
 %right47 = xor i64 %p46,1488
 %right48 = xor i64 %p47,1519
 %right49 = xor i64 %p48,1550
 %right50 = xor i64 %p49,1581
 %right51 = xor i64 %p50,1612
 %right52 = xor i64 %p51,1643
 %right53 = xor i64 %p52,1674
 %right54 = xor i64 %p53,1705
 %right55 = xor i64 %p54,1736
 %right56 = xor i64 %p55,1767
 %right57 = xor i64 %p56,1798
 %right58 = xor i64 %p57,1829
 %right59 = xor i64 %p58,1860
 %right60 = xor i64 %p59,1891
 %right61 = xor i64 %p60,1922
 %right_answer = musttail call fastcc ptr @self_tail_body_119(i64 %next,i64 %right0,i64 %right1,i64 %right2,i64 %right3,i64 %right4,i64 %right5,i64 %right6,i64 %right7,i64 %right8,i64 %right9,i64 %right10,i64 %right11,i64 %right12,i64 %right13,i64 %right14,i64 %right15,i64 %right16,i64 %right17,i64 %right18,i64 %right19,i64 %right20,i64 %right21,i64 %right22,i64 %right23,i64 %right24,i64 %right25,i64 %right26,i64 %right27,i64 %right28,i64 %right29,i64 %right30,i64 %right31,i64 %right32,i64 %right33,i64 %right34,i64 %right35,i64 %right36,i64 %right37,i64 %right38,i64 %right39,i64 %right40,i64 %right41,i64 %right42,i64 %right43,i64 %right44,i64 %right45,i64 %right46,i64 %right47,i64 %right48,i64 %right49,i64 %right50,i64 %right51,i64 %right52,i64 %right53,i64 %right54,i64 %right55,i64 %right56,i64 %right57,i64 %right58,i64 %right59,i64 %right60,i64 %right61,ptr %out)
 ret ptr %right_answer
exit:
 %m0 = mul i64 0,1099511628211
 %r0 = xor i64 %m0,%p0
 %m1 = mul i64 %r0,1099511628211
 %r1 = xor i64 %m1,%p1
 %m2 = mul i64 %r1,1099511628211
 %r2 = xor i64 %m2,%p2
 %m3 = mul i64 %r2,1099511628211
 %r3 = xor i64 %m3,%p3
 %m4 = mul i64 %r3,1099511628211
 %r4 = xor i64 %m4,%p4
 %m5 = mul i64 %r4,1099511628211
 %r5 = xor i64 %m5,%p5
 %m6 = mul i64 %r5,1099511628211
 %r6 = xor i64 %m6,%p6
 %m7 = mul i64 %r6,1099511628211
 %r7 = xor i64 %m7,%p7
 %m8 = mul i64 %r7,1099511628211
 %r8 = xor i64 %m8,%p8
 %m9 = mul i64 %r8,1099511628211
 %r9 = xor i64 %m9,%p9
 %m10 = mul i64 %r9,1099511628211
 %r10 = xor i64 %m10,%p10
 %m11 = mul i64 %r10,1099511628211
 %r11 = xor i64 %m11,%p11
 %m12 = mul i64 %r11,1099511628211
 %r12 = xor i64 %m12,%p12
 %m13 = mul i64 %r12,1099511628211
 %r13 = xor i64 %m13,%p13
 %m14 = mul i64 %r13,1099511628211
 %r14 = xor i64 %m14,%p14
 %m15 = mul i64 %r14,1099511628211
 %r15 = xor i64 %m15,%p15
 %m16 = mul i64 %r15,1099511628211
 %r16 = xor i64 %m16,%p16
 %m17 = mul i64 %r16,1099511628211
 %r17 = xor i64 %m17,%p17
 %m18 = mul i64 %r17,1099511628211
 %r18 = xor i64 %m18,%p18
 %m19 = mul i64 %r18,1099511628211
 %r19 = xor i64 %m19,%p19
 %m20 = mul i64 %r19,1099511628211
 %r20 = xor i64 %m20,%p20
 %m21 = mul i64 %r20,1099511628211
 %r21 = xor i64 %m21,%p21
 %m22 = mul i64 %r21,1099511628211
 %r22 = xor i64 %m22,%p22
 %m23 = mul i64 %r22,1099511628211
 %r23 = xor i64 %m23,%p23
 %m24 = mul i64 %r23,1099511628211
 %r24 = xor i64 %m24,%p24
 %m25 = mul i64 %r24,1099511628211
 %r25 = xor i64 %m25,%p25
 %m26 = mul i64 %r25,1099511628211
 %r26 = xor i64 %m26,%p26
 %m27 = mul i64 %r26,1099511628211
 %r27 = xor i64 %m27,%p27
 %m28 = mul i64 %r27,1099511628211
 %r28 = xor i64 %m28,%p28
 %m29 = mul i64 %r28,1099511628211
 %r29 = xor i64 %m29,%p29
 %m30 = mul i64 %r29,1099511628211
 %r30 = xor i64 %m30,%p30
 %m31 = mul i64 %r30,1099511628211
 %r31 = xor i64 %m31,%p31
 %m32 = mul i64 %r31,1099511628211
 %r32 = xor i64 %m32,%p32
 %m33 = mul i64 %r32,1099511628211
 %r33 = xor i64 %m33,%p33
 %m34 = mul i64 %r33,1099511628211
 %r34 = xor i64 %m34,%p34
 %m35 = mul i64 %r34,1099511628211
 %r35 = xor i64 %m35,%p35
 %m36 = mul i64 %r35,1099511628211
 %r36 = xor i64 %m36,%p36
 %m37 = mul i64 %r36,1099511628211
 %r37 = xor i64 %m37,%p37
 %m38 = mul i64 %r37,1099511628211
 %r38 = xor i64 %m38,%p38
 %m39 = mul i64 %r38,1099511628211
 %r39 = xor i64 %m39,%p39
 %m40 = mul i64 %r39,1099511628211
 %r40 = xor i64 %m40,%p40
 %m41 = mul i64 %r40,1099511628211
 %r41 = xor i64 %m41,%p41
 %m42 = mul i64 %r41,1099511628211
 %r42 = xor i64 %m42,%p42
 %m43 = mul i64 %r42,1099511628211
 %r43 = xor i64 %m43,%p43
 %m44 = mul i64 %r43,1099511628211
 %r44 = xor i64 %m44,%p44
 %m45 = mul i64 %r44,1099511628211
 %r45 = xor i64 %m45,%p45
 %m46 = mul i64 %r45,1099511628211
 %r46 = xor i64 %m46,%p46
 %m47 = mul i64 %r46,1099511628211
 %r47 = xor i64 %m47,%p47
 %m48 = mul i64 %r47,1099511628211
 %r48 = xor i64 %m48,%p48
 %m49 = mul i64 %r48,1099511628211
 %r49 = xor i64 %m49,%p49
 %m50 = mul i64 %r49,1099511628211
 %r50 = xor i64 %m50,%p50
 %m51 = mul i64 %r50,1099511628211
 %r51 = xor i64 %m51,%p51
 %m52 = mul i64 %r51,1099511628211
 %r52 = xor i64 %m52,%p52
 %m53 = mul i64 %r52,1099511628211
 %r53 = xor i64 %m53,%p53
 %m54 = mul i64 %r53,1099511628211
 %r54 = xor i64 %m54,%p54
 %m55 = mul i64 %r54,1099511628211
 %r55 = xor i64 %m55,%p55
 %m56 = mul i64 %r55,1099511628211
 %r56 = xor i64 %m56,%p56
 %m57 = mul i64 %r56,1099511628211
 %r57 = xor i64 %m57,%p57
 %m58 = mul i64 %r57,1099511628211
 %r58 = xor i64 %m58,%p58
 %m59 = mul i64 %r58,1099511628211
 %r59 = xor i64 %m59,%p59
 %m60 = mul i64 %r59,1099511628211
 %r60 = xor i64 %m60,%p60
 %m61 = mul i64 %r60,1099511628211
 %r61 = xor i64 %m61,%p61
 %o0 = getelementptr i8,ptr %out,i64 0
 store i64 %r61,ptr %o0,align 1
 %o1 = getelementptr i8,ptr %out,i64 8
 store i64 %p0,ptr %o1,align 1
 %o2 = getelementptr i8,ptr %out,i64 16
 store i64 %p61,ptr %o2,align 1
 ret ptr %out
}
define i64 @self_tail_probe_119(ptr %input,ptr %out,i64 %count) {
entry:
 %a0 = getelementptr i8,ptr %input,i64 0
 %raw0 = load i64,ptr %a0,align 1
 %a1 = getelementptr i8,ptr %input,i64 8
 %raw1 = load i64,ptr %a1,align 1
 %a2 = getelementptr i8,ptr %input,i64 16
 %raw2 = load i64,ptr %a2,align 1
 %a3 = getelementptr i8,ptr %input,i64 24
 %raw3 = load i64,ptr %a3,align 1
 %a4 = getelementptr i8,ptr %input,i64 32
 %raw4 = load i64,ptr %a4,align 1
 %a5 = getelementptr i8,ptr %input,i64 40
 %raw5 = load i64,ptr %a5,align 1
 %a6 = getelementptr i8,ptr %input,i64 48
 %raw6 = load i64,ptr %a6,align 1
 %a7 = getelementptr i8,ptr %input,i64 56
 %raw7 = load i64,ptr %a7,align 1
 %a8 = getelementptr i8,ptr %input,i64 64
 %raw8 = load i64,ptr %a8,align 1
 %a9 = getelementptr i8,ptr %input,i64 72
 %raw9 = load i64,ptr %a9,align 1
 %a10 = getelementptr i8,ptr %input,i64 80
 %raw10 = load i64,ptr %a10,align 1
 %a11 = getelementptr i8,ptr %input,i64 88
 %raw11 = load i64,ptr %a11,align 1
 %a12 = getelementptr i8,ptr %input,i64 96
 %raw12 = load i64,ptr %a12,align 1
 %a13 = getelementptr i8,ptr %input,i64 104
 %raw13 = load i64,ptr %a13,align 1
 %a14 = getelementptr i8,ptr %input,i64 112
 %raw14 = load i64,ptr %a14,align 1
 %a15 = getelementptr i8,ptr %input,i64 120
 %raw15 = load i64,ptr %a15,align 1
 %a16 = getelementptr i8,ptr %input,i64 128
 %raw16 = load i64,ptr %a16,align 1
 %a17 = getelementptr i8,ptr %input,i64 136
 %raw17 = load i64,ptr %a17,align 1
 %a18 = getelementptr i8,ptr %input,i64 144
 %raw18 = load i64,ptr %a18,align 1
 %a19 = getelementptr i8,ptr %input,i64 152
 %raw19 = load i64,ptr %a19,align 1
 %a20 = getelementptr i8,ptr %input,i64 160
 %raw20 = load i64,ptr %a20,align 1
 %a21 = getelementptr i8,ptr %input,i64 168
 %raw21 = load i64,ptr %a21,align 1
 %a22 = getelementptr i8,ptr %input,i64 176
 %raw22 = load i64,ptr %a22,align 1
 %a23 = getelementptr i8,ptr %input,i64 184
 %raw23 = load i64,ptr %a23,align 1
 %a24 = getelementptr i8,ptr %input,i64 192
 %raw24 = load i64,ptr %a24,align 1
 %a25 = getelementptr i8,ptr %input,i64 200
 %raw25 = load i64,ptr %a25,align 1
 %a26 = getelementptr i8,ptr %input,i64 208
 %raw26 = load i64,ptr %a26,align 1
 %a27 = getelementptr i8,ptr %input,i64 216
 %raw27 = load i64,ptr %a27,align 1
 %a28 = getelementptr i8,ptr %input,i64 224
 %raw28 = load i64,ptr %a28,align 1
 %a29 = getelementptr i8,ptr %input,i64 232
 %raw29 = load i64,ptr %a29,align 1
 %a30 = getelementptr i8,ptr %input,i64 240
 %raw30 = load i64,ptr %a30,align 1
 %a31 = getelementptr i8,ptr %input,i64 248
 %raw31 = load i64,ptr %a31,align 1
 %a32 = getelementptr i8,ptr %input,i64 256
 %raw32 = load i64,ptr %a32,align 1
 %a33 = getelementptr i8,ptr %input,i64 264
 %raw33 = load i64,ptr %a33,align 1
 %a34 = getelementptr i8,ptr %input,i64 272
 %raw34 = load i64,ptr %a34,align 1
 %a35 = getelementptr i8,ptr %input,i64 280
 %raw35 = load i64,ptr %a35,align 1
 %a36 = getelementptr i8,ptr %input,i64 288
 %raw36 = load i64,ptr %a36,align 1
 %a37 = getelementptr i8,ptr %input,i64 296
 %raw37 = load i64,ptr %a37,align 1
 %a38 = getelementptr i8,ptr %input,i64 304
 %raw38 = load i64,ptr %a38,align 1
 %a39 = getelementptr i8,ptr %input,i64 312
 %raw39 = load i64,ptr %a39,align 1
 %a40 = getelementptr i8,ptr %input,i64 320
 %raw40 = load i64,ptr %a40,align 1
 %a41 = getelementptr i8,ptr %input,i64 328
 %raw41 = load i64,ptr %a41,align 1
 %a42 = getelementptr i8,ptr %input,i64 336
 %raw42 = load i64,ptr %a42,align 1
 %a43 = getelementptr i8,ptr %input,i64 344
 %raw43 = load i64,ptr %a43,align 1
 %a44 = getelementptr i8,ptr %input,i64 352
 %raw44 = load i64,ptr %a44,align 1
 %a45 = getelementptr i8,ptr %input,i64 360
 %raw45 = load i64,ptr %a45,align 1
 %a46 = getelementptr i8,ptr %input,i64 368
 %raw46 = load i64,ptr %a46,align 1
 %a47 = getelementptr i8,ptr %input,i64 376
 %raw47 = load i64,ptr %a47,align 1
 %a48 = getelementptr i8,ptr %input,i64 384
 %raw48 = load i64,ptr %a48,align 1
 %a49 = getelementptr i8,ptr %input,i64 392
 %raw49 = load i64,ptr %a49,align 1
 %a50 = getelementptr i8,ptr %input,i64 400
 %raw50 = load i64,ptr %a50,align 1
 %a51 = getelementptr i8,ptr %input,i64 408
 %raw51 = load i64,ptr %a51,align 1
 %a52 = getelementptr i8,ptr %input,i64 416
 %raw52 = load i64,ptr %a52,align 1
 %a53 = getelementptr i8,ptr %input,i64 424
 %raw53 = load i64,ptr %a53,align 1
 %a54 = getelementptr i8,ptr %input,i64 432
 %raw54 = load i64,ptr %a54,align 1
 %a55 = getelementptr i8,ptr %input,i64 440
 %raw55 = load i64,ptr %a55,align 1
 %a56 = getelementptr i8,ptr %input,i64 448
 %raw56 = load i64,ptr %a56,align 1
 %a57 = getelementptr i8,ptr %input,i64 456
 %raw57 = load i64,ptr %a57,align 1
 %a58 = getelementptr i8,ptr %input,i64 464
 %raw58 = load i64,ptr %a58,align 1
 %a59 = getelementptr i8,ptr %input,i64 472
 %raw59 = load i64,ptr %a59,align 1
 %a60 = getelementptr i8,ptr %input,i64 480
 %raw60 = load i64,ptr %a60,align 1
 %a61 = getelementptr i8,ptr %input,i64 488
 %raw61 = load i64,ptr %a61,align 1
 %returned = call fastcc ptr @self_tail_body_119(i64 %count,i64 %raw0,i64 %raw1,i64 %raw2,i64 %raw3,i64 %raw4,i64 %raw5,i64 %raw6,i64 %raw7,i64 %raw8,i64 %raw9,i64 %raw10,i64 %raw11,i64 %raw12,i64 %raw13,i64 %raw14,i64 %raw15,i64 %raw16,i64 %raw17,i64 %raw18,i64 %raw19,i64 %raw20,i64 %raw21,i64 %raw22,i64 %raw23,i64 %raw24,i64 %raw25,i64 %raw26,i64 %raw27,i64 %raw28,i64 %raw29,i64 %raw30,i64 %raw31,i64 %raw32,i64 %raw33,i64 %raw34,i64 %raw35,i64 %raw36,i64 %raw37,i64 %raw38,i64 %raw39,i64 %raw40,i64 %raw41,i64 %raw42,i64 %raw43,i64 %raw44,i64 %raw45,i64 %raw46,i64 %raw47,i64 %raw48,i64 %raw49,i64 %raw50,i64 %raw51,i64 %raw52,i64 %raw53,i64 %raw54,i64 %raw55,i64 %raw56,i64 %raw57,i64 %raw58,i64 %raw59,i64 %raw60,i64 %raw61,ptr %out)
 %result = ptrtoint ptr %returned to i64
 ret i64 %result
}
