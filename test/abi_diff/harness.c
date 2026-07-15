#include <inttypes.h>
#include <limits.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct result_bits { uint64_t lo, hi; };

extern uint64_t probe_neg_u64(uint64_t, struct result_bits *);
extern uint64_t probe_select_i32(int32_t, int32_t, uint8_t, struct result_bits *);
extern uint64_t probe_identity_u8(uint8_t, struct result_bits *);
extern uint64_t probe_identity_i16(int16_t, struct result_bits *);
extern uint64_t probe_pointer_load_store(const uint32_t *, uint32_t *, struct result_bits *);
extern uint64_t probe_load_u32(const uint32_t *, struct result_bits *);
extern uint64_t probe_identity_ptr(const uint8_t *, struct result_bits *);
extern uint64_t probe_neg_u128(unsigned __int128, struct result_bits *);
extern uint64_t probe_add_f32(float, float, struct result_bits *);
extern uint64_t probe_mul_f64(double, double, struct result_bits *);
extern uint64_t probe_negative_clobber(struct result_bits *);
extern void abi_negative_write(uint8_t *);
extern void abi_negative_timeout(void);

static int emit(const char *id, uint64_t lo, uint64_t hi, uint64_t abi) {
    if (abi != 0) return 0;
    printf("case=%s lo=%016" PRIx64 " hi=%016" PRIx64 " abi=%016" PRIx64 " term=normal\n", id, lo, hi, abi);
    return 1;
}

static int run_all(void) {
    struct result_bits r;
    unsigned passed = 0;
    uint64_t abi;

    abi = probe_neg_u64(0, &r); passed += emit("neg_u64/zero", r.lo, 0, abi);
    abi = probe_neg_u64(UINT64_MAX, &r); passed += emit("neg_u64/max", r.lo, 0, abi);
    abi = probe_select_i32(INT32_MIN, INT32_MAX, 0, &r); passed += emit("select_i32/false", (uint32_t)r.lo, 0, abi);
    abi = probe_select_i32(INT32_MIN, INT32_MAX, 1, &r); passed += emit("select_i32/true", (uint32_t)r.lo, 0, abi);

    abi = probe_identity_u8(0xff, &r);
    fprintf(stderr, "diag=identity_u8 upper_rax=%014" PRIx64 "\n", r.hi >> 8);
    passed += emit("identity_u8/max", (uint8_t)r.lo, 0, abi);
    abi = probe_identity_i16(INT16_MIN, &r);
    fprintf(stderr, "diag=identity_i16 upper_rax=%012" PRIx64 "\n", r.hi >> 16);
    passed += emit("identity_i16/min", (uint16_t)r.lo, 0, abi);

    struct { uint64_t left; uint32_t src; uint32_t dst; uint64_t right; } mem = {
        0x13579bdf2468ace0ULL, 0xfffffff0U, 0x11223344U, 0x0eca8642fdb97531ULL
    };
    abi = probe_pointer_load_store(&mem.src, &mem.dst, &r);
    if (mem.left != 0x13579bdf2468ace0ULL || mem.right != 0x0eca8642fdb97531ULL ||
        mem.src != 0xfffffff0U || mem.dst != 0xfffffff7U) return 20;
    passed += emit("pointer_load_store/wrap", (uint32_t)r.lo,
        ((uint64_t)mem.src << 32) | mem.dst, abi);

    const uint32_t load_value = 0x80000001U;
    abi = probe_load_u32(&load_value, &r);
    passed += emit("load_u32/boundary", (uint32_t)r.lo, load_value, abi);

    const uint8_t ptr_bytes[8] = { 1, 2, 3, 4, 5, 6, 7, 8 };
    abi = probe_identity_ptr(&ptr_bytes[3], &r);
    const uintptr_t returned_address = (uintptr_t)r.lo;
    const uintptr_t base_address = (uintptr_t)ptr_bytes;
    if (base_address > UINTPTR_MAX - sizeof(ptr_bytes) || returned_address < base_address ||
        returned_address > base_address + sizeof(ptr_bytes)) return 21;
    const uintptr_t normalized = returned_address - base_address;
    passed += emit("identity_ptr/offset3", normalized, 0, abi);

    const unsigned __int128 wide = ((unsigned __int128)0x0123456789abcdefULL << 64) | 0xfedcba9876543210ULL;
    abi = probe_neg_u128(0, &r); passed += emit("neg_u128/zero", r.lo, r.hi, abi);
    abi = probe_neg_u128(wide, &r); passed += emit("neg_u128/mixed", r.lo, r.hi, abi);

    abi = probe_add_f32(1.5f, 2.25f, &r); passed += emit("add_f32/exact", (uint32_t)r.lo, 0, abi);
    abi = probe_add_f32(-8.0f, 0.5f, &r); passed += emit("add_f32/negative", (uint32_t)r.lo, 0, abi);
    abi = probe_mul_f64(-3.5, 8.0, &r); passed += emit("mul_f64/exact", r.lo, 0, abi);
    abi = probe_mul_f64(0.5, 0.25, &r); passed += emit("mul_f64/fraction", r.lo, 0, abi);

    if (passed != 15) return 22;
    printf("summary cases=15 status=pass\n");
    return 0;
}

int main(int argc, char **argv) {
    if (argc == 1) return run_all();
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
    return 64;
}
