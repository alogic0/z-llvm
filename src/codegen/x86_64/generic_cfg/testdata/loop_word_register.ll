define i32 @fold(i32 %seed, i32 %limit) {
begin:
  %cell = alloca [1 x i32], align 4
  store i32 %seed, ptr %cell, align 4
  br label %head
head:
  %which = phi i32 [ 0, %begin ], [ %inc, %step ]
  %at_end = icmp eq i32 %which, %limit
  br i1 %at_end, label %finish, label %step
step:
  %prior = load i32, ptr %cell, align 4
  %part = xor i32 %prior, %which
  %change = add i32 %part, 7
  store i32 %change, ptr %cell, align 4
  %inc = add i32 %which, 1
  br label %head
finish:
  %answer = load i32, ptr %cell, align 4
  ret i32 %answer
}

define i32 @checksum(i32 %seed, i32 %limit) {
initialize:
  %local_word = alloca [1 x i32], align 4
  store i32 %seed, ptr %local_word, align 4
  br label %compare
compare:
  %which = phi i32 [ 0, %initialize ], [ %inc, %advance ]
  %at_end = icmp eq i32 %which, %limit
  br i1 %at_end, label %complete, label %advance
advance:
  %prior = load i32, ptr %local_word, align 4
  %part = add i32 %prior, %which
  %change = xor i32 %part, 37
  store i32 %change, ptr %local_word, align 4
  %inc = add i32 %which, 1
  br label %compare
complete:
  %answer = load i32, ptr %local_word, align 4
  %out = add i32 %answer, %seed
  ret i32 %out
}

define i32 @sixth_live(i32 %seed, i32 %limit, i32 %a, i32 %b, i32 %c, i32 %keep) {
begin:
  %cell = alloca [1 x i32], align 4
  store i32 %seed, ptr %cell, align 4
  br label %head
head:
  %which = phi i32 [ 0, %begin ], [ %inc, %step ]
  %at_end = icmp eq i32 %which, %limit
  br i1 %at_end, label %finish, label %step
step:
  %prior = load i32, ptr %cell, align 4
  %part = xor i32 %prior, %which
  %change = add i32 %part, 7
  store i32 %change, ptr %cell, align 4
  %inc = add i32 %which, 1
  br label %head
finish:
  %answer = load i32, ptr %cell, align 4
  %out = add i32 %answer, %keep
  ret i32 %out
}

define i32 @observed(i32 %seed, i32 %limit) {
begin:
  %cell = alloca [1 x i32], align 4
  store volatile i32 %seed, ptr %cell, align 4
  br label %head
head:
  %which = phi i32 [ 0, %begin ], [ %inc, %step ]
  %at_end = icmp eq i32 %which, %limit
  br i1 %at_end, label %finish, label %step
step:
  %prior = load volatile i32, ptr %cell, align 4
  %part = xor i32 %prior, %which
  %change = add i32 %part, 7
  store volatile i32 %change, ptr %cell, align 4
  %inc = add i32 %which, 1
  br label %head
finish:
  %answer = load volatile i32, ptr %cell, align 4
  ret i32 %answer
}

define i32 @two_starts(i32 %seed, i32 %limit) {
begin:
  %cell = alloca [1 x i32], align 4
  %positive = icmp sgt i32 %seed, 0
  br i1 %positive, label %first, label %second
first:
  store i32 %seed, ptr %cell, align 4
  br label %head
second:
  store i32 9, ptr %cell, align 4
  br label %head
head:
  %which = phi i32 [ 0, %first ], [ 0, %second ], [ %inc, %step ]
  %at_end = icmp eq i32 %which, %limit
  br i1 %at_end, label %finish, label %step
step:
  %prior = load i32, ptr %cell, align 4
  %part = xor i32 %prior, %which
  %change = add i32 %part, 7
  store i32 %change, ptr %cell, align 4
  %inc = add i32 %which, 1
  br label %head
finish:
  %answer = load i32, ptr %cell, align 4
  ret i32 %answer
}

define i32 @escapes(i32 %seed, i32 %limit) {
begin:
  %cell = alloca [1 x i32], align 4
  store i32 %seed, ptr %cell, align 4
  call void @add_to_cell(ptr %cell)
  br label %head
head:
  %which = phi i32 [ 0, %begin ], [ %inc, %step ]
  %at_end = icmp eq i32 %which, %limit
  br i1 %at_end, label %finish, label %step
step:
  %prior = load i32, ptr %cell, align 4
  %part = xor i32 %prior, %which
  %change = add i32 %part, 7
  store i32 %change, ptr %cell, align 4
  %inc = add i32 %which, 1
  br label %head
finish:
  %answer = load i32, ptr %cell, align 4
  ret i32 %answer
}

declare void @add_to_cell(ptr)
