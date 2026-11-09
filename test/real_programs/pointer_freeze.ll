target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
@pointer_freeze_table = internal constant [128 x i16] [i16 7, i16 19, i16 31, i16 43, i16 55, i16 67, i16 79, i16 91, i16 103, i16 115, i16 127, i16 139, i16 151, i16 163, i16 175, i16 187, i16 199, i16 211, i16 223, i16 235, i16 247, i16 259, i16 271, i16 283, i16 295, i16 307, i16 319, i16 331, i16 343, i16 355, i16 367, i16 379, i16 391, i16 403, i16 415, i16 427, i16 439, i16 451, i16 463, i16 475, i16 487, i16 499, i16 511, i16 523, i16 535, i16 547, i16 559, i16 571, i16 583, i16 595, i16 607, i16 619, i16 631, i16 643, i16 655, i16 667, i16 679, i16 691, i16 703, i16 715, i16 727, i16 739, i16 751, i16 763, i16 775, i16 787, i16 799, i16 811, i16 823, i16 835, i16 847, i16 859, i16 871, i16 883, i16 895, i16 907, i16 919, i16 931, i16 943, i16 955, i16 967, i16 979, i16 991, i16 1003, i16 1015, i16 1027, i16 1039, i16 1051, i16 1063, i16 1075, i16 1087, i16 1099, i16 1111, i16 1123, i16 1135, i16 1147, i16 1159, i16 1171, i16 1183, i16 1195, i16 1207, i16 1219, i16 1231, i16 1243, i16 1255, i16 1267, i16 1279, i16 1291, i16 1303, i16 1315, i16 1327, i16 1339, i16 1351, i16 1363, i16 1375, i16 1387, i16 1399, i16 1411, i16 1423, i16 1435, i16 1447, i16 1459, i16 1471, i16 1483, i16 1495, i16 1507, i16 1519, i16 1531], align 2
declare i64 @pointer_freeze_clobber(i64)

define i64 @pointer_freeze_arg(ptr %p, i64 %index, i64 %b, i64 %c, i64 %d, ptr %out) {
entry:
  %frozen = freeze ptr %p
  %value = load i64, ptr %frozen, align 8
  %result = xor i64 %value, %b
  %address = ptrtoint ptr %p to i64
  store i64 %address, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ib = xor i64 %index, %b
  %cd = xor i64 %c, %d
  %live = xor i64 %ib, %cd
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @pointer_freeze_gep(ptr %p, i64 %index, i64 %b, i64 %c, i64 %d, ptr %out) {
entry:
  %i = and i64 %index, 7
  %element = getelementptr i64, ptr %p, i64 %i
  %frozen = freeze ptr %element
  %value = load i64, ptr %frozen, align 8
  %result = xor i64 %value, %b
  %address = ptrtoint ptr %p to i64
  store i64 %address, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ib = xor i64 %index, %b
  %cd = xor i64 %c, %d
  %live = xor i64 %ib, %cd
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @pointer_freeze_phi(ptr %p, i64 %index, i64 %b, i64 %c, i64 %d, ptr %out) {
entry:
  %i = and i64 %index, 7
  %element = getelementptr i64, ptr %p, i64 %i
  %low = and i64 %index, 1
  %cond = icmp ne i64 %low, 0
  br i1 %cond, label %left, label %right
left:
  br label %join
right:
  br label %join
join:
  %chosen = phi ptr [ %element, %left ], [ %p, %right ]
  %frozen = freeze ptr %chosen
  %value = load i64, ptr %frozen, align 8
  %result = xor i64 %value, %b
  %address = ptrtoint ptr %p to i64
  store i64 %address, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ib = xor i64 %index, %b
  %cd = xor i64 %c, %d
  %live = xor i64 %ib, %cd
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @pointer_freeze_calls(ptr %p, i64 %index, i64 %b, i64 %c, i64 %d, ptr %out) {
entry:
  %frozen = freeze ptr %p
  %before = call i64 @pointer_freeze_clobber(i64 %b)
  %i = and i64 %index, 7
  %element = getelementptr i64, ptr %frozen, i64 %i
  %value = load i64, ptr %element, align 8
  %after = call i64 @pointer_freeze_clobber(i64 %c)
  %calls = xor i64 %before, %after
  %result = xor i64 %value, %calls
  %address = ptrtoint ptr %p to i64
  store i64 %address, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ib = xor i64 %index, %b
  %cd = xor i64 %c, %d
  %live = xor i64 %ib, %cd
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @pointer_freeze_stack(ptr %p, i64 %index, i64 %b, i64 %c, i64 %d, ptr %out) {
entry:
  %slot = alloca i64, align 8
  %word = xor i64 %b, %c
  store i64 %word, ptr %slot, align 8
  %frozen = freeze ptr %slot
  %value = load i64, ptr %frozen, align 8
  %result = xor i64 %value, %d
  %address = ptrtoint ptr %p to i64
  store i64 %address, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ib = xor i64 %index, %b
  %cd = xor i64 %c, %d
  %live = xor i64 %ib, %cd
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @pointer_freeze_array(ptr %p, i64 %index, i64 %b, i64 %c, i64 %d, ptr %out) {
entry:
  %array = alloca [4 x i32], align 16
  %slot = getelementptr [4 x i32], ptr %array, i64 0, i64 2
  %low = trunc i64 %b to i32
  store i32 %low, ptr %slot, align 4
  %frozen = freeze ptr %slot
  %value = load i32, ptr %frozen, align 4
  %wide = zext i32 %value to i64
  %result = xor i64 %wide, %c
  %address = ptrtoint ptr %p to i64
  store i64 %address, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ib = xor i64 %index, %b
  %cd = xor i64 %c, %d
  %live = xor i64 %ib, %cd
  store i64 %live, ptr %next, align 8
  ret i64 %result
}

define i64 @pointer_freeze_readonly(ptr %p, i64 %index, i64 %b, i64 %c, i64 %d, ptr %out) {
entry:
  %i = and i64 %index, 127
  %element = getelementptr [2 x i8], ptr @pointer_freeze_table, i64 %i
  %frozen = freeze ptr %element
  %short = load i16, ptr %frozen, align 2
  %value = zext i16 %short to i64
  %result = xor i64 %value, %b
  %address = ptrtoint ptr %p to i64
  store i64 %address, ptr %out, align 8
  %next = getelementptr i8, ptr %out, i64 8
  %ib = xor i64 %index, %b
  %cd = xor i64 %c, %d
  %live = xor i64 %ib, %cd
  store i64 %live, ptr %next, align 8
  ret i64 %result
}
