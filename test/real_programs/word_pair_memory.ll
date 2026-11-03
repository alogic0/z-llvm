target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%PairBox = type { { ptr, i64 } }

declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

define i64 @word_pair_copy(ptr %pointer, i64 %length, ptr %output) {
entry:
  %source = alloca %PairBox, align 8
  %destination = alloca %PairBox, align 8
  %first = insertvalue { ptr, i64 } poison, ptr %pointer, 0
  %both = insertvalue { ptr, i64 } %first, i64 %length, 1
  store { ptr, i64 } %both, ptr %source, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %destination, ptr align 8 %source, i64 16, i1 false)
  %source0 = getelementptr i8, ptr %source, i64 0
  store ptr null, ptr %source0, align 8
  %destination0 = getelementptr i8, ptr %destination, i64 0
  %destination8 = getelementptr i8, ptr %destination, i64 8
  %actual_pointer = load ptr, ptr %destination0, align 8
  %actual_length = load i64, ptr %destination8, align 8
  %output8 = getelementptr i8, ptr %output, i64 8
  store ptr %actual_pointer, ptr %output, align 8
  store i64 %actual_length, ptr %output8, align 8
  ret i64 %actual_length
}

define i64 @word_pair_extract(ptr %pointer, i64 %length) {
entry:
  %slot = alloca %PairBox, align 8
  %first = insertvalue { ptr, i64 } poison, i64 %length, 1
  %both = insertvalue { ptr, i64 } %first, ptr %pointer, 0
  store { ptr, i64 } %both, ptr %slot, align 8
  %actual_pointer = extractvalue { ptr, i64 } %both, 0
  %actual_length = extractvalue { ptr, i64 } %both, 1
  %address = ptrtoint ptr %actual_pointer to i64
  %result = xor i64 %actual_length, %address
  ret i64 %result
}
