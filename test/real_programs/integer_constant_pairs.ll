target triple = "x86_64-unknown-linux-gnu"
define i64 @constant_pairs_1_add(ptr %out,i64 %salt) {
entry:
 %value0 = add i1 0,1
 %wide0 = zext i1 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = add i1 1,1
 %wide1 = zext i1 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = add i1 1,1
 %wide2 = zext i1 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = add i1 1,1
 %wide3 = zext i1 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_1_sub(ptr %out,i64 %salt) {
entry:
 %value0 = sub i1 0,1
 %wide0 = zext i1 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = sub i1 1,1
 %wide1 = zext i1 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = sub i1 1,1
 %wide2 = zext i1 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = sub i1 1,1
 %wide3 = zext i1 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_1_mul(ptr %out,i64 %salt) {
entry:
 %value0 = mul i1 0,1
 %wide0 = zext i1 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = mul i1 1,1
 %wide1 = zext i1 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = mul i1 1,1
 %wide2 = zext i1 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = mul i1 1,1
 %wide3 = zext i1 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_1_and(ptr %out,i64 %salt) {
entry:
 %value0 = and i1 0,1
 %wide0 = zext i1 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = and i1 1,1
 %wide1 = zext i1 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = and i1 1,1
 %wide2 = zext i1 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = and i1 1,1
 %wide3 = zext i1 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_1_or(ptr %out,i64 %salt) {
entry:
 %value0 = or i1 0,1
 %wide0 = zext i1 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = or i1 1,1
 %wide1 = zext i1 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = or i1 1,1
 %wide2 = zext i1 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = or i1 1,1
 %wide3 = zext i1 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_1_xor(ptr %out,i64 %salt) {
entry:
 %value0 = xor i1 0,1
 %wide0 = zext i1 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = xor i1 1,1
 %wide1 = zext i1 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = xor i1 1,1
 %wide2 = zext i1 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = xor i1 1,1
 %wide3 = zext i1 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_1_shl(ptr %out,i64 %salt) {
entry:
 %value0 = shl i1 0,0
 %wide0 = zext i1 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = shl i1 1,0
 %wide1 = zext i1 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = shl i1 1,0
 %wide2 = zext i1 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = shl i1 1,0
 %wide3 = zext i1 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_1_lshr(ptr %out,i64 %salt) {
entry:
 %value0 = lshr i1 0,0
 %wide0 = zext i1 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = lshr i1 1,0
 %wide1 = zext i1 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = lshr i1 1,0
 %wide2 = zext i1 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = lshr i1 1,0
 %wide3 = zext i1 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_1_ashr(ptr %out,i64 %salt) {
entry:
 %value0 = ashr i1 0,0
 %wide0 = zext i1 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = ashr i1 1,0
 %wide1 = zext i1 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = ashr i1 1,0
 %wide2 = zext i1 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = ashr i1 1,0
 %wide3 = zext i1 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_1_udiv(ptr %out,i64 %salt) {
entry:
 %value0 = udiv i1 0,1
 %wide0 = zext i1 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = udiv i1 1,1
 %wide1 = zext i1 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = udiv i1 1,1
 %wide2 = zext i1 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = udiv i1 1,1
 %wide3 = zext i1 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_1_urem(ptr %out,i64 %salt) {
entry:
 %value0 = urem i1 0,1
 %wide0 = zext i1 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = urem i1 1,1
 %wide1 = zext i1 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = urem i1 1,1
 %wide2 = zext i1 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = urem i1 1,1
 %wide3 = zext i1 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_3_add(ptr %out,i64 %salt) {
entry:
 %value0 = add i3 0,7
 %wide0 = zext i3 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = add i3 1,7
 %wide1 = zext i3 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = add i3 7,1
 %wide2 = zext i3 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = add i3 4,1
 %wide3 = zext i3 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_3_sub(ptr %out,i64 %salt) {
entry:
 %value0 = sub i3 0,7
 %wide0 = zext i3 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = sub i3 1,7
 %wide1 = zext i3 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = sub i3 7,1
 %wide2 = zext i3 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = sub i3 4,1
 %wide3 = zext i3 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_3_mul(ptr %out,i64 %salt) {
entry:
 %value0 = mul i3 0,7
 %wide0 = zext i3 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = mul i3 1,7
 %wide1 = zext i3 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = mul i3 7,1
 %wide2 = zext i3 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = mul i3 4,1
 %wide3 = zext i3 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_3_and(ptr %out,i64 %salt) {
entry:
 %value0 = and i3 0,7
 %wide0 = zext i3 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = and i3 1,7
 %wide1 = zext i3 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = and i3 7,1
 %wide2 = zext i3 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = and i3 4,1
 %wide3 = zext i3 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_3_or(ptr %out,i64 %salt) {
entry:
 %value0 = or i3 0,7
 %wide0 = zext i3 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = or i3 1,7
 %wide1 = zext i3 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = or i3 7,1
 %wide2 = zext i3 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = or i3 4,1
 %wide3 = zext i3 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_3_xor(ptr %out,i64 %salt) {
entry:
 %value0 = xor i3 0,7
 %wide0 = zext i3 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = xor i3 1,7
 %wide1 = zext i3 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = xor i3 7,1
 %wide2 = zext i3 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = xor i3 4,1
 %wide3 = zext i3 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_3_shl(ptr %out,i64 %salt) {
entry:
 %value0 = shl i3 0,0
 %wide0 = zext i3 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = shl i3 1,1
 %wide1 = zext i3 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = shl i3 7,2
 %wide2 = zext i3 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = shl i3 4,1
 %wide3 = zext i3 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_3_lshr(ptr %out,i64 %salt) {
entry:
 %value0 = lshr i3 0,0
 %wide0 = zext i3 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = lshr i3 1,1
 %wide1 = zext i3 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = lshr i3 7,2
 %wide2 = zext i3 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = lshr i3 4,1
 %wide3 = zext i3 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_3_ashr(ptr %out,i64 %salt) {
entry:
 %value0 = ashr i3 0,0
 %wide0 = zext i3 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = ashr i3 1,1
 %wide1 = zext i3 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = ashr i3 7,2
 %wide2 = zext i3 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = ashr i3 4,1
 %wide3 = zext i3 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_3_udiv(ptr %out,i64 %salt) {
entry:
 %value0 = udiv i3 0,1
 %wide0 = zext i3 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = udiv i3 1,1
 %wide1 = zext i3 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = udiv i3 7,7
 %wide2 = zext i3 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = udiv i3 4,1
 %wide3 = zext i3 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_3_urem(ptr %out,i64 %salt) {
entry:
 %value0 = urem i3 0,1
 %wide0 = zext i3 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = urem i3 1,1
 %wide1 = zext i3 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = urem i3 7,7
 %wide2 = zext i3 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = urem i3 4,1
 %wide3 = zext i3 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_8_add(ptr %out,i64 %salt) {
entry:
 %value0 = add i8 0,255
 %wide0 = zext i8 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = add i8 1,255
 %wide1 = zext i8 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = add i8 255,1
 %wide2 = zext i8 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = add i8 128,1
 %wide3 = zext i8 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_8_sub(ptr %out,i64 %salt) {
entry:
 %value0 = sub i8 0,255
 %wide0 = zext i8 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = sub i8 1,255
 %wide1 = zext i8 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = sub i8 255,1
 %wide2 = zext i8 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = sub i8 128,1
 %wide3 = zext i8 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_8_mul(ptr %out,i64 %salt) {
entry:
 %value0 = mul i8 0,255
 %wide0 = zext i8 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = mul i8 1,255
 %wide1 = zext i8 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = mul i8 255,1
 %wide2 = zext i8 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = mul i8 128,1
 %wide3 = zext i8 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_8_and(ptr %out,i64 %salt) {
entry:
 %value0 = and i8 0,255
 %wide0 = zext i8 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = and i8 1,255
 %wide1 = zext i8 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = and i8 255,1
 %wide2 = zext i8 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = and i8 128,1
 %wide3 = zext i8 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_8_or(ptr %out,i64 %salt) {
entry:
 %value0 = or i8 0,255
 %wide0 = zext i8 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = or i8 1,255
 %wide1 = zext i8 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = or i8 255,1
 %wide2 = zext i8 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = or i8 128,1
 %wide3 = zext i8 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_8_xor(ptr %out,i64 %salt) {
entry:
 %value0 = xor i8 0,255
 %wide0 = zext i8 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = xor i8 1,255
 %wide1 = zext i8 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = xor i8 255,1
 %wide2 = zext i8 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = xor i8 128,1
 %wide3 = zext i8 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_8_shl(ptr %out,i64 %salt) {
entry:
 %value0 = shl i8 0,0
 %wide0 = zext i8 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = shl i8 1,1
 %wide1 = zext i8 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = shl i8 255,7
 %wide2 = zext i8 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = shl i8 128,4
 %wide3 = zext i8 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_8_lshr(ptr %out,i64 %salt) {
entry:
 %value0 = lshr i8 0,0
 %wide0 = zext i8 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = lshr i8 1,1
 %wide1 = zext i8 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = lshr i8 255,7
 %wide2 = zext i8 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = lshr i8 128,4
 %wide3 = zext i8 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_8_ashr(ptr %out,i64 %salt) {
entry:
 %value0 = ashr i8 0,0
 %wide0 = zext i8 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = ashr i8 1,1
 %wide1 = zext i8 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = ashr i8 255,7
 %wide2 = zext i8 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = ashr i8 128,4
 %wide3 = zext i8 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_8_udiv(ptr %out,i64 %salt) {
entry:
 %value0 = udiv i8 0,1
 %wide0 = zext i8 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = udiv i8 1,1
 %wide1 = zext i8 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = udiv i8 255,255
 %wide2 = zext i8 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = udiv i8 128,1
 %wide3 = zext i8 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_8_urem(ptr %out,i64 %salt) {
entry:
 %value0 = urem i8 0,1
 %wide0 = zext i8 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = urem i8 1,1
 %wide1 = zext i8 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = urem i8 255,255
 %wide2 = zext i8 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = urem i8 128,1
 %wide3 = zext i8 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_17_add(ptr %out,i64 %salt) {
entry:
 %value0 = add i17 0,131071
 %wide0 = zext i17 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = add i17 1,131071
 %wide1 = zext i17 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = add i17 131071,1
 %wide2 = zext i17 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = add i17 65536,1
 %wide3 = zext i17 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_17_sub(ptr %out,i64 %salt) {
entry:
 %value0 = sub i17 0,131071
 %wide0 = zext i17 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = sub i17 1,131071
 %wide1 = zext i17 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = sub i17 131071,1
 %wide2 = zext i17 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = sub i17 65536,1
 %wide3 = zext i17 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_17_mul(ptr %out,i64 %salt) {
entry:
 %value0 = mul i17 0,131071
 %wide0 = zext i17 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = mul i17 1,131071
 %wide1 = zext i17 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = mul i17 131071,1
 %wide2 = zext i17 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = mul i17 65536,1
 %wide3 = zext i17 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_17_and(ptr %out,i64 %salt) {
entry:
 %value0 = and i17 0,131071
 %wide0 = zext i17 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = and i17 1,131071
 %wide1 = zext i17 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = and i17 131071,1
 %wide2 = zext i17 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = and i17 65536,1
 %wide3 = zext i17 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_17_or(ptr %out,i64 %salt) {
entry:
 %value0 = or i17 0,131071
 %wide0 = zext i17 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = or i17 1,131071
 %wide1 = zext i17 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = or i17 131071,1
 %wide2 = zext i17 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = or i17 65536,1
 %wide3 = zext i17 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_17_xor(ptr %out,i64 %salt) {
entry:
 %value0 = xor i17 0,131071
 %wide0 = zext i17 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = xor i17 1,131071
 %wide1 = zext i17 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = xor i17 131071,1
 %wide2 = zext i17 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = xor i17 65536,1
 %wide3 = zext i17 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_17_shl(ptr %out,i64 %salt) {
entry:
 %value0 = shl i17 0,0
 %wide0 = zext i17 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = shl i17 1,1
 %wide1 = zext i17 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = shl i17 131071,16
 %wide2 = zext i17 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = shl i17 65536,8
 %wide3 = zext i17 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_17_lshr(ptr %out,i64 %salt) {
entry:
 %value0 = lshr i17 0,0
 %wide0 = zext i17 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = lshr i17 1,1
 %wide1 = zext i17 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = lshr i17 131071,16
 %wide2 = zext i17 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = lshr i17 65536,8
 %wide3 = zext i17 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_17_ashr(ptr %out,i64 %salt) {
entry:
 %value0 = ashr i17 0,0
 %wide0 = zext i17 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = ashr i17 1,1
 %wide1 = zext i17 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = ashr i17 131071,16
 %wide2 = zext i17 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = ashr i17 65536,8
 %wide3 = zext i17 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_17_udiv(ptr %out,i64 %salt) {
entry:
 %value0 = udiv i17 0,1
 %wide0 = zext i17 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = udiv i17 1,1
 %wide1 = zext i17 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = udiv i17 131071,131071
 %wide2 = zext i17 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = udiv i17 65536,1
 %wide3 = zext i17 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_17_urem(ptr %out,i64 %salt) {
entry:
 %value0 = urem i17 0,1
 %wide0 = zext i17 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = urem i17 1,1
 %wide1 = zext i17 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = urem i17 131071,131071
 %wide2 = zext i17 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = urem i17 65536,1
 %wide3 = zext i17 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_32_add(ptr %out,i64 %salt) {
entry:
 %value0 = add i32 0,4294967295
 %wide0 = zext i32 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = add i32 1,4294967295
 %wide1 = zext i32 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = add i32 4294967295,1
 %wide2 = zext i32 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = add i32 2147483648,1
 %wide3 = zext i32 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_32_sub(ptr %out,i64 %salt) {
entry:
 %value0 = sub i32 0,4294967295
 %wide0 = zext i32 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = sub i32 1,4294967295
 %wide1 = zext i32 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = sub i32 4294967295,1
 %wide2 = zext i32 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = sub i32 2147483648,1
 %wide3 = zext i32 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_32_mul(ptr %out,i64 %salt) {
entry:
 %value0 = mul i32 0,4294967295
 %wide0 = zext i32 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = mul i32 1,4294967295
 %wide1 = zext i32 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = mul i32 4294967295,1
 %wide2 = zext i32 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = mul i32 2147483648,1
 %wide3 = zext i32 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_32_and(ptr %out,i64 %salt) {
entry:
 %value0 = and i32 0,4294967295
 %wide0 = zext i32 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = and i32 1,4294967295
 %wide1 = zext i32 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = and i32 4294967295,1
 %wide2 = zext i32 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = and i32 2147483648,1
 %wide3 = zext i32 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_32_or(ptr %out,i64 %salt) {
entry:
 %value0 = or i32 0,4294967295
 %wide0 = zext i32 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = or i32 1,4294967295
 %wide1 = zext i32 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = or i32 4294967295,1
 %wide2 = zext i32 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = or i32 2147483648,1
 %wide3 = zext i32 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_32_xor(ptr %out,i64 %salt) {
entry:
 %value0 = xor i32 0,4294967295
 %wide0 = zext i32 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = xor i32 1,4294967295
 %wide1 = zext i32 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = xor i32 4294967295,1
 %wide2 = zext i32 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = xor i32 2147483648,1
 %wide3 = zext i32 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_32_shl(ptr %out,i64 %salt) {
entry:
 %value0 = shl i32 0,0
 %wide0 = zext i32 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = shl i32 1,1
 %wide1 = zext i32 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = shl i32 4294967295,31
 %wide2 = zext i32 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = shl i32 2147483648,16
 %wide3 = zext i32 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_32_lshr(ptr %out,i64 %salt) {
entry:
 %value0 = lshr i32 0,0
 %wide0 = zext i32 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = lshr i32 1,1
 %wide1 = zext i32 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = lshr i32 4294967295,31
 %wide2 = zext i32 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = lshr i32 2147483648,16
 %wide3 = zext i32 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_32_ashr(ptr %out,i64 %salt) {
entry:
 %value0 = ashr i32 0,0
 %wide0 = zext i32 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = ashr i32 1,1
 %wide1 = zext i32 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = ashr i32 4294967295,31
 %wide2 = zext i32 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = ashr i32 2147483648,16
 %wide3 = zext i32 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_32_udiv(ptr %out,i64 %salt) {
entry:
 %value0 = udiv i32 0,1
 %wide0 = zext i32 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = udiv i32 1,1
 %wide1 = zext i32 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = udiv i32 4294967295,4294967295
 %wide2 = zext i32 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = udiv i32 2147483648,1
 %wide3 = zext i32 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_32_urem(ptr %out,i64 %salt) {
entry:
 %value0 = urem i32 0,1
 %wide0 = zext i32 %value0 to i64
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = urem i32 1,1
 %wide1 = zext i32 %value1 to i64
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = urem i32 4294967295,4294967295
 %wide2 = zext i32 %value2 to i64
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = urem i32 2147483648,1
 %wide3 = zext i32 %value3 to i64
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_64_add(ptr %out,i64 %salt) {
entry:
 %value0 = add i64 0,18446744073709551615
 %wide0 = add i64 %value0,0
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = add i64 1,18446744073709551615
 %wide1 = add i64 %value1,0
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = add i64 18446744073709551615,1
 %wide2 = add i64 %value2,0
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = add i64 9223372036854775808,1
 %wide3 = add i64 %value3,0
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_64_sub(ptr %out,i64 %salt) {
entry:
 %value0 = sub i64 0,18446744073709551615
 %wide0 = add i64 %value0,0
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = sub i64 1,18446744073709551615
 %wide1 = add i64 %value1,0
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = sub i64 18446744073709551615,1
 %wide2 = add i64 %value2,0
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = sub i64 9223372036854775808,1
 %wide3 = add i64 %value3,0
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_64_mul(ptr %out,i64 %salt) {
entry:
 %value0 = mul i64 0,18446744073709551615
 %wide0 = add i64 %value0,0
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = mul i64 1,18446744073709551615
 %wide1 = add i64 %value1,0
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = mul i64 18446744073709551615,1
 %wide2 = add i64 %value2,0
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = mul i64 9223372036854775808,1
 %wide3 = add i64 %value3,0
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_64_and(ptr %out,i64 %salt) {
entry:
 %value0 = and i64 0,18446744073709551615
 %wide0 = add i64 %value0,0
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = and i64 1,18446744073709551615
 %wide1 = add i64 %value1,0
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = and i64 18446744073709551615,1
 %wide2 = add i64 %value2,0
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = and i64 9223372036854775808,1
 %wide3 = add i64 %value3,0
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_64_or(ptr %out,i64 %salt) {
entry:
 %value0 = or i64 0,18446744073709551615
 %wide0 = add i64 %value0,0
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = or i64 1,18446744073709551615
 %wide1 = add i64 %value1,0
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = or i64 18446744073709551615,1
 %wide2 = add i64 %value2,0
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = or i64 9223372036854775808,1
 %wide3 = add i64 %value3,0
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_64_xor(ptr %out,i64 %salt) {
entry:
 %value0 = xor i64 0,18446744073709551615
 %wide0 = add i64 %value0,0
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = xor i64 1,18446744073709551615
 %wide1 = add i64 %value1,0
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = xor i64 18446744073709551615,1
 %wide2 = add i64 %value2,0
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = xor i64 9223372036854775808,1
 %wide3 = add i64 %value3,0
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_64_shl(ptr %out,i64 %salt) {
entry:
 %value0 = shl i64 0,0
 %wide0 = add i64 %value0,0
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = shl i64 1,1
 %wide1 = add i64 %value1,0
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = shl i64 18446744073709551615,63
 %wide2 = add i64 %value2,0
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = shl i64 9223372036854775808,32
 %wide3 = add i64 %value3,0
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_64_lshr(ptr %out,i64 %salt) {
entry:
 %value0 = lshr i64 0,0
 %wide0 = add i64 %value0,0
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = lshr i64 1,1
 %wide1 = add i64 %value1,0
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = lshr i64 18446744073709551615,63
 %wide2 = add i64 %value2,0
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = lshr i64 9223372036854775808,32
 %wide3 = add i64 %value3,0
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_64_ashr(ptr %out,i64 %salt) {
entry:
 %value0 = ashr i64 0,0
 %wide0 = add i64 %value0,0
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = ashr i64 1,1
 %wide1 = add i64 %value1,0
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = ashr i64 18446744073709551615,63
 %wide2 = add i64 %value2,0
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = ashr i64 9223372036854775808,32
 %wide3 = add i64 %value3,0
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_64_udiv(ptr %out,i64 %salt) {
entry:
 %value0 = udiv i64 0,1
 %wide0 = add i64 %value0,0
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = udiv i64 1,1
 %wide1 = add i64 %value1,0
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = udiv i64 18446744073709551615,18446744073709551615
 %wide2 = add i64 %value2,0
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = udiv i64 9223372036854775808,1
 %wide3 = add i64 %value3,0
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
define i64 @constant_pairs_64_urem(ptr %out,i64 %salt) {
entry:
 %value0 = urem i64 0,1
 %wide0 = add i64 %value0,0
 %mix0 = xor i64 %wide0,%salt
 %ptr0 = getelementptr i8,ptr %out,i64 0
 store i64 %mix0,ptr %ptr0,align 1
 %value1 = urem i64 1,1
 %wide1 = add i64 %value1,0
 %mix1 = xor i64 %wide1,%salt
 %ptr1 = getelementptr i8,ptr %out,i64 8
 store i64 %mix1,ptr %ptr1,align 1
 %value2 = urem i64 18446744073709551615,18446744073709551615
 %wide2 = add i64 %value2,0
 %mix2 = xor i64 %wide2,%salt
 %ptr2 = getelementptr i8,ptr %out,i64 16
 store i64 %mix2,ptr %ptr2,align 1
 %value3 = urem i64 9223372036854775808,1
 %wide3 = add i64 %value3,0
 %mix3 = xor i64 %wide3,%salt
 %ptr3 = getelementptr i8,ptr %out,i64 24
 store i64 %mix3,ptr %ptr3,align 1
 %live = xor i64 %salt,90
 ret i64 %live
}
