#include <stdint.h>
#include <stdio.h>
#include <string.h>
extern uint64_t pressure_i32_48(const void *, uint64_t), pressure_i32_96(const void *, uint64_t);
extern uint64_t pressure_i64_48(const void *, uint64_t), pressure_i64_96(const void *, uint64_t);
extern uint64_t pressure_i32_288(const void *, uint64_t), pressure_i64_288(const void *, uint64_t);
__attribute__((noinline)) uint64_t pressure_clobber(uint64_t value) {
    uint64_t result = value ^ UINT64_C(0xfeedface87654321);
    __asm__ volatile("" : "+a"(result) : : "rdi", "rsi", "rdx", "rcx", "r8", "r9", "r10", "r11", "memory", "cc");
    return result;
}
int main(void) {
    unsigned char storage[288 * 8 + 2];
    unsigned observations = 0;
    uint64_t random = UINT64_C(0xfedcba9876543210);
    uint64_t (*functions[])(const void *, uint64_t) = {pressure_i32_48,pressure_i32_96,pressure_i32_288,pressure_i64_48,pressure_i64_96,pressure_i64_288};
    const unsigned counts[] = {48,96,288};
    for (unsigned n = 0; n < 128; ++n) {
        uint64_t words[288];
        storage[0] = 165; storage[sizeof storage - 1] = 90;
        for (unsigned i = 0; i < 288; ++i) {
            random ^= random << 13; random ^= random >> 7; random ^= random << 17;
            words[i] = n == 0 ? UINT64_MAX : random;
            memcpy(storage + 1 + i * 8, &words[i], 8);
        }
        for (unsigned f = 0; f < 6; ++f) {
            unsigned count = counts[f % 3];
            uint64_t sum = 0;
            for (unsigned i = 0; i < count; ++i) sum += words[(i + (n & 1)) % count] * (i * 2 + 1);
            if (f < 3) sum = (uint32_t)sum;
            uint64_t expected = sum ^ pressure_clobber(n);
            if (functions[f](storage + 1, n) != expected) return 1 + f;
            if (storage[0] != 165 || storage[sizeof storage - 1] != 90) return 7;
            for (unsigned i = 0; i < 288; ++i) { uint64_t actual; memcpy(&actual,storage + 1 + i * 8,8); if (actual != words[i]) return 8; }
            ++observations;
        }
    }
    printf("register-pressure observations=%u values=48,96,288 widths=32,64 calls=phis=aliases=preserved\n", observations);
    return 0;
}
