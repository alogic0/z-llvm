target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare i64 @complete_clobber(i64,i64,i64,i64,i64,i64,i64,i64)
attributes #7 = { nounwind }
@optional_assembly_global_8 = internal constant i8 165,align 16
@optional_assembly_global_16 = internal constant i16 42405,align 16
@optional_assembly_global_32 = internal constant i32 2779096485,align 16
@optional_assembly_global_64 = internal constant i64 11936128518282651045,align 16
@optional_assembly_global_128 = internal constant i128 -120099658913272398869426332034741721691,align 16
define i64 @optional_assembly_probe_0(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_1(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_2(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_3(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_4(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_5(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_6(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 1 dereferenceable(1) %source) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_7(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 1 dereferenceable(1) %source) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_8(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 1 dereferenceable(1) %source) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_9(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr @optional_assembly_global_8,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_8) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_10(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr @optional_assembly_global_8,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_8) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_11(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr @optional_assembly_global_8,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_8) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_12(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr @optional_assembly_global_8,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_8) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_13(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr @optional_assembly_global_8,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_8) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_14(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr @optional_assembly_global_8,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_8) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_15(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr @optional_assembly_global_8,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 1 dereferenceable(1) @optional_assembly_global_8) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_16(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr @optional_assembly_global_8,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 1 dereferenceable(1) @optional_assembly_global_8) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_17(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i8,ptr @optional_assembly_global_8,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 1 dereferenceable(1) @optional_assembly_global_8) #7
 %next = xor i8 %before,90
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i8 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 1
 store i8 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_18(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_19(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_20(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_21(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_22(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_23(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_24(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 2 dereferenceable(2) %source) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_25(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 2 dereferenceable(2) %source) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_26(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 2 dereferenceable(2) %source) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_27(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr @optional_assembly_global_16,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_16) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_28(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr @optional_assembly_global_16,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_16) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_29(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr @optional_assembly_global_16,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_16) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_30(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr @optional_assembly_global_16,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_16) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_31(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr @optional_assembly_global_16,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_16) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_32(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr @optional_assembly_global_16,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_16) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_33(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr @optional_assembly_global_16,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 2 dereferenceable(2) @optional_assembly_global_16) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_34(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr @optional_assembly_global_16,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 2 dereferenceable(2) @optional_assembly_global_16) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_35(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i16,ptr @optional_assembly_global_16,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 2 dereferenceable(2) @optional_assembly_global_16) #7
 %next = xor i16 %before,23130
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i16 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 2
 store i16 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_36(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_37(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_38(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_39(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_40(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_41(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_42(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 4 dereferenceable(4) %source) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_43(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 4 dereferenceable(4) %source) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_44(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 4 dereferenceable(4) %source) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_45(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr @optional_assembly_global_32,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_32) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_46(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr @optional_assembly_global_32,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_32) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_47(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr @optional_assembly_global_32,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_32) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_48(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr @optional_assembly_global_32,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_32) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_49(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr @optional_assembly_global_32,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_32) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_50(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr @optional_assembly_global_32,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_32) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_51(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr @optional_assembly_global_32,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 4 dereferenceable(4) @optional_assembly_global_32) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_52(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr @optional_assembly_global_32,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 4 dereferenceable(4) @optional_assembly_global_32) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_53(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i32,ptr @optional_assembly_global_32,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 4 dereferenceable(4) @optional_assembly_global_32) #7
 %next = xor i32 %before,1515870810
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i32 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 4
 store i32 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_54(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_55(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_56(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_57(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_58(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_59(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_60(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 8 dereferenceable(8) %source) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_61(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 8 dereferenceable(8) %source) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_62(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 8 dereferenceable(8) %source) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_63(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr @optional_assembly_global_64,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_64) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_64(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr @optional_assembly_global_64,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_64) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_65(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr @optional_assembly_global_64,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_64) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_66(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr @optional_assembly_global_64,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_64) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_67(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr @optional_assembly_global_64,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_64) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_68(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr @optional_assembly_global_64,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_64) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_69(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr @optional_assembly_global_64,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 8 dereferenceable(8) @optional_assembly_global_64) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_70(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr @optional_assembly_global_64,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 8 dereferenceable(8) @optional_assembly_global_64) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_71(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i64,ptr @optional_assembly_global_64,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 8 dereferenceable(8) @optional_assembly_global_64) #7
 %next = xor i64 %before,6510615555426900570
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_72(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_73(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_74(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull %source) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_75(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_76(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_77(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull %source) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_78(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr %source,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 16 dereferenceable(16) %source) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_79(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr %source,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 16 dereferenceable(16) %source) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_80(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr %source,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 16 dereferenceable(16) %source) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_81(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr @optional_assembly_global_128,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_128) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_82(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr @optional_assembly_global_128,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_128) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_83(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr @optional_assembly_global_128,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull @optional_assembly_global_128) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_84(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr @optional_assembly_global_128,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_128) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_85(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr @optional_assembly_global_128,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_128) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_86(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr @optional_assembly_global_128,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr noundef nonnull @optional_assembly_global_128) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_87(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr @optional_assembly_global_128,align 1
 call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 16 dereferenceable(16) @optional_assembly_global_128) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_88(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr @optional_assembly_global_128,align 1
 tail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 16 dereferenceable(16) @optional_assembly_global_128) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_89(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %before = load i128,ptr @optional_assembly_global_128,align 1
 notail call void asm sideeffect "","m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull align 16 dereferenceable(16) @optional_assembly_global_128) #7
 %next = xor i128 %before,120099658913272398869426332034741721690
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i128 %before,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 16
 store i128 %next,ptr %p,align 1
 ret i64 %token
}
define i64 @optional_assembly_probe_90(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = call i32 asm sideeffect "mov $$-123, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_91(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = tail call i32 asm sideeffect "mov $$-123, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_92(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = notail call i32 asm sideeffect "mov $$-123, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_93(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = call i32 asm sideeffect "mov $$0, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_94(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = tail call i32 asm sideeffect "mov $$0, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_95(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = notail call i32 asm sideeffect "mov $$0, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_96(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = call i32 asm sideeffect "mov $$123, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_97(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = tail call i32 asm sideeffect "mov $$123, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_98(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = notail call i32 asm sideeffect "mov $$123, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_99(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = call i32 asm sideeffect "mov $$-2147483648, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_100(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = tail call i32 asm sideeffect "mov $$-2147483648, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_101(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = notail call i32 asm sideeffect "mov $$-2147483648, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_102(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = call i32 asm sideeffect "mov $$4294967295, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_103(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = tail call i32 asm sideeffect "mov $$4294967295, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_104(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = notail call i32 asm sideeffect "mov $$4294967295, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_105(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = call i64 asm sideeffect "mov $$-123, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_106(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = tail call i64 asm sideeffect "mov $$-123, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_107(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = notail call i64 asm sideeffect "mov $$-123, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_108(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = call i64 asm sideeffect "mov $$0, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_109(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = tail call i64 asm sideeffect "mov $$0, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_110(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = notail call i64 asm sideeffect "mov $$0, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_111(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = call i64 asm sideeffect "mov $$123, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_112(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = tail call i64 asm sideeffect "mov $$123, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_113(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = notail call i64 asm sideeffect "mov $$123, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_114(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = call i64 asm sideeffect "mov $$-9223372036854775808, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_115(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = tail call i64 asm sideeffect "mov $$-9223372036854775808, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_116(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = notail call i64 asm sideeffect "mov $$-9223372036854775808, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_117(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = call i64 asm sideeffect "mov $$18446744073709551615, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_118(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = tail call i64 asm sideeffect "mov $$18446744073709551615, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_119(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %v = notail call i64 asm sideeffect "mov $$18446744073709551615, ${0}","=r,~{dirflag},~{fpsr},~{flags}"() #7
 %wide = or i64 %v,0
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_120(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load i32,ptr %source,align 1
 %v = call i32 asm "addl ${1}, ${0}","=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %input) #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_121(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load i32,ptr %source,align 1
 %v = tail call i32 asm "addl ${1}, ${0}","=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %input) #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
define i64 @optional_assembly_probe_122(ptr %out,ptr %source,ptr %unused,i64 %salt) {
entry:
 %input = load i32,ptr %source,align 1
 %v = notail call i32 asm "addl ${1}, ${0}","=r,r,0,~{flags},~{dirflag},~{fpsr},~{flags}"(i32 13,i32 %input) #7
 %wide = zext i32 %v to i64
 %token = call i64 @complete_clobber(i64 %salt,i64 2,i64 3,i64 4,i64 5,i64 6,i64 7,i64 8)
 store i64 %wide,ptr %out,align 1
 %p = getelementptr i8,ptr %out,i64 8
 store i64 %token,ptr %p,align 1
 %answer = xor i64 %wide,%token
 ret i64 %answer
}
