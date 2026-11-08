target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
declare noundef i33 @wide_dirty33(i33, i37)
declare noundef i37 @wide_dirty37(i37)
declare noundef i49 @wide_dirty49(i33, i37, i49, i63)
declare noundef i49 @wide_dirty_stack(i33, i37, i49, i63, i8, i64, i49, i37)
declare noundef range(i63 0, 16) i63 @wide_dirty63(i63)

define noundef i33 @wide_abi_entry33(i33 noundef %a, ptr %output, i64 %live) {
entry:
  %value = zext i33 %a to i64
  %stored = xor i64 %value, %live
  store i64 %stored, ptr %output, align 8
  ret i33 %a
}

define noundef i49 @wide_abi_call49(i33 %a, i37 %b, i49 %c, i63 %d, i64 %live, ptr %output) {
entry:
  %r = call noundef i49 @wide_dirty49(i33 noundef %a, i37 noundef %b, i49 noundef %c, i63 noundef %d)
  %value = zext i49 %r to i64
  %av = zext i33 %a to i64
  %bv = zext i37 %b to i64
  %cv = zext i49 %c to i64
  %dv = zext i63 %d to i64
  %ab = xor i64 %av, %bv
  %cd = xor i64 %cv, %dv
  %abcd = xor i64 %ab, %cd
  %salted = xor i64 %abcd, %live
  %stored = xor i64 %salted, %value
  store i64 %stored, ptr %output, align 8
  ret i49 %r
}

define noundef i33 @wide_abi_call33(i33 %a, i37 %b, i49 %c, i63 %d, i64 %live, ptr %output) {
entry:
  %r = call noundef i33 @wide_dirty33(i33 noundef %a, i37 -1)
  %value = zext i33 %r to i64
  %av = zext i33 %a to i64
  %bv = zext i37 %b to i64
  %cv = zext i49 %c to i64
  %dv = zext i63 %d to i64
  %ab = xor i64 %av, %bv
  %cd = xor i64 %cv, %dv
  %abcd = xor i64 %ab, %cd
  %salted = xor i64 %abcd, %live
  %stored = xor i64 %salted, %value
  store i64 %stored, ptr %output, align 8
  ret i33 %r
}

define noundef i37 @wide_abi_stack37(i33 %a, i37 %b, i49 %c, i63 %d, i8 %e, i64 %live, i49 %g, i37 %h, ptr %output) {
entry:
  %r = call noundef i49 @wide_dirty_stack(i33 noundef %a, i37 noundef %b, i49 noundef %c, i63 noundef %d, i8 noundef %e, i64 %live, i49 noundef %g, i37 noundef %h)
  %value = zext i49 %r to i64
  %stored = xor i64 %value, %live
  store i64 %stored, ptr %output, align 8
  %result = trunc i49 %r to i37
  ret i37 %result
}

define noundef i37 @wide_abi_phi37(i49 %a, i63 %b, i64 %take, i64 %live, ptr %output) {
entry:
  %condition = icmp ne i64 %take, 0
  %av = trunc i49 %a to i37
  %bv = trunc i63 %b to i37
  br i1 %condition, label %left, label %right
left:
  br label %join
right:
  br label %join
join:
  %value = phi i37 [ %av, %left ], [ %bv, %right ]
  %r = call noundef i37 @wide_dirty37(i37 %value)
  %wide = zext i37 %r to i64
  %aw = zext i49 %a to i64
  %bw = zext i63 %b to i64
  %ab = xor i64 %aw, %bw
  %salted = xor i64 %ab, %live
  %stored = xor i64 %salted, %wide
  store i64 %stored, ptr %output, align 8
  ret i37 %r
}

define noundef range(i63 0, 16) i63 @wide_abi_range63(i63 noundef range(i63 -16, 16) %a, i64 %live, ptr %output) {
entry:
  %r = call noundef range(i63 0, 16) i63 @wide_dirty63(i63 noundef range(i63 -16, 16) %a)
  %av = zext i63 %a to i64
  %value = zext i63 %r to i64
  %salted = xor i64 %av, %live
  %stored = xor i64 %salted, %value
  store i64 %stored, ptr %output, align 8
  ret i63 %r
}
