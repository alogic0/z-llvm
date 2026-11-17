; ModuleID = '<stdin>'
source_filename = "<stdin>"
target datalayout = "e-m:e-p:64:64-i16:32-i32:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @layout_i80_array(i64 %seed) {
entry:
  %result = xor i64 %seed, 1048584
  ret i64 %result
}

define i64 @layout_i80_struct(i64 %seed) {
entry:
  %result = xor i64 %seed, 1572872
  ret i64 %result
}

define i64 @layout_i24_array(i64 %seed) {
entry:
  %result = xor i64 %seed, 524296
  ret i64 %result
}

define i64 @layout_i24_struct(i64 %seed) {
entry:
  %result = xor i64 %seed, 1048584
  ret i64 %result
}

define i64 @layout_i9_array(i64 %seed) {
entry:
  %result = xor i64 %seed, 262148
  ret i64 %result
}
