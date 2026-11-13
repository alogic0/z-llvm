#define DRIVER_NAME "floating-boolean-calls"
#define DRIVER_SEEDS 64
#define DRIVER_CONTRACT "independent-integer-floating-goldens=ordered-nan-comparisons=mixed-boolean-return-abi=half-through-quad=cc-and-fastcc=optional-call-hints=call-clobbers=guard-pages=preserved"
#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <unistd.h>
typedef uint64_t (*kernel)(void *,void *,const void *,uint64_t);
struct test_case {kernel run;unsigned bits,kind,mutate;};
struct test_model {size_t input_bytes,expected_bytes,output_bytes,masked_byte;unsigned last_mask;uint64_t answer;};
static struct test_model oracle(const struct test_case *,unsigned,uint64_t,unsigned char *,unsigned char *,unsigned char *);
__attribute__((noinline)) uint64_t complete_clobber(uint64_t a,uint64_t b,uint64_t c,uint64_t d,uint64_t e,uint64_t f,uint64_t g,uint64_t h){
    __asm__ volatile("":::"rax","rcx","rdx","rsi","rdi","r8","r9","r10","r11","xmm0","xmm1","xmm2","xmm3","xmm4","xmm5","xmm6","xmm7","memory");
    return a^(b*3)^(c*5)^(d*7)^(e*11)^(f*13)^(g*17)^(h*19);
}
static uint64_t clobber_model(uint64_t salt){return salt^6^15^28^55^78^119^152;}
static int matching(const unsigned char *a,const unsigned char *b,size_t n,size_t masked,unsigned mask){
#ifndef DRIVER_BYTE_MASK
#define DRIVER_BYTE_MASK(index) 255
#endif
    for(size_t j=0;j<n;j++)if((a[j]&(j==masked?mask:DRIVER_BYTE_MASK(j)))!=(b[j]&(j==masked?mask:DRIVER_BYTE_MASK(j))))return 0;
    return 1;
}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *maps[3];for(unsigned m=0;m<3;m++){
        maps[m]=mmap(0,page*5,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
        if(maps[m]==MAP_FAILED||mprotect(maps[m]+page,page*3,PROT_READ|PROT_WRITE))return 2;
    }
    for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<DRIVER_SEEDS;seed++){
        unsigned char saved[8192],expected_input[256],gold[8208],zeros[8192]={0},guard[8];
        memset(saved,0,sizeof saved);memset(expected_input,0,sizeof expected_input);memset(gold,0,sizeof gold);memset(guard,0xa5,8);
        uint64_t salt=(seed+1)*UINT64_C(0xfedcba9876543211);
        struct test_model model=oracle(&cases[which],seed,salt,saved,expected_input,gold);
        if(!model.input_bytes||model.input_bytes>sizeof saved||!model.expected_bytes||model.expected_bytes>sizeof expected_input||!model.output_bytes||model.output_bytes>sizeof gold)return 2;
        for(unsigned m=0;m<2;m++)if(mprotect(maps[m]+page,page*3,PROT_READ|PROT_WRITE))return 2;
        unsigned char *input=maps[0]+4*page-model.input_bytes,*expected=maps[1]+4*page-model.expected_bytes,*out=maps[2]+4*page-model.output_bytes-8;
        memcpy(input,saved,model.input_bytes);memcpy(expected,expected_input,model.expected_bytes);
        memcpy(input-8,guard,8);memcpy(expected-8,guard,8);memset(out-8,0xa5,model.output_bytes+16);
        if(!cases[which].mutate&&mprotect(maps[0]+page,page*3,PROT_READ))return 2;
        if(mprotect(maps[1]+page,page*3,PROT_READ))return 2;
        uint64_t answer=cases[which].run(out,input,expected,salt);
        if(fault==1)out[0]^=1;if(fault==2)answer^=1;if(fault==3)out[model.output_bytes]^=1;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"%s case=%zu bits=%u kind=%u mutate=%u seed=%u observation=%zu fault=%u\n",DRIVER_NAME,which,cases[which].bits,cases[which].kind,cases[which].mutate,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==model.answer);
        CHECK(matching(out,gold,model.output_bytes,model.masked_byte,model.last_mask));
        CHECK(matching(input,cases[which].mutate?zeros:saved,model.input_bytes,cases[which].mutate?model.input_bytes-1:SIZE_MAX,cases[which].mutate?model.last_mask:255));
        CHECK(memcmp(expected,expected_input,model.expected_bytes)==0);
        CHECK(memcmp(input-8,guard,8)==0);CHECK(memcmp(expected-8,guard,8)==0);
        CHECK(memcmp(out-8,guard,8)==0);CHECK(memcmp(out+model.output_bytes,guard,8)==0);
#undef CHECK
    }
    printf("%s observations=%zu %s\n",DRIVER_NAME,observations,DRIVER_CONTRACT);
    for(unsigned m=0;m<3;m++)if(munmap(maps[m],page*5))return 2;
    return 0;
}
static void boolean_float_input(unsigned bits,unsigned kind,unsigned char *out){
    uint64_t lo=0,hi=0;
    if(bits==16){uint16_t values[]={0,0x8000,0x3c00,0xbc00,0x7c00,0xfc00,1,0x7bff,0x7e01,0x7c01};memcpy(out,&values[kind],2);return;}
    if(bits==32){uint32_t values[]={0,0x80000000,0x3f800000,0xbf800000,0x7f800000,0xff800000,1,0x7f7fffff,0x7fc00001,0x7f800001};memcpy(out,&values[kind],4);return;}
    if(bits==64){uint64_t values[]={0,UINT64_C(0x8000000000000000),UINT64_C(0x3ff0000000000000),UINT64_C(0xbff0000000000000),UINT64_C(0x7ff0000000000000),UINT64_C(0xfff0000000000000),1,UINT64_C(0x7fefffffffffffff),UINT64_C(0x7ff8000000000001),UINT64_C(0x7ff0000000000001)};memcpy(out,&values[kind],8);return;}
    if(bits==80){uint16_t exponent[]={0,0x8000,0x3fff,0xbfff,0x7fff,0xffff,0,0x7ffe,0x7fff,0x7fff};uint64_t significand[]={0,0,UINT64_C(0x8000000000000000),UINT64_C(0x8000000000000000),UINT64_C(0x8000000000000000),UINT64_C(0x8000000000000000),1,UINT64_MAX,UINT64_C(0xc000000000000001),UINT64_C(0x8000000000000001)};memcpy(out,&significand[kind],8);memcpy(out+8,&exponent[kind],2);return;}
    {uint64_t high[]={0,UINT64_C(0x8000000000000000),UINT64_C(0x3fff000000000000),UINT64_C(0xbfff000000000000),UINT64_C(0x7fff000000000000),UINT64_C(0xffff000000000000),0,UINT64_C(0x7ffeffffffffffff),UINT64_C(0x7fff800000000000),UINT64_C(0x7fff000000000000)};hi=high[kind];lo=kind==7?UINT64_MAX:kind>=6?1:0;}
    memcpy(out,&lo,8);memcpy(out+8,&hi,8);
}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;unsigned first=seed%10,second=(seed+3)%10;size_t stride=item->bits>=80?16:item->bits/8;memset(input,0,stride*item->kind);boolean_float_input(item->bits,first,input);if(item->kind==2)boolean_float_input(item->bits,second,input+stride);
    uint64_t result=first<8&&(item->kind==1||second<8),token=clobber_model(salt);memcpy(gold,&result,8);memcpy(gold+8,&token,8);
    return (struct test_model){stride*item->kind,1,16,SIZE_MAX,255,result^token};
}
extern uint64_t floating_boolean_probe_0(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_1(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_2(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_3(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_4(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_5(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_6(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_7(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_8(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_9(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_10(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_11(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_12(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_13(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_14(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_15(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_16(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_17(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_18(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_19(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_20(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_21(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_22(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_23(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_24(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_25(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_26(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_27(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_28(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_29(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_30(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_31(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_32(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_33(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_34(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_35(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_36(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_37(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_38(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_39(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_40(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_41(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_42(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_43(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_44(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_45(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_46(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_47(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_48(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_49(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_50(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_51(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_52(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_53(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_54(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_55(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_56(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_57(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_58(void *,void *,const void *,uint64_t);
extern uint64_t floating_boolean_probe_59(void *,void *,const void *,uint64_t);
static const struct test_case cases[]={
{floating_boolean_probe_0,16,1,0},
{floating_boolean_probe_1,16,1,0},
{floating_boolean_probe_2,16,1,0},
{floating_boolean_probe_3,16,2,0},
{floating_boolean_probe_4,16,2,0},
{floating_boolean_probe_5,16,2,0},
{floating_boolean_probe_6,16,1,0},
{floating_boolean_probe_7,16,1,0},
{floating_boolean_probe_8,16,1,0},
{floating_boolean_probe_9,16,2,0},
{floating_boolean_probe_10,16,2,0},
{floating_boolean_probe_11,16,2,0},
{floating_boolean_probe_12,32,1,0},
{floating_boolean_probe_13,32,1,0},
{floating_boolean_probe_14,32,1,0},
{floating_boolean_probe_15,32,2,0},
{floating_boolean_probe_16,32,2,0},
{floating_boolean_probe_17,32,2,0},
{floating_boolean_probe_18,32,1,0},
{floating_boolean_probe_19,32,1,0},
{floating_boolean_probe_20,32,1,0},
{floating_boolean_probe_21,32,2,0},
{floating_boolean_probe_22,32,2,0},
{floating_boolean_probe_23,32,2,0},
{floating_boolean_probe_24,64,1,0},
{floating_boolean_probe_25,64,1,0},
{floating_boolean_probe_26,64,1,0},
{floating_boolean_probe_27,64,2,0},
{floating_boolean_probe_28,64,2,0},
{floating_boolean_probe_29,64,2,0},
{floating_boolean_probe_30,64,1,0},
{floating_boolean_probe_31,64,1,0},
{floating_boolean_probe_32,64,1,0},
{floating_boolean_probe_33,64,2,0},
{floating_boolean_probe_34,64,2,0},
{floating_boolean_probe_35,64,2,0},
{floating_boolean_probe_36,80,1,0},
{floating_boolean_probe_37,80,1,0},
{floating_boolean_probe_38,80,1,0},
{floating_boolean_probe_39,80,2,0},
{floating_boolean_probe_40,80,2,0},
{floating_boolean_probe_41,80,2,0},
{floating_boolean_probe_42,80,1,0},
{floating_boolean_probe_43,80,1,0},
{floating_boolean_probe_44,80,1,0},
{floating_boolean_probe_45,80,2,0},
{floating_boolean_probe_46,80,2,0},
{floating_boolean_probe_47,80,2,0},
{floating_boolean_probe_48,128,1,0},
{floating_boolean_probe_49,128,1,0},
{floating_boolean_probe_50,128,1,0},
{floating_boolean_probe_51,128,2,0},
{floating_boolean_probe_52,128,2,0},
{floating_boolean_probe_53,128,2,0},
{floating_boolean_probe_54,128,1,0},
{floating_boolean_probe_55,128,1,0},
{floating_boolean_probe_56,128,1,0},
{floating_boolean_probe_57,128,2,0},
{floating_boolean_probe_58,128,2,0},
{floating_boolean_probe_59,128,2,0},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
