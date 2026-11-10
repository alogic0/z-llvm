; Integer/flag SSA transport: original producers, parallel PHIs, stable freezes.
target triple = "x86_64-unknown-linux-gnu"

declare i64 @flag_pair_clobber(i64)

declare { i8, i1 } @llvm.uadd.with.overflow.i8(i8, i8)
declare { i8, i1 } @llvm.usub.with.overflow.i8(i8, i8)

define i64 @flag_pair_overflow8(i64 %a64, i64 %b64, i64 %salt, ptr %out) {
entry:
  %a = trunc i64 %a64 to i8
  %b = trunc i64 %b64 to i8
  %bit = and i64 %salt, 1
  %choose = icmp ne i64 %bit, 0
  %shift = lshr i64 %salt, 1
  %count = and i64 %shift, 7
  br i1 %choose, label %add, label %subtract
add:
  %sum = call { i8, i1 } @llvm.uadd.with.overflow.i8(i8 %a, i8 %b)
  br label %join
subtract:
  %difference = call { i8, i1 } @llvm.usub.with.overflow.i8(i8 %a, i8 %b)
  br label %join
join:
  %initial = phi { i8, i1 } [ %sum, %add ], [ %difference, %subtract ]
  br label %loop
loop:
  %x = phi { i8, i1 } [ %initial, %join ], [ %y, %body ]
  %y = phi { i8, i1 } [ { i8 17, i1 true }, %join ], [ %x, %body ]
  %i = phi i64 [ 0, %join ], [ %next, %body ]
  %done = icmp eq i64 %i, %count
  br i1 %done, label %exit, label %body
body:
  %next = add i64 %i, 1
  br label %loop
exit:
  %stable = freeze { i8, i1 } %x
  %clobber = call i64 @flag_pair_clobber(i64 %salt)
  %flag = extractvalue { i8, i1 } %stable, 1
  %value = extractvalue { i8, i1 } %stable, 0
  %low = zext i8 %value to i64
  %high = add i64 0, 0
  %flag64 = zext i1 %flag to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %flag64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r1 = xor i64 %low, %high
  %r2 = xor i64 %r1, %flag64
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

declare { i16, i1 } @llvm.uadd.with.overflow.i16(i16, i16)
declare { i16, i1 } @llvm.usub.with.overflow.i16(i16, i16)

define i64 @flag_pair_overflow16(i64 %a64, i64 %b64, i64 %salt, ptr %out) {
entry:
  %a = trunc i64 %a64 to i16
  %b = trunc i64 %b64 to i16
  %bit = and i64 %salt, 1
  %choose = icmp ne i64 %bit, 0
  %shift = lshr i64 %salt, 1
  %count = and i64 %shift, 7
  br i1 %choose, label %add, label %subtract
add:
  %sum = call { i16, i1 } @llvm.uadd.with.overflow.i16(i16 %a, i16 %b)
  br label %join
subtract:
  %difference = call { i16, i1 } @llvm.usub.with.overflow.i16(i16 %a, i16 %b)
  br label %join
join:
  %initial = phi { i16, i1 } [ %sum, %add ], [ %difference, %subtract ]
  br label %loop
loop:
  %x = phi { i16, i1 } [ %initial, %join ], [ %y, %body ]
  %y = phi { i16, i1 } [ { i16 17, i1 true }, %join ], [ %x, %body ]
  %i = phi i64 [ 0, %join ], [ %next, %body ]
  %done = icmp eq i64 %i, %count
  br i1 %done, label %exit, label %body
body:
  %next = add i64 %i, 1
  br label %loop
exit:
  %stable = freeze { i16, i1 } %x
  %clobber = call i64 @flag_pair_clobber(i64 %salt)
  %flag = extractvalue { i16, i1 } %stable, 1
  %value = extractvalue { i16, i1 } %stable, 0
  %low = zext i16 %value to i64
  %high = add i64 0, 0
  %flag64 = zext i1 %flag to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %flag64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r1 = xor i64 %low, %high
  %r2 = xor i64 %r1, %flag64
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

declare { i32, i1 } @llvm.uadd.with.overflow.i32(i32, i32)
declare { i32, i1 } @llvm.usub.with.overflow.i32(i32, i32)

define i64 @flag_pair_overflow32(i64 %a64, i64 %b64, i64 %salt, ptr %out) {
entry:
  %a = trunc i64 %a64 to i32
  %b = trunc i64 %b64 to i32
  %bit = and i64 %salt, 1
  %choose = icmp ne i64 %bit, 0
  %shift = lshr i64 %salt, 1
  %count = and i64 %shift, 7
  br i1 %choose, label %add, label %subtract
add:
  %sum = call { i32, i1 } @llvm.uadd.with.overflow.i32(i32 %a, i32 %b)
  br label %join
subtract:
  %difference = call { i32, i1 } @llvm.usub.with.overflow.i32(i32 %a, i32 %b)
  br label %join
join:
  %initial = phi { i32, i1 } [ %sum, %add ], [ %difference, %subtract ]
  br label %loop
loop:
  %x = phi { i32, i1 } [ %initial, %join ], [ %y, %body ]
  %y = phi { i32, i1 } [ { i32 17, i1 true }, %join ], [ %x, %body ]
  %i = phi i64 [ 0, %join ], [ %next, %body ]
  %done = icmp eq i64 %i, %count
  br i1 %done, label %exit, label %body
body:
  %next = add i64 %i, 1
  br label %loop
exit:
  %stable = freeze { i32, i1 } %x
  %clobber = call i64 @flag_pair_clobber(i64 %salt)
  %flag = extractvalue { i32, i1 } %stable, 1
  %value = extractvalue { i32, i1 } %stable, 0
  %low = zext i32 %value to i64
  %high = add i64 0, 0
  %flag64 = zext i1 %flag to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %flag64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r1 = xor i64 %low, %high
  %r2 = xor i64 %r1, %flag64
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

declare { i64, i1 } @llvm.uadd.with.overflow.i64(i64, i64)
declare { i64, i1 } @llvm.usub.with.overflow.i64(i64, i64)

define i64 @flag_pair_overflow64(i64 %a64, i64 %b64, i64 %salt, ptr %out) {
entry:
  %a = add i64 %a64, 0
  %b = add i64 %b64, 0
  %bit = and i64 %salt, 1
  %choose = icmp ne i64 %bit, 0
  %shift = lshr i64 %salt, 1
  %count = and i64 %shift, 7
  br i1 %choose, label %add, label %subtract
add:
  %sum = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %a, i64 %b)
  br label %join
subtract:
  %difference = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %a, i64 %b)
  br label %join
join:
  %initial = phi { i64, i1 } [ %sum, %add ], [ %difference, %subtract ]
  br label %loop
loop:
  %x = phi { i64, i1 } [ %initial, %join ], [ %y, %body ]
  %y = phi { i64, i1 } [ { i64 17, i1 true }, %join ], [ %x, %body ]
  %i = phi i64 [ 0, %join ], [ %next, %body ]
  %done = icmp eq i64 %i, %count
  br i1 %done, label %exit, label %body
body:
  %next = add i64 %i, 1
  br label %loop
exit:
  %stable = freeze { i64, i1 } %x
  %clobber = call i64 @flag_pair_clobber(i64 %salt)
  %flag = extractvalue { i64, i1 } %stable, 1
  %value = extractvalue { i64, i1 } %stable, 0
  %low = add i64 %value, 0
  %high = add i64 0, 0
  %flag64 = zext i1 %flag to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %flag64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r1 = xor i64 %low, %high
  %r2 = xor i64 %r1, %flag64
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

declare { i128, i1 } @llvm.uadd.with.overflow.i128(i128, i128)
declare { i128, i1 } @llvm.usub.with.overflow.i128(i128, i128)

define i64 @flag_pair_overflow128(i64 %a64, i64 %b64, i64 %salt, ptr %out) {
entry:
  %al = zext i64 %a64 to i128
  %ah = zext i64 %b64 to i128
  %ash = shl i128 %ah, 64
  %a = or i128 %al, %ash
  %bl = zext i64 %b64 to i128
  %bh = zext i64 %a64 to i128
  %bsh = shl i128 %bh, 64
  %b = or i128 %bl, %bsh
  %bit = and i64 %salt, 1
  %choose = icmp ne i64 %bit, 0
  %shift = lshr i64 %salt, 1
  %count = and i64 %shift, 7
  br i1 %choose, label %add, label %subtract
add:
  %sum = call { i128, i1 } @llvm.uadd.with.overflow.i128(i128 %a, i128 %b)
  br label %join
subtract:
  %difference = call { i128, i1 } @llvm.usub.with.overflow.i128(i128 %a, i128 %b)
  br label %join
join:
  %initial = phi { i128, i1 } [ %sum, %add ], [ %difference, %subtract ]
  br label %loop
loop:
  %x = phi { i128, i1 } [ %initial, %join ], [ %y, %body ]
  %y = phi { i128, i1 } [ { i128 17, i1 true }, %join ], [ %x, %body ]
  %i = phi i64 [ 0, %join ], [ %next, %body ]
  %done = icmp eq i64 %i, %count
  br i1 %done, label %exit, label %body
body:
  %next = add i64 %i, 1
  br label %loop
exit:
  %stable = freeze { i128, i1 } %x
  %clobber = call i64 @flag_pair_clobber(i64 %salt)
  %flag = extractvalue { i128, i1 } %stable, 1
  %value = extractvalue { i128, i1 } %stable, 0
  %low = trunc i128 %value to i64
  %upper = lshr i128 %value, 64
  %high = trunc i128 %upper to i64
  %flag64 = zext i1 %flag to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %high, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %flag64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r1 = xor i64 %low, %high
  %r2 = xor i64 %r1, %flag64
  %result = xor i64 %r2, %clobber
  ret i64 %result
}

define i64 @flag_pair_atomic8(i64 %a64, i64 %b64, i64 %salt, ptr %out) {
entry:
  %a = trunc i64 %a64 to i8
  %b = trunc i64 %b64 to i8
  %cell = getelementptr i8, ptr %out, i64 32
  %bit = and i64 %salt, 1
  %choose = icmp ne i64 %bit, 0
  br i1 %choose, label %left, label %right
left:
  %a_pair = cmpxchg volatile ptr %cell, i8 %a, i8 %b syncscope("singlethread") seq_cst seq_cst, align 1
  br label %join
right:
  %b_pair = cmpxchg ptr %cell, i8 %b, i8 %a acquire monotonic, align 1
  br label %join
join:
  %pair = phi { i8, i1 } [ %a_pair, %left ], [ %b_pair, %right ]
  %stable = freeze { i8, i1 } %pair
  %clobber = call i64 @flag_pair_clobber(i64 %salt)
  %flag = extractvalue { i8, i1 } %stable, 1
  %value = extractvalue { i8, i1 } %stable, 0
  %low = zext i8 %value to i64
  %flag64 = zext i1 %flag to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 0, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %flag64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r1 = xor i64 %low, %flag64
  %result = xor i64 %r1, %clobber
  ret i64 %result
}

define i64 @flag_pair_atomic16(i64 %a64, i64 %b64, i64 %salt, ptr %out) {
entry:
  %a = trunc i64 %a64 to i16
  %b = trunc i64 %b64 to i16
  %cell = getelementptr i8, ptr %out, i64 32
  %bit = and i64 %salt, 1
  %choose = icmp ne i64 %bit, 0
  br i1 %choose, label %left, label %right
left:
  %a_pair = cmpxchg volatile ptr %cell, i16 %a, i16 %b syncscope("singlethread") seq_cst seq_cst, align 2
  br label %join
right:
  %b_pair = cmpxchg ptr %cell, i16 %b, i16 %a acquire monotonic, align 2
  br label %join
join:
  %pair = phi { i16, i1 } [ %a_pair, %left ], [ %b_pair, %right ]
  %stable = freeze { i16, i1 } %pair
  %clobber = call i64 @flag_pair_clobber(i64 %salt)
  %flag = extractvalue { i16, i1 } %stable, 1
  %value = extractvalue { i16, i1 } %stable, 0
  %low = zext i16 %value to i64
  %flag64 = zext i1 %flag to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 0, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %flag64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r1 = xor i64 %low, %flag64
  %result = xor i64 %r1, %clobber
  ret i64 %result
}

define i64 @flag_pair_atomic32(i64 %a64, i64 %b64, i64 %salt, ptr %out) {
entry:
  %a = trunc i64 %a64 to i32
  %b = trunc i64 %b64 to i32
  %cell = getelementptr i8, ptr %out, i64 32
  %bit = and i64 %salt, 1
  %choose = icmp ne i64 %bit, 0
  br i1 %choose, label %left, label %right
left:
  %a_pair = cmpxchg volatile ptr %cell, i32 %a, i32 %b syncscope("singlethread") seq_cst seq_cst, align 4
  br label %join
right:
  %b_pair = cmpxchg ptr %cell, i32 %b, i32 %a acquire monotonic, align 4
  br label %join
join:
  %pair = phi { i32, i1 } [ %a_pair, %left ], [ %b_pair, %right ]
  %stable = freeze { i32, i1 } %pair
  %clobber = call i64 @flag_pair_clobber(i64 %salt)
  %flag = extractvalue { i32, i1 } %stable, 1
  %value = extractvalue { i32, i1 } %stable, 0
  %low = zext i32 %value to i64
  %flag64 = zext i1 %flag to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 0, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %flag64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r1 = xor i64 %low, %flag64
  %result = xor i64 %r1, %clobber
  ret i64 %result
}

define i64 @flag_pair_atomic64(i64 %a64, i64 %b64, i64 %salt, ptr %out) {
entry:
  %a = add i64 %a64, 0
  %b = add i64 %b64, 0
  %cell = getelementptr i8, ptr %out, i64 32
  %bit = and i64 %salt, 1
  %choose = icmp ne i64 %bit, 0
  br i1 %choose, label %left, label %right
left:
  %a_pair = cmpxchg volatile ptr %cell, i64 %a, i64 %b syncscope("singlethread") seq_cst seq_cst, align 8
  br label %join
right:
  %b_pair = cmpxchg ptr %cell, i64 %b, i64 %a acquire monotonic, align 8
  br label %join
join:
  %pair = phi { i64, i1 } [ %a_pair, %left ], [ %b_pair, %right ]
  %stable = freeze { i64, i1 } %pair
  %clobber = call i64 @flag_pair_clobber(i64 %salt)
  %flag = extractvalue { i64, i1 } %stable, 1
  %value = extractvalue { i64, i1 } %stable, 0
  %low = add i64 %value, 0
  %flag64 = zext i1 %flag to i64
  store i64 %low, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 0, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %flag64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r1 = xor i64 %low, %flag64
  %result = xor i64 %r1, %clobber
  ret i64 %result
}

define i64 @flag_pair_select(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %bit = and i64 %salt, 1
  %choose = icmp ne i64 %bit, 0
  %lt = icmp ult i64 %a, %b
  %gt = icmp ugt i64 %a, %b
  %a0 = insertvalue { i64, i1 } poison, i64 %a, 0
  %a1 = insertvalue { i64, i1 } %a0, i1 %lt, 1
  %b0 = insertvalue { i64, i1 } undef, i64 %b, 0
  %b1 = insertvalue { i64, i1 } %b0, i1 %gt, 1
  %selected = select i1 %choose, { i64, i1 } %a1, { i64, i1 } %b1
  %stable = freeze { i64, i1 } %selected
  %clobber = call i64 @flag_pair_clobber(i64 %salt)
  %flag = extractvalue { i64, i1 } %stable, 1
  %value = extractvalue { i64, i1 } %stable, 0
  %flag64 = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 0, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %flag64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r1 = xor i64 %value, %flag64
  %result = xor i64 %r1, %clobber
  ret i64 %result
}

define i64 @flag_pair_freeze(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %stable = freeze { i64, i1 } { i64 4294967297, i1 true }
  %clobber = call i64 @flag_pair_clobber(i64 %salt)
  %value = extractvalue { i64, i1 } %stable, 0
  %flag = extractvalue { i64, i1 } %stable, 1
  %flag64 = zext i1 %flag to i64
  store i64 %value, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 0, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %flag64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %clobber, ptr %p3, align 8
  %r1 = xor i64 %value, %flag64
  %result = xor i64 %r1, %clobber
  ret i64 %result
}
