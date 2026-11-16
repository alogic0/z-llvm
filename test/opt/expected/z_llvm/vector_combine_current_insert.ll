define i32 @vector_combine_current_insert(i32 %x) {
entry:
  br label %producer
build:
  br label %next
producer:
  br label %build
next:
  br label %merge
merge:
  %p = phi i32 [ %x, %next ]
  ret i32 %p
}
