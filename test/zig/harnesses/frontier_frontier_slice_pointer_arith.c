#include <sys/wait.h>
#include <unistd.h>

extern int z_frontier_slice_stride_sum(const int *) __asm__("frontier_slice_pointer_arith.frontier_slice_stride_sum");
extern int z_frontier_pointer_offset_load(const int *) __asm__("frontier_slice_pointer_arith.frontier_pointer_offset_load");
extern int z_frontier_dynamic_ptr_add(const int *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_dynamic_ptr_add");
extern int z_frontier_dynamic_ptr_pair_sum(const int *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_dynamic_ptr_pair_sum");
extern int z_frontier_comptime_ptr_add(const int *) __asm__("frontier_slice_pointer_arith.frontier_comptime_ptr_add");
extern int z_frontier_chained_ptr_add(const int *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_chained_ptr_add");
extern int z_frontier_ptr_sub_const_load(const int *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_ptr_sub_const_load");
extern int z_frontier_ptr_sub_runtime_load(const int *, unsigned long, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_ptr_sub_runtime_load");
extern int z_frontier_ptr_sub_runtime_rcx_load(const int *, unsigned long, unsigned long, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_ptr_sub_runtime_rcx_load");
extern int z_frontier_ptr_add_store(int *, unsigned long, int) __asm__("frontier_slice_pointer_arith.frontier_ptr_add_store");
extern unsigned char z_frontier_ptr_add_load_u8(const unsigned char *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_ptr_add_load_u8");
extern unsigned short z_frontier_ptr_add_load_u16(const unsigned short *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_ptr_add_load_u16");
extern unsigned long long z_frontier_ptr_add_load_u64(const unsigned long long *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_ptr_add_load_u64");
extern unsigned int z_frontier_ptr_add_load_index_rcx(const unsigned int *, unsigned long, unsigned long, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_ptr_add_load_index_rcx");
extern unsigned char z_frontier_ptr_add_load_const_runtime_u8(const unsigned char *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_ptr_add_load_const_runtime_u8");
extern unsigned short z_frontier_ptr_add_load_const_runtime_u16(const unsigned short *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_ptr_add_load_const_runtime_u16");
extern unsigned int z_frontier_ptr_add_load_const_runtime_u32(const unsigned int *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_ptr_add_load_const_runtime_u32");
extern unsigned long long z_frontier_ptr_add_load_const_runtime_u64(const unsigned long long *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_ptr_add_load_const_runtime_u64");
extern unsigned char z_frontier_ptr_add_store_u8(unsigned char *, unsigned long, unsigned char) __asm__("frontier_slice_pointer_arith.frontier_ptr_add_store_u8");
extern unsigned short z_frontier_ptr_add_store_u16(unsigned short *, unsigned long, unsigned short) __asm__("frontier_slice_pointer_arith.frontier_ptr_add_store_u16");
extern unsigned long long z_frontier_ptr_add_store_u64(unsigned long long *, unsigned long, unsigned long long) __asm__("frontier_slice_pointer_arith.frontier_ptr_add_store_u64");
extern int z_frontier_ptr_add_store_const_runtime_i32(int *, unsigned long, int) __asm__("frontier_slice_pointer_arith.frontier_ptr_add_store_const_runtime_i32");
extern int z_frontier_ptr_slot_load(const int *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_ptr_slot_load");
extern int z_frontier_ptr_slot_store(int *, unsigned long, int) __asm__("frontier_slice_pointer_arith.frontier_ptr_slot_store");
extern unsigned long z_frontier_slice_len_from_ptr(const int *, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_slice_len_from_ptr");
extern int z_frontier_slice_ptr_load(const int *, unsigned long, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_slice_ptr_load");
extern int z_frontier_slice_elem_ptr_load(const int *, unsigned long, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_slice_elem_ptr_load");
extern int z_frontier_slice_elem_ptr_store(int *, unsigned long, unsigned long, int) __asm__("frontier_slice_pointer_arith.frontier_slice_elem_ptr_store");
extern int z_frontier_slice_ptr_const_runtime_load(const int *, unsigned long, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_slice_ptr_const_runtime_load");
extern int z_frontier_slice_ptr_const_runtime_store(int *, unsigned long, unsigned long, int) __asm__("frontier_slice_pointer_arith.frontier_slice_ptr_const_runtime_store");
extern int z_frontier_checked_slice_elem_ptr_load(const int *, unsigned long, unsigned long) __asm__("frontier_slice_pointer_arith.frontier_checked_slice_elem_ptr_load");
void z_frontier_slice_out_of_bounds(unsigned long index, unsigned long len) __asm__("frontier_slice_pointer_arith.outOfBounds");
void z_frontier_slice_out_of_bounds(unsigned long index, unsigned long len) {
    if (index != 5UL || len != 3UL) _exit(104);
    __builtin_trap();
}

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

static void death_checked_slice_oob(void) {
    const int values[] = { 3, 5, 8 };
    (void)z_frontier_checked_slice_elem_ptr_load(values, 3, 5);
}

int main(void) {
    const int value = 37;
    const int values[] = { 3, 5, 8, 13, 21 };
    int mutable_values[] = { 2, 4, 6, 8, 10 };
    const unsigned char bytes[] = { 1, 7, 19, 23 };
    const unsigned short shorts[] = { 11, 29, 47, 61 };
    const unsigned long long longs[] = { 101ULL, 202ULL, 303ULL, 404ULL };
    const unsigned int words[] = { 9U, 14U, 27U, 41U, 55U };
    unsigned char mutable_bytes[] = { 4, 5, 6, 7 };
    unsigned short mutable_shorts[] = { 13, 14, 15, 16 };
    unsigned long long mutable_longs[] = { 1001ULL, 1002ULL, 1003ULL, 1004ULL };
    if (z_frontier_slice_stride_sum(&value) != 37) return 1;
    if (z_frontier_pointer_offset_load(&value) != 37) return 2;
    if (z_frontier_dynamic_ptr_add(values, 3) != 13) return 3;
    if (z_frontier_dynamic_ptr_pair_sum(values, 1) != 13) return 4;
    if (z_frontier_comptime_ptr_add(values) != 8) return 5;
    if (z_frontier_chained_ptr_add(values, 1) != 13) return 6;
    if (z_frontier_ptr_sub_const_load(values, 3) != 8) return 36;
    if (z_frontier_ptr_sub_runtime_load(values, 4, 2) != 8) return 39;
    if (z_frontier_ptr_sub_runtime_rcx_load(values, 100UL, 4UL, 2UL) != 8) return 40;
    if (z_frontier_ptr_add_store(mutable_values, 2, 17) != 17) return 7;
    if (mutable_values[2] != 17) return 8;
    if (z_frontier_slice_len_from_ptr(values, 5) != 5UL) return 9;
    if (z_frontier_slice_ptr_load(values, 5, 4) != 21) return 10;
    if (z_frontier_slice_elem_ptr_load(values, 5, 2) != 8) return 11;
    if (z_frontier_slice_elem_ptr_store(mutable_values, 5, 3, 19) != 19) return 12;
    if (mutable_values[3] != 19) return 13;
    if (z_frontier_ptr_add_load_u8(bytes, 2) != 19) return 14;
    if (z_frontier_ptr_add_load_u16(shorts, 1) != 29) return 15;
    if (z_frontier_ptr_add_load_u64(longs, 3) != 404ULL) return 16;
    if (z_frontier_ptr_add_load_index_rcx(words, 100UL, 200UL, 4UL) != 55U) return 23;
    if (z_frontier_ptr_add_load_const_runtime_u8(bytes, 2) != 23) return 24;
    if (z_frontier_ptr_add_load_const_runtime_u16(shorts, 2) != 61) return 25;
    if (z_frontier_ptr_add_load_const_runtime_u32(words, 3) != 55U) return 26;
    if (z_frontier_ptr_add_load_const_runtime_u64(longs, 2) != 404ULL) return 27;
    if (z_frontier_ptr_add_store_u8(mutable_bytes, 1, 33) != 33) return 17;
    if (mutable_bytes[1] != 33) return 18;
    if (z_frontier_ptr_add_store_u16(mutable_shorts, 2, 44) != 44) return 19;
    if (mutable_shorts[2] != 44) return 20;
    if (z_frontier_ptr_add_store_u64(mutable_longs, 3, 5555ULL) != 5555ULL) return 21;
    if (mutable_longs[3] != 5555ULL) return 22;
    if (z_frontier_ptr_add_store_const_runtime_i32(mutable_values, 2, 31) != 31) return 28;
    if (mutable_values[3] != 31) return 29;
    if (z_frontier_ptr_slot_load(values, 2) != 13) return 30;
    if (z_frontier_ptr_slot_store(mutable_values, 1, 43) != 43) return 31;
    if (mutable_values[2] != 43) return 32;
    if (z_frontier_slice_ptr_const_runtime_load(values, 5, 2) != 13) return 33;
    if (z_frontier_slice_ptr_const_runtime_store(mutable_values, 5, 2, 47) != 47) return 37;
    if (mutable_values[3] != 47) return 38;
    if (z_frontier_checked_slice_elem_ptr_load(values, 5, 4) != 21) return 34;
    if (expect_death(death_checked_slice_oob) != 0) return 35;
    return 0;
}
