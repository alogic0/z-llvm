#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
struct test_case { kernel run; unsigned kind,position,declared,bits; uint64_t raw,y; };
static uint64_t constant_value(const struct test_case *item){
 __uint128_t limit=(__uint128_t)1<<item->bits,mask=limit-1,x=item->raw&mask,y=item->y&mask;
 __uint128_t result=item->kind==0?x+y:item->kind==1?x-y:x*y;
 __int128 sx=x&(limit>>1)?(__int128)x-(__int128)limit:(__int128)x,sy=y&(limit>>1)?(__int128)y-(__int128)limit:(__int128)y;
 __int128 signed_result=item->kind==0?sx+sy:item->kind==1?sx-sy:sx*sy;
 if(((item->declared&1)&&(item->kind==1?x<y:result>mask))||
    ((item->declared&2)&&(signed_result<-(__int128)(limit>>1)||signed_result>(__int128)(limit>>1)-1))){
  fprintf(stderr,"invalid flagged constant fixture bits=%u operation=%u flags=%u\n",item->bits,item->kind,item->declared);exit(2);
 }
 return (uint64_t)(result&mask);
}
static uint32_t reverse32(uint32_t x) {
    uint32_t r=0; for(unsigned i=0;i<32;i++){r=(r<<1)|(x&1);x>>=1;} return r;
}
static uint64_t checksum(const uint64_t *words,uint64_t initial,unsigned position,unsigned declared) {
    for(unsigned i=0;i<6;i++) initial=(initial*UINT64_C(1099511628211))^
        ((declared&&i==position)?(uint32_t)words[i]:words[i]);
    return initial;
}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv) {
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;
    size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *map=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(map==MAP_FAILED||mprotect(map+page,page,PROT_READ|PROT_WRITE))return 2;
    for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++) {
        const struct test_case *item=&cases[which];
        uint64_t words[6]; for(unsigned i=0;i<6;i++)words[i]=
            ((uint64_t)seed*UINT64_C(0x9182736455aaccdd))^((uint64_t)i*UINT64_C(0x123456789abcdef1));
        if(seed==1)memset(words,255,sizeof words);
        if(seed==2)for(unsigned i=0;i<6;i++)words[i]=UINT64_C(0x8000000080000000)^(UINT64_C(1)<<i);
        static const uint64_t edges[]={0,1,UINT64_MAX,UINT64_C(0x8000000000000000),1023,1024,2047,2048,2049,65503,65504,65505,65519,65520,65521,65535,65536,65537};
        if(seed<sizeof edges/sizeof edges[0])words[item->position]=edges[seed];if(seed==3)words[item->position]=UINT64_C(1)<<(item->bits-1);
        unsigned char *input=map+2*page-sizeof words;memcpy(input,words,sizeof words);
        uint64_t salt=UINT64_C(0x9182736455aaccdd)^seed;
        struct {uint64_t pre,data[3],post;} output;memset(&output,0xa5,sizeof output);
        uint64_t answer=item->run(input,output.data,salt),expected[3],returned;
        uint64_t value=constant_value(item);
        expected[0]=checksum(words,value,0,0);expected[1]=salt;expected[2]=words[0];returned=expected[0]^salt;
        if(fault==1)output.data[0]^=1;if(fault==2)answer^=1;if(fault==3)output.post^=1;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"scalar-followup case=%zu kind=%u seed=%u observation=%zu fault=%u\n",which,item->kind,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==returned);for(unsigned i=0;i<3;i++)CHECK(output.data[i]==expected[i]);
        CHECK(output.pre==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(output.post==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(memcmp(input,words,sizeof words)==0);
#undef CHECK
    }
    printf("constant-flags observations=%zu defined-overflow-facts=integer-model=literal-spellings=live-aliases=stack-calls=guard-pages=preserved\n",observations);
    return munmap(map,page*3)!=0;
}
extern uint64_t constant_flags_probe_0(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_1(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_2(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_3(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_4(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_5(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_6(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_7(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_8(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_9(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_10(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_11(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_12(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_13(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_14(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_15(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_16(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_17(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_18(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_19(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_20(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_21(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_22(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_23(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_24(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_25(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_26(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_27(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_28(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_29(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_30(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_31(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_32(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_33(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_34(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_35(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_36(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_37(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_38(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_39(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_40(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_41(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_42(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_43(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_44(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_45(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_46(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_47(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_48(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_49(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_50(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_51(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_52(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_53(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_54(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_55(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_56(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_57(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_58(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_59(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_60(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_61(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_62(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_63(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_64(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_65(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_66(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_67(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_68(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_69(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_70(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_71(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_72(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_73(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_74(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_75(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_76(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_77(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_78(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_79(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_80(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_81(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_82(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_83(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_84(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_85(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_86(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_87(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_88(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_89(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_90(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_91(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_92(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_93(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_94(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_95(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_96(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_97(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_98(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_99(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_100(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_101(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_102(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_103(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_104(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_105(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_106(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_107(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_108(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_109(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_110(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_111(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_112(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_113(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_114(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_115(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_116(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_117(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_118(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_119(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_120(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_121(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_122(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_123(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_124(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_125(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_126(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_127(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_128(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_129(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_130(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_131(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_132(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_133(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_134(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_135(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_136(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_137(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_138(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_139(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_140(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_141(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_142(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_143(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_144(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_145(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_146(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_147(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_148(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_149(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_150(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_151(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_152(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_153(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_154(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_155(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_156(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_157(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_158(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_159(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_160(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_161(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_162(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_163(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_164(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_165(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_166(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_167(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_168(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_169(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_170(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_171(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_172(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_173(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_174(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_175(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_176(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_177(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_178(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_179(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_180(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_181(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_182(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_183(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_184(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_185(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_186(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_187(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_188(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_189(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_190(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_191(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_192(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_193(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_194(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_195(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_196(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_197(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_198(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_199(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_200(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_201(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_202(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_203(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_204(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_205(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_206(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_207(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_208(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_209(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_210(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_211(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_212(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_213(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_214(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_215(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_216(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_217(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_218(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_219(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_220(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_221(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_222(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_223(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_224(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_225(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_226(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_227(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_228(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_229(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_230(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_231(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_232(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_233(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_234(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_235(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_236(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_237(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_238(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_239(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_240(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_241(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_242(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_243(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_244(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_245(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_246(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_247(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_248(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_249(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_250(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_251(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_252(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_253(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_254(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_255(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_256(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_257(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_258(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_259(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_260(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_261(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_262(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_263(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_264(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_265(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_266(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_267(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_268(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_269(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_270(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_271(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_272(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_273(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_274(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_275(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_276(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_277(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_278(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_279(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_280(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_281(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_282(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_283(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_284(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_285(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_286(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_287(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_288(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_289(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_290(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_291(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_292(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_293(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_294(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_295(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_296(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_297(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_298(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_299(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_300(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_301(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_302(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_303(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_304(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_305(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_306(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_307(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_308(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_309(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_310(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_311(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_312(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_313(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_314(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_315(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_316(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_317(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_318(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_319(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_320(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_321(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_322(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_323(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_324(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_325(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_326(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_327(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_328(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_329(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_330(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_331(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_332(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_333(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_334(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_335(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_336(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_337(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_338(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_339(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_340(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_341(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_342(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_343(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_344(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_345(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_346(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_347(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_348(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_349(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_350(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_351(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_352(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_353(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_354(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_355(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_356(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_357(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_358(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_359(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_360(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_361(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_362(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_363(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_364(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_365(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_366(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_367(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_368(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_369(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_370(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_371(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_372(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_373(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_374(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_375(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_376(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_377(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_378(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_379(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_380(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_381(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_382(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_383(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_384(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_385(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_386(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_387(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_388(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_389(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_390(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_391(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_392(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_393(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_394(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_395(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_396(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_397(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_398(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_399(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_400(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_401(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_402(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_403(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_404(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_405(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_406(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_407(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_408(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_409(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_410(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_411(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_412(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_413(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_414(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_415(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_416(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_417(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_418(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_419(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_420(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_421(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_422(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_423(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_424(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_425(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_426(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_427(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_428(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_429(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_430(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_431(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_432(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_433(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_434(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_435(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_436(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_437(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_438(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_439(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_440(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_441(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_442(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_443(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_444(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_445(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_446(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_447(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_448(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_449(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_450(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_451(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_452(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_453(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_454(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_455(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_456(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_457(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_458(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_459(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_460(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_461(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_462(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_463(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_464(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_465(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_466(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_467(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_468(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_469(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_470(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_471(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_472(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_473(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_474(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_475(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_476(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_477(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_478(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_479(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_480(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_481(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_482(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_483(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_484(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_485(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_486(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_487(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_488(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_489(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_490(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_491(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_492(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_493(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_494(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_495(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_496(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_497(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_498(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_499(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_500(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_501(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_502(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_503(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_504(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_505(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_506(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_507(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_508(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_509(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_510(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_511(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_512(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_513(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_514(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_515(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_516(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_517(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_518(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_519(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_520(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_521(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_522(const void *,void *,uint64_t);
extern uint64_t constant_flags_probe_523(const void *,void *,uint64_t);
static const struct test_case cases[]={
{constant_flags_probe_0,0,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_1,0,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_2,0,0,1,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_3,0,0,1,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_4,0,0,1,1,UINT64_C(0),UINT64_C(1)},
{constant_flags_probe_5,0,0,1,1,UINT64_C(0),UINT64_C(1)},
{constant_flags_probe_6,0,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_7,0,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_8,0,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_9,0,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_10,0,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_11,0,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_12,0,0,2,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_13,0,0,2,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_14,0,0,2,1,UINT64_C(0),UINT64_C(1)},
{constant_flags_probe_15,0,0,2,1,UINT64_C(0),UINT64_C(1)},
{constant_flags_probe_16,0,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_17,0,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_18,0,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_19,0,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_20,0,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_21,0,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_22,0,0,3,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_23,0,0,3,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_24,0,0,3,1,UINT64_C(0),UINT64_C(1)},
{constant_flags_probe_25,0,0,3,1,UINT64_C(0),UINT64_C(1)},
{constant_flags_probe_26,0,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_27,0,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_28,0,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_29,0,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_30,1,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_31,1,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_32,1,0,1,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_33,1,0,1,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_34,1,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_35,1,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_36,1,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_37,1,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_38,1,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_39,1,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_40,1,0,2,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_41,1,0,2,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_42,1,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_43,1,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_44,1,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_45,1,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_46,1,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_47,1,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_48,1,0,3,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_49,1,0,3,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_50,1,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_51,1,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_52,1,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_53,1,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_54,2,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_55,2,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_56,2,0,1,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_57,2,0,1,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_58,2,0,1,1,UINT64_C(0),UINT64_C(1)},
{constant_flags_probe_59,2,0,1,1,UINT64_C(0),UINT64_C(1)},
{constant_flags_probe_60,2,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_61,2,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_62,2,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_63,2,0,1,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_64,2,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_65,2,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_66,2,0,2,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_67,2,0,2,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_68,2,0,2,1,UINT64_C(0),UINT64_C(1)},
{constant_flags_probe_69,2,0,2,1,UINT64_C(0),UINT64_C(1)},
{constant_flags_probe_70,2,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_71,2,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_72,2,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_73,2,0,2,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_74,2,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_75,2,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_76,2,0,3,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_77,2,0,3,1,UINT64_C(1),UINT64_C(0)},
{constant_flags_probe_78,2,0,3,1,UINT64_C(0),UINT64_C(1)},
{constant_flags_probe_79,2,0,3,1,UINT64_C(0),UINT64_C(1)},
{constant_flags_probe_80,2,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_81,2,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_82,2,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_83,2,0,3,1,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_84,0,0,1,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_85,0,0,1,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_86,0,0,1,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_87,0,0,1,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_88,0,0,1,3,UINT64_C(3),UINT64_C(1)},
{constant_flags_probe_89,0,0,1,3,UINT64_C(3),UINT64_C(1)},
{constant_flags_probe_90,0,0,1,3,UINT64_C(1),UINT64_C(2)},
{constant_flags_probe_91,0,0,1,3,UINT64_C(1),UINT64_C(2)},
{constant_flags_probe_92,0,0,1,3,UINT64_C(2),UINT64_C(4)},
{constant_flags_probe_93,0,0,1,3,UINT64_C(2),UINT64_C(4)},
{constant_flags_probe_94,0,0,2,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_95,0,0,2,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_96,0,0,2,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_97,0,0,2,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_98,0,0,2,3,UINT64_C(1),UINT64_C(2)},
{constant_flags_probe_99,0,0,2,3,UINT64_C(1),UINT64_C(2)},
{constant_flags_probe_100,0,0,2,3,UINT64_C(2),UINT64_C(4)},
{constant_flags_probe_101,0,0,2,3,UINT64_C(2),UINT64_C(4)},
{constant_flags_probe_102,0,0,3,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_103,0,0,3,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_104,0,0,3,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_105,0,0,3,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_106,0,0,3,3,UINT64_C(1),UINT64_C(2)},
{constant_flags_probe_107,0,0,3,3,UINT64_C(1),UINT64_C(2)},
{constant_flags_probe_108,0,0,3,3,UINT64_C(2),UINT64_C(4)},
{constant_flags_probe_109,0,0,3,3,UINT64_C(2),UINT64_C(4)},
{constant_flags_probe_110,1,0,1,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_111,1,0,1,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_112,1,0,1,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_113,1,0,1,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_114,1,0,1,3,UINT64_C(3),UINT64_C(1)},
{constant_flags_probe_115,1,0,1,3,UINT64_C(3),UINT64_C(1)},
{constant_flags_probe_116,1,0,2,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_117,1,0,2,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_118,1,0,2,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_119,1,0,2,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_120,1,0,2,3,UINT64_C(3),UINT64_C(1)},
{constant_flags_probe_121,1,0,2,3,UINT64_C(3),UINT64_C(1)},
{constant_flags_probe_122,1,0,2,3,UINT64_C(1),UINT64_C(2)},
{constant_flags_probe_123,1,0,2,3,UINT64_C(1),UINT64_C(2)},
{constant_flags_probe_124,1,0,3,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_125,1,0,3,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_126,1,0,3,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_127,1,0,3,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_128,1,0,3,3,UINT64_C(3),UINT64_C(1)},
{constant_flags_probe_129,1,0,3,3,UINT64_C(3),UINT64_C(1)},
{constant_flags_probe_130,2,0,1,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_131,2,0,1,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_132,2,0,1,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_133,2,0,1,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_134,2,0,1,3,UINT64_C(3),UINT64_C(1)},
{constant_flags_probe_135,2,0,1,3,UINT64_C(3),UINT64_C(1)},
{constant_flags_probe_136,2,0,1,3,UINT64_C(1),UINT64_C(2)},
{constant_flags_probe_137,2,0,1,3,UINT64_C(1),UINT64_C(2)},
{constant_flags_probe_138,2,0,2,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_139,2,0,2,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_140,2,0,2,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_141,2,0,2,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_142,2,0,2,3,UINT64_C(3),UINT64_C(1)},
{constant_flags_probe_143,2,0,2,3,UINT64_C(3),UINT64_C(1)},
{constant_flags_probe_144,2,0,2,3,UINT64_C(1),UINT64_C(2)},
{constant_flags_probe_145,2,0,2,3,UINT64_C(1),UINT64_C(2)},
{constant_flags_probe_146,2,0,3,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_147,2,0,3,3,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_148,2,0,3,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_149,2,0,3,3,UINT64_C(7),UINT64_C(0)},
{constant_flags_probe_150,2,0,3,3,UINT64_C(3),UINT64_C(1)},
{constant_flags_probe_151,2,0,3,3,UINT64_C(3),UINT64_C(1)},
{constant_flags_probe_152,2,0,3,3,UINT64_C(1),UINT64_C(2)},
{constant_flags_probe_153,2,0,3,3,UINT64_C(1),UINT64_C(2)},
{constant_flags_probe_154,0,0,1,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_155,0,0,1,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_156,0,0,1,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_157,0,0,1,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_158,0,0,1,8,UINT64_C(127),UINT64_C(1)},
{constant_flags_probe_159,0,0,1,8,UINT64_C(127),UINT64_C(1)},
{constant_flags_probe_160,0,0,1,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_161,0,0,1,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_162,0,0,2,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_163,0,0,2,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_164,0,0,2,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_165,0,0,2,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_166,0,0,2,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_167,0,0,2,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_168,0,0,2,8,UINT64_C(10),UINT64_C(252)},
{constant_flags_probe_169,0,0,2,8,UINT64_C(10),UINT64_C(252)},
{constant_flags_probe_170,0,0,3,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_171,0,0,3,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_172,0,0,3,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_173,0,0,3,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_174,0,0,3,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_175,0,0,3,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_176,1,0,1,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_177,1,0,1,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_178,1,0,1,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_179,1,0,1,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_180,1,0,1,8,UINT64_C(127),UINT64_C(1)},
{constant_flags_probe_181,1,0,1,8,UINT64_C(127),UINT64_C(1)},
{constant_flags_probe_182,1,0,1,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_183,1,0,1,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_184,1,0,2,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_185,1,0,2,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_186,1,0,2,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_187,1,0,2,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_188,1,0,2,8,UINT64_C(127),UINT64_C(1)},
{constant_flags_probe_189,1,0,2,8,UINT64_C(127),UINT64_C(1)},
{constant_flags_probe_190,1,0,2,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_191,1,0,2,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_192,1,0,2,8,UINT64_C(10),UINT64_C(252)},
{constant_flags_probe_193,1,0,2,8,UINT64_C(10),UINT64_C(252)},
{constant_flags_probe_194,1,0,3,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_195,1,0,3,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_196,1,0,3,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_197,1,0,3,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_198,1,0,3,8,UINT64_C(127),UINT64_C(1)},
{constant_flags_probe_199,1,0,3,8,UINT64_C(127),UINT64_C(1)},
{constant_flags_probe_200,1,0,3,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_201,1,0,3,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_202,2,0,1,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_203,2,0,1,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_204,2,0,1,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_205,2,0,1,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_206,2,0,1,8,UINT64_C(127),UINT64_C(1)},
{constant_flags_probe_207,2,0,1,8,UINT64_C(127),UINT64_C(1)},
{constant_flags_probe_208,2,0,1,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_209,2,0,1,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_210,2,0,2,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_211,2,0,2,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_212,2,0,2,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_213,2,0,2,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_214,2,0,2,8,UINT64_C(127),UINT64_C(1)},
{constant_flags_probe_215,2,0,2,8,UINT64_C(127),UINT64_C(1)},
{constant_flags_probe_216,2,0,2,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_217,2,0,2,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_218,2,0,2,8,UINT64_C(10),UINT64_C(252)},
{constant_flags_probe_219,2,0,2,8,UINT64_C(10),UINT64_C(252)},
{constant_flags_probe_220,2,0,3,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_221,2,0,3,8,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_222,2,0,3,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_223,2,0,3,8,UINT64_C(255),UINT64_C(0)},
{constant_flags_probe_224,2,0,3,8,UINT64_C(127),UINT64_C(1)},
{constant_flags_probe_225,2,0,3,8,UINT64_C(127),UINT64_C(1)},
{constant_flags_probe_226,2,0,3,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_227,2,0,3,8,UINT64_C(63),UINT64_C(2)},
{constant_flags_probe_228,0,0,1,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_229,0,0,1,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_230,0,0,1,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_231,0,0,1,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_232,0,0,1,17,UINT64_C(65535),UINT64_C(1)},
{constant_flags_probe_233,0,0,1,17,UINT64_C(65535),UINT64_C(1)},
{constant_flags_probe_234,0,0,1,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_235,0,0,1,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_236,0,0,2,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_237,0,0,2,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_238,0,0,2,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_239,0,0,2,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_240,0,0,2,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_241,0,0,2,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_242,0,0,2,17,UINT64_C(10),UINT64_C(131068)},
{constant_flags_probe_243,0,0,2,17,UINT64_C(10),UINT64_C(131068)},
{constant_flags_probe_244,0,0,3,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_245,0,0,3,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_246,0,0,3,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_247,0,0,3,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_248,0,0,3,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_249,0,0,3,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_250,1,0,1,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_251,1,0,1,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_252,1,0,1,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_253,1,0,1,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_254,1,0,1,17,UINT64_C(65535),UINT64_C(1)},
{constant_flags_probe_255,1,0,1,17,UINT64_C(65535),UINT64_C(1)},
{constant_flags_probe_256,1,0,1,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_257,1,0,1,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_258,1,0,2,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_259,1,0,2,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_260,1,0,2,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_261,1,0,2,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_262,1,0,2,17,UINT64_C(65535),UINT64_C(1)},
{constant_flags_probe_263,1,0,2,17,UINT64_C(65535),UINT64_C(1)},
{constant_flags_probe_264,1,0,2,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_265,1,0,2,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_266,1,0,2,17,UINT64_C(10),UINT64_C(131068)},
{constant_flags_probe_267,1,0,2,17,UINT64_C(10),UINT64_C(131068)},
{constant_flags_probe_268,1,0,3,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_269,1,0,3,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_270,1,0,3,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_271,1,0,3,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_272,1,0,3,17,UINT64_C(65535),UINT64_C(1)},
{constant_flags_probe_273,1,0,3,17,UINT64_C(65535),UINT64_C(1)},
{constant_flags_probe_274,1,0,3,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_275,1,0,3,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_276,2,0,1,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_277,2,0,1,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_278,2,0,1,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_279,2,0,1,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_280,2,0,1,17,UINT64_C(65535),UINT64_C(1)},
{constant_flags_probe_281,2,0,1,17,UINT64_C(65535),UINT64_C(1)},
{constant_flags_probe_282,2,0,1,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_283,2,0,1,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_284,2,0,2,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_285,2,0,2,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_286,2,0,2,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_287,2,0,2,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_288,2,0,2,17,UINT64_C(65535),UINT64_C(1)},
{constant_flags_probe_289,2,0,2,17,UINT64_C(65535),UINT64_C(1)},
{constant_flags_probe_290,2,0,2,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_291,2,0,2,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_292,2,0,2,17,UINT64_C(10),UINT64_C(131068)},
{constant_flags_probe_293,2,0,2,17,UINT64_C(10),UINT64_C(131068)},
{constant_flags_probe_294,2,0,3,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_295,2,0,3,17,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_296,2,0,3,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_297,2,0,3,17,UINT64_C(131071),UINT64_C(0)},
{constant_flags_probe_298,2,0,3,17,UINT64_C(65535),UINT64_C(1)},
{constant_flags_probe_299,2,0,3,17,UINT64_C(65535),UINT64_C(1)},
{constant_flags_probe_300,2,0,3,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_301,2,0,3,17,UINT64_C(32767),UINT64_C(2)},
{constant_flags_probe_302,0,0,1,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_303,0,0,1,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_304,0,0,1,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_305,0,0,1,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_306,0,0,1,32,UINT64_C(2147483647),UINT64_C(1)},
{constant_flags_probe_307,0,0,1,32,UINT64_C(2147483647),UINT64_C(1)},
{constant_flags_probe_308,0,0,1,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_309,0,0,1,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_310,0,0,2,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_311,0,0,2,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_312,0,0,2,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_313,0,0,2,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_314,0,0,2,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_315,0,0,2,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_316,0,0,2,32,UINT64_C(10),UINT64_C(4294967292)},
{constant_flags_probe_317,0,0,2,32,UINT64_C(10),UINT64_C(4294967292)},
{constant_flags_probe_318,0,0,3,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_319,0,0,3,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_320,0,0,3,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_321,0,0,3,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_322,0,0,3,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_323,0,0,3,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_324,1,0,1,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_325,1,0,1,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_326,1,0,1,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_327,1,0,1,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_328,1,0,1,32,UINT64_C(2147483647),UINT64_C(1)},
{constant_flags_probe_329,1,0,1,32,UINT64_C(2147483647),UINT64_C(1)},
{constant_flags_probe_330,1,0,1,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_331,1,0,1,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_332,1,0,2,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_333,1,0,2,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_334,1,0,2,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_335,1,0,2,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_336,1,0,2,32,UINT64_C(2147483647),UINT64_C(1)},
{constant_flags_probe_337,1,0,2,32,UINT64_C(2147483647),UINT64_C(1)},
{constant_flags_probe_338,1,0,2,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_339,1,0,2,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_340,1,0,2,32,UINT64_C(10),UINT64_C(4294967292)},
{constant_flags_probe_341,1,0,2,32,UINT64_C(10),UINT64_C(4294967292)},
{constant_flags_probe_342,1,0,3,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_343,1,0,3,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_344,1,0,3,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_345,1,0,3,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_346,1,0,3,32,UINT64_C(2147483647),UINT64_C(1)},
{constant_flags_probe_347,1,0,3,32,UINT64_C(2147483647),UINT64_C(1)},
{constant_flags_probe_348,1,0,3,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_349,1,0,3,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_350,2,0,1,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_351,2,0,1,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_352,2,0,1,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_353,2,0,1,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_354,2,0,1,32,UINT64_C(2147483647),UINT64_C(1)},
{constant_flags_probe_355,2,0,1,32,UINT64_C(2147483647),UINT64_C(1)},
{constant_flags_probe_356,2,0,1,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_357,2,0,1,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_358,2,0,2,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_359,2,0,2,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_360,2,0,2,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_361,2,0,2,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_362,2,0,2,32,UINT64_C(2147483647),UINT64_C(1)},
{constant_flags_probe_363,2,0,2,32,UINT64_C(2147483647),UINT64_C(1)},
{constant_flags_probe_364,2,0,2,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_365,2,0,2,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_366,2,0,2,32,UINT64_C(10),UINT64_C(4294967292)},
{constant_flags_probe_367,2,0,2,32,UINT64_C(10),UINT64_C(4294967292)},
{constant_flags_probe_368,2,0,3,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_369,2,0,3,32,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_370,2,0,3,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_371,2,0,3,32,UINT64_C(4294967295),UINT64_C(0)},
{constant_flags_probe_372,2,0,3,32,UINT64_C(2147483647),UINT64_C(1)},
{constant_flags_probe_373,2,0,3,32,UINT64_C(2147483647),UINT64_C(1)},
{constant_flags_probe_374,2,0,3,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_375,2,0,3,32,UINT64_C(1073741823),UINT64_C(2)},
{constant_flags_probe_376,0,0,1,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_377,0,0,1,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_378,0,0,1,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_379,0,0,1,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_380,0,0,1,48,UINT64_C(140737488355327),UINT64_C(1)},
{constant_flags_probe_381,0,0,1,48,UINT64_C(140737488355327),UINT64_C(1)},
{constant_flags_probe_382,0,0,1,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_383,0,0,1,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_384,0,0,2,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_385,0,0,2,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_386,0,0,2,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_387,0,0,2,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_388,0,0,2,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_389,0,0,2,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_390,0,0,2,48,UINT64_C(10),UINT64_C(281474976710652)},
{constant_flags_probe_391,0,0,2,48,UINT64_C(10),UINT64_C(281474976710652)},
{constant_flags_probe_392,0,0,3,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_393,0,0,3,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_394,0,0,3,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_395,0,0,3,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_396,0,0,3,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_397,0,0,3,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_398,1,0,1,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_399,1,0,1,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_400,1,0,1,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_401,1,0,1,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_402,1,0,1,48,UINT64_C(140737488355327),UINT64_C(1)},
{constant_flags_probe_403,1,0,1,48,UINT64_C(140737488355327),UINT64_C(1)},
{constant_flags_probe_404,1,0,1,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_405,1,0,1,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_406,1,0,2,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_407,1,0,2,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_408,1,0,2,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_409,1,0,2,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_410,1,0,2,48,UINT64_C(140737488355327),UINT64_C(1)},
{constant_flags_probe_411,1,0,2,48,UINT64_C(140737488355327),UINT64_C(1)},
{constant_flags_probe_412,1,0,2,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_413,1,0,2,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_414,1,0,2,48,UINT64_C(10),UINT64_C(281474976710652)},
{constant_flags_probe_415,1,0,2,48,UINT64_C(10),UINT64_C(281474976710652)},
{constant_flags_probe_416,1,0,3,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_417,1,0,3,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_418,1,0,3,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_419,1,0,3,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_420,1,0,3,48,UINT64_C(140737488355327),UINT64_C(1)},
{constant_flags_probe_421,1,0,3,48,UINT64_C(140737488355327),UINT64_C(1)},
{constant_flags_probe_422,1,0,3,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_423,1,0,3,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_424,2,0,1,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_425,2,0,1,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_426,2,0,1,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_427,2,0,1,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_428,2,0,1,48,UINT64_C(140737488355327),UINT64_C(1)},
{constant_flags_probe_429,2,0,1,48,UINT64_C(140737488355327),UINT64_C(1)},
{constant_flags_probe_430,2,0,1,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_431,2,0,1,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_432,2,0,2,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_433,2,0,2,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_434,2,0,2,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_435,2,0,2,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_436,2,0,2,48,UINT64_C(140737488355327),UINT64_C(1)},
{constant_flags_probe_437,2,0,2,48,UINT64_C(140737488355327),UINT64_C(1)},
{constant_flags_probe_438,2,0,2,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_439,2,0,2,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_440,2,0,2,48,UINT64_C(10),UINT64_C(281474976710652)},
{constant_flags_probe_441,2,0,2,48,UINT64_C(10),UINT64_C(281474976710652)},
{constant_flags_probe_442,2,0,3,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_443,2,0,3,48,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_444,2,0,3,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_445,2,0,3,48,UINT64_C(281474976710655),UINT64_C(0)},
{constant_flags_probe_446,2,0,3,48,UINT64_C(140737488355327),UINT64_C(1)},
{constant_flags_probe_447,2,0,3,48,UINT64_C(140737488355327),UINT64_C(1)},
{constant_flags_probe_448,2,0,3,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_449,2,0,3,48,UINT64_C(70368744177663),UINT64_C(2)},
{constant_flags_probe_450,0,0,1,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_451,0,0,1,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_452,0,0,1,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_453,0,0,1,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_454,0,0,1,64,UINT64_C(9223372036854775807),UINT64_C(1)},
{constant_flags_probe_455,0,0,1,64,UINT64_C(9223372036854775807),UINT64_C(1)},
{constant_flags_probe_456,0,0,1,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_457,0,0,1,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_458,0,0,2,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_459,0,0,2,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_460,0,0,2,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_461,0,0,2,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_462,0,0,2,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_463,0,0,2,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_464,0,0,2,64,UINT64_C(10),UINT64_C(18446744073709551612)},
{constant_flags_probe_465,0,0,2,64,UINT64_C(10),UINT64_C(18446744073709551612)},
{constant_flags_probe_466,0,0,3,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_467,0,0,3,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_468,0,0,3,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_469,0,0,3,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_470,0,0,3,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_471,0,0,3,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_472,1,0,1,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_473,1,0,1,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_474,1,0,1,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_475,1,0,1,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_476,1,0,1,64,UINT64_C(9223372036854775807),UINT64_C(1)},
{constant_flags_probe_477,1,0,1,64,UINT64_C(9223372036854775807),UINT64_C(1)},
{constant_flags_probe_478,1,0,1,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_479,1,0,1,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_480,1,0,2,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_481,1,0,2,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_482,1,0,2,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_483,1,0,2,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_484,1,0,2,64,UINT64_C(9223372036854775807),UINT64_C(1)},
{constant_flags_probe_485,1,0,2,64,UINT64_C(9223372036854775807),UINT64_C(1)},
{constant_flags_probe_486,1,0,2,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_487,1,0,2,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_488,1,0,2,64,UINT64_C(10),UINT64_C(18446744073709551612)},
{constant_flags_probe_489,1,0,2,64,UINT64_C(10),UINT64_C(18446744073709551612)},
{constant_flags_probe_490,1,0,3,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_491,1,0,3,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_492,1,0,3,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_493,1,0,3,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_494,1,0,3,64,UINT64_C(9223372036854775807),UINT64_C(1)},
{constant_flags_probe_495,1,0,3,64,UINT64_C(9223372036854775807),UINT64_C(1)},
{constant_flags_probe_496,1,0,3,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_497,1,0,3,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_498,2,0,1,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_499,2,0,1,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_500,2,0,1,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_501,2,0,1,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_502,2,0,1,64,UINT64_C(9223372036854775807),UINT64_C(1)},
{constant_flags_probe_503,2,0,1,64,UINT64_C(9223372036854775807),UINT64_C(1)},
{constant_flags_probe_504,2,0,1,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_505,2,0,1,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_506,2,0,2,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_507,2,0,2,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_508,2,0,2,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_509,2,0,2,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_510,2,0,2,64,UINT64_C(9223372036854775807),UINT64_C(1)},
{constant_flags_probe_511,2,0,2,64,UINT64_C(9223372036854775807),UINT64_C(1)},
{constant_flags_probe_512,2,0,2,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_513,2,0,2,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_514,2,0,2,64,UINT64_C(10),UINT64_C(18446744073709551612)},
{constant_flags_probe_515,2,0,2,64,UINT64_C(10),UINT64_C(18446744073709551612)},
{constant_flags_probe_516,2,0,3,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_517,2,0,3,64,UINT64_C(0),UINT64_C(0)},
{constant_flags_probe_518,2,0,3,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_519,2,0,3,64,UINT64_C(18446744073709551615),UINT64_C(0)},
{constant_flags_probe_520,2,0,3,64,UINT64_C(9223372036854775807),UINT64_C(1)},
{constant_flags_probe_521,2,0,3,64,UINT64_C(9223372036854775807),UINT64_C(1)},
{constant_flags_probe_522,2,0,3,64,UINT64_C(4611686018427387903),UINT64_C(2)},
{constant_flags_probe_523,2,0,3,64,UINT64_C(4611686018427387903),UINT64_C(2)},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
