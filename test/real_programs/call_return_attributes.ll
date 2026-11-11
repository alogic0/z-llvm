target triple = "x86_64-unknown-linux-gnu"
declare zeroext i1 @return_attr_helper_1(i1 zeroext, i64, i64, i64, i64, i64, i64, i64)
define zeroext i1 @return_attr_own_1(i1 zeroext %input, i64 %seed) {
entry:
 %wide = zext i1 %input to i64
 %mixed = xor i64 %wide, %seed
 %small = trunc i64 %mixed to i1
 ret i1 %small
}
define i64 @return_attr_call_1(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h) {
entry:
 %small = trunc i64 %a to i1
 %called = call zeroext i1 @return_attr_helper_1(i1 zeroext %small, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h)
 %wide = zext i1 %called to i64
 %one = xor i64 %wide, %a
 %two = add i64 %one, %b
 %three = xor i64 %two, %c
 %four = add i64 %three, %d
 %five = xor i64 %four, %e
 %six = sub i64 %five, %f
 %seven = xor i64 %six, %g
 %result = add i64 %seven, %h
 ret i64 %result
}
declare zeroext i7 @return_attr_helper_7(i7 zeroext, i64, i64, i64, i64, i64, i64, i64)
define zeroext i7 @return_attr_own_7(i7 zeroext %input, i64 %seed) {
entry:
 %wide = zext i7 %input to i64
 %mixed = xor i64 %wide, %seed
 %small = trunc i64 %mixed to i7
 ret i7 %small
}
define i64 @return_attr_call_7(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h) {
entry:
 %small = trunc i64 %a to i7
 %called = call zeroext i7 @return_attr_helper_7(i7 zeroext %small, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h)
 %wide = zext i7 %called to i64
 %one = xor i64 %wide, %a
 %two = add i64 %one, %b
 %three = xor i64 %two, %c
 %four = add i64 %three, %d
 %five = xor i64 %four, %e
 %six = sub i64 %five, %f
 %seven = xor i64 %six, %g
 %result = add i64 %seven, %h
 ret i64 %result
}
declare zeroext i8 @return_attr_helper_8(i8 zeroext, i64, i64, i64, i64, i64, i64, i64)
define zeroext i8 @return_attr_own_8(i8 zeroext %input, i64 %seed) {
entry:
 %wide = zext i8 %input to i64
 %mixed = xor i64 %wide, %seed
 %small = trunc i64 %mixed to i8
 ret i8 %small
}
define i64 @return_attr_call_8(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h) {
entry:
 %small = trunc i64 %a to i8
 %called = call zeroext i8 @return_attr_helper_8(i8 zeroext %small, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h)
 %wide = zext i8 %called to i64
 %one = xor i64 %wide, %a
 %two = add i64 %one, %b
 %three = xor i64 %two, %c
 %four = add i64 %three, %d
 %five = xor i64 %four, %e
 %six = sub i64 %five, %f
 %seven = xor i64 %six, %g
 %result = add i64 %seven, %h
 ret i64 %result
}
declare zeroext i16 @return_attr_helper_16(i16 zeroext, i64, i64, i64, i64, i64, i64, i64)
define zeroext i16 @return_attr_own_16(i16 zeroext %input, i64 %seed) {
entry:
 %wide = zext i16 %input to i64
 %mixed = xor i64 %wide, %seed
 %small = trunc i64 %mixed to i16
 ret i16 %small
}
define i64 @return_attr_call_16(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h) {
entry:
 %small = trunc i64 %a to i16
 %called = call zeroext i16 @return_attr_helper_16(i16 zeroext %small, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h)
 %wide = zext i16 %called to i64
 %one = xor i64 %wide, %a
 %two = add i64 %one, %b
 %three = xor i64 %two, %c
 %four = add i64 %three, %d
 %five = xor i64 %four, %e
 %six = sub i64 %five, %f
 %seven = xor i64 %six, %g
 %result = add i64 %seven, %h
 ret i64 %result
}
declare zeroext i23 @return_attr_helper_23(i23 zeroext, i64, i64, i64, i64, i64, i64, i64)
define zeroext i23 @return_attr_own_23(i23 zeroext %input, i64 %seed) {
entry:
 %wide = zext i23 %input to i64
 %mixed = xor i64 %wide, %seed
 %small = trunc i64 %mixed to i23
 ret i23 %small
}
define i64 @return_attr_call_23(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h) {
entry:
 %small = trunc i64 %a to i23
 %called = call zeroext i23 @return_attr_helper_23(i23 zeroext %small, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h)
 %wide = zext i23 %called to i64
 %one = xor i64 %wide, %a
 %two = add i64 %one, %b
 %three = xor i64 %two, %c
 %four = add i64 %three, %d
 %five = xor i64 %four, %e
 %six = sub i64 %five, %f
 %seven = xor i64 %six, %g
 %result = add i64 %seven, %h
 ret i64 %result
}
declare zeroext i31 @return_attr_helper_31(i31 zeroext, i64, i64, i64, i64, i64, i64, i64)
define zeroext i31 @return_attr_own_31(i31 zeroext %input, i64 %seed) {
entry:
 %wide = zext i31 %input to i64
 %mixed = xor i64 %wide, %seed
 %small = trunc i64 %mixed to i31
 ret i31 %small
}
define i64 @return_attr_call_31(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h) {
entry:
 %small = trunc i64 %a to i31
 %called = call zeroext i31 @return_attr_helper_31(i31 zeroext %small, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i64 %g, i64 %h)
 %wide = zext i31 %called to i64
 %one = xor i64 %wide, %a
 %two = add i64 %one, %b
 %three = xor i64 %two, %c
 %four = add i64 %three, %d
 %five = xor i64 %four, %e
 %six = sub i64 %five, %f
 %seven = xor i64 %six, %g
 %result = add i64 %seven, %h
 ret i64 %result
}
declare dereferenceable_or_null(16) ptr @return_attr_pointer_helper_16(ptr dereferenceable_or_null(16), i64, i64, i64)
define i64 @return_attr_nullable_16(ptr dereferenceable_or_null(16) %input, i64 %choose, i64 %seed, i64 %live) {
entry:
 %called = call dereferenceable_or_null(16) ptr @return_attr_pointer_helper_16(ptr dereferenceable_or_null(16) %input, i64 %choose, i64 %seed, i64 %live)
 %empty = icmp eq ptr %called, null
 br i1 %empty, label %null, label %read
read:
 %last = getelementptr i8, ptr %called, i64 15
 %first_byte = load i8, ptr %called, align 1
 %last_byte = load i8, ptr %last, align 1
 %first = zext i8 %first_byte to i64
 %final = zext i8 %last_byte to i64
 %bytes = xor i64 %first, %final
 br label %done
null:
 br label %done
done:
 %value = phi i64 [ %bytes, %read ], [ 74565, %null ]
 %mixed = xor i64 %value, %seed
 %result = add i64 %mixed, %live
 ret i64 %result
}
declare dereferenceable_or_null(140) ptr @return_attr_pointer_helper_140(ptr dereferenceable_or_null(140), i64, i64, i64)
define i64 @return_attr_nullable_140(ptr dereferenceable_or_null(140) %input, i64 %choose, i64 %seed, i64 %live) {
entry:
 %called = call dereferenceable_or_null(140) ptr @return_attr_pointer_helper_140(ptr dereferenceable_or_null(140) %input, i64 %choose, i64 %seed, i64 %live)
 %empty = icmp eq ptr %called, null
 br i1 %empty, label %null, label %read
read:
 %last = getelementptr i8, ptr %called, i64 139
 %first_byte = load i8, ptr %called, align 1
 %last_byte = load i8, ptr %last, align 1
 %first = zext i8 %first_byte to i64
 %final = zext i8 %last_byte to i64
 %bytes = xor i64 %first, %final
 br label %done
null:
 br label %done
done:
 %value = phi i64 [ %bytes, %read ], [ 74565, %null ]
 %mixed = xor i64 %value, %seed
 %result = add i64 %mixed, %live
 ret i64 %result
}
define dereferenceable_or_null(16) ptr @return_attr_nullable_forward(ptr dereferenceable_or_null(16) %input) {
entry:
 ret ptr %input
}
