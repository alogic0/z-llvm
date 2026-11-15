target datalayout = "e-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define void @negate80(ptr %input, ptr %output) {
entry:
  %x = load x86_fp80, ptr %input, align 1
  %n = fneg x86_fp80 %x
  store x86_fp80 %n, ptr %output, align 1
  ret void
}

define void @negate128(ptr %input, ptr %output) {
entry:
  %x = load fp128, ptr %input, align 1
  %n = fneg fp128 %x
  store fp128 %n, ptr %output, align 1
  ret void
}

define void @negate_vector80(ptr %input, ptr %output) {
entry:
  %in1 = getelementptr i8, ptr %input, i64 16
  %out1 = getelementptr i8, ptr %output, i64 16
  %x = load x86_fp80, ptr %input, align 1
  %y = load x86_fp80, ptr %in1, align 1
  %v0 = insertelement <2 x x86_fp80> poison, x86_fp80 %x, i32 0
  %v = insertelement <2 x x86_fp80> %v0, x86_fp80 %y, i32 1
  %n = fneg <2 x x86_fp80> %v
  %a = extractelement <2 x x86_fp80> %n, i32 0
  %b = extractelement <2 x x86_fp80> %n, i32 1
  store x86_fp80 %a, ptr %output, align 1
  store x86_fp80 %b, ptr %out1, align 1
  ret void
}

define void @negate_vector128(ptr %input, ptr %output) {
entry:
  %in1 = getelementptr i8, ptr %input, i64 16
  %out1 = getelementptr i8, ptr %output, i64 16
  %x = load fp128, ptr %input, align 1
  %y = load fp128, ptr %in1, align 1
  %v0 = insertelement <2 x fp128> poison, fp128 %x, i32 0
  %v = insertelement <2 x fp128> %v0, fp128 %y, i32 1
  %n = fneg <2 x fp128> %v
  %a = extractelement <2 x fp128> %n, i32 0
  %b = extractelement <2 x fp128> %n, i32 1
  store fp128 %a, ptr %output, align 1
  store fp128 %b, ptr %out1, align 1
  ret void
}
