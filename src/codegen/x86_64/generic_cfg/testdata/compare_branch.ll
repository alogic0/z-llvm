define i32 @equal(i32 %left, i32 %right) {
entry:
  %same = icmp eq i32 %left, %right
  br i1 %same, label %yes, label %no
yes:
  %plus = add i32 %left, 7
  ret i32 %plus
no:
  %minus = sub i32 %right, 3
  ret i32 %minus
}

define i32 @swapped(i32 %left, i32 %right) {
entry:
  %same = icmp eq i32 %right, %left
  br i1 %same, label %yes, label %no
yes:
  %plus = add i32 %left, 7
  ret i32 %plus
no:
  %minus = sub i32 %right, 3
  ret i32 %minus
}

define i32 @writes_flags(i32 %left, i32 %right) {
entry:
  %same = icmp eq i32 %left, %right
  %plus = add i32 %left, 7
  br i1 %same, label %yes, label %no
yes:
  ret i32 %plus
no:
  %minus = sub i32 %right, 3
  ret i32 %minus
}

define i32 @extra_boolean(i32 %left, i32 %right) {
entry:
  %same = icmp eq i32 %left, %right
  br i1 %same, label %yes, label %no
yes:
  %bit = zext i1 %same to i32
  %res = add i32 %left, %bit
  ret i32 %res
no:
  %minus = sub i32 %right, 3
  ret i32 %minus
}

define i32 @edge_phi(i32 %left, i32 %right) {
entry:
  %same = icmp eq i32 %right, %left
  br i1 %same, label %merge, label %no
no:
  %minus = sub i32 %right, 3
  br label %merge
merge:
  %res = phi i32 [ %left, %entry ], [ %minus, %no ]
  ret i32 %res
}
