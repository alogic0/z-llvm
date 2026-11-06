#include <stdint.h>
#include <stdio.h>
extern uint64_t indirect_branch_mutable(uint64_t,uint64_t);
extern uint64_t indirect_branch_loop(uint64_t,uint64_t);
extern uint64_t indirect_branch_packed(uint64_t,uint64_t);
__attribute__((noinline)) uint64_t indirect_branch_noise(uint64_t seed) {
    __asm__ volatile("xor %%eax,%%eax; xor %%edx,%%edx; xor %%ecx,%%ecx; xor %%edi,%%edi; xor %%esi,%%esi; xor %%r8d,%%r8d; xor %%r9d,%%r9d"
        ::: "rax", "rdx", "rcx", "rdi", "rsi", "r8", "r9", "cc");
    return seed^UINT64_C(0x6de803f1b2ac9754);
}
int main(void) {
    unsigned observations=0;
    for(unsigned i=0;i<1024;++i) {
        uint64_t seed=UINT64_C(0x159e289357cb410a)+i*UINT64_C(0x531c), noise=seed^UINT64_C(0x6de803f1b2ac9754);
        unsigned index=i%4, actual_index=index;
        if(!(i&1) && index<2) actual_index=index^1;
        uint64_t expected=actual_index==0?noise+17:actual_index==1?noise^91:actual_index==2?noise-seed:noise*3;
        uint64_t actual=indirect_branch_mutable(index,seed);
        if(actual!=expected) { fprintf(stderr,"branch case=%u actual=%llx expected=%llx\n",i,(unsigned long long)actual,(unsigned long long)expected); return 1; }
        ++observations;
        expected=seed;
        for(unsigned j=0;j<i%37;++j) expected+=j^UINT64_C(0x6de803f1b2ac9754);
        actual=indirect_branch_loop(i%37,seed);
        if(actual!=expected) { fprintf(stderr,"loop case=%u actual=%llx expected=%llx\n",i,(unsigned long long)actual,(unsigned long long)expected); return 2; }
        ++observations;
        expected=(i&1) ? noise^999 : noise+777;
        actual=indirect_branch_packed(i&1,seed);
        if(actual!=expected) { fprintf(stderr,"packed case=%u actual=%llx expected=%llx\n",i,(unsigned long long)actual,(unsigned long long)expected); return 3; }
        ++observations;
    }
    printf("indirect-branches observations=%u mutable=checked packed=checked loop=checked calls=preserved\n",observations);
    return 0;
}
