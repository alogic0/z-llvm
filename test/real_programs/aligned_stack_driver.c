#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#define DECLARE(n) extern uint64_t aligned_stack_##n(uint64_t);
DECLARE(32) DECLARE(64) DECLARE(128) DECLARE(256) DECLARE(1024) DECLARE(4096)
__attribute__((noinline)) uint64_t aligned_stack_fill(unsigned char *p, unsigned char *q, uint64_t size, uint64_t alignment, uint64_t seed) {
    uintptr_t a=(uintptr_t)p, b=(uintptr_t)q;
    if((a%alignment) || (b%alignment) || !((a+size<=b) || (b+size<=a))) {
        fprintf(stderr,"stack alignment=%llu size=%llu overlap/alignment failure\n",(unsigned long long)alignment,(unsigned long long)size); abort();
    }
    for(uint64_t i=0;i<size;++i) { p[i]=(unsigned char)(seed+i); q[i]=(unsigned char)(seed^i); }
    __asm__ volatile("xor %%eax,%%eax; xor %%edx,%%edx; xor %%ecx,%%ecx; xor %%edi,%%edi; xor %%esi,%%esi; xor %%r8d,%%r8d; xor %%r9d,%%r9d"
        ::: "rax", "rdx", "rcx", "rdi", "rsi", "r8", "r9", "cc");
    return seed^UINT64_C(0x70da9e6b5f183c24);
}
int main(void) {
    uint64_t (*functions[])(uint64_t)={aligned_stack_32,aligned_stack_64,aligned_stack_128,aligned_stack_256,aligned_stack_1024,aligned_stack_4096};
    unsigned sizes[]={3,17,65,129,257,257}, observations=0;
    for(unsigned k=0;k<6;++k) for(uint64_t seed=0;seed<1024;++seed) {
        uint64_t sum=2*(uint64_t)(uint8_t)seed+(uint8_t)(seed+sizes[k]-1)+(uint8_t)(seed^(sizes[k]-1));
        uint64_t expected=sum^seed^UINT64_C(0x70da9e6b5f183c24), actual=functions[k](seed);
        if(actual!=expected) { fprintf(stderr,"stack case=%u seed=%llu actual=%llx expected=%llx\n",k,(unsigned long long)seed,(unsigned long long)actual,(unsigned long long)expected); return 1; }
        ++observations;
    }
    printf("aligned-stack observations=%u alignment=32-4096 disjoint=checked calls=preserved\n",observations);
    return 0;
}
