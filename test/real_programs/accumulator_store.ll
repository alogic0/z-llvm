target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
declare ptr @accumulator_store_destination(ptr)
declare i64 @accumulator_store_clobber(i64)
define i64 @accumulator_store_i64_load_zero(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = load ptr, ptr %slot, align 8
  store i64 0, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_i64_load_ones(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = load ptr, ptr %slot, align 8
  store i64 -1, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_i64_load_large(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = load ptr, ptr %slot, align 8
  store i64 -2401053092306725256, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_i64_load_input(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = load ptr, ptr %slot, align 8
  store i64 %input, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_i64_load_derived(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %derived = add i64 %input, 17
  %destination = load ptr, ptr %slot, align 8
  store i64 %derived, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_i64_load_self(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = load ptr, ptr %slot, align 8
  %self = ptrtoint ptr %destination to i64
  store i64 %self, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_i64_call_zero(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = call ptr @accumulator_store_destination(ptr %slot)
  store i64 0, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_i64_call_ones(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = call ptr @accumulator_store_destination(ptr %slot)
  store i64 -1, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_i64_call_large(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = call ptr @accumulator_store_destination(ptr %slot)
  store i64 -2401053092306725256, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_i64_call_input(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = call ptr @accumulator_store_destination(ptr %slot)
  store i64 %input, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_i64_call_derived(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %derived = add i64 %input, 17
  %destination = call ptr @accumulator_store_destination(ptr %slot)
  store i64 %derived, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_i64_call_self(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = call ptr @accumulator_store_destination(ptr %slot)
  %self = ptrtoint ptr %destination to i64
  store i64 %self, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_ptr_load_zero(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = load ptr, ptr %slot, align 8
  store ptr null, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_ptr_load_ones(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = load ptr, ptr %slot, align 8
  store ptr inttoptr (i64 -1 to ptr), ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_ptr_load_large(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = load ptr, ptr %slot, align 8
  store ptr inttoptr (i64 -2401053092306725256 to ptr), ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_ptr_load_input(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %pointer_value = inttoptr i64 %input to ptr
  %destination = load ptr, ptr %slot, align 8
  store ptr %pointer_value, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_ptr_load_derived(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %derived = add i64 %input, 17
  %pointer_value = inttoptr i64 %derived to ptr
  %destination = load ptr, ptr %slot, align 8
  store ptr %pointer_value, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_ptr_load_self(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = load ptr, ptr %slot, align 8
  store ptr %destination, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_ptr_call_zero(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = call ptr @accumulator_store_destination(ptr %slot)
  store ptr null, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_ptr_call_ones(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = call ptr @accumulator_store_destination(ptr %slot)
  store ptr inttoptr (i64 -1 to ptr), ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_ptr_call_large(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = call ptr @accumulator_store_destination(ptr %slot)
  store ptr inttoptr (i64 -2401053092306725256 to ptr), ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_ptr_call_input(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %pointer_value = inttoptr i64 %input to ptr
  %destination = call ptr @accumulator_store_destination(ptr %slot)
  store ptr %pointer_value, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_ptr_call_derived(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %derived = add i64 %input, 17
  %pointer_value = inttoptr i64 %derived to ptr
  %destination = call ptr @accumulator_store_destination(ptr %slot)
  store ptr %pointer_value, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}

define i64 @accumulator_store_ptr_call_self(ptr %slot, i64 %input, i64 %live, ptr %out) {
entry:
  %destination = call ptr @accumulator_store_destination(ptr %slot)
  store ptr %destination, ptr %destination, align 8
  %written = load i64, ptr %destination, align 8
  %clobber = call i64 @accumulator_store_clobber(i64 %live)
  store i64 %clobber, ptr %out, align 8
  %answer = add i64 %written, %live
  ret i64 %answer
}
