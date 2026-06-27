#include <sys/wait.h>
#include <unistd.h>
extern float z_expanded_float_from_int(int) __asm__("expanded_numeric_casts.expanded_float_from_int");
extern double z_expanded_double_from_unsigned(unsigned) __asm__("expanded_numeric_casts.expanded_double_from_unsigned");
extern int z_expanded_int_from_float(float) __asm__("expanded_numeric_casts.expanded_int_from_float");
extern float z_expanded_float_narrow(double) __asm__("expanded_numeric_casts.expanded_float_narrow");
extern double z_expanded_double_widen(float) __asm__("expanded_numeric_casts.expanded_double_widen");
void z_expanded_int_from_float_oob(void) __asm__("expanded_numeric_casts.integerPartOutOfBounds");
void z_expanded_int_from_float_oob(void) { __builtin_trap(); }
#ifdef ZLLVM_HARNESS_MODE_ReleaseSafe
static int expect_out_of_range_trap(float value) {
    pid_t child = fork();
    if (child < 0) return -1;
    if (child == 0) {
        (void)z_expanded_int_from_float(value);
        _exit(0);
    }
    int status = 0;
    if (waitpid(child, &status, 0) != child) return -1;
    if (!WIFSIGNALED(status)) return -1;
    return 0;
}
#endif
int main(void) {
    if (z_expanded_float_from_int(-7) != -7.0f) return 1;
    if (z_expanded_double_from_unsigned(3000000000u) != 3000000000.0) return 2;
    if (z_expanded_int_from_float(41.75f) != 41) return 3;
    if (z_expanded_int_from_float(-2.5f) != -2) return 4;
    if (z_expanded_float_narrow(1.5) != 1.5f) return 5;
    if (z_expanded_double_widen(2.25f) != 2.25) return 6;
#ifdef ZLLVM_HARNESS_MODE_ReleaseSafe
    if (expect_out_of_range_trap(3000000000.0f) != 0) return 7;
    if (expect_out_of_range_trap(-3000000000.0f) != 0) return 8;
#endif
    return 0;
}

