target triple = "x86_64-unknown-linux-gnu"
define i64 @volatile_absolute_0_value(i64 %value,i64 %salt) {
entry:
 %input = trunc i64 %value to i8
 %a = load volatile i8,ptr inttoptr (i64 90159953485823 to ptr),align 1
 store volatile i8 %input,ptr inttoptr (i64 90159953485823 to ptr),align 1
 %b = load volatile i8,ptr inttoptr (i64 90159953485823 to ptr),align 1
 %wide_a = zext i8 %a to i64
 %wide_b = zext i8 %b to i64
 %pair = xor i64 %wide_a,%wide_b
 %r = xor i64 %pair,%salt
 ret i64 %r
}
define i64 @volatile_absolute_0_literal(i64 %value,i64 %salt) {
entry:
 %input = trunc i64 %value to i8
 %a = load volatile i8,ptr inttoptr (i64 90159953485823 to ptr),align 1
 store volatile i8 88,ptr inttoptr (i64 90159953485823 to ptr),align 1
 %b = load volatile i8,ptr inttoptr (i64 90159953485823 to ptr),align 1
 %wide_a = zext i8 %a to i64
 %wide_b = zext i8 %b to i64
 %pair = xor i64 %wide_a,%wide_b
 %r = xor i64 %pair,%salt
 ret i64 %r
}
define i64 @volatile_absolute_1_value(i64 %value,i64 %salt) {
entry:
 %input = trunc i64 %value to i16
 %a = load volatile i16,ptr inttoptr (i64 90159953485822 to ptr),align 1
 store volatile i16 %input,ptr inttoptr (i64 90159953485822 to ptr),align 1
 %b = load volatile i16,ptr inttoptr (i64 90159953485822 to ptr),align 1
 %wide_a = zext i16 %a to i64
 %wide_b = zext i16 %b to i64
 %pair = xor i64 %wide_a,%wide_b
 %r = xor i64 %pair,%salt
 ret i64 %r
}
define i64 @volatile_absolute_1_literal(i64 %value,i64 %salt) {
entry:
 %input = trunc i64 %value to i16
 %a = load volatile i16,ptr inttoptr (i64 90159953485822 to ptr),align 1
 store volatile i16 88,ptr inttoptr (i64 90159953485822 to ptr),align 1
 %b = load volatile i16,ptr inttoptr (i64 90159953485822 to ptr),align 1
 %wide_a = zext i16 %a to i64
 %wide_b = zext i16 %b to i64
 %pair = xor i64 %wide_a,%wide_b
 %r = xor i64 %pair,%salt
 ret i64 %r
}
define i64 @volatile_absolute_2_value(i64 %value,i64 %salt) {
entry:
 %input = trunc i64 %value to i32
 %a = load volatile i32,ptr inttoptr (i64 90159953485820 to ptr),align 1
 store volatile i32 %input,ptr inttoptr (i64 90159953485820 to ptr),align 1
 %b = load volatile i32,ptr inttoptr (i64 90159953485820 to ptr),align 1
 %wide_a = zext i32 %a to i64
 %wide_b = zext i32 %b to i64
 %pair = xor i64 %wide_a,%wide_b
 %r = xor i64 %pair,%salt
 ret i64 %r
}
define i64 @volatile_absolute_2_literal(i64 %value,i64 %salt) {
entry:
 %input = trunc i64 %value to i32
 %a = load volatile i32,ptr inttoptr (i64 90159953485820 to ptr),align 1
 store volatile i32 88,ptr inttoptr (i64 90159953485820 to ptr),align 1
 %b = load volatile i32,ptr inttoptr (i64 90159953485820 to ptr),align 1
 %wide_a = zext i32 %a to i64
 %wide_b = zext i32 %b to i64
 %pair = xor i64 %wide_a,%wide_b
 %r = xor i64 %pair,%salt
 ret i64 %r
}
define i64 @volatile_absolute_3_value(i64 %value,i64 %salt) {
entry:
 %input = add i64 %value,0
 %a = load volatile i64,ptr inttoptr (i64 90159953485816 to ptr),align 1
 store volatile i64 %input,ptr inttoptr (i64 90159953485816 to ptr),align 1
 %b = load volatile i64,ptr inttoptr (i64 90159953485816 to ptr),align 1
 %wide_a = add i64 %a,0
 %wide_b = add i64 %b,0
 %pair = xor i64 %wide_a,%wide_b
 %r = xor i64 %pair,%salt
 ret i64 %r
}
define i64 @volatile_absolute_3_literal(i64 %value,i64 %salt) {
entry:
 %input = add i64 %value,0
 %a = load volatile i64,ptr inttoptr (i64 90159953485816 to ptr),align 1
 store volatile i64 88,ptr inttoptr (i64 90159953485816 to ptr),align 1
 %b = load volatile i64,ptr inttoptr (i64 90159953485816 to ptr),align 1
 %wide_a = add i64 %a,0
 %wide_b = add i64 %b,0
 %pair = xor i64 %wide_a,%wide_b
 %r = xor i64 %pair,%salt
 ret i64 %r
}
define i64 @volatile_absolute_4_value(i64 %value,i64 %salt) {
entry:
 %input = inttoptr i64 %value to ptr
 %a = load volatile ptr,ptr inttoptr (i64 90159953485816 to ptr),align 1
 store volatile ptr %input,ptr inttoptr (i64 90159953485816 to ptr),align 1
 %b = load volatile ptr,ptr inttoptr (i64 90159953485816 to ptr),align 1
 %wide_a = ptrtoint ptr %a to i64
 %wide_b = ptrtoint ptr %b to i64
 %pair = xor i64 %wide_a,%wide_b
 %r = xor i64 %pair,%salt
 ret i64 %r
}
define i64 @volatile_absolute_4_literal(i64 %value,i64 %salt) {
entry:
 %input = inttoptr i64 %value to ptr
 %a = load volatile ptr,ptr inttoptr (i64 90159953485816 to ptr),align 1
 store volatile ptr inttoptr (i64 88 to ptr),ptr inttoptr (i64 90159953485816 to ptr),align 1
 %b = load volatile ptr,ptr inttoptr (i64 90159953485816 to ptr),align 1
 %wide_a = ptrtoint ptr %a to i64
 %wide_b = ptrtoint ptr %b to i64
 %pair = xor i64 %wide_a,%wide_b
 %r = xor i64 %pair,%salt
 ret i64 %r
}
