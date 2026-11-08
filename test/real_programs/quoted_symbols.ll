target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@"switch.table.map.Custom([]const u8,main.Module,true).getOrPut" = private unnamed_addr constant [4 x i64] [i64 17, i64 -9223372036854775799, i64 -1, i64 71], align 8
@"switch.table.map.Custom(void,void,true).checkedHash" = private unnamed_addr constant [8 x i64] [i64 101, i64 3, i64 -7, i64 4294967297, i64 109, i64 11, i64 -13, i64 9223372036854775807], align 8
@"quote\22-backslash\5C31,()[]{}<>;" = private constant i64 1311768467463790320, align 8
@qs_data = global [80 x i8] zeroinitializer, align 16
@"chain,first" = internal alias [80 x i8], ptr @"chain,sec\6Fnd"
@"chain,second" = internal alias [80 x i8], ptr @"qs_d\61ta"
@"init,alias" = internal alias [80 x i8], ptr @"qs_data"
@"pointer,initializer" = private constant ptr getelementptr (i8, ptr @"init,ali\61s", i64 8), align 8

declare i64 @qs_check(i64, i64, i64, i64)

define i64 @quoted_four(i64 %index) {
entry:
  %offset = shl i64 %index, 3
  %p = getelementptr inbounds i8, ptr @"switch.table.map.Custom([]const u8,main.Module,true).getOrPut", i64 %offset
  %word = load i64, ptr %p, align 8
  ret i64 %word
}

define i64 @quoted_eight(i64 %index) {
entry:
  %offset = shl i64 %index, 3
  %p = getelementptr inbounds i8, ptr @"switch.table.map.Custom(void,void,true).checkedHash", i64 %offset
  %word = load i64, ptr %p, align 8
  ret i64 %word
}

define i64 @quoted_initializer(i64 %index) {
entry:
  %base = load ptr, ptr @"pointer,initializ\65r", align 8
  %offset = shl i64 %index, 3
  %p = getelementptr i8, ptr %base, i64 %offset
  %word = load i64, ptr %p, align 8
  ret i64 %word
}

define i64 @quoted_literal() {
entry:
  %word = load i64, ptr @"quote\22-backslash\5C31,()[]{}<>;", align 8
  ret i64 %word
}

define i64 @quoted_call(i64 %seed) {
entry:
  %called = call i64 @qs_check(i64 ptrtoint (ptr getelementptr (i8, ptr @"chain,fi\72st", i64 17) to i64), i64 ptrtoint (ptr getelementptr (i8, ptr @"qs_data", i64 31) to i64), i64 ptrtoint (ptr getelementptr (i8, ptr @"qs_d\61ta", i64 -8) to i64), i64 %seed)
  %result = xor i64 %called, %seed
  ret i64 %result
}

define i64 @quoted_mutate(i64 %index, i64 %value) {
entry:
  %offset = shl i64 %index, 3
  %within = add i64 %offset, 8
  %p = getelementptr i8, ptr @"chain,first", i64 %within
  %old = load i64, ptr %p, align 8
  store i64 %value, ptr %p, align 8
  ret i64 %old
}

define i64 @quoted_phi(i64 %index, i1 %choose) {
entry:
  br i1 %choose, label %left, label %right
left:
  br label %join
right:
  br label %join
join:
  %base = phi ptr [ @"switch.table.map.Custom([]const u8,main.Module,true).getOrPut", %left ], [ @"switch.table.map.Custom(void,void,true).checkedHash", %right ]
  %offset = shl i64 %index, 3
  %p = getelementptr i8, ptr %base, i64 %offset
  %word = load i64, ptr %p, align 8
  ret i64 %word
}
