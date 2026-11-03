target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

%Object = type { i8, i64, ptr, [2 x i16], ptr }
@global_object = internal global %Object { i8 165, i64 4294967295, ptr getelementptr (i8, ptr @global_payload, i64 3), [2 x i16] [i16 65535, i16 4660], ptr @global_address_echo }, align 64
@global_payload = private constant [8 x i8] c"payload\00", align 8
@global_bits = private constant { ptr, i128 } { ptr inttoptr (i64 -1 to ptr), i128 -1 }, align 16
@unreferenced_pointer = internal global { ptr } { ptr @must_not_be_imported }, align 8

declare i64 @global_address_echo(i64)
declare void @must_not_be_imported()

define ptr @global_object_address() {
entry:
  %address = getelementptr i8, ptr @global_object, i64 0
  ret ptr %address
}

define ptr @global_payload_address() {
entry:
  %address = getelementptr i8, ptr @global_payload, i64 0
  ret ptr %address
}

define ptr @global_bits_address() {
entry:
  %address = getelementptr i8, ptr @global_bits, i64 0
  ret ptr %address
}

define i64 @global_live_offset(i64 %live) {
entry:
  %address = getelementptr i8, ptr @global_object, i64 8
  %bits = ptrtoint ptr %address to i64
  %result = xor i64 %bits, %live
  ret i64 %result
}
