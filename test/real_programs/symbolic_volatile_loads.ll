target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
@symbolic_volatile_plain = global [8192 x i8] zeroinitializer,align 4096
@"symbolic volatile storage" = global [8192 x i8] zeroinitializer,align 4096
declare void @complete_volatile_change(ptr,i64)
declare void @complete_volatile_snapshot(ptr)
define i64 @symbolic_volatile_probe_0(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i8,ptr @symbolic_volatile_plain,align 1
 call void @complete_volatile_change(ptr @symbolic_volatile_plain,i64 1)
 %after = load volatile i8,ptr @symbolic_volatile_plain,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 10
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_1(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i8,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),i64 1)
 %after = load volatile i8,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 10
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_2(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i8,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),i64 1)
 %after = load volatile i8,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 10
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_3(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i8,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4095),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4095),i64 1)
 %after = load volatile i8,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4095),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 10
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_4(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i8,ptr @"symbolic volatile storage",align 1
 call void @complete_volatile_change(ptr @"symbolic volatile storage",i64 1)
 %after = load volatile i8,ptr @"symbolic volatile storage",align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 10
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_5(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i8,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),i64 1)
 %after = load volatile i8,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 10
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_6(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i8,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),i64 1)
 %after = load volatile i8,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 10
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_7(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i8,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4095),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4095),i64 1)
 %after = load volatile i8,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4095),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 2
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 10
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_8(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i16,ptr @symbolic_volatile_plain,align 1
 call void @complete_volatile_change(ptr @symbolic_volatile_plain,i64 2)
 %after = load volatile i16,ptr @symbolic_volatile_plain,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 12
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_9(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i16,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),i64 2)
 %after = load volatile i16,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 12
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_10(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i16,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),i64 2)
 %after = load volatile i16,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 12
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_11(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i16,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4094),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4094),i64 2)
 %after = load volatile i16,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4094),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 12
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_12(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i16,ptr @"symbolic volatile storage",align 1
 call void @complete_volatile_change(ptr @"symbolic volatile storage",i64 2)
 %after = load volatile i16,ptr @"symbolic volatile storage",align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 12
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_13(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i16,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),i64 2)
 %after = load volatile i16,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 12
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_14(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i16,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),i64 2)
 %after = load volatile i16,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 12
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_15(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i16,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4094),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4094),i64 2)
 %after = load volatile i16,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4094),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 4
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 12
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_16(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i32,ptr @symbolic_volatile_plain,align 1
 call void @complete_volatile_change(ptr @symbolic_volatile_plain,i64 4)
 %after = load volatile i32,ptr @symbolic_volatile_plain,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 16
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_17(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i32,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),i64 4)
 %after = load volatile i32,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 16
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_18(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i32,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),i64 4)
 %after = load volatile i32,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 16
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_19(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i32,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4092),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4092),i64 4)
 %after = load volatile i32,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4092),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 16
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_20(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i32,ptr @"symbolic volatile storage",align 1
 call void @complete_volatile_change(ptr @"symbolic volatile storage",i64 4)
 %after = load volatile i32,ptr @"symbolic volatile storage",align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 16
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_21(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i32,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),i64 4)
 %after = load volatile i32,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 16
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_22(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i32,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),i64 4)
 %after = load volatile i32,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 16
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_23(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i32,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4092),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4092),i64 4)
 %after = load volatile i32,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4092),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 16
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_24(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i64,ptr @symbolic_volatile_plain,align 1
 call void @complete_volatile_change(ptr @symbolic_volatile_plain,i64 8)
 %after = load volatile i64,ptr @symbolic_volatile_plain,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_25(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i64,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),i64 8)
 %after = load volatile i64,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_26(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i64,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),i64 8)
 %after = load volatile i64,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_27(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i64,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4088),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4088),i64 8)
 %after = load volatile i64,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4088),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_28(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i64,ptr @"symbolic volatile storage",align 1
 call void @complete_volatile_change(ptr @"symbolic volatile storage",i64 8)
 %after = load volatile i64,ptr @"symbolic volatile storage",align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_29(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i64,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),i64 8)
 %after = load volatile i64,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_30(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i64,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),i64 8)
 %after = load volatile i64,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_31(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile i64,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4088),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4088),i64 8)
 %after = load volatile i64,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4088),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_32(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile ptr,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 0),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 0),i64 8)
 %after = load volatile ptr,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 0),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store ptr %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store ptr %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_33(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile ptr,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),i64 8)
 %after = load volatile ptr,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 8),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store ptr %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store ptr %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_34(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile ptr,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),i64 8)
 %after = load volatile ptr,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 31),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store ptr %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store ptr %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_35(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile ptr,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4088),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4088),i64 8)
 %after = load volatile ptr,ptr getelementptr inbounds (i8,ptr @symbolic_volatile_plain,i64 4088),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store ptr %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store ptr %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_36(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile ptr,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 0),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 0),i64 8)
 %after = load volatile ptr,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 0),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store ptr %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store ptr %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_37(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile ptr,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),i64 8)
 %after = load volatile ptr,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 8),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store ptr %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store ptr %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_38(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile ptr,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),i64 8)
 %after = load volatile ptr,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 31),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store ptr %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store ptr %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
define i64 @symbolic_volatile_probe_39(ptr %out,ptr %unused,ptr %expected,i64 %salt) {
entry:
 %before = load volatile ptr,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4088),align 1
 call void @complete_volatile_change(ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4088),i64 8)
 %after = load volatile ptr,ptr getelementptr inbounds (i8,ptr @"symbolic volatile storage",i64 4088),align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store ptr %before,ptr %out,align 1
 %after_out = getelementptr i8,ptr %out,i64 8
 store ptr %after,ptr %after_out,align 1
 %token_out = getelementptr i8,ptr %out,i64 16
 store i64 %token,ptr %token_out,align 1
 %snapshot_out = getelementptr i8,ptr %out,i64 24
 call void @complete_volatile_snapshot(ptr %snapshot_out)
 ret i64 %token
}
