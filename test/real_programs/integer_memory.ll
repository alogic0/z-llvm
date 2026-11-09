target triple = "x86_64-unknown-linux-gnu"
declare i64 @integer_memory_clobber(i64)

define i64 @integer_memory_24(ptr %input, ptr %output, i64 %live) {
entry:
 %value = load i24, ptr %input, align 1
 %changed = xor i24 %value, 173
 store i24 %changed, ptr %output, align 1
 %clobbered = call i64 @integer_memory_clobber(i64 %live)
 %back = load i24, ptr %output, align 1
 %wide = zext i24 %back to i64
 %result = xor i64 %wide, %clobbered
 ret i64 %result
}

define i64 @integer_memory_40(ptr %input, ptr %output, i64 %live) {
entry:
 %value = load i40, ptr %input, align 1
 %changed = xor i40 %value, 173
 store i40 %changed, ptr %output, align 1
 %clobbered = call i64 @integer_memory_clobber(i64 %live)
 %back = load i40, ptr %output, align 1
 %wide = zext i40 %back to i64
 %result = xor i64 %wide, %clobbered
 ret i64 %result
}

define i64 @integer_memory_56(ptr %input, ptr %output, i64 %live) {
entry:
 %value = load i56, ptr %input, align 1
 %changed = xor i56 %value, 173
 store i56 %changed, ptr %output, align 1
 %clobbered = call i64 @integer_memory_clobber(i64 %live)
 %back = load i56, ptr %output, align 1
 %wide = zext i56 %back to i64
 %result = xor i64 %wide, %clobbered
 ret i64 %result
}

define i64 @integer_memory_65(ptr %input, ptr %output, i64 %live) {
entry:
 ; Non-byte-sized loads require a preceding store of the same type. Seed
 ; the source through defined native-width reads before exercising i65.
 %seed_low = load i64, ptr %input, align 1
 %seed_high_ptr = getelementptr i8, ptr %input, i64 8
 %seed_byte = load i8, ptr %seed_high_ptr, align 1
 %seed_bit = and i8 %seed_byte, 1
 %seed_low65 = zext i64 %seed_low to i65
 %seed_high65 = zext i8 %seed_bit to i65
 %seed_shifted = shl i65 %seed_high65, 64
 %seed = or i65 %seed_low65, %seed_shifted
 store i65 %seed, ptr %input, align 1
 %value = load i65, ptr %input, align 1
 %changed = xor i65 %value, 173
 store i65 %changed, ptr %output, align 1
 %clobbered = call i64 @integer_memory_clobber(i64 %live)
 %back = load i65, ptr %output, align 1
 %upper = lshr i65 %back, 64
 %high = trunc i65 %upper to i64
 %low = trunc i65 %back to i64
 %fold = xor i64 %low, %high
 %result = xor i64 %fold, %clobbered
 ret i64 %result
}

define i64 @integer_memory_96(ptr %input, ptr %output, i64 %live) {
entry:
 %value = load i96, ptr %input, align 1
 %changed = xor i96 %value, 173
 store i96 %changed, ptr %output, align 1
 %clobbered = call i64 @integer_memory_clobber(i64 %live)
 %back = load i96, ptr %output, align 1
 %upper = lshr i96 %back, 64
 %high = trunc i96 %upper to i64
 %low = trunc i96 %back to i64
 %fold = xor i64 %low, %high
 %result = xor i64 %fold, %clobbered
 ret i64 %result
}
