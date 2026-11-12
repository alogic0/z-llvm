define float @phi_fp_literal32(float %x, i32 %which) {
entry:
  %condition = icmp eq i32 %which, 0
  br i1 %condition, label %left, label %right
left:
  br label %merge
right:
  br label %merge
merge:
  %literal = phi float [ 0.0, %left ], [ 1.0, %right ]
  %first = phi float [ %x, %left ], [ %x, %right ]
  %second = phi float [ %x, %left ], [ %x, %right ]
  %sum = fadd float %first, %second
  %result = fadd float %sum, %literal
  ret float %result
}

define double @phi_fp_literal64(double %x, i32 %which) {
entry:
  %condition = icmp eq i32 %which, 0
  br i1 %condition, label %left, label %right
left:
  br label %merge
right:
  br label %merge
merge:
  %literal = phi double [ 0.0, %left ], [ 1.0, %right ]
  %first = phi double [ %x, %left ], [ %x, %right ]
  %second = phi double [ %x, %left ], [ %x, %right ]
  %sum = fadd double %first, %second
  %result = fadd double %sum, %literal
  ret double %result
}
