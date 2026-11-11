declare x86_fp80 @extended80_mixed_provider(i64,double,x86_fp80,i64,float,i64,double,i64,i64,i64,i64,x86_fp80,fp128,ptr)

define i128 @extended80_mixed_incoming(i64 %a,double %d0,x86_fp80 %x,i64 %b,float %f0,i64 %c,double %d1,i64 %d,i64 %e,i64 %f,i64 %g,x86_fp80 %y,fp128 %q,ptr %output) {
entry:
 %probe = call i64 @extended80_float_clobber(i64 %a)
 store x86_fp80 %x,ptr %output,align 1
 %o10 = getelementptr i8,ptr %output,i64 10
 store x86_fp80 %y,ptr %o10,align 1
 %o20 = getelementptr i8,ptr %output,i64 20
 store fp128 %q,ptr %o20,align 1
 %o36 = getelementptr i8,ptr %output,i64 36
 store double %d0,ptr %o36,align 1
 %o44 = getelementptr i8,ptr %output,i64 44
 store float %f0,ptr %o44,align 1
 %o48 = getelementptr i8,ptr %output,i64 48
 store double %d1,ptr %o48,align 1
 %xb = bitcast x86_fp80 %x to i80
 %yb = bitcast x86_fp80 %y to i80
 %xw = zext i80 %xb to i128
 %yw = zext i80 %yb to i128
 %qb = bitcast fp128 %q to i128
 %d0b = bitcast double %d0 to i64
 %f0b = bitcast float %f0 to i32
 %d1b = bitcast double %d1 to i64
 %d0w = zext i64 %d0b to i128
 %f0w = zext i32 %f0b to i128
 %d1w = zext i64 %d1b to i128
 %s1 = xor i64 %probe,%b
 %s2 = add i64 %s1,%c
 %s3 = xor i64 %s2,%d
 %s4 = add i64 %s3,%e
 %s5 = xor i64 %s4,%f
 %s6 = add i64 %s5,%g
 %sw = zext i64 %s6 to i128
 %v1 = xor i128 %xw,%yw
 %v2 = xor i128 %v1,%qb
 %v3 = xor i128 %v2,%d0w
 %v4 = xor i128 %v3,%f0w
 %v5 = xor i128 %v4,%d1w
 %answer = xor i128 %v5,%sw
 ret i128 %answer
}

define i128 @extended80_mixed_call(ptr %input,ptr %output,i64 %live) {
entry:
 %x = load x86_fp80,ptr %input,align 1
 %i16 = getelementptr i8,ptr %input,i64 16
 %y = load x86_fp80,ptr %i16,align 1
 %i32 = getelementptr i8,ptr %input,i64 32
 %q = load fp128,ptr %i32,align 1
 %i48 = getelementptr i8,ptr %input,i64 48
 %d0 = load double,ptr %i48,align 1
 %i56 = getelementptr i8,ptr %input,i64 56
 %f0 = load float,ptr %i56,align 1
 %i60 = getelementptr i8,ptr %input,i64 60
 %d1 = load double,ptr %i60,align 1
 %r = call x86_fp80 @extended80_mixed_provider(i64 %live,double %d0,x86_fp80 %x,i64 13,float %f0,i64 17,double %d1,i64 19,i64 23,i64 29,i64 31,x86_fp80 %y,fp128 %q,ptr %output)
 %probe = call i64 @extended80_float_clobber(i64 %live)
 %last = getelementptr i8,ptr %output,i64 56
 store x86_fp80 %r,ptr %last,align 1
 %rb = bitcast x86_fp80 %r to i80
 %rw = zext i80 %rb to i128
 %qb = bitcast fp128 %q to i128
 %mask = zext i64 %probe to i128
 %with_q = xor i128 %rw,%qb
 %answer = xor i128 %with_q,%mask
 ret i128 %answer
}
