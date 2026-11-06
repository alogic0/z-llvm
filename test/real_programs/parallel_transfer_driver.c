#include <stdint.h>
#include <stdio.h>
#include <string.h>

void parallel_copy_swap(const void *, void *, uint64_t);
void parallel_fill_rotate(uint64_t, void *, uint8_t);
void parallel_move_swap(const void *, void *, uint64_t);
unsigned char *parallel_global_base(void);
unsigned char *parallel_global_stride(uint8_t);
uint64_t parallel_left_ops(uint64_t, uint64_t);
uint64_t parallel_call_swap(uint64_t, uint64_t, uint64_t, uint64_t, uint64_t, uint64_t);
uint64_t parallel_call_fanout(uint64_t, uint64_t, uint64_t);
uint64_t parallel_call_mixed(uint64_t, uint64_t);
uint64_t parallel_phi_rotate(uint64_t, uint64_t, uint64_t, uint32_t);

static uint64_t mix(uint64_t a, uint64_t b, uint64_t c, uint64_t d, uint64_t e, uint64_t f) {
    return a + 3*b + 5*c + 7*d + 11*e + 13*f;
}
static void clobber(void) {
    __asm__ volatile ("xor %%eax,%%eax; xor %%edi,%%edi; xor %%esi,%%esi; xor %%edx,%%edx; xor %%ecx,%%ecx; xor %%r8d,%%r8d; xor %%r9d,%%r9d; xor %%r10d,%%r10d; xor %%r11d,%%r11d"
        ::: "rax", "rdi", "rsi", "rdx", "rcx", "r8", "r9", "r10", "r11", "cc");
}
uint64_t parallel_sink(uint64_t a, uint64_t b, uint64_t c, uint64_t d, uint64_t e, uint64_t f) {
    uint64_t result = mix(a,b,c,d,e,f);
    clobber();
    return result;
}
uint64_t parallel_mixed_sink(uint32_t a, uint64_t b, uint32_t c) {
    uint64_t result = a + 3*b + 5*(uint64_t)c;
    clobber();
    return result;
}
int main(void) {
    uint64_t state = UINT64_C(0xdeadbeef12345678);
    unsigned observations = 0;
    for (unsigned iteration = 0; iteration < 512; iteration++) {
        uint64_t values[6];
        for (unsigned j=0; j<6; j++) {
            state ^= state << 13; state ^= state >> 7; state ^= state << 17;
            values[j] = state;
        }
        uint64_t a=values[0], b=values[1], c=values[2], d=values[3], e=values[4], f=values[5];
        if (parallel_call_swap(a,b,c,d,e,f) != mix(b,a,c,f,d,e) + (a^f)) return 1;
        if (parallel_call_fanout(a,b,c) != mix(c,a,b,a,c,b)) return 2;
        if (parallel_call_mixed(a,b) != (uint32_t)b + 3*a + 5*(uint64_t)(uint32_t)a + b) return 3;
        observations += 3;
        for (unsigned count=0; count<7; count++) {
            uint64_t x=a,y=b,z=c;
            for (unsigned k=0; k<count; k++) { uint64_t previous=x; x=y; y=z; z=previous; }
            if (parallel_phi_rotate(a,b,c,count) != x + 3*y + 7*z) return 4;
            observations++;
        }
        unsigned length=iteration % 33;
        unsigned char source[48], destination[48], expected[48];
        for (unsigned j=0; j<48; j++) source[j]=(unsigned char)(values[j%6] >> (j%8));
        memset(destination,0xa5,sizeof(destination));
        memcpy(expected,destination,sizeof(expected));
        memcpy(expected+8,source+8,length);
        parallel_copy_swap(source+8,destination+8,length);
        if (memcmp(destination,expected,sizeof(expected))) return 5;
        observations++;
        unsigned char byte=(unsigned char)iteration;
        memset(expected+8,byte,length);
        parallel_fill_rotate(length,destination+8,byte);
        if (memcmp(destination,expected,sizeof(expected))) return 6;
        observations++;
        for (unsigned reverse=0; reverse<2; reverse++) {
            memcpy(destination,source,sizeof(source));
            memcpy(expected,source,sizeof(source));
            unsigned from=reverse ? 12 : 8, to=reverse ? 8 : 12;
            memmove(expected+to,expected+from,length);
            parallel_move_swap(destination+from,destination+to,length);
            if (memcmp(destination,expected,sizeof(expected))) return 8;
            observations++;
        }
        if (parallel_global_stride((uint8_t)iteration) != parallel_global_base()+72+128*(uint8_t)iteration) return 9;
        observations++;
        unsigned shift=iteration%64;
        if (parallel_left_ops(a,shift) != ((16*a) ^ (19-a) ^ (UINT64_MAX >> shift))) return 10;
        observations++;
    }
    if (observations != 8192) return 7;
    puts("parallel-transfer observations=8192 cycles=2,3 fanout=checked aliases=checked phi=checked calls=checked memory=guarded");
    return 0;
}
