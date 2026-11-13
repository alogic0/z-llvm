target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
define <4 x float> @native_fp_mask_32_0_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp false <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_0_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp false <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_1_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp oeq <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_1_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp oeq <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_2_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp ogt <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_2_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp ogt <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_3_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp oge <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_3_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp oge <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_4_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp olt <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_4_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp olt <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_5_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp ole <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_5_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp ole <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_6_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp one <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_6_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp one <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_7_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp ord <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_7_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp ord <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_8_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp ueq <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_8_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp ueq <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_9_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp ugt <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_9_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp ugt <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_10_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp uge <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_10_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp uge <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_11_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp ult <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_11_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp ult <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_12_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp ule <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_12_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp ule <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_13_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp une <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_13_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp une <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_14_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp uno <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_14_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp uno <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <4 x float> @native_fp_mask_32_15_0(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp true <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define fastcc <4 x float> @native_fp_mask_32_15_1(<4 x float> %a,<4 x float> %b) noinline {
entry:
 %home = alloca <4 x float>,align 16
 store <4 x float> %a,ptr %home,align 16
 %copy = load <4 x float>,ptr %home,align 16
 %condition = fcmp true <4 x float> %copy,%b
 %result = select <4 x i1> %condition,<4 x float> %copy,<4 x float> %b
 ret <4 x float> %result
}
define <2 x double> @native_fp_mask_64_0_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp false <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_0_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp false <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_1_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp oeq <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_1_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp oeq <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_2_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp ogt <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_2_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp ogt <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_3_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp oge <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_3_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp oge <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_4_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp olt <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_4_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp olt <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_5_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp ole <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_5_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp ole <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_6_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp one <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_6_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp one <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_7_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp ord <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_7_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp ord <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_8_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp ueq <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_8_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp ueq <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_9_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp ugt <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_9_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp ugt <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_10_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp uge <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_10_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp uge <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_11_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp ult <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_11_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp ult <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_12_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp ule <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_12_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp ule <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_13_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp une <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_13_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp une <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_14_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp uno <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_14_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp uno <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define <2 x double> @native_fp_mask_64_15_0(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp true <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
define fastcc <2 x double> @native_fp_mask_64_15_1(<2 x double> %a,<2 x double> %b) noinline {
entry:
 %home = alloca <2 x double>,align 16
 store <2 x double> %a,ptr %home,align 16
 %copy = load <2 x double>,ptr %home,align 16
 %condition = fcmp true <2 x double> %copy,%b
 %result = select <2 x i1> %condition,<2 x double> %copy,<2 x double> %b
 ret <2 x double> %result
}
