#define DRIVER_NAME "atomic-pointer-facts"
#define DRIVER_SEEDS 64
#define DRIVER_CONTRACT "independent-c-atomic-state-model=symbolic-byte-addresses=scalar-and-pointer-cmpxchg=all-admitted-rmw-operations=atomic-load-and-store=ordering-volatility-and-singlethread-scope=neighbor-bytes=call-clobbers=preserved"
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
extern unsigned char atomic_pointer_storage[128];
__attribute__((noinline)) void complete_atomic_snapshot(void *out){memcpy(out,atomic_pointer_storage,128);}
__attribute__((noinline)) void complete_atomic_touch(void *p){if(p!=atomic_pointer_storage+96)abort();__asm__ volatile(""::"r"(p):"memory");}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected_input,unsigned char *gold){
    (void)expected_input;unsigned op=item->kind/16,success=(item->kind/8)%2,offset=(item->kind/4)%2?64:16,bits=item->bits?item->bits:64;size_t bytes=bits/8;
    uint64_t mask=bits==64?UINT64_MAX:(UINT64_C(1)<<bits)-1,sign=UINT64_C(1)<<(bits-1),edges[]={0,1,sign-1,sign,mask-1,mask,UINT64_C(0xa55a12348765dead),UINT64_MAX};
    uint64_t initial=edges[seed%8]&mask,desired=edges[(seed/8+3)%8]&mask,expected=success?initial:initial^1;
    if(!item->bits){initial=(uintptr_t)(atomic_pointer_storage+(op==9&&!success?112:96));expected=(uintptr_t)(atomic_pointer_storage+96);desired=(uintptr_t)(atomic_pointer_storage+112);}
    memcpy(input,&initial,8);memcpy(input+8,&expected,8);memcpy(input+16,&desired,8);
    memset(atomic_pointer_storage,0xa5,128);memcpy(atomic_pointer_storage+offset,&initial,bytes);memset(gold+24,0xa5,128);uint64_t next=initial,flag=0;
    switch(op){case 0:next=desired;break;case 1:next=initial+desired;break;case 2:next=initial-desired;break;case 3:next=initial&desired;break;case 4:next=initial|desired;break;case 5:next=initial^desired;break;case 6:next=~(initial&desired);break;case 7:next=initial<desired?initial:desired;break;case 8:next=initial>desired?initial:desired;break;case 9:flag=initial==expected;if(flag)next=desired;break;case 10:break;case 11:next=desired;break;default:abort();}
    next&=mask;uint64_t token=clobber_model(salt);memcpy(gold,&initial,8);memcpy(gold+8,&flag,8);memcpy(gold+16,&token,8);memcpy(gold+24+offset,&next,bytes);
    return (struct test_model){24,1,152,SIZE_MAX,255,initial^token};
}
extern uint64_t atomic_pointer_probe_0(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_1(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_2(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_3(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_4(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_5(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_6(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_7(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_8(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_9(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_10(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_11(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_12(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_13(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_14(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_15(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_16(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_17(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_18(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_19(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_20(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_21(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_22(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_23(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_24(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_25(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_26(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_27(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_28(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_29(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_30(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_31(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_32(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_33(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_34(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_35(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_36(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_37(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_38(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_39(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_40(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_41(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_42(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_43(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_44(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_45(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_46(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_47(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_48(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_49(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_50(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_51(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_52(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_53(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_54(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_55(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_56(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_57(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_58(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_59(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_60(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_61(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_62(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_63(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_64(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_65(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_66(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_67(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_68(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_69(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_70(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_71(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_72(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_73(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_74(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_75(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_76(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_77(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_78(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_79(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_80(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_81(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_82(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_83(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_84(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_85(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_86(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_87(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_88(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_89(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_90(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_91(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_92(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_93(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_94(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_95(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_96(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_97(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_98(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_99(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_100(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_101(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_102(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_103(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_104(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_105(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_106(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_107(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_108(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_109(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_110(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_111(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_112(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_113(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_114(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_115(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_116(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_117(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_118(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_119(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_120(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_121(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_122(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_123(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_124(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_125(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_126(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_127(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_128(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_129(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_130(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_131(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_132(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_133(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_134(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_135(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_136(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_137(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_138(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_139(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_140(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_141(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_142(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_143(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_144(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_145(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_146(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_147(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_148(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_149(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_150(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_151(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_152(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_153(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_154(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_155(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_156(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_157(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_158(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_159(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_160(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_161(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_162(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_163(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_164(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_165(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_166(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_167(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_168(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_169(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_170(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_171(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_172(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_173(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_174(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_175(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_176(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_177(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_178(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_179(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_180(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_181(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_182(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_183(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_184(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_185(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_186(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_187(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_188(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_189(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_190(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_191(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_192(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_193(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_194(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_195(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_196(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_197(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_198(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_199(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_200(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_201(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_202(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_203(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_204(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_205(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_206(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_207(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_208(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_209(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_210(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_211(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_212(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_213(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_214(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_215(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_216(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_217(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_218(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_219(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_220(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_221(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_222(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_223(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_224(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_225(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_226(void *,void *,const void *,uint64_t);
extern uint64_t atomic_pointer_probe_227(void *,void *,const void *,uint64_t);
static const struct test_case cases[]={
{atomic_pointer_probe_0,8,0,0},
{atomic_pointer_probe_1,8,1,0},
{atomic_pointer_probe_2,8,4,0},
{atomic_pointer_probe_3,8,5,0},
{atomic_pointer_probe_4,8,16,0},
{atomic_pointer_probe_5,8,17,0},
{atomic_pointer_probe_6,8,20,0},
{atomic_pointer_probe_7,8,21,0},
{atomic_pointer_probe_8,8,32,0},
{atomic_pointer_probe_9,8,33,0},
{atomic_pointer_probe_10,8,36,0},
{atomic_pointer_probe_11,8,37,0},
{atomic_pointer_probe_12,8,48,0},
{atomic_pointer_probe_13,8,49,0},
{atomic_pointer_probe_14,8,52,0},
{atomic_pointer_probe_15,8,53,0},
{atomic_pointer_probe_16,8,64,0},
{atomic_pointer_probe_17,8,65,0},
{atomic_pointer_probe_18,8,68,0},
{atomic_pointer_probe_19,8,69,0},
{atomic_pointer_probe_20,8,80,0},
{atomic_pointer_probe_21,8,81,0},
{atomic_pointer_probe_22,8,84,0},
{atomic_pointer_probe_23,8,85,0},
{atomic_pointer_probe_24,8,96,0},
{atomic_pointer_probe_25,8,97,0},
{atomic_pointer_probe_26,8,100,0},
{atomic_pointer_probe_27,8,101,0},
{atomic_pointer_probe_28,8,112,0},
{atomic_pointer_probe_29,8,113,0},
{atomic_pointer_probe_30,8,116,0},
{atomic_pointer_probe_31,8,117,0},
{atomic_pointer_probe_32,8,128,0},
{atomic_pointer_probe_33,8,129,0},
{atomic_pointer_probe_34,8,132,0},
{atomic_pointer_probe_35,8,133,0},
{atomic_pointer_probe_36,8,144,0},
{atomic_pointer_probe_37,8,145,0},
{atomic_pointer_probe_38,8,148,0},
{atomic_pointer_probe_39,8,149,0},
{atomic_pointer_probe_40,8,152,0},
{atomic_pointer_probe_41,8,153,0},
{atomic_pointer_probe_42,8,156,0},
{atomic_pointer_probe_43,8,157,0},
{atomic_pointer_probe_44,8,160,0},
{atomic_pointer_probe_45,8,161,0},
{atomic_pointer_probe_46,8,164,0},
{atomic_pointer_probe_47,8,165,0},
{atomic_pointer_probe_48,8,176,0},
{atomic_pointer_probe_49,8,177,0},
{atomic_pointer_probe_50,8,180,0},
{atomic_pointer_probe_51,8,181,0},
{atomic_pointer_probe_52,16,0,0},
{atomic_pointer_probe_53,16,1,0},
{atomic_pointer_probe_54,16,4,0},
{atomic_pointer_probe_55,16,5,0},
{atomic_pointer_probe_56,16,16,0},
{atomic_pointer_probe_57,16,17,0},
{atomic_pointer_probe_58,16,20,0},
{atomic_pointer_probe_59,16,21,0},
{atomic_pointer_probe_60,16,32,0},
{atomic_pointer_probe_61,16,33,0},
{atomic_pointer_probe_62,16,36,0},
{atomic_pointer_probe_63,16,37,0},
{atomic_pointer_probe_64,16,48,0},
{atomic_pointer_probe_65,16,49,0},
{atomic_pointer_probe_66,16,52,0},
{atomic_pointer_probe_67,16,53,0},
{atomic_pointer_probe_68,16,64,0},
{atomic_pointer_probe_69,16,65,0},
{atomic_pointer_probe_70,16,68,0},
{atomic_pointer_probe_71,16,69,0},
{atomic_pointer_probe_72,16,80,0},
{atomic_pointer_probe_73,16,81,0},
{atomic_pointer_probe_74,16,84,0},
{atomic_pointer_probe_75,16,85,0},
{atomic_pointer_probe_76,16,96,0},
{atomic_pointer_probe_77,16,97,0},
{atomic_pointer_probe_78,16,100,0},
{atomic_pointer_probe_79,16,101,0},
{atomic_pointer_probe_80,16,112,0},
{atomic_pointer_probe_81,16,113,0},
{atomic_pointer_probe_82,16,116,0},
{atomic_pointer_probe_83,16,117,0},
{atomic_pointer_probe_84,16,128,0},
{atomic_pointer_probe_85,16,129,0},
{atomic_pointer_probe_86,16,132,0},
{atomic_pointer_probe_87,16,133,0},
{atomic_pointer_probe_88,16,144,0},
{atomic_pointer_probe_89,16,145,0},
{atomic_pointer_probe_90,16,148,0},
{atomic_pointer_probe_91,16,149,0},
{atomic_pointer_probe_92,16,152,0},
{atomic_pointer_probe_93,16,153,0},
{atomic_pointer_probe_94,16,156,0},
{atomic_pointer_probe_95,16,157,0},
{atomic_pointer_probe_96,16,160,0},
{atomic_pointer_probe_97,16,161,0},
{atomic_pointer_probe_98,16,164,0},
{atomic_pointer_probe_99,16,165,0},
{atomic_pointer_probe_100,16,176,0},
{atomic_pointer_probe_101,16,177,0},
{atomic_pointer_probe_102,16,180,0},
{atomic_pointer_probe_103,16,181,0},
{atomic_pointer_probe_104,32,0,0},
{atomic_pointer_probe_105,32,1,0},
{atomic_pointer_probe_106,32,4,0},
{atomic_pointer_probe_107,32,5,0},
{atomic_pointer_probe_108,32,16,0},
{atomic_pointer_probe_109,32,17,0},
{atomic_pointer_probe_110,32,20,0},
{atomic_pointer_probe_111,32,21,0},
{atomic_pointer_probe_112,32,32,0},
{atomic_pointer_probe_113,32,33,0},
{atomic_pointer_probe_114,32,36,0},
{atomic_pointer_probe_115,32,37,0},
{atomic_pointer_probe_116,32,48,0},
{atomic_pointer_probe_117,32,49,0},
{atomic_pointer_probe_118,32,52,0},
{atomic_pointer_probe_119,32,53,0},
{atomic_pointer_probe_120,32,64,0},
{atomic_pointer_probe_121,32,65,0},
{atomic_pointer_probe_122,32,68,0},
{atomic_pointer_probe_123,32,69,0},
{atomic_pointer_probe_124,32,80,0},
{atomic_pointer_probe_125,32,81,0},
{atomic_pointer_probe_126,32,84,0},
{atomic_pointer_probe_127,32,85,0},
{atomic_pointer_probe_128,32,96,0},
{atomic_pointer_probe_129,32,97,0},
{atomic_pointer_probe_130,32,100,0},
{atomic_pointer_probe_131,32,101,0},
{atomic_pointer_probe_132,32,112,0},
{atomic_pointer_probe_133,32,113,0},
{atomic_pointer_probe_134,32,116,0},
{atomic_pointer_probe_135,32,117,0},
{atomic_pointer_probe_136,32,128,0},
{atomic_pointer_probe_137,32,129,0},
{atomic_pointer_probe_138,32,132,0},
{atomic_pointer_probe_139,32,133,0},
{atomic_pointer_probe_140,32,144,0},
{atomic_pointer_probe_141,32,145,0},
{atomic_pointer_probe_142,32,148,0},
{atomic_pointer_probe_143,32,149,0},
{atomic_pointer_probe_144,32,152,0},
{atomic_pointer_probe_145,32,153,0},
{atomic_pointer_probe_146,32,156,0},
{atomic_pointer_probe_147,32,157,0},
{atomic_pointer_probe_148,32,160,0},
{atomic_pointer_probe_149,32,161,0},
{atomic_pointer_probe_150,32,164,0},
{atomic_pointer_probe_151,32,165,0},
{atomic_pointer_probe_152,32,176,0},
{atomic_pointer_probe_153,32,177,0},
{atomic_pointer_probe_154,32,180,0},
{atomic_pointer_probe_155,32,181,0},
{atomic_pointer_probe_156,64,0,0},
{atomic_pointer_probe_157,64,1,0},
{atomic_pointer_probe_158,64,4,0},
{atomic_pointer_probe_159,64,5,0},
{atomic_pointer_probe_160,64,16,0},
{atomic_pointer_probe_161,64,17,0},
{atomic_pointer_probe_162,64,20,0},
{atomic_pointer_probe_163,64,21,0},
{atomic_pointer_probe_164,64,32,0},
{atomic_pointer_probe_165,64,33,0},
{atomic_pointer_probe_166,64,36,0},
{atomic_pointer_probe_167,64,37,0},
{atomic_pointer_probe_168,64,48,0},
{atomic_pointer_probe_169,64,49,0},
{atomic_pointer_probe_170,64,52,0},
{atomic_pointer_probe_171,64,53,0},
{atomic_pointer_probe_172,64,64,0},
{atomic_pointer_probe_173,64,65,0},
{atomic_pointer_probe_174,64,68,0},
{atomic_pointer_probe_175,64,69,0},
{atomic_pointer_probe_176,64,80,0},
{atomic_pointer_probe_177,64,81,0},
{atomic_pointer_probe_178,64,84,0},
{atomic_pointer_probe_179,64,85,0},
{atomic_pointer_probe_180,64,96,0},
{atomic_pointer_probe_181,64,97,0},
{atomic_pointer_probe_182,64,100,0},
{atomic_pointer_probe_183,64,101,0},
{atomic_pointer_probe_184,64,112,0},
{atomic_pointer_probe_185,64,113,0},
{atomic_pointer_probe_186,64,116,0},
{atomic_pointer_probe_187,64,117,0},
{atomic_pointer_probe_188,64,128,0},
{atomic_pointer_probe_189,64,129,0},
{atomic_pointer_probe_190,64,132,0},
{atomic_pointer_probe_191,64,133,0},
{atomic_pointer_probe_192,64,144,0},
{atomic_pointer_probe_193,64,145,0},
{atomic_pointer_probe_194,64,148,0},
{atomic_pointer_probe_195,64,149,0},
{atomic_pointer_probe_196,64,152,0},
{atomic_pointer_probe_197,64,153,0},
{atomic_pointer_probe_198,64,156,0},
{atomic_pointer_probe_199,64,157,0},
{atomic_pointer_probe_200,64,160,0},
{atomic_pointer_probe_201,64,161,0},
{atomic_pointer_probe_202,64,164,0},
{atomic_pointer_probe_203,64,165,0},
{atomic_pointer_probe_204,64,176,0},
{atomic_pointer_probe_205,64,177,0},
{atomic_pointer_probe_206,64,180,0},
{atomic_pointer_probe_207,64,181,0},
{atomic_pointer_probe_208,0,0,0},
{atomic_pointer_probe_209,0,1,0},
{atomic_pointer_probe_210,0,4,0},
{atomic_pointer_probe_211,0,5,0},
{atomic_pointer_probe_212,0,144,0},
{atomic_pointer_probe_213,0,145,0},
{atomic_pointer_probe_214,0,148,0},
{atomic_pointer_probe_215,0,149,0},
{atomic_pointer_probe_216,0,152,0},
{atomic_pointer_probe_217,0,153,0},
{atomic_pointer_probe_218,0,156,0},
{atomic_pointer_probe_219,0,157,0},
{atomic_pointer_probe_220,0,160,0},
{atomic_pointer_probe_221,0,161,0},
{atomic_pointer_probe_222,0,164,0},
{atomic_pointer_probe_223,0,165,0},
{atomic_pointer_probe_224,0,176,0},
{atomic_pointer_probe_225,0,177,0},
{atomic_pointer_probe_226,0,180,0},
{atomic_pointer_probe_227,0,181,0},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
