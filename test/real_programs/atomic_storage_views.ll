target triple = "x86_64-unknown-linux-gnu"
@frontier_views_global = global [3 x i64] zeroinitializer, align 16
declare i64 @frontier_views_clobber(i64)

define i64 @atomic_storage_8(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %slot = alloca { i8, [7 x i8], i64 }, align 16
  %tail = getelementptr i8, ptr %slot, i64 8
  store i64 %salt, ptr %tail, align 8
  %a0 = trunc i64 %a to i8
  %b0 = trunc i64 %b to i8
  %g = load atomic volatile i8, ptr getelementptr (i8, ptr @frontier_views_global, i64 8) syncscope("singlethread") acquire, align 1
  store atomic volatile i8 %a0, ptr %slot syncscope("singlethread") release, align 1
  %old = atomicrmw add ptr %slot, i8 %b0 acq_rel, align 1
  %new = load atomic volatile i8, ptr %slot seq_cst, align 1
  store atomic i8 %new, ptr getelementptr (i8, ptr @frontier_views_global, i64 8) seq_cst, align 1
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %guard = load i64, ptr %tail, align 8
  %old64 = zext i8 %old to i64
  %new64 = zext i8 %new to i64
  %g64 = zext i8 %g to i64
  %check = xor i64 %clobber, %guard
  store i64 %old64, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %new64, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %g64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %check, ptr %p3, align 8
  %r0 = xor i64 %old64, %new64
  %r1 = xor i64 %r0, %g64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %check
  ret i64 %result
}

define i64 @atomic_storage_16(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %slot = alloca { i16, [6 x i8], i64 }, align 16
  %tail = getelementptr i8, ptr %slot, i64 8
  store i64 %salt, ptr %tail, align 8
  %a0 = trunc i64 %a to i16
  %b0 = trunc i64 %b to i16
  %g = load atomic volatile i16, ptr getelementptr (i8, ptr @frontier_views_global, i64 8) syncscope("singlethread") acquire, align 2
  store atomic volatile i16 %a0, ptr %slot syncscope("singlethread") release, align 2
  %old = atomicrmw add ptr %slot, i16 %b0 acq_rel, align 2
  %new = load atomic volatile i16, ptr %slot seq_cst, align 2
  store atomic i16 %new, ptr getelementptr (i8, ptr @frontier_views_global, i64 8) seq_cst, align 2
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %guard = load i64, ptr %tail, align 8
  %old64 = zext i16 %old to i64
  %new64 = zext i16 %new to i64
  %g64 = zext i16 %g to i64
  %check = xor i64 %clobber, %guard
  store i64 %old64, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %new64, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %g64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %check, ptr %p3, align 8
  %r0 = xor i64 %old64, %new64
  %r1 = xor i64 %r0, %g64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %check
  ret i64 %result
}

define i64 @atomic_storage_32(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %slot = alloca { i32, [4 x i8], i64 }, align 16
  %tail = getelementptr i8, ptr %slot, i64 8
  store i64 %salt, ptr %tail, align 8
  %a0 = trunc i64 %a to i32
  %b0 = trunc i64 %b to i32
  %g = load atomic volatile i32, ptr getelementptr (i8, ptr @frontier_views_global, i64 8) syncscope("singlethread") acquire, align 4
  store atomic volatile i32 %a0, ptr %slot syncscope("singlethread") release, align 4
  %old = atomicrmw add ptr %slot, i32 %b0 acq_rel, align 4
  %new = load atomic volatile i32, ptr %slot seq_cst, align 4
  store atomic i32 %new, ptr getelementptr (i8, ptr @frontier_views_global, i64 8) seq_cst, align 4
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %guard = load i64, ptr %tail, align 8
  %old64 = zext i32 %old to i64
  %new64 = zext i32 %new to i64
  %g64 = zext i32 %g to i64
  %check = xor i64 %clobber, %guard
  store i64 %old64, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %new64, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %g64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %check, ptr %p3, align 8
  %r0 = xor i64 %old64, %new64
  %r1 = xor i64 %r0, %g64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %check
  ret i64 %result
}

define i64 @atomic_storage_64(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %slot = alloca { i64, [0 x i8], i64 }, align 16
  %tail = getelementptr i8, ptr %slot, i64 8
  store i64 %salt, ptr %tail, align 8
  %a0 = add i64 %a, 0
  %b0 = add i64 %b, 0
  %g = load atomic volatile i64, ptr getelementptr (i8, ptr @frontier_views_global, i64 8) syncscope("singlethread") acquire, align 8
  store atomic volatile i64 %a0, ptr %slot syncscope("singlethread") release, align 8
  %old = atomicrmw add ptr %slot, i64 %b0 acq_rel, align 8
  %new = load atomic volatile i64, ptr %slot seq_cst, align 8
  store atomic i64 %new, ptr getelementptr (i8, ptr @frontier_views_global, i64 8) seq_cst, align 8
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %guard = load i64, ptr %tail, align 8
  %old64 = add i64 %old, 0
  %new64 = add i64 %new, 0
  %g64 = add i64 %g, 0
  %check = xor i64 %clobber, %guard
  store i64 %old64, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %new64, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %g64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %check, ptr %p3, align 8
  %r0 = xor i64 %old64, %new64
  %r1 = xor i64 %r0, %g64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %check
  ret i64 %result
}

define i64 @atomic_storage_pointer(i64 %a, i64 %b, i64 %salt, ptr %out) {
entry:
  %slot = alloca { ptr, i64 }, align 16
  %tail = getelementptr i8, ptr %slot, i64 8
  store i64 %salt, ptr %tail, align 8
  %pa = inttoptr i64 %a to ptr
  %pb = inttoptr i64 %b to ptr
  %wrong = xor i64 %a, 1
  %pw = inttoptr i64 %wrong to ptr
  %g = load atomic ptr, ptr getelementptr (i8, ptr @frontier_views_global, i64 8) acquire, align 8
  store atomic ptr %pa, ptr %slot release, align 8
  %bit = and i64 %salt, 1
  %choose = icmp ne i64 %bit, 0
  br i1 %choose, label %yes, label %no
yes:
  %success = cmpxchg ptr %slot, ptr %pa, ptr %pb seq_cst acquire, align 8
  br label %exit
no:
  %failure = cmpxchg ptr %slot, ptr %pw, ptr %pb acq_rel acquire, align 8
  br label %exit
exit:
  %pair = phi { ptr, i1 } [ %success, %yes ], [ %failure, %no ]
  %old = extractvalue { ptr, i1 } %pair, 0
  %flag = extractvalue { ptr, i1 } %pair, 1
  %new = load atomic ptr, ptr %slot seq_cst, align 8
  store atomic ptr %new, ptr getelementptr (i8, ptr @frontier_views_global, i64 8) seq_cst, align 8
  %clobber = call i64 @frontier_views_clobber(i64 %salt)
  %guard = load i64, ptr %tail, align 8
  %old64 = ptrtoint ptr %old to i64
  %new64 = ptrtoint ptr %new to i64
  %g64 = ptrtoint ptr %g to i64
  %flag64 = zext i1 %flag to i64
  %c0 = xor i64 %clobber, %guard
  %check = xor i64 %c0, %flag64
  store i64 %old64, ptr %out, align 8
  %p1 = getelementptr i8, ptr %out, i64 8
  store i64 %new64, ptr %p1, align 8
  %p2 = getelementptr i8, ptr %out, i64 16
  store i64 %g64, ptr %p2, align 8
  %p3 = getelementptr i8, ptr %out, i64 24
  store i64 %check, ptr %p3, align 8
  %r0 = xor i64 %old64, %new64
  %r1 = xor i64 %r0, %g64
  %r2 = xor i64 %r1, %a
  %result = xor i64 %r2, %check
  ret i64 %result
}
