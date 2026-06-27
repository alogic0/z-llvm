#include <sys/wait.h>
#include <unistd.h>

extern int z_frontier_checked_add(int) __asm__("frontier_safety_edges.frontier_checked_add");
extern unsigned z_frontier_checked_uadd(unsigned) __asm__("frontier_safety_edges.frontier_checked_uadd");
extern int z_frontier_explicit_sadd_overflow(int) __asm__("frontier_safety_edges.frontier_explicit_sadd_overflow");
extern unsigned z_frontier_explicit_uadd_overflow(unsigned) __asm__("frontier_safety_edges.frontier_explicit_uadd_overflow");
extern int z_frontier_bounds_guard(const int *, unsigned long, unsigned long) __asm__("frontier_safety_edges.frontier_bounds_guard");
extern int z_frontier_bounds_direct(const int *, unsigned long) __asm__("frontier_safety_edges.frontier_bounds_direct");
extern int z_frontier_bounds_panic(const int *, unsigned long, unsigned long) __asm__("frontier_safety_edges.frontier_bounds_panic");
extern int z_frontier_guard_return_else(const int *, unsigned long, unsigned long) __asm__("frontier_safety_edges.frontier_guard_return_else");
extern int z_frontier_optional_unwrap(int, const int *) __asm__("frontier_safety_edges.frontier_optional_unwrap");
extern int z_frontier_int_from_float_checked(float) __asm__("frontier_safety_edges.frontier_int_from_float_checked");
extern int z_frontier_panic_param_len(int, unsigned long) __asm__("frontier_safety_edges.frontier_panic_param_len");
extern int z_frontier_panic_computed_len(int, unsigned long) __asm__("frontier_safety_edges.frontier_panic_computed_len");
extern int z_frontier_panic_loaded_len(int) __asm__("frontier_safety_edges.frontier_panic_loaded_len");
extern int z_frontier_panic_phi_len(int, int, unsigned long, unsigned long) __asm__("frontier_safety_edges.frontier_panic_phi_len");
extern int z_frontier_panic_loaded_ptr(int, unsigned long) __asm__("frontier_safety_edges.frontier_panic_loaded_ptr");
unsigned long z_frontier_runtime_panic_len __asm__("frontier_safety_edges.frontier_runtime_panic_len") = 23;
static const unsigned char z_frontier_loaded_panic_payload[] = "frontier loaded pointer panic payload";
const unsigned char *z_frontier_runtime_panic_ptr __asm__("frontier_safety_edges.frontier_runtime_panic_ptr") = z_frontier_loaded_panic_payload;
void z_frontier_safety_out_of_bounds(void) __asm__("frontier_safety_edges.outOfBounds");
void z_frontier_safety_out_of_bounds(void) { __builtin_trap(); }
void z_frontier_safety_int_part_oob(void) __asm__("frontier_safety_edges.integerPartOutOfBounds");
void z_frontier_safety_int_part_oob(void) { __builtin_trap(); }
void z_frontier_safety_unwrap_null(void) __asm__("frontier_safety_edges.unwrapNull");
void z_frontier_safety_unwrap_null(void) { __builtin_trap(); }
void z_frontier_safety_default_panic(const unsigned char *ptr, unsigned long len) __asm__("debug.defaultPanic");
void z_frontier_safety_default_panic(const unsigned char *ptr, unsigned long len) { (void)ptr; (void)len; __builtin_trap(); }
static int expect_death(void (*fn)(void)) {
    int status = 0;
    pid_t pid = fork();
    if (pid < 0) return 100;
    if (pid == 0) {
        fn();
        _exit(101);
    }
    if (waitpid(pid, &status, 0) < 0) return 102;
    return WIFSIGNALED(status) ? 0 : 103;
}
static void death_panic_param(void) { (void)z_frontier_panic_param_len(0, 11); }
static void death_panic_computed(void) { (void)z_frontier_panic_computed_len(0, 5); }
static void death_panic_loaded(void) { (void)z_frontier_panic_loaded_len(0); }
static void death_panic_phi_left(void) { (void)z_frontier_panic_phi_len(0, 1, 13, 17); }
static void death_panic_phi_right(void) { (void)z_frontier_panic_phi_len(0, 0, 13, 17); }
static void death_panic_loaded_ptr(void) { (void)z_frontier_panic_loaded_ptr(0, 19); }
static void death_explicit_sadd_overflow(void) { (void)z_frontier_explicit_sadd_overflow(2147483640); }
static void death_explicit_uadd_overflow(void) { (void)z_frontier_explicit_uadd_overflow(4294967290u); }
#ifdef ZLLVM_HARNESS_MODE_ReleaseSafe
static void death_bounds_panic(void) { int values[1] = { 7 }; (void)z_frontier_bounds_panic(values, 1, 2); }
static void death_optional_unwrap(void) { int value = 41; (void)z_frontier_optional_unwrap(0, &value); }
static void death_int_from_float(void) { (void)z_frontier_int_from_float_checked(2147483648.0f); }
#endif
int main(void) {
    int value = 41;
    int values[3] = { 11, 41, 77 };
    if (z_frontier_checked_add(5) != 16) return 1;
    if (z_frontier_checked_uadd(5u) != 24u) return 2;
    if (z_frontier_explicit_sadd_overflow(5) != 16) return 20;
    if (z_frontier_explicit_uadd_overflow(5u) != 24u) return 21;
    if (z_frontier_bounds_guard(&value, 1, 0) != 41) return 3;
    if (z_frontier_bounds_direct(values, 2) != 77) return 4;
    if (z_frontier_bounds_panic(values, 3, 2) != 77) return 22;
    if (z_frontier_guard_return_else(values, 3, 1) != 41) return 5;
    if (z_frontier_guard_return_else(values, 3, 3) != -1) return 6;
    if (z_frontier_optional_unwrap(1, &value) != 41) return 7;
    if (z_frontier_int_from_float_checked(12.0f) != 12) return 8;
    if (z_frontier_panic_param_len(1, 11) != 91) return 9;
    if (z_frontier_panic_computed_len(1, 5) != 92) return 10;
    if (z_frontier_panic_loaded_len(1) != 93) return 11;
    if (z_frontier_panic_phi_len(1, 1, 13, 17) != 94) return 23;
    if (z_frontier_panic_loaded_ptr(1, 19) != 95) return 24;
    if (expect_death(death_panic_param) != 0) return 12;
    if (expect_death(death_panic_computed) != 0) return 13;
    if (expect_death(death_panic_loaded) != 0) return 14;
    if (expect_death(death_panic_phi_left) != 0) return 25;
    if (expect_death(death_panic_phi_right) != 0) return 26;
    if (expect_death(death_panic_loaded_ptr) != 0) return 27;
    if (expect_death(death_explicit_sadd_overflow) != 0) return 15;
    if (expect_death(death_explicit_uadd_overflow) != 0) return 16;
#ifdef ZLLVM_HARNESS_MODE_ReleaseSafe
    if (expect_death(death_bounds_panic) != 0) return 17;
    if (expect_death(death_optional_unwrap) != 0) return 18;
    if (expect_death(death_int_from_float) != 0) return 19;
#endif
    return 0;
}

