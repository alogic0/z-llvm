target triple = "x86_64-unknown-linux-gnu"
declare i64 @half_storage_clobber(i64)
declare void @llvm.memset.p0.i64(ptr,i8,i64,i1)
declare void @llvm.memcpy.p0.p0.i64(ptr,ptr,i64,i1)
define i64 @half_storage_argument(i16 %raw,ptr %input,ptr %output,i64 %live) {
entry:
 %slab = alloca [16 x i8],align 16
 call void @llvm.memset.p0.i64(ptr %slab,i8 -89,i64 16,i1 false)
 %value = bitcast i16 %raw to half
 %choose = trunc i64 %live to i1
 br i1 %choose,label %left,label %right
left:
 %a = getelementptr i8,ptr %slab,i64 3
 br label %merge
right:
 %b = getelementptr i8,ptr %slab,i64 14
 br label %merge
merge:
 %at = phi ptr [%a,%left],[%b,%right]
 store half %value,ptr %at,align 1
 %captured = load i16,ptr %at,align 1
 %probe = call i64 @half_storage_clobber(i64 %live)
 store half 0xH3C01,ptr %at,align 1
 call void @llvm.memcpy.p0.p0.i64(ptr %output,ptr %slab,i64 16,i1 false)
 %before = zext i16 %captured to i64
 %answer = xor i64 %before,%probe
 ret i64 %answer
}
define i64 @half_storage_input(i16 %raw,ptr %input,ptr %output,i64 %live) {
entry:
 %slab = alloca [16 x i8],align 16
 call void @llvm.memset.p0.i64(ptr %slab,i8 -89,i64 16,i1 false)
 %source = load i16,ptr %input,align 1
 %value = bitcast i16 %source to half
 %choose = trunc i64 %live to i1
 br i1 %choose,label %left,label %right
left:
 %a = getelementptr i8,ptr %slab,i64 3
 br label %merge
right:
 %b = getelementptr i8,ptr %slab,i64 14
 br label %merge
merge:
 %at = phi ptr [%a,%left],[%b,%right]
 store half %value,ptr %at,align 1
 %captured = load i16,ptr %at,align 1
 %probe = call i64 @half_storage_clobber(i64 %live)
 store half 0xH3C01,ptr %at,align 1
 call void @llvm.memcpy.p0.p0.i64(ptr %output,ptr %slab,i64 16,i1 false)
 %before = zext i16 %captured to i64
 %answer = xor i64 %before,%probe
 ret i64 %answer
}
define i64 @half_storage_signaling_nan(i16 %raw,ptr %input,ptr %output,i64 %live) {
entry:
 %slab = alloca [16 x i8],align 16
 call void @llvm.memset.p0.i64(ptr %slab,i8 -89,i64 16,i1 false)
 %choose = trunc i64 %live to i1
 br i1 %choose,label %left,label %right
left:
 %a = getelementptr i8,ptr %slab,i64 3
 br label %merge
right:
 %b = getelementptr i8,ptr %slab,i64 14
 br label %merge
merge:
 %at = phi ptr [%a,%left],[%b,%right]
 store half 0xH7D01,ptr %at,align 1
 %captured = load i16,ptr %at,align 1
 %probe = call i64 @half_storage_clobber(i64 %live)
 store half 0xH3C01,ptr %at,align 1
 call void @llvm.memcpy.p0.p0.i64(ptr %output,ptr %slab,i64 16,i1 false)
 %before = zext i16 %captured to i64
 %answer = xor i64 %before,%probe
 ret i64 %answer
}
define i64 @half_storage_negative_zero(i16 %raw,ptr %input,ptr %output,i64 %live) {
entry:
 %slab = alloca [16 x i8],align 16
 call void @llvm.memset.p0.i64(ptr %slab,i8 -89,i64 16,i1 false)
 %choose = trunc i64 %live to i1
 br i1 %choose,label %left,label %right
left:
 %a = getelementptr i8,ptr %slab,i64 3
 br label %merge
right:
 %b = getelementptr i8,ptr %slab,i64 14
 br label %merge
merge:
 %at = phi ptr [%a,%left],[%b,%right]
 store half 0xH8000,ptr %at,align 1
 %captured = load i16,ptr %at,align 1
 %probe = call i64 @half_storage_clobber(i64 %live)
 store half 0xH3C01,ptr %at,align 1
 call void @llvm.memcpy.p0.p0.i64(ptr %output,ptr %slab,i64 16,i1 false)
 %before = zext i16 %captured to i64
 %answer = xor i64 %before,%probe
 ret i64 %answer
}
