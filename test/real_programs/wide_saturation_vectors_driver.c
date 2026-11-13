#define DRIVER_NAME "wide-saturation-vectors"
#define DRIVER_SEEDS 64
#define DRIVER_CONTRACT "independent-c-bit-model=i140-and-i200-saturating-shifts=four-private-i140-lanes=all-ten-comparisons=literal-and-constructed-operands=optional-tail-hints=dirty-input-padding=live-limbs-after-clobbers=exact-output-bytes=guard-pages=preserved"
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
/* Independent bit model: no wide C arithmetic or backend limb algorithm. */
struct wide_bits { uint64_t word[4]; };
static unsigned wide_bit(struct wide_bits value,unsigned bit){return (unsigned)((value.word[bit/64]>>(bit%64))&1);}
static void wide_set(struct wide_bits *value,unsigned bit){value->word[bit/64]|=UINT64_C(1)<<(bit%64);}
static struct wide_bits wide_read(const unsigned char *input,unsigned bits){
    struct wide_bits value={{0,0,0,0}};
    for(unsigned bit=0;bit<bits;bit++)if((input[bit/8]>>(bit%8))&1)wide_set(&value,bit);
    return value;
}
static struct wide_bits wide_sat(struct wide_bits value,unsigned bits,unsigned shift,unsigned is_signed){
    struct wide_bits result={{0,0,0,0}};unsigned overflow=0,sign=wide_bit(value,bits-1);
    for(unsigned bit=shift;bit<bits;bit++)if(wide_bit(value,bit-shift))wide_set(&result,bit);
    if(is_signed){
        for(unsigned bit=bits-shift-1;bit<bits;bit++)if(wide_bit(value,bit)!=sign)overflow=1;
    }else{
        for(unsigned bit=bits-shift;bit<bits;bit++)if(wide_bit(value,bit))overflow=1;
    }
    if(overflow){
        memset(&result,0,sizeof result);
        for(unsigned bit=0;bit<bits;bit++)if(!is_signed||((bit==bits-1)==(sign!=0)))wide_set(&result,bit);
    }
    return result;
}
static int wide_cmp(struct wide_bits left,struct wide_bits right,unsigned bits,unsigned is_signed){
    unsigned ls=wide_bit(left,bits-1),rs=wide_bit(right,bits-1);
    if(is_signed&&ls!=rs)return ls?-1:1;
    for(unsigned bit=bits;bit>0;bit--){unsigned l=wide_bit(left,bit-1),r=wide_bit(right,bit-1);if(l!=r)return l?1:-1;}
    return 0;
}
static unsigned wide_pred(unsigned predicate,int comparison){
    switch(predicate){case 0:return comparison==0;case 1:return comparison!=0;case 2:case 6:return comparison>0;case 3:case 7:return comparison>=0;case 4:case 8:return comparison<0;default:return comparison<=0;}
}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;
    for(unsigned i=0;i<80;i++)input[i]=(unsigned char)(((seed+1)*UINT64_C(0x9182736455aaccdd)>>(8*(i%8)))^(i*71));
    for(unsigned which=0;which<2;which++){
        unsigned bits=which?200:140,offset=which?32:0,bytes=(bits+7)/8;
        if(seed<8){
            memset(input+offset,0,32);
            if(seed==1)memset(input+offset,255,bytes);
            if(seed==2)input[offset+(bits-1)/8]=(unsigned char)(1U<<((bits-1)%8));
            if(seed==3){memset(input+offset,255,bytes);input[offset+(bits-1)/8]&=(unsigned char)~(1U<<((bits-1)%8));}
            if(seed==4)input[offset+100/8]=(unsigned char)(1U<<(100%8));
            if(seed==5)input[offset]=1;
            if(seed==6)input[offset+128/8]=1;
            if(seed==7)input[offset+bytes-1]=(unsigned char)(255U<<((bits-1)%8+1));
        }
    }
    static const unsigned shifts140[16]={0,1,17,20,38,39,63,64,65,100,127,128,137,138,139,5};
    static const unsigned shifts200[16]={0,1,17,38,63,64,65,100,127,128,139,190,197,198,199,5};
    uint64_t s=shifts140[seed%16],t=shifts200[(seed*5)%16];memcpy(input+64,&s,8);memcpy(input+72,&t,8);
    struct wide_bits a=wide_read(input,140),b=wide_read(input+32,200),constant={{0,0,0,0}},results[6],right[4];wide_set(&constant,100);
    results[0]=wide_sat(a,140,(unsigned)s,0);results[1]=wide_sat(a,140,(unsigned)s,1);
    results[2]=wide_sat(constant,140,(unsigned)s,0);results[3]=wide_sat(constant,140,(unsigned)s,1);
    results[4]=wide_sat(b,200,(unsigned)t,0);results[5]=wide_sat(b,200,(unsigned)t,1);
    memset(right,0,sizeof right);
    for(unsigned bit=0;bit<140;bit++)wide_set(&right[1],bit);
    for(unsigned bit=0;bit<139;bit++)wide_set(&right[2],bit);wide_set(&right[3],139);
    unsigned predicate=item->kind/2;uint64_t mask=0,token=clobber_model(salt);
    for(unsigned lane=0;lane<4;lane++)if(wide_pred(predicate,wide_cmp(results[lane],right[lane],140,predicate>=6)))mask|=UINT64_C(1)<<lane;
    size_t out=0;
    for(unsigned i=0;i<6;i++)for(unsigned word=0;word<(i<4?3U:4U);word++){memcpy(gold+out,&results[i].word[word],8);out+=8;}
    memcpy(gold+160,&mask,8);memcpy(gold+168,&token,8);
    return (struct test_model){80,1,176,SIZE_MAX,255,token^mask};
}
extern uint64_t wide_saturation_vector_probe_0(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_1(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_2(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_3(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_4(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_5(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_6(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_7(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_8(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_9(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_10(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_11(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_12(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_13(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_14(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_15(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_16(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_17(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_18(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_19(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_20(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_21(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_22(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_23(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_24(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_25(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_26(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_27(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_28(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_29(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_30(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_31(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_32(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_33(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_34(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_35(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_36(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_37(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_38(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_39(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_40(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_41(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_42(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_43(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_44(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_45(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_46(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_47(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_48(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_49(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_50(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_51(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_52(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_53(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_54(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_55(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_56(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_57(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_58(void *,void *,const void *,uint64_t);
extern uint64_t wide_saturation_vector_probe_59(void *,void *,const void *,uint64_t);
static const struct test_case cases[]={
{wide_saturation_vector_probe_0,140,0,0},
{wide_saturation_vector_probe_1,140,0,0},
{wide_saturation_vector_probe_2,140,0,0},
{wide_saturation_vector_probe_3,140,1,0},
{wide_saturation_vector_probe_4,140,1,0},
{wide_saturation_vector_probe_5,140,1,0},
{wide_saturation_vector_probe_6,140,2,0},
{wide_saturation_vector_probe_7,140,2,0},
{wide_saturation_vector_probe_8,140,2,0},
{wide_saturation_vector_probe_9,140,3,0},
{wide_saturation_vector_probe_10,140,3,0},
{wide_saturation_vector_probe_11,140,3,0},
{wide_saturation_vector_probe_12,140,4,0},
{wide_saturation_vector_probe_13,140,4,0},
{wide_saturation_vector_probe_14,140,4,0},
{wide_saturation_vector_probe_15,140,5,0},
{wide_saturation_vector_probe_16,140,5,0},
{wide_saturation_vector_probe_17,140,5,0},
{wide_saturation_vector_probe_18,140,6,0},
{wide_saturation_vector_probe_19,140,6,0},
{wide_saturation_vector_probe_20,140,6,0},
{wide_saturation_vector_probe_21,140,7,0},
{wide_saturation_vector_probe_22,140,7,0},
{wide_saturation_vector_probe_23,140,7,0},
{wide_saturation_vector_probe_24,140,8,0},
{wide_saturation_vector_probe_25,140,8,0},
{wide_saturation_vector_probe_26,140,8,0},
{wide_saturation_vector_probe_27,140,9,0},
{wide_saturation_vector_probe_28,140,9,0},
{wide_saturation_vector_probe_29,140,9,0},
{wide_saturation_vector_probe_30,140,10,0},
{wide_saturation_vector_probe_31,140,10,0},
{wide_saturation_vector_probe_32,140,10,0},
{wide_saturation_vector_probe_33,140,11,0},
{wide_saturation_vector_probe_34,140,11,0},
{wide_saturation_vector_probe_35,140,11,0},
{wide_saturation_vector_probe_36,140,12,0},
{wide_saturation_vector_probe_37,140,12,0},
{wide_saturation_vector_probe_38,140,12,0},
{wide_saturation_vector_probe_39,140,13,0},
{wide_saturation_vector_probe_40,140,13,0},
{wide_saturation_vector_probe_41,140,13,0},
{wide_saturation_vector_probe_42,140,14,0},
{wide_saturation_vector_probe_43,140,14,0},
{wide_saturation_vector_probe_44,140,14,0},
{wide_saturation_vector_probe_45,140,15,0},
{wide_saturation_vector_probe_46,140,15,0},
{wide_saturation_vector_probe_47,140,15,0},
{wide_saturation_vector_probe_48,140,16,0},
{wide_saturation_vector_probe_49,140,16,0},
{wide_saturation_vector_probe_50,140,16,0},
{wide_saturation_vector_probe_51,140,17,0},
{wide_saturation_vector_probe_52,140,17,0},
{wide_saturation_vector_probe_53,140,17,0},
{wide_saturation_vector_probe_54,140,18,0},
{wide_saturation_vector_probe_55,140,18,0},
{wide_saturation_vector_probe_56,140,18,0},
{wide_saturation_vector_probe_57,140,19,0},
{wide_saturation_vector_probe_58,140,19,0},
{wide_saturation_vector_probe_59,140,19,0},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
