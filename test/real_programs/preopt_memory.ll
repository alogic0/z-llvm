target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"
@preopt_table = private constant [16 x double] [double 1.25, double 2.5, double 3.75, double 5.0, double 6.25, double 7.5, double 8.75, double 10.0, double 11.25, double 12.5, double 13.75, double 15.0, double 16.25, double 17.5, double 18.75, double 20.0], align 8
declare void @preopt_mutate(ptr)
@preopt_pairs = private constant [512 x double] [double 1.25, double 2.50, double 3.75, double 5.00, double 6.25, double 7.50, double 8.75, double 10.00, double 11.25, double 12.50, double 13.75, double 15.00, double 16.25, double 17.50, double 18.75, double 20.00, double 21.25, double 22.50, double 23.75, double 25.00, double 26.25, double 27.50, double 28.75, double 30.00, double 31.25, double 32.50, double 33.75, double 35.00, double 36.25, double 37.50, double 38.75, double 40.00, double 41.25, double 42.50, double 43.75, double 45.00, double 46.25, double 47.50, double 48.75, double 50.00, double 51.25, double 52.50, double 53.75, double 55.00, double 56.25, double 57.50, double 58.75, double 60.00, double 61.25, double 62.50, double 63.75, double 65.00, double 66.25, double 67.50, double 68.75, double 70.00, double 71.25, double 72.50, double 73.75, double 75.00, double 76.25, double 77.50, double 78.75, double 80.00, double 81.25, double 82.50, double 83.75, double 85.00, double 86.25, double 87.50, double 88.75, double 90.00, double 91.25, double 92.50, double 93.75, double 95.00, double 96.25, double 97.50, double 98.75, double 100.00, double 101.25, double 102.50, double 103.75, double 105.00, double 106.25, double 107.50, double 108.75, double 110.00, double 111.25, double 112.50, double 113.75, double 115.00, double 116.25, double 117.50, double 118.75, double 120.00, double 121.25, double 122.50, double 123.75, double 125.00, double 126.25, double 127.50, double 128.75, double 130.00, double 131.25, double 132.50, double 133.75, double 135.00, double 136.25, double 137.50, double 138.75, double 140.00, double 141.25, double 142.50, double 143.75, double 145.00, double 146.25, double 147.50, double 148.75, double 150.00, double 151.25, double 152.50, double 153.75, double 155.00, double 156.25, double 157.50, double 158.75, double 160.00, double 161.25, double 162.50, double 163.75, double 165.00, double 166.25, double 167.50, double 168.75, double 170.00, double 171.25, double 172.50, double 173.75, double 175.00, double 176.25, double 177.50, double 178.75, double 180.00, double 181.25, double 182.50, double 183.75, double 185.00, double 186.25, double 187.50, double 188.75, double 190.00, double 191.25, double 192.50, double 193.75, double 195.00, double 196.25, double 197.50, double 198.75, double 200.00, double 201.25, double 202.50, double 203.75, double 205.00, double 206.25, double 207.50, double 208.75, double 210.00, double 211.25, double 212.50, double 213.75, double 215.00, double 216.25, double 217.50, double 218.75, double 220.00, double 221.25, double 222.50, double 223.75, double 225.00, double 226.25, double 227.50, double 228.75, double 230.00, double 231.25, double 232.50, double 233.75, double 235.00, double 236.25, double 237.50, double 238.75, double 240.00, double 241.25, double 242.50, double 243.75, double 245.00, double 246.25, double 247.50, double 248.75, double 250.00, double 251.25, double 252.50, double 253.75, double 255.00, double 256.25, double 257.50, double 258.75, double 260.00, double 261.25, double 262.50, double 263.75, double 265.00, double 266.25, double 267.50, double 268.75, double 270.00, double 271.25, double 272.50, double 273.75, double 275.00, double 276.25, double 277.50, double 278.75, double 280.00, double 281.25, double 282.50, double 283.75, double 285.00, double 286.25, double 287.50, double 288.75, double 290.00, double 291.25, double 292.50, double 293.75, double 295.00, double 296.25, double 297.50, double 298.75, double 300.00, double 301.25, double 302.50, double 303.75, double 305.00, double 306.25, double 307.50, double 308.75, double 310.00, double 311.25, double 312.50, double 313.75, double 315.00, double 316.25, double 317.50, double 318.75, double 320.00, double 321.25, double 322.50, double 323.75, double 325.00, double 326.25, double 327.50, double 328.75, double 330.00, double 331.25, double 332.50, double 333.75, double 335.00, double 336.25, double 337.50, double 338.75, double 340.00, double 341.25, double 342.50, double 343.75, double 345.00, double 346.25, double 347.50, double 348.75, double 350.00, double 351.25, double 352.50, double 353.75, double 355.00, double 356.25, double 357.50, double 358.75, double 360.00, double 361.25, double 362.50, double 363.75, double 365.00, double 366.25, double 367.50, double 368.75, double 370.00, double 371.25, double 372.50, double 373.75, double 375.00, double 376.25, double 377.50, double 378.75, double 380.00, double 381.25, double 382.50, double 383.75, double 385.00, double 386.25, double 387.50, double 388.75, double 390.00, double 391.25, double 392.50, double 393.75, double 395.00, double 396.25, double 397.50, double 398.75, double 400.00, double 401.25, double 402.50, double 403.75, double 405.00, double 406.25, double 407.50, double 408.75, double 410.00, double 411.25, double 412.50, double 413.75, double 415.00, double 416.25, double 417.50, double 418.75, double 420.00, double 421.25, double 422.50, double 423.75, double 425.00, double 426.25, double 427.50, double 428.75, double 430.00, double 431.25, double 432.50, double 433.75, double 435.00, double 436.25, double 437.50, double 438.75, double 440.00, double 441.25, double 442.50, double 443.75, double 445.00, double 446.25, double 447.50, double 448.75, double 450.00, double 451.25, double 452.50, double 453.75, double 455.00, double 456.25, double 457.50, double 458.75, double 460.00, double 461.25, double 462.50, double 463.75, double 465.00, double 466.25, double 467.50, double 468.75, double 470.00, double 471.25, double 472.50, double 473.75, double 475.00, double 476.25, double 477.50, double 478.75, double 480.00, double 481.25, double 482.50, double 483.75, double 485.00, double 486.25, double 487.50, double 488.75, double 490.00, double 491.25, double 492.50, double 493.75, double 495.00, double 496.25, double 497.50, double 498.75, double 500.00, double 501.25, double 502.50, double 503.75, double 505.00, double 506.25, double 507.50, double 508.75, double 510.00, double 511.25, double 512.50, double 513.75, double 515.00, double 516.25, double 517.50, double 518.75, double 520.00, double 521.25, double 522.50, double 523.75, double 525.00, double 526.25, double 527.50, double 528.75, double 530.00, double 531.25, double 532.50, double 533.75, double 535.00, double 536.25, double 537.50, double 538.75, double 540.00, double 541.25, double 542.50, double 543.75, double 545.00, double 546.25, double 547.50, double 548.75, double 550.00, double 551.25, double 552.50, double 553.75, double 555.00, double 556.25, double 557.50, double 558.75, double 560.00, double 561.25, double 562.50, double 563.75, double 565.00, double 566.25, double 567.50, double 568.75, double 570.00, double 571.25, double 572.50, double 573.75, double 575.00, double 576.25, double 577.50, double 578.75, double 580.00, double 581.25, double 582.50, double 583.75, double 585.00, double 586.25, double 587.50, double 588.75, double 590.00, double 591.25, double 592.50, double 593.75, double 595.00, double 596.25, double 597.50, double 598.75, double 600.00, double 601.25, double 602.50, double 603.75, double 605.00, double 606.25, double 607.50, double 608.75, double 610.00, double 611.25, double 612.50, double 613.75, double 615.00, double 616.25, double 617.50, double 618.75, double 620.00, double 621.25, double 622.50, double 623.75, double 625.00, double 626.25, double 627.50, double 628.75, double 630.00, double 631.25, double 632.50, double 633.75, double 635.00, double 636.25, double 637.50, double 638.75, double 640.00], align 8

define { double, double } @preopt_pair_read(ptr %p) {
entry:
 %pair = load { double, double },ptr %p,align 1
 ret { double, double } %pair
}

define { double, double } @preopt_pair_snapshot(ptr %p) {
entry:
 %pair = load { double, double },ptr %p,align 1
 call void @preopt_mutate(ptr %p)
 ret { double, double } %pair
}

define double @preopt_table_private(i64 %input,i1 %choose) {
entry:
 %slot = alloca [2 x i32],align 8
 %masked = urem i64 %input,16
 %other = xor i64 %input,3
 %masked_other = and i64 %other,15
 br i1 %choose,label %left,label %right
left:
 store i64 %masked,ptr %slot,align 8
 br label %merge
right:
 store i64 %masked_other,ptr %slot,align 8
 br label %merge
merge:
 %index = load i64,ptr %slot,align 8
 %address = getelementptr [8 x i8],ptr @preopt_table,i64 %index
 %value = load double,ptr %address,align 8
 ret double %value
}

define double @preopt_table_wide(i128 %input) {
entry:
 %masked = and i128 %input,15
 %low = trunc i128 %masked to i64
 %identity = bitcast i64 %low to i64
 %address = getelementptr [8 x i8],ptr @preopt_table,i64 %identity
 %value = load double,ptr %address,align 8
 ret double %value
}

define double @preopt_table_pair(i32 %input) {
entry:
 %bounded = urem i32 %input,256
 %base = mul i32 %bounded,2
 %odd = add i32 %base,1
 %index = zext i32 %odd to i64
 %address = getelementptr [8 x i8],ptr @preopt_pairs,i64 %index
 %value = load double,ptr %address,align 8
 ret double %value
}

define double @preopt_table_roundtrip(i64 %input) {
entry:
 %slot = alloca double,align 8
 %index = and i64 %input,15
 %address = getelementptr [8 x i8],ptr @preopt_table,i64 %index
 %value = load double,ptr %address,align 8
 store double %value,ptr %slot,align 8
 %again = load double,ptr %slot,align 8
 %answer = fadd double %again,%value
 ret double %answer
}
