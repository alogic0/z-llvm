#include <stdint.h>
#include <stdio.h>
#include <inttypes.h>

__attribute__((noinline)) void comparison_clobber(void) {
    __asm__ volatile("mov $0x55, %%rax\n\tmov $0x66, %%rcx\n\tmov $0x77, %%rdx\n\t"
                     "mov $0x88, %%rsi\n\tmov $0x99, %%rdi\n\tmov $0xaa, %%r8\n\t"
                     "mov $0xbb, %%r9\n\tmov $0xcc, %%r10\n\tmov $0xdd, %%r11"
                     ::: "rax","rcx","rdx","rsi","rdi","r8","r9","r10","r11","cc","memory");
}
extern uint64_t compare_1_ne(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_1_ule(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_1_uge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_1_sle(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_1_sge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_1_reverse(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_6_ne(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_6_ule(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_6_uge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_6_sle(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_6_sge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_6_reverse(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_8_ne(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_8_ule(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_8_uge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_8_sle(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_8_sge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_8_reverse(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_16_ne(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_16_ule(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_16_uge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_16_sle(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_16_sge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_16_reverse(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_31_ne(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_31_ule(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_31_uge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_31_sle(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_31_sge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_31_reverse(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_32_ne(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_32_ule(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_32_uge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_32_sle(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_32_sge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_32_reverse(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_64_ne(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_64_ule(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_64_uge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_64_sle(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_64_sge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_64_reverse(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_pointer_ne(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_pointer_ule(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_pointer_uge(uint64_t,uint64_t,uint32_t*);
extern uint64_t compare_frame(uint64_t,uint64_t,uint32_t*);
struct Test { const char *name; uint64_t (*run)(uint64_t,uint64_t,uint32_t*); unsigned bits, op; };
static const struct Test cases[] = {
    {"compare_1_ne", compare_1_ne, 1, 0},
    {"compare_1_ule", compare_1_ule, 1, 1},
    {"compare_1_uge", compare_1_uge, 1, 2},
    {"compare_1_sle", compare_1_sle, 1, 3},
    {"compare_1_sge", compare_1_sge, 1, 4},
    {"compare_1_reverse", compare_1_reverse, 1, 5},
    {"compare_6_ne", compare_6_ne, 6, 0},
    {"compare_6_ule", compare_6_ule, 6, 1},
    {"compare_6_uge", compare_6_uge, 6, 2},
    {"compare_6_sle", compare_6_sle, 6, 3},
    {"compare_6_sge", compare_6_sge, 6, 4},
    {"compare_6_reverse", compare_6_reverse, 6, 5},
    {"compare_8_ne", compare_8_ne, 8, 0},
    {"compare_8_ule", compare_8_ule, 8, 1},
    {"compare_8_uge", compare_8_uge, 8, 2},
    {"compare_8_sle", compare_8_sle, 8, 3},
    {"compare_8_sge", compare_8_sge, 8, 4},
    {"compare_8_reverse", compare_8_reverse, 8, 5},
    {"compare_16_ne", compare_16_ne, 16, 0},
    {"compare_16_ule", compare_16_ule, 16, 1},
    {"compare_16_uge", compare_16_uge, 16, 2},
    {"compare_16_sle", compare_16_sle, 16, 3},
    {"compare_16_sge", compare_16_sge, 16, 4},
    {"compare_16_reverse", compare_16_reverse, 16, 5},
    {"compare_31_ne", compare_31_ne, 31, 0},
    {"compare_31_ule", compare_31_ule, 31, 1},
    {"compare_31_uge", compare_31_uge, 31, 2},
    {"compare_31_sle", compare_31_sle, 31, 3},
    {"compare_31_sge", compare_31_sge, 31, 4},
    {"compare_31_reverse", compare_31_reverse, 31, 5},
    {"compare_32_ne", compare_32_ne, 32, 0},
    {"compare_32_ule", compare_32_ule, 32, 1},
    {"compare_32_uge", compare_32_uge, 32, 2},
    {"compare_32_sle", compare_32_sle, 32, 3},
    {"compare_32_sge", compare_32_sge, 32, 4},
    {"compare_32_reverse", compare_32_reverse, 32, 5},
    {"compare_64_ne", compare_64_ne, 64, 0},
    {"compare_64_ule", compare_64_ule, 64, 1},
    {"compare_64_uge", compare_64_uge, 64, 2},
    {"compare_64_sle", compare_64_sle, 64, 3},
    {"compare_64_sge", compare_64_sge, 64, 4},
    {"compare_64_reverse", compare_64_reverse, 64, 5},
    {"compare_pointer_ne", compare_pointer_ne, 64, 6},
    {"compare_pointer_ule", compare_pointer_ule, 64, 7},
    {"compare_pointer_uge", compare_pointer_uge, 64, 8},
    {"compare_frame", compare_frame, 64, 9},
};
static uint32_t expected(unsigned bits,unsigned op,uint64_t a,uint64_t b) {
    uint64_t mask=bits==64?UINT64_MAX:((UINT64_C(1)<<bits)-1);
    uint64_t sign=UINT64_C(1)<<(bits-1),x=a&mask,y=b&mask;
    switch(op) {
        case 0: return x!=y;
        case 1: return x<=y;
        case 2: return x>=y;
        case 3: return (x^sign)<=(y^sign);
        case 4: return (x^sign)>=(y^sign);
        case 5: return sign<=x;
        case 6: return a!=b;
        case 7: return a<=b;
        case 8: return a>=b;
        default: return 1;
    }
}
int main(void) {
    const uint64_t values[]={0,1,UINT64_C(0x7f),UINT64_C(0x8000),UINT64_C(0x7fffffff),UINT64_C(0x80000000),UINT64_C(0x8000000000000000),UINT64_MAX};
    unsigned observations=0;
    for(unsigned t=0;t<sizeof cases/sizeof cases[0];t++)
      for(unsigned i=0;i<8;i++) for(unsigned j=0;j<8;j++) {
        const struct Test *c=&cases[t];uint64_t a=values[i],b=values[j];
        uint32_t out[]={UINT32_C(0xa5a5a5a5),UINT32_C(0xdeadbeef),UINT32_C(0xa5a5a5a5)};
        uint64_t live=c->run(a,b,&out[1]);
        if(live!=(a^b)||out[1]!=expected(c->bits,c->op,a,b)||out[0]!=UINT32_C(0xa5a5a5a5)||out[2]!=out[0]) {
            fprintf(stderr,"%s a=%" PRIx64 " b=%" PRIx64 " result=%u expected=%u live=%" PRIx64 "\n",c->name,a,b,out[1],expected(c->bits,c->op,a,b),live);return 1;
        }
        observations++;
      }
    if(observations!=2944) return 2;
    puts("safe-comparisons observations=2944 narrow=signed=pointer=constant=live=guards=preserved");return 0;
}
