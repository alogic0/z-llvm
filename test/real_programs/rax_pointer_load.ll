target datalayout = "e-p:64:64-i64:64"
target triple = "x86_64-unknown-linux-gnu"

declare ptr @rax_load_helper(ptr)

define i64 @rax_load_u8(ptr %slot, i64 %take, i64 %left, i64 %right, ptr %output) {
entry:
  %slot.saved = alloca ptr, align 8
  store ptr %slot, ptr %slot.saved, align 8
  %condition = icmp ne i64 %take, 0
  br i1 %condition, label %load, label %empty
load:
  %slot.loaded = load ptr, ptr %slot.saved, align 8
  %pointer = load ptr, ptr %slot.loaded, align 8
  %loaded = load i8, ptr %pointer, align 1
  %bits = zext i8 %loaded to i64
  %a = xor i64 %bits, %left
  %b = xor i64 %a, %right
  %result = xor i64 %b, %take
  store i64 %bits, ptr %output, align 8
  ret i64 %result
empty:
  store i64 0, ptr %output, align 8
  %zero = xor i64 %left, %right
  ret i64 %zero
}

define i64 @rax_load_u16(ptr %slot, i64 %take, i64 %left, i64 %right, ptr %output) {
entry:
  %slot.saved = alloca ptr, align 8
  store ptr %slot, ptr %slot.saved, align 8
  %condition = icmp ne i64 %take, 0
  br i1 %condition, label %load, label %empty
load:
  %slot.loaded = load ptr, ptr %slot.saved, align 8
  %pointer = load ptr, ptr %slot.loaded, align 8
  %loaded = load i16, ptr %pointer, align 1
  %bits = zext i16 %loaded to i64
  %a = xor i64 %bits, %left
  %b = xor i64 %a, %right
  %result = xor i64 %b, %take
  %address = ptrtoint ptr %pointer to i64
  %observed = xor i64 %bits, %address
  store i64 %observed, ptr %output, align 8
  ret i64 %result
empty:
  store i64 0, ptr %output, align 8
  %zero = xor i64 %left, %right
  ret i64 %zero
}

define i64 @rax_load_u32(ptr %slot, i64 %take, i64 %left, i64 %right, ptr %output) {
entry:
  %slot.saved = alloca ptr, align 8
  store ptr %slot, ptr %slot.saved, align 8
  %condition = icmp ne i64 %take, 0
  br i1 %condition, label %load, label %empty
load:
  %slot.loaded = load ptr, ptr %slot.saved, align 8
  %pointer = load ptr, ptr %slot.loaded, align 8
  %loaded = load i32, ptr %pointer, align 1
  %bits = zext i32 %loaded to i64
  %a = xor i64 %bits, %left
  %b = xor i64 %a, %right
  %result = xor i64 %b, %take
  store i64 %bits, ptr %output, align 8
  ret i64 %result
empty:
  store i64 0, ptr %output, align 8
  %zero = xor i64 %left, %right
  ret i64 %zero
}

define i64 @rax_load_u64(ptr %slot, i64 %take, i64 %left, i64 %right, ptr %output) {
entry:
  %slot.saved = alloca ptr, align 8
  store ptr %slot, ptr %slot.saved, align 8
  %condition = icmp ne i64 %take, 0
  br i1 %condition, label %load, label %empty
load:
  %slot.loaded = load ptr, ptr %slot.saved, align 8
  %pointer = load ptr, ptr %slot.loaded, align 8
  %loaded = load i64, ptr %pointer, align 1
  %bits = add i64 %loaded, 0
  %a = xor i64 %bits, %left
  %b = xor i64 %a, %right
  %result = xor i64 %b, %take
  %address = ptrtoint ptr %pointer to i64
  %observed = xor i64 %bits, %address
  store i64 %observed, ptr %output, align 8
  ret i64 %result
empty:
  store i64 0, ptr %output, align 8
  %zero = xor i64 %left, %right
  ret i64 %zero
}

define i64 @rax_load_pointer(ptr %slot, i64 %take, i64 %left, i64 %right, ptr %output) {
entry:
  %slot.saved = alloca ptr, align 8
  store ptr %slot, ptr %slot.saved, align 8
  %condition = icmp ne i64 %take, 0
  br i1 %condition, label %load, label %empty
load:
  %slot.loaded = load ptr, ptr %slot.saved, align 8
  %pointer = load ptr, ptr %slot.loaded, align 8
  %loaded = load ptr, ptr %pointer, align 1
  %bits = ptrtoint ptr %loaded to i64
  %a = xor i64 %bits, %left
  %b = xor i64 %a, %right
  %result = xor i64 %b, %take
  %address = ptrtoint ptr %pointer to i64
  %observed = xor i64 %bits, %address
  store i64 %observed, ptr %output, align 8
  ret i64 %result
empty:
  store i64 0, ptr %output, align 8
  %zero = xor i64 %left, %right
  ret i64 %zero
}

define i64 @rax_load_called(ptr %slot, i64 %take, i64 %left, i64 %right, ptr %output) {
entry:
  %slot.saved = alloca ptr, align 8
  store ptr %slot, ptr %slot.saved, align 8
  %condition = icmp ne i64 %take, 0
  br i1 %condition, label %load, label %empty
load:
  %slot.loaded = load ptr, ptr %slot.saved, align 8
  %pointer = call ptr @rax_load_helper(ptr %slot.loaded)
  %loaded = load i64, ptr %pointer, align 1
  %bits = add i64 %loaded, 0
  %a = xor i64 %bits, %left
  %b = xor i64 %a, %right
  %result = xor i64 %b, %take
  %address = ptrtoint ptr %pointer to i64
  %observed = xor i64 %bits, %address
  store i64 %observed, ptr %output, align 8
  ret i64 %result
empty:
  store i64 0, ptr %output, align 8
  %zero = xor i64 %left, %right
  ret i64 %zero
}

define i64 @rax_load_loop(ptr %base, i64 %length, i64 %left, i64 %right, ptr %output) {
entry:
  %pointer.slot = alloca ptr, align 8
  %index.slot = alloca i64, align 8
  %sum.slot = alloca i64, align 8
  store i64 0, ptr %index.slot, align 8
  store i64 %left, ptr %sum.slot, align 8
  br label %loop
loop:
  %index = load i64, ptr %index.slot, align 8
  %more = icmp ult i64 %index, %length
  br i1 %more, label %read, label %exit
read:
  %address = getelementptr [56 x i8], ptr %base, i64 %index
  store ptr %address, ptr %pointer.slot, align 8
  %pointer = load ptr, ptr %pointer.slot, align 8
  %value = load i32, ptr %pointer, align 8
  %wide = zext i32 %value to i64
  %address.bits = ptrtoint ptr %address to i64
  %delta = xor i64 %wide, %address.bits
  %sum = load i64, ptr %sum.slot, align 8
  %updated = add i64 %sum, %delta
  store i64 %updated, ptr %sum.slot, align 8
  %next = add i64 %index, 1
  store i64 %next, ptr %index.slot, align 8
  br label %loop
exit:
  %final = load i64, ptr %sum.slot, align 8
  store i64 %final, ptr %output, align 8
  %result = xor i64 %final, %right
  ret i64 %result
}
