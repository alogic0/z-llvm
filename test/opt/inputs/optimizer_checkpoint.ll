@checkpoint.a = private unnamed_addr constant i32 7
@checkpoint.b = private unnamed_addr constant i32 7
@checkpoint.p = global ptr getelementptr (i32, ptr @checkpoint.a, i64 0)

define i32 @checkpoint_global() {
entry:
  %p = load ptr, ptr @checkpoint.p
  %v = load i32, ptr %p
  ret i32 %v
}

define i32 @checkpoint_loop(i32 %n) {
entry:
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %next, %loop ]
  %sum = phi i32 [ 0, %entry ], [ %copy, %loop ]
  %added = add i32 %sum, %i
  %copy = add i32 %added, 0
  %next = add i32 %i, 1
  %done = icmp eq i32 %next, %n
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %copy
}

define i32 @checkpoint_forward(i32 %x) {
entry:
  br label %producer
exit:
  ret i32 %a
middle:
  %a = add i32 %b, 0
  br label %exit
producer:
  %b = add i32 %x, 0
  br label %middle
}

define i32 @checkpoint_lane(i32 %x) {
entry:
  %v = insertelement <4 x i32> zeroinitializer, i32 %x, i1 3
  %r = extractelement <4 x i32> %v, i32 1
  ret i32 %r
}

define i32 @checkpoint_signed_lane(i32 %x) {
entry:
  %v = insertelement <4 x i32> zeroinitializer, i32 %x, i1 -1
  %r = extractelement <4 x i32> %v, i8 257
  ret i32 %r
}

define i32 @checkpoint_bypass(i32 %x) {
entry:
  %input = insertelement <4 x i32> zeroinitializer, i32 %x, i32 1
  %v = insertelement <4 x i32> %input, i32 42, i32 0
  %r = extractelement <4 x i32> %v, i1 3
  ret i32 %r
}

define i32 @checkpoint_distinct(i32 %x) {
entry:
  %v = insertelement <4 x i32> zeroinitializer, i32 %x, i1 3
  %r = extractelement <4 x i32> %v, i32 3
  ret i32 %r
}

define i32 @checkpoint_shuffle(i32 %x) {
entry:
  %input = insertelement <4 x i32> zeroinitializer, i32 %x, i32 2
  %v = shufflevector <4 x i32> %input, <4 x i32> poison, <4 x i32> <i32 3, i32 2, i32 1, i32 0>
  %r = extractelement <4 x i32> %v, i1 3
  ret i32 %r
}

define i8 @checkpoint_shl() {
entry:
  %r = shl i8 1, 256
  ret i8 %r
}

define i8 @checkpoint_lshr() {
entry:
  %r = lshr i8 -128, 257
  ret i8 %r
}

define i8 @checkpoint_ashr() {
entry:
  %r = ashr i8 -4, -255
  ret i8 %r
}
