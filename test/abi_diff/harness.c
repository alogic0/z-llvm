#include <inttypes.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct result_bits { uint64_t lo, hi; };

extern uint64_t probe_negsi2(int32_t, struct result_bits *);
extern uint64_t probe_ashlsi3(int32_t, int32_t, struct result_bits *);
extern uint64_t probe_fabsh(_Float16, struct result_bits *);
extern uint64_t probe_neghf2(_Float16, struct result_bits *);
extern uint64_t probe_mulosi4(int32_t, int32_t, int *, struct result_bits *);
extern uint64_t probe_mulodi4(int64_t, int64_t, int *, struct result_bits *);
extern uint64_t probe_negti2(__int128, struct result_bits *);
extern uint64_t probe_ashlti3(__int128, int32_t, struct result_bits *);
extern uint64_t probe_fabs(double, struct result_bits *);
extern uint64_t probe_fmin(double, double, struct result_bits *);
extern uint64_t probe_negative_clobber(struct result_bits *);
extern void abi_negative_write(uint8_t *);
extern void abi_negative_timeout(void);
extern void abi_negative_signal(void);
extern void abi_diff_controlled_panic(void) __attribute__((weak));

static uint16_t f16_bits(_Float16 value) {
    uint16_t bits;
    __builtin_memcpy(&bits, &value, sizeof(bits));
    return bits;
}

static int emit(const char *id, uint64_t lo, uint64_t hi, uint64_t abi) {
    if (abi != 0) return 70;
    printf("case=%s lo=%016" PRIx64 " hi=%016" PRIx64
           " abi=%016" PRIx64 " term=normal\n", id, lo, hi, abi);
    return 0;
}

static int run_mulo_i32(const char *id, int32_t a, int32_t b) {
    struct result_bits r = {0, 0};
    struct {
        uint64_t left;
        int overflow;
        uint32_t right_pad;
        uint64_t right;
    } guarded = {0x13579bdf2468ace0ULL, 0x11223344, 0xa55aa55aU,
        0x0eca8642fdb97531ULL};
    const uint64_t abi = probe_mulosi4(a, b, &guarded.overflow, &r);
    if (guarded.left != 0x13579bdf2468ace0ULL ||
        guarded.right_pad != 0xa55aa55aU ||
        guarded.right != 0x0eca8642fdb97531ULL) return 71;
    if (guarded.overflow != 0 && guarded.overflow != 1) return 72;
    return emit(id, (uint32_t)r.lo, (uint32_t)guarded.overflow, abi);
}

static int run_mulo_i64(const char *id, int64_t a, int64_t b) {
    struct result_bits r = {0, 0};
    struct {
        uint64_t left;
        int overflow;
        uint32_t right_pad;
        uint64_t right;
    } guarded = {0x13579bdf2468ace0ULL, 0x11223344, 0xa55aa55aU,
        0x0eca8642fdb97531ULL};
    const uint64_t abi = probe_mulodi4(a, b, &guarded.overflow, &r);
    if (guarded.left != 0x13579bdf2468ace0ULL ||
        guarded.right_pad != 0xa55aa55aU ||
        guarded.right != 0x0eca8642fdb97531ULL) return 73;
    if (guarded.overflow != 0 && guarded.overflow != 1) return 74;
    return emit(id, r.lo, (uint32_t)guarded.overflow, abi);
}

static int run_case(unsigned index) {
    struct result_bits r = {0, 0};
    uint64_t abi;
    const __int128 wide = ((__int128)0x0123456789abcdefULL << 64) |
        (__int128)0x0edcba9876543210ULL;

    switch (index) {
    case 0:
        abi = probe_negsi2(0, &r);
        return emit("negsi2/zero", (uint32_t)r.lo, 0, abi);
    case 1:
        abi = probe_negsi2(1234567, &r);
        return emit("negsi2/positive", (uint32_t)r.lo, 0, abi);
    case 2:
        abi = probe_ashlsi3(0x1234567, 4, &r);
        return emit("ashlsi3/shift4", (uint32_t)r.lo, 0, abi);
    case 3:
        abi = probe_ashlsi3(-1, 17, &r);
        return emit("ashlsi3/negative", (uint32_t)r.lo, 0, abi);
    case 4: {
        const _Float16 value = (_Float16)-3.5;
        abi = probe_fabsh(value, &r);
        return emit("fabsh/negative", (uint16_t)r.lo, f16_bits(value), abi);
    }
    case 5: {
        const _Float16 value = (_Float16)-0.0;
        abi = probe_fabsh(value, &r);
        return emit("fabsh/negative-zero", (uint16_t)r.lo, f16_bits(value), abi);
    }
    case 6:
        abi = probe_neghf2((_Float16)-3.5, &r);
        return emit("neghf2/negative", (uint16_t)r.lo, 0, abi);
    case 7:
        abi = probe_neghf2((_Float16)0.0, &r);
        return emit("neghf2/positive-zero", (uint16_t)r.lo, 0, abi);
    case 8:
        return run_mulo_i32("mulosi4/exact", 12345, -17);
    case 9:
        return run_mulo_i32("mulosi4/overflow", INT32_MAX, 2);
    case 10:
        return run_mulo_i64("mulodi4/exact", 123456789, 17);
    case 11:
        return run_mulo_i64("mulodi4/overflow", INT64_MAX, 2);
    case 12:
        abi = probe_negti2(0, &r);
        return emit("negti2/zero", r.lo, r.hi, abi);
    case 13:
        abi = probe_negti2(wide, &r);
        return emit("negti2/mixed", r.lo, r.hi, abi);
    case 14:
        abi = probe_ashlti3(wide, 13, &r);
        return emit("ashlti3/shift13", r.lo, r.hi, abi);
    case 15:
        abi = probe_ashlti3((__int128)1, 64, &r);
        return emit("ashlti3/shift64", r.lo, r.hi, abi);
    case 16:
        abi = probe_fabs(-3.5, &r);
        return emit("fabs/negative", r.lo, 0, abi);
    case 17:
        abi = probe_fabs(-0.0, &r);
        return emit("fabs/negative-zero", r.lo, 0, abi);
    case 18:
        abi = probe_fmin(-3.5, 2.0, &r);
        return emit("fmin/ordered", r.lo, 0, abi);
    case 19:
        abi = probe_fmin(0.0, -0.0, &r);
        return emit("fmin/signed-zero", r.lo, 0, abi);
    default:
        return 64;
    }
}

int main(int argc, char **argv) {
    if (argc == 3 && strcmp(argv[1], "--case") == 0) {
        char *end = NULL;
        const unsigned long index = strtoul(argv[2], &end, 10);
        if (end == argv[2] || *end != '\0' || index >= 20) return 64;
        return run_case((unsigned)index);
    }
    if (argc == 2 && strcmp(argv[1], "--negative-clobber") == 0) {
        struct result_bits r = {0, 0};
        return probe_negative_clobber(&r) == 1 ? 0 : 31;
    }
    if (argc == 2 && strcmp(argv[1], "--negative-write") == 0) {
        uint8_t guarded[3] = {0xa5, 0x11, 0x5a};
        abi_negative_write(&guarded[1]);
        return guarded[0] != 0xa5 ? 0 : 32;
    }
    if (argc == 2 && strcmp(argv[1], "--negative-timeout") == 0) {
        abi_negative_timeout();
        return 33;
    }
    if (argc == 2 && strcmp(argv[1], "--negative-signal") == 0) {
        abi_negative_signal();
        return 34;
    }
    if (argc == 2 && strcmp(argv[1], "--controlled-panic") == 0) {
        if (abi_diff_controlled_panic == NULL) return 65;
        abi_diff_controlled_panic();
        return 35;
    }
    return 64;
}
