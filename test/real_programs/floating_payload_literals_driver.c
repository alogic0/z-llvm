#define DRIVER_NAME "floating-payload-literals"
#define DRIVER_SEEDS 64
#define DRIVER_CONTRACT "integer-bit-goldens=signaling-and-quiet-nans=payloads-and-signs=literal-stores=call-arguments=returns=bitcasts=call-clobbers=guard-pages=preserved"
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
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;uint32_t literal=item->bits,dynamic=seed*UINT32_C(0x9e3779b1)^UINT32_C(0xa5a5a5a5);
    uint64_t token=clobber_model(salt);memcpy(input,&dynamic,4);
    for(unsigned i=0;i<4;i++)memcpy(gold+i*4,&literal,4);
    memcpy(gold+16,&dynamic,4);memcpy(gold+20,&token,8);
    return (struct test_model){4,1,28,SIZE_MAX,255,token};
}
extern uint64_t floating_payload_probe_0(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_1(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_2(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_3(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_4(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_5(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_6(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_7(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_8(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_9(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_10(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_11(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_12(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_13(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_14(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_15(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_16(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_17(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_18(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_19(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_20(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_21(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_22(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_23(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_24(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_25(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_26(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_27(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_28(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_29(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_30(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_31(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_32(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_33(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_34(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_35(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_36(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_37(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_38(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_39(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_40(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_41(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_42(void *,void *,const void *,uint64_t);
extern uint64_t floating_payload_probe_43(void *,void *,const void *,uint64_t);
static const struct test_case cases[]={
{floating_payload_probe_0,0,0,0},
{floating_payload_probe_1,0,1,0},
{floating_payload_probe_2,2147483648,0,0},
{floating_payload_probe_3,2147483648,1,0},
{floating_payload_probe_4,2139095040,0,0},
{floating_payload_probe_5,2139095040,1,0},
{floating_payload_probe_6,4286578688,0,0},
{floating_payload_probe_7,4286578688,1,0},
{floating_payload_probe_8,2139095041,0,0},
{floating_payload_probe_9,2139095041,1,0},
{floating_payload_probe_10,4286578689,0,0},
{floating_payload_probe_11,4286578689,1,0},
{floating_payload_probe_12,2141192192,0,0},
{floating_payload_probe_13,2141192192,1,0},
{floating_payload_probe_14,4288675840,0,0},
{floating_payload_probe_15,4288675840,1,0},
{floating_payload_probe_16,2143289343,0,0},
{floating_payload_probe_17,2143289343,1,0},
{floating_payload_probe_18,4290772991,0,0},
{floating_payload_probe_19,4290772991,1,0},
{floating_payload_probe_20,2143289344,0,0},
{floating_payload_probe_21,2143289344,1,0},
{floating_payload_probe_22,4290772992,0,0},
{floating_payload_probe_23,4290772992,1,0},
{floating_payload_probe_24,2147483647,0,0},
{floating_payload_probe_25,2147483647,1,0},
{floating_payload_probe_26,4294967295,0,0},
{floating_payload_probe_27,4294967295,1,0},
{floating_payload_probe_28,1,0,0},
{floating_payload_probe_29,1,1,0},
{floating_payload_probe_30,2147483649,0,0},
{floating_payload_probe_31,2147483649,1,0},
{floating_payload_probe_32,8388607,0,0},
{floating_payload_probe_33,8388607,1,0},
{floating_payload_probe_34,2155872255,0,0},
{floating_payload_probe_35,2155872255,1,0},
{floating_payload_probe_36,1065353216,0,0},
{floating_payload_probe_37,1065353216,1,0},
{floating_payload_probe_38,3212836864,0,0},
{floating_payload_probe_39,3212836864,1,0},
{floating_payload_probe_40,2139095039,0,0},
{floating_payload_probe_41,2139095039,1,0},
{floating_payload_probe_42,4286578687,0,0},
{floating_payload_probe_43,4286578687,1,0},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
