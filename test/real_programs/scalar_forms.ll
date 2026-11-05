target triple = "x86_64-unknown-linux-gnu"
declare i64 @llvm.umin.i64(i64, i64)
declare i32 @llvm.umin.i32(i32, i32)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

define i64 @forms_min64(i64 %a, i64 %b, ptr %output) {
entry:
  %minimum = call i64 @llvm.umin.i64(i64 %a, i64 %b)
  store i64 %minimum, ptr %output
  %live = xor i64 %a, %b
  ret i64 %live
}

define i32 @forms_min32(i32 %a, i32 %b) {
entry:
  %minimum = call i32 @llvm.umin.i32(i32 %a, i32 %b)
  ret i32 %minimum
}

define i64 @forms_min_loaded(ptr %a, ptr %b) {
entry:
  %x = load i64, ptr %a, align 8
  %y = load i64, ptr %b, align 8
  %minimum = call i64 @llvm.umin.i64(i64 %x, i64 %y)
  ret i64 %minimum
}

define i32 @forms_le32(i32 %x) {
entry:
  %comparison = icmp sle i32 %x, 65535
  %result = zext i1 %comparison to i32
  ret i32 %result
}

define i32 @forms_le64(i64 %x) {
entry:
  %comparison = icmp sle i64 %x, 65535
  %result = zext i1 %comparison to i32
  ret i32 %result
}

define i32 @forms_le_named64(i64 %x, i64 %y) {
entry:
  %comparison = icmp sle i64 %x, %y
  %result = zext i1 %comparison to i32
  ret i32 %result
}

define i32 @forms_switch(i32 %x) {
entry:
  switch i32 %x, label %merge [
    i32 0, label %merge
    i32 1, label %one
    i32 2, label %merge
  ]
one:
  %value = add i32 %x, 7
  br label %merge
merge:
  %result = phi i32 [ 55, %entry ], [ 55, %entry ], [ 55, %entry ], [ %value, %one ]
  ret i32 %result
}

define i64 @forms_memset_undef(ptr %output, i64 %a, i64 %b) {
entry:
  call void @llvm.memset.p0.i64(ptr align 8 %output, i8 undef, i64 16, i1 false)
  %second = getelementptr i8, ptr %output, i64 8
  store i64 %a, ptr %output, align 8
  store i64 %b, ptr %second, align 8
  %result = xor i64 %a, %b
  ret i64 %result
}

define i64 @forms_memset_stack16(i64 %a, i64 %b) {
entry:
  %slot = alloca { i64, i64 }, align 8
  call void @llvm.memset.p0.i64(ptr align 8 %slot, i8 undef, i64 16, i1 false)
  %second = getelementptr i8, ptr %slot, i64 8
  store i64 %a, ptr %slot, align 8
  store i64 %b, ptr %second, align 8
  %x = load i64, ptr %slot, align 8
  %y = load i64, ptr %second, align 8
  %result = xor i64 %x, %y
  ret i64 %result
}

define void @forms_memset_stack24(ptr %output) {
entry:
  %slot = alloca { [3 x i64] }, align 8
  call void @llvm.memset.p0.i64(ptr align 8 %slot, i8 -91, i64 24, i1 false)
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %output, ptr align 8 %slot, i64 24, i1 false)
  ret void
}
