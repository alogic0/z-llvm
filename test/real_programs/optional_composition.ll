target triple = "x86_64-unknown-linux-gnu"

define i32 @runtime_optional_pointer_main.optionalPtrValue(ptr %0) {
1:
  %2 = icmp ne ptr %0, null
  br i1 %2, label %4, label %3
3:
  ret i32 -1
4:
  %5 = load i32, ptr %0, align 4
  ret i32 %5
}

define i32 @optional_phi_adjust(ptr %payload) {
entry:
  %absent = icmp eq ptr %payload, null
  br i1 %absent, label %merge, label %read
merge:
  %answer = phi i32 [ -1, %entry ], [ %adjusted, %read ]
  ret i32 %answer
read:
  %value = load i32, ptr %payload, align 4
  %adjusted = add i32 %value, 8
  br label %merge
}

define i32 @renamed_optional_read(ptr %payload, i32 %salt, i32 %bias) {
start:
  %nonnull = icmp ne ptr %payload, null
  %independent = add i32 %salt, 17
  %noise = xor i32 %salt, %bias
  br i1 %nonnull, label %present, label %absent
absent:
  %fallback = xor i32 -1, %noise
  ret i32 %fallback
present:
  %value = load i32, ptr %payload, align 4
  %adjusted = add i32 %value, %independent
  %answer = xor i32 %adjusted, %noise
  ret i32 %answer
}

define i32 @optional_live_pressure(ptr %payload, i32 %a, i32 %b, i32 %c, i32 %d, i32 %e) {
entry:
  %r0 = add i32 %a, 11
  %r1 = add i32 %b, 13
  %r2 = xor i32 %c, 22136
  %r3 = add i32 %d, 17
  %r4 = xor i32 %e, 39612
  %r5 = mul i32 %a, 7
  %r6 = xor i32 %b, %d
  %r7 = add i32 %c, %e
  %missing = icmp eq ptr %payload, null
  br i1 %missing, label %merge, label %read
read:
  %loaded = load i32, ptr %payload, align 4
  br label %merge
merge:
  %value = phi i32 [ -1, %entry ], [ %loaded, %read ]
  %t0 = add i32 %value, %r0
  %t1 = xor i32 %t0, %r1
  %t2 = add i32 %t1, %r2
  %t3 = xor i32 %t2, %r3
  %t4 = add i32 %t3, %r4
  %t5 = xor i32 %t4, %r5
  %t6 = add i32 %t5, %r6
  %answer = xor i32 %t6, %r7
  ret i32 %answer
}
