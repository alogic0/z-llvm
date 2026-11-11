target triple = "x86_64-unknown-linux-gnu"
declare i1 @llvm.is.fpclass.f16(half,i32)
declare i64 @half_classification_clobber(i64)
define i64 @half_classification_0(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 0)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_1(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 1)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_2(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 2)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_4(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 4)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_8(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 8)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_16(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 16)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_32(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 32)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_64(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 64)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_128(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 128)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_256(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 256)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_512(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 512)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_3(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 3)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_1020(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 1020)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_448(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 448)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_60(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 60)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
define i64 @half_classification_1023(ptr %input,ptr %out,i64 %live) {
entry:
 %value = load half,ptr %input,align 1
 %condition = call i1 @llvm.is.fpclass.f16(half %value,i32 1023)
 %byte = zext i1 %condition to i8
 %wide = zext i1 %condition to i64
 %probe = call i64 @half_classification_clobber(i64 %live)
 store i8 %byte,ptr %out,align 1
 %answer = xor i64 %wide,%probe
 ret i64 %answer
}
