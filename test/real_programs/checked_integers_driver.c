#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
typedef uint64_t (*probe)(uint64_t,uint64_t,uint64_t *);
static uint64_t dirty(uint64_t v) {
    __asm__ volatile("mov $17, %%rax\n\tmov $19, %%rcx\n\tmov $23, %%rdx\n\t"
        "mov $29, %%rsi\n\tmov $31, %%rdi\n\tmov $37, %%r8\n\t"
        "mov $41, %%r9\n\tmov $43, %%r10\n\tmov $47, %%r11"
        : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc", "memory");
    return (v & 1) | UINT64_C(0xdeadbeefcafefefe);
}
__attribute__((noinline)) uint64_t checked_boolean_ptr(const uint64_t *p) {return dirty(*p);}
__attribute__((noinline)) uint64_t checked_boolean_six(uint64_t a,uint64_t b,uint64_t c,uint64_t d,uint64_t e,uint64_t f) {
    return dirty((a+3*b+5*c+7*d+11*e+13*f)>>3);
}
__attribute__((noinline)) uint64_t checked_boolean_eight(uint64_t a,uint64_t b,uint64_t c,uint64_t d,uint64_t e,uint64_t f,uint64_t g,uint64_t h) {
    return dirty((a+3*b+5*c+7*d+11*e+13*f+17*g+19*h)>>3);
}

extern uint64_t checked_uadd_1_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_1_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_1_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_1_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_1_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_1_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_1_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_1_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_1_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_1_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_1_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_1_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_1_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_1_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_1_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_1_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_1_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_1_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_3_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_3_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_3_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_3_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_3_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_3_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_3_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_3_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_3_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_3_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_3_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_3_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_3_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_3_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_3_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_3_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_3_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_3_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_8_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_8_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_8_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_8_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_8_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_8_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_8_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_8_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_8_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_8_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_8_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_8_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_8_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_8_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_8_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_8_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_8_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_8_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_16_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_16_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_16_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_16_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_16_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_16_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_16_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_16_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_16_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_16_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_16_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_16_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_16_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_16_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_16_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_16_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_16_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_16_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_31_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_31_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_31_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_31_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_31_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_31_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_31_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_31_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_31_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_31_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_31_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_31_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_31_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_31_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_31_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_31_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_31_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_31_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_32_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_32_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_32_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_32_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_32_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_32_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_32_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_32_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_umul_32_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_32_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_32_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_sadd_32_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_32_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_32_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_ssub_32_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_32_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_32_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_smul_32_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_64_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_64_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_uadd_64_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_64_0(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_64_1(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_usub_64_2(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_roundtrip(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_bool_pointer(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_bool_derived(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_bool_forward(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_bool_branch(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_bool_six(uint64_t,uint64_t,uint64_t *);
extern uint64_t checked_bool_eight(uint64_t,uint64_t,uint64_t *);
struct row {probe run; unsigned bits, is_signed, op, side;};
static const struct row rows[]={
{checked_uadd_1_0,1,0,0,0},
{checked_uadd_1_1,1,0,0,1},
{checked_uadd_1_2,1,0,0,2},
{checked_usub_1_0,1,0,1,0},
{checked_usub_1_1,1,0,1,1},
{checked_usub_1_2,1,0,1,2},
{checked_umul_1_0,1,0,2,0},
{checked_umul_1_1,1,0,2,1},
{checked_umul_1_2,1,0,2,2},
{checked_sadd_1_0,1,1,0,0},
{checked_sadd_1_1,1,1,0,1},
{checked_sadd_1_2,1,1,0,2},
{checked_ssub_1_0,1,1,1,0},
{checked_ssub_1_1,1,1,1,1},
{checked_ssub_1_2,1,1,1,2},
{checked_smul_1_0,1,1,2,0},
{checked_smul_1_1,1,1,2,1},
{checked_smul_1_2,1,1,2,2},
{checked_uadd_3_0,3,0,0,0},
{checked_uadd_3_1,3,0,0,1},
{checked_uadd_3_2,3,0,0,2},
{checked_usub_3_0,3,0,1,0},
{checked_usub_3_1,3,0,1,1},
{checked_usub_3_2,3,0,1,2},
{checked_umul_3_0,3,0,2,0},
{checked_umul_3_1,3,0,2,1},
{checked_umul_3_2,3,0,2,2},
{checked_sadd_3_0,3,1,0,0},
{checked_sadd_3_1,3,1,0,1},
{checked_sadd_3_2,3,1,0,2},
{checked_ssub_3_0,3,1,1,0},
{checked_ssub_3_1,3,1,1,1},
{checked_ssub_3_2,3,1,1,2},
{checked_smul_3_0,3,1,2,0},
{checked_smul_3_1,3,1,2,1},
{checked_smul_3_2,3,1,2,2},
{checked_uadd_8_0,8,0,0,0},
{checked_uadd_8_1,8,0,0,1},
{checked_uadd_8_2,8,0,0,2},
{checked_usub_8_0,8,0,1,0},
{checked_usub_8_1,8,0,1,1},
{checked_usub_8_2,8,0,1,2},
{checked_umul_8_0,8,0,2,0},
{checked_umul_8_1,8,0,2,1},
{checked_umul_8_2,8,0,2,2},
{checked_sadd_8_0,8,1,0,0},
{checked_sadd_8_1,8,1,0,1},
{checked_sadd_8_2,8,1,0,2},
{checked_ssub_8_0,8,1,1,0},
{checked_ssub_8_1,8,1,1,1},
{checked_ssub_8_2,8,1,1,2},
{checked_smul_8_0,8,1,2,0},
{checked_smul_8_1,8,1,2,1},
{checked_smul_8_2,8,1,2,2},
{checked_uadd_16_0,16,0,0,0},
{checked_uadd_16_1,16,0,0,1},
{checked_uadd_16_2,16,0,0,2},
{checked_usub_16_0,16,0,1,0},
{checked_usub_16_1,16,0,1,1},
{checked_usub_16_2,16,0,1,2},
{checked_umul_16_0,16,0,2,0},
{checked_umul_16_1,16,0,2,1},
{checked_umul_16_2,16,0,2,2},
{checked_sadd_16_0,16,1,0,0},
{checked_sadd_16_1,16,1,0,1},
{checked_sadd_16_2,16,1,0,2},
{checked_ssub_16_0,16,1,1,0},
{checked_ssub_16_1,16,1,1,1},
{checked_ssub_16_2,16,1,1,2},
{checked_smul_16_0,16,1,2,0},
{checked_smul_16_1,16,1,2,1},
{checked_smul_16_2,16,1,2,2},
{checked_uadd_31_0,31,0,0,0},
{checked_uadd_31_1,31,0,0,1},
{checked_uadd_31_2,31,0,0,2},
{checked_usub_31_0,31,0,1,0},
{checked_usub_31_1,31,0,1,1},
{checked_usub_31_2,31,0,1,2},
{checked_umul_31_0,31,0,2,0},
{checked_umul_31_1,31,0,2,1},
{checked_umul_31_2,31,0,2,2},
{checked_sadd_31_0,31,1,0,0},
{checked_sadd_31_1,31,1,0,1},
{checked_sadd_31_2,31,1,0,2},
{checked_ssub_31_0,31,1,1,0},
{checked_ssub_31_1,31,1,1,1},
{checked_ssub_31_2,31,1,1,2},
{checked_smul_31_0,31,1,2,0},
{checked_smul_31_1,31,1,2,1},
{checked_smul_31_2,31,1,2,2},
{checked_uadd_32_0,32,0,0,0},
{checked_uadd_32_1,32,0,0,1},
{checked_uadd_32_2,32,0,0,2},
{checked_usub_32_0,32,0,1,0},
{checked_usub_32_1,32,0,1,1},
{checked_usub_32_2,32,0,1,2},
{checked_umul_32_0,32,0,2,0},
{checked_umul_32_1,32,0,2,1},
{checked_umul_32_2,32,0,2,2},
{checked_sadd_32_0,32,1,0,0},
{checked_sadd_32_1,32,1,0,1},
{checked_sadd_32_2,32,1,0,2},
{checked_ssub_32_0,32,1,1,0},
{checked_ssub_32_1,32,1,1,1},
{checked_ssub_32_2,32,1,1,2},
{checked_smul_32_0,32,1,2,0},
{checked_smul_32_1,32,1,2,1},
{checked_smul_32_2,32,1,2,2},
{checked_uadd_64_0,64,0,0,0},
{checked_uadd_64_1,64,0,0,1},
{checked_uadd_64_2,64,0,0,2},
{checked_usub_64_0,64,0,1,0},
{checked_usub_64_1,64,0,1,1},
{checked_usub_64_2,64,0,1,2},
};
int main(void) {
    const uint64_t guard=UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations=0;
    for(unsigned f=0;f<sizeof rows/sizeof *rows;++f) {
        struct row r=rows[f];uint64_t sign=UINT64_C(1)<<(r.bits-1),mask=(sign-1)|sign;
        uint64_t values[]={0,1,sign-1,sign,sign+1,mask,mask+UINT64_C(1),UINT64_MAX};
        for(unsigned i=0;i<8;++i) for(unsigned j=0;j<8;++j) {
            uint64_t a=values[i],b=values[j],out[]={guard,0,0,guard};
            __int128 x=r.side==1?mask:a&mask,y=r.side==2?mask:b&mask;
            if(r.is_signed) {x=(x^sign)-sign;y=(y^sign)-sign;}
            __int128 full=r.op==0?x+y:r.op==1?x-y:x*y;
            __int128 lo=r.is_signed?-(__int128)sign:0,hi=r.is_signed?sign-1:(__int128)mask;
            uint64_t flag=full<lo || full>hi,wrapped=(uint64_t)full&mask;
            if(r.run(a,b,out+1)!=flag || out[1]!=wrapped || out[2]!=(a^b) || out[0]!=guard || out[3]!=guard) {
                fprintf(stderr,"checked arithmetic row=%u a=%llx b=%llx\n",f,(unsigned long long)a,(unsigned long long)b);return 1;
            }
            ++observations;
        }
    }
    const uint64_t values[]={0,1,7,8,UINT32_MAX,UINT64_C(1)<<32,UINT64_C(1)<<63,UINT64_MAX};
    probe booleans[]={checked_bool_pointer,checked_bool_derived,checked_bool_forward,checked_bool_branch,checked_bool_six,checked_bool_eight};
    for(unsigned i=0;i<8;++i) for(unsigned j=0;j<8;++j) {
        uint64_t a=values[i],b=values[j],out[]={guard,0,0,guard};
        if(checked_roundtrip(a,b,out+1)!=((a+7)&UINT32_MAX) || out[1]!=(a+7) || out[0]!=guard || out[3]!=guard)return 2;
        ++observations;
        for(unsigned f=0;f<6;++f) {
            uint64_t flag=a&1;
            if(f>=4) {uint64_t sum=b+3*a+5*19+7*a+11*37+13*b;if(f==5)sum+=17*a+19*73;flag=(sum>>3)&1;}
            if(booleans[f](a,b,out+1)!=(a^b) || out[1]!=flag || out[0]!=guard || out[3]!=guard) {
                fprintf(stderr,"checked boolean row=%u a=%llx b=%llx\n",f,(unsigned long long)a,(unsigned long long)b);return 3;
            }
            ++observations;
        }
    }
    printf("checked-integers observations=%u overflow=widths=constants=boolean=stack=live=guards=preserved\n",observations);
    return 0;
}

