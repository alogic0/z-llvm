target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
declare i64 @constant_pair_clobber(i64)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
define i64 @constant_pair_pi_argument(ptr %destination, ptr %slot, i64 %live, ptr %out) {
entry:
  store { ptr, i64 } { ptr inttoptr (i64 8 to ptr), i64 -1 }, ptr %destination, align 8
  %noise = call i64 @constant_pair_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %low = load i64, ptr %destination, align 8
  %next = getelementptr i8, ptr %destination, i64 8
  %high = load i64, ptr %next, align 8
  %sum = add i64 %low, %high
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @constant_pair_pi_loaded(ptr %destination, ptr %slot, i64 %live, ptr %out) {
entry:
  %loaded = load ptr, ptr %slot, align 8
  store { ptr, i64 } { ptr inttoptr (i64 8 to ptr), i64 -1 }, ptr %loaded, align 8
  %noise = call i64 @constant_pair_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %low = load i64, ptr %loaded, align 8
  %next = getelementptr i8, ptr %loaded, i64 8
  %high = load i64, ptr %next, align 8
  %sum = add i64 %low, %high
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @constant_pair_pi_frame(ptr %destination, ptr %slot, i64 %live, ptr %out) {
entry:
  %frame = alloca [48 x i8], align 16
  call void @llvm.memset.p0.i64(ptr %frame, i8 0, i64 48, i1 false)
  store { ptr, i64 } { ptr inttoptr (i64 8 to ptr), i64 -1 }, ptr %frame, align 8
  %noise = call i64 @constant_pair_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr %destination, ptr %frame, i64 48, i1 false)
  %low = load i64, ptr %frame, align 8
  %next = getelementptr i8, ptr %frame, i64 8
  %high = load i64, ptr %next, align 8
  %sum = add i64 %low, %high
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @constant_pair_ip_argument(ptr %destination, ptr %slot, i64 %live, ptr %out) {
entry:
  store { i64, ptr } { i64 -2401053092306725256, ptr null }, ptr %destination, align 8
  %noise = call i64 @constant_pair_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %low = load i64, ptr %destination, align 8
  %next = getelementptr i8, ptr %destination, i64 8
  %high = load i64, ptr %next, align 8
  %sum = add i64 %low, %high
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @constant_pair_ip_loaded(ptr %destination, ptr %slot, i64 %live, ptr %out) {
entry:
  %loaded = load ptr, ptr %slot, align 8
  store { i64, ptr } { i64 -2401053092306725256, ptr null }, ptr %loaded, align 8
  %noise = call i64 @constant_pair_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %low = load i64, ptr %loaded, align 8
  %next = getelementptr i8, ptr %loaded, i64 8
  %high = load i64, ptr %next, align 8
  %sum = add i64 %low, %high
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @constant_pair_ip_frame(ptr %destination, ptr %slot, i64 %live, ptr %out) {
entry:
  %frame = alloca [48 x i8], align 16
  call void @llvm.memset.p0.i64(ptr %frame, i8 0, i64 48, i1 false)
  store { i64, ptr } { i64 -2401053092306725256, ptr null }, ptr %frame, align 8
  %noise = call i64 @constant_pair_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr %destination, ptr %frame, i64 48, i1 false)
  %low = load i64, ptr %frame, align 8
  %next = getelementptr i8, ptr %frame, i64 8
  %high = load i64, ptr %next, align 8
  %sum = add i64 %low, %high
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @constant_pair_pp_argument(ptr %destination, ptr %slot, i64 %live, ptr %out) {
entry:
  store { ptr, ptr } { ptr null, ptr inttoptr (i64 1 to ptr) }, ptr %destination, align 8
  %noise = call i64 @constant_pair_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %low = load i64, ptr %destination, align 8
  %next = getelementptr i8, ptr %destination, i64 8
  %high = load i64, ptr %next, align 8
  %sum = add i64 %low, %high
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @constant_pair_pp_loaded(ptr %destination, ptr %slot, i64 %live, ptr %out) {
entry:
  %loaded = load ptr, ptr %slot, align 8
  store { ptr, ptr } { ptr null, ptr inttoptr (i64 1 to ptr) }, ptr %loaded, align 8
  %noise = call i64 @constant_pair_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %low = load i64, ptr %loaded, align 8
  %next = getelementptr i8, ptr %loaded, i64 8
  %high = load i64, ptr %next, align 8
  %sum = add i64 %low, %high
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @constant_pair_pp_frame(ptr %destination, ptr %slot, i64 %live, ptr %out) {
entry:
  %frame = alloca [48 x i8], align 16
  call void @llvm.memset.p0.i64(ptr %frame, i8 0, i64 48, i1 false)
  store { ptr, ptr } { ptr null, ptr inttoptr (i64 1 to ptr) }, ptr %frame, align 8
  %noise = call i64 @constant_pair_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr %destination, ptr %frame, i64 48, i1 false)
  %low = load i64, ptr %frame, align 8
  %next = getelementptr i8, ptr %frame, i64 8
  %high = load i64, ptr %next, align 8
  %sum = add i64 %low, %high
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @constant_pair_ii_argument(ptr %destination, ptr %slot, i64 %live, ptr %out) {
entry:
  store { i64, i64 } { i64 -9223372036854775808, i64 4294967296 }, ptr %destination, align 8
  %noise = call i64 @constant_pair_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %low = load i64, ptr %destination, align 8
  %next = getelementptr i8, ptr %destination, i64 8
  %high = load i64, ptr %next, align 8
  %sum = add i64 %low, %high
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @constant_pair_ii_loaded(ptr %destination, ptr %slot, i64 %live, ptr %out) {
entry:
  %loaded = load ptr, ptr %slot, align 8
  store { i64, i64 } { i64 -9223372036854775808, i64 4294967296 }, ptr %loaded, align 8
  %noise = call i64 @constant_pair_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  %low = load i64, ptr %loaded, align 8
  %next = getelementptr i8, ptr %loaded, i64 8
  %high = load i64, ptr %next, align 8
  %sum = add i64 %low, %high
  %answer = xor i64 %sum, %live
  ret i64 %answer
}

define i64 @constant_pair_ii_frame(ptr %destination, ptr %slot, i64 %live, ptr %out) {
entry:
  %frame = alloca [48 x i8], align 16
  call void @llvm.memset.p0.i64(ptr %frame, i8 0, i64 48, i1 false)
  store { i64, i64 } { i64 -9223372036854775808, i64 4294967296 }, ptr %frame, align 8
  %noise = call i64 @constant_pair_clobber(i64 %live)
  store i64 %noise, ptr %out, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr %destination, ptr %frame, i64 48, i1 false)
  %low = load i64, ptr %frame, align 8
  %next = getelementptr i8, ptr %frame, i64 8
  %high = load i64, ptr %next, align 8
  %sum = add i64 %low, %high
  %answer = xor i64 %sum, %live
  ret i64 %answer
}
