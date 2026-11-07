target triple = "x86_64-unknown-linux-gnu"
declare void @vector_cast_clobber()

define void @vector_cast_narrow(ptr %input, ptr %output, ptr %preserved) {
entry:
  %source = load <2 x double>, ptr %input, align 1
  %converted = fptrunc <2 x double> %source to <2 x float>
  store <2 x float> %converted, ptr %output, align 1
  store <2 x double> %source, ptr %preserved, align 1
  ret void
}

define void @vector_cast_widen(ptr %input, ptr %output, ptr %preserved) {
entry:
  %source = load <2 x float>, ptr %input, align 1
  %converted = fpext <2 x float> %source to <2 x double>
  store <2 x double> %converted, ptr %output, align 1
  store <2 x float> %source, ptr %preserved, align 1
  ret void
}

define void @vector_cast_phi(ptr %input, ptr %output, i64 %choice) {
entry:
  %source = load <2 x double>, ptr %input, align 1
  %condition = icmp eq i64 %choice, 0
  br i1 %condition, label %left, label %right
left:
  %narrow = fptrunc <2 x double> %source to <2 x float>
  %left.wide = fpext <2 x float> %narrow to <2 x double>
  br label %join
right:
  %reverse = shufflevector <2 x double> %source, <2 x double> poison, <2 x i32> <i32 1, i32 0>
  %reversed = fptrunc <2 x double> %reverse to <2 x float>
  %right.wide = fpext <2 x float> %reversed to <2 x double>
  br label %join
join:
  %selected = phi <2 x double> [ %left.wide, %left ], [ %right.wide, %right ]
  store <2 x double> %selected, ptr %output, align 1
  ret void
}

define void @vector_cast_pressure(ptr %output, double %a, double %b, double %c, double %d, double %e, double %f, double %g, double %h) {
entry:
  %v0.seed = insertelement <2 x double> poison, double %a, i64 0
  %v0 = insertelement <2 x double> %v0.seed, double %b, i64 1
  %v1.seed = insertelement <2 x double> poison, double %c, i64 0
  %v1 = insertelement <2 x double> %v1.seed, double %d, i64 1
  %v2.seed = insertelement <2 x double> poison, double %e, i64 0
  %v2 = insertelement <2 x double> %v2.seed, double %f, i64 1
  %v3.seed = insertelement <2 x double> poison, double %g, i64 0
  %v3 = insertelement <2 x double> %v3.seed, double %h, i64 1
  %n0 = fptrunc <2 x double> %v0 to <2 x float>
  %n1 = fptrunc <2 x double> %v1 to <2 x float>
  %n2 = fptrunc <2 x double> %v2 to <2 x float>
  %n3 = fptrunc <2 x double> %v3 to <2 x float>
  call void @vector_cast_clobber()
  %p1 = getelementptr i8, ptr %output, i64 16
  %p2 = getelementptr i8, ptr %output, i64 32
  %p3 = getelementptr i8, ptr %output, i64 48
  store <2 x double> %v0, ptr %output, align 1
  store <2 x double> %v1, ptr %p1, align 1
  store <2 x double> %v2, ptr %p2, align 1
  store <2 x double> %v3, ptr %p3, align 1
  %w0 = fpext <2 x float> %n0 to <2 x double>
  %w1 = fpext <2 x float> %n1 to <2 x double>
  %w2 = fpext <2 x float> %n2 to <2 x double>
  %w3 = fpext <2 x float> %n3 to <2 x double>
  %p4 = getelementptr i8, ptr %output, i64 64
  %p5 = getelementptr i8, ptr %output, i64 80
  %p6 = getelementptr i8, ptr %output, i64 96
  %p7 = getelementptr i8, ptr %output, i64 112
  store <2 x double> %w0, ptr %p4, align 1
  store <2 x double> %w1, ptr %p5, align 1
  store <2 x double> %w2, ptr %p6, align 1
  store <2 x double> %w3, ptr %p7, align 1
  ret void
}

define float @vector_cast_partial(double %input) {
entry:
  %source = insertelement <2 x double> poison, double %input, i64 0
  %converted = fptrunc <2 x double> %source to <2 x float>
  %result = extractelement <2 x float> %converted, i64 0
  ret float %result
}
