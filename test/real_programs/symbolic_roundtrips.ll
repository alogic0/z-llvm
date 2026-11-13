target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
@symbolic_roundtrip_storage = global [256 x i8] zeroinitializer,align 16
declare i64 @complete_pointer_echo(ptr)
define i64 @symbolic_roundtrip_probe_0(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 1) to i64),i64 1) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 1) to i64),i64 1) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 2)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 1) to i64),i64 1) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_1(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 1) to i64),i64 1) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 3),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 2),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 3)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_2(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 1) to i64),i64 1) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 1) to i64),i64 1) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 0)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 1) to i64),i64 1) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_3(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 1) to i64),i64 1) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 1),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 0),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 1)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_4(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 4) to i64),i64 4) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 4) to i64),i64 4) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 8)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 4) to i64),i64 4) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_5(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 4) to i64),i64 4) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 9),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 8),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 9)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_6(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 4) to i64),i64 4) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 4) to i64),i64 4) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 0)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 4) to i64),i64 4) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_7(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 4) to i64),i64 4) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 1),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 0),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 1)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_8(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 8) to i64),i64 8) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 8) to i64),i64 8) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 16)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 8) to i64),i64 8) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_9(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 8) to i64),i64 8) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 17),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 16),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 17)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_10(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 8) to i64),i64 8) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 8) to i64),i64 8) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 0)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 8) to i64),i64 8) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_11(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 8) to i64),i64 8) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 1),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 0),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 1)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_12(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 16) to i64),i64 16) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 16) to i64),i64 16) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 32)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 16) to i64),i64 16) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_13(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 16) to i64),i64 16) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 33),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 32),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 33)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_14(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 16) to i64),i64 16) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 16) to i64),i64 16) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 0)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 16) to i64),i64 16) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_15(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 16) to i64),i64 16) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 1),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 0),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 1)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_16(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 32) to i64),i64 32) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 32) to i64),i64 32) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 64)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 32) to i64),i64 32) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_17(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 32) to i64),i64 32) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 65),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 64),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 65)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_18(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 32) to i64),i64 32) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 32) to i64),i64 32) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 0)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 32) to i64),i64 32) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_19(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 32) to i64),i64 32) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 1),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 0),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 1)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_20(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 64) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 64) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 128)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 64) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_21(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 64) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 129),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 128),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 129)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_22(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 64) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 64) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 0)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 64) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_23(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 64) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 1),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 0),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 1)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_24(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 1) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 1) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 65)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 1) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_25(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 1) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 66),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 65),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 66)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_26(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 1) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 1) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 63)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 1) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_27(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 1) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 64),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 63),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 64)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_28(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 7) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 7) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 71)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 7) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_29(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 7) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 72),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 71),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 72)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_30(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 7) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 7) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 57)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 7) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_31(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 7) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 58),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 57),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 58)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_32(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -1) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -1) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 63)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -1) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_33(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -1) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 64),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 63),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 64)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_34(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551615) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551615) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 63)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551615) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_35(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551615) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 64),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 63),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 64)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_36(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -1) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -1) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 65)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -1) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_37(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -1) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 66),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 65),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 66)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_38(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551615) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551615) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 65)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551615) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_39(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551615) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 66),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 65),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 66)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_40(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -17) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -17) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 47)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -17) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_41(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -17) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 48),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 47),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 48)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_42(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551599) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551599) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 47)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551599) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_43(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551599) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 48),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 47),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 48)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_44(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -17) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -17) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 81)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -17) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_45(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 -17) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 82),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 81),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 82)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_46(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551599) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551599) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 81)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551599) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_47(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 64) to i64),i64 18446744073709551599) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 82),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 81),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 82)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_48(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 32) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 32) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 160)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 32) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_49(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 32) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 161),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 160),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 161)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_50(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 32) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 32) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 96)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 32) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_51(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 32) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 97),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 96),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 97)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_52(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 64) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 64) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 192)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 64) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_53(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 add (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 64) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 193),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 192),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 193)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_54(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 store ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 64) to ptr),ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 64) to ptr),getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 64)
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 64) to ptr))
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
define i64 @symbolic_roundtrip_probe_55(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %left,label %right
left:
 br label %merge
right:
 br label %merge
merge:
 %selected = phi ptr [inttoptr (i64 sub (i64 ptrtoint (ptr getelementptr inbounds nuw (i8,ptr @symbolic_roundtrip_storage,i64 128) to i64),i64 64) to ptr),%left],[getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 65),%right]
 %expected = select i1 %condition,ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 64),ptr getelementptr inbounds (i8,ptr @symbolic_roundtrip_storage,i64 65)
 store ptr %selected,ptr %out,align 1
 %actual = load ptr,ptr %out,align 1
 %address = ptrtoint ptr %actual to i64
 %same = icmp eq ptr %selected,%expected
 %wide = zext i1 %same to i64
 %echo = call i64 @complete_pointer_echo(ptr %selected)
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 %p1 = getelementptr i8,ptr %out,i64 8
 store i64 %wide,ptr %p1,align 1
 %p2 = getelementptr i8,ptr %out,i64 16
 store i64 %echo,ptr %p2,align 1
 %p3 = getelementptr i8,ptr %out,i64 24
 store i64 %token,ptr %p3,align 1
 %answer = xor i64 %address,%token
 ret i64 %answer
}
