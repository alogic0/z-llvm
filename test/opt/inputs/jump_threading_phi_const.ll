define i32 @thread_phi(i1 %c) {
entry:
  br i1 %c, label %left, label %right

left:
  br label %join

right:
  br label %join

join:
  %p = phi i1 [ 1, %left ], [ 0, %right ]
  br i1 %p, label %then, label %else

then:
  ret i32 1

else:
  ret i32 0
}
