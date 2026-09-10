define i32 @probe(i32 %x, i32 %y) {
entry:
  %v0 = add i32 %x, 1
  %v1 = add i32 %x, 2
  %v2 = add i32 %x, 3
  %v3 = add i32 %x, 4
  %v4 = add i32 %x, 5
  %v5 = add i32 %x, 6
  %v6 = add i32 %x, 7
  %v7 = add i32 %x, 8
  %v8 = add i32 %x, 9
  %v9 = add i32 %x, 10
  %v10 = add i32 %x, 11
  %v11 = add i32 %x, 12
  %a0 = xor i32 %v0, %y
  %a1 = xor i32 %a0, %v1
  %a2 = xor i32 %a1, %v2
  %a3 = xor i32 %a2, %v3
  %a4 = xor i32 %a3, %v4
  %a5 = xor i32 %a4, %v5
  %a6 = xor i32 %a5, %v6
  %a7 = xor i32 %a6, %v7
  %a8 = xor i32 %a7, %v8
  %a9 = xor i32 %a8, %v9
  %a10 = xor i32 %a9, %v10
  %a11 = xor i32 %a10, %v11
  ret i32 %a11
}
