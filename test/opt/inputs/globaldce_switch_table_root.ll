@switch.table = private unnamed_addr constant [3 x i32] [i32 11, i32 13, i32 17], align 4
@unused.table = private unnamed_addr constant [2 x i32] [i32 1, i32 2], align 4

@dense_switch = alias i32 (i8), ptr @switch.dense

define private i32 @switch.dense(i8 %idx) {
entry:
  %wide = zext nneg i8 %idx to i64
  %gep = getelementptr inbounds nuw i32, ptr @switch.table, i64 %wide
  %value = load i32, ptr %gep, align 4
  ret i32 %value
}
