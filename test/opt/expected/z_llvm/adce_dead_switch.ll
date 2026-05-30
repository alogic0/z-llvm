define i32 @adce_dead_switch(i32 %tag, i32 %a) {
entry:
  br label %default
default:
  br label %join
left:
  br label %join
right:
  br label %join
join:
  ret i32 0
}
