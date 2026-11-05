target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n8:16:32:64-S128"

target triple = "x86_64-unknown-linux-gnu"

@pointer_flow_data = global [8 x i8] c"\01\03\05\07\09\0B\0D\0F", align 8

declare i64 @pointer_flow_clobber(i64)

declare i64 @pointer_flow_helper(ptr, ptr, i64)

define { ptr, i64 } @pointer_flow_phi_pi(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  %base = insertvalue { ptr, i64 } poison, ptr %p, 0
  %pair = insertvalue { ptr, i64 } %base, i64 %b, 1
  %other0 = insertvalue { ptr, i64 } poison, ptr null, 0
  %other = insertvalue { ptr, i64 } %other0, i64 %a, 1
  br i1 %cond, label %yes, label %no
merge:
  %selected = phi { ptr, i64 } [ %pair, %yes ], [ %other, %no ]
  br label %finish
yes:
  br label %merge
no:
  br label %merge
finish:
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  ret { ptr, i64 } %selected
}

define { ptr, i64 } @pointer_flow_select_pi(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  %base = insertvalue { ptr, i64 } poison, ptr %p, 0
  %pair = insertvalue { ptr, i64 } %base, i64 %b, 1
  %other0 = insertvalue { ptr, i64 } poison, ptr null, 0
  %other = insertvalue { ptr, i64 } %other0, i64 %a, 1
  %selected = select i1 %cond, { ptr, i64 } %pair, { ptr, i64 } %other
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  ret { ptr, i64 } %selected
}

define { ptr, i64 } @pointer_flow_loop_pi(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  %base = insertvalue { ptr, i64 } poison, ptr %p, 0
  %pair = insertvalue { ptr, i64 } %base, i64 %b, 1
  %count = and i64 %choice, 7
  br label %loop
loop:
  %selected = phi { ptr, i64 } [ %pair, %entry ], [ %next, %body ]
  %i = phi i64 [ 0, %entry ], [ %inc, %body ]
  %done = icmp eq i64 %i, %count
  br i1 %done, label %finish, label %body
body:
  %old = extractvalue { ptr, i64 } %selected, 1
  %newbits = add i64 %old, 1
  %next = insertvalue { ptr, i64 } %selected, i64 %newbits, 1
  %inc = add i64 %i, 1
  br label %loop
finish:
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  ret { ptr, i64 } %selected
}

define { ptr, i64 } @pointer_flow_constant_pi(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  br i1 %cond, label %constant, label %zero
constant:
  %answer1 = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer1, ptr %out
  ret { ptr, i64 } { ptr @pointer_flow_data, i64 -1 }
zero:
  %answer0 = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer0, ptr %out
  ret { ptr, i64 } zeroinitializer
}

define { i64, ptr } @pointer_flow_phi_ip(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  %base = insertvalue { i64, ptr } poison, i64 %a, 0
  %pair = insertvalue { i64, ptr } %base, ptr %pb, 1
  %other0 = insertvalue { i64, ptr } poison, i64 %b, 0
  %other = insertvalue { i64, ptr } %other0, ptr %p, 1
  br i1 %cond, label %yes, label %no
merge:
  %selected = phi { i64, ptr } [ %pair, %yes ], [ %other, %no ]
  br label %finish
yes:
  br label %merge
no:
  br label %merge
finish:
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  ret { i64, ptr } %selected
}

define { i64, ptr } @pointer_flow_select_ip(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  %base = insertvalue { i64, ptr } poison, i64 %a, 0
  %pair = insertvalue { i64, ptr } %base, ptr %pb, 1
  %other0 = insertvalue { i64, ptr } poison, i64 %b, 0
  %other = insertvalue { i64, ptr } %other0, ptr %p, 1
  %selected = select i1 %cond, { i64, ptr } %pair, { i64, ptr } %other
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  ret { i64, ptr } %selected
}

define { i64, ptr } @pointer_flow_loop_ip(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  %base = insertvalue { i64, ptr } poison, i64 %a, 0
  %pair = insertvalue { i64, ptr } %base, ptr %pb, 1
  %count = and i64 %choice, 7
  br label %loop
loop:
  %selected = phi { i64, ptr } [ %pair, %entry ], [ %next, %body ]
  %i = phi i64 [ 0, %entry ], [ %inc, %body ]
  %done = icmp eq i64 %i, %count
  br i1 %done, label %finish, label %body
body:
  %old = extractvalue { i64, ptr } %selected, 1
  %bits = ptrtoint ptr %old to i64
  %newbits = add i64 %bits, 1
  %new = inttoptr i64 %newbits to ptr
  %next = insertvalue { i64, ptr } %selected, ptr %new, 1
  %inc = add i64 %i, 1
  br label %loop
finish:
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  ret { i64, ptr } %selected
}

define { i64, ptr } @pointer_flow_constant_ip(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  br i1 %cond, label %constant, label %zero
constant:
  %answer1 = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer1, ptr %out
  ret { i64, ptr } { i64 9223372036854775808, ptr inttoptr (i64 -1 to ptr) }
zero:
  %answer0 = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer0, ptr %out
  ret { i64, ptr } zeroinitializer
}

define { ptr, ptr } @pointer_flow_phi_pp(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  %base = insertvalue { ptr, ptr } poison, ptr %p, 0
  %pair = insertvalue { ptr, ptr } %base, ptr %pb, 1
  %other0 = insertvalue { ptr, ptr } poison, ptr null, 0
  %other = insertvalue { ptr, ptr } %other0, ptr %p, 1
  br i1 %cond, label %yes, label %no
merge:
  %selected = phi { ptr, ptr } [ %pair, %yes ], [ %other, %no ]
  br label %finish
yes:
  br label %merge
no:
  br label %merge
finish:
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  ret { ptr, ptr } %selected
}

define { ptr, ptr } @pointer_flow_select_pp(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  %base = insertvalue { ptr, ptr } poison, ptr %p, 0
  %pair = insertvalue { ptr, ptr } %base, ptr %pb, 1
  %other0 = insertvalue { ptr, ptr } poison, ptr null, 0
  %other = insertvalue { ptr, ptr } %other0, ptr %p, 1
  %selected = select i1 %cond, { ptr, ptr } %pair, { ptr, ptr } %other
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  ret { ptr, ptr } %selected
}

define { ptr, ptr } @pointer_flow_loop_pp(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  %base = insertvalue { ptr, ptr } poison, ptr %p, 0
  %pair = insertvalue { ptr, ptr } %base, ptr %pb, 1
  %count = and i64 %choice, 7
  br label %loop
loop:
  %selected = phi { ptr, ptr } [ %pair, %entry ], [ %next, %body ]
  %i = phi i64 [ 0, %entry ], [ %inc, %body ]
  %done = icmp eq i64 %i, %count
  br i1 %done, label %finish, label %body
body:
  %old = extractvalue { ptr, ptr } %selected, 1
  %bits = ptrtoint ptr %old to i64
  %newbits = add i64 %bits, 1
  %new = inttoptr i64 %newbits to ptr
  %next = insertvalue { ptr, ptr } %selected, ptr %new, 1
  %inc = add i64 %i, 1
  br label %loop
finish:
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  ret { ptr, ptr } %selected
}

define { ptr, ptr } @pointer_flow_constant_pp(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  br i1 %cond, label %constant, label %zero
constant:
  %answer1 = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer1, ptr %out
  ret { ptr, ptr } { ptr @pointer_flow_data, ptr inttoptr (i64 -1 to ptr) }
zero:
  %answer0 = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer0, ptr %out
  ret { ptr, ptr } zeroinitializer
}

define { i64, i64 } @pointer_flow_phi_ii(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  %base = insertvalue { i64, i64 } poison, i64 %a, 0
  %pair = insertvalue { i64, i64 } %base, i64 %b, 1
  %other0 = insertvalue { i64, i64 } poison, i64 %b, 0
  %other = insertvalue { i64, i64 } %other0, i64 %a, 1
  br i1 %cond, label %yes, label %no
merge:
  %selected = phi { i64, i64 } [ %pair, %yes ], [ %other, %no ]
  br label %finish
yes:
  br label %merge
no:
  br label %merge
finish:
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  ret { i64, i64 } %selected
}

define { i64, i64 } @pointer_flow_select_ii(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  %base = insertvalue { i64, i64 } poison, i64 %a, 0
  %pair = insertvalue { i64, i64 } %base, i64 %b, 1
  %other0 = insertvalue { i64, i64 } poison, i64 %b, 0
  %other = insertvalue { i64, i64 } %other0, i64 %a, 1
  %selected = select i1 %cond, { i64, i64 } %pair, { i64, i64 } %other
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  ret { i64, i64 } %selected
}

define { i64, i64 } @pointer_flow_loop_ii(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  %base = insertvalue { i64, i64 } poison, i64 %a, 0
  %pair = insertvalue { i64, i64 } %base, i64 %b, 1
  %count = and i64 %choice, 7
  br label %loop
loop:
  %selected = phi { i64, i64 } [ %pair, %entry ], [ %next, %body ]
  %i = phi i64 [ 0, %entry ], [ %inc, %body ]
  %done = icmp eq i64 %i, %count
  br i1 %done, label %finish, label %body
body:
  %old = extractvalue { i64, i64 } %selected, 1
  %newbits = add i64 %old, 1
  %next = insertvalue { i64, i64 } %selected, i64 %newbits, 1
  %inc = add i64 %i, 1
  br label %loop
finish:
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  ret { i64, i64 } %selected
}

define { i64, i64 } @pointer_flow_constant_ii(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %pb = inttoptr i64 %b to ptr
  %cond = trunc i64 %choice to i1
  br i1 %cond, label %constant, label %zero
constant:
  %answer1 = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer1, ptr %out
  ret { i64, i64 } { i64 9223372036854775808, i64 -1 }
zero:
  %answer0 = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer0, ptr %out
  ret { i64, i64 } zeroinitializer
}

define { i64, i64 } @pointer_flow_global_phi(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %cond = trunc i64 %choice to i1
  br i1 %cond, label %yes, label %no
merge:
  %selected = phi ptr [ @pointer_flow_data, %yes ], [ null, %no ]
  %value = ptrtoint ptr %selected to i64
  br label %finish
yes:
  br label %merge
no:
  br label %merge
finish:
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  %pair0 = insertvalue { i64, i64 } poison, i64 %value, 0
  %pair = insertvalue { i64, i64 } %pair0, i64 %b, 1
  ret { i64, i64 } %pair
}

define { i64, i64 } @pointer_flow_global_select(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %cond = trunc i64 %choice to i1
  %selected = select i1 %cond, ptr @pointer_flow_data, ptr null
  %value = ptrtoint ptr %selected to i64
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  %pair0 = insertvalue { i64, i64 } poison, i64 %value, 0
  %pair = insertvalue { i64, i64 } %pair0, i64 %b, 1
  ret { i64, i64 } %pair
}

define { i64, i64 } @pointer_flow_constant_cast(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %value = ptrtoint ptr inttoptr (i64 -1 to ptr) to i64
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  %pair0 = insertvalue { i64, i64 } poison, i64 %value, 0
  %pair = insertvalue { i64, i64 } %pair0, i64 %b, 1
  ret { i64, i64 } %pair
}

define { i64, i64 } @pointer_flow_global_call(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %value = call i64 @pointer_flow_helper(ptr @pointer_flow_data, ptr null, i64 %b)
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  %pair0 = insertvalue { i64, i64 } poison, i64 %value, 0
  %pair = insertvalue { i64, i64 } %pair0, i64 %b, 1
  ret { i64, i64 } %pair
}

define { i64, i64 } @pointer_flow_global_index(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %index = and i64 %choice, 7
  %address = getelementptr [1 x i8], ptr @pointer_flow_data, i64 %index
  %byte = load i8, ptr %address
  %value = zext i8 %byte to i64
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  %pair0 = insertvalue { i64, i64 } poison, i64 %value, 0
  %pair = insertvalue { i64, i64 } %pair0, i64 %b, 1
  ret { i64, i64 } %pair
}

define { i64, i64 } @pointer_flow_constant_gep(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %address = getelementptr i8, ptr inttoptr (i64 1 to ptr), i64 8
  %value = ptrtoint ptr %address to i64
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  %pair0 = insertvalue { i64, i64 } poison, i64 %value, 0
  %pair = insertvalue { i64, i64 } %pair0, i64 %b, 1
  ret { i64, i64 } %pair
}

define { i64, i64 } @pointer_flow_global_load(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %byte = load i8, ptr @pointer_flow_data
  %value = zext i8 %byte to i64
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  %pair0 = insertvalue { i64, i64 } poison, i64 %value, 0
  %pair = insertvalue { i64, i64 } %pair0, i64 %b, 1
  ret { i64, i64 } %pair
}

define { i64, i64 } @pointer_flow_global_offset(ptr %p, i64 %a, i64 %b, i64 %choice, ptr %out) {
entry:
  %address = select i1 true, ptr getelementptr (i8, ptr @pointer_flow_data, i64 3), ptr null
  %value = ptrtoint ptr %address to i64
  %answer = call i64 @pointer_flow_clobber(i64 %a)
  store i64 %answer, ptr %out
  %pair0 = insertvalue { i64, i64 } poison, i64 %value, 0
  %pair = insertvalue { i64, i64 } %pair0, i64 %b, 1
  ret { i64, i64 } %pair
}
