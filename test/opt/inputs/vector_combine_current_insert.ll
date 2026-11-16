define i32 @vector_combine_current_insert(i32 %x) {
entry:
  %a = insertelement <2 x i32> poison, i32 %x, i32 0
  br label %producer
build:
  %b = insertelement <2 x i32> poison, i32 %first, i32 1
  br label %next
producer:
  %first = extractelement <2 x i32> %a, i32 0
  br label %build
next:
  %r = extractelement <2 x i32> %b, i32 1
  br label %merge
merge:
  %p = phi i32 [ %r, %next ]
  ret i32 %p
}
