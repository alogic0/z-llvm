declare i64 @owned_vector_touch(ptr,i64)
declare <8 x half> @llvm.fabs.v8f16(<8 x half>)
define i64 @owned_vector_f16x8(ptr %input,ptr %output) {
entry:
 %slot = alloca <8 x half>,align 16
 %value = load <8 x half>,ptr %input,align 1
 store <8 x half> %value,ptr %slot,align 16
 %sum = call i64 @owned_vector_touch(ptr %slot,i64 16)
 %again = load <8 x half>,ptr %slot,align 16
 %positive = call <8 x half> @llvm.fabs.v8f16(<8 x half> %again)
 store <8 x half> %positive,ptr %output,align 1
 ret i64 %sum
}
declare <4 x float> @llvm.fabs.v4f32(<4 x float>)
define i64 @owned_vector_f32x4(ptr %input,ptr %output) {
entry:
 %slot = alloca <4 x float>,align 16
 %value = load <4 x float>,ptr %input,align 1
 store <4 x float> %value,ptr %slot,align 16
 %sum = call i64 @owned_vector_touch(ptr %slot,i64 16)
 %again = load <4 x float>,ptr %slot,align 16
 %positive = call <4 x float> @llvm.fabs.v4f32(<4 x float> %again)
 store <4 x float> %positive,ptr %output,align 1
 ret i64 %sum
}
declare <2 x double> @llvm.fabs.v2f64(<2 x double>)
define i64 @owned_vector_f64x2(ptr %input,ptr %output) {
entry:
 %slot = alloca <2 x double>,align 16
 %value = load <2 x double>,ptr %input,align 1
 store <2 x double> %value,ptr %slot,align 16
 %sum = call i64 @owned_vector_touch(ptr %slot,i64 16)
 %again = load <2 x double>,ptr %slot,align 16
 %positive = call <2 x double> @llvm.fabs.v2f64(<2 x double> %again)
 store <2 x double> %positive,ptr %output,align 1
 ret i64 %sum
}
declare <3 x float> @llvm.fabs.v3f32(<3 x float>)
define i64 @owned_vector_f32x3(ptr %input,ptr %output) {
entry:
 %slot = alloca <3 x float>,align 16
 %value = load <3 x float>,ptr %input,align 1
 store <3 x float> %value,ptr %slot,align 16
 %sum = call i64 @owned_vector_touch(ptr %slot,i64 12)
 %again = load <3 x float>,ptr %slot,align 16
 %positive = call <3 x float> @llvm.fabs.v3f32(<3 x float> %again)
 store <3 x float> %positive,ptr %output,align 1
 ret i64 %sum
}
declare <17 x float> @llvm.fabs.v17f32(<17 x float>)
define i64 @owned_vector_f32x17(ptr %input,ptr %output) {
entry:
 %slot = alloca <17 x float>,align 16
 %value = load <17 x float>,ptr %input,align 1
 store <17 x float> %value,ptr %slot,align 16
 %sum = call i64 @owned_vector_touch(ptr %slot,i64 68)
 %again = load <17 x float>,ptr %slot,align 16
 %positive = call <17 x float> @llvm.fabs.v17f32(<17 x float> %again)
 store <17 x float> %positive,ptr %output,align 1
 ret i64 %sum
}
