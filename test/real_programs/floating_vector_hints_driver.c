#define DRIVER_NAME "floating-vector-hints"
#define DRIVER_SEEDS 64
#define DRIVER_CONTRACT "independent-integer-payload-goldens=four-double-x87-and-quad=fastcc-optional-tail-and-notail=literal-and-dynamic-vectors=one-and-two-vector-arguments=caller-and-callee-call-clobbers=source-and-output-guards=preserved"
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
static void floating_hint_lane(unsigned bits,unsigned kind,unsigned char *out){
    uint64_t low=0,high=0;
    if(bits==64){static const uint64_t values[]={UINT64_C(0x3ff0000000000000),UINT64_C(0x8000000000000000),UINT64_C(0x7ff8000000000001),UINT64_C(0xc000000000000000),0,1,UINT64_C(0x7ff0000000000000),UINT64_C(0xfff0000000000000)};memcpy(out,&values[kind],8);return;}
    if(bits==80){static const uint64_t fraction[]={UINT64_C(0x8000000000000000),0,UINT64_C(0xc000000000000000),UINT64_C(0x8000000000000000),0,1,UINT64_C(0x8000000000000000),UINT64_C(0x8000000000000000)};static const uint16_t exponent[]={0x3fff,0x8000,0x4000,0xbfff,0,0,0x7fff,0xffff};memcpy(out,&fraction[kind],8);memcpy(out+8,&exponent[kind],2);return;}
    {static const uint64_t upper[]={UINT64_C(0x3fff000000000000),UINT64_C(0x8000000000000000),UINT64_C(0x40007fff00000000),UINT64_C(0xc000000000000000),0,0,UINT64_C(0x7fff000000000000),UINT64_C(0xffff000000000000)};high=upper[kind];low=kind==2||kind==5?1:0;}
    memcpy(out,&low,8);memcpy(out+8,&high,8);
}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;unsigned arity=item->kind/2,literal=item->kind%2;size_t bytes=item->bits/8,payload=4*arity*bytes;
    for(unsigned i=0;i<4*arity;i++){floating_hint_lane(item->bits,(seed+i)%8,input+i*bytes);floating_hint_lane(item->bits,literal?i%4:(seed+i)%8,gold+i*bytes);}
    uint64_t token=clobber_model(salt);memcpy(gold+payload,&token,8);memcpy(gold+payload+8,gold,payload);memcpy(gold+2*payload+8,&token,8);
    return (struct test_model){payload,1,2*payload+16,SIZE_MAX,255,token^salt};
}
extern uint64_t floating_hint_probe_0(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_1(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_2(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_3(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_4(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_5(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_6(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_7(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_8(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_9(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_10(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_11(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_12(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_13(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_14(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_15(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_16(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_17(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_18(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_19(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_20(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_21(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_22(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_23(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_24(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_25(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_26(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_27(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_28(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_29(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_30(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_31(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_32(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_33(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_34(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_35(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_36(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_37(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_38(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_39(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_40(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_41(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_42(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_43(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_44(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_45(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_46(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_47(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_48(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_49(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_50(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_51(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_52(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_53(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_54(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_55(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_56(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_57(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_58(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_59(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_60(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_61(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_62(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_63(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_64(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_65(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_66(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_67(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_68(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_69(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_70(void *,void *,const void *,uint64_t);
extern uint64_t floating_hint_probe_71(void *,void *,const void *,uint64_t);
static const struct test_case cases[]={
{floating_hint_probe_0,64,2,0},
{floating_hint_probe_1,64,2,0},
{floating_hint_probe_2,64,2,0},
{floating_hint_probe_3,64,2,0},
{floating_hint_probe_4,64,2,0},
{floating_hint_probe_5,64,2,0},
{floating_hint_probe_6,64,3,0},
{floating_hint_probe_7,64,3,0},
{floating_hint_probe_8,64,3,0},
{floating_hint_probe_9,64,3,0},
{floating_hint_probe_10,64,3,0},
{floating_hint_probe_11,64,3,0},
{floating_hint_probe_12,64,4,0},
{floating_hint_probe_13,64,4,0},
{floating_hint_probe_14,64,4,0},
{floating_hint_probe_15,64,4,0},
{floating_hint_probe_16,64,4,0},
{floating_hint_probe_17,64,4,0},
{floating_hint_probe_18,64,5,0},
{floating_hint_probe_19,64,5,0},
{floating_hint_probe_20,64,5,0},
{floating_hint_probe_21,64,5,0},
{floating_hint_probe_22,64,5,0},
{floating_hint_probe_23,64,5,0},
{floating_hint_probe_24,80,2,0},
{floating_hint_probe_25,80,2,0},
{floating_hint_probe_26,80,2,0},
{floating_hint_probe_27,80,2,0},
{floating_hint_probe_28,80,2,0},
{floating_hint_probe_29,80,2,0},
{floating_hint_probe_30,80,3,0},
{floating_hint_probe_31,80,3,0},
{floating_hint_probe_32,80,3,0},
{floating_hint_probe_33,80,3,0},
{floating_hint_probe_34,80,3,0},
{floating_hint_probe_35,80,3,0},
{floating_hint_probe_36,80,4,0},
{floating_hint_probe_37,80,4,0},
{floating_hint_probe_38,80,4,0},
{floating_hint_probe_39,80,4,0},
{floating_hint_probe_40,80,4,0},
{floating_hint_probe_41,80,4,0},
{floating_hint_probe_42,80,5,0},
{floating_hint_probe_43,80,5,0},
{floating_hint_probe_44,80,5,0},
{floating_hint_probe_45,80,5,0},
{floating_hint_probe_46,80,5,0},
{floating_hint_probe_47,80,5,0},
{floating_hint_probe_48,128,2,0},
{floating_hint_probe_49,128,2,0},
{floating_hint_probe_50,128,2,0},
{floating_hint_probe_51,128,2,0},
{floating_hint_probe_52,128,2,0},
{floating_hint_probe_53,128,2,0},
{floating_hint_probe_54,128,3,0},
{floating_hint_probe_55,128,3,0},
{floating_hint_probe_56,128,3,0},
{floating_hint_probe_57,128,3,0},
{floating_hint_probe_58,128,3,0},
{floating_hint_probe_59,128,3,0},
{floating_hint_probe_60,128,4,0},
{floating_hint_probe_61,128,4,0},
{floating_hint_probe_62,128,4,0},
{floating_hint_probe_63,128,4,0},
{floating_hint_probe_64,128,4,0},
{floating_hint_probe_65,128,4,0},
{floating_hint_probe_66,128,5,0},
{floating_hint_probe_67,128,5,0},
{floating_hint_probe_68,128,5,0},
{floating_hint_probe_69,128,5,0},
{floating_hint_probe_70,128,5,0},
{floating_hint_probe_71,128,5,0},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
