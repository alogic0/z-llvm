target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
@atomic_pointer_storage = global [128 x i8] zeroinitializer,align 64
declare void @complete_atomic_snapshot(ptr)
declare void @complete_atomic_touch(ptr)
define i64 @atomic_pointer_probe_0(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_1(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_2(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_3(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_4(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_5(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_6(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_7(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_8(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_9(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_10(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_11(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_12(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_13(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_14(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_15(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_16(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_17(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_18(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_19(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_20(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_21(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_22(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_23(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_24(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_25(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_26(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_27(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_28(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_29(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_30(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_31(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_32(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_33(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_34(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_35(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %desired syncscope("singlethread") seq_cst,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_36(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %expected,i8 %desired monotonic monotonic,align 1
 %old = extractvalue { i8, i1 } %pair,0
 %success = extractvalue { i8, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_37(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %expected,i8 %desired syncscope("singlethread") acq_rel acquire,align 1
 %old = extractvalue { i8, i1 } %pair,0
 %success = extractvalue { i8, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_38(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %expected,i8 %desired monotonic monotonic,align 1
 %old = extractvalue { i8, i1 } %pair,0
 %success = extractvalue { i8, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_39(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %expected,i8 %desired syncscope("singlethread") acq_rel acquire,align 1
 %old = extractvalue { i8, i1 } %pair,0
 %success = extractvalue { i8, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_40(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %expected,i8 %desired monotonic monotonic,align 1
 %old = extractvalue { i8, i1 } %pair,0
 %success = extractvalue { i8, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_41(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i8 %expected,i8 %desired syncscope("singlethread") acq_rel acquire,align 1
 %old = extractvalue { i8, i1 } %pair,0
 %success = extractvalue { i8, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_42(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %expected,i8 %desired monotonic monotonic,align 1
 %old = extractvalue { i8, i1 } %pair,0
 %success = extractvalue { i8, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_43(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i8 %expected,i8 %desired syncscope("singlethread") acq_rel acquire,align 1
 %old = extractvalue { i8, i1 } %pair,0
 %success = extractvalue { i8, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_44(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic i8,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_45(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic volatile i8,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) syncscope("singlethread") acquire,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_46(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic i8,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_47(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic volatile i8,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) syncscope("singlethread") acquire,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_48(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i8,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),align 1
 store atomic i8 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_49(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i8,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),align 1
 store atomic volatile i8 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) syncscope("singlethread") release,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_50(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i8,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),align 1
 store atomic i8 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) monotonic,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_51(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i8,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i8,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i8,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),align 1
 store atomic volatile i8 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) syncscope("singlethread") release,align 1
 %wide = zext i8 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_52(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_53(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_54(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_55(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_56(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_57(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_58(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_59(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_60(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_61(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_62(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_63(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_64(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_65(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_66(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_67(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_68(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_69(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_70(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_71(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_72(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_73(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_74(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_75(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_76(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_77(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_78(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_79(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_80(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_81(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_82(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_83(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_84(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_85(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_86(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_87(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %desired syncscope("singlethread") seq_cst,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_88(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %expected,i16 %desired monotonic monotonic,align 2
 %old = extractvalue { i16, i1 } %pair,0
 %success = extractvalue { i16, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_89(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %expected,i16 %desired syncscope("singlethread") acq_rel acquire,align 2
 %old = extractvalue { i16, i1 } %pair,0
 %success = extractvalue { i16, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_90(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %expected,i16 %desired monotonic monotonic,align 2
 %old = extractvalue { i16, i1 } %pair,0
 %success = extractvalue { i16, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_91(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %expected,i16 %desired syncscope("singlethread") acq_rel acquire,align 2
 %old = extractvalue { i16, i1 } %pair,0
 %success = extractvalue { i16, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_92(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %expected,i16 %desired monotonic monotonic,align 2
 %old = extractvalue { i16, i1 } %pair,0
 %success = extractvalue { i16, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_93(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i16 %expected,i16 %desired syncscope("singlethread") acq_rel acquire,align 2
 %old = extractvalue { i16, i1 } %pair,0
 %success = extractvalue { i16, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_94(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %expected,i16 %desired monotonic monotonic,align 2
 %old = extractvalue { i16, i1 } %pair,0
 %success = extractvalue { i16, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_95(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i16 %expected,i16 %desired syncscope("singlethread") acq_rel acquire,align 2
 %old = extractvalue { i16, i1 } %pair,0
 %success = extractvalue { i16, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_96(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic i16,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_97(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic volatile i16,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) syncscope("singlethread") acquire,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_98(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic i16,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_99(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic volatile i16,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) syncscope("singlethread") acquire,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_100(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i16,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),align 2
 store atomic i16 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_101(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i16,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),align 2
 store atomic volatile i16 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) syncscope("singlethread") release,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_102(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i16,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),align 2
 store atomic i16 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) monotonic,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_103(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i16,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i16,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i16,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),align 2
 store atomic volatile i16 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) syncscope("singlethread") release,align 2
 %wide = zext i16 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_104(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_105(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_106(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_107(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_108(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_109(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_110(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_111(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_112(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_113(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_114(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_115(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_116(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_117(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_118(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_119(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_120(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_121(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_122(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_123(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_124(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_125(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_126(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_127(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_128(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_129(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_130(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_131(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_132(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_133(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_134(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_135(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_136(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_137(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_138(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_139(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %desired syncscope("singlethread") seq_cst,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_140(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %expected,i32 %desired monotonic monotonic,align 4
 %old = extractvalue { i32, i1 } %pair,0
 %success = extractvalue { i32, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_141(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %expected,i32 %desired syncscope("singlethread") acq_rel acquire,align 4
 %old = extractvalue { i32, i1 } %pair,0
 %success = extractvalue { i32, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_142(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %expected,i32 %desired monotonic monotonic,align 4
 %old = extractvalue { i32, i1 } %pair,0
 %success = extractvalue { i32, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_143(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %expected,i32 %desired syncscope("singlethread") acq_rel acquire,align 4
 %old = extractvalue { i32, i1 } %pair,0
 %success = extractvalue { i32, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_144(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %expected,i32 %desired monotonic monotonic,align 4
 %old = extractvalue { i32, i1 } %pair,0
 %success = extractvalue { i32, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_145(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i32 %expected,i32 %desired syncscope("singlethread") acq_rel acquire,align 4
 %old = extractvalue { i32, i1 } %pair,0
 %success = extractvalue { i32, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_146(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %expected,i32 %desired monotonic monotonic,align 4
 %old = extractvalue { i32, i1 } %pair,0
 %success = extractvalue { i32, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_147(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i32 %expected,i32 %desired syncscope("singlethread") acq_rel acquire,align 4
 %old = extractvalue { i32, i1 } %pair,0
 %success = extractvalue { i32, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_148(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic i32,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_149(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic volatile i32,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) syncscope("singlethread") acquire,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_150(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic i32,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_151(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic volatile i32,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) syncscope("singlethread") acquire,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_152(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i32,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),align 4
 store atomic i32 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_153(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i32,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),align 4
 store atomic volatile i32 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) syncscope("singlethread") release,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_154(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i32,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),align 4
 store atomic i32 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) monotonic,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_155(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i32,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i32,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i32,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),align 4
 store atomic volatile i32 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) syncscope("singlethread") release,align 4
 %wide = zext i32 %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_156(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_157(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_158(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_159(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_160(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_161(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_162(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_163(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile add ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_164(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_165(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_166(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_167(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile sub ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_168(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_169(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_170(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_171(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile and ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_172(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_173(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_174(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_175(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile or ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_176(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_177(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_178(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_179(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xor ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_180(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_181(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_182(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_183(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile nand ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_184(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_185(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_186(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_187(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umin ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_188(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_189(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_190(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_191(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile umax ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %desired syncscope("singlethread") seq_cst,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_192(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %expected,i64 %desired monotonic monotonic,align 8
 %old = extractvalue { i64, i1 } %pair,0
 %success = extractvalue { i64, i1 } %pair,1
 %flag = zext i1 %success to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_193(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %expected,i64 %desired syncscope("singlethread") acq_rel acquire,align 8
 %old = extractvalue { i64, i1 } %pair,0
 %success = extractvalue { i64, i1 } %pair,1
 %flag = zext i1 %success to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_194(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %expected,i64 %desired monotonic monotonic,align 8
 %old = extractvalue { i64, i1 } %pair,0
 %success = extractvalue { i64, i1 } %pair,1
 %flag = zext i1 %success to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_195(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %expected,i64 %desired syncscope("singlethread") acq_rel acquire,align 8
 %old = extractvalue { i64, i1 } %pair,0
 %success = extractvalue { i64, i1 } %pair,1
 %flag = zext i1 %success to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_196(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %expected,i64 %desired monotonic monotonic,align 8
 %old = extractvalue { i64, i1 } %pair,0
 %success = extractvalue { i64, i1 } %pair,1
 %flag = zext i1 %success to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_197(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),i64 %expected,i64 %desired syncscope("singlethread") acq_rel acquire,align 8
 %old = extractvalue { i64, i1 } %pair,0
 %success = extractvalue { i64, i1 } %pair,1
 %flag = zext i1 %success to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_198(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %expected,i64 %desired monotonic monotonic,align 8
 %old = extractvalue { i64, i1 } %pair,0
 %success = extractvalue { i64, i1 } %pair,1
 %flag = zext i1 %success to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_199(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),i64 %expected,i64 %desired syncscope("singlethread") acq_rel acquire,align 8
 %old = extractvalue { i64, i1 } %pair,0
 %success = extractvalue { i64, i1 } %pair,1
 %flag = zext i1 %success to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_200(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic i64,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_201(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic volatile i64,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) syncscope("singlethread") acquire,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_202(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic i64,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_203(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic volatile i64,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) syncscope("singlethread") acquire,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_204(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i64,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),align 8
 store atomic i64 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_205(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i64,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),align 8
 store atomic volatile i64 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) syncscope("singlethread") release,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_206(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i64,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),align 8
 store atomic i64 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) monotonic,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_207(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load i64,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load i64,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load i64,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),align 8
 store atomic volatile i64 %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) syncscope("singlethread") release,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %old,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %old,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_208(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),ptr %desired monotonic,align 8
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_209(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),ptr %desired syncscope("singlethread") seq_cst,align 8
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_210(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),ptr %desired monotonic,align 8
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_211(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = atomicrmw volatile xchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),ptr %desired syncscope("singlethread") seq_cst,align 8
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_212(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),ptr %expected,ptr %desired monotonic monotonic,align 8
 %old = extractvalue { ptr, i1 } %pair,0
 %success = extractvalue { ptr, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_213(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),ptr %expected,ptr %desired syncscope("singlethread") acq_rel acquire,align 8
 %old = extractvalue { ptr, i1 } %pair,0
 %success = extractvalue { ptr, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_214(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),ptr %expected,ptr %desired monotonic monotonic,align 8
 %old = extractvalue { ptr, i1 } %pair,0
 %success = extractvalue { ptr, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_215(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),ptr %expected,ptr %desired syncscope("singlethread") acq_rel acquire,align 8
 %old = extractvalue { ptr, i1 } %pair,0
 %success = extractvalue { ptr, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_216(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),ptr %expected,ptr %desired monotonic monotonic,align 8
 %old = extractvalue { ptr, i1 } %pair,0
 %success = extractvalue { ptr, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_217(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),ptr %expected,ptr %desired syncscope("singlethread") acq_rel acquire,align 8
 %old = extractvalue { ptr, i1 } %pair,0
 %success = extractvalue { ptr, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_218(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),ptr %expected,ptr %desired monotonic monotonic,align 8
 %old = extractvalue { ptr, i1 } %pair,0
 %success = extractvalue { ptr, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_219(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %pair = cmpxchg volatile ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),ptr %expected,ptr %desired syncscope("singlethread") acq_rel acquire,align 8
 %old = extractvalue { ptr, i1 } %pair,0
 %success = extractvalue { ptr, i1 } %pair,1
 %flag = zext i1 %success to i64
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 %flag,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_220(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic ptr,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) monotonic,align 8
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_221(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic volatile ptr,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) syncscope("singlethread") acquire,align 8
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_222(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic ptr,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) monotonic,align 8
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_223(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load atomic volatile ptr,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) syncscope("singlethread") acquire,align 8
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_224(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load ptr,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),align 8
 store atomic ptr %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) monotonic,align 8
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_225(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load ptr,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16),align 8
 store atomic volatile ptr %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 16) syncscope("singlethread") release,align 8
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_226(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load ptr,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),align 8
 store atomic ptr %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) monotonic,align 8
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @atomic_pointer_probe_227(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %expected_ptr = getelementptr i8,ptr %source,i64 8
 %expected = load ptr,ptr %expected_ptr,align 1
 %desired_ptr = getelementptr i8,ptr %source,i64 16
 %desired = load ptr,ptr %desired_ptr,align 1
 call void @complete_atomic_touch(ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 96))
 %bit = and i64 %salt,1
 %condition = icmp ne i64 %bit,0
 br i1 %condition,label %clobber,label %atomic
clobber:
 %ignored = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 br label %atomic
atomic:
 %old = load ptr,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64),align 8
 store atomic volatile ptr %desired,ptr getelementptr inbounds (i8,ptr @atomic_pointer_storage,i64 64) syncscope("singlethread") release,align 8
 %wide = ptrtoint ptr %old to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %flag_out = getelementptr i8,ptr %out,i64 8
 store i64 0,ptr %flag_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_atomic_snapshot(ptr %snapshot_out)
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
