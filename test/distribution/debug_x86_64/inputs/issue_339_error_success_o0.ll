; ModuleID = 'BitcodeBuffer'
source_filename = "test"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

%Io.Writer.VTable = type { ptr, ptr, ptr, ptr }
%Target.Os = type { %Target.Os.VersionRange, i6, [7 x i8] }
%Target.Os.VersionRange = type { %Target.Os.LinuxVersionRange, i3, [7 x i8] }
%Target.Os.LinuxVersionRange = type { %SemanticVersion.Range, %SemanticVersion, i32, [4 x i8] }
%SemanticVersion.Range = type { %SemanticVersion, %SemanticVersion }
%SemanticVersion = type { i64, i64, i64, { ptr, i64 }, { ptr, i64 } }
%std.Options = type { { i64, i8, [7 x i8] }, { ptr, i64 }, { i64, i8, [7 x i8] }, { i64, i8, [7 x i8] }, i64, i1, i2, i1, i1, i2, i1, i1, i1 }
%fmt.Options = type { { i64, i8, [7 x i8] }, { i64, i8, [7 x i8] }, i2, i8, [6 x i8] }
%Io.Writer = type { ptr, { ptr, i64 }, i64 }

@builtin.output_mode = private unnamed_addr constant i2 -2, align 1
@__zig_error_name_table = private unnamed_addr constant [5 x { ptr, i64 }] [{ ptr, i64 } undef, { ptr, i64 } { ptr @0, i64 11 }, { ptr, i64 } { ptr @1, i64 10 }, { ptr, i64 } { ptr @2, i64 11 }, { ptr, i64 } { ptr @3, i64 13 }], align 8
@__anon_597 = private unnamed_addr constant [16 x i8] c"(msg truncated)\00", align 1
@__anon_706 = private unnamed_addr constant %Io.Writer.VTable { ptr @Io.Writer.fixedDrain, ptr @Io.Writer.unimplementedSendFile, ptr @Io.Writer.noopFlush, ptr @Io.Writer.failingRebase }, align 8
@__anon_720 = private unnamed_addr constant [1 x { ptr, i64 }] [{ ptr, i64 } { ptr @__anon_715, i64 0 }], align 8
@__anon_715 = private unnamed_addr constant [1 x i8] zeroinitializer, align 1
@__anon_728 = private unnamed_addr constant [56 x i8] c"source and destination arguments have non-equal lengths\00", align 1
@builtin.zig_backend = private unnamed_addr constant i64 2, align 8
@mem.use_vectors = private unnamed_addr constant i1 true, align 1
@builtin.fuzz = private unnamed_addr constant i1 false, align 1
@mem.use_vectors_for_comparison = private unnamed_addr constant i1 true, align 1
@builtin.mode = private unnamed_addr constant i2 0, align 1
@debug.runtime_safety = private unnamed_addr constant i1 true, align 1
@builtin.os = private unnamed_addr constant %Target.Os { %Target.Os.VersionRange { %Target.Os.LinuxVersionRange { %SemanticVersion.Range { %SemanticVersion { i64 5, i64 10, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer }, %SemanticVersion { i64 6, i64 19, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer } }, %SemanticVersion { i64 2, i64 31, i64 0, { ptr, i64 } zeroinitializer, { ptr, i64 } zeroinitializer }, i32 29, [4 x i8] undef }, i3 3, [7 x i8] undef }, i6 9, [7 x i8] undef }, align 8
@debug.native_os = private unnamed_addr constant i6 9, align 1
@debug.have_segfault_handling_support = private unnamed_addr constant i1 true, align 1
@debug.default_enable_segfault_handler = private unnamed_addr constant i1 true, align 1
@log.default_level = private unnamed_addr constant i2 -1, align 1
@builtin.strip_debug_info = private unnamed_addr constant i1 true, align 1
@std.options = private unnamed_addr constant %std.Options { { i64, i8, [7 x i8] } { i64 262144, i8 1, [7 x i8] undef }, { ptr, i64 } { ptr inttoptr (i64 1 to ptr), i64 0 }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i64 3, i1 true, i2 -1, i1 false, i1 true, i2 -2, i1 false, i1 true, i1 true }, align 8
@__anon_873 = private unnamed_addr constant [12 x i8] c"start index ", align 1
@__anon_1068 = private unnamed_addr constant %fmt.Options { { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, { i64, i8, [7 x i8] } { i64 undef, i8 0, [7 x i8] undef }, i2 -2, i8 32, [6 x i8] undef }, align 8
@__anon_1359 = private unnamed_addr constant [26 x i8] c" is larger than end index ", align 1
@__anon_1432 = private unnamed_addr constant [27 x i8] c"index out of bounds: index ", align 1
@__anon_1453 = private unnamed_addr constant [6 x i8] c", len ", align 1
@__anon_1545 = private unnamed_addr constant [25 x i8] c"reached unreachable code\00", align 1
@__anon_1551 = private unnamed_addr constant [24 x i8] c"switch on corrupt value\00", align 1
@__anon_1561 = private unnamed_addr constant [17 x i8] c"division by zero\00", align 1
@__anon_1572 = private unnamed_addr constant [201 x i8] c"00010203040506070809101112131415161718192021222324252627282930313233343536373839404142434445464748495051525354555657585960616263646566676869707172737475767778798081828384858687888990919293949596979899\00", align 1
@__anon_1589 = private unnamed_addr constant [41 x i8] c"integer does not fit in destination type\00", align 1
@__anon_1594 = private unnamed_addr constant [17 x i8] c"integer overflow\00", align 1
@__anon_1601 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 4, [6 x i8] undef }, align 8
@__anon_1604 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 0, i16 0, [6 x i8] undef }, align 8
@__anon_1605 = private unnamed_addr constant { i64, i16, [6 x i8] } { i64 undef, i16 1, [6 x i8] undef }, align 8
@__anon_1606 = private unnamed_addr constant [24 x i8] c"@memcpy arguments alias\00", align 1
@__anon_1659 = private unnamed_addr constant [25 x i8] c"attempt to unwrap error: ", align 1
@0 = private unnamed_addr constant [12 x i8] c"WriteFailed\00", align 1
@1 = private unnamed_addr constant [11 x i8] c"ReadFailed\00", align 1
@2 = private unnamed_addr constant [12 x i8] c"EndOfStream\00", align 1
@3 = private unnamed_addr constant [14 x i8] c"Unimplemented\00", align 1

@foo = alias void (), ptr @test.foo

; Function Attrs: nounwind uwtable
define private void @test.foo() unnamed_addr #0 align 1 {
  %1 = call fastcc i16 @test.bar()
  %2 = icmp eq i16 %1, 0
  br i1 %2, label %4, label %5, !prof !0

3:                                                ; preds = %4
  ret void

4:                                                ; preds = %0
  br label %3

5:                                                ; preds = %0
  call fastcc void @"debug.FullPanic((function 'panic')).unwrapError"(i16 %1)
  unreachable
}

; Function Attrs: nounwind uwtable
define private fastcc i16 @test.bar() unnamed_addr #0 align 1 {
  ret i16 0
}

; Function Attrs: cold noreturn nounwind uwtable
define private fastcc void @"debug.FullPanic((function 'panic')).unwrapError"(i16 %0) unnamed_addr #1 align 1 {
  %2 = alloca { { ptr, i64 } }, align 8
  %3 = alloca { i64, i8, [7 x i8] }, align 8
  %4 = call ptr @llvm.returnaddress(i32 0)
  %5 = ptrtoint ptr %4 to i64
  store i64 %5, ptr %3, align 8
  %6 = getelementptr inbounds i8, ptr %3, i64 8
  store i8 1, ptr %6, align 1
  %7 = zext i16 %0 to i64
  %8 = getelementptr inbounds [16 x i8], ptr @__zig_error_name_table, i64 %7
  %9 = load { ptr, i64 }, ptr %8, align 8
  store { ptr, i64 } %9, ptr %2, align 8
  call fastcc void @debug.panicExtra__anon_594(ptr nonnull readonly align 8 %3, ptr nonnull readonly align 8 %2)
  unreachable
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare ptr @llvm.returnaddress(i32 immarg) #2

; Function Attrs: cold noreturn nounwind uwtable
define private fastcc void @debug.panicExtra__anon_594(ptr nonnull readonly align 8 %0, ptr nonnull readonly align 8 %1) unnamed_addr #1 align 1 {
  %3 = alloca { ptr, i64 }, align 8
  %4 = alloca %Io.Writer, align 8
  %5 = alloca %Io.Writer, align 8
  %6 = alloca [4111 x i8], align 1
  call void @llvm.memset.p0.i64(ptr align 1 %6, i8 -86, i64 4111, i1 false)
  %7 = getelementptr inbounds [1 x i8], ptr %6, i64 0
  %8 = insertvalue { ptr, i64 } poison, ptr %7, 0
  %9 = insertvalue { ptr, i64 } %8, i64 4096, 1
  %10 = extractvalue { ptr, i64 } %9, 0
  %11 = extractvalue { ptr, i64 } %9, 1
  call fastcc void @Io.Writer.fixed(ptr sret(%Io.Writer) %4, ptr nonnull %10, i64 %11)
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %5, ptr align 8 %4, i64 32, i1 false)
  %12 = call fastcc i16 @Io.Writer.print__anon_634(ptr nonnull align 8 %5, ptr nonnull readonly align 8 %1)
  %13 = icmp eq i16 %12, 0
  br i1 %13, label %19, label %21

14:                                               ; preds = %27, %19
  %15 = phi { ptr, i64 } [ %20, %19 ], [ %29, %27 ]
  store { ptr, i64 } %15, ptr %3, align 8
  %16 = load { ptr, i64 }, ptr %3, align 8
  %17 = extractvalue { ptr, i64 } %16, 0
  %18 = extractvalue { ptr, i64 } %16, 1
  call fastcc void @lang.panic__struct_212.panic(ptr nonnull readonly %17, i64 %18, ptr nonnull readonly align 8 %0)
  unreachable

19:                                               ; preds = %2
  %20 = call fastcc { ptr, i64 } @Io.Writer.buffered(ptr nonnull readonly align 8 %5)
  br label %14

21:                                               ; preds = %2
  %22 = getelementptr inbounds [1 x i8], ptr %6, i64 4096
  %23 = getelementptr inbounds [1 x i8], ptr %22, i64 15
  %24 = icmp uge ptr %22, getelementptr inbounds (i8, ptr @__anon_597, i64 15)
  %25 = icmp uge ptr @__anon_597, %23
  %26 = or i1 %24, %25
  br i1 %26, label %30, label %31

27:                                               ; preds = %30
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %22, ptr align 1 @__anon_597, i64 15, i1 false)
  %28 = insertvalue { ptr, i64 } poison, ptr %6, 0
  %29 = insertvalue { ptr, i64 } %28, i64 4111, 1
  br label %14

30:                                               ; preds = %21
  br label %27

31:                                               ; preds = %21
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).memcpyAlias"()
  unreachable
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #3

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #4

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #5

; Function Attrs: nounwind uwtable
define private fastcc void @Io.Writer.fixed(ptr noalias nonnull sret(%Io.Writer) %0, ptr nonnull %1, i64 %2) unnamed_addr #0 align 1 {
  %4 = insertvalue { ptr, i64 } poison, ptr %1, 0
  %5 = insertvalue { ptr, i64 } %4, i64 %2, 1
  store ptr @__anon_706, ptr %0, align 8
  %6 = getelementptr inbounds i8, ptr %0, i64 8
  store { ptr, i64 } %5, ptr %6, align 8
  %7 = getelementptr inbounds i8, ptr %0, i64 24
  store i64 0, ptr %7, align 8
  ret void
}

; Function Attrs: noreturn nounwind uwtable
define private fastcc void @lang.panic__struct_212.panic(ptr nonnull readonly %0, i64 %1, ptr nonnull readonly align 8 %2) unnamed_addr #6 align 1 {
  %4 = insertvalue { ptr, i64 } poison, ptr %0, 0
  %5 = insertvalue { ptr, i64 } %4, i64 %1, 1
  %6 = extractvalue { ptr, i64 } %5, 0
  %7 = extractvalue { ptr, i64 } %5, 1
  call fastcc void @test.panic(ptr nonnull readonly %6, i64 %7, ptr align 8 null, ptr nonnull readonly align 8 %2)
  unreachable
}

; Function Attrs: nounwind uwtable
define private fastcc i16 @Io.Writer.defaultRebase(ptr nonnull align 8 %0, i64 %1, i64 %2) unnamed_addr #0 align 1 {
  %4 = alloca { i64, i16, [6 x i8] }, align 8
  %5 = alloca ptr, align 8
  store ptr %0, ptr %5, align 8
  br label %7

6:                                                ; preds = %32
  ret i16 0

7:                                                ; preds = %17, %3
  %8 = load ptr, ptr %5, align 8
  %9 = getelementptr inbounds i8, ptr %8, i64 8
  %10 = getelementptr inbounds i8, ptr %9, i64 8
  %11 = load i64, ptr %10, align 8
  %12 = load ptr, ptr %5, align 8
  %13 = getelementptr inbounds i8, ptr %12, i64 24
  %14 = load i64, ptr %13, align 8
  %15 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %11, i64 %14)
  %16 = extractvalue { i64, i1 } %15, 1
  br i1 %16, label %18, label %19

17:                                               ; preds = %126
  br label %7

18:                                               ; preds = %7
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

19:                                               ; preds = %7
  %20 = extractvalue { i64, i1 } %15, 0
  %21 = icmp ult i64 %20, %2
  br i1 %21, label %22, label %32

22:                                               ; preds = %19
  %23 = load ptr, ptr %5, align 8
  %24 = getelementptr inbounds i8, ptr %23, i64 24
  %25 = load i64, ptr %24, align 8
  %26 = call i64 @llvm.usub.sat.i64(i64 %25, i64 %1)
  %27 = load ptr, ptr %5, align 8
  %28 = getelementptr inbounds i8, ptr %27, i64 24
  %29 = load i64, ptr %28, align 8
  %30 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %29, i64 %26)
  %31 = extractvalue { i64, i1 } %30, 1
  br i1 %31, label %33, label %34

32:                                               ; preds = %19
  br label %6

33:                                               ; preds = %22
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

34:                                               ; preds = %22
  %35 = extractvalue { i64, i1 } %30, 0
  %36 = load ptr, ptr %5, align 8
  %37 = getelementptr inbounds i8, ptr %36, i64 24
  store i64 %26, ptr %37, align 8
  %38 = load ptr, ptr %5, align 8
  %39 = load ptr, ptr %38, align 8
  %40 = load ptr, ptr %39, align 8
  %41 = extractvalue { ptr, i64 } { ptr @__anon_720, i64 1 }, 0
  %42 = extractvalue { ptr, i64 } { ptr @__anon_720, i64 1 }, 1
  call fastcc void %40(ptr sret({ i64, i16, [6 x i8] }) %4, ptr nonnull align 8 %0, ptr nonnull readonly align 8 %41, i64 %42, i64 1)
  %43 = getelementptr inbounds i8, ptr %4, i64 8
  %44 = load i16, ptr %43, align 2
  %45 = icmp ne i16 %44, 0
  br i1 %45, label %46, label %54, !prof !1

46:                                               ; preds = %34
  %47 = getelementptr inbounds i8, ptr %4, i64 8
  %48 = load i16, ptr %47, align 2
  %49 = load ptr, ptr %5, align 8
  %50 = getelementptr inbounds i8, ptr %49, i64 24
  %51 = load i64, ptr %50, align 8
  %52 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %51, i64 %35)
  %53 = extractvalue { i64, i1 } %52, 1
  br i1 %53, label %62, label %63

54:                                               ; preds = %34
  %55 = load i64, ptr %4, align 8
  %56 = icmp eq i64 0, %55
  call fastcc void @debug.assert(i1 %56)
  %57 = load ptr, ptr %5, align 8
  %58 = getelementptr inbounds i8, ptr %57, i64 24
  %59 = load i64, ptr %58, align 8
  %60 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %26, i64 %35)
  %61 = extractvalue { i64, i1 } %60, 1
  br i1 %61, label %65, label %66

62:                                               ; preds = %46
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

63:                                               ; preds = %46
  %64 = extractvalue { i64, i1 } %52, 0
  store i64 %64, ptr %50, align 8
  ret i16 %48

65:                                               ; preds = %54
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

66:                                               ; preds = %54
  %67 = extractvalue { i64, i1 } %60, 0
  %68 = icmp ule i64 %59, %67
  call fastcc void @debug.assert(i1 %68)
  %69 = load ptr, ptr %5, align 8
  %70 = getelementptr inbounds i8, ptr %69, i64 8
  %71 = load ptr, ptr %5, align 8
  %72 = getelementptr inbounds i8, ptr %71, i64 24
  %73 = load i64, ptr %72, align 8
  %74 = load { ptr, i64 }, ptr %70, align 8
  %75 = extractvalue { ptr, i64 } %74, 0
  %76 = getelementptr inbounds [1 x i8], ptr %75, i64 %73
  %77 = add nuw i64 %73, %35
  %78 = extractvalue { ptr, i64 } %74, 1
  %79 = icmp ule i64 %77, %78
  br i1 %79, label %89, label %90

80:                                               ; preds = %89
  %81 = insertvalue { ptr, i64 } poison, ptr %76, 0
  %82 = insertvalue { ptr, i64 } %81, i64 %35, 1
  %83 = load ptr, ptr %5, align 8
  %84 = getelementptr inbounds i8, ptr %83, i64 8
  %85 = load { ptr, i64 }, ptr %84, align 8
  %86 = extractvalue { ptr, i64 } %85, 0
  %87 = getelementptr inbounds [1 x i8], ptr %86, i64 %26
  %88 = icmp ule i64 %26, %29
  br i1 %88, label %95, label %96

89:                                               ; preds = %66
  br label %80

90:                                               ; preds = %66
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %77, i64 %78)
  unreachable

91:                                               ; preds = %95
  %92 = sub nuw i64 %29, %26
  %93 = extractvalue { ptr, i64 } %85, 1
  %94 = icmp ule i64 %29, %93
  br i1 %94, label %103, label %104

95:                                               ; preds = %80
  br label %91

96:                                               ; preds = %80
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).startGreaterThanEnd"(i64 %26, i64 %29)
  unreachable

97:                                               ; preds = %103
  %98 = insertvalue { ptr, i64 } poison, ptr %87, 0
  %99 = insertvalue { ptr, i64 } %98, i64 %92, 1
  %100 = extractvalue { ptr, i64 } %82, 1
  %101 = extractvalue { ptr, i64 } %99, 1
  %102 = icmp eq i64 %100, %101
  br i1 %102, label %114, label %115

103:                                              ; preds = %91
  br label %97

104:                                              ; preds = %91
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %29, i64 %93)
  unreachable

105:                                              ; preds = %114
  %106 = extractvalue { ptr, i64 } %99, 0
  %107 = extractvalue { ptr, i64 } %82, 1
  %108 = extractvalue { ptr, i64 } %82, 0
  call void @llvm.memmove.p0.p0.i64(ptr align 1 %108, ptr align 1 %106, i64 %107, i1 false)
  %109 = load ptr, ptr %5, align 8
  %110 = getelementptr inbounds i8, ptr %109, i64 24
  %111 = load i64, ptr %110, align 8
  %112 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %111, i64 %35)
  %113 = extractvalue { i64, i1 } %112, 1
  br i1 %113, label %116, label %117

114:                                              ; preds = %97
  br label %105

115:                                              ; preds = %97
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).copyLenMismatch"()
  unreachable

116:                                              ; preds = %105
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

117:                                              ; preds = %105
  %118 = extractvalue { i64, i1 } %112, 0
  store i64 %118, ptr %110, align 8
  %119 = load ptr, ptr %5, align 8
  %120 = getelementptr inbounds i8, ptr %119, i64 8
  %121 = getelementptr inbounds i8, ptr %120, i64 8
  %122 = load i64, ptr %121, align 8
  %123 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %122, i64 %1)
  %124 = extractvalue { i64, i1 } %123, 1
  br i1 %124, label %125, label %126

125:                                              ; preds = %117
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

126:                                              ; preds = %117
  %127 = extractvalue { i64, i1 } %123, 0
  %128 = icmp uge i64 %127, %2
  call fastcc void @debug.assert(i1 %128)
  br label %17
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.usub.with.overflow.i64(i64, i64) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.usub.sat.i64(i64, i64) #7

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.uadd.with.overflow.i64(i64, i64) #7

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memmove.p0.p0.i64(ptr writeonly captures(none), ptr readonly captures(none), i64, i1 immarg) #4

; Function Attrs: noreturn nounwind uwtable
define private fastcc void @test.panic(ptr nonnull readonly %0, i64 %1, ptr align 8 %2, ptr nonnull readonly align 8 %3) unnamed_addr #6 align 1 {
  %5 = insertvalue { ptr, i64 } poison, ptr %0, 0
  %6 = insertvalue { ptr, i64 } %5, i64 %1, 1
  call void @llvm.debugtrap()
  br label %7

7:                                                ; preds = %7, %4
  br label %7
}

; Function Attrs: nounwind
declare void @llvm.debugtrap() #8

; Function Attrs: cold noreturn nounwind uwtable
define private fastcc void @"debug.FullPanic((function 'panic')).copyLenMismatch"() unnamed_addr #1 align 1 {
  %1 = alloca { i64, i8, [7 x i8] }, align 8
  %2 = call ptr @llvm.returnaddress(i32 0)
  %3 = ptrtoint ptr %2 to i64
  store i64 %3, ptr %1, align 8
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  store i8 1, ptr %4, align 1
  %5 = extractvalue { ptr, i64 } { ptr @__anon_728, i64 55 }, 0
  %6 = extractvalue { ptr, i64 } { ptr @__anon_728, i64 55 }, 1
  call fastcc void @lang.panic__struct_212.panic(ptr nonnull readonly %5, i64 %6, ptr nonnull readonly align 8 %1)
  unreachable
}

; Function Attrs: cold noreturn nounwind uwtable
define private fastcc void @"debug.FullPanic((function 'panic')).startGreaterThanEnd"(i64 %0, i64 %1) unnamed_addr #1 align 1 {
  %3 = alloca { i64, i64 }, align 8
  %4 = alloca { i64, i8, [7 x i8] }, align 8
  %5 = call ptr @llvm.returnaddress(i32 0)
  %6 = ptrtoint ptr %5 to i64
  store i64 %6, ptr %4, align 8
  %7 = getelementptr inbounds i8, ptr %4, i64 8
  store i8 1, ptr %7, align 1
  store i64 %0, ptr %3, align 8
  %8 = getelementptr inbounds i8, ptr %3, i64 8
  store i64 %1, ptr %8, align 8
  call fastcc void @debug.panicExtra__anon_743(ptr nonnull readonly align 8 %4, ptr nonnull readonly align 8 %3)
  unreachable
}

; Function Attrs: cold noreturn nounwind uwtable
define private fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %0, i64 %1) unnamed_addr #1 align 1 {
  %3 = alloca { i64, i64 }, align 8
  %4 = alloca { i64, i8, [7 x i8] }, align 8
  %5 = call ptr @llvm.returnaddress(i32 0)
  %6 = ptrtoint ptr %5 to i64
  store i64 %6, ptr %4, align 8
  %7 = getelementptr inbounds i8, ptr %4, i64 8
  store i8 1, ptr %7, align 1
  store i64 %0, ptr %3, align 8
  %8 = getelementptr inbounds i8, ptr %3, i64 8
  store i64 %1, ptr %8, align 8
  call fastcc void @debug.panicExtra__anon_751(ptr nonnull readonly align 8 %4, ptr nonnull readonly align 8 %3)
  unreachable
}

; Function Attrs: cold noreturn nounwind uwtable
define private fastcc void @debug.panicExtra__anon_743(ptr nonnull readonly align 8 %0, ptr nonnull readonly align 8 %1) unnamed_addr #1 align 1 {
  %3 = alloca { ptr, i64 }, align 8
  %4 = alloca %Io.Writer, align 8
  %5 = alloca %Io.Writer, align 8
  %6 = alloca [4111 x i8], align 1
  call void @llvm.memset.p0.i64(ptr align 1 %6, i8 -86, i64 4111, i1 false)
  %7 = getelementptr inbounds [1 x i8], ptr %6, i64 0
  %8 = insertvalue { ptr, i64 } poison, ptr %7, 0
  %9 = insertvalue { ptr, i64 } %8, i64 4096, 1
  %10 = extractvalue { ptr, i64 } %9, 0
  %11 = extractvalue { ptr, i64 } %9, 1
  call fastcc void @Io.Writer.fixed(ptr sret(%Io.Writer) %4, ptr nonnull %10, i64 %11)
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %5, ptr align 8 %4, i64 32, i1 false)
  %12 = call fastcc i16 @Io.Writer.print__anon_753(ptr nonnull align 8 %5, ptr nonnull readonly align 8 %1)
  %13 = icmp eq i16 %12, 0
  br i1 %13, label %19, label %21

14:                                               ; preds = %27, %19
  %15 = phi { ptr, i64 } [ %20, %19 ], [ %29, %27 ]
  store { ptr, i64 } %15, ptr %3, align 8
  %16 = load { ptr, i64 }, ptr %3, align 8
  %17 = extractvalue { ptr, i64 } %16, 0
  %18 = extractvalue { ptr, i64 } %16, 1
  call fastcc void @lang.panic__struct_212.panic(ptr nonnull readonly %17, i64 %18, ptr nonnull readonly align 8 %0)
  unreachable

19:                                               ; preds = %2
  %20 = call fastcc { ptr, i64 } @Io.Writer.buffered(ptr nonnull readonly align 8 %5)
  br label %14

21:                                               ; preds = %2
  %22 = getelementptr inbounds [1 x i8], ptr %6, i64 4096
  %23 = getelementptr inbounds [1 x i8], ptr %22, i64 15
  %24 = icmp uge ptr %22, getelementptr inbounds (i8, ptr @__anon_597, i64 15)
  %25 = icmp uge ptr @__anon_597, %23
  %26 = or i1 %24, %25
  br i1 %26, label %30, label %31

27:                                               ; preds = %30
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %22, ptr align 1 @__anon_597, i64 15, i1 false)
  %28 = insertvalue { ptr, i64 } poison, ptr %6, 0
  %29 = insertvalue { ptr, i64 } %28, i64 4111, 1
  br label %14

30:                                               ; preds = %21
  br label %27

31:                                               ; preds = %21
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).memcpyAlias"()
  unreachable
}

; Function Attrs: cold noreturn nounwind uwtable
define private fastcc void @debug.panicExtra__anon_751(ptr nonnull readonly align 8 %0, ptr nonnull readonly align 8 %1) unnamed_addr #1 align 1 {
  %3 = alloca { ptr, i64 }, align 8
  %4 = alloca %Io.Writer, align 8
  %5 = alloca %Io.Writer, align 8
  %6 = alloca [4111 x i8], align 1
  call void @llvm.memset.p0.i64(ptr align 1 %6, i8 -86, i64 4111, i1 false)
  %7 = getelementptr inbounds [1 x i8], ptr %6, i64 0
  %8 = insertvalue { ptr, i64 } poison, ptr %7, 0
  %9 = insertvalue { ptr, i64 } %8, i64 4096, 1
  %10 = extractvalue { ptr, i64 } %9, 0
  %11 = extractvalue { ptr, i64 } %9, 1
  call fastcc void @Io.Writer.fixed(ptr sret(%Io.Writer) %4, ptr nonnull %10, i64 %11)
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %5, ptr align 8 %4, i64 32, i1 false)
  %12 = call fastcc i16 @Io.Writer.print__anon_754(ptr nonnull align 8 %5, ptr nonnull readonly align 8 %1)
  %13 = icmp eq i16 %12, 0
  br i1 %13, label %19, label %21

14:                                               ; preds = %27, %19
  %15 = phi { ptr, i64 } [ %20, %19 ], [ %29, %27 ]
  store { ptr, i64 } %15, ptr %3, align 8
  %16 = load { ptr, i64 }, ptr %3, align 8
  %17 = extractvalue { ptr, i64 } %16, 0
  %18 = extractvalue { ptr, i64 } %16, 1
  call fastcc void @lang.panic__struct_212.panic(ptr nonnull readonly %17, i64 %18, ptr nonnull readonly align 8 %0)
  unreachable

19:                                               ; preds = %2
  %20 = call fastcc { ptr, i64 } @Io.Writer.buffered(ptr nonnull readonly align 8 %5)
  br label %14

21:                                               ; preds = %2
  %22 = getelementptr inbounds [1 x i8], ptr %6, i64 4096
  %23 = getelementptr inbounds [1 x i8], ptr %22, i64 15
  %24 = icmp uge ptr %22, getelementptr inbounds (i8, ptr @__anon_597, i64 15)
  %25 = icmp uge ptr @__anon_597, %23
  %26 = or i1 %24, %25
  br i1 %26, label %30, label %31

27:                                               ; preds = %30
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %22, ptr align 1 @__anon_597, i64 15, i1 false)
  %28 = insertvalue { ptr, i64 } poison, ptr %6, 0
  %29 = insertvalue { ptr, i64 } %28, i64 4111, 1
  br label %14

30:                                               ; preds = %21
  br label %27

31:                                               ; preds = %21
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).memcpyAlias"()
  unreachable
}

; Function Attrs: nounwind uwtable
define private fastcc i16 @Io.Writer.print__anon_753(ptr nonnull align 8 %0, ptr nonnull readonly align 8 %1) unnamed_addr #0 align 1 {
  %3 = alloca { i64, i64 }, align 8
  %4 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %3, ptr align 8 %1, i64 16, i1 false)
  %5 = load ptr, ptr %4, align 8
  %6 = extractvalue { ptr, i64 } { ptr @__anon_873, i64 12 }, 0
  %7 = extractvalue { ptr, i64 } { ptr @__anon_873, i64 12 }, 1
  %8 = call fastcc i16 @Io.Writer.writeAll(ptr nonnull align 8 %5, ptr nonnull readonly %6, i64 %7)
  %9 = icmp ne i16 %8, 0
  br i1 %9, label %10, label %11, !prof !1

10:                                               ; preds = %2
  ret i16 %8

11:                                               ; preds = %2
  %12 = load ptr, ptr %4, align 8
  %13 = load i64, ptr %3, align 8
  %14 = call fastcc i16 @Io.Writer.printValue__anon_1277(ptr nonnull align 8 %12, ptr nonnull readonly align 8 @__anon_1068, i64 %13, i64 3)
  %15 = icmp ne i16 %14, 0
  br i1 %15, label %16, label %17, !prof !1

16:                                               ; preds = %11
  ret i16 %14

17:                                               ; preds = %11
  %18 = load ptr, ptr %4, align 8
  %19 = extractvalue { ptr, i64 } { ptr @__anon_1359, i64 26 }, 0
  %20 = extractvalue { ptr, i64 } { ptr @__anon_1359, i64 26 }, 1
  %21 = call fastcc i16 @Io.Writer.writeAll(ptr nonnull align 8 %18, ptr nonnull readonly %19, i64 %20)
  %22 = icmp ne i16 %21, 0
  br i1 %22, label %23, label %24, !prof !1

23:                                               ; preds = %17
  ret i16 %21

24:                                               ; preds = %17
  %25 = load ptr, ptr %4, align 8
  %26 = getelementptr inbounds i8, ptr %3, i64 8
  %27 = load i64, ptr %26, align 8
  %28 = call fastcc i16 @Io.Writer.printValue__anon_1277(ptr nonnull align 8 %25, ptr nonnull readonly align 8 @__anon_1068, i64 %27, i64 3)
  %29 = icmp ne i16 %28, 0
  br i1 %29, label %30, label %31, !prof !1

30:                                               ; preds = %24
  ret i16 %28

31:                                               ; preds = %24
  ret i16 0
}

; Function Attrs: nounwind uwtable
define private fastcc i16 @Io.Writer.print__anon_754(ptr nonnull align 8 %0, ptr nonnull readonly align 8 %1) unnamed_addr #0 align 1 {
  %3 = alloca { i64, i64 }, align 8
  %4 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %3, ptr align 8 %1, i64 16, i1 false)
  %5 = load ptr, ptr %4, align 8
  %6 = extractvalue { ptr, i64 } { ptr @__anon_1432, i64 27 }, 0
  %7 = extractvalue { ptr, i64 } { ptr @__anon_1432, i64 27 }, 1
  %8 = call fastcc i16 @Io.Writer.writeAll(ptr nonnull align 8 %5, ptr nonnull readonly %6, i64 %7)
  %9 = icmp ne i16 %8, 0
  br i1 %9, label %10, label %11, !prof !1

10:                                               ; preds = %2
  ret i16 %8

11:                                               ; preds = %2
  %12 = load ptr, ptr %4, align 8
  %13 = load i64, ptr %3, align 8
  %14 = call fastcc i16 @Io.Writer.printValue__anon_1277(ptr nonnull align 8 %12, ptr nonnull readonly align 8 @__anon_1068, i64 %13, i64 3)
  %15 = icmp ne i16 %14, 0
  br i1 %15, label %16, label %17, !prof !1

16:                                               ; preds = %11
  ret i16 %14

17:                                               ; preds = %11
  %18 = load ptr, ptr %4, align 8
  %19 = extractvalue { ptr, i64 } { ptr @__anon_1453, i64 6 }, 0
  %20 = extractvalue { ptr, i64 } { ptr @__anon_1453, i64 6 }, 1
  %21 = call fastcc i16 @Io.Writer.writeAll(ptr nonnull align 8 %18, ptr nonnull readonly %19, i64 %20)
  %22 = icmp ne i16 %21, 0
  br i1 %22, label %23, label %24, !prof !1

23:                                               ; preds = %17
  ret i16 %21

24:                                               ; preds = %17
  %25 = load ptr, ptr %4, align 8
  %26 = getelementptr inbounds i8, ptr %3, i64 8
  %27 = load i64, ptr %26, align 8
  %28 = call fastcc i16 @Io.Writer.printValue__anon_1277(ptr nonnull align 8 %25, ptr nonnull readonly align 8 @__anon_1068, i64 %27, i64 3)
  %29 = icmp ne i16 %28, 0
  br i1 %29, label %30, label %31, !prof !1

30:                                               ; preds = %24
  ret i16 %28

31:                                               ; preds = %24
  ret i16 0
}

; Function Attrs: nounwind uwtable
define private fastcc i16 @Io.Writer.printValue__anon_1277(ptr nonnull align 8 %0, ptr nonnull readonly align 8 %1, i64 %2, i64 %3) unnamed_addr #0 align 1 {
  %5 = alloca i64, align 8
  %6 = alloca %fmt.Options, align 8
  %7 = alloca ptr, align 8
  store ptr %0, ptr %7, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %6, ptr align 8 %1, i64 40, i1 false)
  store i64 %2, ptr %5, align 8
  %8 = call fastcc i16 @Io.Writer.printIntAny__anon_1497(ptr nonnull align 8 %0, i64 %2, i8 10, i1 false, ptr nonnull readonly align 8 %1)
  ret i16 %8
}

; Function Attrs: nounwind uwtable
define private fastcc i16 @Io.Writer.writeAll(ptr nonnull align 8 %0, ptr nonnull readonly %1, i64 %2) unnamed_addr #0 align 1 {
  %4 = alloca { i64, i16, [6 x i8] }, align 8
  %5 = alloca i64, align 8
  %6 = alloca { ptr, i64 }, align 8
  %7 = alloca ptr, align 8
  %8 = insertvalue { ptr, i64 } poison, ptr %1, 0
  %9 = insertvalue { ptr, i64 } %8, i64 %2, 1
  store ptr %0, ptr %7, align 8
  store { ptr, i64 } %9, ptr %6, align 8
  store i64 0, ptr %5, align 8
  br label %11

10:                                               ; preds = %26
  ret i16 0

11:                                               ; preds = %16, %3
  %12 = load i64, ptr %5, align 8
  %13 = getelementptr inbounds i8, ptr %6, i64 8
  %14 = load i64, ptr %13, align 8
  %15 = icmp ult i64 %12, %14
  br i1 %15, label %17, label %26

16:                                               ; preds = %51
  br label %11

17:                                               ; preds = %11
  %18 = load i64, ptr %5, align 8
  %19 = load ptr, ptr %7, align 8
  %20 = load i64, ptr %5, align 8
  %21 = load { ptr, i64 }, ptr %6, align 8
  %22 = extractvalue { ptr, i64 } %21, 0
  %23 = getelementptr inbounds [1 x i8], ptr %22, i64 %20
  %24 = extractvalue { ptr, i64 } %21, 1
  %25 = icmp ule i64 %20, %24
  br i1 %25, label %31, label %32

26:                                               ; preds = %11
  br label %10

27:                                               ; preds = %31
  %28 = sub nuw i64 %24, %20
  %29 = extractvalue { ptr, i64 } %21, 1
  %30 = icmp ule i64 %24, %29
  br i1 %30, label %41, label %42

31:                                               ; preds = %17
  br label %27

32:                                               ; preds = %17
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).startGreaterThanEnd"(i64 %20, i64 %24)
  unreachable

33:                                               ; preds = %41
  %34 = insertvalue { ptr, i64 } poison, ptr %23, 0
  %35 = insertvalue { ptr, i64 } %34, i64 %28, 1
  %36 = extractvalue { ptr, i64 } %35, 0
  %37 = extractvalue { ptr, i64 } %35, 1
  call fastcc void @Io.Writer.write(ptr sret({ i64, i16, [6 x i8] }) %4, ptr nonnull align 8 %19, ptr nonnull readonly %36, i64 %37)
  %38 = getelementptr inbounds i8, ptr %4, i64 8
  %39 = load i16, ptr %38, align 2
  %40 = icmp ne i16 %39, 0
  br i1 %40, label %43, label %46, !prof !1

41:                                               ; preds = %27
  br label %33

42:                                               ; preds = %27
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %24, i64 %29)
  unreachable

43:                                               ; preds = %33
  %44 = getelementptr inbounds i8, ptr %4, i64 8
  %45 = load i16, ptr %44, align 2
  ret i16 %45

46:                                               ; preds = %33
  %47 = load i64, ptr %4, align 8
  %48 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %18, i64 %47)
  %49 = extractvalue { i64, i1 } %48, 1
  br i1 %49, label %50, label %51

50:                                               ; preds = %46
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

51:                                               ; preds = %46
  %52 = extractvalue { i64, i1 } %48, 0
  store i64 %52, ptr %5, align 8
  br label %16
}

; Function Attrs: nounwind uwtable
define private fastcc i16 @Io.Writer.printIntAny__anon_1497(ptr nonnull align 8 %0, i64 %1, i8 %2, i1 %3, ptr nonnull readonly align 8 %4) unnamed_addr #0 align 1 {
  %6 = alloca { ptr, i64 }, align 8
  %7 = alloca [2 x i8], align 1
  %8 = alloca [2 x i8], align 1
  %9 = alloca i64, align 8
  %10 = alloca i64, align 8
  %11 = alloca [65 x i8], align 1
  %12 = alloca %fmt.Options, align 8
  %13 = alloca ptr, align 8
  store ptr %0, ptr %13, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %12, ptr align 8 %4, i64 40, i1 false)
  %14 = icmp uge i8 %2, 2
  call fastcc void @debug.assert(i1 %14)
  call void @llvm.memset.p0.i64(ptr align 1 %11, i8 -86, i64 65, i1 false)
  store i64 %1, ptr %10, align 8
  store i64 65, ptr %9, align 8
  %15 = icmp eq i8 %2, 10
  br i1 %15, label %21, label %22

16:                                               ; preds = %96, %53
  %17 = load ptr, ptr %13, align 8
  %18 = load i64, ptr %9, align 8
  %19 = getelementptr inbounds [1 x i8], ptr %11, i64 %18
  %20 = icmp ule i64 %18, 65
  br i1 %20, label %137, label %138

21:                                               ; preds = %5
  br label %26

22:                                               ; preds = %5
  br label %97

23:                                               ; preds = %34
  %24 = load i64, ptr %10, align 8
  %25 = icmp ult i64 %24, 10
  br i1 %25, label %54, label %58

26:                                               ; preds = %29, %21
  %27 = load i64, ptr %10, align 8
  %28 = icmp uge i64 %27, 100
  br i1 %28, label %30, label %34

29:                                               ; preds = %49
  br label %26

30:                                               ; preds = %26
  %31 = load i64, ptr %9, align 8
  %32 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %31, i64 2)
  %33 = extractvalue { i64, i1 } %32, 1
  br i1 %33, label %35, label %36

34:                                               ; preds = %26
  br label %23

35:                                               ; preds = %30
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

36:                                               ; preds = %30
  %37 = extractvalue { i64, i1 } %32, 0
  store i64 %37, ptr %9, align 8
  %38 = load i64, ptr %9, align 8
  %39 = getelementptr inbounds [1 x i8], ptr %11, i64 %38
  %40 = add nuw i64 %38, 2
  %41 = icmp ule i64 %40, 65
  br i1 %41, label %46, label %47

42:                                               ; preds = %46
  %43 = load i64, ptr %10, align 8
  %44 = urem i64 %43, 100
  %45 = icmp ule i64 %44, 255
  br i1 %45, label %49, label %48

46:                                               ; preds = %36
  br label %42

47:                                               ; preds = %36
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %40, i64 65)
  unreachable

48:                                               ; preds = %42
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOutOfBounds"()
  unreachable

49:                                               ; preds = %42
  %50 = trunc i64 %44 to i8
  call fastcc void @fmt.digits2(ptr sret([2 x i8]) %8, i8 %50)
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %39, ptr align 1 %8, i64 2, i1 false)
  %51 = load i64, ptr %10, align 8
  %52 = udiv i64 %51, 100
  store i64 %52, ptr %10, align 8
  br label %29

53:                                               ; preds = %94, %79
  br label %16

54:                                               ; preds = %23
  %55 = load i64, ptr %9, align 8
  %56 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %55, i64 1)
  %57 = extractvalue { i64, i1 } %56, 1
  br i1 %57, label %62, label %63

58:                                               ; preds = %23
  %59 = load i64, ptr %9, align 8
  %60 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %59, i64 2)
  %61 = extractvalue { i64, i1 } %60, 1
  br i1 %61, label %81, label %82

62:                                               ; preds = %54
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

63:                                               ; preds = %54
  %64 = extractvalue { i64, i1 } %56, 0
  store i64 %64, ptr %9, align 8
  %65 = load i64, ptr %9, align 8
  %66 = icmp ult i64 %65, 65
  br i1 %66, label %71, label %72

67:                                               ; preds = %71
  %68 = getelementptr inbounds [1 x i8], ptr %11, i64 %65
  %69 = load i64, ptr %10, align 8
  %70 = icmp ule i64 %69, 255
  br i1 %70, label %74, label %73

71:                                               ; preds = %63
  br label %67

72:                                               ; preds = %63
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %65, i64 65)
  unreachable

73:                                               ; preds = %67
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOutOfBounds"()
  unreachable

74:                                               ; preds = %67
  %75 = trunc i64 %69 to i8
  %76 = call { i8, i1 } @llvm.uadd.with.overflow.i8(i8 48, i8 %75)
  %77 = extractvalue { i8, i1 } %76, 1
  br i1 %77, label %78, label %79

78:                                               ; preds = %74
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

79:                                               ; preds = %74
  %80 = extractvalue { i8, i1 } %76, 0
  store i8 %80, ptr %68, align 1
  br label %53

81:                                               ; preds = %58
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

82:                                               ; preds = %58
  %83 = extractvalue { i64, i1 } %60, 0
  store i64 %83, ptr %9, align 8
  %84 = load i64, ptr %9, align 8
  %85 = getelementptr inbounds [1 x i8], ptr %11, i64 %84
  %86 = add nuw i64 %84, 2
  %87 = icmp ule i64 %86, 65
  br i1 %87, label %91, label %92

88:                                               ; preds = %91
  %89 = load i64, ptr %10, align 8
  %90 = icmp ule i64 %89, 255
  br i1 %90, label %94, label %93

91:                                               ; preds = %82
  br label %88

92:                                               ; preds = %82
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %86, i64 65)
  unreachable

93:                                               ; preds = %88
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOutOfBounds"()
  unreachable

94:                                               ; preds = %88
  %95 = trunc i64 %89 to i8
  call fastcc void @fmt.digits2(ptr sret([2 x i8]) %7, i8 %95)
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %85, ptr align 1 %7, i64 2, i1 false)
  br label %53

96:                                               ; preds = %132
  br label %16

97:                                               ; preds = %131, %22
  %98 = load i64, ptr %10, align 8
  %99 = zext i8 %2 to i64
  %100 = icmp ne i64 %99, 0
  br i1 %100, label %106, label %107

101:                                              ; preds = %106
  %102 = urem i64 %98, %99
  %103 = load i64, ptr %9, align 8
  %104 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %103, i64 1)
  %105 = extractvalue { i64, i1 } %104, 1
  br i1 %105, label %108, label %109

106:                                              ; preds = %97
  br label %101

107:                                              ; preds = %97
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).divideByZero"()
  unreachable

108:                                              ; preds = %101
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

109:                                              ; preds = %101
  %110 = extractvalue { i64, i1 } %104, 0
  store i64 %110, ptr %9, align 8
  %111 = load i64, ptr %9, align 8
  %112 = icmp ult i64 %111, 65
  br i1 %112, label %116, label %117

113:                                              ; preds = %116
  %114 = getelementptr inbounds [1 x i8], ptr %11, i64 %111
  %115 = icmp ule i64 %102, 255
  br i1 %115, label %119, label %118

116:                                              ; preds = %109
  br label %113

117:                                              ; preds = %109
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %111, i64 65)
  unreachable

118:                                              ; preds = %113
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOutOfBounds"()
  unreachable

119:                                              ; preds = %113
  %120 = trunc i64 %102 to i8
  %121 = call fastcc i8 @fmt.digitToChar(i8 %120, i1 %3)
  store i8 %121, ptr %114, align 1
  %122 = load i64, ptr %10, align 8
  %123 = zext i8 %2 to i64
  %124 = icmp ne i64 %123, 0
  br i1 %124, label %129, label %130

125:                                              ; preds = %129
  %126 = udiv i64 %122, %123
  store i64 %126, ptr %10, align 8
  %127 = load i64, ptr %10, align 8
  %128 = icmp eq i64 %127, 0
  br i1 %128, label %132, label %133

129:                                              ; preds = %119
  br label %125

130:                                              ; preds = %119
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).divideByZero"()
  unreachable

131:                                              ; preds = %133
  br label %97

132:                                              ; preds = %125
  br label %96

133:                                              ; preds = %125
  br label %131

134:                                              ; preds = %137
  %135 = sub nuw i64 65, %18
  %136 = icmp ule i64 65, 65
  br i1 %136, label %146, label %147

137:                                              ; preds = %16
  br label %134

138:                                              ; preds = %16
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).startGreaterThanEnd"(i64 %18, i64 65)
  unreachable

139:                                              ; preds = %146
  %140 = insertvalue { ptr, i64 } poison, ptr %19, 0
  %141 = insertvalue { ptr, i64 } %140, i64 %135, 1
  store { ptr, i64 } %141, ptr %6, align 8
  %142 = load { ptr, i64 }, ptr %6, align 8
  %143 = extractvalue { ptr, i64 } %142, 0
  %144 = extractvalue { ptr, i64 } %142, 1
  %145 = call fastcc i16 @Io.Writer.alignBufferOptions(ptr nonnull align 8 %17, ptr nonnull readonly %143, i64 %144, ptr nonnull readonly align 8 %4)
  ret i16 %145

146:                                              ; preds = %134
  br label %139

147:                                              ; preds = %134
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 65, i64 65)
  unreachable
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare { i8, i1 } @llvm.uadd.with.overflow.i8(i8, i8) #7

; Function Attrs: nounwind uwtable
define private fastcc void @Io.Writer.write(ptr noalias nonnull sret({ i64, i16, [6 x i8] }) %0, ptr nonnull align 8 %1, ptr nonnull readonly %2, i64 %3) unnamed_addr #0 align 1 {
  %5 = alloca { i64, i16, [6 x i8] }, align 8
  %6 = alloca [1 x { ptr, i64 }], align 8
  %7 = alloca { i64, i16, [6 x i8] }, align 8
  %8 = alloca { ptr, i64 }, align 8
  %9 = alloca ptr, align 8
  %10 = insertvalue { ptr, i64 } poison, ptr %2, 0
  %11 = insertvalue { ptr, i64 } %10, i64 %3, 1
  store ptr %1, ptr %9, align 8
  store { ptr, i64 } %11, ptr %8, align 8
  %12 = load ptr, ptr %9, align 8
  %13 = getelementptr inbounds i8, ptr %12, i64 24
  %14 = load i64, ptr %13, align 8
  %15 = getelementptr inbounds i8, ptr %8, i64 8
  %16 = load i64, ptr %15, align 8
  %17 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %14, i64 %16)
  %18 = extractvalue { i64, i1 } %17, 1
  br i1 %18, label %28, label %29

19:                                               ; preds = %50
  %20 = load ptr, ptr %9, align 8
  %21 = load ptr, ptr %20, align 8
  %22 = load ptr, ptr %21, align 8
  %23 = getelementptr inbounds [16 x i8], ptr %6, i64 0
  store { ptr, i64 } %11, ptr %23, align 8
  %24 = insertvalue { ptr, i64 } poison, ptr %6, 0
  %25 = insertvalue { ptr, i64 } %24, i64 1, 1
  %26 = extractvalue { ptr, i64 } %25, 0
  %27 = extractvalue { ptr, i64 } %25, 1
  call fastcc void %22(ptr sret({ i64, i16, [6 x i8] }) %5, ptr nonnull align 8 %1, ptr nonnull readonly align 8 %26, i64 %27, i64 1)
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %5, i64 16, i1 false)
  ret void

28:                                               ; preds = %4
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

29:                                               ; preds = %4
  %30 = extractvalue { i64, i1 } %17, 0
  %31 = load ptr, ptr %9, align 8
  %32 = getelementptr inbounds i8, ptr %31, i64 8
  %33 = getelementptr inbounds i8, ptr %32, i64 8
  %34 = load i64, ptr %33, align 8
  %35 = icmp ule i64 %30, %34
  br i1 %35, label %36, label %50, !prof !0

36:                                               ; preds = %29
  %37 = load ptr, ptr %9, align 8
  %38 = getelementptr inbounds i8, ptr %37, i64 8
  %39 = load ptr, ptr %9, align 8
  %40 = getelementptr inbounds i8, ptr %39, i64 24
  %41 = load i64, ptr %40, align 8
  %42 = getelementptr inbounds i8, ptr %8, i64 8
  %43 = load i64, ptr %42, align 8
  %44 = load { ptr, i64 }, ptr %38, align 8
  %45 = extractvalue { ptr, i64 } %44, 0
  %46 = getelementptr inbounds [1 x i8], ptr %45, i64 %41
  %47 = add nuw i64 %41, %43
  %48 = extractvalue { ptr, i64 } %44, 1
  %49 = icmp ule i64 %47, %48
  br i1 %49, label %57, label %58

50:                                               ; preds = %29
  br label %19

51:                                               ; preds = %57
  %52 = insertvalue { ptr, i64 } poison, ptr %46, 0
  %53 = insertvalue { ptr, i64 } %52, i64 %43, 1
  %54 = extractvalue { ptr, i64 } %53, 1
  %55 = extractvalue { ptr, i64 } %11, 1
  %56 = icmp eq i64 %54, %55
  br i1 %56, label %67, label %68

57:                                               ; preds = %36
  br label %51

58:                                               ; preds = %36
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %47, i64 %48)
  unreachable

59:                                               ; preds = %67
  %60 = extractvalue { ptr, i64 } %11, 0
  %61 = extractvalue { ptr, i64 } %53, 0
  %62 = getelementptr inbounds [1 x i8], ptr %60, i64 %54
  %63 = getelementptr inbounds [1 x i8], ptr %61, i64 %54
  %64 = icmp uge ptr %61, %62
  %65 = icmp uge ptr %60, %63
  %66 = or i1 %64, %65
  br i1 %66, label %79, label %80

67:                                               ; preds = %51
  br label %59

68:                                               ; preds = %51
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).copyLenMismatch"()
  unreachable

69:                                               ; preds = %79
  %70 = extractvalue { ptr, i64 } %53, 1
  %71 = extractvalue { ptr, i64 } %53, 0
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %71, ptr align 1 %60, i64 %70, i1 false)
  %72 = load ptr, ptr %9, align 8
  %73 = getelementptr inbounds i8, ptr %72, i64 24
  %74 = load i64, ptr %73, align 8
  %75 = getelementptr inbounds i8, ptr %8, i64 8
  %76 = load i64, ptr %75, align 8
  %77 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %74, i64 %76)
  %78 = extractvalue { i64, i1 } %77, 1
  br i1 %78, label %81, label %82

79:                                               ; preds = %59
  br label %69

80:                                               ; preds = %59
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).memcpyAlias"()
  unreachable

81:                                               ; preds = %69
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

82:                                               ; preds = %69
  %83 = extractvalue { i64, i1 } %77, 0
  store i64 %83, ptr %73, align 8
  %84 = getelementptr inbounds i8, ptr %8, i64 8
  %85 = load i64, ptr %84, align 8
  %86 = getelementptr inbounds i8, ptr %7, i64 8
  store i16 0, ptr %86, align 2
  store i64 %85, ptr %7, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %7, i64 16, i1 false)
  ret void
}

; Function Attrs: nounwind uwtable
define private fastcc i16 @Io.Writer.alignBufferOptions(ptr nonnull align 8 %0, ptr nonnull readonly %1, i64 %2, ptr nonnull readonly align 8 %3) unnamed_addr #0 align 1 {
  %5 = alloca { i64, i8, [7 x i8] }, align 8
  %6 = alloca %fmt.Options, align 8
  %7 = alloca { ptr, i64 }, align 8
  %8 = alloca ptr, align 8
  %9 = insertvalue { ptr, i64 } poison, ptr %1, 0
  %10 = insertvalue { ptr, i64 } %9, i64 %2, 1
  store ptr %0, ptr %8, align 8
  store { ptr, i64 } %10, ptr %7, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %6, ptr align 8 %3, i64 40, i1 false)
  %11 = load ptr, ptr %8, align 8
  %12 = getelementptr inbounds i8, ptr %6, i64 16
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %5, ptr align 8 %12, i64 16, i1 false)
  %13 = getelementptr inbounds i8, ptr %5, i64 8
  %14 = load i8, ptr %13, align 1
  %15 = icmp ne i8 %14, 0
  br i1 %15, label %26, label %28

16:                                               ; preds = %28, %26
  %17 = phi i64 [ %27, %26 ], [ %30, %28 ]
  %18 = getelementptr inbounds i8, ptr %6, i64 32
  %19 = load i8, ptr %18, align 1
  %20 = trunc i8 %19 to i2
  %21 = getelementptr inbounds i8, ptr %6, i64 33
  %22 = load i8, ptr %21, align 1
  %23 = extractvalue { ptr, i64 } %10, 0
  %24 = extractvalue { ptr, i64 } %10, 1
  %25 = call fastcc i16 @Io.Writer.alignBuffer(ptr nonnull align 8 %11, ptr nonnull readonly %23, i64 %24, i64 %17, i2 %20, i8 %22)
  ret i16 %25

26:                                               ; preds = %4
  %27 = load i64, ptr %5, align 8
  br label %16

28:                                               ; preds = %4
  %29 = getelementptr inbounds i8, ptr %7, i64 8
  %30 = load i64, ptr %29, align 8
  br label %16
}

; Function Attrs: nounwind uwtable
define private fastcc i8 @fmt.digitToChar(i8 %0, i1 %1) unnamed_addr #0 align 1 {
  switch i8 %0, label %11 [
  ]

3:                                                ; preds = %34, %20
  %4 = phi i8 [ %21, %20 ], [ %35, %34 ]
  ret i8 %4

5:                                                ; preds = %11
  %6 = call { i8, i1 } @llvm.uadd.with.overflow.i8(i8 %0, i8 48)
  %7 = extractvalue { i8, i1 } %6, 1
  br i1 %7, label %19, label %20

8:                                                ; preds = %15
  %9 = icmp eq i1 %1, true
  br i1 %9, label %26, label %27

10:                                               ; preds = %15
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).reachedUnreachable"()
  unreachable

11:                                               ; preds = %2
  %12 = icmp uge i8 %0, 0
  %13 = icmp ule i8 %0, 9
  %14 = and i1 %12, %13
  br i1 %14, label %5, label %15

15:                                               ; preds = %11
  %16 = icmp uge i8 %0, 10
  %17 = icmp ule i8 %0, 35
  %18 = and i1 %16, %17
  br i1 %18, label %8, label %10

19:                                               ; preds = %5
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

20:                                               ; preds = %5
  %21 = extractvalue { i8, i1 } %6, 0
  br label %3

22:                                               ; preds = %27, %26
  %23 = phi i8 [ 65, %26 ], [ 97, %27 ]
  %24 = call { i8, i1 } @llvm.usub.with.overflow.i8(i8 %23, i8 10)
  %25 = extractvalue { i8, i1 } %24, 1
  br i1 %25, label %28, label %29

26:                                               ; preds = %8
  br label %22

27:                                               ; preds = %8
  br label %22

28:                                               ; preds = %22
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

29:                                               ; preds = %22
  %30 = extractvalue { i8, i1 } %24, 0
  %31 = call { i8, i1 } @llvm.uadd.with.overflow.i8(i8 %0, i8 %30)
  %32 = extractvalue { i8, i1 } %31, 1
  br i1 %32, label %33, label %34

33:                                               ; preds = %29
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

34:                                               ; preds = %29
  %35 = extractvalue { i8, i1 } %31, 0
  br label %3
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare { i8, i1 } @llvm.usub.with.overflow.i8(i8, i8) #7

; Function Attrs: nounwind uwtable
define private fastcc i16 @Io.Writer.alignBuffer(ptr nonnull align 8 %0, ptr nonnull readonly %1, i64 %2, i64 %3, i2 %4, i8 %5) unnamed_addr #0 align 1 {
  %7 = alloca { ptr, i64 }, align 8
  %8 = alloca ptr, align 8
  %9 = insertvalue { ptr, i64 } poison, ptr %1, 0
  %10 = insertvalue { ptr, i64 } %9, i64 %2, 1
  store ptr %0, ptr %8, align 8
  store { ptr, i64 } %10, ptr %7, align 8
  %11 = getelementptr inbounds i8, ptr %7, i64 8
  %12 = load i64, ptr %11, align 8
  %13 = icmp ult i64 %12, %3
  br i1 %13, label %17, label %22

14:                                               ; preds = %24, %22
  %15 = phi i64 [ %25, %24 ], [ 0, %22 ]
  %16 = icmp eq i64 %15, 0
  br i1 %16, label %27, label %32, !prof !0

17:                                               ; preds = %6
  %18 = getelementptr inbounds i8, ptr %7, i64 8
  %19 = load i64, ptr %18, align 8
  %20 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %3, i64 %19)
  %21 = extractvalue { i64, i1 } %20, 1
  br i1 %21, label %23, label %24

22:                                               ; preds = %6
  br label %14

23:                                               ; preds = %17
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

24:                                               ; preds = %17
  %25 = extractvalue { i64, i1 } %20, 0
  br label %14

26:                                               ; preds = %32
  switch i2 %4, label %48 [
    i2 0, label %34
    i2 1, label %40
    i2 -2, label %44
  ]

27:                                               ; preds = %14
  %28 = load ptr, ptr %8, align 8
  %29 = extractvalue { ptr, i64 } %10, 0
  %30 = extractvalue { ptr, i64 } %10, 1
  %31 = call fastcc i16 @Io.Writer.writeAll(ptr nonnull align 8 %28, ptr nonnull readonly %29, i64 %30)
  ret i16 %31

32:                                               ; preds = %14
  br label %26

33:                                               ; preds = %85, %76, %55
  ret i16 0

34:                                               ; preds = %26
  %35 = load ptr, ptr %8, align 8
  %36 = extractvalue { ptr, i64 } %10, 0
  %37 = extractvalue { ptr, i64 } %10, 1
  %38 = call fastcc i16 @Io.Writer.writeAll(ptr nonnull align 8 %35, ptr nonnull readonly %36, i64 %37)
  %39 = icmp ne i16 %38, 0
  br i1 %39, label %49, label %50, !prof !1

40:                                               ; preds = %26
  %41 = udiv i64 %15, 2
  %42 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %15, i64 1)
  %43 = extractvalue { i64, i1 } %42, 1
  br i1 %43, label %56, label %57

44:                                               ; preds = %26
  %45 = load ptr, ptr %8, align 8
  %46 = call fastcc i16 @Io.Writer.splatByteAll(ptr nonnull align 8 %45, i8 %5, i64 %15)
  %47 = icmp ne i16 %46, 0
  br i1 %47, label %77, label %78, !prof !1

48:                                               ; preds = %26
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).corruptSwitch"()
  unreachable

49:                                               ; preds = %34
  ret i16 %38

50:                                               ; preds = %34
  %51 = load ptr, ptr %8, align 8
  %52 = call fastcc i16 @Io.Writer.splatByteAll(ptr nonnull align 8 %51, i8 %5, i64 %15)
  %53 = icmp ne i16 %52, 0
  br i1 %53, label %54, label %55, !prof !1

54:                                               ; preds = %50
  ret i16 %52

55:                                               ; preds = %50
  br label %33

56:                                               ; preds = %40
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

57:                                               ; preds = %40
  %58 = extractvalue { i64, i1 } %42, 0
  %59 = udiv i64 %58, 2
  %60 = load ptr, ptr %8, align 8
  %61 = call fastcc i16 @Io.Writer.splatByteAll(ptr nonnull align 8 %60, i8 %5, i64 %41)
  %62 = icmp ne i16 %61, 0
  br i1 %62, label %63, label %64, !prof !1

63:                                               ; preds = %57
  ret i16 %61

64:                                               ; preds = %57
  %65 = load ptr, ptr %8, align 8
  %66 = extractvalue { ptr, i64 } %10, 0
  %67 = extractvalue { ptr, i64 } %10, 1
  %68 = call fastcc i16 @Io.Writer.writeAll(ptr nonnull align 8 %65, ptr nonnull readonly %66, i64 %67)
  %69 = icmp ne i16 %68, 0
  br i1 %69, label %70, label %71, !prof !1

70:                                               ; preds = %64
  ret i16 %68

71:                                               ; preds = %64
  %72 = load ptr, ptr %8, align 8
  %73 = call fastcc i16 @Io.Writer.splatByteAll(ptr nonnull align 8 %72, i8 %5, i64 %59)
  %74 = icmp ne i16 %73, 0
  br i1 %74, label %75, label %76, !prof !1

75:                                               ; preds = %71
  ret i16 %73

76:                                               ; preds = %71
  br label %33

77:                                               ; preds = %44
  ret i16 %46

78:                                               ; preds = %44
  %79 = load ptr, ptr %8, align 8
  %80 = extractvalue { ptr, i64 } %10, 0
  %81 = extractvalue { ptr, i64 } %10, 1
  %82 = call fastcc i16 @Io.Writer.writeAll(ptr nonnull align 8 %79, ptr nonnull readonly %80, i64 %81)
  %83 = icmp ne i16 %82, 0
  br i1 %83, label %84, label %85, !prof !1

84:                                               ; preds = %78
  ret i16 %82

85:                                               ; preds = %78
  br label %33
}

; Function Attrs: cold noreturn nounwind uwtable
define private fastcc void @"debug.FullPanic((function 'panic')).reachedUnreachable"() unnamed_addr #1 align 1 {
  %1 = alloca { i64, i8, [7 x i8] }, align 8
  %2 = call ptr @llvm.returnaddress(i32 0)
  %3 = ptrtoint ptr %2 to i64
  store i64 %3, ptr %1, align 8
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  store i8 1, ptr %4, align 1
  %5 = extractvalue { ptr, i64 } { ptr @__anon_1545, i64 24 }, 0
  %6 = extractvalue { ptr, i64 } { ptr @__anon_1545, i64 24 }, 1
  call fastcc void @lang.panic__struct_212.panic(ptr nonnull readonly %5, i64 %6, ptr nonnull readonly align 8 %1)
  unreachable
}

; Function Attrs: cold noreturn nounwind uwtable
define private fastcc void @"debug.FullPanic((function 'panic')).corruptSwitch"() unnamed_addr #1 align 1 {
  %1 = alloca { i64, i8, [7 x i8] }, align 8
  %2 = call ptr @llvm.returnaddress(i32 0)
  %3 = ptrtoint ptr %2 to i64
  store i64 %3, ptr %1, align 8
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  store i8 1, ptr %4, align 1
  %5 = extractvalue { ptr, i64 } { ptr @__anon_1551, i64 23 }, 0
  %6 = extractvalue { ptr, i64 } { ptr @__anon_1551, i64 23 }, 1
  call fastcc void @lang.panic__struct_212.panic(ptr nonnull readonly %5, i64 %6, ptr nonnull readonly align 8 %1)
  unreachable
}

; Function Attrs: nounwind uwtable
define private fastcc i16 @Io.Writer.splatByteAll(ptr nonnull align 8 %0, i8 %1, i64 %2) unnamed_addr #0 align 1 {
  %4 = alloca { i64, i16, [6 x i8] }, align 8
  %5 = alloca i64, align 8
  %6 = alloca ptr, align 8
  store ptr %0, ptr %6, align 8
  store i64 %2, ptr %5, align 8
  br label %8

7:                                                ; preds = %19
  ret i16 0

8:                                                ; preds = %11, %3
  %9 = load i64, ptr %5, align 8
  %10 = icmp ugt i64 %9, 0
  br i1 %10, label %12, label %19

11:                                               ; preds = %28
  br label %8

12:                                               ; preds = %8
  %13 = load i64, ptr %5, align 8
  %14 = load ptr, ptr %6, align 8
  %15 = load i64, ptr %5, align 8
  call fastcc void @Io.Writer.splatByte(ptr sret({ i64, i16, [6 x i8] }) %4, ptr nonnull align 8 %14, i8 %1, i64 %15)
  %16 = getelementptr inbounds i8, ptr %4, i64 8
  %17 = load i16, ptr %16, align 2
  %18 = icmp ne i16 %17, 0
  br i1 %18, label %20, label %23, !prof !1

19:                                               ; preds = %8
  br label %7

20:                                               ; preds = %12
  %21 = getelementptr inbounds i8, ptr %4, i64 8
  %22 = load i16, ptr %21, align 2
  ret i16 %22

23:                                               ; preds = %12
  %24 = load i64, ptr %4, align 8
  %25 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %13, i64 %24)
  %26 = extractvalue { i64, i1 } %25, 1
  br i1 %26, label %27, label %28

27:                                               ; preds = %23
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

28:                                               ; preds = %23
  %29 = extractvalue { i64, i1 } %25, 0
  store i64 %29, ptr %5, align 8
  br label %11
}

; Function Attrs: cold noreturn nounwind uwtable
define private fastcc void @"debug.FullPanic((function 'panic')).divideByZero"() unnamed_addr #1 align 1 {
  %1 = alloca { i64, i8, [7 x i8] }, align 8
  %2 = call ptr @llvm.returnaddress(i32 0)
  %3 = ptrtoint ptr %2 to i64
  store i64 %3, ptr %1, align 8
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  store i8 1, ptr %4, align 1
  %5 = extractvalue { ptr, i64 } { ptr @__anon_1561, i64 16 }, 0
  %6 = extractvalue { ptr, i64 } { ptr @__anon_1561, i64 16 }, 1
  call fastcc void @lang.panic__struct_212.panic(ptr nonnull readonly %5, i64 %6, ptr nonnull readonly align 8 %1)
  unreachable
}

; Function Attrs: nounwind uwtable
define private fastcc void @Io.Writer.splatByte(ptr noalias nonnull sret({ i64, i16, [6 x i8] }) %0, ptr nonnull align 8 %1, i8 %2, i64 %3) unnamed_addr #0 align 1 {
  %5 = alloca { i64, i16, [6 x i8] }, align 8
  %6 = alloca [1 x { ptr, i64 }], align 8
  %7 = alloca [1 x i8], align 1
  %8 = alloca { i64, i16, [6 x i8] }, align 8
  %9 = alloca ptr, align 8
  store ptr %1, ptr %9, align 8
  %10 = load ptr, ptr %9, align 8
  %11 = getelementptr inbounds i8, ptr %10, i64 24
  %12 = load i64, ptr %11, align 8
  %13 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %12, i64 %3)
  %14 = extractvalue { i64, i1 } %13, 1
  br i1 %14, label %24, label %25

15:                                               ; preds = %44
  %16 = getelementptr inbounds [1 x i8], ptr %7, i64 0
  store i8 %2, ptr %16, align 1
  %17 = insertvalue { ptr, i64 } poison, ptr %7, 0
  %18 = insertvalue { ptr, i64 } %17, i64 1, 1
  %19 = getelementptr inbounds [16 x i8], ptr %6, i64 0
  store { ptr, i64 } %18, ptr %19, align 8
  %20 = insertvalue { ptr, i64 } poison, ptr %6, 0
  %21 = insertvalue { ptr, i64 } %20, i64 1, 1
  %22 = extractvalue { ptr, i64 } %21, 0
  %23 = extractvalue { ptr, i64 } %21, 1
  call fastcc void @Io.Writer.writeSplat(ptr sret({ i64, i16, [6 x i8] }) %5, ptr nonnull align 8 %1, ptr nonnull readonly align 8 %22, i64 %23, i64 %3)
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %5, i64 16, i1 false)
  ret void

24:                                               ; preds = %4
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

25:                                               ; preds = %4
  %26 = extractvalue { i64, i1 } %13, 0
  %27 = load ptr, ptr %9, align 8
  %28 = getelementptr inbounds i8, ptr %27, i64 8
  %29 = getelementptr inbounds i8, ptr %28, i64 8
  %30 = load i64, ptr %29, align 8
  %31 = icmp ule i64 %26, %30
  br i1 %31, label %32, label %44, !prof !0

32:                                               ; preds = %25
  %33 = load ptr, ptr %9, align 8
  %34 = getelementptr inbounds i8, ptr %33, i64 8
  %35 = load ptr, ptr %9, align 8
  %36 = getelementptr inbounds i8, ptr %35, i64 24
  %37 = load i64, ptr %36, align 8
  %38 = load { ptr, i64 }, ptr %34, align 8
  %39 = extractvalue { ptr, i64 } %38, 0
  %40 = getelementptr inbounds [1 x i8], ptr %39, i64 %37
  %41 = add nuw i64 %37, %3
  %42 = extractvalue { ptr, i64 } %38, 1
  %43 = icmp ule i64 %41, %42
  br i1 %43, label %55, label %56

44:                                               ; preds = %25
  br label %15

45:                                               ; preds = %55
  %46 = insertvalue { ptr, i64 } poison, ptr %40, 0
  %47 = insertvalue { ptr, i64 } %46, i64 %3, 1
  %48 = extractvalue { ptr, i64 } %47, 0
  %49 = extractvalue { ptr, i64 } %47, 1
  call void @llvm.memset.p0.i64(ptr align 1 %48, i8 %2, i64 %49, i1 false)
  %50 = load ptr, ptr %9, align 8
  %51 = getelementptr inbounds i8, ptr %50, i64 24
  %52 = load i64, ptr %51, align 8
  %53 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %52, i64 %3)
  %54 = extractvalue { i64, i1 } %53, 1
  br i1 %54, label %57, label %58

55:                                               ; preds = %32
  br label %45

56:                                               ; preds = %32
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %41, i64 %42)
  unreachable

57:                                               ; preds = %45
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

58:                                               ; preds = %45
  %59 = extractvalue { i64, i1 } %53, 0
  store i64 %59, ptr %51, align 8
  %60 = getelementptr inbounds i8, ptr %8, i64 8
  store i16 0, ptr %60, align 2
  store i64 %3, ptr %8, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %8, i64 16, i1 false)
  ret void
}

; Function Attrs: nounwind uwtable
define private fastcc void @fmt.digits2(ptr noalias nonnull sret([2 x i8]) %0, i8 %1) unnamed_addr #0 align 1 {
  %3 = alloca [2 x i8], align 1
  %4 = call { i8, i1 } @llvm.umul.with.overflow.i8(i8 %1, i8 2)
  %5 = extractvalue { i8, i1 } %4, 1
  br i1 %5, label %6, label %7

6:                                                ; preds = %2
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

7:                                                ; preds = %2
  %8 = extractvalue { i8, i1 } %4, 0
  %9 = zext i8 %8 to i64
  %10 = getelementptr inbounds [1 x i8], ptr @__anon_1572, i64 %9
  %11 = add nuw i64 %9, 2
  %12 = icmp ule i64 %11, 201
  br i1 %12, label %14, label %15

13:                                               ; preds = %14
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %3, ptr align 1 %10, i64 2, i1 false)
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %0, ptr align 1 %3, i64 2, i1 false)
  ret void

14:                                               ; preds = %7
  br label %13

15:                                               ; preds = %7
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %11, i64 201)
  unreachable
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare { i8, i1 } @llvm.umul.with.overflow.i8(i8, i8) #7

; Function Attrs: nounwind uwtable
define private fastcc void @Io.Writer.writeSplat(ptr noalias nonnull sret({ i64, i16, [6 x i8] }) %0, ptr nonnull align 8 %1, ptr nonnull readonly align 8 %2, i64 %3, i64 %4) unnamed_addr #0 align 1 {
  %6 = alloca { i64, i16, [6 x i8] }, align 8
  %7 = alloca i64, align 8
  %8 = alloca { ptr, i64 }, align 8
  %9 = alloca { ptr, i64 }, align 8
  %10 = alloca i64, align 8
  %11 = alloca { i64, i16, [6 x i8] }, align 8
  %12 = alloca { ptr, i64 }, align 8
  %13 = alloca { ptr, i64 }, align 8
  %14 = alloca ptr, align 8
  %15 = insertvalue { ptr, i64 } poison, ptr %2, 0
  %16 = insertvalue { ptr, i64 } %15, i64 %3, 1
  store ptr %1, ptr %14, align 8
  store { ptr, i64 } %16, ptr %13, align 8
  %17 = getelementptr inbounds i8, ptr %13, i64 8
  %18 = load i64, ptr %17, align 8
  %19 = icmp ugt i64 %18, 0
  call fastcc void @debug.assert(i1 %19)
  %20 = load ptr, ptr %14, align 8
  %21 = getelementptr inbounds i8, ptr %20, i64 8
  %22 = load { ptr, i64 }, ptr %21, align 8
  store { ptr, i64 } %22, ptr %12, align 8
  %23 = extractvalue { ptr, i64 } %16, 0
  %24 = extractvalue { ptr, i64 } %16, 1
  %25 = call fastcc i64 @Io.Writer.countSplat(ptr nonnull readonly align 8 %23, i64 %24, i64 %4)
  %26 = load ptr, ptr %14, align 8
  %27 = getelementptr inbounds i8, ptr %26, i64 24
  %28 = load i64, ptr %27, align 8
  %29 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %28, i64 %25)
  %30 = extractvalue { i64, i1 } %29, 1
  br i1 %30, label %36, label %37

31:                                               ; preds = %48
  store i64 0, ptr %10, align 8
  %32 = getelementptr inbounds i8, ptr %13, i64 8
  %33 = load i64, ptr %32, align 8
  %34 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %33, i64 1)
  %35 = extractvalue { i64, i1 } %34, 1
  br i1 %35, label %49, label %50

36:                                               ; preds = %5
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

37:                                               ; preds = %5
  %38 = extractvalue { i64, i1 } %29, 0
  %39 = getelementptr inbounds i8, ptr %12, i64 8
  %40 = load i64, ptr %39, align 8
  %41 = icmp ugt i64 %38, %40
  br i1 %41, label %42, label %48

42:                                               ; preds = %37
  %43 = load ptr, ptr %14, align 8
  %44 = load ptr, ptr %43, align 8
  %45 = load ptr, ptr %44, align 8
  %46 = extractvalue { ptr, i64 } %16, 0
  %47 = extractvalue { ptr, i64 } %16, 1
  call fastcc void %45(ptr sret({ i64, i16, [6 x i8] }) %11, ptr nonnull align 8 %1, ptr nonnull readonly align 8 %46, i64 %47, i64 %4)
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %11, i64 16, i1 false)
  ret void

48:                                               ; preds = %37
  br label %31

49:                                               ; preds = %31
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

50:                                               ; preds = %31
  %51 = extractvalue { i64, i1 } %34, 0
  %52 = load { ptr, i64 }, ptr %13, align 8
  %53 = extractvalue { ptr, i64 } %52, 0
  %54 = getelementptr inbounds [16 x i8], ptr %53, i64 0
  %55 = sub nuw i64 %51, 0
  %56 = extractvalue { ptr, i64 } %52, 1
  %57 = icmp ule i64 %51, %56
  br i1 %57, label %62, label %63

58:                                               ; preds = %62
  %59 = insertvalue { ptr, i64 } poison, ptr %54, 0
  %60 = insertvalue { ptr, i64 } %59, i64 %55, 1
  %61 = extractvalue { ptr, i64 } %60, 1
  br label %69

62:                                               ; preds = %50
  br label %58

63:                                               ; preds = %50
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %51, i64 %56)
  unreachable

64:                                               ; preds = %89
  %65 = getelementptr inbounds i8, ptr %13, i64 8
  %66 = load i64, ptr %65, align 8
  %67 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %66, i64 1)
  %68 = extractvalue { i64, i1 } %67, 1
  br i1 %68, label %123, label %124

69:                                               ; preds = %72, %58
  %70 = load i64, ptr %10, align 8
  %71 = icmp ult i64 %70, %61
  br i1 %71, label %74, label %89

72:                                               ; preds = %121
  %73 = add nuw i64 %70, 1
  store i64 %73, ptr %10, align 8
  br label %69

74:                                               ; preds = %69
  %75 = extractvalue { ptr, i64 } %60, 0
  %76 = getelementptr inbounds [16 x i8], ptr %75, i64 %70
  %77 = load { ptr, i64 }, ptr %76, align 8
  store { ptr, i64 } %77, ptr %9, align 8
  %78 = load ptr, ptr %14, align 8
  %79 = getelementptr inbounds i8, ptr %78, i64 24
  %80 = load i64, ptr %79, align 8
  %81 = getelementptr inbounds i8, ptr %9, i64 8
  %82 = load i64, ptr %81, align 8
  %83 = load { ptr, i64 }, ptr %12, align 8
  %84 = extractvalue { ptr, i64 } %83, 0
  %85 = getelementptr inbounds [1 x i8], ptr %84, i64 %80
  %86 = add nuw i64 %80, %82
  %87 = extractvalue { ptr, i64 } %83, 1
  %88 = icmp ule i64 %86, %87
  br i1 %88, label %96, label %97

89:                                               ; preds = %69
  br label %64

90:                                               ; preds = %96
  %91 = insertvalue { ptr, i64 } poison, ptr %85, 0
  %92 = insertvalue { ptr, i64 } %91, i64 %82, 1
  %93 = extractvalue { ptr, i64 } %92, 1
  %94 = extractvalue { ptr, i64 } %77, 1
  %95 = icmp eq i64 %93, %94
  br i1 %95, label %106, label %107

96:                                               ; preds = %74
  br label %90

97:                                               ; preds = %74
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %86, i64 %87)
  unreachable

98:                                               ; preds = %106
  %99 = extractvalue { ptr, i64 } %77, 0
  %100 = extractvalue { ptr, i64 } %92, 0
  %101 = getelementptr inbounds [1 x i8], ptr %99, i64 %93
  %102 = getelementptr inbounds [1 x i8], ptr %100, i64 %93
  %103 = icmp uge ptr %100, %101
  %104 = icmp uge ptr %99, %102
  %105 = or i1 %103, %104
  br i1 %105, label %118, label %119

106:                                              ; preds = %90
  br label %98

107:                                              ; preds = %90
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).copyLenMismatch"()
  unreachable

108:                                              ; preds = %118
  %109 = extractvalue { ptr, i64 } %92, 1
  %110 = extractvalue { ptr, i64 } %92, 0
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %110, ptr align 1 %99, i64 %109, i1 false)
  %111 = load ptr, ptr %14, align 8
  %112 = getelementptr inbounds i8, ptr %111, i64 24
  %113 = load i64, ptr %112, align 8
  %114 = getelementptr inbounds i8, ptr %9, i64 8
  %115 = load i64, ptr %114, align 8
  %116 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %113, i64 %115)
  %117 = extractvalue { i64, i1 } %116, 1
  br i1 %117, label %120, label %121

118:                                              ; preds = %98
  br label %108

119:                                              ; preds = %98
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).memcpyAlias"()
  unreachable

120:                                              ; preds = %108
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

121:                                              ; preds = %108
  %122 = extractvalue { i64, i1 } %116, 0
  store i64 %122, ptr %112, align 8
  br label %72

123:                                              ; preds = %64
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

124:                                              ; preds = %64
  %125 = extractvalue { i64, i1 } %67, 0
  %126 = load { ptr, i64 }, ptr %13, align 8
  %127 = extractvalue { ptr, i64 } %126, 1
  %128 = icmp ult i64 %125, %127
  br i1 %128, label %135, label %136

129:                                              ; preds = %135
  %130 = extractvalue { ptr, i64 } %126, 0
  %131 = getelementptr inbounds [16 x i8], ptr %130, i64 %125
  %132 = load { ptr, i64 }, ptr %131, align 8
  store { ptr, i64 } %132, ptr %8, align 8
  %133 = getelementptr inbounds i8, ptr %8, i64 8
  %134 = load i64, ptr %133, align 8
  switch i64 %134, label %150 [
    i64 0, label %139
    i64 1, label %140
  ]

135:                                              ; preds = %124
  br label %129

136:                                              ; preds = %124
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %125, i64 %127)
  unreachable

137:                                              ; preds = %175, %173, %139
  %138 = getelementptr inbounds i8, ptr %6, i64 8
  store i16 0, ptr %138, align 2
  store i64 %25, ptr %6, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 %6, i64 16, i1 false)
  ret void

139:                                              ; preds = %129
  br label %137

140:                                              ; preds = %129
  %141 = load ptr, ptr %14, align 8
  %142 = getelementptr inbounds i8, ptr %141, i64 24
  %143 = load i64, ptr %142, align 8
  %144 = load { ptr, i64 }, ptr %12, align 8
  %145 = extractvalue { ptr, i64 } %144, 0
  %146 = getelementptr inbounds [1 x i8], ptr %145, i64 %143
  %147 = add nuw i64 %143, %4
  %148 = extractvalue { ptr, i64 } %144, 1
  %149 = icmp ule i64 %147, %148
  br i1 %149, label %157, label %158

150:                                              ; preds = %129
  store i64 0, ptr %7, align 8
  br label %176

151:                                              ; preds = %157
  %152 = insertvalue { ptr, i64 } poison, ptr %146, 0
  %153 = insertvalue { ptr, i64 } %152, i64 %4, 1
  %154 = load { ptr, i64 }, ptr %8, align 8
  %155 = extractvalue { ptr, i64 } %154, 1
  %156 = icmp ult i64 0, %155
  br i1 %156, label %170, label %171

157:                                              ; preds = %140
  br label %151

158:                                              ; preds = %140
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %147, i64 %148)
  unreachable

159:                                              ; preds = %170
  %160 = extractvalue { ptr, i64 } %154, 0
  %161 = getelementptr inbounds [1 x i8], ptr %160, i64 0
  %162 = load i8, ptr %161, align 1
  %163 = extractvalue { ptr, i64 } %153, 0
  %164 = extractvalue { ptr, i64 } %153, 1
  call void @llvm.memset.p0.i64(ptr align 1 %163, i8 %162, i64 %164, i1 false)
  %165 = load ptr, ptr %14, align 8
  %166 = getelementptr inbounds i8, ptr %165, i64 24
  %167 = load i64, ptr %166, align 8
  %168 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %167, i64 %4)
  %169 = extractvalue { i64, i1 } %168, 1
  br i1 %169, label %172, label %173

170:                                              ; preds = %151
  br label %159

171:                                              ; preds = %151
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 0, i64 %155)
  unreachable

172:                                              ; preds = %159
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

173:                                              ; preds = %159
  %174 = extractvalue { i64, i1 } %168, 0
  store i64 %174, ptr %166, align 8
  br label %137

175:                                              ; preds = %193
  br label %137

176:                                              ; preds = %179, %150
  %177 = load i64, ptr %7, align 8
  %178 = icmp ult i64 %177, %4
  br i1 %178, label %181, label %193

179:                                              ; preds = %225
  %180 = add nuw i64 %177, 1
  store i64 %180, ptr %7, align 8
  br label %176

181:                                              ; preds = %176
  %182 = load ptr, ptr %14, align 8
  %183 = getelementptr inbounds i8, ptr %182, i64 24
  %184 = load i64, ptr %183, align 8
  %185 = getelementptr inbounds i8, ptr %8, i64 8
  %186 = load i64, ptr %185, align 8
  %187 = load { ptr, i64 }, ptr %12, align 8
  %188 = extractvalue { ptr, i64 } %187, 0
  %189 = getelementptr inbounds [1 x i8], ptr %188, i64 %184
  %190 = add nuw i64 %184, %186
  %191 = extractvalue { ptr, i64 } %187, 1
  %192 = icmp ule i64 %190, %191
  br i1 %192, label %200, label %201

193:                                              ; preds = %176
  br label %175

194:                                              ; preds = %200
  %195 = insertvalue { ptr, i64 } poison, ptr %189, 0
  %196 = insertvalue { ptr, i64 } %195, i64 %186, 1
  %197 = extractvalue { ptr, i64 } %196, 1
  %198 = extractvalue { ptr, i64 } %132, 1
  %199 = icmp eq i64 %197, %198
  br i1 %199, label %210, label %211

200:                                              ; preds = %181
  br label %194

201:                                              ; preds = %181
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %190, i64 %191)
  unreachable

202:                                              ; preds = %210
  %203 = extractvalue { ptr, i64 } %132, 0
  %204 = extractvalue { ptr, i64 } %196, 0
  %205 = getelementptr inbounds [1 x i8], ptr %203, i64 %197
  %206 = getelementptr inbounds [1 x i8], ptr %204, i64 %197
  %207 = icmp uge ptr %204, %205
  %208 = icmp uge ptr %203, %206
  %209 = or i1 %207, %208
  br i1 %209, label %222, label %223

210:                                              ; preds = %194
  br label %202

211:                                              ; preds = %194
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).copyLenMismatch"()
  unreachable

212:                                              ; preds = %222
  %213 = extractvalue { ptr, i64 } %196, 1
  %214 = extractvalue { ptr, i64 } %196, 0
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %214, ptr align 1 %203, i64 %213, i1 false)
  %215 = load ptr, ptr %14, align 8
  %216 = getelementptr inbounds i8, ptr %215, i64 24
  %217 = load i64, ptr %216, align 8
  %218 = getelementptr inbounds i8, ptr %8, i64 8
  %219 = load i64, ptr %218, align 8
  %220 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %217, i64 %219)
  %221 = extractvalue { i64, i1 } %220, 1
  br i1 %221, label %224, label %225

222:                                              ; preds = %202
  br label %212

223:                                              ; preds = %202
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).memcpyAlias"()
  unreachable

224:                                              ; preds = %212
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

225:                                              ; preds = %212
  %226 = extractvalue { i64, i1 } %220, 0
  store i64 %226, ptr %216, align 8
  br label %179
}

; Function Attrs: cold noreturn nounwind uwtable
define private fastcc void @"debug.FullPanic((function 'panic')).integerOutOfBounds"() unnamed_addr #1 align 1 {
  %1 = alloca { i64, i8, [7 x i8] }, align 8
  %2 = call ptr @llvm.returnaddress(i32 0)
  %3 = ptrtoint ptr %2 to i64
  store i64 %3, ptr %1, align 8
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  store i8 1, ptr %4, align 1
  %5 = extractvalue { ptr, i64 } { ptr @__anon_1589, i64 40 }, 0
  %6 = extractvalue { ptr, i64 } { ptr @__anon_1589, i64 40 }, 1
  call fastcc void @lang.panic__struct_212.panic(ptr nonnull readonly %5, i64 %6, ptr nonnull readonly align 8 %1)
  unreachable
}

; Function Attrs: nounwind uwtable
define private fastcc i64 @Io.Writer.countSplat(ptr nonnull readonly align 8 %0, i64 %1, i64 %2) unnamed_addr #0 align 1 {
  %4 = alloca { ptr, i64 }, align 8
  %5 = alloca i64, align 8
  %6 = alloca i64, align 8
  %7 = alloca { ptr, i64 }, align 8
  %8 = insertvalue { ptr, i64 } poison, ptr %0, 0
  %9 = insertvalue { ptr, i64 } %8, i64 %1, 1
  store { ptr, i64 } %9, ptr %7, align 8
  store i64 0, ptr %6, align 8
  store i64 0, ptr %5, align 8
  %10 = getelementptr inbounds i8, ptr %7, i64 8
  %11 = load i64, ptr %10, align 8
  %12 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %11, i64 1)
  %13 = extractvalue { i64, i1 } %12, 1
  br i1 %13, label %14, label %15

14:                                               ; preds = %3
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

15:                                               ; preds = %3
  %16 = extractvalue { i64, i1 } %12, 0
  %17 = load { ptr, i64 }, ptr %7, align 8
  %18 = extractvalue { ptr, i64 } %17, 0
  %19 = getelementptr inbounds [16 x i8], ptr %18, i64 0
  %20 = sub nuw i64 %16, 0
  %21 = extractvalue { ptr, i64 } %17, 1
  %22 = icmp ule i64 %16, %21
  br i1 %22, label %27, label %28

23:                                               ; preds = %27
  %24 = insertvalue { ptr, i64 } poison, ptr %19, 0
  %25 = insertvalue { ptr, i64 } %24, i64 %20, 1
  %26 = extractvalue { ptr, i64 } %25, 1
  br label %35

27:                                               ; preds = %15
  br label %23

28:                                               ; preds = %15
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %16, i64 %21)
  unreachable

29:                                               ; preds = %49
  %30 = load i64, ptr %6, align 8
  %31 = getelementptr inbounds i8, ptr %7, i64 8
  %32 = load i64, ptr %31, align 8
  %33 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %32, i64 1)
  %34 = extractvalue { i64, i1 } %33, 1
  br i1 %34, label %53, label %54

35:                                               ; preds = %38, %23
  %36 = load i64, ptr %5, align 8
  %37 = icmp ult i64 %36, %26
  br i1 %37, label %40, label %49

38:                                               ; preds = %51
  %39 = add nuw i64 %36, 1
  store i64 %39, ptr %5, align 8
  br label %35

40:                                               ; preds = %35
  %41 = extractvalue { ptr, i64 } %25, 0
  %42 = getelementptr inbounds [16 x i8], ptr %41, i64 %36
  %43 = load { ptr, i64 }, ptr %42, align 8
  store { ptr, i64 } %43, ptr %4, align 8
  %44 = load i64, ptr %6, align 8
  %45 = getelementptr inbounds i8, ptr %4, i64 8
  %46 = load i64, ptr %45, align 8
  %47 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %44, i64 %46)
  %48 = extractvalue { i64, i1 } %47, 1
  br i1 %48, label %50, label %51

49:                                               ; preds = %35
  br label %29

50:                                               ; preds = %40
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

51:                                               ; preds = %40
  %52 = extractvalue { i64, i1 } %47, 0
  store i64 %52, ptr %6, align 8
  br label %38

53:                                               ; preds = %29
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

54:                                               ; preds = %29
  %55 = extractvalue { i64, i1 } %33, 0
  %56 = load { ptr, i64 }, ptr %7, align 8
  %57 = extractvalue { ptr, i64 } %56, 1
  %58 = icmp ult i64 %55, %57
  br i1 %58, label %66, label %67

59:                                               ; preds = %66
  %60 = extractvalue { ptr, i64 } %56, 0
  %61 = getelementptr inbounds [16 x i8], ptr %60, i64 %55
  %62 = getelementptr inbounds i8, ptr %61, i64 8
  %63 = load i64, ptr %62, align 8
  %64 = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %63, i64 %2)
  %65 = extractvalue { i64, i1 } %64, 1
  br i1 %65, label %68, label %69

66:                                               ; preds = %54
  br label %59

67:                                               ; preds = %54
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %55, i64 %57)
  unreachable

68:                                               ; preds = %59
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

69:                                               ; preds = %59
  %70 = extractvalue { i64, i1 } %64, 0
  %71 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %30, i64 %70)
  %72 = extractvalue { i64, i1 } %71, 1
  br i1 %72, label %73, label %74

73:                                               ; preds = %69
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

74:                                               ; preds = %69
  %75 = extractvalue { i64, i1 } %71, 0
  store i64 %75, ptr %6, align 8
  %76 = load i64, ptr %6, align 8
  ret i64 %76
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare { i64, i1 } @llvm.umul.with.overflow.i64(i64, i64) #7

; Function Attrs: nosanitize_coverage nounwind skipprofile uwtable
define private fastcc void @debug.assert(i1 %0) unnamed_addr #9 align 1 {
  %2 = xor i1 %0, true
  br i1 %2, label %4, label %5

3:                                                ; preds = %5
  ret void

4:                                                ; preds = %1
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).reachedUnreachable"()
  unreachable

5:                                                ; preds = %1
  br label %3
}

; Function Attrs: cold noreturn nounwind uwtable
define private fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"() unnamed_addr #1 align 1 {
  %1 = alloca { i64, i8, [7 x i8] }, align 8
  %2 = call ptr @llvm.returnaddress(i32 0)
  %3 = ptrtoint ptr %2 to i64
  store i64 %3, ptr %1, align 8
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  store i8 1, ptr %4, align 1
  %5 = extractvalue { ptr, i64 } { ptr @__anon_1594, i64 16 }, 0
  %6 = extractvalue { ptr, i64 } { ptr @__anon_1594, i64 16 }, 1
  call fastcc void @lang.panic__struct_212.panic(ptr nonnull readonly %5, i64 %6, ptr nonnull readonly align 8 %1)
  unreachable
}

; Function Attrs: nounwind uwtable
define private fastcc i16 @Io.Writer.defaultFlush(ptr nonnull align 8 %0) unnamed_addr #0 align 1 {
  %2 = alloca { i64, i16, [6 x i8] }, align 8
  %3 = alloca ptr, align 8
  store ptr %0, ptr %3, align 8
  %4 = load ptr, ptr %3, align 8
  %5 = load ptr, ptr %4, align 8
  %6 = load ptr, ptr %5, align 8
  br label %8

7:                                                ; preds = %20
  ret i16 0

8:                                                ; preds = %13, %1
  %9 = load ptr, ptr %3, align 8
  %10 = getelementptr inbounds i8, ptr %9, i64 24
  %11 = load i64, ptr %10, align 8
  %12 = icmp ne i64 %11, 0
  br i1 %12, label %14, label %20

13:                                               ; preds = %24
  br label %8

14:                                               ; preds = %8
  %15 = extractvalue { ptr, i64 } { ptr @__anon_720, i64 1 }, 0
  %16 = extractvalue { ptr, i64 } { ptr @__anon_720, i64 1 }, 1
  call fastcc void %6(ptr sret({ i64, i16, [6 x i8] }) %2, ptr nonnull align 8 %0, ptr nonnull readonly align 8 %15, i64 %16, i64 1)
  %17 = getelementptr inbounds i8, ptr %2, i64 8
  %18 = load i16, ptr %17, align 2
  %19 = icmp ne i16 %18, 0
  br i1 %19, label %21, label %24, !prof !1

20:                                               ; preds = %8
  br label %7

21:                                               ; preds = %14
  %22 = getelementptr inbounds i8, ptr %2, i64 8
  %23 = load i16, ptr %22, align 2
  ret i16 %23

24:                                               ; preds = %14
  br label %13
}

; Function Attrs: nounwind uwtable
define private fastcc void @Io.Writer.unimplementedSendFile(ptr noalias nonnull sret({ i64, i16, [6 x i8] }) %0, ptr nonnull align 8 %1, ptr nonnull align 1 %2, i64 %3) unnamed_addr #0 align 1 {
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 @__anon_1601, i64 16, i1 false)
  ret void
}

; Function Attrs: nounwind uwtable
define private fastcc i16 @Io.Writer.failingRebase(ptr nonnull align 8 %0, i64 %1, i64 %2) unnamed_addr #0 align 1 {
  ret i16 1
}

; Function Attrs: nounwind uwtable
define private fastcc i16 @Io.Writer.noopFlush(ptr nonnull align 8 %0) unnamed_addr #0 align 1 {
  ret i16 0
}

; Function Attrs: nounwind uwtable
define private fastcc void @Io.Writer.fixedDrain(ptr noalias nonnull sret({ i64, i16, [6 x i8] }) %0, ptr nonnull align 8 %1, ptr nonnull readonly align 8 %2, i64 %3, i64 %4) unnamed_addr #0 align 1 {
  %6 = alloca { ptr, i64 }, align 8
  %7 = alloca i64, align 8
  %8 = alloca { ptr, i64 }, align 8
  %9 = alloca { ptr, i64 }, align 8
  %10 = alloca { ptr, i64 }, align 8
  %11 = alloca { ptr, i64 }, align 8
  %12 = alloca i64, align 8
  %13 = alloca { ptr, i64 }, align 8
  %14 = alloca ptr, align 8
  %15 = insertvalue { ptr, i64 } poison, ptr %2, 0
  %16 = insertvalue { ptr, i64 } %15, i64 %3, 1
  store ptr %1, ptr %14, align 8
  store { ptr, i64 } %16, ptr %13, align 8
  %17 = getelementptr inbounds i8, ptr %13, i64 8
  %18 = load i64, ptr %17, align 8
  %19 = icmp eq i64 %18, 0
  br i1 %19, label %25, label %26

20:                                               ; preds = %26
  store i64 0, ptr %12, align 8
  %21 = getelementptr inbounds i8, ptr %13, i64 8
  %22 = load i64, ptr %21, align 8
  %23 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %22, i64 1)
  %24 = extractvalue { i64, i1 } %23, 1
  br i1 %24, label %27, label %28

25:                                               ; preds = %5
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 @__anon_1604, i64 16, i1 false)
  ret void

26:                                               ; preds = %5
  br label %20

27:                                               ; preds = %20
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

28:                                               ; preds = %20
  %29 = extractvalue { i64, i1 } %23, 0
  %30 = load { ptr, i64 }, ptr %13, align 8
  %31 = extractvalue { ptr, i64 } %30, 0
  %32 = getelementptr inbounds [16 x i8], ptr %31, i64 0
  %33 = sub nuw i64 %29, 0
  %34 = extractvalue { ptr, i64 } %30, 1
  %35 = icmp ule i64 %29, %34
  br i1 %35, label %40, label %41

36:                                               ; preds = %40
  %37 = insertvalue { ptr, i64 } poison, ptr %32, 0
  %38 = insertvalue { ptr, i64 } %37, i64 %33, 1
  %39 = extractvalue { ptr, i64 } %38, 1
  br label %47

40:                                               ; preds = %28
  br label %36

41:                                               ; preds = %28
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %29, i64 %34)
  unreachable

42:                                               ; preds = %66
  %43 = getelementptr inbounds i8, ptr %13, i64 8
  %44 = load i64, ptr %43, align 8
  %45 = call { i64, i1 } @llvm.usub.with.overflow.i64(i64 %44, i64 1)
  %46 = extractvalue { i64, i1 } %45, 1
  br i1 %46, label %139, label %140

47:                                               ; preds = %50, %36
  %48 = load i64, ptr %12, align 8
  %49 = icmp ult i64 %48, %39
  br i1 %49, label %52, label %66

50:                                               ; preds = %136
  %51 = add nuw i64 %48, 1
  store i64 %51, ptr %12, align 8
  br label %47

52:                                               ; preds = %47
  %53 = extractvalue { ptr, i64 } %38, 0
  %54 = getelementptr inbounds [16 x i8], ptr %53, i64 %48
  %55 = load { ptr, i64 }, ptr %54, align 8
  store { ptr, i64 } %55, ptr %11, align 8
  %56 = load ptr, ptr %14, align 8
  %57 = getelementptr inbounds i8, ptr %56, i64 8
  %58 = load ptr, ptr %14, align 8
  %59 = getelementptr inbounds i8, ptr %58, i64 24
  %60 = load i64, ptr %59, align 8
  %61 = load { ptr, i64 }, ptr %57, align 8
  %62 = extractvalue { ptr, i64 } %61, 0
  %63 = getelementptr inbounds [1 x i8], ptr %62, i64 %60
  %64 = extractvalue { ptr, i64 } %61, 1
  %65 = icmp ule i64 %60, %64
  br i1 %65, label %71, label %72

66:                                               ; preds = %47
  br label %42

67:                                               ; preds = %71
  %68 = sub nuw i64 %64, %60
  %69 = extractvalue { ptr, i64 } %61, 1
  %70 = icmp ule i64 %64, %69
  br i1 %70, label %87, label %88

71:                                               ; preds = %52
  br label %67

72:                                               ; preds = %52
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).startGreaterThanEnd"(i64 %60, i64 %64)
  unreachable

73:                                               ; preds = %87
  %74 = insertvalue { ptr, i64 } poison, ptr %63, 0
  %75 = insertvalue { ptr, i64 } %74, i64 %68, 1
  store { ptr, i64 } %75, ptr %10, align 8
  %76 = getelementptr inbounds i8, ptr %11, i64 8
  %77 = load i64, ptr %76, align 8
  %78 = getelementptr inbounds i8, ptr %10, i64 8
  %79 = load i64, ptr %78, align 8
  %80 = call i64 @llvm.umin.i64(i64 %77, i64 %79)
  %81 = load { ptr, i64 }, ptr %10, align 8
  %82 = extractvalue { ptr, i64 } %81, 0
  %83 = getelementptr inbounds [1 x i8], ptr %82, i64 0
  %84 = sub nuw i64 %80, 0
  %85 = extractvalue { ptr, i64 } %81, 1
  %86 = icmp ule i64 %80, %85
  br i1 %86, label %98, label %99

87:                                               ; preds = %67
  br label %73

88:                                               ; preds = %67
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %64, i64 %69)
  unreachable

89:                                               ; preds = %98
  %90 = insertvalue { ptr, i64 } poison, ptr %83, 0
  %91 = insertvalue { ptr, i64 } %90, i64 %84, 1
  %92 = load { ptr, i64 }, ptr %11, align 8
  %93 = extractvalue { ptr, i64 } %92, 0
  %94 = getelementptr inbounds [1 x i8], ptr %93, i64 0
  %95 = sub nuw i64 %80, 0
  %96 = extractvalue { ptr, i64 } %92, 1
  %97 = icmp ule i64 %80, %96
  br i1 %97, label %106, label %107

98:                                               ; preds = %73
  br label %89

99:                                               ; preds = %73
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %80, i64 %85)
  unreachable

100:                                              ; preds = %106
  %101 = insertvalue { ptr, i64 } poison, ptr %94, 0
  %102 = insertvalue { ptr, i64 } %101, i64 %95, 1
  %103 = extractvalue { ptr, i64 } %91, 1
  %104 = extractvalue { ptr, i64 } %102, 1
  %105 = icmp eq i64 %103, %104
  br i1 %105, label %116, label %117

106:                                              ; preds = %89
  br label %100

107:                                              ; preds = %89
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %80, i64 %96)
  unreachable

108:                                              ; preds = %116
  %109 = extractvalue { ptr, i64 } %102, 0
  %110 = extractvalue { ptr, i64 } %91, 0
  %111 = getelementptr inbounds [1 x i8], ptr %109, i64 %103
  %112 = getelementptr inbounds [1 x i8], ptr %110, i64 %103
  %113 = icmp uge ptr %110, %111
  %114 = icmp uge ptr %109, %112
  %115 = or i1 %113, %114
  br i1 %115, label %126, label %127

116:                                              ; preds = %100
  br label %108

117:                                              ; preds = %100
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).copyLenMismatch"()
  unreachable

118:                                              ; preds = %126
  %119 = extractvalue { ptr, i64 } %91, 1
  %120 = extractvalue { ptr, i64 } %91, 0
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %120, ptr align 1 %109, i64 %119, i1 false)
  %121 = load ptr, ptr %14, align 8
  %122 = getelementptr inbounds i8, ptr %121, i64 24
  %123 = load i64, ptr %122, align 8
  %124 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %123, i64 %80)
  %125 = extractvalue { i64, i1 } %124, 1
  br i1 %125, label %128, label %129

126:                                              ; preds = %108
  br label %118

127:                                              ; preds = %108
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).memcpyAlias"()
  unreachable

128:                                              ; preds = %118
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

129:                                              ; preds = %118
  %130 = extractvalue { i64, i1 } %124, 0
  store i64 %130, ptr %122, align 8
  %131 = getelementptr inbounds i8, ptr %11, i64 8
  %132 = load i64, ptr %131, align 8
  %133 = getelementptr inbounds i8, ptr %10, i64 8
  %134 = load i64, ptr %133, align 8
  %135 = icmp ugt i64 %132, %134
  br i1 %135, label %137, label %138

136:                                              ; preds = %138
  br label %50

137:                                              ; preds = %129
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 @__anon_1605, i64 16, i1 false)
  ret void

138:                                              ; preds = %129
  br label %136

139:                                              ; preds = %42
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

140:                                              ; preds = %42
  %141 = extractvalue { i64, i1 } %45, 0
  %142 = load { ptr, i64 }, ptr %13, align 8
  %143 = extractvalue { ptr, i64 } %142, 1
  %144 = icmp ult i64 %141, %143
  br i1 %144, label %159, label %160

145:                                              ; preds = %159
  %146 = extractvalue { ptr, i64 } %142, 0
  %147 = getelementptr inbounds [16 x i8], ptr %146, i64 %141
  %148 = load { ptr, i64 }, ptr %147, align 8
  store { ptr, i64 } %148, ptr %9, align 8
  %149 = load ptr, ptr %14, align 8
  %150 = getelementptr inbounds i8, ptr %149, i64 8
  %151 = load ptr, ptr %14, align 8
  %152 = getelementptr inbounds i8, ptr %151, i64 24
  %153 = load i64, ptr %152, align 8
  %154 = load { ptr, i64 }, ptr %150, align 8
  %155 = extractvalue { ptr, i64 } %154, 0
  %156 = getelementptr inbounds [1 x i8], ptr %155, i64 %153
  %157 = extractvalue { ptr, i64 } %154, 1
  %158 = icmp ule i64 %153, %157
  br i1 %158, label %165, label %166

159:                                              ; preds = %140
  br label %145

160:                                              ; preds = %140
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %141, i64 %143)
  unreachable

161:                                              ; preds = %165
  %162 = sub nuw i64 %157, %153
  %163 = extractvalue { ptr, i64 } %154, 1
  %164 = icmp ule i64 %157, %163
  br i1 %164, label %172, label %173

165:                                              ; preds = %145
  br label %161

166:                                              ; preds = %145
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).startGreaterThanEnd"(i64 %153, i64 %157)
  unreachable

167:                                              ; preds = %172
  %168 = insertvalue { ptr, i64 } poison, ptr %156, 0
  %169 = insertvalue { ptr, i64 } %168, i64 %162, 1
  store { ptr, i64 } %169, ptr %8, align 8
  %170 = getelementptr inbounds i8, ptr %9, i64 8
  %171 = load i64, ptr %170, align 8
  switch i64 %171, label %182 [
    i64 0, label %174
    i64 1, label %175
  ]

172:                                              ; preds = %161
  br label %167

173:                                              ; preds = %161
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %157, i64 %163)
  unreachable

174:                                              ; preds = %167
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 @__anon_1604, i64 16, i1 false)
  ret void

175:                                              ; preds = %167
  %176 = getelementptr inbounds i8, ptr %8, i64 8
  %177 = load i64, ptr %176, align 8
  %178 = icmp uge i64 %4, %177
  call fastcc void @debug.assert(i1 %178)
  %179 = load { ptr, i64 }, ptr %9, align 8
  %180 = extractvalue { ptr, i64 } %179, 1
  %181 = icmp ult i64 0, %180
  br i1 %181, label %196, label %197

182:                                              ; preds = %167
  call void @llvm.assume(i1 true) [ "cold"() ]
  store i64 0, ptr %7, align 8
  br label %202

183:                                              ; preds = %196
  %184 = extractvalue { ptr, i64 } %179, 0
  %185 = getelementptr inbounds [1 x i8], ptr %184, i64 0
  %186 = load i8, ptr %185, align 1
  %187 = extractvalue { ptr, i64 } %169, 0
  %188 = extractvalue { ptr, i64 } %169, 1
  call void @llvm.memset.p0.i64(ptr align 1 %187, i8 %186, i64 %188, i1 false)
  %189 = load ptr, ptr %14, align 8
  %190 = getelementptr inbounds i8, ptr %189, i64 24
  %191 = load i64, ptr %190, align 8
  %192 = getelementptr inbounds i8, ptr %8, i64 8
  %193 = load i64, ptr %192, align 8
  %194 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %191, i64 %193)
  %195 = extractvalue { i64, i1 } %194, 1
  br i1 %195, label %198, label %199

196:                                              ; preds = %175
  br label %183

197:                                              ; preds = %175
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 0, i64 %180)
  unreachable

198:                                              ; preds = %183
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

199:                                              ; preds = %183
  %200 = extractvalue { i64, i1 } %194, 0
  store i64 %200, ptr %190, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 @__anon_1605, i64 16, i1 false)
  ret void

201:                                              ; preds = %212
  call fastcc void @"debug.FullPanic((function 'panic')).reachedUnreachable"()
  unreachable

202:                                              ; preds = %205, %182
  %203 = load i64, ptr %7, align 8
  %204 = icmp ult i64 %203, %4
  br i1 %204, label %207, label %212

205:                                              ; preds = %290
  %206 = add nuw i64 %203, 1
  store i64 %206, ptr %7, align 8
  br label %202

207:                                              ; preds = %202
  %208 = getelementptr inbounds i8, ptr %9, i64 8
  %209 = load i64, ptr %208, align 8
  %210 = call { i64, i1 } @llvm.umul.with.overflow.i64(i64 %203, i64 %209)
  %211 = extractvalue { i64, i1 } %210, 1
  br i1 %211, label %213, label %214

212:                                              ; preds = %202
  br label %201

213:                                              ; preds = %207
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

214:                                              ; preds = %207
  %215 = extractvalue { i64, i1 } %210, 0
  %216 = load { ptr, i64 }, ptr %8, align 8
  %217 = extractvalue { ptr, i64 } %216, 0
  %218 = getelementptr inbounds [1 x i8], ptr %217, i64 %215
  %219 = extractvalue { ptr, i64 } %216, 1
  %220 = icmp ule i64 %215, %219
  br i1 %220, label %225, label %226

221:                                              ; preds = %225
  %222 = sub nuw i64 %219, %215
  %223 = extractvalue { ptr, i64 } %216, 1
  %224 = icmp ule i64 %219, %223
  br i1 %224, label %241, label %242

225:                                              ; preds = %214
  br label %221

226:                                              ; preds = %214
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).startGreaterThanEnd"(i64 %215, i64 %219)
  unreachable

227:                                              ; preds = %241
  %228 = insertvalue { ptr, i64 } poison, ptr %218, 0
  %229 = insertvalue { ptr, i64 } %228, i64 %222, 1
  store { ptr, i64 } %229, ptr %6, align 8
  %230 = getelementptr inbounds i8, ptr %9, i64 8
  %231 = load i64, ptr %230, align 8
  %232 = getelementptr inbounds i8, ptr %6, i64 8
  %233 = load i64, ptr %232, align 8
  %234 = call i64 @llvm.umin.i64(i64 %231, i64 %233)
  %235 = load { ptr, i64 }, ptr %6, align 8
  %236 = extractvalue { ptr, i64 } %235, 0
  %237 = getelementptr inbounds [1 x i8], ptr %236, i64 0
  %238 = sub nuw i64 %234, 0
  %239 = extractvalue { ptr, i64 } %235, 1
  %240 = icmp ule i64 %234, %239
  br i1 %240, label %252, label %253

241:                                              ; preds = %221
  br label %227

242:                                              ; preds = %221
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %219, i64 %223)
  unreachable

243:                                              ; preds = %252
  %244 = insertvalue { ptr, i64 } poison, ptr %237, 0
  %245 = insertvalue { ptr, i64 } %244, i64 %238, 1
  %246 = load { ptr, i64 }, ptr %9, align 8
  %247 = extractvalue { ptr, i64 } %246, 0
  %248 = getelementptr inbounds [1 x i8], ptr %247, i64 0
  %249 = sub nuw i64 %234, 0
  %250 = extractvalue { ptr, i64 } %246, 1
  %251 = icmp ule i64 %234, %250
  br i1 %251, label %260, label %261

252:                                              ; preds = %227
  br label %243

253:                                              ; preds = %227
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %234, i64 %239)
  unreachable

254:                                              ; preds = %260
  %255 = insertvalue { ptr, i64 } poison, ptr %248, 0
  %256 = insertvalue { ptr, i64 } %255, i64 %249, 1
  %257 = extractvalue { ptr, i64 } %245, 1
  %258 = extractvalue { ptr, i64 } %256, 1
  %259 = icmp eq i64 %257, %258
  br i1 %259, label %270, label %271

260:                                              ; preds = %243
  br label %254

261:                                              ; preds = %243
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %234, i64 %250)
  unreachable

262:                                              ; preds = %270
  %263 = extractvalue { ptr, i64 } %256, 0
  %264 = extractvalue { ptr, i64 } %245, 0
  %265 = getelementptr inbounds [1 x i8], ptr %263, i64 %257
  %266 = getelementptr inbounds [1 x i8], ptr %264, i64 %257
  %267 = icmp uge ptr %264, %265
  %268 = icmp uge ptr %263, %266
  %269 = or i1 %267, %268
  br i1 %269, label %280, label %281

270:                                              ; preds = %254
  br label %262

271:                                              ; preds = %254
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).copyLenMismatch"()
  unreachable

272:                                              ; preds = %280
  %273 = extractvalue { ptr, i64 } %245, 1
  %274 = extractvalue { ptr, i64 } %245, 0
  call void @llvm.memcpy.p0.p0.i64(ptr align 1 %274, ptr align 1 %263, i64 %273, i1 false)
  %275 = load ptr, ptr %14, align 8
  %276 = getelementptr inbounds i8, ptr %275, i64 24
  %277 = load i64, ptr %276, align 8
  %278 = call { i64, i1 } @llvm.uadd.with.overflow.i64(i64 %277, i64 %234)
  %279 = extractvalue { i64, i1 } %278, 1
  br i1 %279, label %282, label %283

280:                                              ; preds = %262
  br label %272

281:                                              ; preds = %262
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).memcpyAlias"()
  unreachable

282:                                              ; preds = %272
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).integerOverflow"()
  unreachable

283:                                              ; preds = %272
  %284 = extractvalue { i64, i1 } %278, 0
  store i64 %284, ptr %276, align 8
  %285 = getelementptr inbounds i8, ptr %9, i64 8
  %286 = load i64, ptr %285, align 8
  %287 = getelementptr inbounds i8, ptr %6, i64 8
  %288 = load i64, ptr %287, align 8
  %289 = icmp ugt i64 %286, %288
  br i1 %289, label %291, label %292

290:                                              ; preds = %292
  br label %205

291:                                              ; preds = %283
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %0, ptr align 8 @__anon_1605, i64 16, i1 false)
  ret void

292:                                              ; preds = %283
  br label %290
}

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.umin.i64(i64, i64) #7

; Function Attrs: cold noreturn nounwind uwtable
define private fastcc void @"debug.FullPanic((function 'panic')).memcpyAlias"() unnamed_addr #1 align 1 {
  %1 = alloca { i64, i8, [7 x i8] }, align 8
  %2 = call ptr @llvm.returnaddress(i32 0)
  %3 = ptrtoint ptr %2 to i64
  store i64 %3, ptr %1, align 8
  %4 = getelementptr inbounds i8, ptr %1, i64 8
  store i8 1, ptr %4, align 1
  %5 = extractvalue { ptr, i64 } { ptr @__anon_1606, i64 23 }, 0
  %6 = extractvalue { ptr, i64 } { ptr @__anon_1606, i64 23 }, 1
  call fastcc void @lang.panic__struct_212.panic(ptr nonnull readonly %5, i64 %6, ptr nonnull readonly align 8 %1)
  unreachable
}

; Function Attrs: nounwind uwtable
define private fastcc { ptr, i64 } @Io.Writer.buffered(ptr nonnull readonly align 8 %0) unnamed_addr #0 align 1 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds i8, ptr %3, i64 8
  %5 = load ptr, ptr %2, align 8
  %6 = getelementptr inbounds i8, ptr %5, i64 24
  %7 = load i64, ptr %6, align 8
  %8 = load { ptr, i64 }, ptr %4, align 8
  %9 = extractvalue { ptr, i64 } %8, 0
  %10 = getelementptr inbounds [1 x i8], ptr %9, i64 0
  %11 = sub nuw i64 %7, 0
  %12 = extractvalue { ptr, i64 } %8, 1
  %13 = icmp ule i64 %7, %12
  br i1 %13, label %17, label %18

14:                                               ; preds = %17
  %15 = insertvalue { ptr, i64 } poison, ptr %10, 0
  %16 = insertvalue { ptr, i64 } %15, i64 %11, 1
  ret { ptr, i64 } %16

17:                                               ; preds = %1
  br label %14

18:                                               ; preds = %1
  call void @llvm.assume(i1 true) [ "cold"() ]
  call fastcc void @"debug.FullPanic((function 'panic')).outOfBounds"(i64 %7, i64 %12)
  unreachable
}

; Function Attrs: nounwind uwtable
define private fastcc i16 @Io.Writer.print__anon_634(ptr nonnull align 8 %0, ptr nonnull readonly align 8 %1) unnamed_addr #0 align 1 {
  %3 = alloca { { ptr, i64 } }, align 8
  %4 = alloca ptr, align 8
  store ptr %0, ptr %4, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %3, ptr align 8 %1, i64 16, i1 false)
  %5 = load ptr, ptr %4, align 8
  %6 = extractvalue { ptr, i64 } { ptr @__anon_1659, i64 25 }, 0
  %7 = extractvalue { ptr, i64 } { ptr @__anon_1659, i64 25 }, 1
  %8 = call fastcc i16 @Io.Writer.writeAll(ptr nonnull align 8 %5, ptr nonnull readonly %6, i64 %7)
  %9 = icmp ne i16 %8, 0
  br i1 %9, label %10, label %11, !prof !1

10:                                               ; preds = %2
  ret i16 %8

11:                                               ; preds = %2
  %12 = load ptr, ptr %4, align 8
  %13 = load { ptr, i64 }, ptr %3, align 8
  %14 = extractvalue { ptr, i64 } %13, 0
  %15 = extractvalue { ptr, i64 } %13, 1
  %16 = call fastcc i16 @Io.Writer.printValue__anon_1680(ptr nonnull align 8 %12, ptr nonnull readonly align 8 @__anon_1068, ptr nonnull readonly %14, i64 %15, i64 3)
  %17 = icmp ne i16 %16, 0
  br i1 %17, label %18, label %19, !prof !1

18:                                               ; preds = %11
  ret i16 %16

19:                                               ; preds = %11
  ret i16 0
}

; Function Attrs: nounwind uwtable
define private fastcc i16 @Io.Writer.printValue__anon_1680(ptr nonnull align 8 %0, ptr nonnull readonly align 8 %1, ptr nonnull readonly %2, i64 %3, i64 %4) unnamed_addr #0 align 1 {
  %6 = alloca { ptr, i64 }, align 8
  %7 = alloca { ptr, i64 }, align 8
  %8 = alloca %fmt.Options, align 8
  %9 = alloca ptr, align 8
  %10 = insertvalue { ptr, i64 } poison, ptr %2, 0
  %11 = insertvalue { ptr, i64 } %10, i64 %3, 1
  store ptr %0, ptr %9, align 8
  call void @llvm.memcpy.p0.p0.i64(ptr align 8 %8, ptr align 8 %1, i64 40, i1 false)
  store { ptr, i64 } %11, ptr %7, align 8
  store { ptr, i64 } %11, ptr %6, align 8
  %12 = load { ptr, i64 }, ptr %6, align 8
  %13 = load ptr, ptr %9, align 8
  %14 = extractvalue { ptr, i64 } %12, 0
  %15 = extractvalue { ptr, i64 } %12, 1
  %16 = call fastcc i16 @Io.Writer.alignBufferOptions(ptr nonnull align 8 %13, ptr nonnull readonly %14, i64 %15, ptr nonnull readonly align 8 %1)
  ret i16 %16
}

attributes #0 = { nounwind uwtable "frame-pointer"="all" "probe-stack"="__zig_probe_stack" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #1 = { cold noreturn nounwind uwtable "frame-pointer"="all" "probe-stack"="__zig_probe_stack" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(none) }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #5 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #6 = { noreturn nounwind uwtable "frame-pointer"="all" "probe-stack"="__zig_probe_stack" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #7 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #8 = { nounwind }
attributes #9 = { nosanitize_coverage nounwind skipprofile uwtable "frame-pointer"="all" "probe-stack"="__zig_probe_stack" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }

!llvm.module.flags = !{}

!0 = !{!"branch_weights", i32 2000, i32 1}
!1 = !{!"branch_weights", i32 1, i32 2000}
