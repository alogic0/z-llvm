target triple = "x86_64-unknown-linux-gnu"
@branch_table = internal global [4 x ptr] [ptr blockaddress(@indirect_branch_mutable, %a), ptr blockaddress(@indirect_branch_mutable, %b), ptr blockaddress(@indirect_branch_mutable, %c), ptr blockaddress(@indirect_branch_mutable, %d)]
@loop_table = internal constant [2 x ptr] [ptr blockaddress(@indirect_branch_loop, %exit), ptr blockaddress(@indirect_branch_loop, %body)]
@packed_table = internal constant { i8, <{ ptr, i8, ptr }> } { i8 90, <{ ptr, i8, ptr }> <{ ptr blockaddress(@indirect_branch_packed, %left), i8 61, ptr blockaddress(@indirect_branch_packed, %right) }> }, align 8
declare i64 @indirect_branch_noise(i64)

define i64 @indirect_branch_packed(i64 %index, i64 %seed) {
entry:
 %offset = mul i64 %index, 9
 %position = add i64 %offset, 1
 %slot = getelementptr i8, ptr @packed_table, i64 %position
 %target = load ptr, ptr %slot, align 1
 %noise = call i64 @indirect_branch_noise(i64 %seed)
 indirectbr ptr %target, [label %left, label %right]
left:
 %a = add i64 %noise, 777
 ret i64 %a
right:
 %b = xor i64 %noise, 999
 ret i64 %b
}

define i64 @indirect_branch_mutable(i64 %index, i64 %seed) {
entry:
 %zero = getelementptr ptr, ptr @branch_table, i64 0
 %one = getelementptr ptr, ptr @branch_table, i64 1
 %old0 = load ptr, ptr %zero
 %old1 = load ptr, ptr %one
 store ptr %old1, ptr %zero
 store ptr %old0, ptr %one
 %slot = getelementptr ptr, ptr @branch_table, i64 %index
 %target = load ptr, ptr %slot
 %noise = call i64 @indirect_branch_noise(i64 %seed)
 indirectbr ptr %target, [label %a, label %b, label %c, label %d]
a:
 %aa = add i64 %noise, 17
 ret i64 %aa
b:
 %bb = xor i64 %noise, 91
 ret i64 %bb
c:
 %cc = sub i64 %noise, %seed
 ret i64 %cc
d:
 %dd = mul i64 %noise, 3
 ret i64 %dd
}

define i64 @indirect_branch_loop(i64 %count, i64 %seed) {
entry:
 br label %loop
loop:
 %i = phi i64 [ 0, %entry ], [ %next, %body ]
 %sum = phi i64 [ %seed, %entry ], [ %updated, %body ]
 %more = icmp ult i64 %i, %count
 %index = zext i1 %more to i64
 %slot = getelementptr ptr, ptr @loop_table, i64 %index
 %target = load ptr, ptr %slot
 indirectbr ptr %target, [label %exit, label %body]
body:
 %noise = call i64 @indirect_branch_noise(i64 %i)
 %updated = add i64 %sum, %noise
 %next = add i64 %i, 1
 br label %loop
exit:
 ret i64 %sum
}
