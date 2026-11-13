target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define i64 @literal_branches_body_0(i64 %a,i64 %b,i64 %live) noinline {
entry:
 br i1 false,label %yes,label %no
yes:
 %x = xor i64 %a,%live
 br label %join
no:
 %y = add i64 %b,%live
 br label %join
join:
 %r = phi i64 [%x,%yes],[%y,%no]
 ret i64 %r
}
define i64 @literal_branches_probe_0(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call i64 @literal_branches_body_0(i64 %a0,i64 %a1,i64 %a2)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @literal_branches_body_1(i64 %a,i64 %b,i64 %live) noinline {
entry:
 br i1 false,label %yes,label %no
yes:
 %x = xor i64 %a,%live
 br label %join
no:
 %y = add i64 %b,%live
 br label %join
join:
 %r = phi i64 [%x,%yes],[%y,%no]
 ret i64 %r
}
define i64 @literal_branches_probe_1(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call fastcc i64 @literal_branches_body_1(i64 %a0,i64 %a1,i64 %a2)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @literal_branches_body_2(i64 %a,i64 %b,i64 %live) noinline {
entry:
 br i1 true,label %yes,label %no
yes:
 %x = xor i64 %a,%live
 br label %join
no:
 %y = add i64 %b,%live
 br label %join
join:
 %r = phi i64 [%x,%yes],[%y,%no]
 ret i64 %r
}
define i64 @literal_branches_probe_2(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call i64 @literal_branches_body_2(i64 %a0,i64 %a1,i64 %a2)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @literal_branches_body_3(i64 %a,i64 %b,i64 %live) noinline {
entry:
 br i1 true,label %yes,label %no
yes:
 %x = xor i64 %a,%live
 br label %join
no:
 %y = add i64 %b,%live
 br label %join
join:
 %r = phi i64 [%x,%yes],[%y,%no]
 ret i64 %r
}
define i64 @literal_branches_probe_3(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call fastcc i64 @literal_branches_body_3(i64 %a0,i64 %a1,i64 %a2)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @literal_branches_body_4(i64 %a,i64 %b,i64 %live) noinline {
entry:
 br i1 -1,label %yes,label %no
yes:
 %x = xor i64 %a,%live
 br label %join
no:
 %y = add i64 %b,%live
 br label %join
join:
 %r = phi i64 [%x,%yes],[%y,%no]
 ret i64 %r
}
define i64 @literal_branches_probe_4(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call i64 @literal_branches_body_4(i64 %a0,i64 %a1,i64 %a2)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @literal_branches_body_5(i64 %a,i64 %b,i64 %live) noinline {
entry:
 br i1 -1,label %yes,label %no
yes:
 %x = xor i64 %a,%live
 br label %join
no:
 %y = add i64 %b,%live
 br label %join
join:
 %r = phi i64 [%x,%yes],[%y,%no]
 ret i64 %r
}
define i64 @literal_branches_probe_5(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call fastcc i64 @literal_branches_body_5(i64 %a0,i64 %a1,i64 %a2)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @literal_branches_body_6(i64 %a,i64 %b,i64 %live) noinline {
entry:
 br label %loop
loop:
 %i = phi i32 [0,%entry],[%next,%join]
 %sum = phi i64 [0,%entry],[%added,%join]
 br i1 false,label %yes,label %no
yes:
 br label %join
no:
 br label %join
join:
 %increment = phi i64 [%a,%yes],[%b,%no]
 %added = add i64 %sum,%increment
 %next = add i32 %i,1
 %more = icmp ult i32 %next,32
 br i1 %more,label %loop,label %end
end:
 %r = xor i64 %added,%live
 ret i64 %r
}
define i64 @literal_branches_probe_6(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call i64 @literal_branches_body_6(i64 %a0,i64 %a1,i64 %a2)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @literal_branches_body_7(i64 %a,i64 %b,i64 %live) noinline {
entry:
 br label %loop
loop:
 %i = phi i32 [0,%entry],[%next,%join]
 %sum = phi i64 [0,%entry],[%added,%join]
 br i1 false,label %yes,label %no
yes:
 br label %join
no:
 br label %join
join:
 %increment = phi i64 [%a,%yes],[%b,%no]
 %added = add i64 %sum,%increment
 %next = add i32 %i,1
 %more = icmp ult i32 %next,32
 br i1 %more,label %loop,label %end
end:
 %r = xor i64 %added,%live
 ret i64 %r
}
define i64 @literal_branches_probe_7(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call fastcc i64 @literal_branches_body_7(i64 %a0,i64 %a1,i64 %a2)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @literal_branches_body_8(i64 %a,i64 %b,i64 %live) noinline {
entry:
 br label %loop
loop:
 %i = phi i32 [0,%entry],[%next,%join]
 %sum = phi i64 [0,%entry],[%added,%join]
 br i1 true,label %yes,label %no
yes:
 br label %join
no:
 br label %join
join:
 %increment = phi i64 [%a,%yes],[%b,%no]
 %added = add i64 %sum,%increment
 %next = add i32 %i,1
 %more = icmp ult i32 %next,32
 br i1 %more,label %loop,label %end
end:
 %r = xor i64 %added,%live
 ret i64 %r
}
define i64 @literal_branches_probe_8(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call i64 @literal_branches_body_8(i64 %a0,i64 %a1,i64 %a2)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @literal_branches_body_9(i64 %a,i64 %b,i64 %live) noinline {
entry:
 br label %loop
loop:
 %i = phi i32 [0,%entry],[%next,%join]
 %sum = phi i64 [0,%entry],[%added,%join]
 br i1 true,label %yes,label %no
yes:
 br label %join
no:
 br label %join
join:
 %increment = phi i64 [%a,%yes],[%b,%no]
 %added = add i64 %sum,%increment
 %next = add i32 %i,1
 %more = icmp ult i32 %next,32
 br i1 %more,label %loop,label %end
end:
 %r = xor i64 %added,%live
 ret i64 %r
}
define i64 @literal_branches_probe_9(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call fastcc i64 @literal_branches_body_9(i64 %a0,i64 %a1,i64 %a2)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define i64 @literal_branches_body_10(i64 %a,i64 %b,i64 %live) noinline {
entry:
 br label %loop
loop:
 %i = phi i32 [0,%entry],[%next,%join]
 %sum = phi i64 [0,%entry],[%added,%join]
 br i1 -1,label %yes,label %no
yes:
 br label %join
no:
 br label %join
join:
 %increment = phi i64 [%a,%yes],[%b,%no]
 %added = add i64 %sum,%increment
 %next = add i32 %i,1
 %more = icmp ult i32 %next,32
 br i1 %more,label %loop,label %end
end:
 %r = xor i64 %added,%live
 ret i64 %r
}
define i64 @literal_branches_probe_10(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call i64 @literal_branches_body_10(i64 %a0,i64 %a1,i64 %a2)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
define fastcc i64 @literal_branches_body_11(i64 %a,i64 %b,i64 %live) noinline {
entry:
 br label %loop
loop:
 %i = phi i32 [0,%entry],[%next,%join]
 %sum = phi i64 [0,%entry],[%added,%join]
 br i1 -1,label %yes,label %no
yes:
 br label %join
no:
 br label %join
join:
 %increment = phi i64 [%a,%yes],[%b,%no]
 %added = add i64 %sum,%increment
 %next = add i32 %i,1
 %more = icmp ult i32 %next,32
 br i1 %more,label %loop,label %end
end:
 %r = xor i64 %added,%live
 ret i64 %r
}
define i64 @literal_branches_probe_11(ptr %input,ptr %out,i64 %salt) {
entry:
 %p0 = getelementptr i8,ptr %input,i64 0
 %a0 = load i64,ptr %p0,align 1
 %p1 = getelementptr i8,ptr %input,i64 8
 %a1 = load i64,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %input,i64 16
 %a2 = load i64,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %input,i64 24
 %a3 = load i64,ptr %p3,align 1
 %p4 = getelementptr i8,ptr %input,i64 32
 %a4 = load i64,ptr %p4,align 1
 %p5 = getelementptr i8,ptr %input,i64 40
 %a5 = load i64,ptr %p5,align 1
 %v = call fastcc i64 @literal_branches_body_11(i64 %a0,i64 %a1,i64 %a2)
 store i64 %v,ptr %out,align 1
 %next = getelementptr i8,ptr %out,i64 8
 store i64 %salt,ptr %next,align 1
 %tail = getelementptr i8,ptr %out,i64 16
 store i64 %a0,ptr %tail,align 1
 %r = xor i64 %v,%salt
 ret i64 %r
}
