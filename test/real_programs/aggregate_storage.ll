target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
%File = type { i32, { i8 }, [3 x i8] }
%Stack = type { ptr, i32, [4 x i8], i64 }
%Union = type { <{ { i64, i16, [6 x i8] }, [16 x i8] }>, i8, [7 x i8] }
%Result = type { %Union, i16, [6 x i8] }
%Large = type { [32 x i64] }
@aggregate_marker = global i64 55, align 8
declare i64 @aggregate_storage_fill(ptr, i64, i64, i64)
declare i64 @aggregate_permutation_helper(i64, i64, i64, i64)
declare { ptr, i64 } @aggregate_pair_helper(ptr, i64)
declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)

define i64 @aggregate_frame_8(i64 %a, i64 %b, ptr %output) {
entry:
  %before = alloca i64, align 8
  %slot = alloca %File, align 16
  %after = alloca i64, align 8
  store i64 6148914691236517205, ptr %before, align 8
  store i64 -6148914691236517206, ptr %after, align 8
  %answer = call i64 @aggregate_storage_fill(ptr %slot, i64 8, i64 %a, i64 %b)
  %last_address = getelementptr i8, ptr %slot, i64 0
  %first = load i64, ptr %slot, align 8
  %last = load i64, ptr %last_address, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %output, ptr align 16 %slot, i64 8, i1 false)
  %guard0 = load i64, ptr %before, align 8
  %guard1 = load i64, ptr %after, align 8
  %guards = xor i64 %guard0, %guard1
  %data = xor i64 %first, %last
  %guarded = add i64 %data, %guards
  %result = add i64 %guarded, %answer
  ret i64 %result
}

define i64 @aggregate_frame_24(i64 %a, i64 %b, ptr %output) {
entry:
  %before = alloca i64, align 8
  %slot = alloca %Stack, align 16
  %after = alloca i64, align 8
  store i64 6148914691236517205, ptr %before, align 8
  store i64 -6148914691236517206, ptr %after, align 8
  %answer = call i64 @aggregate_storage_fill(ptr %slot, i64 24, i64 %a, i64 %b)
  %last_address = getelementptr i8, ptr %slot, i64 16
  %first = load i64, ptr %slot, align 8
  %last = load i64, ptr %last_address, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %output, ptr align 16 %slot, i64 24, i1 false)
  %guard0 = load i64, ptr %before, align 8
  %guard1 = load i64, ptr %after, align 8
  %guards = xor i64 %guard0, %guard1
  %data = xor i64 %first, %last
  %guarded = add i64 %data, %guards
  %result = add i64 %guarded, %answer
  ret i64 %result
}

define i64 @aggregate_frame_48(i64 %a, i64 %b, ptr %output) {
entry:
  %before = alloca i64, align 8
  %slot = alloca %Result, align 16
  %after = alloca i64, align 8
  store i64 6148914691236517205, ptr %before, align 8
  store i64 -6148914691236517206, ptr %after, align 8
  %answer = call i64 @aggregate_storage_fill(ptr %slot, i64 48, i64 %a, i64 %b)
  %last_address = getelementptr i8, ptr %slot, i64 40
  %first = load i64, ptr %slot, align 8
  %last = load i64, ptr %last_address, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %output, ptr align 16 %slot, i64 48, i1 false)
  %guard0 = load i64, ptr %before, align 8
  %guard1 = load i64, ptr %after, align 8
  %guards = xor i64 %guard0, %guard1
  %data = xor i64 %first, %last
  %guarded = add i64 %data, %guards
  %result = add i64 %guarded, %answer
  ret i64 %result
}

define i64 @aggregate_frame_256(i64 %a, i64 %b, ptr %output) {
entry:
  %before = alloca i64, align 8
  %slot = alloca %Large, align 16
  %after = alloca i64, align 8
  store i64 6148914691236517205, ptr %before, align 8
  store i64 -6148914691236517206, ptr %after, align 8
  %answer = call i64 @aggregate_storage_fill(ptr %slot, i64 256, i64 %a, i64 %b)
  %last_address = getelementptr i8, ptr %slot, i64 248
  %first = load i64, ptr %slot, align 8
  %last = load i64, ptr %last_address, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %output, ptr align 16 %slot, i64 256, i1 false)
  %guard0 = load i64, ptr %before, align 8
  %guard1 = load i64, ptr %after, align 8
  %guards = xor i64 %guard0, %guard1
  %data = xor i64 %first, %last
  %guarded = add i64 %data, %guards
  %result = add i64 %guarded, %answer
  ret i64 %result
}

define i64 @aggregate_replace(ptr %source, ptr %destination, i64 %extra) {
entry:
  %original = load { ptr, i64 }, ptr %source, align 8
  %length = extractvalue { ptr, i64 } %original, 1
  %new_length = add i64 %length, %extra
  %replaced = insertvalue { ptr, i64 } %original, i64 %new_length, 1
  store { ptr, i64 } %replaced, ptr %destination, align 8
  ret i64 %length
}

define { ptr, i64 } @aggregate_return_pi(ptr %source) {
entry:
  %pair = load { ptr, i64 }, ptr %source, align 8
  ret { ptr, i64 } %pair
}

define { i64, ptr } @aggregate_return_ip(ptr %source) {
entry:
  %pair = load { i64, ptr }, ptr %source, align 8
  ret { i64, ptr } %pair
}

define { ptr, ptr } @aggregate_return_pp(ptr %source) {
entry:
  %pair = load { ptr, ptr }, ptr %source, align 8
  ret { ptr, ptr } %pair
}

define { i64, i64 } @aggregate_return_ii(ptr %source) {
entry:
  %pair = load { i64, i64 }, ptr %source, align 8
  ret { i64, i64 } %pair
}

define i64 @aggregate_call(ptr %input, i64 %length, ptr %output, i64 %live) {
entry:
  %pair = call { ptr, i64 } @aggregate_pair_helper(ptr %input, i64 %length)
  store { ptr, i64 } %pair, ptr %output, align 8
  %returned_length = extractvalue { ptr, i64 } %pair, 1
  %result = xor i64 %returned_length, %live
  ret i64 %result
}
define i64 @aggregate_permutation(i64 %a, i64 %b, i64 %c, i64 %d) {
entry:
  %answer = call i64 @aggregate_permutation_helper(i64 %d, i64 %c, i64 %a, i64 %b)
  ret i64 %answer
}
define i64 @aggregate_symbol(ptr %output) {
entry:
  %pair = insertvalue { ptr, i64 } { ptr @aggregate_marker, i64 1 }, i64 55, 1
  store { ptr, i64 } %pair, ptr %output, align 8
  ret i64 55
}
