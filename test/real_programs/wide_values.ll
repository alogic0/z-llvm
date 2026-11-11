target triple = "x86_64-unknown-linux-gnu"
declare i64 @wide_values_clobber(i64)
declare i128 @wide_values_probe(i128,i128,i64)
declare i65 @llvm.abs.i65(i65,i1)
define i128 @wide_values_65_abs_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i65
 %result = call i65 @llvm.abs.i65(i65 %narrow,i1 false)
 %wide = zext i65 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_65_abs_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i65
 %result = call i65 @llvm.abs.i65(i65 81985529216486895,i1 false)
 %wide = zext i65 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i65 @llvm.ctlz.i65(i65,i1)
define i128 @wide_values_65_ctlz_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i65
 %result = call i65 @llvm.ctlz.i65(i65 %narrow,i1 false)
 %wide = zext i65 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_65_ctlz_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i65
 %result = call i65 @llvm.ctlz.i65(i65 81985529216486895,i1 false)
 %wide = zext i65 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i65 @llvm.cttz.i65(i65,i1)
define i128 @wide_values_65_cttz_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i65
 %result = call i65 @llvm.cttz.i65(i65 %narrow,i1 false)
 %wide = zext i65 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_65_cttz_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i65
 %result = call i65 @llvm.cttz.i65(i65 81985529216486895,i1 false)
 %wide = zext i65 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i65 @llvm.ctpop.i65(i65)
define i128 @wide_values_65_ctpop_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i65
 %result = call i65 @llvm.ctpop.i65(i65 %narrow)
 %wide = zext i65 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_65_ctpop_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i65
 %result = call i65 @llvm.ctpop.i65(i65 81985529216486895)
 %wide = zext i65 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i80 @llvm.abs.i80(i80,i1)
define i128 @wide_values_80_abs_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i80
 %result = call i80 @llvm.abs.i80(i80 %narrow,i1 false)
 %wide = zext i80 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_80_abs_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i80
 %result = call i80 @llvm.abs.i80(i80 236413554034190829997551,i1 false)
 %wide = zext i80 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i80 @llvm.ctlz.i80(i80,i1)
define i128 @wide_values_80_ctlz_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i80
 %result = call i80 @llvm.ctlz.i80(i80 %narrow,i1 false)
 %wide = zext i80 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_80_ctlz_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i80
 %result = call i80 @llvm.ctlz.i80(i80 236413554034190829997551,i1 false)
 %wide = zext i80 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i80 @llvm.cttz.i80(i80,i1)
define i128 @wide_values_80_cttz_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i80
 %result = call i80 @llvm.cttz.i80(i80 %narrow,i1 false)
 %wide = zext i80 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_80_cttz_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i80
 %result = call i80 @llvm.cttz.i80(i80 236413554034190829997551,i1 false)
 %wide = zext i80 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i80 @llvm.ctpop.i80(i80)
define i128 @wide_values_80_ctpop_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i80
 %result = call i80 @llvm.ctpop.i80(i80 %narrow)
 %wide = zext i80 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_80_ctpop_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i80
 %result = call i80 @llvm.ctpop.i80(i80 236413554034190829997551)
 %wide = zext i80 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i113 @llvm.abs.i113(i113,i1)
define i128 @wide_values_113_abs_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i113
 %result = call i113 @llvm.abs.i113(i113 %narrow,i1 false)
 %wide = zext i113 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_113_abs_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i113
 %result = call i113 @llvm.abs.i113(i113 3784607487998720198549558449130991,i1 false)
 %wide = zext i113 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i113 @llvm.ctlz.i113(i113,i1)
define i128 @wide_values_113_ctlz_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i113
 %result = call i113 @llvm.ctlz.i113(i113 %narrow,i1 false)
 %wide = zext i113 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_113_ctlz_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i113
 %result = call i113 @llvm.ctlz.i113(i113 3784607487998720198549558449130991,i1 false)
 %wide = zext i113 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i113 @llvm.cttz.i113(i113,i1)
define i128 @wide_values_113_cttz_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i113
 %result = call i113 @llvm.cttz.i113(i113 %narrow,i1 false)
 %wide = zext i113 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_113_cttz_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i113
 %result = call i113 @llvm.cttz.i113(i113 3784607487998720198549558449130991,i1 false)
 %wide = zext i113 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i113 @llvm.ctpop.i113(i113)
define i128 @wide_values_113_ctpop_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i113
 %result = call i113 @llvm.ctpop.i113(i113 %narrow)
 %wide = zext i113 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_113_ctpop_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i113
 %result = call i113 @llvm.ctpop.i113(i113 3784607487998720198549558449130991)
 %wide = zext i113 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i127 @llvm.abs.i127(i127,i1)
define i128 @wide_values_127_abs_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i127
 %result = call i127 @llvm.abs.i127(i127 %narrow,i1 false)
 %wide = zext i127 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_127_abs_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i127
 %result = call i127 @llvm.abs.i127(i127 168628817385265060784354948346200968687,i1 false)
 %wide = zext i127 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i127 @llvm.ctlz.i127(i127,i1)
define i128 @wide_values_127_ctlz_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i127
 %result = call i127 @llvm.ctlz.i127(i127 %narrow,i1 false)
 %wide = zext i127 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_127_ctlz_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i127
 %result = call i127 @llvm.ctlz.i127(i127 168628817385265060784354948346200968687,i1 false)
 %wide = zext i127 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i127 @llvm.cttz.i127(i127,i1)
define i128 @wide_values_127_cttz_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i127
 %result = call i127 @llvm.cttz.i127(i127 %narrow,i1 false)
 %wide = zext i127 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_127_cttz_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i127
 %result = call i127 @llvm.cttz.i127(i127 168628817385265060784354948346200968687,i1 false)
 %wide = zext i127 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
declare i127 @llvm.ctpop.i127(i127)
define i128 @wide_values_127_ctpop_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i127
 %result = call i127 @llvm.ctpop.i127(i127 %narrow)
 %wide = zext i127 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_127_ctpop_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %narrow = trunc i128 %raw to i127
 %result = call i127 @llvm.ctpop.i127(i127 168628817385265060784354948346200968687)
 %wide = zext i127 %result to i128
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %wide,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %wide,%extended
 ret i128 %answer
}
define i128 @wide_values_call_0(i128 %raw,ptr %out,i64 %live) {
entry:
 %result = call i128 @wide_values_probe(i128 -1512366075204170947332355369683137041,i128 %raw,i64 %live)
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %result,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %result,%extended
 ret i128 %answer
}
define i128 @wide_values_call_1(i128 %raw,ptr %out,i64 %live) {
entry:
 %result = call i128 @wide_values_probe(i128 %raw,i128 -1512366075204170947332355369683137041,i64 %live)
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %result,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %result,%extended
 ret i128 %answer
}
define i128 @wide_values_call_2(i128 %raw,ptr %out,i64 %live) {
entry:
 %result = call i128 @wide_values_probe(i128 -1512366075204170947332355369683137041,i128 -1512366075204170947332355369683137041,i64 %live)
 %probe = call i64 @wide_values_clobber(i64 %live)
 store i128 %result,ptr %out,align 1
 %extended = zext i64 %probe to i128
 %answer = xor i128 %result,%extended
 ret i128 %answer
}
