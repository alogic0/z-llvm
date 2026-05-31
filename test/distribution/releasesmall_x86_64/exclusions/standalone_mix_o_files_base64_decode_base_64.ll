source_filename = "base64"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux5.10.0-gnu2.31.0"

%base64.Base64Decoder = type { [4 x [256 x i32]], [256 x i8], { i8, i8 }, [2 x i8] }

@base64.x_ptr = private unnamed_addr global ptr @base64.x, align 8
@__anon_1321 = private unnamed_addr constant %base64.Base64Decoder { [4 x [256 x i32]] [[256 x i32] [i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 248, i32 -16777216, i32 -16777216, i32 -16777216, i32 252, i32 208, i32 212, i32 216, i32 220, i32 224, i32 228, i32 232, i32 236, i32 240, i32 244, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 0, i32 4, i32 8, i32 12, i32 16, i32 20, i32 24, i32 28, i32 32, i32 36, i32 40, i32 44, i32 48, i32 52, i32 56, i32 60, i32 64, i32 68, i32 72, i32 76, i32 80, i32 84, i32 88, i32 92, i32 96, i32 100, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 104, i32 108, i32 112, i32 116, i32 120, i32 124, i32 128, i32 132, i32 136, i32 140, i32 144, i32 148, i32 152, i32 156, i32 160, i32 164, i32 168, i32 172, i32 176, i32 180, i32 184, i32 188, i32 192, i32 196, i32 200, i32 204, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216], [256 x i32] [i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 57347, i32 -16777216, i32 -16777216, i32 -16777216, i32 61443, i32 16387, i32 20483, i32 24579, i32 28675, i32 32771, i32 36867, i32 40963, i32 45059, i32 49155, i32 53251, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 0, i32 4096, i32 8192, i32 12288, i32 16384, i32 20480, i32 24576, i32 28672, i32 32768, i32 36864, i32 40960, i32 45056, i32 49152, i32 53248, i32 57344, i32 61440, i32 1, i32 4097, i32 8193, i32 12289, i32 16385, i32 20481, i32 24577, i32 28673, i32 32769, i32 36865, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 40961, i32 45057, i32 49153, i32 53249, i32 57345, i32 61441, i32 2, i32 4098, i32 8194, i32 12290, i32 16386, i32 20482, i32 24578, i32 28674, i32 32770, i32 36866, i32 40962, i32 45058, i32 49154, i32 53250, i32 57346, i32 61442, i32 3, i32 4099, i32 8195, i32 12291, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216], [256 x i32] [i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 8392448, i32 -16777216, i32 -16777216, i32 -16777216, i32 12586752, i32 3328, i32 4197632, i32 8391936, i32 12586240, i32 3584, i32 4197888, i32 8392192, i32 12586496, i32 3840, i32 4198144, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 0, i32 4194304, i32 8388608, i32 12582912, i32 256, i32 4194560, i32 8388864, i32 12583168, i32 512, i32 4194816, i32 8389120, i32 12583424, i32 768, i32 4195072, i32 8389376, i32 12583680, i32 1024, i32 4195328, i32 8389632, i32 12583936, i32 1280, i32 4195584, i32 8389888, i32 12584192, i32 1536, i32 4195840, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 8390144, i32 12584448, i32 1792, i32 4196096, i32 8390400, i32 12584704, i32 2048, i32 4196352, i32 8390656, i32 12584960, i32 2304, i32 4196608, i32 8390912, i32 12585216, i32 2560, i32 4196864, i32 8391168, i32 12585472, i32 2816, i32 4197120, i32 8391424, i32 12585728, i32 3072, i32 4197376, i32 8391680, i32 12585984, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216], [256 x i32] [i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 4063232, i32 -16777216, i32 -16777216, i32 -16777216, i32 4128768, i32 3407872, i32 3473408, i32 3538944, i32 3604480, i32 3670016, i32 3735552, i32 3801088, i32 3866624, i32 3932160, i32 3997696, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 0, i32 65536, i32 131072, i32 196608, i32 262144, i32 327680, i32 393216, i32 458752, i32 524288, i32 589824, i32 655360, i32 720896, i32 786432, i32 851968, i32 917504, i32 983040, i32 1048576, i32 1114112, i32 1179648, i32 1245184, i32 1310720, i32 1376256, i32 1441792, i32 1507328, i32 1572864, i32 1638400, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 1703936, i32 1769472, i32 1835008, i32 1900544, i32 1966080, i32 2031616, i32 2097152, i32 2162688, i32 2228224, i32 2293760, i32 2359296, i32 2424832, i32 2490368, i32 2555904, i32 2621440, i32 2686976, i32 2752512, i32 2818048, i32 2883584, i32 2949120, i32 3014656, i32 3080192, i32 3145728, i32 3211264, i32 3276800, i32 3342336, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216, i32 -16777216]], [256 x i8] c"\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF>\FF\FF\FF?456789:;<=\FF\FF\FF\FF\FF\FF\FF\00\01\02\03\04\05\06\07\08\09\0A\0B\0C\0D\0E\0F\10\11\12\13\14\15\16\17\18\19\FF\FF\FF\FF\FF\FF\1A\1B\1C\1D\1E\1F !\22#$%&'()*+,-./0123\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF", { i8, i8 } { i8 61, i8 1 }, [2 x i8] undef }, align 4
@base64.x = private unnamed_addr global i32 1234, align 4

@x_ptr = alias ptr, ptr @base64.x_ptr
@decode_base_64 = alias i64 (ptr, i64, ptr, i64), ptr @base64.decode_base_64

declare void @llvm.assume(i1 noundef) #1

declare void @llvm.lifetime.start.p0(ptr captures(none)) #2

declare void @llvm.lifetime.end.p0(ptr captures(none)) #2

define private range(i64 -2, -4611686018427387906) i64 @base64.decode_base_64(ptr nonnull writeonly captures(none) %0, i64 %1, ptr nonnull readonly captures(none) %2, i64 %3) unnamed_addr #0 align 1 {
4:
  %.sroa.0237.i = alloca i8, align 1
  %.sroa.0234.i = alloca i16, align 2
  %5 = and i64 %3, 3
  %.not.i.i = icmp eq i64 %5, 0
  tail call void @llvm.assume(i1 %.not.i.i)
  %6 = lshr exact i64 %3, 2
  %7 = mul nuw i64 %6, 3
  %.not20.i = icmp eq i64 %3, 0
  br i1 %.not20.i, label %17, label %.critedge.i
.critedge.i:
  %8 = getelementptr [1 x i8], ptr %2, i64 %3
  %9 = getelementptr i8, ptr %8, i64 -1
  %10 = load i8, ptr %9, align 1, !noalias !0
  %11 = icmp eq i8 %10, 61
  %12 = sext i1 %11 to i64
  %spec.select.i = add i64 %7, %12
  %13 = getelementptr i8, ptr %8, i64 -2
  %14 = load i8, ptr %13, align 1, !noalias !0
  %15 = icmp eq i8 %14, 61
  %16 = sext i1 %15 to i64
  %spec.select21.i = add i64 %spec.select.i, %16
  br label %17
17:
  %.sroa.0.0.ph = phi i64 [ %spec.select21.i, %.critedge.i ], [ %7, %4 ]
  call void @llvm.lifetime.start.p0(ptr nonnull %.sroa.0237.i)
  call void @llvm.lifetime.start.p0(ptr nonnull %.sroa.0234.i)
  store i12 0, ptr %.sroa.0234.i, align 2
  store i4 0, ptr %.sroa.0237.i, align 1
  br label %18
18:
  %indvars.iv.i = phi i64 [ %indvars.iv.next.i, %121 ], [ %3, %17 ]
  %.0304.i = phi i64 [ %19, %121 ], [ 0, %17 ]
  %.0303.i = phi i64 [ %132, %121 ], [ 0, %17 ]
  %19 = add nuw i64 %.0304.i, 16
  %20 = icmp ult i64 %19, %3
  %21 = add nuw i64 %.0303.i, 15
  %22 = icmp ult i64 %21, %.sroa.0.0.ph
  %23 = select i1 %20, i1 %22, i1 0
  br i1 %23, label %24, label %.preheader.i
24:
  %25 = getelementptr [1 x i8], ptr %2, i64 %.0304.i
  %26 = load i8, ptr %25, align 1
  %27 = zext i8 %26 to i64
  %28 = getelementptr [4 x i8], ptr @__anon_1321, i64 %27
  %29 = load i32, ptr %28, align 4
  %30 = getelementptr i8, ptr %25, i64 1
  %31 = load i8, ptr %30, align 1
  %32 = zext i8 %31 to i64
  %33 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 1024), i64 %32
  %34 = load i32, ptr %33, align 4
  %35 = or i32 %34, %29
  %36 = getelementptr i8, ptr %25, i64 2
  %37 = load i8, ptr %36, align 1
  %38 = zext i8 %37 to i64
  %39 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 2048), i64 %38
  %40 = load i32, ptr %39, align 4
  %41 = or i32 %35, %40
  %42 = getelementptr i8, ptr %25, i64 3
  %43 = load i8, ptr %42, align 1
  %44 = zext i8 %43 to i64
  %45 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 3072), i64 %44
  %46 = load i32, ptr %45, align 4
  %47 = or i32 %41, %46
  %48 = zext i32 %47 to i128
  %.not320.i = icmp ult i32 %47, 16777216
  br i1 %.not320.i, label %49, label %base64.Base64Decoder.decode.exit
49:
  %50 = getelementptr i8, ptr %25, i64 4
  %51 = load i8, ptr %50, align 1
  %52 = zext i8 %51 to i64
  %53 = getelementptr [4 x i8], ptr @__anon_1321, i64 %52
  %54 = load i32, ptr %53, align 4
  %55 = getelementptr i8, ptr %25, i64 5
  %56 = load i8, ptr %55, align 1
  %57 = zext i8 %56 to i64
  %58 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 1024), i64 %57
  %59 = load i32, ptr %58, align 4
  %60 = or i32 %59, %54
  %61 = getelementptr i8, ptr %25, i64 6
  %62 = load i8, ptr %61, align 1
  %63 = zext i8 %62 to i64
  %64 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 2048), i64 %63
  %65 = load i32, ptr %64, align 4
  %66 = or i32 %60, %65
  %67 = getelementptr i8, ptr %25, i64 7
  %68 = load i8, ptr %67, align 1
  %69 = zext i8 %68 to i64
  %70 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 3072), i64 %69
  %71 = load i32, ptr %70, align 4
  %72 = or i32 %66, %71
  %.not321.i = icmp ult i32 %72, 16777216
  br i1 %.not321.i, label %73, label %base64.Base64Decoder.decode.exit
73:
  %74 = getelementptr i8, ptr %25, i64 8
  %75 = load i8, ptr %74, align 1
  %76 = zext i8 %75 to i64
  %77 = getelementptr [4 x i8], ptr @__anon_1321, i64 %76
  %78 = load i32, ptr %77, align 4
  %79 = getelementptr i8, ptr %25, i64 9
  %80 = load i8, ptr %79, align 1
  %81 = zext i8 %80 to i64
  %82 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 1024), i64 %81
  %83 = load i32, ptr %82, align 4
  %84 = or i32 %83, %78
  %85 = getelementptr i8, ptr %25, i64 10
  %86 = load i8, ptr %85, align 1
  %87 = zext i8 %86 to i64
  %88 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 2048), i64 %87
  %89 = load i32, ptr %88, align 4
  %90 = or i32 %84, %89
  %91 = getelementptr i8, ptr %25, i64 11
  %92 = load i8, ptr %91, align 1
  %93 = zext i8 %92 to i64
  %94 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 3072), i64 %93
  %95 = load i32, ptr %94, align 4
  %96 = or i32 %90, %95
  %.not322.i = icmp ult i32 %96, 16777216
  br i1 %.not322.i, label %97, label %base64.Base64Decoder.decode.exit
97:
  %98 = getelementptr i8, ptr %25, i64 12
  %99 = load i8, ptr %98, align 1
  %100 = zext i8 %99 to i64
  %101 = getelementptr [4 x i8], ptr @__anon_1321, i64 %100
  %102 = load i32, ptr %101, align 4
  %103 = getelementptr i8, ptr %25, i64 13
  %104 = load i8, ptr %103, align 1
  %105 = zext i8 %104 to i64
  %106 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 1024), i64 %105
  %107 = load i32, ptr %106, align 4
  %108 = or i32 %107, %102
  %109 = getelementptr i8, ptr %25, i64 14
  %110 = load i8, ptr %109, align 1
  %111 = zext i8 %110 to i64
  %112 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 2048), i64 %111
  %113 = load i32, ptr %112, align 4
  %114 = or i32 %108, %113
  %115 = getelementptr i8, ptr %25, i64 15
  %116 = load i8, ptr %115, align 1
  %117 = zext i8 %116 to i64
  %118 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 3072), i64 %117
  %119 = load i32, ptr %118, align 4
  %120 = or i32 %114, %119
  %.not323.i = icmp ult i32 %120, 16777216
  br i1 %.not323.i, label %121, label %base64.Base64Decoder.decode.exit
121:
  %122 = zext nneg i32 %120 to i128
  %123 = zext nneg i32 %72 to i128
  %124 = shl nsw nuw i128 %123, 24
  %125 = or disjoint i128 %124, %48
  %126 = zext nneg i32 %96 to i128
  %127 = shl nsw nuw i128 %126, 48
  %128 = or disjoint i128 %125, %127
  %129 = shl nsw nuw i128 %122, 72
  %130 = or disjoint i128 %128, %129
  %131 = getelementptr [1 x i8], ptr %0, i64 %.0303.i
  store i128 %130, ptr %131, align 1
  %132 = add nuw i64 %.0303.i, 12
  %indvars.iv.next.i = add i64 %indvars.iv.i, -16
  br label %18
.preheader.i:
  %indvars.iv345.i = phi i64 [ %indvars.iv.next346.i, %164 ], [ %indvars.iv.i, %18 ]
  %.1305.i = phi i64 [ %133, %164 ], [ %.0304.i, %18 ]
  %.1.i = phi i64 [ %135, %164 ], [ %.0303.i, %18 ]
  %133 = add nuw i64 %.1305.i, 4
  %134 = icmp ult i64 %133, %3
  %135 = add nuw i64 %.1.i, 3
  %136 = icmp ult i64 %135, %.sroa.0.0.ph
  %137 = select i1 %134, i1 %136, i1 0
  %138 = getelementptr [1 x i8], ptr %2, i64 %.1305.i
  br i1 %137, label %139, label %162
139:
  %140 = load i8, ptr %138, align 1
  %141 = zext i8 %140 to i64
  %142 = getelementptr [4 x i8], ptr @__anon_1321, i64 %141
  %143 = load i32, ptr %142, align 4
  %144 = getelementptr i8, ptr %138, i64 1
  %145 = load i8, ptr %144, align 1
  %146 = zext i8 %145 to i64
  %147 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 1024), i64 %146
  %148 = load i32, ptr %147, align 4
  %149 = or i32 %148, %143
  %150 = getelementptr i8, ptr %138, i64 2
  %151 = load i8, ptr %150, align 1
  %152 = zext i8 %151 to i64
  %153 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 2048), i64 %152
  %154 = load i32, ptr %153, align 4
  %155 = or i32 %149, %154
  %156 = getelementptr i8, ptr %138, i64 3
  %157 = load i8, ptr %156, align 1
  %158 = zext i8 %157 to i64
  %159 = getelementptr [4 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 3072), i64 %158
  %160 = load i32, ptr %159, align 4
  %161 = or i32 %155, %160
  %.not319.i = icmp ult i32 %161, 16777216
  br i1 %.not319.i, label %164, label %base64.Base64Decoder.decode.exit
162:
  %163 = sub nuw i64 %3, %.1305.i
  br label %168
164:
  %165 = getelementptr [1 x i8], ptr %0, i64 %.1.i
  store i32 %161, ptr %165, align 1
  %indvars.iv.next346.i = add i64 %indvars.iv345.i, -4
  br label %.preheader.i
.loopexit.i:
  %.0302.i22 = phi i64 [ %.0302.i, %185 ], [ %indvars.iv345.i, %168 ]
  %.sroa.0282.0.i = phi i64 [ %186, %185 ], [ undef, %168 ]
  %.sroa.0237.i.0..sroa.0237.i.0..sroa.0237.i.0..sroa.0237.0..sroa.0237.0..sroa.0237.0..sroa.0237.0..i = load i8, ptr %.sroa.0237.i, align 1
  %166 = trunc i8 %.sroa.0237.i.0..sroa.0237.i.0..sroa.0237.i.0..sroa.0237.0..sroa.0237.0..sroa.0237.0..sroa.0237.0..i to i4
  %167 = icmp ugt i4 %166, 4
  br i1 %167, label %base64.Base64Decoder.decode.exit, label %197
168:
  %.2.i = phi i64 [ %.1.i, %162 ], [ %.3.i, %187 ]
  %.0302.i = phi i64 [ 0, %162 ], [ %188, %187 ]
  %exitcond.i = icmp eq i64 %.0302.i, %indvars.iv345.i
  br i1 %exitcond.i, label %.loopexit.i, label %169
169:
  %170 = getelementptr [1 x i8], ptr %138, i64 %.0302.i
  %171 = load i8, ptr %170, align 1
  %172 = zext i8 %171 to i64
  %173 = getelementptr [1 x i8], ptr getelementptr inbounds nuw (i8, ptr @__anon_1321, i64 4096), i64 %172
  %174 = load i8, ptr %173, align 1
  %175 = icmp eq i8 %174, -1
  br i1 %175, label %185, label %176
176:
  %.sroa.0234.i.0..sroa.0234.i.0..sroa.0234.i.0..sroa.0234.0..sroa.0234.0..sroa.0234.0..sroa.0234.0..i = load i16, ptr %.sroa.0234.i, align 2
  %177 = trunc i16 %.sroa.0234.i.0..sroa.0234.i.0..sroa.0234.i.0..sroa.0234.0..sroa.0234.0..sroa.0234.0..sroa.0234.0..i to i12
  %178 = shl i12 %177, 6
  %179 = zext i8 %174 to i12
  %180 = add nuw i12 %178, %179
  store i12 %180, ptr %.sroa.0234.i, align 2
  %.sroa.0237.i.0..sroa.0237.i.0..sroa.0237.i.0..sroa.0237.0..sroa.0237.0..sroa.0237.0..sroa.0237.0.238.i = load i8, ptr %.sroa.0237.i, align 1
  %181 = trunc i8 %.sroa.0237.i.0..sroa.0237.i.0..sroa.0237.i.0..sroa.0237.0..sroa.0237.0..sroa.0237.0..sroa.0237.0.238.i to i4
  %182 = add nuw i4 %181, 6
  store i4 %182, ptr %.sroa.0237.i, align 1
  %.sroa.0237.i.0..sroa.0237.i.0..sroa.0237.i.0..sroa.0237.0..sroa.0237.0..sroa.0237.0..sroa.0237.0.239.i = load i8, ptr %.sroa.0237.i, align 1
  %183 = trunc i8 %.sroa.0237.i.0..sroa.0237.i.0..sroa.0237.i.0..sroa.0237.0..sroa.0237.0..sroa.0237.0..sroa.0237.0.239.i to i4
  %184 = icmp slt i4 %183, 0
  br i1 %184, label %189, label %187
185:
  %186 = add nuw i64 %.0302.i, %.1305.i
  %.not313.i = icmp eq i8 %171, 61
  br i1 %.not313.i, label %.loopexit.i, label %base64.Base64Decoder.decode.exit
187:
  %.3.i = phi i64 [ %196, %189 ], [ %.2.i, %176 ]
  %188 = add nuw i64 %.0302.i, 1
  br label %168
189:
  %190 = and i4 %183, 7
  store i4 %190, ptr %.sroa.0237.i, align 1
  %191 = getelementptr [1 x i8], ptr %0, i64 %.2.i
  %.sroa.0234.i.0..sroa.0234.i.0..sroa.0234.i.0..sroa.0234.0..sroa.0234.0..sroa.0234.0..sroa.0234.0.235.i = load i16, ptr %.sroa.0234.i, align 2
  %192 = trunc i16 %.sroa.0234.i.0..sroa.0234.i.0..sroa.0234.i.0..sroa.0234.0..sroa.0234.0..sroa.0234.0..sroa.0234.0.235.i to i12
  %.sroa.0237.i.0..sroa.0237.i.0..sroa.0237.i.0..sroa.0237.0..sroa.0237.0..sroa.0237.0..sroa.0237.0.241.i = load i8, ptr %.sroa.0237.i, align 1
  %.mask.i = and i8 %.sroa.0237.i.0..sroa.0237.i.0..sroa.0237.i.0..sroa.0237.0..sroa.0237.0..sroa.0237.0..sroa.0237.0.241.i, 15
  %193 = zext nneg i8 %.mask.i to i12
  %194 = lshr i12 %192, %193
  %195 = trunc i12 %194 to i8
  store i8 %195, ptr %191, align 1
  %196 = add nuw i64 %.2.i, 1
  br label %187
197:
  %.not316.not361.i = icmp uge i64 %.0302.i22, %163
  %.sroa.0234.i.0..sroa.0234.i.0..sroa.0234.i.0..sroa.0234.0..sroa.0234.0..sroa.0234.0..sroa.0234.0.236.i = load i16, ptr %.sroa.0234.i, align 2
  %198 = trunc i16 %.sroa.0234.i.0..sroa.0234.i.0..sroa.0234.i.0..sroa.0234.0..sroa.0234.0..sroa.0234.0..sroa.0234.0.236.i to i12
  %.mask314.i = and i8 %.sroa.0237.i.0..sroa.0237.i.0..sroa.0237.i.0..sroa.0237.0..sroa.0237.0..sroa.0237.0..sroa.0237.0..i, 7
  %199 = zext nneg i8 %.mask314.i to i12
  %notmask.i = shl nsw i12 -1, %199
  %200 = xor i12 %notmask.i, -1
  %201 = and i12 %198, %200
  %.not315.i = icmp ne i12 %201, 0
  %brmerge.i = or i1 %.not316.not361.i, %.not315.i
  br i1 %brmerge.i, label %base64.Base64Decoder.decode.exit, label %202
202:
  %203 = getelementptr [1 x i8], ptr %2, i64 %.sroa.0282.0.i
  %204 = sub nuw i64 %3, %.sroa.0282.0.i
  br label %205
205:
  %.0301.i = phi i64 [ 0, %202 ], [ %209, %206 ]
  %exitcond348.not.i = icmp eq i64 %.0301.i, %204
  br i1 %exitcond348.not.i, label %base64.Base64Decoder.decode.exit, label %206
206:
  %207 = getelementptr [1 x i8], ptr %203, i64 %.0301.i
  %208 = load i8, ptr %207, align 1
  %.not318.i = icmp eq i8 %208, 61
  %209 = add i64 %.0301.i, 1
  br i1 %.not318.i, label %205, label %base64.Base64Decoder.decode.exit
base64.Base64Decoder.decode.exit:
  call void @llvm.lifetime.end.p0(ptr nonnull %.sroa.0237.i)
  call void @llvm.lifetime.end.p0(ptr nonnull %.sroa.0234.i)
  ret i64 %.sroa.0.0.ph
}

attributes #0 = { minsize nofree norecurse nosync nounwind optsize memory(argmem: readwrite, inaccessiblemem: write) uwtable "frame-pointer"="all" "target-cpu"="x86-64" "target-features"="+64bit,+cmov,+cx8,+fxsr,+idivq-to-divl,+macrofusion,+mmx,+nopl,+slow-3ops-lea,+slow-incdec,+sse,+sse2,+vzeroupper,+x87,-16bit-mode,-32bit-mode,-adx,-aes,-allow-light-256-bit,-amx-avx512,-amx-bf16,-amx-complex,-amx-fp16,-amx-fp8,-amx-int8,-amx-movrs,-amx-tf32,-amx-tile,-avx,-avx10.1,-avx10.2,-avx2,-avx512bf16,-avx512bitalg,-avx512bw,-avx512cd,-avx512dq,-avx512f,-avx512fp16,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vl,-avx512vnni,-avx512vp2intersect,-avx512vpopcntdq,-avxifma,-avxneconvert,-avxvnni,-avxvnniint16,-avxvnniint8,-bmi,-bmi2,-branch-hint,-branchfusion,-ccmp,-cf,-cldemote,-clflushopt,-clwb,-clzero,-cmpccxadd,-crc32,-cx16,-egpr,-enqcmd,-ermsb,-f16c,-false-deps-getmant,-false-deps-lzcnt-tzcnt,-false-deps-mulc,-false-deps-mullq,-false-deps-perm,-false-deps-popcnt,-false-deps-range,-fast-11bytenop,-fast-15bytenop,-fast-7bytenop,-fast-bextr,-fast-dpwssd,-fast-gather,-fast-hops,-fast-imm16,-fast-lzcnt,-fast-movbe,-fast-scalar-fsqrt,-fast-scalar-shift-masks,-fast-shld-rotate,-fast-variable-crosslane-shuffle,-fast-variable-perlane-shuffle,-fast-vector-fsqrt,-fast-vector-shift-masks,-faster-shift-than-shuffle,-fma,-fma4,-fsgsbase,-fsrm,-gfni,-harden-sls-ijmp,-harden-sls-ret,-hreset,-idivl-to-divb,-inline-asm-use-gpr32,-invpcid,-kl,-lea-sp,-lea-uses-ag,-lvi-cfi,-lvi-load-hardening,-lwp,-lzcnt,-movbe,-movdir64b,-movdiri,-movrs,-mwaitx,-ndd,-nf,-no-bypass-delay,-no-bypass-delay-blend,-no-bypass-delay-mov,-no-bypass-delay-shuffle,-pad-short-functions,-pclmul,-pconfig,-pku,-popcnt,-ppx,-prefer-128-bit,-prefer-256-bit,-prefer-legacy-setcc,-prefer-mask-registers,-prefer-movmsk-over-vtest,-prefer-no-gather,-prefer-no-scatter,-prefetchi,-prfchw,-ptwrite,-push2pop2,-raoint,-rdpid,-rdpru,-rdrnd,-rdseed,-retpoline,-retpoline-external-thunk,-retpoline-indirect-branches,-retpoline-indirect-calls,-rtm,-sahf,-sbb-dep-breaking,-serialize,-seses,-sgx,-sha,-sha512,-shstk,-slow-lea,-slow-pmaddwd,-slow-pmulld,-slow-pmullq,-slow-shld,-slow-two-mem-ops,-slow-unaligned-mem-16,-slow-unaligned-mem-32,-sm3,-sm4,-soft-float,-sse3,-sse4.1,-sse4.2,-sse4a,-sse-unaligned-mem,-ssse3,-tagged-globals,-tbm,-tsxldtrk,-tuning-fast-imm-vector-shift,-uintr,-use-glm-div-sqrt-costs,-use-slm-arith-costs,-usermsr,-vaes,-vpclmulqdq,-waitpkg,-wbnoinvd,-widekl,-xop,-xsave,-xsavec,-xsaveopt,-xsaves,-zu" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }

!llvm.module.flags = !{}
!0 = !{!1}
!1 = distinct !{!1, !2, !"base64.Base64Decoder.calcSizeForSlice: argument 0"}
!2 = distinct !{!2, !"base64.Base64Decoder.calcSizeForSlice"}
