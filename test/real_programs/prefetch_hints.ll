declare void @llvm.prefetch.p0(ptr,i32,i32,i32)
define i64 @prefetch_data_0_0(i64 %value,ptr %out,ptr %address,ptr %bad) {
entry:
 call void @llvm.prefetch.p0(ptr %address,i32 0,i32 0,i32 1)
 call void @llvm.prefetch.p0(ptr %bad,i32 0,i32 0,i32 1)
 %sum = add i64 %value,17
 store i64 %sum,ptr %out,align 1
 %result = xor i64 %value,19088743
 ret i64 %result
}
define i64 @prefetch_data_0_1(i64 %value,ptr %out,ptr %address,ptr %bad) {
entry:
 call void @llvm.prefetch.p0(ptr %address,i32 0,i32 1,i32 1)
 call void @llvm.prefetch.p0(ptr %bad,i32 0,i32 1,i32 1)
 %sum = add i64 %value,17
 store i64 %sum,ptr %out,align 1
 %result = xor i64 %value,19088743
 ret i64 %result
}
define i64 @prefetch_data_0_2(i64 %value,ptr %out,ptr %address,ptr %bad) {
entry:
 call void @llvm.prefetch.p0(ptr %address,i32 0,i32 2,i32 1)
 call void @llvm.prefetch.p0(ptr %bad,i32 0,i32 2,i32 1)
 %sum = add i64 %value,17
 store i64 %sum,ptr %out,align 1
 %result = xor i64 %value,19088743
 ret i64 %result
}
define i64 @prefetch_data_0_3(i64 %value,ptr %out,ptr %address,ptr %bad) {
entry:
 call void @llvm.prefetch.p0(ptr %address,i32 0,i32 3,i32 1)
 call void @llvm.prefetch.p0(ptr %bad,i32 0,i32 3,i32 1)
 %sum = add i64 %value,17
 store i64 %sum,ptr %out,align 1
 %result = xor i64 %value,19088743
 ret i64 %result
}
define i64 @prefetch_data_1_0(i64 %value,ptr %out,ptr %address,ptr %bad) {
entry:
 call void @llvm.prefetch.p0(ptr %address,i32 1,i32 0,i32 1)
 call void @llvm.prefetch.p0(ptr %bad,i32 1,i32 0,i32 1)
 %sum = add i64 %value,17
 store i64 %sum,ptr %out,align 1
 %result = xor i64 %value,19088743
 ret i64 %result
}
define i64 @prefetch_data_1_1(i64 %value,ptr %out,ptr %address,ptr %bad) {
entry:
 call void @llvm.prefetch.p0(ptr %address,i32 1,i32 1,i32 1)
 call void @llvm.prefetch.p0(ptr %bad,i32 1,i32 1,i32 1)
 %sum = add i64 %value,17
 store i64 %sum,ptr %out,align 1
 %result = xor i64 %value,19088743
 ret i64 %result
}
define i64 @prefetch_data_1_2(i64 %value,ptr %out,ptr %address,ptr %bad) {
entry:
 call void @llvm.prefetch.p0(ptr %address,i32 1,i32 2,i32 1)
 call void @llvm.prefetch.p0(ptr %bad,i32 1,i32 2,i32 1)
 %sum = add i64 %value,17
 store i64 %sum,ptr %out,align 1
 %result = xor i64 %value,19088743
 ret i64 %result
}
define i64 @prefetch_data_1_3(i64 %value,ptr %out,ptr %address,ptr %bad) {
entry:
 call void @llvm.prefetch.p0(ptr %address,i32 1,i32 3,i32 1)
 call void @llvm.prefetch.p0(ptr %bad,i32 1,i32 3,i32 1)
 %sum = add i64 %value,17
 store i64 %sum,ptr %out,align 1
 %result = xor i64 %value,19088743
 ret i64 %result
}
