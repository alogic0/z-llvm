target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%Words = type { i64, i64 }
%WordBox = type { %Words }
%PaddedWord = type { i64, i16, [6 x i8] }
%PaddedWords = type { %Words, i16, [6 x i8] }
%PaddedBox = type { %PaddedWords }

declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
declare i64 @bounded_frame_helper(ptr, i64, i64)

define i64 @bounded_frame_pair(i64 %a, i64 %b, ptr %output) {
entry:
  %source = alloca %WordBox, align 8
  %destination = alloca %Words, align 8
  %bridge = alloca %PaddedWords, align 8
  %first = insertvalue { i64, i64 } poison, i64 %a, 0
  %both = insertvalue { i64, i64 } %first, i64 %b, 1
  store { i64, i64 } %both, ptr %source, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %bridge, ptr align 8 %source, i64 16, i1 false)
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %destination, ptr align 8 %bridge, i64 16, i1 false)
  store i64 0, ptr %source, align 8
  store i64 0, ptr %bridge, align 8
  %destination8 = getelementptr i8, ptr %destination, i64 8
  %actual_a = load i64, ptr %destination, align 8
  %actual_b = load i64, ptr %destination8, align 8
  %output8 = getelementptr i8, ptr %output, i64 8
  store i64 %actual_a, ptr %output, align 8
  store i64 %actual_b, ptr %output8, align 8
  %result = xor i64 %actual_a, %actual_b
  ret i64 %result
}

define i64 @bounded_frame_padded_pair(i64 %a, i64 %b, ptr %output) {
entry:
  %before = alloca i64, align 8
  %source = alloca %PaddedBox, align 16
  %destination = alloca %PaddedWords, align 16
  %after = alloca i64, align 8
  store i64 6148914691236517205, ptr %before, align 8
  store i64 -6148914691236517206, ptr %after, align 8
  %source8 = getelementptr i8, ptr %source, i64 8
  %source16 = getelementptr i8, ptr %source, i64 16
  store i64 %a, ptr %source, align 8
  store i64 %b, ptr %source8, align 8
  store i64 81985529216486895, ptr %source16, align 8
  %tag = trunc i64 %b to i16
  store i16 %tag, ptr %source16, align 2
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %destination, ptr align 16 %source, i64 24, i1 false)
  store i64 0, ptr %source, align 8
  store i64 0, ptr %source16, align 8
  %destination8 = getelementptr i8, ptr %destination, i64 8
  %destination16 = getelementptr i8, ptr %destination, i64 16
  %actual_a = load i64, ptr %destination, align 8
  %actual_b = load i64, ptr %destination8, align 8
  %actual_tail = load i64, ptr %destination16, align 8
  %output8 = getelementptr i8, ptr %output, i64 8
  %output16 = getelementptr i8, ptr %output, i64 16
  store i64 %actual_a, ptr %output, align 8
  store i64 %actual_b, ptr %output8, align 8
  store i64 %actual_tail, ptr %output16, align 8
  %guard_before = load i64, ptr %before, align 8
  %guard_after = load i64, ptr %after, align 8
  %guards = xor i64 %guard_before, %guard_after
  %data = xor i64 %actual_a, %actual_b
  %result = xor i64 %data, %guards
  ret i64 %result
}

define i64 @bounded_frame_padded_word(i64 %a, i64 %b, ptr %output) {
entry:
  %source = alloca %PaddedWord, align 8
  %destination = alloca { %PaddedWord }, align 8
  %source8 = getelementptr i8, ptr %source, i64 8
  store i64 %a, ptr %source, align 8
  store i64 -81985529216486896, ptr %source8, align 8
  %tag = trunc i64 %b to i16
  store i16 %tag, ptr %source8, align 2
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %destination, ptr align 8 %source, i64 16, i1 false)
  store i64 0, ptr %source8, align 8
  %destination8 = getelementptr i8, ptr %destination, i64 8
  %actual_a = load i64, ptr %destination, align 8
  %actual_tail = load i64, ptr %destination8, align 8
  %actual_tag = load i16, ptr %destination8, align 2
  %wide_tag = zext i16 %actual_tag to i64
  %output8 = getelementptr i8, ptr %output, i64 8
  store i64 %actual_a, ptr %output, align 8
  store i64 %actual_tail, ptr %output8, align 8
  %result = xor i64 %actual_a, %wide_tag
  ret i64 %result
}

define i64 @bounded_frame_call(i64 %a, i64 %b, ptr %output) {
entry:
  %before = alloca i64, align 8
  %slot = alloca %PaddedWords, align 16
  %after = alloca i64, align 8
  store i64 6148914691236517205, ptr %before, align 8
  store i64 -6148914691236517206, ptr %after, align 8
  %answer = call i64 @bounded_frame_helper(ptr %slot, i64 %a, i64 %b)
  %slot8 = getelementptr i8, ptr %slot, i64 8
  %slot16 = getelementptr i8, ptr %slot, i64 16
  %actual_a = load i64, ptr %slot, align 8
  %actual_b = load i64, ptr %slot8, align 8
  %actual_tail = load i64, ptr %slot16, align 8
  %output8 = getelementptr i8, ptr %output, i64 8
  %output16 = getelementptr i8, ptr %output, i64 16
  store i64 %actual_a, ptr %output, align 8
  store i64 %actual_b, ptr %output8, align 8
  store i64 %actual_tail, ptr %output16, align 8
  %guard_before = load i64, ptr %before, align 8
  %guard_after = load i64, ptr %after, align 8
  %guards = xor i64 %guard_before, %guard_after
  %live = add i64 %a, %b
  %data = xor i64 %live, %answer
  %result = xor i64 %data, %guards
  ret i64 %result
}
