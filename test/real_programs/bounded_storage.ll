target triple = "x86_64-unknown-linux-gnu"

%Packed = type <{ i8, float, double }>

%Padded = type { i8, x86_fp80 }

declare void @storage_clobber(ptr, ptr)

declare i64 @storage_probe_sink(ptr)

define i64 @storage_bytes1(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca [1 x i8], align 16
  %guard = alloca [8 x i8], align 8
  %tail = getelementptr i8, ptr %slot, i64 0
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  store i64 %a, ptr %guard
  store i8 %x, ptr %slot
  store i8 %y, ptr %tail
  call void @storage_clobber(ptr %slot, ptr %guard)
  %first = load i8, ptr %slot
  %last = load i8, ptr %tail
  %saved = load i64, ptr %guard
  %left = zext i8 %first to i64
  %right = zext i8 %last to i64
  %live = xor i64 %saved, %b
  %sum = add i64 %left, %right
  store i64 %sum, ptr %out
  ret i64 %live
}

define i64 @storage_bytes2(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca [2 x i8], align 16
  %guard = alloca [8 x i8], align 8
  %tail = getelementptr i8, ptr %slot, i64 1
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  store i64 %a, ptr %guard
  store i8 %x, ptr %slot
  store i8 %y, ptr %tail
  call void @storage_clobber(ptr %slot, ptr %guard)
  %first = load i8, ptr %slot
  %last = load i8, ptr %tail
  %saved = load i64, ptr %guard
  %left = zext i8 %first to i64
  %right = zext i8 %last to i64
  %live = xor i64 %saved, %b
  %sum = add i64 %left, %right
  store i64 %sum, ptr %out
  ret i64 %live
}

define i64 @storage_bytes3(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca [3 x i8], align 16
  %guard = alloca [8 x i8], align 8
  %tail = getelementptr i8, ptr %slot, i64 2
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  store i64 %a, ptr %guard
  store i8 %x, ptr %slot
  store i8 %y, ptr %tail
  call void @storage_clobber(ptr %slot, ptr %guard)
  %first = load i8, ptr %slot
  %last = load i8, ptr %tail
  %saved = load i64, ptr %guard
  %left = zext i8 %first to i64
  %right = zext i8 %last to i64
  %live = xor i64 %saved, %b
  %sum = add i64 %left, %right
  store i64 %sum, ptr %out
  ret i64 %live
}

define i64 @storage_bytes5(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca [5 x i8], align 16
  %guard = alloca [8 x i8], align 8
  %tail = getelementptr i8, ptr %slot, i64 4
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  store i64 %a, ptr %guard
  store i8 %x, ptr %slot
  store i8 %y, ptr %tail
  call void @storage_clobber(ptr %slot, ptr %guard)
  %first = load i8, ptr %slot
  %last = load i8, ptr %tail
  %saved = load i64, ptr %guard
  %left = zext i8 %first to i64
  %right = zext i8 %last to i64
  %live = xor i64 %saved, %b
  %sum = add i64 %left, %right
  store i64 %sum, ptr %out
  ret i64 %live
}

define i64 @storage_bytes257(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca [257 x i8], align 16
  %guard = alloca [8 x i8], align 8
  %tail = getelementptr i8, ptr %slot, i64 256
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  store i64 %a, ptr %guard
  store i8 %x, ptr %slot
  store i8 %y, ptr %tail
  call void @storage_clobber(ptr %slot, ptr %guard)
  %first = load i8, ptr %slot
  %last = load i8, ptr %tail
  %saved = load i64, ptr %guard
  %left = zext i8 %first to i64
  %right = zext i8 %last to i64
  %live = xor i64 %saved, %b
  %sum = add i64 %left, %right
  store i64 %sum, ptr %out
  ret i64 %live
}

define i64 @storage_page(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca [4096 x i8], align 16
  %guard = alloca [8 x i8], align 8
  %tail = getelementptr i8, ptr %slot, i64 4095
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  store i64 %a, ptr %guard
  store i8 %x, ptr %slot
  store i8 %y, ptr %tail
  call void @storage_clobber(ptr %slot, ptr %guard)
  %first = load i8, ptr %slot
  %last = load i8, ptr %tail
  %saved = load i64, ptr %guard
  %left = zext i8 %first to i64
  %right = zext i8 %last to i64
  %live = xor i64 %saved, %b
  %sum = add i64 %left, %right
  store i64 %sum, ptr %out
  ret i64 %live
}

define i64 @storage_pages(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca [8193 x i8], align 16
  %guard = alloca [8 x i8], align 8
  %tail = getelementptr i8, ptr %slot, i64 8192
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  store i64 %a, ptr %guard
  store i8 %x, ptr %slot
  store i8 %y, ptr %tail
  call void @storage_clobber(ptr %slot, ptr %guard)
  %first = load i8, ptr %slot
  %last = load i8, ptr %tail
  %saved = load i64, ptr %guard
  %left = zext i8 %first to i64
  %right = zext i8 %last to i64
  %live = xor i64 %saved, %b
  %sum = add i64 %left, %right
  store i64 %sum, ptr %out
  ret i64 %live
}

define i64 @storage_limit(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca [65536 x i8], align 16
  %guard = alloca [8 x i8], align 8
  %tail = getelementptr i8, ptr %slot, i64 65535
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  store i64 %a, ptr %guard
  store i8 %x, ptr %slot
  store i8 %y, ptr %tail
  call void @storage_clobber(ptr %slot, ptr %guard)
  %first = load i8, ptr %slot
  %last = load i8, ptr %tail
  %saved = load i64, ptr %guard
  %left = zext i8 %first to i64
  %right = zext i8 %last to i64
  %live = xor i64 %saved, %b
  %sum = add i64 %left, %right
  store i64 %sum, ptr %out
  ret i64 %live
}

define i64 @storage_slot16(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca i16, align 16
  %guard = alloca [8 x i8], align 8
  %tail = getelementptr i8, ptr %slot, i64 1
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  store i64 %a, ptr %guard
  store i8 %x, ptr %slot
  store i8 %y, ptr %tail
  call void @storage_clobber(ptr %slot, ptr %guard)
  %first = load i8, ptr %slot
  %last = load i8, ptr %tail
  %saved = load i64, ptr %guard
  %left = zext i8 %first to i64
  %right = zext i8 %last to i64
  %live = xor i64 %saved, %b
  %sum = add i64 %left, %right
  store i64 %sum, ptr %out
  ret i64 %live
}

define i64 @storage_slot32(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca i32, align 16
  %guard = alloca [8 x i8], align 8
  %tail = getelementptr i8, ptr %slot, i64 3
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  store i64 %a, ptr %guard
  store i8 %x, ptr %slot
  store i8 %y, ptr %tail
  call void @storage_clobber(ptr %slot, ptr %guard)
  %first = load i8, ptr %slot
  %last = load i8, ptr %tail
  %saved = load i64, ptr %guard
  %left = zext i8 %first to i64
  %right = zext i8 %last to i64
  %live = xor i64 %saved, %b
  %sum = add i64 %left, %right
  store i64 %sum, ptr %out
  ret i64 %live
}

define i64 @storage_packed(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca %Packed, align 16
  %guard = alloca [8 x i8], align 8
  %tail = getelementptr i8, ptr %slot, i64 12
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  store i64 %a, ptr %guard
  store i8 %x, ptr %slot
  store i8 %y, ptr %tail
  call void @storage_clobber(ptr %slot, ptr %guard)
  %first = load i8, ptr %slot
  %last = load i8, ptr %tail
  %saved = load i64, ptr %guard
  %left = zext i8 %first to i64
  %right = zext i8 %last to i64
  %live = xor i64 %saved, %b
  %sum = add i64 %left, %right
  store i64 %sum, ptr %out
  ret i64 %live
}

define i64 @storage_padded(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca %Padded, align 16
  %guard = alloca [8 x i8], align 8
  %tail = getelementptr i8, ptr %slot, i64 31
  %x = trunc i64 %a to i8
  %y = trunc i64 %b to i8
  store i64 %a, ptr %guard
  store i8 %x, ptr %slot
  store i8 %y, ptr %tail
  call void @storage_clobber(ptr %slot, ptr %guard)
  %first = load i8, ptr %slot
  %last = load i8, ptr %tail
  %saved = load i64, ptr %guard
  %left = zext i8 %first to i64
  %right = zext i8 %last to i64
  %live = xor i64 %saved, %b
  %sum = add i64 %left, %right
  store i64 %sum, ptr %out
  ret i64 %live
}

define i64 @storage_word16(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca i16, align 8
  %guard = alloca i64, align 8
  %x = trunc i64 %a to i16
  store i16 %x, ptr %slot
  store i64 %b, ptr %guard
  call void @storage_clobber(ptr %slot, ptr %guard)
  %read = load i16, ptr %slot
  %wide = zext i16 %read to i64
  %saved = load i64, ptr %guard
  store i64 %wide, ptr %out
  %live = xor i64 %a, %saved
  ret i64 %live
}

define i64 @storage_word32(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca i32, align 8
  %guard = alloca i64, align 8
  %x = trunc i64 %a to i32
  store i32 %x, ptr %slot
  store i64 %b, ptr %guard
  call void @storage_clobber(ptr %slot, ptr %guard)
  %read = load i32, ptr %slot
  %wide = zext i32 %read to i64
  %saved = load i64, ptr %guard
  store i64 %wide, ptr %out
  %live = xor i64 %a, %saved
  ret i64 %live
}

define i64 @storage_probe() {
entry:
  %slot = alloca [32768 x i8], align 16
  %tail = getelementptr i8, ptr %slot, i64 32767
  store i8 33, ptr %slot
  store i8 91, ptr %tail
  %result = call i64 @storage_probe_sink(ptr %slot)
  ret i64 %result
}
