source_filename = "base64_table_lookup"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@__anon_base64_table = private unnamed_addr constant [4 x i8] c"\00\04\08\0C", align 4
@base64_table_lookup = alias i32 (i8), ptr @base64.table_lookup

define private i32 @base64.table_lookup(i8 zeroext %0) unnamed_addr align 1 {
Entry:
  %1 = zext i8 %0 to i64
  %2 = getelementptr inbounds [4 x i8], ptr @__anon_base64_table, i64 0, i64 %1
  %3 = load i8, ptr %2, align 1
  %4 = zext i8 %3 to i32
  ret i32 %4
}
