define i32 @loop_deletion_dead_counted() #0 {
entry:
  br label %exit

exit:
  ret i32 0
}

attributes #0 = { mustprogress }
