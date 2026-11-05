target triple = "x86_64-unknown-linux-gnu"

declare { i64, i1 } @llvm.uadd.with.overflow.i64(i64, i64)

declare { i64, i1 } @llvm.usub.with.overflow.i64(i64, i64)

declare ptr @llvm.returnaddress(i32)

declare void @safe_scalar_touch(ptr)

define i64 @safe_mask_32(i64 %input, ptr %out) {
entry:
  %live = xor i64 %input, 55
  %narrow = trunc i64 %input to i31
  %extended = zext i31 %narrow to i32
  %wide = zext i32 %extended to i64
  store i64 %wide, ptr %out, align 8
  ret i64 %live
}


define i64 @safe_mask_64(i64 %input, ptr %out) {
entry:
  %live = xor i64 %input, 55
  %narrow = trunc i64 %input to i31
  %extended = zext i31 %narrow to i64
  store i64 %extended, ptr %out, align 8
  ret i64 %live
}


define i64 @safe_uadd_named(i64 %a, i64 %b, ptr %out) {
entry:
  %pair = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %a, i64 %b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %wrapped = extractvalue { i64, i1 } %pair, 0
  store i64 %wrapped, ptr %out, align 8
  %second = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %a, %b
  store i64 %live, ptr %second, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @safe_uadd_max(i64 %a, i64 %b, ptr %out) {
entry:
  %pair = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %a, i64 -1)
  %flag = extractvalue { i64, i1 } %pair, 1
  %wrapped = extractvalue { i64, i1 } %pair, 0
  store i64 %wrapped, ptr %out, align 8
  %second = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %a, %b
  store i64 %live, ptr %second, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @safe_uadd_high(i64 %a, i64 %b, ptr %out) {
entry:
  %pair = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %a, i64 9223372036854775808)
  %flag = extractvalue { i64, i1 } %pair, 1
  %wrapped = extractvalue { i64, i1 } %pair, 0
  store i64 %wrapped, ptr %out, align 8
  %second = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %a, %b
  store i64 %live, ptr %second, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @safe_usub_named(i64 %a, i64 %b, ptr %out) {
entry:
  %pair = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %a, i64 %b)
  %flag = extractvalue { i64, i1 } %pair, 1
  %wrapped = extractvalue { i64, i1 } %pair, 0
  store i64 %wrapped, ptr %out, align 8
  %second = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %a, %b
  store i64 %live, ptr %second, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @safe_usub_max(i64 %a, i64 %b, ptr %out) {
entry:
  %pair = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %a, i64 -1)
  %flag = extractvalue { i64, i1 } %pair, 1
  %wrapped = extractvalue { i64, i1 } %pair, 0
  store i64 %wrapped, ptr %out, align 8
  %second = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %a, %b
  store i64 %live, ptr %second, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @safe_usub_high(i64 %a, i64 %b, ptr %out) {
entry:
  %pair = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %a, i64 9223372036854775808)
  %flag = extractvalue { i64, i1 } %pair, 1
  %wrapped = extractvalue { i64, i1 } %pair, 0
  store i64 %wrapped, ptr %out, align 8
  %second = getelementptr i8, ptr %out, i64 8
  %live = xor i64 %a, %b
  store i64 %live, ptr %second, align 8
  %result = zext i1 %flag to i64
  ret i64 %result
}


define i64 @safe_null_eq(ptr %input) {
entry:
  %c = icmp eq ptr null, %input
  %r = zext i1 %c to i64
  ret i64 %r
}


define i64 @safe_null_ne(ptr %input) {
entry:
  %c = icmp ne ptr null, %input
  %r = zext i1 %c to i64
  ret i64 %r
}


define ptr @safe_ra_plain() {
entry:
  %r = call ptr @llvm.returnaddress(i32 0)
  ret ptr %r
}


define ptr @safe_ra_frame(i64 %input, ptr %out) {
entry:
  %slot = alloca i64, align 8
  store i64 %input, ptr %slot, align 8
  %before = call ptr @llvm.returnaddress(i32 0)
  call void @safe_scalar_touch(ptr %slot)
  %after = call ptr @llvm.returnaddress(i32 0)
  %value = load i64, ptr %slot, align 8
  store i64 %value, ptr %out, align 8
  %same = icmp eq ptr %before, %after
  br i1 %same, label %ok, label %bad
ok:
  ret ptr %after
bad:
  ret ptr null
}


define i64 @safe_unreachable_branch(i64 %x) {
entry:
  %c = icmp ne i64 %x, 0
  br i1 %c, label %ok, label %bad
ok:
  %r = xor i64 %x, 55
  ret i64 %r
bad:
  unreachable
}

