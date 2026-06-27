extern float z_frontier_mixed_float(float, float) __asm__("frontier_mixed_numeric.frontier_mixed_float");
extern double z_frontier_double_roundtrip(double, double) __asm__("frontier_mixed_numeric.frontier_double_roundtrip");
extern float z_frontier_i32_to_f32_add(int, float) __asm__("frontier_mixed_numeric.frontier_i32_to_f32_add");
extern float z_frontier_i32_to_f32_mul_add(int, float, float) __asm__("frontier_mixed_numeric.frontier_i32_to_f32_mul_add");
extern double z_frontier_i32_to_f64_mul_add(int, double, double) __asm__("frontier_mixed_numeric.frontier_i32_to_f64_mul_add");
int main(void) {
    if (z_frontier_mixed_float(1.5f, 2.25f) != 3.75f) return 1;
    if (z_frontier_double_roundtrip(9.0, 2.0) != 4.5) return 2;
    if (z_frontier_i32_to_f32_add(4, 1.5f) != 5.5f) return 3;
    if (z_frontier_i32_to_f32_mul_add(3, 2.0f, 1.25f) != 7.25f) return 4;
    if (z_frontier_i32_to_f64_mul_add(4, 2.5, 0.5) != 10.5) return 5;
    return 0;
}

