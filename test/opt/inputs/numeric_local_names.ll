source_filename = "numeric_local_names.ll"
target datalayout = "e-p:64:64-i64:64-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @numeric_external(i32)

@numeric_jump_table = constant [2 x ptr] [ptr blockaddress(@numeric_jump, %4), ptr blockaddress(@numeric_jump, %5)]
@numeric_address_only_table = constant [1 x ptr] [ptr blockaddress(@numeric_address_only, %2)]

; Merging later into entry moves %2 before %1 in the optimizer's IR.
define i32 @numeric_order(i32 %0) {
entry:
  br label %later
earlier:
  %1 = add i32 %2, 3
  ret i32 %1
later:
  %2 = xor i32 %0, 7
  br label %earlier
}

; Block labels consume the same numeric namespace as values.
define i32 @numeric_blocks(i32 %0) {
1:
  br label %4
2:
  %3 = add i32 %5, 3
  ret i32 %3
4:
  %5 = xor i32 %0, 7
  br label %2
}

define i32 @numeric_implicit(i32 %0) {
  %2 = add i32 %0, 1
  ret i32 %2
}

define i32 @numeric_loop(i32 %0) {
1:
  br label %2
2:
  %3 = phi i32 [ 0, %1 ], [ %6, %5 ]
  %4 = icmp ult i32 %3, %0
  br i1 %4, label %5, label %7
5:
  %6 = add i32 %3, 1
  br label %2
7:
  ret i32 %3
}

define i32 @numeric_call(i32 %0) {
entry:
  br label %later
earlier:
  %1 = add i32 %2, 3
  ret i32 %1
later:
  %2 = call i32 @numeric_external(i32 %0)
  br label %earlier
}

define i32 @numeric_switch(i32 %0) {
1:
  switch i32 %0, label %3 [
    i32 0, label %2
  ]
2:
  ret i32 7
3:
  ret i32 9
}

; Threading these empty destinations must also preserve their stored addresses.
define i32 @numeric_jump(i32 %0) {
entry:
  %1 = and i32 %0, 1
  %2 = getelementptr [2 x ptr], ptr @numeric_jump_table, i64 0, i32 %1
  %3 = load ptr, ptr %2
  indirectbr ptr %3, [label %4, label %5]
4:
  br label %6
5:
  br label %7
6:
  ret i32 17
7:
  ret i32 29
}

; A retained address still needs a block even without an indirectbr predecessor.
define i32 @numeric_address_only(i32 %0) {
entry:
  %1 = add i32 %0, 9
  br label %2
2:
  ret i32 %1
}

; Folding this diamond must not generate an invalid name such as %7.select.
define i32 @numeric_select(i32 %0) {
1:
  %2 = and i32 %0, 1
  %3 = icmp ne i32 %2, 0
  br i1 %3, label %4, label %5
4:
  br label %6
5:
  br label %6
6:
  %7 = phi i32 [ 17, %4 ], [ 29, %5 ]
  ret i32 %7
}

; Labels, quoted values and their escaped spellings share the generated namespace.
define i32 @quoted_select(i32 %"select.1") {
select:
  %"sel\65ct.2" = and i32 %"select.1", 1
  %cond = icmp ne i32 %"sel\65ct.2", 0
  br i1 %cond, label %yes, label %no
yes:
  br label %merge
no:
  br label %merge
merge:
  %"return value" = phi i32 [ 17, %yes ], [ 29, %no ]
  ret i32 %"return value"
}
