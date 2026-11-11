target triple = "x86_64-unknown-linux-gnu"
define i128 @hardware_queries_named(i32 %leaf,i32 %subleaf,ptr %out,i128 %live) {
entry:
 %r = call { i32, i32, i32, i32 } asm sideeffect "cpuid", "={eax},={ebx},={ecx},={edx},{eax},{ecx},~{dirflag},~{fpsr},~{flags}"(i32 %leaf,i32 %subleaf)
 %a = extractvalue { i32, i32, i32, i32 } %r,0
 %aw = zext i32 %a to i128
 %b = extractvalue { i32, i32, i32, i32 } %r,1
 %bw = zext i32 %b to i128
 %bs = shl i128 %bw,32
 %c = extractvalue { i32, i32, i32, i32 } %r,2
 %cw = zext i32 %c to i128
 %cs = shl i128 %cw,64
 %d = extractvalue { i32, i32, i32, i32 } %r,3
 %dw = zext i32 %d to i128
 %ds = shl i128 %dw,96
 %lo = or i128 %aw,%bs
 %hi = or i128 %cs,%ds
 %packed = or i128 %lo,%hi
 store i128 %packed,ptr %out,align 1
 %answer = xor i128 %packed,%live
 ret i128 %answer
}
define i128 @hardware_queries_leaf0(i32 %leaf,i32 %subleaf,ptr %out,i128 %live) {
entry:
 %r = call { i32, i32, i32, i32 } asm sideeffect "cpuid", "={eax},={ebx},={ecx},={edx},{eax},{ecx},~{dirflag},~{fpsr},~{flags}"(i32 0,i32 0)
 %a = extractvalue { i32, i32, i32, i32 } %r,0
 %aw = zext i32 %a to i128
 %b = extractvalue { i32, i32, i32, i32 } %r,1
 %bw = zext i32 %b to i128
 %bs = shl i128 %bw,32
 %c = extractvalue { i32, i32, i32, i32 } %r,2
 %cw = zext i32 %c to i128
 %cs = shl i128 %cw,64
 %d = extractvalue { i32, i32, i32, i32 } %r,3
 %dw = zext i32 %d to i128
 %ds = shl i128 %dw,96
 %lo = or i128 %aw,%bs
 %hi = or i128 %cs,%ds
 %packed = or i128 %lo,%hi
 store i128 %packed,ptr %out,align 1
 %answer = xor i128 %packed,%live
 ret i128 %answer
}
define i128 @hardware_queries_leaf7(i32 %leaf,i32 %subleaf,ptr %out,i128 %live) {
entry:
 %r = call { i32, i32, i32, i32 } asm sideeffect "cpuid", "={eax},={ebx},={ecx},={edx},{eax},{ecx},~{dirflag},~{fpsr},~{flags}"(i32 7,i32 0)
 %a = extractvalue { i32, i32, i32, i32 } %r,0
 %aw = zext i32 %a to i128
 %b = extractvalue { i32, i32, i32, i32 } %r,1
 %bw = zext i32 %b to i128
 %bs = shl i128 %bw,32
 %c = extractvalue { i32, i32, i32, i32 } %r,2
 %cw = zext i32 %c to i128
 %cs = shl i128 %cw,64
 %d = extractvalue { i32, i32, i32, i32 } %r,3
 %dw = zext i32 %d to i128
 %ds = shl i128 %dw,96
 %lo = or i128 %aw,%bs
 %hi = or i128 %cs,%ds
 %packed = or i128 %lo,%hi
 store i128 %packed,ptr %out,align 1
 %answer = xor i128 %packed,%live
 ret i128 %answer
}
define i128 @hardware_queries_xcr0(i32 %leaf,i32 %subleaf,ptr %out,i128 %live) {
entry:
 %r = call { i32, i32, i32, i32 } asm sideeffect "cpuid", "={eax},={ebx},={ecx},={edx},{eax},{ecx},~{dirflag},~{fpsr},~{flags}"(i32 1,i32 0)
 %features = extractvalue { i32, i32, i32, i32 } %r,2
 %osxsave = and i32 %features,134217728
 %enabled = icmp ne i32 %osxsave,0
 br i1 %enabled,label %query,label %exit
query:
 %xcr = call i32 asm sideeffect " xor %ecx, %ecx\0A xgetbv", "={eax},~{ecx},~{edx},~{dirflag},~{fpsr},~{flags}"()
 %wide = zext i32 %xcr to i128
 br label %exit
exit:
 %packed = phi i128 [ 0,%entry ],[ %wide,%query ]
 store i128 %packed,ptr %out,align 1
 %answer = xor i128 %packed,%live
 ret i128 %answer
}
define i128 @hardware_queries_delayed(i32 %leaf,i32 %subleaf,ptr %out,i128 %live) {
entry:
 %r = call { i32, i32, i32, i32 } asm sideeffect "cpuid", "={eax},={ebx},={ecx},={edx},{eax},{ecx},~{dirflag},~{fpsr},~{flags}"(i32 %leaf,i32 %subleaf)
 %a = extractvalue { i32, i32, i32, i32 } %r,0
 %aw = zext i32 %a to i128
 %b = extractvalue { i32, i32, i32, i32 } %r,1
 %bw = zext i32 %b to i128
 %bs = shl i128 %bw,32
 %c = extractvalue { i32, i32, i32, i32 } %r,2
 %cw = zext i32 %c to i128
 %cs = shl i128 %cw,64
 %d = extractvalue { i32, i32, i32, i32 } %r,3
 %dw = zext i32 %d to i128
 %ds = shl i128 %dw,96
 %lo = or i128 %aw,%bs
 %hi = or i128 %cs,%ds
 %packed = or i128 %lo,%hi
 %unused = call { i32, i32, i32, i32 } asm sideeffect "cpuid", "={eax},={ebx},={ecx},={edx},{eax},{ecx},~{dirflag},~{fpsr},~{flags}"(i32 0,i32 0)
 %zero = icmp eq i32 %a,0
 %flag = zext i1 %zero to i128
 %marker = shl i128 %flag,127
 %payload = xor i128 %packed,%marker
 store i128 %payload,ptr %out,align 1
 %answer = xor i128 %payload,%live
 ret i128 %answer
}
