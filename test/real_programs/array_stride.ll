target datalayout = "e-p:64:64-i64:64-i24:32"
target triple = "x86_64-unknown-linux-gnu"

define i64 @array_stride_eight(ptr %base, i64 %index, i64 %live, ptr %output, i64 %salt) {
entry:
  %address = getelementptr [8 x i8], ptr %base, i64 %index
  store ptr %address, ptr %output, align 8
  %bits = ptrtoint ptr %address to i64
  %base_bits = ptrtoint ptr %base to i64
  %a = xor i64 %bits, %base_bits
  %b = xor i64 %a, %index
  %c = xor i64 %b, %live
  %result = xor i64 %c, %salt
  ret i64 %result
}

define i64 @array_stride_padding(ptr %base, i64 %index, i64 %live, ptr %output, i64 %salt) {
entry:
  %address = getelementptr [1 x i24], ptr %base, i64 %index
  store ptr %address, ptr %output, align 8
  %bits = ptrtoint ptr %address to i64
  %base_bits = ptrtoint ptr %base to i64
  %a = xor i64 %bits, %base_bits
  %b = xor i64 %a, %index
  %c = xor i64 %b, %live
  %result = xor i64 %c, %salt
  ret i64 %result
}

define i64 @array_stride_nested(ptr %base, i64 %index, i64 %live, ptr %output, i64 %salt) {
entry:
  %address = getelementptr [2 x [2 x i64]], ptr %base, i64 %index
  store ptr %address, ptr %output, align 8
  %bits = ptrtoint ptr %address to i64
  %base_bits = ptrtoint ptr %base to i64
  %a = xor i64 %bits, %base_bits
  %b = xor i64 %a, %index
  %c = xor i64 %b, %live
  %result = xor i64 %c, %salt
  ret i64 %result
}

define i64 @array_stride_loaded(ptr %base, i64 %index, i64 %live, ptr %output, i64 %salt) {
entry:
  %base_slot = alloca ptr, align 8
  %index_slot = alloca i64, align 8
  store ptr %base, ptr %base_slot, align 8
  store i64 %index, ptr %index_slot, align 8
  %loaded_index = load i64, ptr %index_slot, align 8
  %loaded_base = load ptr, ptr %base_slot, align 8
  %address = getelementptr [8 x i8], ptr %loaded_base, i64 %loaded_index
  store ptr %address, ptr %output, align 8
  %bits = ptrtoint ptr %address to i64
  %base_bits = ptrtoint ptr %base to i64
  %a = xor i64 %bits, %base_bits
  %b = xor i64 %a, %index
  %c = xor i64 %b, %live
  %result = xor i64 %c, %salt
  ret i64 %result
}
