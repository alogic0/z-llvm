#define DRIVER_NAME "intrinsic-pointer-facts"
#define DRIVER_SEEDS 64
#define DRIVER_CONTRACT "independent-integer-byte-goldens=checked-pointer-facts=prefetch-memory=variadic-start-copy-end=independent-cursors=gp-overflow=call-clobbers=guard-pages=preserved"
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
    (void)expected;uint64_t state=seed+UINT64_C(0x123456789abcdef1),sum=0,first=0;unsigned count=item->kind?item->kind%16:1;
    for(unsigned i=0;i<count;i++){state=state*UINT64_C(6364136223846793005)+1;memcpy(input+i*8,&state,8);memcpy(gold+i*8,&state,8);sum+=state;if(!i)first=state;}
    uint64_t token=clobber_model(salt);if(!item->kind){memcpy(gold+8,&token,8);return (struct test_model){8,1,16,SIZE_MAX,255,token};}
    if(item->kind>=16)sum+=first;return (struct test_model){count*8,1,count*8,SIZE_MAX,255,sum^token};
}
extern uint64_t intrinsic_pointer_probe_0(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_1(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_2(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_3(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_4(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_5(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_6(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_7(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_8(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_9(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_10(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_11(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_12(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_13(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_14(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_15(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_16(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_17(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_18(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_19(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_20(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_21(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_22(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_23(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_24(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_25(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_26(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_27(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_28(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_29(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_30(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_31(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_32(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_33(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_34(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_35(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_36(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_37(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_38(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_39(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_40(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_41(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_42(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_43(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_44(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_45(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_46(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_47(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_48(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_49(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_50(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_51(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_52(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_53(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_54(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_55(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_56(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_57(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_58(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_59(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_60(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_61(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_62(void *,void *,const void *,uint64_t);
extern uint64_t intrinsic_pointer_probe_63(void *,void *,const void *,uint64_t);
static const struct test_case cases[]={
{intrinsic_pointer_probe_0,64,0,0},
{intrinsic_pointer_probe_1,64,0,0},
{intrinsic_pointer_probe_2,64,0,0},
{intrinsic_pointer_probe_3,64,0,0},
{intrinsic_pointer_probe_4,64,0,0},
{intrinsic_pointer_probe_5,64,0,0},
{intrinsic_pointer_probe_6,64,0,0},
{intrinsic_pointer_probe_7,64,0,0},
{intrinsic_pointer_probe_8,64,0,0},
{intrinsic_pointer_probe_9,64,0,0},
{intrinsic_pointer_probe_10,64,0,0},
{intrinsic_pointer_probe_11,64,0,0},
{intrinsic_pointer_probe_12,64,0,0},
{intrinsic_pointer_probe_13,64,0,0},
{intrinsic_pointer_probe_14,64,0,0},
{intrinsic_pointer_probe_15,64,0,0},
{intrinsic_pointer_probe_16,64,0,0},
{intrinsic_pointer_probe_17,64,0,0},
{intrinsic_pointer_probe_18,64,0,0},
{intrinsic_pointer_probe_19,64,0,0},
{intrinsic_pointer_probe_20,64,0,0},
{intrinsic_pointer_probe_21,64,0,0},
{intrinsic_pointer_probe_22,64,0,0},
{intrinsic_pointer_probe_23,64,0,0},
{intrinsic_pointer_probe_24,64,0,0},
{intrinsic_pointer_probe_25,64,0,0},
{intrinsic_pointer_probe_26,64,0,0},
{intrinsic_pointer_probe_27,64,0,0},
{intrinsic_pointer_probe_28,64,0,0},
{intrinsic_pointer_probe_29,64,0,0},
{intrinsic_pointer_probe_30,64,0,0},
{intrinsic_pointer_probe_31,64,0,0},
{intrinsic_pointer_probe_32,64,1,0},
{intrinsic_pointer_probe_33,64,17,0},
{intrinsic_pointer_probe_34,64,4,0},
{intrinsic_pointer_probe_35,64,20,0},
{intrinsic_pointer_probe_36,64,5,0},
{intrinsic_pointer_probe_37,64,21,0},
{intrinsic_pointer_probe_38,64,10,0},
{intrinsic_pointer_probe_39,64,26,0},
{intrinsic_pointer_probe_40,64,1,0},
{intrinsic_pointer_probe_41,64,17,0},
{intrinsic_pointer_probe_42,64,4,0},
{intrinsic_pointer_probe_43,64,20,0},
{intrinsic_pointer_probe_44,64,5,0},
{intrinsic_pointer_probe_45,64,21,0},
{intrinsic_pointer_probe_46,64,10,0},
{intrinsic_pointer_probe_47,64,26,0},
{intrinsic_pointer_probe_48,64,1,0},
{intrinsic_pointer_probe_49,64,17,0},
{intrinsic_pointer_probe_50,64,4,0},
{intrinsic_pointer_probe_51,64,20,0},
{intrinsic_pointer_probe_52,64,5,0},
{intrinsic_pointer_probe_53,64,21,0},
{intrinsic_pointer_probe_54,64,10,0},
{intrinsic_pointer_probe_55,64,26,0},
{intrinsic_pointer_probe_56,64,1,0},
{intrinsic_pointer_probe_57,64,17,0},
{intrinsic_pointer_probe_58,64,4,0},
{intrinsic_pointer_probe_59,64,20,0},
{intrinsic_pointer_probe_60,64,5,0},
{intrinsic_pointer_probe_61,64,21,0},
{intrinsic_pointer_probe_62,64,10,0},
{intrinsic_pointer_probe_63,64,26,0},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
