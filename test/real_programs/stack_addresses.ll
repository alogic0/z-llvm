target triple = "x86_64-unknown-linux-gnu"

declare void @address_clobber(ptr)

declare ptr @address_identity(ptr)

define i64 @address_phi(i64 %a, i64 %b, ptr %out) {
entry:
  %left = alloca [24 x i8], align 16
  %right = alloca [40 x i8], align 16
  store i64 %a, ptr %left
  store i64 %b, ptr %right
  %low = and i64 %b, 1
  %condition = icmp ne i64 %low, 0
  br i1 %condition, label %yes, label %no
yes:
  call void @address_clobber(ptr %left)
  br label %merge
no:
  call void @address_clobber(ptr %right)
  br label %merge
merge:
  %chosen = phi ptr [ %left, %yes ], [ %right, %no ]
  %read = load i64, ptr %chosen
  store i64 %read, ptr %out
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @address_large_phi(i64 %a, i64 %b, ptr %out) {
entry:
  %left = alloca [8193 x i8], align 16
  %right = alloca [65536 x i8], align 16
  store i64 %a, ptr %left
  store i64 %b, ptr %right
  %low = and i64 %b, 1
  %condition = icmp ne i64 %low, 0
  br i1 %condition, label %yes, label %no
yes:
  call void @address_clobber(ptr %left)
  br label %merge
no:
  call void @address_clobber(ptr %right)
  br label %merge
merge:
  %chosen = phi ptr [ %left, %yes ], [ %right, %no ]
  %read = load i64, ptr %chosen
  store i64 %read, ptr %out
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @address_select(i64 %a, i64 %b, ptr %out) {
entry:
  %left = alloca [20 x i8], align 8
  %right = alloca [28 x i8], align 8
  %holder = alloca ptr, align 8
  store i64 %a, ptr %left
  store i64 %b, ptr %right
  %low = and i64 %b, 1
  %condition = icmp ne i64 %low, 0
  %chosen = select i1 %condition, ptr %left, ptr %right
  store ptr %chosen, ptr %holder
  call void @address_clobber(ptr %chosen)
  %pointer = load ptr, ptr %holder
  %read = load i64, ptr %pointer
  store i64 %read, ptr %out
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @address_loop(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca [4 x i64], align 8
  br label %loop
loop:
  %cursor = phi ptr [ %slot, %entry ], [ %next, %loop ]
  %index = phi i64 [ 0, %entry ], [ %increment, %loop ]
  %value = add i64 %b, %index
  store i64 %value, ptr %cursor
  call void @address_clobber(ptr %cursor)
  %next = getelementptr i8, ptr %cursor, i64 8
  %increment = add i64 %index, 1
  %again = icmp ult i64 %increment, 4
  br i1 %again, label %loop, label %done
done:
  %tail = getelementptr i8, ptr %slot, i64 24
  %read = load i64, ptr %tail
  store i64 %read, ptr %out
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @address_dynamic(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca [8 x i64], align 8
  %p0 = getelementptr i8, ptr %slot, i64 0
  %v0 = add i64 %a, 0
  store i64 %v0, ptr %p0
  %p1 = getelementptr i8, ptr %slot, i64 8
  %v1 = add i64 %a, 1
  store i64 %v1, ptr %p1
  %p2 = getelementptr i8, ptr %slot, i64 16
  %v2 = add i64 %a, 2
  store i64 %v2, ptr %p2
  %p3 = getelementptr i8, ptr %slot, i64 24
  %v3 = add i64 %a, 3
  store i64 %v3, ptr %p3
  %p4 = getelementptr i8, ptr %slot, i64 32
  %v4 = add i64 %a, 4
  store i64 %v4, ptr %p4
  %p5 = getelementptr i8, ptr %slot, i64 40
  %v5 = add i64 %a, 5
  store i64 %v5, ptr %p5
  %p6 = getelementptr i8, ptr %slot, i64 48
  %v6 = add i64 %a, 6
  store i64 %v6, ptr %p6
  %p7 = getelementptr i8, ptr %slot, i64 56
  %v7 = add i64 %a, 7
  store i64 %v7, ptr %p7
  %index = and i64 %b, 7
  %offset = shl i64 %index, 3
  %element = getelementptr i8, ptr %slot, i64 %offset
  call void @address_clobber(ptr %slot)
  %read = load i64, ptr %element
  store i64 %read, ptr %out
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @address_scalar(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca i64, align 8
  %holder = alloca ptr, align 8
  store i64 %a, ptr %slot
  store ptr %slot, ptr %holder
  call void @address_clobber(ptr %slot)
  %pointer = load ptr, ptr %holder
  %read = load i64, ptr %pointer
  store i64 %read, ptr %out
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @address_pair(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca i128, align 16
  %holder = alloca ptr, align 8
  %tail = getelementptr i8, ptr %slot, i64 8
  store i64 %a, ptr %slot
  store i64 %b, ptr %tail
  store ptr %slot, ptr %holder
  call void @address_clobber(ptr %slot)
  %pointer = load ptr, ptr %holder
  %end = getelementptr i8, ptr %pointer, i64 8
  %first = load i64, ptr %pointer
  %last = load i64, ptr %end
  %sum = add i64 %first, %last
  store i64 %sum, ptr %out
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @address_cast(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca [8 x i64], align 8
  store i64 %a, ptr %slot
  %bits = ptrtoint ptr %slot to i64
  call void @address_clobber(ptr %slot)
  %pointer = inttoptr i64 %bits to ptr
  %read = load i64, ptr %pointer
  store i64 %read, ptr %out
  %live = xor i64 %a, %b
  ret i64 %live
}

define i64 @address_called(i64 %a, i64 %b, ptr %out) {
entry:
  %slot = alloca [4 x i64], align 8
  %holder = alloca ptr, align 8
  store i64 %a, ptr %slot
  store ptr %slot, ptr %holder
  %pointer = load ptr, ptr %holder
  %returned = call ptr @address_identity(ptr %pointer)
  %read = load i64, ptr %returned
  store i64 %read, ptr %out
  %live = xor i64 %a, %b
  ret i64 %live
}
