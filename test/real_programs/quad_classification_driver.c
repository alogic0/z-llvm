#define DRIVER_NAME "quad-classification"
#define DRIVER_SEEDS 64
#define DRIVER_CONTRACT "independent-c-integer-classification=all-1024-class-masks=ten-ieee-classes=both-signs=zeros-subnormals-normals-infinities-and-nans=signaling-and-quiet-payloads=optional-call-hints=literal-and-dynamic-inputs=call-clobbers=exact-payloads=guard-pages=preserved"
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
static unsigned quad_classification(uint64_t low,uint64_t high){
    unsigned negative=(unsigned)(high>>63),exponent=(unsigned)((high>>48)&32767);uint64_t fraction=low|(high&UINT64_C(0x0000ffffffffffff));
    if(exponent==32767)return fraction?((high&UINT64_C(0x0000800000000000))?2:1):(negative?4:512);
    if(!exponent)return fraction?(negative?16:128):(negative?32:64);
    return negative?8:256;
}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)expected;unsigned literal=item->kind/1024,mask=item->kind%1024,kind=seed%16;uint64_t low=0,high=0;
    if(literal){static const uint64_t upper[]={0,UINT64_C(0x8000000000000000),UINT64_C(0x7fff800000000000),UINT64_C(0x7fff000000000000)};high=upper[literal-1];low=literal>=3?1:0;}
    else{
        static const uint64_t upper[]={0,0,UINT64_C(0x0000ffffffffffff),UINT64_C(0x0001000000000000),UINT64_C(0x3fff000000000000),UINT64_C(0x7ffeffffffffffff),UINT64_C(0x7fff000000000000),UINT64_C(0x7fff800000000000),UINT64_C(0x7fff000000000000),UINT64_C(0x7fff400000000000),UINT64_C(0x4000123456789abc),UINT64_C(0x0001000000000001),UINT64_C(0x7fffffffffffffff),UINT64_C(0x7fff000000000001),UINT64_C(0x0020000000000000),UINT64_C(0x7000000000000000)};
        high=upper[kind];low=kind==1||kind==8||kind==13?1:kind==2||kind==5||kind==12?UINT64_MAX:0;
        if(seed&16)high|=UINT64_C(0x8000000000000000);if(seed>=32&&kind!=0&&kind!=6)low|=UINT64_C(0x123456789abcdef0);
    }
    memcpy(input,&low,8);memcpy(input+8,&high,8);uint64_t flag=(quad_classification(low,high)&mask)!=0,token=clobber_model(salt);memcpy(gold,&flag,8);memcpy(gold+8,&token,8);memcpy(gold+16,input,16);
    return (struct test_model){16,1,32,SIZE_MAX,255,flag^token};
}
extern uint64_t quad_classification_probe_0(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_2(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_3(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_4(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_5(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_6(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_7(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_8(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_9(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_10(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_11(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_12(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_13(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_14(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_15(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_16(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_17(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_18(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_19(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_20(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_21(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_22(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_23(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_24(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_25(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_26(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_27(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_28(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_29(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_30(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_31(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_32(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_33(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_34(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_35(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_36(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_37(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_38(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_39(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_40(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_41(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_42(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_43(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_44(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_45(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_46(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_47(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_48(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_49(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_50(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_51(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_52(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_53(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_54(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_55(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_56(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_57(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_58(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_59(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_60(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_61(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_62(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_63(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_64(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_65(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_66(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_67(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_68(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_69(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_70(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_71(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_72(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_73(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_74(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_75(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_76(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_77(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_78(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_79(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_80(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_81(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_82(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_83(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_84(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_85(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_86(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_87(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_88(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_89(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_90(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_91(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_92(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_93(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_94(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_95(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_96(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_97(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_98(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_99(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_100(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_101(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_102(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_103(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_104(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_105(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_106(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_107(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_108(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_109(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_110(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_111(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_112(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_113(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_114(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_115(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_116(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_117(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_118(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_119(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_120(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_121(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_122(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_123(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_124(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_125(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_126(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_127(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_128(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_129(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_130(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_131(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_132(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_133(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_134(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_135(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_136(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_137(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_138(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_139(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_140(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_141(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_142(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_143(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_144(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_145(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_146(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_147(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_148(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_149(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_150(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_151(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_152(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_153(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_154(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_155(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_156(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_157(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_158(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_159(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_160(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_161(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_162(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_163(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_164(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_165(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_166(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_167(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_168(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_169(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_170(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_171(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_172(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_173(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_174(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_175(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_176(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_177(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_178(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_179(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_180(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_181(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_182(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_183(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_184(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_185(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_186(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_187(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_188(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_189(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_190(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_191(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_192(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_193(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_194(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_195(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_196(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_197(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_198(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_199(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_200(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_201(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_202(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_203(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_204(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_205(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_206(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_207(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_208(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_209(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_210(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_211(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_212(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_213(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_214(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_215(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_216(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_217(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_218(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_219(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_220(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_221(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_222(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_223(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_224(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_225(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_226(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_227(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_228(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_229(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_230(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_231(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_232(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_233(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_234(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_235(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_236(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_237(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_238(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_239(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_240(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_241(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_242(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_243(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_244(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_245(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_246(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_247(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_248(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_249(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_250(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_251(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_252(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_253(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_254(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_255(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_256(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_257(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_258(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_259(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_260(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_261(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_262(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_263(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_264(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_265(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_266(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_267(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_268(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_269(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_270(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_271(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_272(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_273(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_274(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_275(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_276(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_277(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_278(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_279(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_280(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_281(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_282(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_283(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_284(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_285(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_286(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_287(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_288(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_289(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_290(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_291(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_292(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_293(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_294(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_295(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_296(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_297(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_298(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_299(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_300(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_301(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_302(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_303(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_304(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_305(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_306(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_307(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_308(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_309(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_310(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_311(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_312(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_313(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_314(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_315(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_316(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_317(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_318(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_319(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_320(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_321(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_322(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_323(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_324(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_325(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_326(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_327(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_328(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_329(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_330(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_331(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_332(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_333(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_334(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_335(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_336(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_337(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_338(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_339(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_340(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_341(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_342(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_343(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_344(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_345(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_346(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_347(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_348(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_349(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_350(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_351(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_352(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_353(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_354(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_355(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_356(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_357(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_358(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_359(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_360(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_361(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_362(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_363(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_364(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_365(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_366(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_367(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_368(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_369(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_370(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_371(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_372(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_373(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_374(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_375(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_376(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_377(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_378(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_379(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_380(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_381(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_382(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_383(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_384(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_385(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_386(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_387(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_388(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_389(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_390(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_391(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_392(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_393(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_394(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_395(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_396(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_397(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_398(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_399(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_400(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_401(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_402(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_403(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_404(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_405(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_406(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_407(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_408(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_409(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_410(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_411(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_412(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_413(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_414(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_415(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_416(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_417(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_418(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_419(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_420(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_421(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_422(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_423(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_424(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_425(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_426(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_427(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_428(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_429(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_430(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_431(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_432(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_433(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_434(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_435(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_436(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_437(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_438(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_439(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_440(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_441(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_442(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_443(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_444(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_445(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_446(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_447(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_448(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_449(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_450(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_451(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_452(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_453(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_454(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_455(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_456(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_457(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_458(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_459(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_460(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_461(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_462(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_463(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_464(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_465(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_466(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_467(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_468(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_469(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_470(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_471(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_472(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_473(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_474(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_475(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_476(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_477(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_478(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_479(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_480(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_481(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_482(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_483(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_484(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_485(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_486(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_487(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_488(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_489(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_490(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_491(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_492(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_493(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_494(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_495(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_496(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_497(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_498(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_499(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_500(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_501(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_502(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_503(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_504(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_505(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_506(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_507(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_508(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_509(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_510(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_511(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_512(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_513(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_514(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_515(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_516(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_517(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_518(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_519(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_520(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_521(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_522(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_523(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_524(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_525(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_526(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_527(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_528(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_529(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_530(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_531(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_532(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_533(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_534(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_535(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_536(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_537(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_538(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_539(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_540(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_541(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_542(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_543(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_544(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_545(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_546(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_547(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_548(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_549(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_550(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_551(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_552(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_553(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_554(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_555(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_556(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_557(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_558(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_559(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_560(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_561(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_562(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_563(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_564(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_565(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_566(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_567(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_568(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_569(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_570(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_571(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_572(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_573(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_574(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_575(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_576(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_577(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_578(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_579(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_580(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_581(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_582(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_583(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_584(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_585(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_586(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_587(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_588(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_589(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_590(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_591(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_592(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_593(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_594(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_595(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_596(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_597(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_598(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_599(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_600(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_601(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_602(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_603(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_604(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_605(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_606(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_607(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_608(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_609(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_610(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_611(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_612(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_613(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_614(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_615(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_616(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_617(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_618(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_619(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_620(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_621(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_622(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_623(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_624(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_625(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_626(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_627(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_628(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_629(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_630(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_631(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_632(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_633(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_634(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_635(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_636(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_637(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_638(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_639(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_640(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_641(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_642(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_643(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_644(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_645(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_646(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_647(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_648(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_649(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_650(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_651(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_652(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_653(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_654(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_655(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_656(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_657(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_658(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_659(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_660(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_661(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_662(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_663(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_664(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_665(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_666(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_667(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_668(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_669(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_670(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_671(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_672(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_673(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_674(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_675(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_676(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_677(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_678(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_679(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_680(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_681(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_682(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_683(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_684(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_685(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_686(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_687(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_688(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_689(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_690(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_691(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_692(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_693(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_694(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_695(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_696(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_697(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_698(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_699(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_700(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_701(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_702(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_703(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_704(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_705(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_706(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_707(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_708(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_709(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_710(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_711(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_712(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_713(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_714(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_715(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_716(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_717(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_718(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_719(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_720(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_721(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_722(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_723(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_724(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_725(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_726(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_727(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_728(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_729(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_730(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_731(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_732(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_733(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_734(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_735(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_736(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_737(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_738(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_739(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_740(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_741(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_742(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_743(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_744(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_745(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_746(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_747(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_748(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_749(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_750(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_751(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_752(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_753(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_754(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_755(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_756(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_757(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_758(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_759(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_760(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_761(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_762(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_763(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_764(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_765(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_766(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_767(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_768(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_769(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_770(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_771(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_772(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_773(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_774(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_775(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_776(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_777(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_778(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_779(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_780(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_781(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_782(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_783(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_784(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_785(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_786(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_787(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_788(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_789(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_790(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_791(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_792(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_793(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_794(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_795(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_796(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_797(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_798(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_799(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_800(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_801(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_802(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_803(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_804(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_805(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_806(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_807(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_808(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_809(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_810(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_811(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_812(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_813(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_814(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_815(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_816(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_817(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_818(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_819(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_820(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_821(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_822(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_823(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_824(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_825(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_826(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_827(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_828(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_829(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_830(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_831(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_832(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_833(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_834(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_835(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_836(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_837(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_838(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_839(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_840(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_841(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_842(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_843(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_844(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_845(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_846(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_847(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_848(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_849(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_850(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_851(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_852(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_853(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_854(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_855(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_856(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_857(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_858(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_859(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_860(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_861(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_862(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_863(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_864(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_865(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_866(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_867(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_868(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_869(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_870(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_871(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_872(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_873(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_874(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_875(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_876(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_877(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_878(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_879(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_880(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_881(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_882(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_883(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_884(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_885(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_886(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_887(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_888(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_889(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_890(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_891(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_892(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_893(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_894(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_895(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_896(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_897(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_898(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_899(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_900(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_901(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_902(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_903(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_904(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_905(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_906(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_907(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_908(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_909(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_910(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_911(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_912(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_913(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_914(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_915(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_916(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_917(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_918(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_919(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_920(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_921(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_922(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_923(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_924(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_925(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_926(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_927(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_928(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_929(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_930(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_931(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_932(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_933(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_934(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_935(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_936(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_937(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_938(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_939(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_940(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_941(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_942(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_943(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_944(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_945(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_946(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_947(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_948(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_949(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_950(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_951(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_952(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_953(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_954(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_955(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_956(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_957(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_958(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_959(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_960(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_961(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_962(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_963(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_964(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_965(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_966(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_967(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_968(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_969(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_970(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_971(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_972(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_973(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_974(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_975(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_976(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_977(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_978(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_979(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_980(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_981(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_982(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_983(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_984(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_985(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_986(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_987(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_988(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_989(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_990(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_991(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_992(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_993(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_994(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_995(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_996(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_997(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_998(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_999(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1000(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1001(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1002(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1003(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1004(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1005(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1006(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1007(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1008(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1009(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1010(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1011(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1012(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1013(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1014(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1015(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1016(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1017(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1018(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1019(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1020(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1021(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1022(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1023(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1024(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1025(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1026(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1027(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1028(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1029(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1030(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1031(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1032(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1033(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1034(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1035(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1036(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1037(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1038(void *,void *,const void *,uint64_t);
extern uint64_t quad_classification_probe_1039(void *,void *,const void *,uint64_t);
static const struct test_case cases[]={
{quad_classification_probe_0,128,0,0},
{quad_classification_probe_1,128,1,0},
{quad_classification_probe_2,128,2,0},
{quad_classification_probe_3,128,3,0},
{quad_classification_probe_4,128,4,0},
{quad_classification_probe_5,128,5,0},
{quad_classification_probe_6,128,6,0},
{quad_classification_probe_7,128,7,0},
{quad_classification_probe_8,128,8,0},
{quad_classification_probe_9,128,9,0},
{quad_classification_probe_10,128,10,0},
{quad_classification_probe_11,128,11,0},
{quad_classification_probe_12,128,12,0},
{quad_classification_probe_13,128,13,0},
{quad_classification_probe_14,128,14,0},
{quad_classification_probe_15,128,15,0},
{quad_classification_probe_16,128,16,0},
{quad_classification_probe_17,128,17,0},
{quad_classification_probe_18,128,18,0},
{quad_classification_probe_19,128,19,0},
{quad_classification_probe_20,128,20,0},
{quad_classification_probe_21,128,21,0},
{quad_classification_probe_22,128,22,0},
{quad_classification_probe_23,128,23,0},
{quad_classification_probe_24,128,24,0},
{quad_classification_probe_25,128,25,0},
{quad_classification_probe_26,128,26,0},
{quad_classification_probe_27,128,27,0},
{quad_classification_probe_28,128,28,0},
{quad_classification_probe_29,128,29,0},
{quad_classification_probe_30,128,30,0},
{quad_classification_probe_31,128,31,0},
{quad_classification_probe_32,128,32,0},
{quad_classification_probe_33,128,33,0},
{quad_classification_probe_34,128,34,0},
{quad_classification_probe_35,128,35,0},
{quad_classification_probe_36,128,36,0},
{quad_classification_probe_37,128,37,0},
{quad_classification_probe_38,128,38,0},
{quad_classification_probe_39,128,39,0},
{quad_classification_probe_40,128,40,0},
{quad_classification_probe_41,128,41,0},
{quad_classification_probe_42,128,42,0},
{quad_classification_probe_43,128,43,0},
{quad_classification_probe_44,128,44,0},
{quad_classification_probe_45,128,45,0},
{quad_classification_probe_46,128,46,0},
{quad_classification_probe_47,128,47,0},
{quad_classification_probe_48,128,48,0},
{quad_classification_probe_49,128,49,0},
{quad_classification_probe_50,128,50,0},
{quad_classification_probe_51,128,51,0},
{quad_classification_probe_52,128,52,0},
{quad_classification_probe_53,128,53,0},
{quad_classification_probe_54,128,54,0},
{quad_classification_probe_55,128,55,0},
{quad_classification_probe_56,128,56,0},
{quad_classification_probe_57,128,57,0},
{quad_classification_probe_58,128,58,0},
{quad_classification_probe_59,128,59,0},
{quad_classification_probe_60,128,60,0},
{quad_classification_probe_61,128,61,0},
{quad_classification_probe_62,128,62,0},
{quad_classification_probe_63,128,63,0},
{quad_classification_probe_64,128,64,0},
{quad_classification_probe_65,128,65,0},
{quad_classification_probe_66,128,66,0},
{quad_classification_probe_67,128,67,0},
{quad_classification_probe_68,128,68,0},
{quad_classification_probe_69,128,69,0},
{quad_classification_probe_70,128,70,0},
{quad_classification_probe_71,128,71,0},
{quad_classification_probe_72,128,72,0},
{quad_classification_probe_73,128,73,0},
{quad_classification_probe_74,128,74,0},
{quad_classification_probe_75,128,75,0},
{quad_classification_probe_76,128,76,0},
{quad_classification_probe_77,128,77,0},
{quad_classification_probe_78,128,78,0},
{quad_classification_probe_79,128,79,0},
{quad_classification_probe_80,128,80,0},
{quad_classification_probe_81,128,81,0},
{quad_classification_probe_82,128,82,0},
{quad_classification_probe_83,128,83,0},
{quad_classification_probe_84,128,84,0},
{quad_classification_probe_85,128,85,0},
{quad_classification_probe_86,128,86,0},
{quad_classification_probe_87,128,87,0},
{quad_classification_probe_88,128,88,0},
{quad_classification_probe_89,128,89,0},
{quad_classification_probe_90,128,90,0},
{quad_classification_probe_91,128,91,0},
{quad_classification_probe_92,128,92,0},
{quad_classification_probe_93,128,93,0},
{quad_classification_probe_94,128,94,0},
{quad_classification_probe_95,128,95,0},
{quad_classification_probe_96,128,96,0},
{quad_classification_probe_97,128,97,0},
{quad_classification_probe_98,128,98,0},
{quad_classification_probe_99,128,99,0},
{quad_classification_probe_100,128,100,0},
{quad_classification_probe_101,128,101,0},
{quad_classification_probe_102,128,102,0},
{quad_classification_probe_103,128,103,0},
{quad_classification_probe_104,128,104,0},
{quad_classification_probe_105,128,105,0},
{quad_classification_probe_106,128,106,0},
{quad_classification_probe_107,128,107,0},
{quad_classification_probe_108,128,108,0},
{quad_classification_probe_109,128,109,0},
{quad_classification_probe_110,128,110,0},
{quad_classification_probe_111,128,111,0},
{quad_classification_probe_112,128,112,0},
{quad_classification_probe_113,128,113,0},
{quad_classification_probe_114,128,114,0},
{quad_classification_probe_115,128,115,0},
{quad_classification_probe_116,128,116,0},
{quad_classification_probe_117,128,117,0},
{quad_classification_probe_118,128,118,0},
{quad_classification_probe_119,128,119,0},
{quad_classification_probe_120,128,120,0},
{quad_classification_probe_121,128,121,0},
{quad_classification_probe_122,128,122,0},
{quad_classification_probe_123,128,123,0},
{quad_classification_probe_124,128,124,0},
{quad_classification_probe_125,128,125,0},
{quad_classification_probe_126,128,126,0},
{quad_classification_probe_127,128,127,0},
{quad_classification_probe_128,128,128,0},
{quad_classification_probe_129,128,129,0},
{quad_classification_probe_130,128,130,0},
{quad_classification_probe_131,128,131,0},
{quad_classification_probe_132,128,132,0},
{quad_classification_probe_133,128,133,0},
{quad_classification_probe_134,128,134,0},
{quad_classification_probe_135,128,135,0},
{quad_classification_probe_136,128,136,0},
{quad_classification_probe_137,128,137,0},
{quad_classification_probe_138,128,138,0},
{quad_classification_probe_139,128,139,0},
{quad_classification_probe_140,128,140,0},
{quad_classification_probe_141,128,141,0},
{quad_classification_probe_142,128,142,0},
{quad_classification_probe_143,128,143,0},
{quad_classification_probe_144,128,144,0},
{quad_classification_probe_145,128,145,0},
{quad_classification_probe_146,128,146,0},
{quad_classification_probe_147,128,147,0},
{quad_classification_probe_148,128,148,0},
{quad_classification_probe_149,128,149,0},
{quad_classification_probe_150,128,150,0},
{quad_classification_probe_151,128,151,0},
{quad_classification_probe_152,128,152,0},
{quad_classification_probe_153,128,153,0},
{quad_classification_probe_154,128,154,0},
{quad_classification_probe_155,128,155,0},
{quad_classification_probe_156,128,156,0},
{quad_classification_probe_157,128,157,0},
{quad_classification_probe_158,128,158,0},
{quad_classification_probe_159,128,159,0},
{quad_classification_probe_160,128,160,0},
{quad_classification_probe_161,128,161,0},
{quad_classification_probe_162,128,162,0},
{quad_classification_probe_163,128,163,0},
{quad_classification_probe_164,128,164,0},
{quad_classification_probe_165,128,165,0},
{quad_classification_probe_166,128,166,0},
{quad_classification_probe_167,128,167,0},
{quad_classification_probe_168,128,168,0},
{quad_classification_probe_169,128,169,0},
{quad_classification_probe_170,128,170,0},
{quad_classification_probe_171,128,171,0},
{quad_classification_probe_172,128,172,0},
{quad_classification_probe_173,128,173,0},
{quad_classification_probe_174,128,174,0},
{quad_classification_probe_175,128,175,0},
{quad_classification_probe_176,128,176,0},
{quad_classification_probe_177,128,177,0},
{quad_classification_probe_178,128,178,0},
{quad_classification_probe_179,128,179,0},
{quad_classification_probe_180,128,180,0},
{quad_classification_probe_181,128,181,0},
{quad_classification_probe_182,128,182,0},
{quad_classification_probe_183,128,183,0},
{quad_classification_probe_184,128,184,0},
{quad_classification_probe_185,128,185,0},
{quad_classification_probe_186,128,186,0},
{quad_classification_probe_187,128,187,0},
{quad_classification_probe_188,128,188,0},
{quad_classification_probe_189,128,189,0},
{quad_classification_probe_190,128,190,0},
{quad_classification_probe_191,128,191,0},
{quad_classification_probe_192,128,192,0},
{quad_classification_probe_193,128,193,0},
{quad_classification_probe_194,128,194,0},
{quad_classification_probe_195,128,195,0},
{quad_classification_probe_196,128,196,0},
{quad_classification_probe_197,128,197,0},
{quad_classification_probe_198,128,198,0},
{quad_classification_probe_199,128,199,0},
{quad_classification_probe_200,128,200,0},
{quad_classification_probe_201,128,201,0},
{quad_classification_probe_202,128,202,0},
{quad_classification_probe_203,128,203,0},
{quad_classification_probe_204,128,204,0},
{quad_classification_probe_205,128,205,0},
{quad_classification_probe_206,128,206,0},
{quad_classification_probe_207,128,207,0},
{quad_classification_probe_208,128,208,0},
{quad_classification_probe_209,128,209,0},
{quad_classification_probe_210,128,210,0},
{quad_classification_probe_211,128,211,0},
{quad_classification_probe_212,128,212,0},
{quad_classification_probe_213,128,213,0},
{quad_classification_probe_214,128,214,0},
{quad_classification_probe_215,128,215,0},
{quad_classification_probe_216,128,216,0},
{quad_classification_probe_217,128,217,0},
{quad_classification_probe_218,128,218,0},
{quad_classification_probe_219,128,219,0},
{quad_classification_probe_220,128,220,0},
{quad_classification_probe_221,128,221,0},
{quad_classification_probe_222,128,222,0},
{quad_classification_probe_223,128,223,0},
{quad_classification_probe_224,128,224,0},
{quad_classification_probe_225,128,225,0},
{quad_classification_probe_226,128,226,0},
{quad_classification_probe_227,128,227,0},
{quad_classification_probe_228,128,228,0},
{quad_classification_probe_229,128,229,0},
{quad_classification_probe_230,128,230,0},
{quad_classification_probe_231,128,231,0},
{quad_classification_probe_232,128,232,0},
{quad_classification_probe_233,128,233,0},
{quad_classification_probe_234,128,234,0},
{quad_classification_probe_235,128,235,0},
{quad_classification_probe_236,128,236,0},
{quad_classification_probe_237,128,237,0},
{quad_classification_probe_238,128,238,0},
{quad_classification_probe_239,128,239,0},
{quad_classification_probe_240,128,240,0},
{quad_classification_probe_241,128,241,0},
{quad_classification_probe_242,128,242,0},
{quad_classification_probe_243,128,243,0},
{quad_classification_probe_244,128,244,0},
{quad_classification_probe_245,128,245,0},
{quad_classification_probe_246,128,246,0},
{quad_classification_probe_247,128,247,0},
{quad_classification_probe_248,128,248,0},
{quad_classification_probe_249,128,249,0},
{quad_classification_probe_250,128,250,0},
{quad_classification_probe_251,128,251,0},
{quad_classification_probe_252,128,252,0},
{quad_classification_probe_253,128,253,0},
{quad_classification_probe_254,128,254,0},
{quad_classification_probe_255,128,255,0},
{quad_classification_probe_256,128,256,0},
{quad_classification_probe_257,128,257,0},
{quad_classification_probe_258,128,258,0},
{quad_classification_probe_259,128,259,0},
{quad_classification_probe_260,128,260,0},
{quad_classification_probe_261,128,261,0},
{quad_classification_probe_262,128,262,0},
{quad_classification_probe_263,128,263,0},
{quad_classification_probe_264,128,264,0},
{quad_classification_probe_265,128,265,0},
{quad_classification_probe_266,128,266,0},
{quad_classification_probe_267,128,267,0},
{quad_classification_probe_268,128,268,0},
{quad_classification_probe_269,128,269,0},
{quad_classification_probe_270,128,270,0},
{quad_classification_probe_271,128,271,0},
{quad_classification_probe_272,128,272,0},
{quad_classification_probe_273,128,273,0},
{quad_classification_probe_274,128,274,0},
{quad_classification_probe_275,128,275,0},
{quad_classification_probe_276,128,276,0},
{quad_classification_probe_277,128,277,0},
{quad_classification_probe_278,128,278,0},
{quad_classification_probe_279,128,279,0},
{quad_classification_probe_280,128,280,0},
{quad_classification_probe_281,128,281,0},
{quad_classification_probe_282,128,282,0},
{quad_classification_probe_283,128,283,0},
{quad_classification_probe_284,128,284,0},
{quad_classification_probe_285,128,285,0},
{quad_classification_probe_286,128,286,0},
{quad_classification_probe_287,128,287,0},
{quad_classification_probe_288,128,288,0},
{quad_classification_probe_289,128,289,0},
{quad_classification_probe_290,128,290,0},
{quad_classification_probe_291,128,291,0},
{quad_classification_probe_292,128,292,0},
{quad_classification_probe_293,128,293,0},
{quad_classification_probe_294,128,294,0},
{quad_classification_probe_295,128,295,0},
{quad_classification_probe_296,128,296,0},
{quad_classification_probe_297,128,297,0},
{quad_classification_probe_298,128,298,0},
{quad_classification_probe_299,128,299,0},
{quad_classification_probe_300,128,300,0},
{quad_classification_probe_301,128,301,0},
{quad_classification_probe_302,128,302,0},
{quad_classification_probe_303,128,303,0},
{quad_classification_probe_304,128,304,0},
{quad_classification_probe_305,128,305,0},
{quad_classification_probe_306,128,306,0},
{quad_classification_probe_307,128,307,0},
{quad_classification_probe_308,128,308,0},
{quad_classification_probe_309,128,309,0},
{quad_classification_probe_310,128,310,0},
{quad_classification_probe_311,128,311,0},
{quad_classification_probe_312,128,312,0},
{quad_classification_probe_313,128,313,0},
{quad_classification_probe_314,128,314,0},
{quad_classification_probe_315,128,315,0},
{quad_classification_probe_316,128,316,0},
{quad_classification_probe_317,128,317,0},
{quad_classification_probe_318,128,318,0},
{quad_classification_probe_319,128,319,0},
{quad_classification_probe_320,128,320,0},
{quad_classification_probe_321,128,321,0},
{quad_classification_probe_322,128,322,0},
{quad_classification_probe_323,128,323,0},
{quad_classification_probe_324,128,324,0},
{quad_classification_probe_325,128,325,0},
{quad_classification_probe_326,128,326,0},
{quad_classification_probe_327,128,327,0},
{quad_classification_probe_328,128,328,0},
{quad_classification_probe_329,128,329,0},
{quad_classification_probe_330,128,330,0},
{quad_classification_probe_331,128,331,0},
{quad_classification_probe_332,128,332,0},
{quad_classification_probe_333,128,333,0},
{quad_classification_probe_334,128,334,0},
{quad_classification_probe_335,128,335,0},
{quad_classification_probe_336,128,336,0},
{quad_classification_probe_337,128,337,0},
{quad_classification_probe_338,128,338,0},
{quad_classification_probe_339,128,339,0},
{quad_classification_probe_340,128,340,0},
{quad_classification_probe_341,128,341,0},
{quad_classification_probe_342,128,342,0},
{quad_classification_probe_343,128,343,0},
{quad_classification_probe_344,128,344,0},
{quad_classification_probe_345,128,345,0},
{quad_classification_probe_346,128,346,0},
{quad_classification_probe_347,128,347,0},
{quad_classification_probe_348,128,348,0},
{quad_classification_probe_349,128,349,0},
{quad_classification_probe_350,128,350,0},
{quad_classification_probe_351,128,351,0},
{quad_classification_probe_352,128,352,0},
{quad_classification_probe_353,128,353,0},
{quad_classification_probe_354,128,354,0},
{quad_classification_probe_355,128,355,0},
{quad_classification_probe_356,128,356,0},
{quad_classification_probe_357,128,357,0},
{quad_classification_probe_358,128,358,0},
{quad_classification_probe_359,128,359,0},
{quad_classification_probe_360,128,360,0},
{quad_classification_probe_361,128,361,0},
{quad_classification_probe_362,128,362,0},
{quad_classification_probe_363,128,363,0},
{quad_classification_probe_364,128,364,0},
{quad_classification_probe_365,128,365,0},
{quad_classification_probe_366,128,366,0},
{quad_classification_probe_367,128,367,0},
{quad_classification_probe_368,128,368,0},
{quad_classification_probe_369,128,369,0},
{quad_classification_probe_370,128,370,0},
{quad_classification_probe_371,128,371,0},
{quad_classification_probe_372,128,372,0},
{quad_classification_probe_373,128,373,0},
{quad_classification_probe_374,128,374,0},
{quad_classification_probe_375,128,375,0},
{quad_classification_probe_376,128,376,0},
{quad_classification_probe_377,128,377,0},
{quad_classification_probe_378,128,378,0},
{quad_classification_probe_379,128,379,0},
{quad_classification_probe_380,128,380,0},
{quad_classification_probe_381,128,381,0},
{quad_classification_probe_382,128,382,0},
{quad_classification_probe_383,128,383,0},
{quad_classification_probe_384,128,384,0},
{quad_classification_probe_385,128,385,0},
{quad_classification_probe_386,128,386,0},
{quad_classification_probe_387,128,387,0},
{quad_classification_probe_388,128,388,0},
{quad_classification_probe_389,128,389,0},
{quad_classification_probe_390,128,390,0},
{quad_classification_probe_391,128,391,0},
{quad_classification_probe_392,128,392,0},
{quad_classification_probe_393,128,393,0},
{quad_classification_probe_394,128,394,0},
{quad_classification_probe_395,128,395,0},
{quad_classification_probe_396,128,396,0},
{quad_classification_probe_397,128,397,0},
{quad_classification_probe_398,128,398,0},
{quad_classification_probe_399,128,399,0},
{quad_classification_probe_400,128,400,0},
{quad_classification_probe_401,128,401,0},
{quad_classification_probe_402,128,402,0},
{quad_classification_probe_403,128,403,0},
{quad_classification_probe_404,128,404,0},
{quad_classification_probe_405,128,405,0},
{quad_classification_probe_406,128,406,0},
{quad_classification_probe_407,128,407,0},
{quad_classification_probe_408,128,408,0},
{quad_classification_probe_409,128,409,0},
{quad_classification_probe_410,128,410,0},
{quad_classification_probe_411,128,411,0},
{quad_classification_probe_412,128,412,0},
{quad_classification_probe_413,128,413,0},
{quad_classification_probe_414,128,414,0},
{quad_classification_probe_415,128,415,0},
{quad_classification_probe_416,128,416,0},
{quad_classification_probe_417,128,417,0},
{quad_classification_probe_418,128,418,0},
{quad_classification_probe_419,128,419,0},
{quad_classification_probe_420,128,420,0},
{quad_classification_probe_421,128,421,0},
{quad_classification_probe_422,128,422,0},
{quad_classification_probe_423,128,423,0},
{quad_classification_probe_424,128,424,0},
{quad_classification_probe_425,128,425,0},
{quad_classification_probe_426,128,426,0},
{quad_classification_probe_427,128,427,0},
{quad_classification_probe_428,128,428,0},
{quad_classification_probe_429,128,429,0},
{quad_classification_probe_430,128,430,0},
{quad_classification_probe_431,128,431,0},
{quad_classification_probe_432,128,432,0},
{quad_classification_probe_433,128,433,0},
{quad_classification_probe_434,128,434,0},
{quad_classification_probe_435,128,435,0},
{quad_classification_probe_436,128,436,0},
{quad_classification_probe_437,128,437,0},
{quad_classification_probe_438,128,438,0},
{quad_classification_probe_439,128,439,0},
{quad_classification_probe_440,128,440,0},
{quad_classification_probe_441,128,441,0},
{quad_classification_probe_442,128,442,0},
{quad_classification_probe_443,128,443,0},
{quad_classification_probe_444,128,444,0},
{quad_classification_probe_445,128,445,0},
{quad_classification_probe_446,128,446,0},
{quad_classification_probe_447,128,447,0},
{quad_classification_probe_448,128,448,0},
{quad_classification_probe_449,128,449,0},
{quad_classification_probe_450,128,450,0},
{quad_classification_probe_451,128,451,0},
{quad_classification_probe_452,128,452,0},
{quad_classification_probe_453,128,453,0},
{quad_classification_probe_454,128,454,0},
{quad_classification_probe_455,128,455,0},
{quad_classification_probe_456,128,456,0},
{quad_classification_probe_457,128,457,0},
{quad_classification_probe_458,128,458,0},
{quad_classification_probe_459,128,459,0},
{quad_classification_probe_460,128,460,0},
{quad_classification_probe_461,128,461,0},
{quad_classification_probe_462,128,462,0},
{quad_classification_probe_463,128,463,0},
{quad_classification_probe_464,128,464,0},
{quad_classification_probe_465,128,465,0},
{quad_classification_probe_466,128,466,0},
{quad_classification_probe_467,128,467,0},
{quad_classification_probe_468,128,468,0},
{quad_classification_probe_469,128,469,0},
{quad_classification_probe_470,128,470,0},
{quad_classification_probe_471,128,471,0},
{quad_classification_probe_472,128,472,0},
{quad_classification_probe_473,128,473,0},
{quad_classification_probe_474,128,474,0},
{quad_classification_probe_475,128,475,0},
{quad_classification_probe_476,128,476,0},
{quad_classification_probe_477,128,477,0},
{quad_classification_probe_478,128,478,0},
{quad_classification_probe_479,128,479,0},
{quad_classification_probe_480,128,480,0},
{quad_classification_probe_481,128,481,0},
{quad_classification_probe_482,128,482,0},
{quad_classification_probe_483,128,483,0},
{quad_classification_probe_484,128,484,0},
{quad_classification_probe_485,128,485,0},
{quad_classification_probe_486,128,486,0},
{quad_classification_probe_487,128,487,0},
{quad_classification_probe_488,128,488,0},
{quad_classification_probe_489,128,489,0},
{quad_classification_probe_490,128,490,0},
{quad_classification_probe_491,128,491,0},
{quad_classification_probe_492,128,492,0},
{quad_classification_probe_493,128,493,0},
{quad_classification_probe_494,128,494,0},
{quad_classification_probe_495,128,495,0},
{quad_classification_probe_496,128,496,0},
{quad_classification_probe_497,128,497,0},
{quad_classification_probe_498,128,498,0},
{quad_classification_probe_499,128,499,0},
{quad_classification_probe_500,128,500,0},
{quad_classification_probe_501,128,501,0},
{quad_classification_probe_502,128,502,0},
{quad_classification_probe_503,128,503,0},
{quad_classification_probe_504,128,504,0},
{quad_classification_probe_505,128,505,0},
{quad_classification_probe_506,128,506,0},
{quad_classification_probe_507,128,507,0},
{quad_classification_probe_508,128,508,0},
{quad_classification_probe_509,128,509,0},
{quad_classification_probe_510,128,510,0},
{quad_classification_probe_511,128,511,0},
{quad_classification_probe_512,128,512,0},
{quad_classification_probe_513,128,513,0},
{quad_classification_probe_514,128,514,0},
{quad_classification_probe_515,128,515,0},
{quad_classification_probe_516,128,516,0},
{quad_classification_probe_517,128,517,0},
{quad_classification_probe_518,128,518,0},
{quad_classification_probe_519,128,519,0},
{quad_classification_probe_520,128,520,0},
{quad_classification_probe_521,128,521,0},
{quad_classification_probe_522,128,522,0},
{quad_classification_probe_523,128,523,0},
{quad_classification_probe_524,128,524,0},
{quad_classification_probe_525,128,525,0},
{quad_classification_probe_526,128,526,0},
{quad_classification_probe_527,128,527,0},
{quad_classification_probe_528,128,528,0},
{quad_classification_probe_529,128,529,0},
{quad_classification_probe_530,128,530,0},
{quad_classification_probe_531,128,531,0},
{quad_classification_probe_532,128,532,0},
{quad_classification_probe_533,128,533,0},
{quad_classification_probe_534,128,534,0},
{quad_classification_probe_535,128,535,0},
{quad_classification_probe_536,128,536,0},
{quad_classification_probe_537,128,537,0},
{quad_classification_probe_538,128,538,0},
{quad_classification_probe_539,128,539,0},
{quad_classification_probe_540,128,540,0},
{quad_classification_probe_541,128,541,0},
{quad_classification_probe_542,128,542,0},
{quad_classification_probe_543,128,543,0},
{quad_classification_probe_544,128,544,0},
{quad_classification_probe_545,128,545,0},
{quad_classification_probe_546,128,546,0},
{quad_classification_probe_547,128,547,0},
{quad_classification_probe_548,128,548,0},
{quad_classification_probe_549,128,549,0},
{quad_classification_probe_550,128,550,0},
{quad_classification_probe_551,128,551,0},
{quad_classification_probe_552,128,552,0},
{quad_classification_probe_553,128,553,0},
{quad_classification_probe_554,128,554,0},
{quad_classification_probe_555,128,555,0},
{quad_classification_probe_556,128,556,0},
{quad_classification_probe_557,128,557,0},
{quad_classification_probe_558,128,558,0},
{quad_classification_probe_559,128,559,0},
{quad_classification_probe_560,128,560,0},
{quad_classification_probe_561,128,561,0},
{quad_classification_probe_562,128,562,0},
{quad_classification_probe_563,128,563,0},
{quad_classification_probe_564,128,564,0},
{quad_classification_probe_565,128,565,0},
{quad_classification_probe_566,128,566,0},
{quad_classification_probe_567,128,567,0},
{quad_classification_probe_568,128,568,0},
{quad_classification_probe_569,128,569,0},
{quad_classification_probe_570,128,570,0},
{quad_classification_probe_571,128,571,0},
{quad_classification_probe_572,128,572,0},
{quad_classification_probe_573,128,573,0},
{quad_classification_probe_574,128,574,0},
{quad_classification_probe_575,128,575,0},
{quad_classification_probe_576,128,576,0},
{quad_classification_probe_577,128,577,0},
{quad_classification_probe_578,128,578,0},
{quad_classification_probe_579,128,579,0},
{quad_classification_probe_580,128,580,0},
{quad_classification_probe_581,128,581,0},
{quad_classification_probe_582,128,582,0},
{quad_classification_probe_583,128,583,0},
{quad_classification_probe_584,128,584,0},
{quad_classification_probe_585,128,585,0},
{quad_classification_probe_586,128,586,0},
{quad_classification_probe_587,128,587,0},
{quad_classification_probe_588,128,588,0},
{quad_classification_probe_589,128,589,0},
{quad_classification_probe_590,128,590,0},
{quad_classification_probe_591,128,591,0},
{quad_classification_probe_592,128,592,0},
{quad_classification_probe_593,128,593,0},
{quad_classification_probe_594,128,594,0},
{quad_classification_probe_595,128,595,0},
{quad_classification_probe_596,128,596,0},
{quad_classification_probe_597,128,597,0},
{quad_classification_probe_598,128,598,0},
{quad_classification_probe_599,128,599,0},
{quad_classification_probe_600,128,600,0},
{quad_classification_probe_601,128,601,0},
{quad_classification_probe_602,128,602,0},
{quad_classification_probe_603,128,603,0},
{quad_classification_probe_604,128,604,0},
{quad_classification_probe_605,128,605,0},
{quad_classification_probe_606,128,606,0},
{quad_classification_probe_607,128,607,0},
{quad_classification_probe_608,128,608,0},
{quad_classification_probe_609,128,609,0},
{quad_classification_probe_610,128,610,0},
{quad_classification_probe_611,128,611,0},
{quad_classification_probe_612,128,612,0},
{quad_classification_probe_613,128,613,0},
{quad_classification_probe_614,128,614,0},
{quad_classification_probe_615,128,615,0},
{quad_classification_probe_616,128,616,0},
{quad_classification_probe_617,128,617,0},
{quad_classification_probe_618,128,618,0},
{quad_classification_probe_619,128,619,0},
{quad_classification_probe_620,128,620,0},
{quad_classification_probe_621,128,621,0},
{quad_classification_probe_622,128,622,0},
{quad_classification_probe_623,128,623,0},
{quad_classification_probe_624,128,624,0},
{quad_classification_probe_625,128,625,0},
{quad_classification_probe_626,128,626,0},
{quad_classification_probe_627,128,627,0},
{quad_classification_probe_628,128,628,0},
{quad_classification_probe_629,128,629,0},
{quad_classification_probe_630,128,630,0},
{quad_classification_probe_631,128,631,0},
{quad_classification_probe_632,128,632,0},
{quad_classification_probe_633,128,633,0},
{quad_classification_probe_634,128,634,0},
{quad_classification_probe_635,128,635,0},
{quad_classification_probe_636,128,636,0},
{quad_classification_probe_637,128,637,0},
{quad_classification_probe_638,128,638,0},
{quad_classification_probe_639,128,639,0},
{quad_classification_probe_640,128,640,0},
{quad_classification_probe_641,128,641,0},
{quad_classification_probe_642,128,642,0},
{quad_classification_probe_643,128,643,0},
{quad_classification_probe_644,128,644,0},
{quad_classification_probe_645,128,645,0},
{quad_classification_probe_646,128,646,0},
{quad_classification_probe_647,128,647,0},
{quad_classification_probe_648,128,648,0},
{quad_classification_probe_649,128,649,0},
{quad_classification_probe_650,128,650,0},
{quad_classification_probe_651,128,651,0},
{quad_classification_probe_652,128,652,0},
{quad_classification_probe_653,128,653,0},
{quad_classification_probe_654,128,654,0},
{quad_classification_probe_655,128,655,0},
{quad_classification_probe_656,128,656,0},
{quad_classification_probe_657,128,657,0},
{quad_classification_probe_658,128,658,0},
{quad_classification_probe_659,128,659,0},
{quad_classification_probe_660,128,660,0},
{quad_classification_probe_661,128,661,0},
{quad_classification_probe_662,128,662,0},
{quad_classification_probe_663,128,663,0},
{quad_classification_probe_664,128,664,0},
{quad_classification_probe_665,128,665,0},
{quad_classification_probe_666,128,666,0},
{quad_classification_probe_667,128,667,0},
{quad_classification_probe_668,128,668,0},
{quad_classification_probe_669,128,669,0},
{quad_classification_probe_670,128,670,0},
{quad_classification_probe_671,128,671,0},
{quad_classification_probe_672,128,672,0},
{quad_classification_probe_673,128,673,0},
{quad_classification_probe_674,128,674,0},
{quad_classification_probe_675,128,675,0},
{quad_classification_probe_676,128,676,0},
{quad_classification_probe_677,128,677,0},
{quad_classification_probe_678,128,678,0},
{quad_classification_probe_679,128,679,0},
{quad_classification_probe_680,128,680,0},
{quad_classification_probe_681,128,681,0},
{quad_classification_probe_682,128,682,0},
{quad_classification_probe_683,128,683,0},
{quad_classification_probe_684,128,684,0},
{quad_classification_probe_685,128,685,0},
{quad_classification_probe_686,128,686,0},
{quad_classification_probe_687,128,687,0},
{quad_classification_probe_688,128,688,0},
{quad_classification_probe_689,128,689,0},
{quad_classification_probe_690,128,690,0},
{quad_classification_probe_691,128,691,0},
{quad_classification_probe_692,128,692,0},
{quad_classification_probe_693,128,693,0},
{quad_classification_probe_694,128,694,0},
{quad_classification_probe_695,128,695,0},
{quad_classification_probe_696,128,696,0},
{quad_classification_probe_697,128,697,0},
{quad_classification_probe_698,128,698,0},
{quad_classification_probe_699,128,699,0},
{quad_classification_probe_700,128,700,0},
{quad_classification_probe_701,128,701,0},
{quad_classification_probe_702,128,702,0},
{quad_classification_probe_703,128,703,0},
{quad_classification_probe_704,128,704,0},
{quad_classification_probe_705,128,705,0},
{quad_classification_probe_706,128,706,0},
{quad_classification_probe_707,128,707,0},
{quad_classification_probe_708,128,708,0},
{quad_classification_probe_709,128,709,0},
{quad_classification_probe_710,128,710,0},
{quad_classification_probe_711,128,711,0},
{quad_classification_probe_712,128,712,0},
{quad_classification_probe_713,128,713,0},
{quad_classification_probe_714,128,714,0},
{quad_classification_probe_715,128,715,0},
{quad_classification_probe_716,128,716,0},
{quad_classification_probe_717,128,717,0},
{quad_classification_probe_718,128,718,0},
{quad_classification_probe_719,128,719,0},
{quad_classification_probe_720,128,720,0},
{quad_classification_probe_721,128,721,0},
{quad_classification_probe_722,128,722,0},
{quad_classification_probe_723,128,723,0},
{quad_classification_probe_724,128,724,0},
{quad_classification_probe_725,128,725,0},
{quad_classification_probe_726,128,726,0},
{quad_classification_probe_727,128,727,0},
{quad_classification_probe_728,128,728,0},
{quad_classification_probe_729,128,729,0},
{quad_classification_probe_730,128,730,0},
{quad_classification_probe_731,128,731,0},
{quad_classification_probe_732,128,732,0},
{quad_classification_probe_733,128,733,0},
{quad_classification_probe_734,128,734,0},
{quad_classification_probe_735,128,735,0},
{quad_classification_probe_736,128,736,0},
{quad_classification_probe_737,128,737,0},
{quad_classification_probe_738,128,738,0},
{quad_classification_probe_739,128,739,0},
{quad_classification_probe_740,128,740,0},
{quad_classification_probe_741,128,741,0},
{quad_classification_probe_742,128,742,0},
{quad_classification_probe_743,128,743,0},
{quad_classification_probe_744,128,744,0},
{quad_classification_probe_745,128,745,0},
{quad_classification_probe_746,128,746,0},
{quad_classification_probe_747,128,747,0},
{quad_classification_probe_748,128,748,0},
{quad_classification_probe_749,128,749,0},
{quad_classification_probe_750,128,750,0},
{quad_classification_probe_751,128,751,0},
{quad_classification_probe_752,128,752,0},
{quad_classification_probe_753,128,753,0},
{quad_classification_probe_754,128,754,0},
{quad_classification_probe_755,128,755,0},
{quad_classification_probe_756,128,756,0},
{quad_classification_probe_757,128,757,0},
{quad_classification_probe_758,128,758,0},
{quad_classification_probe_759,128,759,0},
{quad_classification_probe_760,128,760,0},
{quad_classification_probe_761,128,761,0},
{quad_classification_probe_762,128,762,0},
{quad_classification_probe_763,128,763,0},
{quad_classification_probe_764,128,764,0},
{quad_classification_probe_765,128,765,0},
{quad_classification_probe_766,128,766,0},
{quad_classification_probe_767,128,767,0},
{quad_classification_probe_768,128,768,0},
{quad_classification_probe_769,128,769,0},
{quad_classification_probe_770,128,770,0},
{quad_classification_probe_771,128,771,0},
{quad_classification_probe_772,128,772,0},
{quad_classification_probe_773,128,773,0},
{quad_classification_probe_774,128,774,0},
{quad_classification_probe_775,128,775,0},
{quad_classification_probe_776,128,776,0},
{quad_classification_probe_777,128,777,0},
{quad_classification_probe_778,128,778,0},
{quad_classification_probe_779,128,779,0},
{quad_classification_probe_780,128,780,0},
{quad_classification_probe_781,128,781,0},
{quad_classification_probe_782,128,782,0},
{quad_classification_probe_783,128,783,0},
{quad_classification_probe_784,128,784,0},
{quad_classification_probe_785,128,785,0},
{quad_classification_probe_786,128,786,0},
{quad_classification_probe_787,128,787,0},
{quad_classification_probe_788,128,788,0},
{quad_classification_probe_789,128,789,0},
{quad_classification_probe_790,128,790,0},
{quad_classification_probe_791,128,791,0},
{quad_classification_probe_792,128,792,0},
{quad_classification_probe_793,128,793,0},
{quad_classification_probe_794,128,794,0},
{quad_classification_probe_795,128,795,0},
{quad_classification_probe_796,128,796,0},
{quad_classification_probe_797,128,797,0},
{quad_classification_probe_798,128,798,0},
{quad_classification_probe_799,128,799,0},
{quad_classification_probe_800,128,800,0},
{quad_classification_probe_801,128,801,0},
{quad_classification_probe_802,128,802,0},
{quad_classification_probe_803,128,803,0},
{quad_classification_probe_804,128,804,0},
{quad_classification_probe_805,128,805,0},
{quad_classification_probe_806,128,806,0},
{quad_classification_probe_807,128,807,0},
{quad_classification_probe_808,128,808,0},
{quad_classification_probe_809,128,809,0},
{quad_classification_probe_810,128,810,0},
{quad_classification_probe_811,128,811,0},
{quad_classification_probe_812,128,812,0},
{quad_classification_probe_813,128,813,0},
{quad_classification_probe_814,128,814,0},
{quad_classification_probe_815,128,815,0},
{quad_classification_probe_816,128,816,0},
{quad_classification_probe_817,128,817,0},
{quad_classification_probe_818,128,818,0},
{quad_classification_probe_819,128,819,0},
{quad_classification_probe_820,128,820,0},
{quad_classification_probe_821,128,821,0},
{quad_classification_probe_822,128,822,0},
{quad_classification_probe_823,128,823,0},
{quad_classification_probe_824,128,824,0},
{quad_classification_probe_825,128,825,0},
{quad_classification_probe_826,128,826,0},
{quad_classification_probe_827,128,827,0},
{quad_classification_probe_828,128,828,0},
{quad_classification_probe_829,128,829,0},
{quad_classification_probe_830,128,830,0},
{quad_classification_probe_831,128,831,0},
{quad_classification_probe_832,128,832,0},
{quad_classification_probe_833,128,833,0},
{quad_classification_probe_834,128,834,0},
{quad_classification_probe_835,128,835,0},
{quad_classification_probe_836,128,836,0},
{quad_classification_probe_837,128,837,0},
{quad_classification_probe_838,128,838,0},
{quad_classification_probe_839,128,839,0},
{quad_classification_probe_840,128,840,0},
{quad_classification_probe_841,128,841,0},
{quad_classification_probe_842,128,842,0},
{quad_classification_probe_843,128,843,0},
{quad_classification_probe_844,128,844,0},
{quad_classification_probe_845,128,845,0},
{quad_classification_probe_846,128,846,0},
{quad_classification_probe_847,128,847,0},
{quad_classification_probe_848,128,848,0},
{quad_classification_probe_849,128,849,0},
{quad_classification_probe_850,128,850,0},
{quad_classification_probe_851,128,851,0},
{quad_classification_probe_852,128,852,0},
{quad_classification_probe_853,128,853,0},
{quad_classification_probe_854,128,854,0},
{quad_classification_probe_855,128,855,0},
{quad_classification_probe_856,128,856,0},
{quad_classification_probe_857,128,857,0},
{quad_classification_probe_858,128,858,0},
{quad_classification_probe_859,128,859,0},
{quad_classification_probe_860,128,860,0},
{quad_classification_probe_861,128,861,0},
{quad_classification_probe_862,128,862,0},
{quad_classification_probe_863,128,863,0},
{quad_classification_probe_864,128,864,0},
{quad_classification_probe_865,128,865,0},
{quad_classification_probe_866,128,866,0},
{quad_classification_probe_867,128,867,0},
{quad_classification_probe_868,128,868,0},
{quad_classification_probe_869,128,869,0},
{quad_classification_probe_870,128,870,0},
{quad_classification_probe_871,128,871,0},
{quad_classification_probe_872,128,872,0},
{quad_classification_probe_873,128,873,0},
{quad_classification_probe_874,128,874,0},
{quad_classification_probe_875,128,875,0},
{quad_classification_probe_876,128,876,0},
{quad_classification_probe_877,128,877,0},
{quad_classification_probe_878,128,878,0},
{quad_classification_probe_879,128,879,0},
{quad_classification_probe_880,128,880,0},
{quad_classification_probe_881,128,881,0},
{quad_classification_probe_882,128,882,0},
{quad_classification_probe_883,128,883,0},
{quad_classification_probe_884,128,884,0},
{quad_classification_probe_885,128,885,0},
{quad_classification_probe_886,128,886,0},
{quad_classification_probe_887,128,887,0},
{quad_classification_probe_888,128,888,0},
{quad_classification_probe_889,128,889,0},
{quad_classification_probe_890,128,890,0},
{quad_classification_probe_891,128,891,0},
{quad_classification_probe_892,128,892,0},
{quad_classification_probe_893,128,893,0},
{quad_classification_probe_894,128,894,0},
{quad_classification_probe_895,128,895,0},
{quad_classification_probe_896,128,896,0},
{quad_classification_probe_897,128,897,0},
{quad_classification_probe_898,128,898,0},
{quad_classification_probe_899,128,899,0},
{quad_classification_probe_900,128,900,0},
{quad_classification_probe_901,128,901,0},
{quad_classification_probe_902,128,902,0},
{quad_classification_probe_903,128,903,0},
{quad_classification_probe_904,128,904,0},
{quad_classification_probe_905,128,905,0},
{quad_classification_probe_906,128,906,0},
{quad_classification_probe_907,128,907,0},
{quad_classification_probe_908,128,908,0},
{quad_classification_probe_909,128,909,0},
{quad_classification_probe_910,128,910,0},
{quad_classification_probe_911,128,911,0},
{quad_classification_probe_912,128,912,0},
{quad_classification_probe_913,128,913,0},
{quad_classification_probe_914,128,914,0},
{quad_classification_probe_915,128,915,0},
{quad_classification_probe_916,128,916,0},
{quad_classification_probe_917,128,917,0},
{quad_classification_probe_918,128,918,0},
{quad_classification_probe_919,128,919,0},
{quad_classification_probe_920,128,920,0},
{quad_classification_probe_921,128,921,0},
{quad_classification_probe_922,128,922,0},
{quad_classification_probe_923,128,923,0},
{quad_classification_probe_924,128,924,0},
{quad_classification_probe_925,128,925,0},
{quad_classification_probe_926,128,926,0},
{quad_classification_probe_927,128,927,0},
{quad_classification_probe_928,128,928,0},
{quad_classification_probe_929,128,929,0},
{quad_classification_probe_930,128,930,0},
{quad_classification_probe_931,128,931,0},
{quad_classification_probe_932,128,932,0},
{quad_classification_probe_933,128,933,0},
{quad_classification_probe_934,128,934,0},
{quad_classification_probe_935,128,935,0},
{quad_classification_probe_936,128,936,0},
{quad_classification_probe_937,128,937,0},
{quad_classification_probe_938,128,938,0},
{quad_classification_probe_939,128,939,0},
{quad_classification_probe_940,128,940,0},
{quad_classification_probe_941,128,941,0},
{quad_classification_probe_942,128,942,0},
{quad_classification_probe_943,128,943,0},
{quad_classification_probe_944,128,944,0},
{quad_classification_probe_945,128,945,0},
{quad_classification_probe_946,128,946,0},
{quad_classification_probe_947,128,947,0},
{quad_classification_probe_948,128,948,0},
{quad_classification_probe_949,128,949,0},
{quad_classification_probe_950,128,950,0},
{quad_classification_probe_951,128,951,0},
{quad_classification_probe_952,128,952,0},
{quad_classification_probe_953,128,953,0},
{quad_classification_probe_954,128,954,0},
{quad_classification_probe_955,128,955,0},
{quad_classification_probe_956,128,956,0},
{quad_classification_probe_957,128,957,0},
{quad_classification_probe_958,128,958,0},
{quad_classification_probe_959,128,959,0},
{quad_classification_probe_960,128,960,0},
{quad_classification_probe_961,128,961,0},
{quad_classification_probe_962,128,962,0},
{quad_classification_probe_963,128,963,0},
{quad_classification_probe_964,128,964,0},
{quad_classification_probe_965,128,965,0},
{quad_classification_probe_966,128,966,0},
{quad_classification_probe_967,128,967,0},
{quad_classification_probe_968,128,968,0},
{quad_classification_probe_969,128,969,0},
{quad_classification_probe_970,128,970,0},
{quad_classification_probe_971,128,971,0},
{quad_classification_probe_972,128,972,0},
{quad_classification_probe_973,128,973,0},
{quad_classification_probe_974,128,974,0},
{quad_classification_probe_975,128,975,0},
{quad_classification_probe_976,128,976,0},
{quad_classification_probe_977,128,977,0},
{quad_classification_probe_978,128,978,0},
{quad_classification_probe_979,128,979,0},
{quad_classification_probe_980,128,980,0},
{quad_classification_probe_981,128,981,0},
{quad_classification_probe_982,128,982,0},
{quad_classification_probe_983,128,983,0},
{quad_classification_probe_984,128,984,0},
{quad_classification_probe_985,128,985,0},
{quad_classification_probe_986,128,986,0},
{quad_classification_probe_987,128,987,0},
{quad_classification_probe_988,128,988,0},
{quad_classification_probe_989,128,989,0},
{quad_classification_probe_990,128,990,0},
{quad_classification_probe_991,128,991,0},
{quad_classification_probe_992,128,992,0},
{quad_classification_probe_993,128,993,0},
{quad_classification_probe_994,128,994,0},
{quad_classification_probe_995,128,995,0},
{quad_classification_probe_996,128,996,0},
{quad_classification_probe_997,128,997,0},
{quad_classification_probe_998,128,998,0},
{quad_classification_probe_999,128,999,0},
{quad_classification_probe_1000,128,1000,0},
{quad_classification_probe_1001,128,1001,0},
{quad_classification_probe_1002,128,1002,0},
{quad_classification_probe_1003,128,1003,0},
{quad_classification_probe_1004,128,1004,0},
{quad_classification_probe_1005,128,1005,0},
{quad_classification_probe_1006,128,1006,0},
{quad_classification_probe_1007,128,1007,0},
{quad_classification_probe_1008,128,1008,0},
{quad_classification_probe_1009,128,1009,0},
{quad_classification_probe_1010,128,1010,0},
{quad_classification_probe_1011,128,1011,0},
{quad_classification_probe_1012,128,1012,0},
{quad_classification_probe_1013,128,1013,0},
{quad_classification_probe_1014,128,1014,0},
{quad_classification_probe_1015,128,1015,0},
{quad_classification_probe_1016,128,1016,0},
{quad_classification_probe_1017,128,1017,0},
{quad_classification_probe_1018,128,1018,0},
{quad_classification_probe_1019,128,1019,0},
{quad_classification_probe_1020,128,1020,0},
{quad_classification_probe_1021,128,1021,0},
{quad_classification_probe_1022,128,1022,0},
{quad_classification_probe_1023,128,1023,0},
{quad_classification_probe_1024,128,1056,0},
{quad_classification_probe_1025,128,2080,0},
{quad_classification_probe_1026,128,3104,0},
{quad_classification_probe_1027,128,4128,0},
{quad_classification_probe_1028,128,1088,0},
{quad_classification_probe_1029,128,2112,0},
{quad_classification_probe_1030,128,3136,0},
{quad_classification_probe_1031,128,4160,0},
{quad_classification_probe_1032,128,1027,0},
{quad_classification_probe_1033,128,2051,0},
{quad_classification_probe_1034,128,3075,0},
{quad_classification_probe_1035,128,4099,0},
{quad_classification_probe_1036,128,2047,0},
{quad_classification_probe_1037,128,3071,0},
{quad_classification_probe_1038,128,4095,0},
{quad_classification_probe_1039,128,5119,0},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
