target datalayout = "e-p:64:64-i64:64-i24:32"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @general_stride_helper(i64)

define i64 @general_stride_56(ptr %base, i64 %index, i64 %live, ptr %output, i64 %salt) {
entry:
  %address = getelementptr [56 x i8], ptr %base, i64 %index
  store ptr %address, ptr %output, align 8
  %bits = ptrtoint ptr %address to i64
  %base_bits = ptrtoint ptr %base to i64
  %a = xor i64 %bits, %base_bits
  %b = xor i64 %a, %index
  %c = xor i64 %b, %live
  %result = xor i64 %c, %salt
  ret i64 %result
}

define i64 @general_stride_padding(ptr %base, i64 %index, i64 %live, ptr %output, i64 %salt) {
entry:
  %address = getelementptr [3 x i24], ptr %base, i64 %index
  store ptr %address, ptr %output, align 8
  %bits = ptrtoint ptr %address to i64
  %base_bits = ptrtoint ptr %base to i64
  %a = xor i64 %bits, %base_bits
  %b = xor i64 %a, %index
  %c = xor i64 %b, %live
  %result = xor i64 %c, %salt
  ret i64 %result
}

define i64 @general_stride_nested(ptr %base, i64 %index, i64 %live, ptr %output, i64 %salt) {
entry:
  %address = getelementptr [3 x [5 x i8]], ptr %base, i64 %index
  store ptr %address, ptr %output, align 8
  %bits = ptrtoint ptr %address to i64
  %base_bits = ptrtoint ptr %base to i64
  %a = xor i64 %bits, %base_bits
  %b = xor i64 %a, %index
  %c = xor i64 %b, %live
  %result = xor i64 %c, %salt
  ret i64 %result
}

define i64 @general_stride_called(ptr %base, i64 %index, i64 %live, ptr %output, i64 %salt) {
entry:
  %base_slot = alloca ptr, align 8
  %index_slot = alloca i64, align 8
  store ptr %base, ptr %base_slot, align 8
  store i64 %index, ptr %index_slot, align 8
  %loaded_index = load i64, ptr %index_slot, align 8
  %returned_index = call i64 @general_stride_helper(i64 %loaded_index)
  %loaded_base = load ptr, ptr %base_slot, align 8
  %address = getelementptr [255 x i8], ptr %loaded_base, i64 %returned_index
  store ptr %address, ptr %output, align 8
  %bits = ptrtoint ptr %address to i64
  %base_bits = ptrtoint ptr %base to i64
  %a = xor i64 %bits, %base_bits
  %b = xor i64 %a, %index
  %c = xor i64 %b, %live
  %result = xor i64 %c, %salt
  ret i64 %result
}

define i64 @general_stride_store(ptr %base, i64 %index, i64 %live, ptr %output, i64 %salt) {
entry:
  %address = getelementptr [56 x i8], ptr %base, i64 %index
  store i64 %live, ptr %address, align 8
  store ptr %address, ptr %output, align 8
  %bits = ptrtoint ptr %address to i64
  %base_bits = ptrtoint ptr %base to i64
  %a = xor i64 %bits, %base_bits
  %b = xor i64 %a, %index
  %c = xor i64 %b, %live
  %result = xor i64 %c, %salt
  ret i64 %result
}
