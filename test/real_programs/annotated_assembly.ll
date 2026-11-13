target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
attributes #7 = { nounwind }
define i64 @annotated_assembly_probe_0(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 1
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 1
 %before = load i8,ptr %slot,align 1
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i8) %slot,i32 3) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 1
 %after = load i8,ptr %slot,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_1(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 64
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 64
 %before = load i8,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i8) %slot,i32 3) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 64
 %after = load i8,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_2(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 1
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 1
 %before = load i8,ptr %slot,align 1
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 1 elementtype(i8) dereferenceable(1) %slot,i32 3) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 1
 %after = load i8,ptr %slot,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_3(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 64
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 64
 %before = load i8,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i8) dereferenceable(1) %slot,i32 3) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 64
 %after = load i8,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_4(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 1
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 1
 %before = load i8,ptr %slot,align 1
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i8) align 1 nonnull noundef dereferenceable_or_null(1) %slot,i32 3) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 1
 %after = load i8,ptr %slot,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_5(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 64
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 64
 %before = load i8,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i8) align 64 nonnull noundef dereferenceable_or_null(1) %slot,i32 3) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 64
 %after = load i8,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_6(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 1
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 1
 %before = load i8,ptr %slot,align 1
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i8) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 1
 %after = load i8,ptr %slot,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_7(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 64
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 64
 %before = load i8,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i8) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 64
 %after = load i8,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_8(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 1
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 1
 %before = load i8,ptr %slot,align 1
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 1 elementtype(i8) dereferenceable(1) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 1
 %after = load i8,ptr %slot,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_9(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 64
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 64
 %before = load i8,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i8) dereferenceable(1) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 64
 %after = load i8,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_10(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 1
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 1
 %before = load i8,ptr %slot,align 1
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i8) align 1 nonnull noundef dereferenceable_or_null(1) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 1
 %after = load i8,ptr %slot,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_11(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 64
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 64
 %before = load i8,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i8) align 64 nonnull noundef dereferenceable_or_null(1) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 64
 %after = load i8,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_12(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 1
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 1
 %before = load i8,ptr %slot,align 1
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i8) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 1
 %after = load i8,ptr %slot,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_13(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 64
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 64
 %before = load i8,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i8) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 64
 %after = load i8,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_14(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 1
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 1
 %before = load i8,ptr %slot,align 1
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 1 elementtype(i8) dereferenceable(1) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 1
 %after = load i8,ptr %slot,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_15(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 64
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 64
 %before = load i8,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i8) dereferenceable(1) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 64
 %after = load i8,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_16(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 1
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 1
 %before = load i8,ptr %slot,align 1
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i8) align 1 nonnull noundef dereferenceable_or_null(1) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 1
 %after = load i8,ptr %slot,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_17(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 64
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 64
 %before = load i8,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i8) align 64 nonnull noundef dereferenceable_or_null(1) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 64
 %after = load i8,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_18(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 1
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 1
 %before = load i8,ptr %slot,align 1
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i8) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 1
 %after = load i8,ptr %slot,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_19(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 64
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 64
 %before = load i8,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i8) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 64
 %after = load i8,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_20(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 1
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 1
 %before = load i8,ptr %slot,align 1
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 1 elementtype(i8) dereferenceable(1) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 1
 %after = load i8,ptr %slot,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_21(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 64
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 64
 %before = load i8,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i8) dereferenceable(1) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 64
 %after = load i8,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_22(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 1
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 1
 %before = load i8,ptr %slot,align 1
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i8) align 1 nonnull noundef dereferenceable_or_null(1) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 1
 %after = load i8,ptr %slot,align 1
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_23(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i8,align 64
 %input = load i8,ptr %source,align 1
 store i8 %input,ptr %slot,align 64
 %before = load i8,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i8) align 64 nonnull noundef dereferenceable_or_null(1) %slot) #7
 %next = xor i8 %before,90
 store i8 %next,ptr %slot,align 64
 %after = load i8,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_24(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 2
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 2
 %before = load i16,ptr %slot,align 2
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i16) %slot,i32 3) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 2
 %after = load i16,ptr %slot,align 2
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_25(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 64
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 64
 %before = load i16,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i16) %slot,i32 3) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 64
 %after = load i16,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_26(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 2
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 2
 %before = load i16,ptr %slot,align 2
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 2 elementtype(i16) dereferenceable(2) %slot,i32 3) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 2
 %after = load i16,ptr %slot,align 2
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_27(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 64
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 64
 %before = load i16,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i16) dereferenceable(2) %slot,i32 3) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 64
 %after = load i16,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_28(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 2
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 2
 %before = load i16,ptr %slot,align 2
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i16) align 2 nonnull noundef dereferenceable_or_null(2) %slot,i32 3) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 2
 %after = load i16,ptr %slot,align 2
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_29(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 64
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 64
 %before = load i16,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i16) align 64 nonnull noundef dereferenceable_or_null(2) %slot,i32 3) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 64
 %after = load i16,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_30(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 2
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 2
 %before = load i16,ptr %slot,align 2
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i16) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 2
 %after = load i16,ptr %slot,align 2
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_31(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 64
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 64
 %before = load i16,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i16) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 64
 %after = load i16,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_32(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 2
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 2
 %before = load i16,ptr %slot,align 2
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 2 elementtype(i16) dereferenceable(2) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 2
 %after = load i16,ptr %slot,align 2
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_33(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 64
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 64
 %before = load i16,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i16) dereferenceable(2) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 64
 %after = load i16,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_34(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 2
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 2
 %before = load i16,ptr %slot,align 2
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i16) align 2 nonnull noundef dereferenceable_or_null(2) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 2
 %after = load i16,ptr %slot,align 2
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_35(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 64
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 64
 %before = load i16,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i16) align 64 nonnull noundef dereferenceable_or_null(2) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 64
 %after = load i16,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_36(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 2
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 2
 %before = load i16,ptr %slot,align 2
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i16) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 2
 %after = load i16,ptr %slot,align 2
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_37(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 64
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 64
 %before = load i16,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i16) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 64
 %after = load i16,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_38(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 2
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 2
 %before = load i16,ptr %slot,align 2
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 2 elementtype(i16) dereferenceable(2) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 2
 %after = load i16,ptr %slot,align 2
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_39(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 64
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 64
 %before = load i16,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i16) dereferenceable(2) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 64
 %after = load i16,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_40(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 2
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 2
 %before = load i16,ptr %slot,align 2
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i16) align 2 nonnull noundef dereferenceable_or_null(2) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 2
 %after = load i16,ptr %slot,align 2
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_41(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 64
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 64
 %before = load i16,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i16) align 64 nonnull noundef dereferenceable_or_null(2) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 64
 %after = load i16,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_42(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 2
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 2
 %before = load i16,ptr %slot,align 2
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i16) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 2
 %after = load i16,ptr %slot,align 2
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_43(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 64
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 64
 %before = load i16,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i16) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 64
 %after = load i16,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_44(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 2
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 2
 %before = load i16,ptr %slot,align 2
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 2 elementtype(i16) dereferenceable(2) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 2
 %after = load i16,ptr %slot,align 2
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_45(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 64
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 64
 %before = load i16,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i16) dereferenceable(2) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 64
 %after = load i16,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_46(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 2
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 2
 %before = load i16,ptr %slot,align 2
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i16) align 2 nonnull noundef dereferenceable_or_null(2) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 2
 %after = load i16,ptr %slot,align 2
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_47(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i16,align 64
 %input = load i16,ptr %source,align 1
 store i16 %input,ptr %slot,align 64
 %before = load i16,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i16) align 64 nonnull noundef dereferenceable_or_null(2) %slot) #7
 %next = xor i16 %before,23130
 store i16 %next,ptr %slot,align 64
 %after = load i16,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_48(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 4
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 4
 %before = load i32,ptr %slot,align 4
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i32) %slot,i32 3) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 4
 %after = load i32,ptr %slot,align 4
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_49(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 64
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 64
 %before = load i32,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i32) %slot,i32 3) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 64
 %after = load i32,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_50(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 4
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 4
 %before = load i32,ptr %slot,align 4
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 4 elementtype(i32) dereferenceable(4) %slot,i32 3) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 4
 %after = load i32,ptr %slot,align 4
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_51(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 64
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 64
 %before = load i32,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i32) dereferenceable(4) %slot,i32 3) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 64
 %after = load i32,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_52(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 4
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 4
 %before = load i32,ptr %slot,align 4
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i32) align 4 nonnull noundef dereferenceable_or_null(4) %slot,i32 3) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 4
 %after = load i32,ptr %slot,align 4
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_53(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 64
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 64
 %before = load i32,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i32) align 64 nonnull noundef dereferenceable_or_null(4) %slot,i32 3) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 64
 %after = load i32,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_54(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 4
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 4
 %before = load i32,ptr %slot,align 4
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i32) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 4
 %after = load i32,ptr %slot,align 4
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_55(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 64
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 64
 %before = load i32,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i32) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 64
 %after = load i32,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_56(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 4
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 4
 %before = load i32,ptr %slot,align 4
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 4 elementtype(i32) dereferenceable(4) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 4
 %after = load i32,ptr %slot,align 4
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_57(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 64
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 64
 %before = load i32,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i32) dereferenceable(4) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 64
 %after = load i32,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_58(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 4
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 4
 %before = load i32,ptr %slot,align 4
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i32) align 4 nonnull noundef dereferenceable_or_null(4) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 4
 %after = load i32,ptr %slot,align 4
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_59(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 64
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 64
 %before = load i32,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i32) align 64 nonnull noundef dereferenceable_or_null(4) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 64
 %after = load i32,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_60(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 4
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 4
 %before = load i32,ptr %slot,align 4
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i32) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 4
 %after = load i32,ptr %slot,align 4
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_61(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 64
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 64
 %before = load i32,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i32) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 64
 %after = load i32,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_62(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 4
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 4
 %before = load i32,ptr %slot,align 4
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 4 elementtype(i32) dereferenceable(4) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 4
 %after = load i32,ptr %slot,align 4
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_63(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 64
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 64
 %before = load i32,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i32) dereferenceable(4) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 64
 %after = load i32,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_64(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 4
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 4
 %before = load i32,ptr %slot,align 4
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i32) align 4 nonnull noundef dereferenceable_or_null(4) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 4
 %after = load i32,ptr %slot,align 4
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_65(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 64
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 64
 %before = load i32,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i32) align 64 nonnull noundef dereferenceable_or_null(4) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 64
 %after = load i32,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_66(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 4
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 4
 %before = load i32,ptr %slot,align 4
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i32) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 4
 %after = load i32,ptr %slot,align 4
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_67(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 64
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 64
 %before = load i32,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i32) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 64
 %after = load i32,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_68(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 4
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 4
 %before = load i32,ptr %slot,align 4
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 4 elementtype(i32) dereferenceable(4) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 4
 %after = load i32,ptr %slot,align 4
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_69(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 64
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 64
 %before = load i32,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i32) dereferenceable(4) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 64
 %after = load i32,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_70(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 4
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 4
 %before = load i32,ptr %slot,align 4
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i32) align 4 nonnull noundef dereferenceable_or_null(4) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 4
 %after = load i32,ptr %slot,align 4
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_71(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i32,align 64
 %input = load i32,ptr %source,align 1
 store i32 %input,ptr %slot,align 64
 %before = load i32,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i32) align 64 nonnull noundef dereferenceable_or_null(4) %slot) #7
 %next = xor i32 %before,1515870810
 store i32 %next,ptr %slot,align 64
 %after = load i32,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_72(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 8
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 8
 %before = load i64,ptr %slot,align 8
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i64) %slot,i32 3) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 8
 %after = load i64,ptr %slot,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_73(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 64
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 64
 %before = load i64,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i64) %slot,i32 3) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 64
 %after = load i64,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_74(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 8
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 8
 %before = load i64,ptr %slot,align 8
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 8 elementtype(i64) dereferenceable(8) %slot,i32 3) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 8
 %after = load i64,ptr %slot,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_75(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 64
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 64
 %before = load i64,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i64) dereferenceable(8) %slot,i32 3) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 64
 %after = load i64,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_76(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 8
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 8
 %before = load i64,ptr %slot,align 8
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i64) align 8 nonnull noundef dereferenceable_or_null(8) %slot,i32 3) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 8
 %after = load i64,ptr %slot,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_77(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 64
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 64
 %before = load i64,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i64) align 64 nonnull noundef dereferenceable_or_null(8) %slot,i32 3) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 64
 %after = load i64,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_78(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 8
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 8
 %before = load i64,ptr %slot,align 8
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i64) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 8
 %after = load i64,ptr %slot,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_79(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 64
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 64
 %before = load i64,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i64) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 64
 %after = load i64,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_80(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 8
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 8
 %before = load i64,ptr %slot,align 8
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 8 elementtype(i64) dereferenceable(8) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 8
 %after = load i64,ptr %slot,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_81(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 64
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 64
 %before = load i64,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i64) dereferenceable(8) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 64
 %after = load i64,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_82(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 8
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 8
 %before = load i64,ptr %slot,align 8
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i64) align 8 nonnull noundef dereferenceable_or_null(8) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 8
 %after = load i64,ptr %slot,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_83(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 64
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 64
 %before = load i64,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i64) align 64 nonnull noundef dereferenceable_or_null(8) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 64
 %after = load i64,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_84(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 8
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 8
 %before = load i64,ptr %slot,align 8
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i64) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 8
 %after = load i64,ptr %slot,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_85(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 64
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 64
 %before = load i64,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i64) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 64
 %after = load i64,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_86(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 8
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 8
 %before = load i64,ptr %slot,align 8
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 8 elementtype(i64) dereferenceable(8) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 8
 %after = load i64,ptr %slot,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_87(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 64
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 64
 %before = load i64,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i64) dereferenceable(8) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 64
 %after = load i64,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_88(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 8
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 8
 %before = load i64,ptr %slot,align 8
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i64) align 8 nonnull noundef dereferenceable_or_null(8) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 8
 %after = load i64,ptr %slot,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_89(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 64
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 64
 %before = load i64,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i64) align 64 nonnull noundef dereferenceable_or_null(8) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 64
 %after = load i64,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_90(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 8
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 8
 %before = load i64,ptr %slot,align 8
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i64) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 8
 %after = load i64,ptr %slot,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_91(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 64
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 64
 %before = load i64,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i64) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 64
 %after = load i64,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_92(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 8
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 8
 %before = load i64,ptr %slot,align 8
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 8 elementtype(i64) dereferenceable(8) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 8
 %after = load i64,ptr %slot,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_93(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 64
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 64
 %before = load i64,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i64) dereferenceable(8) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 64
 %after = load i64,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_94(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 8
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 8
 %before = load i64,ptr %slot,align 8
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i64) align 8 nonnull noundef dereferenceable_or_null(8) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 8
 %after = load i64,ptr %slot,align 8
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_95(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i64,align 64
 %input = load i64,ptr %source,align 1
 store i64 %input,ptr %slot,align 64
 %before = load i64,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i64) align 64 nonnull noundef dereferenceable_or_null(8) %slot) #7
 %next = xor i64 %before,6510615555426900570
 store i64 %next,ptr %slot,align 64
 %after = load i64,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_96(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 16
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 16
 %before = load i128,ptr %slot,align 16
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i128) %slot,i32 3) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 16
 %after = load i128,ptr %slot,align 16
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_97(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 64
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 64
 %before = load i128,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i128) %slot,i32 3) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 64
 %after = load i128,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_98(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 16
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 16
 %before = load i128,ptr %slot,align 16
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 16 elementtype(i128) dereferenceable(16) %slot,i32 3) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 16
 %after = load i128,ptr %slot,align 16
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_99(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 64
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 64
 %before = load i128,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i128) dereferenceable(16) %slot,i32 3) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 64
 %after = load i128,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_100(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 16
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 16
 %before = load i128,ptr %slot,align 16
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i128) align 16 nonnull noundef dereferenceable_or_null(16) %slot,i32 3) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 16
 %after = load i128,ptr %slot,align 16
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_101(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 64
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 64
 %before = load i128,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i128) align 64 nonnull noundef dereferenceable_or_null(16) %slot,i32 3) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 64
 %after = load i128,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_102(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 16
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 16
 %before = load i128,ptr %slot,align 16
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i128) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 16
 %after = load i128,ptr %slot,align 16
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_103(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 64
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 64
 %before = load i128,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i128) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 64
 %after = load i128,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_104(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 16
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 16
 %before = load i128,ptr %slot,align 16
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 16 elementtype(i128) dereferenceable(16) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 16
 %after = load i128,ptr %slot,align 16
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_105(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 64
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 64
 %before = load i128,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i128) dereferenceable(16) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 64
 %after = load i128,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_106(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 16
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 16
 %before = load i128,ptr %slot,align 16
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i128) align 16 nonnull noundef dereferenceable_or_null(16) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 16
 %after = load i128,ptr %slot,align 16
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_107(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 64
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 64
 %before = load i128,ptr %slot,align 64
 call void asm sideeffect "", "=*m|r,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i128) align 64 nonnull noundef dereferenceable_or_null(16) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 64
 %after = load i128,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_108(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 16
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 16
 %before = load i128,ptr %slot,align 16
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i128) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 16
 %after = load i128,ptr %slot,align 16
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_109(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 64
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 64
 %before = load i128,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i128) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 64
 %after = load i128,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_110(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 16
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 16
 %before = load i128,ptr %slot,align 16
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 16 elementtype(i128) dereferenceable(16) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 16
 %after = load i128,ptr %slot,align 16
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_111(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 64
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 64
 %before = load i128,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i128) dereferenceable(16) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 64
 %after = load i128,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_112(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 16
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 16
 %before = load i128,ptr %slot,align 16
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i128) align 16 nonnull noundef dereferenceable_or_null(16) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 16
 %after = load i128,ptr %slot,align 16
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_113(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 64
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 64
 %before = load i128,ptr %slot,align 64
 call void asm sideeffect "", "=*r|m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i128) align 64 nonnull noundef dereferenceable_or_null(16) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 64
 %after = load i128,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_114(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 16
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 16
 %before = load i128,ptr %slot,align 16
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i128) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 16
 %after = load i128,ptr %slot,align 16
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_115(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 64
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 64
 %before = load i128,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i128) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 64
 %after = load i128,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_116(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 16
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 16
 %before = load i128,ptr %slot,align 16
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 16 elementtype(i128) dereferenceable(16) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 16
 %after = load i128,ptr %slot,align 16
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_117(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 64
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 64
 %before = load i128,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull align 64 elementtype(i128) dereferenceable(16) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 64
 %after = load i128,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_118(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 16
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 16
 %before = load i128,ptr %slot,align 16
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i128) align 16 nonnull noundef dereferenceable_or_null(16) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 16
 %after = load i128,ptr %slot,align 16
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
define i64 @annotated_assembly_probe_119(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %slot = alloca i128,align 64
 %input = load i128,ptr %source,align 1
 store i128 %input,ptr %slot,align 64
 %before = load i128,ptr %slot,align 64
 call void asm sideeffect "", "*m,~{dirflag},~{fpsr},~{flags}"(ptr elementtype(i128) align 64 nonnull noundef dereferenceable_or_null(16) %slot) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 store i128 %next,ptr %slot,align 64
 %after = load i128,ptr %slot,align 64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %after,ptr %p,align 1
 ret i64 %token
}
