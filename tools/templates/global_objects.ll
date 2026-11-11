; Generated fixture prefix: tools/generate_global_objects_canary.zig.
target triple = "x86_64-unknown-linux-gnu"
target datalayout = "e-p:64:64-i64:64-i128:128-f80:128"
%GlobalFloats = type { i8, [2 x float], [3 x double], fp128, ptr }
@global_objects_escapes = private constant { i64, [13 x i8], i64 } { i64 1234605616436508552, [13 x i8] c"\1B[J\1B]9;4;0\1B\\\00", i64 72623859790382856 }
@global_objects_poison_cells = private constant { [3 x i32], [3 x ptr] } { [3 x i32] [i32 287454020, i32 poison, i32 -1], [3 x ptr] [ptr @global_objects_first_data, ptr poison, ptr @global_objects_second_data] }
@global_objects_floats = private constant %GlobalFloats { i8 90, [2 x float] [float 0x7FF0000020000000, float 0x36A0000000000000], [3 x double] [double 0x8000000000000000, double 0x1, double 0xFFF0000000000123], fp128 0xL0123456789ABCDEF7FFF000000000123, ptr @global_objects_first_data }, align 16
@global_objects_halves = private constant [3 x half] [half 0xH8000, half 0xH7C01, half 0xH0001]
@global_objects_x87 = private constant [2 x x86_fp80] [x86_fp80 0xK7FFF8000000000000001, x86_fp80 0xK80000000000000000000], align 16
@global_objects_first_data = internal global { i64, [48 x i8], i64 } { i64 17, [48 x i8] zeroinitializer, i64 238 }
@global_objects_second_data = internal global { i64, [48 x i8], i64 } { i64 34, [48 x i8] zeroinitializer, i64 221 }
@global_objects_relative_table = private constant [4 x i32] [i32 trunc (i64 sub (i64 ptrtoint (ptr @global_objects_first_data to i64), i64 ptrtoint (ptr @global_objects_relative_table to i64)) to i32), i32 trunc (i64 sub (i64 ptrtoint (ptr getelementptr (i8, ptr @global_objects_second_data, i64 7) to i64), i64 ptrtoint (ptr getelementptr (i8, ptr @global_objects_relative_table, i64 3) to i64)) to i32), i32 trunc (i64 sub (i64 ptrtoint (ptr getelementptr (i8, ptr @global_objects_relative_table, i64 8) to i64), i64 ptrtoint (ptr @global_objects_relative_table to i64)) to i32), i32 trunc (i64 sub (i64 ptrtoint (ptr getelementptr (i8, ptr @global_objects_first_data, i64 5) to i64), i64 ptrtoint (ptr getelementptr (i8, ptr @global_objects_relative_table, i64 12) to i64)) to i32)], align 4
