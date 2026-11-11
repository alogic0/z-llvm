target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-i128:128-f80:128"
declare i64 @extended80_payload_clobber(i64)
declare x86_fp80 @extended80_call_provider(i64,x86_fp80,i64,i64,i64,i64,i64,i64,x86_fp80,x86_fp80,ptr)
define i128 @extended80_payload_0(ptr %input, ptr %output, i128 %raw, i64 %index, i32 %choice, i64 %live, i64 %extra) {
entry:
 %narrow = trunc i128 %raw to i80
 %from_bits = bitcast i80 %narrow to x86_fp80
 %cond = icmp ne i32 %choice, 0
 %loaded = load x86_fp80, ptr %input, align 1
 %stable = freeze x86_fp80 %loaded
 %probe = call i64 @extended80_payload_clobber(i64 %live)
 store x86_fp80 %stable, ptr %output, align 1
 %next = getelementptr i8, ptr %output, i64 10
 store x86_fp80 %stable, ptr %next, align 1
 %bits = bitcast x86_fp80 %stable to i80
 %wide = zext i80 %bits to i128
 %one = xor i64 %probe, %extra
 %two = add i64 %one, %index
 %choice64 = zext i32 %choice to i64
 %mixed = xor i64 %two, %choice64
 %mask = zext i64 %mixed to i128
 %with_raw = xor i128 %wide, %raw
 %answer = xor i128 %with_raw, %mask
 ret i128 %answer
}
define i128 @extended80_payload_1(ptr %input, ptr %output, i128 %raw, i64 %index, i32 %choice, i64 %live, i64 %extra) {
entry:
 %narrow = trunc i128 %raw to i80
 %from_bits = bitcast i80 %narrow to x86_fp80
 %cond = icmp ne i32 %choice, 0
 %address = getelementptr x86_fp80, ptr %input, i64 %index
 %loaded = load x86_fp80, ptr %address, align 1
 %stable = freeze x86_fp80 %loaded
 %probe = call i64 @extended80_payload_clobber(i64 %live)
 store x86_fp80 %stable, ptr %output, align 1
 %next = getelementptr i8, ptr %output, i64 10
 store x86_fp80 %stable, ptr %next, align 1
 %bits = bitcast x86_fp80 %stable to i80
 %wide = zext i80 %bits to i128
 %one = xor i64 %probe, %extra
 %two = add i64 %one, %index
 %choice64 = zext i32 %choice to i64
 %mixed = xor i64 %two, %choice64
 %mask = zext i64 %mixed to i128
 %with_raw = xor i128 %wide, %raw
 %answer = xor i128 %with_raw, %mask
 ret i128 %answer
}
define i128 @extended80_payload_2(ptr %input, ptr %output, i128 %raw, i64 %index, i32 %choice, i64 %live, i64 %extra) {
entry:
 %narrow = trunc i128 %raw to i80
 %from_bits = bitcast i80 %narrow to x86_fp80
 %cond = icmp ne i32 %choice, 0
 %loaded = load x86_fp80, ptr %input, align 1
 %slot = alloca x86_fp80, align 16
 store x86_fp80 %loaded, ptr %slot, align 16
 %owned = load x86_fp80, ptr %slot, align 16
 %stable = freeze x86_fp80 %owned
 %probe = call i64 @extended80_payload_clobber(i64 %live)
 store x86_fp80 %stable, ptr %output, align 1
 %next = getelementptr i8, ptr %output, i64 10
 store x86_fp80 %stable, ptr %next, align 1
 %bits = bitcast x86_fp80 %stable to i80
 %wide = zext i80 %bits to i128
 %one = xor i64 %probe, %extra
 %two = add i64 %one, %index
 %choice64 = zext i32 %choice to i64
 %mixed = xor i64 %two, %choice64
 %mask = zext i64 %mixed to i128
 %with_raw = xor i128 %wide, %raw
 %answer = xor i128 %with_raw, %mask
 ret i128 %answer
}
define i128 @extended80_payload_3(ptr %input, ptr %output, i128 %raw, i64 %index, i32 %choice, i64 %live, i64 %extra) {
entry:
 %narrow = trunc i128 %raw to i80
 %from_bits = bitcast i80 %narrow to x86_fp80
 %cond = icmp ne i32 %choice, 0
 %loaded = load x86_fp80, ptr %input, align 1
 %chosen = select i1 %cond, x86_fp80 %loaded, x86_fp80 %from_bits
 %stable = freeze x86_fp80 %chosen
 %probe = call i64 @extended80_payload_clobber(i64 %live)
 store x86_fp80 %stable, ptr %output, align 1
 %next = getelementptr i8, ptr %output, i64 10
 store x86_fp80 %stable, ptr %next, align 1
 %bits = bitcast x86_fp80 %stable to i80
 %wide = zext i80 %bits to i128
 %one = xor i64 %probe, %extra
 %two = add i64 %one, %index
 %choice64 = zext i32 %choice to i64
 %mixed = xor i64 %two, %choice64
 %mask = zext i64 %mixed to i128
 %with_raw = xor i128 %wide, %raw
 %answer = xor i128 %with_raw, %mask
 ret i128 %answer
}
define i128 @extended80_payload_4(ptr %input, ptr %output, i128 %raw, i64 %index, i32 %choice, i64 %live, i64 %extra) {
entry:
 %narrow = trunc i128 %raw to i80
 %from_bits = bitcast i80 %narrow to x86_fp80
 %cond = icmp ne i32 %choice, 0
 %loaded = load x86_fp80, ptr %input, align 1
 br i1 %cond, label %left, label %right
left:
 br label %join
right:
 br label %join
join:
 %merged = phi x86_fp80 [ %loaded, %left ], [ %from_bits, %right ]
 %stable = freeze x86_fp80 %merged
 %probe = call i64 @extended80_payload_clobber(i64 %live)
 store x86_fp80 %stable, ptr %output, align 1
 %next = getelementptr i8, ptr %output, i64 10
 store x86_fp80 %stable, ptr %next, align 1
 %bits = bitcast x86_fp80 %stable to i80
 %wide = zext i80 %bits to i128
 %one = xor i64 %probe, %extra
 %two = add i64 %one, %index
 %choice64 = zext i32 %choice to i64
 %mixed = xor i64 %two, %choice64
 %mask = zext i64 %mixed to i128
 %with_raw = xor i128 %wide, %raw
 %answer = xor i128 %with_raw, %mask
 ret i128 %answer
}
define i128 @extended80_payload_5(ptr %input, ptr %output, i128 %raw, i64 %index, i32 %choice, i64 %live, i64 %extra) {
entry:
 %narrow = trunc i128 %raw to i80
 %from_bits = bitcast i80 %narrow to x86_fp80
 %cond = icmp ne i32 %choice, 0
 %stable = freeze x86_fp80 poison
 %probe = call i64 @extended80_payload_clobber(i64 %live)
 store x86_fp80 %stable, ptr %output, align 1
 %next = getelementptr i8, ptr %output, i64 10
 store x86_fp80 %stable, ptr %next, align 1
 %bits = bitcast x86_fp80 %stable to i80
 %wide = zext i80 %bits to i128
 %one = xor i64 %probe, %extra
 %two = add i64 %one, %index
 %choice64 = zext i32 %choice to i64
 %mixed = xor i64 %two, %choice64
 %mask = zext i64 %mixed to i128
 %with_raw = xor i128 %wide, %raw
 %answer = xor i128 %with_raw, %mask
 ret i128 %answer
}
define i128 @extended80_payload_6(ptr %input, ptr %output, i128 %raw, i64 %index, i32 %choice, i64 %live, i64 %extra) {
entry:
 %narrow = trunc i128 %raw to i80
 %from_bits = bitcast i80 %narrow to x86_fp80
 %cond = icmp ne i32 %choice, 0
 %stable = freeze x86_fp80 undef
 %probe = call i64 @extended80_payload_clobber(i64 %live)
 store x86_fp80 %stable, ptr %output, align 1
 %next = getelementptr i8, ptr %output, i64 10
 store x86_fp80 %stable, ptr %next, align 1
 %bits = bitcast x86_fp80 %stable to i80
 %wide = zext i80 %bits to i128
 %one = xor i64 %probe, %extra
 %two = add i64 %one, %index
 %choice64 = zext i32 %choice to i64
 %mixed = xor i64 %two, %choice64
 %mask = zext i64 %mixed to i128
 %with_raw = xor i128 %wide, %raw
 %answer = xor i128 %with_raw, %mask
 ret i128 %answer
}
define i128 @extended80_payload_7(ptr %input, ptr %output, i128 %raw, i64 %index, i32 %choice, i64 %live, i64 %extra) {
entry:
 %narrow = trunc i128 %raw to i80
 %from_bits = bitcast i80 %narrow to x86_fp80
 %cond = icmp ne i32 %choice, 0
 %stable = freeze x86_fp80 0xK7FFF8000000000000001
 %probe = call i64 @extended80_payload_clobber(i64 %live)
 store x86_fp80 %stable, ptr %output, align 1
 %next = getelementptr i8, ptr %output, i64 10
 store x86_fp80 %stable, ptr %next, align 1
 %bits = bitcast x86_fp80 %stable to i80
 %wide = zext i80 %bits to i128
 %one = xor i64 %probe, %extra
 %two = add i64 %one, %index
 %choice64 = zext i32 %choice to i64
 %mixed = xor i64 %two, %choice64
 %mask = zext i64 %mixed to i128
 %with_raw = xor i128 %wide, %raw
 %answer = xor i128 %with_raw, %mask
 ret i128 %answer
}
define i128 @extended80_incoming(i64 %a, x86_fp80 %x, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, x86_fp80 %y, ptr %output) {
entry:
 %probe = call i64 @extended80_payload_clobber(i64 %a)
 store x86_fp80 %x, ptr %output, align 1
 %next = getelementptr i8, ptr %output, i64 10
 store x86_fp80 %y, ptr %next, align 1
 %xb = bitcast x86_fp80 %x to i80
 %yb = bitcast x86_fp80 %y to i80
 %xw = zext i80 %xb to i128
 %yw = zext i80 %yb to i128
 %one = xor i64 %probe, %b
 %two = add i64 %one, %c
 %three = xor i64 %two, %d
 %four = add i64 %three, %e
 %five = xor i64 %four, %f
 %six = add i64 %five, %g
 %mask = zext i64 %six to i128
 %xy = xor i128 %xw, %yw
 %answer = xor i128 %xy, %mask
 ret i128 %answer
}
define x86_fp80 @extended80_return_load(ptr %input, ptr %output, i64 %live) {
entry:
 %value = load x86_fp80, ptr %input, align 1
 %probe = call i64 @extended80_payload_clobber(i64 %live)
 store i64 %probe, ptr %output, align 1
 ret x86_fp80 %value
}
define x86_fp80 @extended80_return_phi(i64 %live, x86_fp80 %x, x86_fp80 %y, i32 %choice, ptr %output) {
entry:
 %cond = icmp ne i32 %choice, 0
 br i1 %cond, label %left, label %right
left:
 br label %join
right:
 br label %join
join:
 %value = phi x86_fp80 [ %x, %left ], [ %y, %right ]
 %probe = call i64 @extended80_payload_clobber(i64 %live)
 store i64 %probe, ptr %output, align 1
 ret x86_fp80 %value
}
define x86_fp80 @extended80_return_constant(ptr %output, i64 %live) {
entry:
 %probe = call i64 @extended80_payload_clobber(i64 %live)
 store i64 %probe, ptr %output, align 1
 ret x86_fp80 0xK7FFF8000000000000001
}
define i128 @extended80_call(ptr %input, ptr %output, i128 %raw, i64 %index, i32 %choice, i64 %live, i64 %extra) {
entry:
 %narrow = trunc i128 %raw to i80
 %z = bitcast i80 %narrow to x86_fp80
 %x = load x86_fp80, ptr %input, align 1
 %next = getelementptr i8, ptr %input, i64 16
 %y = load x86_fp80, ptr %next, align 1
 %r = call x86_fp80 @extended80_call_provider(i64 %live,x86_fp80 %x,i64 %index,i64 %extra,i64 %live,i64 %index,i64 %extra,i64 %live,x86_fp80 %y,x86_fp80 %z,ptr %output)
 %second = getelementptr i8, ptr %output, i64 10
 %ignored = call x86_fp80 @extended80_call_provider(i64 %extra,x86_fp80 %z,i64 %index,i64 %live,i64 %extra,i64 %index,i64 %live,i64 %extra,x86_fp80 %x,x86_fp80 %y,ptr %second)
 %probe = call i64 @extended80_payload_clobber(i64 %live)
 %third = getelementptr i8, ptr %output, i64 20
 store x86_fp80 %r, ptr %third, align 1
 %bits = bitcast x86_fp80 %r to i80
 %wide = zext i80 %bits to i128
 %one = xor i64 %probe, %extra
 %two = add i64 %one, %index
 %choice64 = zext i32 %choice to i64
 %mixed = xor i64 %two, %choice64
 %mask = zext i64 %mixed to i128
 %with_raw = xor i128 %wide, %raw
 %answer = xor i128 %with_raw, %mask
 ret i128 %answer
}
