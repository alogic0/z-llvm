target triple = "x86_64-unknown-linux-gnu"

@atomic_global8 = global i8 0, align 8

@atomic_global16 = global i16 0, align 8

@atomic_global32 = global i32 0, align 8

@atomic_global64 = global i64 0, align 8

define i64 @atomic_xchg8_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw xchg ptr %p, i8 %value seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg8_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw xchg ptr %p, i8 1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg8_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw xchg ptr %p, i8 -1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg8_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile xchg ptr %p, i8 %value syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg8_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile xchg ptr %p, i8 1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg8_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile xchg ptr %p, i8 -1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add8_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw add ptr %p, i8 %value seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add8_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw add ptr %p, i8 1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add8_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw add ptr %p, i8 -1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add8_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile add ptr %p, i8 %value syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add8_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile add ptr %p, i8 1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add8_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile add ptr %p, i8 -1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub8_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw sub ptr %p, i8 %value seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub8_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw sub ptr %p, i8 1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub8_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw sub ptr %p, i8 -1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub8_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile sub ptr %p, i8 %value syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub8_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile sub ptr %p, i8 1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub8_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile sub ptr %p, i8 -1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and8_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw and ptr %p, i8 %value seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and8_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw and ptr %p, i8 1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and8_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw and ptr %p, i8 -1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and8_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile and ptr %p, i8 %value syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and8_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile and ptr %p, i8 1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and8_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile and ptr %p, i8 -1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or8_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw or ptr %p, i8 %value seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or8_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw or ptr %p, i8 1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or8_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw or ptr %p, i8 -1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or8_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile or ptr %p, i8 %value syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or8_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile or ptr %p, i8 1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or8_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile or ptr %p, i8 -1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor8_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw xor ptr %p, i8 %value seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor8_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw xor ptr %p, i8 1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor8_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw xor ptr %p, i8 -1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor8_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile xor ptr %p, i8 %value syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor8_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile xor ptr %p, i8 1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor8_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile xor ptr %p, i8 -1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand8_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw nand ptr %p, i8 %value seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand8_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw nand ptr %p, i8 1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand8_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw nand ptr %p, i8 -1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand8_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile nand ptr %p, i8 %value syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand8_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile nand ptr %p, i8 1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand8_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile nand ptr %p, i8 -1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin8_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw umin ptr %p, i8 %value seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin8_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw umin ptr %p, i8 1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin8_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw umin ptr %p, i8 -1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin8_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile umin ptr %p, i8 %value syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin8_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile umin ptr %p, i8 1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin8_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile umin ptr %p, i8 -1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax8_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw umax ptr %p, i8 %value seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax8_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw umax ptr %p, i8 1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax8_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw umax ptr %p, i8 -1 seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax8_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile umax ptr %p, i8 %value syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax8_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile umax ptr %p, i8 1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax8_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw volatile umax ptr %p, i8 -1 syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_global_xchg8(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw xchg ptr @atomic_global8, i8 %value syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_global_add8(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i8
  %old = atomicrmw add ptr @atomic_global8, i8 %value syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg16_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw xchg ptr %p, i16 %value seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg16_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw xchg ptr %p, i16 1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg16_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw xchg ptr %p, i16 -1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg16_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile xchg ptr %p, i16 %value syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg16_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile xchg ptr %p, i16 1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg16_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile xchg ptr %p, i16 -1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add16_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw add ptr %p, i16 %value seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add16_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw add ptr %p, i16 1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add16_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw add ptr %p, i16 -1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add16_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile add ptr %p, i16 %value syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add16_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile add ptr %p, i16 1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add16_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile add ptr %p, i16 -1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub16_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw sub ptr %p, i16 %value seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub16_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw sub ptr %p, i16 1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub16_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw sub ptr %p, i16 -1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub16_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile sub ptr %p, i16 %value syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub16_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile sub ptr %p, i16 1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub16_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile sub ptr %p, i16 -1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and16_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw and ptr %p, i16 %value seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and16_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw and ptr %p, i16 1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and16_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw and ptr %p, i16 -1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and16_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile and ptr %p, i16 %value syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and16_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile and ptr %p, i16 1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and16_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile and ptr %p, i16 -1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or16_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw or ptr %p, i16 %value seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or16_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw or ptr %p, i16 1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or16_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw or ptr %p, i16 -1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or16_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile or ptr %p, i16 %value syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or16_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile or ptr %p, i16 1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or16_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile or ptr %p, i16 -1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor16_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw xor ptr %p, i16 %value seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor16_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw xor ptr %p, i16 1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor16_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw xor ptr %p, i16 -1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor16_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile xor ptr %p, i16 %value syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor16_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile xor ptr %p, i16 1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor16_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile xor ptr %p, i16 -1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand16_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw nand ptr %p, i16 %value seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand16_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw nand ptr %p, i16 1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand16_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw nand ptr %p, i16 -1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand16_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile nand ptr %p, i16 %value syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand16_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile nand ptr %p, i16 1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand16_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile nand ptr %p, i16 -1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin16_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw umin ptr %p, i16 %value seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin16_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw umin ptr %p, i16 1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin16_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw umin ptr %p, i16 -1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin16_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile umin ptr %p, i16 %value syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin16_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile umin ptr %p, i16 1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin16_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile umin ptr %p, i16 -1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax16_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw umax ptr %p, i16 %value seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax16_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw umax ptr %p, i16 1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax16_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw umax ptr %p, i16 -1 seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax16_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile umax ptr %p, i16 %value syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax16_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile umax ptr %p, i16 1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax16_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw volatile umax ptr %p, i16 -1 syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_global_xchg16(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw xchg ptr @atomic_global16, i16 %value syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_global_add16(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i16
  %old = atomicrmw add ptr @atomic_global16, i16 %value syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg32_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw xchg ptr %p, i32 %value seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg32_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw xchg ptr %p, i32 1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg32_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw xchg ptr %p, i32 -1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg32_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile xchg ptr %p, i32 %value syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg32_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile xchg ptr %p, i32 1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg32_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile xchg ptr %p, i32 -1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add32_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw add ptr %p, i32 %value seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add32_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw add ptr %p, i32 1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add32_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw add ptr %p, i32 -1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add32_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile add ptr %p, i32 %value syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add32_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile add ptr %p, i32 1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add32_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile add ptr %p, i32 -1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub32_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw sub ptr %p, i32 %value seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub32_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw sub ptr %p, i32 1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub32_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw sub ptr %p, i32 -1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub32_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile sub ptr %p, i32 %value syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub32_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile sub ptr %p, i32 1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub32_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile sub ptr %p, i32 -1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and32_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw and ptr %p, i32 %value seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and32_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw and ptr %p, i32 1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and32_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw and ptr %p, i32 -1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and32_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile and ptr %p, i32 %value syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and32_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile and ptr %p, i32 1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and32_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile and ptr %p, i32 -1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or32_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw or ptr %p, i32 %value seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or32_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw or ptr %p, i32 1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or32_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw or ptr %p, i32 -1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or32_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile or ptr %p, i32 %value syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or32_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile or ptr %p, i32 1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or32_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile or ptr %p, i32 -1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor32_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw xor ptr %p, i32 %value seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor32_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw xor ptr %p, i32 1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor32_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw xor ptr %p, i32 -1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor32_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile xor ptr %p, i32 %value syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor32_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile xor ptr %p, i32 1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor32_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile xor ptr %p, i32 -1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand32_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw nand ptr %p, i32 %value seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand32_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw nand ptr %p, i32 1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand32_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw nand ptr %p, i32 -1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand32_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile nand ptr %p, i32 %value syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand32_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile nand ptr %p, i32 1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand32_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile nand ptr %p, i32 -1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin32_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw umin ptr %p, i32 %value seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin32_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw umin ptr %p, i32 1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin32_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw umin ptr %p, i32 -1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin32_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile umin ptr %p, i32 %value syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin32_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile umin ptr %p, i32 1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin32_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile umin ptr %p, i32 -1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax32_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw umax ptr %p, i32 %value seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax32_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw umax ptr %p, i32 1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax32_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw umax ptr %p, i32 -1 seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax32_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile umax ptr %p, i32 %value syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax32_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile umax ptr %p, i32 1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax32_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw volatile umax ptr %p, i32 -1 syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_global_xchg32(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw xchg ptr @atomic_global32, i32 %value syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_global_add32(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %a to i32
  %old = atomicrmw add ptr @atomic_global32, i32 %value syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg64_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw xchg ptr %p, i64 %value seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg64_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw xchg ptr %p, i64 1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg64_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw xchg ptr %p, i64 -1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg64_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile xchg ptr %p, i64 %value syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg64_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile xchg ptr %p, i64 1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xchg64_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile xchg ptr %p, i64 -1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add64_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw add ptr %p, i64 %value seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add64_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw add ptr %p, i64 1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add64_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw add ptr %p, i64 -1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add64_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile add ptr %p, i64 %value syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add64_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile add ptr %p, i64 1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_add64_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile add ptr %p, i64 -1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub64_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw sub ptr %p, i64 %value seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub64_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw sub ptr %p, i64 1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub64_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw sub ptr %p, i64 -1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub64_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile sub ptr %p, i64 %value syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub64_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile sub ptr %p, i64 1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_sub64_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile sub ptr %p, i64 -1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and64_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw and ptr %p, i64 %value seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and64_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw and ptr %p, i64 1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and64_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw and ptr %p, i64 -1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and64_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile and ptr %p, i64 %value syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and64_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile and ptr %p, i64 1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_and64_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile and ptr %p, i64 -1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or64_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw or ptr %p, i64 %value seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or64_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw or ptr %p, i64 1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or64_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw or ptr %p, i64 -1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or64_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile or ptr %p, i64 %value syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or64_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile or ptr %p, i64 1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_or64_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile or ptr %p, i64 -1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor64_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw xor ptr %p, i64 %value seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor64_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw xor ptr %p, i64 1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor64_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw xor ptr %p, i64 -1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor64_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile xor ptr %p, i64 %value syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor64_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile xor ptr %p, i64 1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_xor64_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile xor ptr %p, i64 -1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand64_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw nand ptr %p, i64 %value seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand64_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw nand ptr %p, i64 1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand64_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw nand ptr %p, i64 -1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand64_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile nand ptr %p, i64 %value syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand64_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile nand ptr %p, i64 1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_nand64_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile nand ptr %p, i64 -1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin64_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw umin ptr %p, i64 %value seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin64_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw umin ptr %p, i64 1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin64_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw umin ptr %p, i64 -1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin64_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile umin ptr %p, i64 %value syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin64_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile umin ptr %p, i64 1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umin64_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile umin ptr %p, i64 -1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax64_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw umax ptr %p, i64 %value seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax64_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw umax ptr %p, i64 1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax64_0_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw umax ptr %p, i64 -1 seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax64_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile umax ptr %p, i64 %value syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax64_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile umax ptr %p, i64 1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_umax64_1_2(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw volatile umax ptr %p, i64 -1 syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_global_xchg64(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw xchg ptr @atomic_global64, i64 %value syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_global_add64(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %a, 0
  %old = atomicrmw add ptr @atomic_global64, i64 %value syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 0, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp8_0_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i8
  %desired = trunc i64 %b to i8
  %pair = cmpxchg ptr %p, i8 %expected, i8 %desired seq_cst acquire, align 1
  %old = extractvalue { i8, i1 } %pair, 0
  %flag = extractvalue { i8, i1 } %pair, 1
  %oldwide = zext i8 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp8_0_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i8
  %desired = trunc i64 %b to i8
  %pair = cmpxchg ptr %p, i8 %expected, i8 %desired seq_cst acquire, align 1
  %flag = extractvalue { i8, i1 } %pair, 1
  %old = extractvalue { i8, i1 } %pair, 0
  %oldwide = zext i8 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp8_0_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i8
  %desired = trunc i64 %b to i8
  %pair = cmpxchg weak ptr %p, i8 %expected, i8 %desired seq_cst acquire, align 1
  %old = extractvalue { i8, i1 } %pair, 0
  %flag = extractvalue { i8, i1 } %pair, 1
  %oldwide = zext i8 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp8_0_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i8
  %desired = trunc i64 %b to i8
  %pair = cmpxchg weak ptr %p, i8 %expected, i8 %desired seq_cst acquire, align 1
  %flag = extractvalue { i8, i1 } %pair, 1
  %old = extractvalue { i8, i1 } %pair, 0
  %oldwide = zext i8 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory8_0_monotonic(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i8
  %old = load atomic i8, ptr %p monotonic, align 1
  store atomic i8 %value, ptr %p monotonic, align 1
  %new = load atomic i8, ptr %p monotonic, align 1
  %oldwide = zext i8 %old to i64
  %aux = zext i8 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory8_0_release(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i8
  %old = load atomic i8, ptr %p acquire, align 1
  store atomic i8 %value, ptr %p release, align 1
  %new = load atomic i8, ptr %p acquire, align 1
  %oldwide = zext i8 %old to i64
  %aux = zext i8 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory8_0_seq_cst(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i8
  %old = load atomic i8, ptr %p seq_cst, align 1
  store atomic i8 %value, ptr %p seq_cst, align 1
  %new = load atomic i8, ptr %p seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = zext i8 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp8_1_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i8
  %desired = trunc i64 %b to i8
  %pair = cmpxchg volatile ptr %p, i8 %expected, i8 %desired syncscope("singlethread") seq_cst acquire, align 1
  %old = extractvalue { i8, i1 } %pair, 0
  %flag = extractvalue { i8, i1 } %pair, 1
  %oldwide = zext i8 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp8_1_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i8
  %desired = trunc i64 %b to i8
  %pair = cmpxchg volatile ptr %p, i8 %expected, i8 %desired syncscope("singlethread") seq_cst acquire, align 1
  %flag = extractvalue { i8, i1 } %pair, 1
  %old = extractvalue { i8, i1 } %pair, 0
  %oldwide = zext i8 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp8_1_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i8
  %desired = trunc i64 %b to i8
  %pair = cmpxchg weak volatile ptr %p, i8 %expected, i8 %desired syncscope("singlethread") seq_cst acquire, align 1
  %old = extractvalue { i8, i1 } %pair, 0
  %flag = extractvalue { i8, i1 } %pair, 1
  %oldwide = zext i8 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp8_1_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i8
  %desired = trunc i64 %b to i8
  %pair = cmpxchg weak volatile ptr %p, i8 %expected, i8 %desired syncscope("singlethread") seq_cst acquire, align 1
  %flag = extractvalue { i8, i1 } %pair, 1
  %old = extractvalue { i8, i1 } %pair, 0
  %oldwide = zext i8 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory8_1_monotonic(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i8
  %old = load atomic volatile i8, ptr %p syncscope("singlethread") monotonic, align 1
  store atomic volatile i8 %value, ptr %p syncscope("singlethread") monotonic, align 1
  %new = load atomic volatile i8, ptr %p syncscope("singlethread") monotonic, align 1
  %oldwide = zext i8 %old to i64
  %aux = zext i8 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory8_1_release(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i8
  %old = load atomic volatile i8, ptr %p syncscope("singlethread") acquire, align 1
  store atomic volatile i8 %value, ptr %p syncscope("singlethread") release, align 1
  %new = load atomic volatile i8, ptr %p syncscope("singlethread") acquire, align 1
  %oldwide = zext i8 %old to i64
  %aux = zext i8 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory8_1_seq_cst(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i8
  %old = load atomic volatile i8, ptr %p syncscope("singlethread") seq_cst, align 1
  store atomic volatile i8 %value, ptr %p syncscope("singlethread") seq_cst, align 1
  %new = load atomic volatile i8, ptr %p syncscope("singlethread") seq_cst, align 1
  %oldwide = zext i8 %old to i64
  %aux = zext i8 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp16_0_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i16
  %desired = trunc i64 %b to i16
  %pair = cmpxchg ptr %p, i16 %expected, i16 %desired seq_cst acquire, align 2
  %old = extractvalue { i16, i1 } %pair, 0
  %flag = extractvalue { i16, i1 } %pair, 1
  %oldwide = zext i16 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp16_0_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i16
  %desired = trunc i64 %b to i16
  %pair = cmpxchg ptr %p, i16 %expected, i16 %desired seq_cst acquire, align 2
  %flag = extractvalue { i16, i1 } %pair, 1
  %old = extractvalue { i16, i1 } %pair, 0
  %oldwide = zext i16 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp16_0_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i16
  %desired = trunc i64 %b to i16
  %pair = cmpxchg weak ptr %p, i16 %expected, i16 %desired seq_cst acquire, align 2
  %old = extractvalue { i16, i1 } %pair, 0
  %flag = extractvalue { i16, i1 } %pair, 1
  %oldwide = zext i16 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp16_0_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i16
  %desired = trunc i64 %b to i16
  %pair = cmpxchg weak ptr %p, i16 %expected, i16 %desired seq_cst acquire, align 2
  %flag = extractvalue { i16, i1 } %pair, 1
  %old = extractvalue { i16, i1 } %pair, 0
  %oldwide = zext i16 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory16_0_monotonic(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i16
  %old = load atomic i16, ptr %p monotonic, align 2
  store atomic i16 %value, ptr %p monotonic, align 2
  %new = load atomic i16, ptr %p monotonic, align 2
  %oldwide = zext i16 %old to i64
  %aux = zext i16 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory16_0_release(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i16
  %old = load atomic i16, ptr %p acquire, align 2
  store atomic i16 %value, ptr %p release, align 2
  %new = load atomic i16, ptr %p acquire, align 2
  %oldwide = zext i16 %old to i64
  %aux = zext i16 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory16_0_seq_cst(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i16
  %old = load atomic i16, ptr %p seq_cst, align 2
  store atomic i16 %value, ptr %p seq_cst, align 2
  %new = load atomic i16, ptr %p seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = zext i16 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp16_1_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i16
  %desired = trunc i64 %b to i16
  %pair = cmpxchg volatile ptr %p, i16 %expected, i16 %desired syncscope("singlethread") seq_cst acquire, align 2
  %old = extractvalue { i16, i1 } %pair, 0
  %flag = extractvalue { i16, i1 } %pair, 1
  %oldwide = zext i16 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp16_1_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i16
  %desired = trunc i64 %b to i16
  %pair = cmpxchg volatile ptr %p, i16 %expected, i16 %desired syncscope("singlethread") seq_cst acquire, align 2
  %flag = extractvalue { i16, i1 } %pair, 1
  %old = extractvalue { i16, i1 } %pair, 0
  %oldwide = zext i16 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp16_1_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i16
  %desired = trunc i64 %b to i16
  %pair = cmpxchg weak volatile ptr %p, i16 %expected, i16 %desired syncscope("singlethread") seq_cst acquire, align 2
  %old = extractvalue { i16, i1 } %pair, 0
  %flag = extractvalue { i16, i1 } %pair, 1
  %oldwide = zext i16 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp16_1_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i16
  %desired = trunc i64 %b to i16
  %pair = cmpxchg weak volatile ptr %p, i16 %expected, i16 %desired syncscope("singlethread") seq_cst acquire, align 2
  %flag = extractvalue { i16, i1 } %pair, 1
  %old = extractvalue { i16, i1 } %pair, 0
  %oldwide = zext i16 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory16_1_monotonic(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i16
  %old = load atomic volatile i16, ptr %p syncscope("singlethread") monotonic, align 2
  store atomic volatile i16 %value, ptr %p syncscope("singlethread") monotonic, align 2
  %new = load atomic volatile i16, ptr %p syncscope("singlethread") monotonic, align 2
  %oldwide = zext i16 %old to i64
  %aux = zext i16 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory16_1_release(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i16
  %old = load atomic volatile i16, ptr %p syncscope("singlethread") acquire, align 2
  store atomic volatile i16 %value, ptr %p syncscope("singlethread") release, align 2
  %new = load atomic volatile i16, ptr %p syncscope("singlethread") acquire, align 2
  %oldwide = zext i16 %old to i64
  %aux = zext i16 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory16_1_seq_cst(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i16
  %old = load atomic volatile i16, ptr %p syncscope("singlethread") seq_cst, align 2
  store atomic volatile i16 %value, ptr %p syncscope("singlethread") seq_cst, align 2
  %new = load atomic volatile i16, ptr %p syncscope("singlethread") seq_cst, align 2
  %oldwide = zext i16 %old to i64
  %aux = zext i16 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp32_0_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i32
  %desired = trunc i64 %b to i32
  %pair = cmpxchg ptr %p, i32 %expected, i32 %desired seq_cst acquire, align 4
  %old = extractvalue { i32, i1 } %pair, 0
  %flag = extractvalue { i32, i1 } %pair, 1
  %oldwide = zext i32 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp32_0_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i32
  %desired = trunc i64 %b to i32
  %pair = cmpxchg ptr %p, i32 %expected, i32 %desired seq_cst acquire, align 4
  %flag = extractvalue { i32, i1 } %pair, 1
  %old = extractvalue { i32, i1 } %pair, 0
  %oldwide = zext i32 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp32_0_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i32
  %desired = trunc i64 %b to i32
  %pair = cmpxchg weak ptr %p, i32 %expected, i32 %desired seq_cst acquire, align 4
  %old = extractvalue { i32, i1 } %pair, 0
  %flag = extractvalue { i32, i1 } %pair, 1
  %oldwide = zext i32 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp32_0_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i32
  %desired = trunc i64 %b to i32
  %pair = cmpxchg weak ptr %p, i32 %expected, i32 %desired seq_cst acquire, align 4
  %flag = extractvalue { i32, i1 } %pair, 1
  %old = extractvalue { i32, i1 } %pair, 0
  %oldwide = zext i32 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory32_0_monotonic(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i32
  %old = load atomic i32, ptr %p monotonic, align 4
  store atomic i32 %value, ptr %p monotonic, align 4
  %new = load atomic i32, ptr %p monotonic, align 4
  %oldwide = zext i32 %old to i64
  %aux = zext i32 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory32_0_release(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i32
  %old = load atomic i32, ptr %p acquire, align 4
  store atomic i32 %value, ptr %p release, align 4
  %new = load atomic i32, ptr %p acquire, align 4
  %oldwide = zext i32 %old to i64
  %aux = zext i32 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory32_0_seq_cst(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i32
  %old = load atomic i32, ptr %p seq_cst, align 4
  store atomic i32 %value, ptr %p seq_cst, align 4
  %new = load atomic i32, ptr %p seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = zext i32 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp32_1_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i32
  %desired = trunc i64 %b to i32
  %pair = cmpxchg volatile ptr %p, i32 %expected, i32 %desired syncscope("singlethread") seq_cst acquire, align 4
  %old = extractvalue { i32, i1 } %pair, 0
  %flag = extractvalue { i32, i1 } %pair, 1
  %oldwide = zext i32 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp32_1_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i32
  %desired = trunc i64 %b to i32
  %pair = cmpxchg volatile ptr %p, i32 %expected, i32 %desired syncscope("singlethread") seq_cst acquire, align 4
  %flag = extractvalue { i32, i1 } %pair, 1
  %old = extractvalue { i32, i1 } %pair, 0
  %oldwide = zext i32 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp32_1_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i32
  %desired = trunc i64 %b to i32
  %pair = cmpxchg weak volatile ptr %p, i32 %expected, i32 %desired syncscope("singlethread") seq_cst acquire, align 4
  %old = extractvalue { i32, i1 } %pair, 0
  %flag = extractvalue { i32, i1 } %pair, 1
  %oldwide = zext i32 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp32_1_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = trunc i64 %a to i32
  %desired = trunc i64 %b to i32
  %pair = cmpxchg weak volatile ptr %p, i32 %expected, i32 %desired syncscope("singlethread") seq_cst acquire, align 4
  %flag = extractvalue { i32, i1 } %pair, 1
  %old = extractvalue { i32, i1 } %pair, 0
  %oldwide = zext i32 %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory32_1_monotonic(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i32
  %old = load atomic volatile i32, ptr %p syncscope("singlethread") monotonic, align 4
  store atomic volatile i32 %value, ptr %p syncscope("singlethread") monotonic, align 4
  %new = load atomic volatile i32, ptr %p syncscope("singlethread") monotonic, align 4
  %oldwide = zext i32 %old to i64
  %aux = zext i32 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory32_1_release(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i32
  %old = load atomic volatile i32, ptr %p syncscope("singlethread") acquire, align 4
  store atomic volatile i32 %value, ptr %p syncscope("singlethread") release, align 4
  %new = load atomic volatile i32, ptr %p syncscope("singlethread") acquire, align 4
  %oldwide = zext i32 %old to i64
  %aux = zext i32 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory32_1_seq_cst(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = trunc i64 %b to i32
  %old = load atomic volatile i32, ptr %p syncscope("singlethread") seq_cst, align 4
  store atomic volatile i32 %value, ptr %p syncscope("singlethread") seq_cst, align 4
  %new = load atomic volatile i32, ptr %p syncscope("singlethread") seq_cst, align 4
  %oldwide = zext i32 %old to i64
  %aux = zext i32 %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp64_0_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = add i64 %a, 0
  %desired = add i64 %b, 0
  %pair = cmpxchg ptr %p, i64 %expected, i64 %desired seq_cst acquire, align 8
  %old = extractvalue { i64, i1 } %pair, 0
  %flag = extractvalue { i64, i1 } %pair, 1
  %oldwide = add i64 %old, 0
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp64_0_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = add i64 %a, 0
  %desired = add i64 %b, 0
  %pair = cmpxchg ptr %p, i64 %expected, i64 %desired seq_cst acquire, align 8
  %flag = extractvalue { i64, i1 } %pair, 1
  %old = extractvalue { i64, i1 } %pair, 0
  %oldwide = add i64 %old, 0
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp64_0_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = add i64 %a, 0
  %desired = add i64 %b, 0
  %pair = cmpxchg weak ptr %p, i64 %expected, i64 %desired seq_cst acquire, align 8
  %old = extractvalue { i64, i1 } %pair, 0
  %flag = extractvalue { i64, i1 } %pair, 1
  %oldwide = add i64 %old, 0
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp64_0_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = add i64 %a, 0
  %desired = add i64 %b, 0
  %pair = cmpxchg weak ptr %p, i64 %expected, i64 %desired seq_cst acquire, align 8
  %flag = extractvalue { i64, i1 } %pair, 1
  %old = extractvalue { i64, i1 } %pair, 0
  %oldwide = add i64 %old, 0
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory64_0_monotonic(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %b, 0
  %old = load atomic i64, ptr %p monotonic, align 8
  store atomic i64 %value, ptr %p monotonic, align 8
  %new = load atomic i64, ptr %p monotonic, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 %new, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory64_0_release(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %b, 0
  %old = load atomic i64, ptr %p acquire, align 8
  store atomic i64 %value, ptr %p release, align 8
  %new = load atomic i64, ptr %p acquire, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 %new, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory64_0_seq_cst(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %b, 0
  %old = load atomic i64, ptr %p seq_cst, align 8
  store atomic i64 %value, ptr %p seq_cst, align 8
  %new = load atomic i64, ptr %p seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 %new, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp64_1_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = add i64 %a, 0
  %desired = add i64 %b, 0
  %pair = cmpxchg volatile ptr %p, i64 %expected, i64 %desired syncscope("singlethread") seq_cst acquire, align 8
  %old = extractvalue { i64, i1 } %pair, 0
  %flag = extractvalue { i64, i1 } %pair, 1
  %oldwide = add i64 %old, 0
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp64_1_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = add i64 %a, 0
  %desired = add i64 %b, 0
  %pair = cmpxchg volatile ptr %p, i64 %expected, i64 %desired syncscope("singlethread") seq_cst acquire, align 8
  %flag = extractvalue { i64, i1 } %pair, 1
  %old = extractvalue { i64, i1 } %pair, 0
  %oldwide = add i64 %old, 0
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp64_1_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = add i64 %a, 0
  %desired = add i64 %b, 0
  %pair = cmpxchg weak volatile ptr %p, i64 %expected, i64 %desired syncscope("singlethread") seq_cst acquire, align 8
  %old = extractvalue { i64, i1 } %pair, 0
  %flag = extractvalue { i64, i1 } %pair, 1
  %oldwide = add i64 %old, 0
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp64_1_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = add i64 %a, 0
  %desired = add i64 %b, 0
  %pair = cmpxchg weak volatile ptr %p, i64 %expected, i64 %desired syncscope("singlethread") seq_cst acquire, align 8
  %flag = extractvalue { i64, i1 } %pair, 1
  %old = extractvalue { i64, i1 } %pair, 0
  %oldwide = add i64 %old, 0
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory64_1_monotonic(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %b, 0
  %old = load atomic volatile i64, ptr %p syncscope("singlethread") monotonic, align 8
  store atomic volatile i64 %value, ptr %p syncscope("singlethread") monotonic, align 8
  %new = load atomic volatile i64, ptr %p syncscope("singlethread") monotonic, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 %new, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory64_1_release(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %b, 0
  %old = load atomic volatile i64, ptr %p syncscope("singlethread") acquire, align 8
  store atomic volatile i64 %value, ptr %p syncscope("singlethread") release, align 8
  %new = load atomic volatile i64, ptr %p syncscope("singlethread") acquire, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 %new, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory64_1_seq_cst(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = add i64 %b, 0
  %old = load atomic volatile i64, ptr %p syncscope("singlethread") seq_cst, align 8
  store atomic volatile i64 %value, ptr %p syncscope("singlethread") seq_cst, align 8
  %new = load atomic volatile i64, ptr %p syncscope("singlethread") seq_cst, align 8
  %oldwide = add i64 %old, 0
  %aux = add i64 %new, 0
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp0_0_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = inttoptr i64 %a to ptr
  %desired = inttoptr i64 %b to ptr
  %pair = cmpxchg ptr %p, ptr %expected, ptr %desired seq_cst acquire, align 8
  %old = extractvalue { ptr, i1 } %pair, 0
  %flag = extractvalue { ptr, i1 } %pair, 1
  %oldwide = ptrtoint ptr %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp0_0_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = inttoptr i64 %a to ptr
  %desired = inttoptr i64 %b to ptr
  %pair = cmpxchg ptr %p, ptr %expected, ptr %desired seq_cst acquire, align 8
  %flag = extractvalue { ptr, i1 } %pair, 1
  %old = extractvalue { ptr, i1 } %pair, 0
  %oldwide = ptrtoint ptr %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp0_0_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = inttoptr i64 %a to ptr
  %desired = inttoptr i64 %b to ptr
  %pair = cmpxchg weak ptr %p, ptr %expected, ptr %desired seq_cst acquire, align 8
  %old = extractvalue { ptr, i1 } %pair, 0
  %flag = extractvalue { ptr, i1 } %pair, 1
  %oldwide = ptrtoint ptr %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp0_0_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = inttoptr i64 %a to ptr
  %desired = inttoptr i64 %b to ptr
  %pair = cmpxchg weak ptr %p, ptr %expected, ptr %desired seq_cst acquire, align 8
  %flag = extractvalue { ptr, i1 } %pair, 1
  %old = extractvalue { ptr, i1 } %pair, 0
  %oldwide = ptrtoint ptr %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory0_0_monotonic(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = inttoptr i64 %b to ptr
  %old = load atomic ptr, ptr %p monotonic, align 8
  store atomic ptr %value, ptr %p monotonic, align 8
  %new = load atomic ptr, ptr %p monotonic, align 8
  %oldwide = ptrtoint ptr %old to i64
  %aux = ptrtoint ptr %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory0_0_release(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = inttoptr i64 %b to ptr
  %old = load atomic ptr, ptr %p acquire, align 8
  store atomic ptr %value, ptr %p release, align 8
  %new = load atomic ptr, ptr %p acquire, align 8
  %oldwide = ptrtoint ptr %old to i64
  %aux = ptrtoint ptr %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory0_0_seq_cst(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = inttoptr i64 %b to ptr
  %old = load atomic ptr, ptr %p seq_cst, align 8
  store atomic ptr %value, ptr %p seq_cst, align 8
  %new = load atomic ptr, ptr %p seq_cst, align 8
  %oldwide = ptrtoint ptr %old to i64
  %aux = ptrtoint ptr %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp0_1_0_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = inttoptr i64 %a to ptr
  %desired = inttoptr i64 %b to ptr
  %pair = cmpxchg volatile ptr %p, ptr %expected, ptr %desired syncscope("singlethread") seq_cst acquire, align 8
  %old = extractvalue { ptr, i1 } %pair, 0
  %flag = extractvalue { ptr, i1 } %pair, 1
  %oldwide = ptrtoint ptr %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp0_1_0_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = inttoptr i64 %a to ptr
  %desired = inttoptr i64 %b to ptr
  %pair = cmpxchg volatile ptr %p, ptr %expected, ptr %desired syncscope("singlethread") seq_cst acquire, align 8
  %flag = extractvalue { ptr, i1 } %pair, 1
  %old = extractvalue { ptr, i1 } %pair, 0
  %oldwide = ptrtoint ptr %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp0_1_1_0(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = inttoptr i64 %a to ptr
  %desired = inttoptr i64 %b to ptr
  %pair = cmpxchg weak volatile ptr %p, ptr %expected, ptr %desired syncscope("singlethread") seq_cst acquire, align 8
  %old = extractvalue { ptr, i1 } %pair, 0
  %flag = extractvalue { ptr, i1 } %pair, 1
  %oldwide = ptrtoint ptr %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_cmp0_1_1_1(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %expected = inttoptr i64 %a to ptr
  %desired = inttoptr i64 %b to ptr
  %pair = cmpxchg weak volatile ptr %p, ptr %expected, ptr %desired syncscope("singlethread") seq_cst acquire, align 8
  %flag = extractvalue { ptr, i1 } %pair, 1
  %old = extractvalue { ptr, i1 } %pair, 0
  %oldwide = ptrtoint ptr %old to i64
  %aux = zext i1 %flag to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory0_1_monotonic(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = inttoptr i64 %b to ptr
  %old = load atomic volatile ptr, ptr %p syncscope("singlethread") monotonic, align 8
  store atomic volatile ptr %value, ptr %p syncscope("singlethread") monotonic, align 8
  %new = load atomic volatile ptr, ptr %p syncscope("singlethread") monotonic, align 8
  %oldwide = ptrtoint ptr %old to i64
  %aux = ptrtoint ptr %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory0_1_release(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = inttoptr i64 %b to ptr
  %old = load atomic volatile ptr, ptr %p syncscope("singlethread") acquire, align 8
  store atomic volatile ptr %value, ptr %p syncscope("singlethread") release, align 8
  %new = load atomic volatile ptr, ptr %p syncscope("singlethread") acquire, align 8
  %oldwide = ptrtoint ptr %old to i64
  %aux = ptrtoint ptr %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}


define i64 @atomic_memory0_1_seq_cst(ptr %p, i64 %a, i64 %b, ptr %out, i64 %salt) {
entry:
  %value = inttoptr i64 %b to ptr
  %old = load atomic volatile ptr, ptr %p syncscope("singlethread") seq_cst, align 8
  store atomic volatile ptr %value, ptr %p syncscope("singlethread") seq_cst, align 8
  %new = load atomic volatile ptr, ptr %p syncscope("singlethread") seq_cst, align 8
  %oldwide = ptrtoint ptr %old to i64
  %aux = ptrtoint ptr %new to i64
  store i64 %oldwide, ptr %out
  %next = getelementptr i8, ptr %out, i64 8
  store i64 %aux, ptr %next
  %last = getelementptr i8, ptr %out, i64 16
  %xor = xor i64 %a, %b
  %live = xor i64 %xor, %salt
  store i64 %live, ptr %last
  ret i64 %oldwide
}

