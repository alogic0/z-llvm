#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
__attribute__((noinline)) void safe_scalar_touch(uint64_t *p) {
    *p ^= UINT64_C(0xdeadbeefcafe0123);
    __asm__ volatile("mov $17, %%rax\n\tmov $19, %%rcx\n\tmov $23, %%rdx\n\t"
        "mov $29, %%rsi\n\tmov $31, %%rdi\n\tmov $37, %%r8\n\t"
        "mov $41, %%r9\n\tmov $43, %%r10\n\tmov $47, %%r11"
        : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc", "memory");
}
#define RETURN_ADDRESS_CHECK(name, target) \
    ".globl " #name "\n.type " #name ",@function\n" #name ":\n" \
    "subq $8,%rsp\ncall " #target "\n1:\nleaq 1b(%rip),%rcx\n" \
    "cmpq %rcx,%rax\nsete %al\nmovzbl %al,%eax\naddq $8,%rsp\nret\n" \
    ".size " #name ",.-" #name "\n"
__asm__(".text\n" RETURN_ADDRESS_CHECK(check_ra_plain,safe_ra_plain) RETURN_ADDRESS_CHECK(check_ra_frame,safe_ra_frame));
extern uint64_t safe_mask_32(uint64_t,uint64_t *),safe_mask_64(uint64_t,uint64_t *);
extern uint64_t safe_null_eq(void *),safe_null_ne(void *),safe_unreachable_branch(uint64_t);
extern int check_ra_plain(void),check_ra_frame(uint64_t,uint64_t *);

extern uint64_t safe_uadd_named(uint64_t,uint64_t,uint64_t *);
extern uint64_t safe_uadd_max(uint64_t,uint64_t,uint64_t *);
extern uint64_t safe_uadd_high(uint64_t,uint64_t,uint64_t *);
extern uint64_t safe_usub_named(uint64_t,uint64_t,uint64_t *);
extern uint64_t safe_usub_max(uint64_t,uint64_t,uint64_t *);
extern uint64_t safe_usub_high(uint64_t,uint64_t,uint64_t *);
int main(void) {
    const uint64_t values[]={0,1,2,UINT32_MAX,UINT64_C(0x7fffffffffffffff),UINT64_C(1)<<63,UINT64_MAX-1,UINT64_MAX};
    const uint64_t guard=UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations=0;
    for(unsigned i=0;i<8;++i) for(unsigned j=0;j<8;++j) {
        uint64_t a=values[i],b=values[j],out[]={guard,0,0,guard};
        uint64_t (*mask[])(uint64_t,uint64_t *)={safe_mask_32,safe_mask_64};
        for(unsigned f=0;f<2;++f) {
            out[2]=guard;
            if(mask[f](a,out+1)!=(a^55) || out[1]!=(a&UINT64_C(0x7fffffff)) || out[2]!=guard || out[0]!=guard || out[3]!=guard) return 1;
            ++observations;
        }
        uint64_t (*overflow[])(uint64_t,uint64_t,uint64_t *)={safe_uadd_named,safe_uadd_max,safe_uadd_high,safe_usub_named,safe_usub_max,safe_usub_high};
        for(unsigned f=0;f<6;++f) {
            uint64_t y=f%3==0?b:f%3==1?UINT64_MAX:UINT64_C(1)<<63;
            uint64_t wrapped=f<3?a+y:a-y;
            uint64_t flag=f<3?wrapped<a:a<y;
            if(overflow[f](a,b,out+1)!=flag || out[1]!=wrapped || out[2]!=(a^b) || out[0]!=guard || out[3]!=guard) return 2;
            ++observations;
        }
        if(safe_null_eq((void *)(uintptr_t)a)!=(a==0)) return 3;
        ++observations;
        if(safe_null_ne((void *)(uintptr_t)b)!=(b!=0)) return 4;
        ++observations;
        if(!check_ra_plain()) return 5;
        ++observations;
        if(!check_ra_frame(a,out+1) || out[1]!=(a^UINT64_C(0xdeadbeefcafe0123)) || out[2]!=(a^b) || out[0]!=guard || out[3]!=guard) return 6;
        ++observations;
        if(safe_unreachable_branch(a|1)!=((a|1)^55)) return 7;
        ++observations;
    }
    printf("safe-scalar-forms observations=%u masks=overflow=null=return-address=live=guards=preserved\n",observations);
    return 0;
}
