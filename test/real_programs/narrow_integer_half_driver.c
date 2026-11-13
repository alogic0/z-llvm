#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
struct test_case { kernel run; unsigned kind,position,declared,bits; uint64_t raw; };
static uint16_t integer_half(uint64_t raw,unsigned bits,unsigned is_signed){
 uint64_t mask=(UINT64_C(1)<<bits)-1,sign=UINT64_C(1)<<(bits-1);raw&=mask;
 unsigned negative=is_signed&&(raw&sign)!=0;uint64_t magnitude=negative?((~raw+1)&mask):raw;
 if(!magnitude)return 0;unsigned exponent=63u-(unsigned)__builtin_clzll(magnitude);uint64_t leading;
 if(exponent<=10)leading=magnitude<<(10-exponent);else{unsigned shift=exponent-10;leading=magnitude>>shift;uint64_t tail=magnitude&((UINT64_C(1)<<shift)-1),half=UINT64_C(1)<<(shift-1);if(tail>half||(tail==half&&(leading&1)))leading++;if(leading==2048){leading=1024;exponent++;}}
 uint16_t payload=exponent>15?0x7c00:(uint16_t)(((exponent+15)<<10)|(leading&1023));return payload|(negative?0x8000:0);
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
        uint16_t value=integer_half(words[item->position],item->bits,item->declared);
        expected[0]=checksum(words,value,0,0);expected[1]=salt;expected[2]=words[0];returned=expected[0]^salt;
        if(fault==1)output.data[0]^=1;if(fault==2)answer^=1;if(fault==3)output.post^=1;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"scalar-followup case=%zu kind=%u seed=%u observation=%zu fault=%u\n",which,item->kind,seed,observations,fault);return 1;}}while(0)
        CHECK(answer==returned);for(unsigned i=0;i<3;i++)CHECK(output.data[i]==expected[i]);
        CHECK(output.pre==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(output.post==UINT64_C(0xa5a5a5a5a5a5a5a5));CHECK(memcmp(input,words,sizeof words)==0);
#undef CHECK
    }
    printf("narrow-integer-half observations=%zu integer-rounding-model=exact-half-payloads=live-aliases=stack-calls=guard-pages=preserved\n",observations);
    return munmap(map,page*3)!=0;
}
extern uint64_t narrow_half_probe_0(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_1(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_2(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_3(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_4(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_5(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_6(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_7(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_8(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_9(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_10(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_11(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_12(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_13(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_14(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_15(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_16(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_17(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_18(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_19(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_20(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_21(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_22(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_23(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_24(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_25(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_26(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_27(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_28(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_29(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_30(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_31(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_32(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_33(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_34(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_35(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_36(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_37(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_38(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_39(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_40(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_41(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_42(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_43(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_44(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_45(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_46(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_47(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_48(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_49(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_50(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_51(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_52(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_53(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_54(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_55(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_56(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_57(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_58(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_59(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_60(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_61(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_62(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_63(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_64(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_65(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_66(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_67(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_68(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_69(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_70(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_71(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_72(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_73(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_74(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_75(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_76(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_77(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_78(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_79(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_80(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_81(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_82(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_83(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_84(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_85(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_86(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_87(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_88(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_89(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_90(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_91(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_92(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_93(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_94(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_95(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_96(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_97(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_98(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_99(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_100(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_101(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_102(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_103(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_104(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_105(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_106(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_107(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_108(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_109(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_110(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_111(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_112(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_113(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_114(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_115(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_116(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_117(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_118(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_119(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_120(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_121(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_122(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_123(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_124(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_125(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_126(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_127(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_128(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_129(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_130(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_131(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_132(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_133(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_134(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_135(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_136(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_137(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_138(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_139(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_140(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_141(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_142(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_143(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_144(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_145(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_146(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_147(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_148(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_149(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_150(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_151(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_152(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_153(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_154(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_155(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_156(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_157(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_158(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_159(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_160(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_161(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_162(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_163(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_164(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_165(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_166(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_167(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_168(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_169(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_170(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_171(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_172(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_173(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_174(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_175(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_176(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_177(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_178(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_179(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_180(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_181(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_182(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_183(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_184(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_185(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_186(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_187(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_188(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_189(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_190(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_191(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_192(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_193(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_194(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_195(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_196(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_197(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_198(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_199(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_200(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_201(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_202(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_203(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_204(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_205(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_206(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_207(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_208(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_209(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_210(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_211(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_212(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_213(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_214(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_215(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_216(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_217(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_218(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_219(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_220(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_221(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_222(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_223(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_224(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_225(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_226(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_227(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_228(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_229(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_230(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_231(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_232(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_233(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_234(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_235(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_236(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_237(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_238(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_239(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_240(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_241(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_242(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_243(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_244(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_245(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_246(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_247(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_248(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_249(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_250(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_251(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_252(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_253(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_254(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_255(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_256(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_257(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_258(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_259(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_260(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_261(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_262(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_263(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_264(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_265(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_266(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_267(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_268(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_269(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_270(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_271(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_272(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_273(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_274(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_275(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_276(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_277(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_278(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_279(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_280(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_281(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_282(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_283(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_284(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_285(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_286(const void *,void *,uint64_t);
extern uint64_t narrow_half_probe_287(const void *,void *,uint64_t);
static const struct test_case cases[]={
{narrow_half_probe_0,0,0,0,1,UINT64_C(0)},
{narrow_half_probe_1,0,0,0,1,UINT64_C(0)},
{narrow_half_probe_2,0,1,0,1,UINT64_C(0)},
{narrow_half_probe_3,0,1,0,1,UINT64_C(0)},
{narrow_half_probe_4,0,2,0,1,UINT64_C(0)},
{narrow_half_probe_5,0,2,0,1,UINT64_C(0)},
{narrow_half_probe_6,0,3,0,1,UINT64_C(0)},
{narrow_half_probe_7,0,3,0,1,UINT64_C(0)},
{narrow_half_probe_8,0,4,0,1,UINT64_C(0)},
{narrow_half_probe_9,0,4,0,1,UINT64_C(0)},
{narrow_half_probe_10,0,5,0,1,UINT64_C(0)},
{narrow_half_probe_11,0,5,0,1,UINT64_C(0)},
{narrow_half_probe_12,0,0,1,1,UINT64_C(0)},
{narrow_half_probe_13,0,0,1,1,UINT64_C(0)},
{narrow_half_probe_14,0,1,1,1,UINT64_C(0)},
{narrow_half_probe_15,0,1,1,1,UINT64_C(0)},
{narrow_half_probe_16,0,2,1,1,UINT64_C(0)},
{narrow_half_probe_17,0,2,1,1,UINT64_C(0)},
{narrow_half_probe_18,0,3,1,1,UINT64_C(0)},
{narrow_half_probe_19,0,3,1,1,UINT64_C(0)},
{narrow_half_probe_20,0,4,1,1,UINT64_C(0)},
{narrow_half_probe_21,0,4,1,1,UINT64_C(0)},
{narrow_half_probe_22,0,5,1,1,UINT64_C(0)},
{narrow_half_probe_23,0,5,1,1,UINT64_C(0)},
{narrow_half_probe_24,0,0,0,2,UINT64_C(0)},
{narrow_half_probe_25,0,0,0,2,UINT64_C(0)},
{narrow_half_probe_26,0,1,0,2,UINT64_C(0)},
{narrow_half_probe_27,0,1,0,2,UINT64_C(0)},
{narrow_half_probe_28,0,2,0,2,UINT64_C(0)},
{narrow_half_probe_29,0,2,0,2,UINT64_C(0)},
{narrow_half_probe_30,0,3,0,2,UINT64_C(0)},
{narrow_half_probe_31,0,3,0,2,UINT64_C(0)},
{narrow_half_probe_32,0,4,0,2,UINT64_C(0)},
{narrow_half_probe_33,0,4,0,2,UINT64_C(0)},
{narrow_half_probe_34,0,5,0,2,UINT64_C(0)},
{narrow_half_probe_35,0,5,0,2,UINT64_C(0)},
{narrow_half_probe_36,0,0,1,2,UINT64_C(0)},
{narrow_half_probe_37,0,0,1,2,UINT64_C(0)},
{narrow_half_probe_38,0,1,1,2,UINT64_C(0)},
{narrow_half_probe_39,0,1,1,2,UINT64_C(0)},
{narrow_half_probe_40,0,2,1,2,UINT64_C(0)},
{narrow_half_probe_41,0,2,1,2,UINT64_C(0)},
{narrow_half_probe_42,0,3,1,2,UINT64_C(0)},
{narrow_half_probe_43,0,3,1,2,UINT64_C(0)},
{narrow_half_probe_44,0,4,1,2,UINT64_C(0)},
{narrow_half_probe_45,0,4,1,2,UINT64_C(0)},
{narrow_half_probe_46,0,5,1,2,UINT64_C(0)},
{narrow_half_probe_47,0,5,1,2,UINT64_C(0)},
{narrow_half_probe_48,0,0,0,3,UINT64_C(0)},
{narrow_half_probe_49,0,0,0,3,UINT64_C(0)},
{narrow_half_probe_50,0,1,0,3,UINT64_C(0)},
{narrow_half_probe_51,0,1,0,3,UINT64_C(0)},
{narrow_half_probe_52,0,2,0,3,UINT64_C(0)},
{narrow_half_probe_53,0,2,0,3,UINT64_C(0)},
{narrow_half_probe_54,0,3,0,3,UINT64_C(0)},
{narrow_half_probe_55,0,3,0,3,UINT64_C(0)},
{narrow_half_probe_56,0,4,0,3,UINT64_C(0)},
{narrow_half_probe_57,0,4,0,3,UINT64_C(0)},
{narrow_half_probe_58,0,5,0,3,UINT64_C(0)},
{narrow_half_probe_59,0,5,0,3,UINT64_C(0)},
{narrow_half_probe_60,0,0,1,3,UINT64_C(0)},
{narrow_half_probe_61,0,0,1,3,UINT64_C(0)},
{narrow_half_probe_62,0,1,1,3,UINT64_C(0)},
{narrow_half_probe_63,0,1,1,3,UINT64_C(0)},
{narrow_half_probe_64,0,2,1,3,UINT64_C(0)},
{narrow_half_probe_65,0,2,1,3,UINT64_C(0)},
{narrow_half_probe_66,0,3,1,3,UINT64_C(0)},
{narrow_half_probe_67,0,3,1,3,UINT64_C(0)},
{narrow_half_probe_68,0,4,1,3,UINT64_C(0)},
{narrow_half_probe_69,0,4,1,3,UINT64_C(0)},
{narrow_half_probe_70,0,5,1,3,UINT64_C(0)},
{narrow_half_probe_71,0,5,1,3,UINT64_C(0)},
{narrow_half_probe_72,0,0,0,7,UINT64_C(0)},
{narrow_half_probe_73,0,0,0,7,UINT64_C(0)},
{narrow_half_probe_74,0,1,0,7,UINT64_C(0)},
{narrow_half_probe_75,0,1,0,7,UINT64_C(0)},
{narrow_half_probe_76,0,2,0,7,UINT64_C(0)},
{narrow_half_probe_77,0,2,0,7,UINT64_C(0)},
{narrow_half_probe_78,0,3,0,7,UINT64_C(0)},
{narrow_half_probe_79,0,3,0,7,UINT64_C(0)},
{narrow_half_probe_80,0,4,0,7,UINT64_C(0)},
{narrow_half_probe_81,0,4,0,7,UINT64_C(0)},
{narrow_half_probe_82,0,5,0,7,UINT64_C(0)},
{narrow_half_probe_83,0,5,0,7,UINT64_C(0)},
{narrow_half_probe_84,0,0,1,7,UINT64_C(0)},
{narrow_half_probe_85,0,0,1,7,UINT64_C(0)},
{narrow_half_probe_86,0,1,1,7,UINT64_C(0)},
{narrow_half_probe_87,0,1,1,7,UINT64_C(0)},
{narrow_half_probe_88,0,2,1,7,UINT64_C(0)},
{narrow_half_probe_89,0,2,1,7,UINT64_C(0)},
{narrow_half_probe_90,0,3,1,7,UINT64_C(0)},
{narrow_half_probe_91,0,3,1,7,UINT64_C(0)},
{narrow_half_probe_92,0,4,1,7,UINT64_C(0)},
{narrow_half_probe_93,0,4,1,7,UINT64_C(0)},
{narrow_half_probe_94,0,5,1,7,UINT64_C(0)},
{narrow_half_probe_95,0,5,1,7,UINT64_C(0)},
{narrow_half_probe_96,0,0,0,8,UINT64_C(0)},
{narrow_half_probe_97,0,0,0,8,UINT64_C(0)},
{narrow_half_probe_98,0,1,0,8,UINT64_C(0)},
{narrow_half_probe_99,0,1,0,8,UINT64_C(0)},
{narrow_half_probe_100,0,2,0,8,UINT64_C(0)},
{narrow_half_probe_101,0,2,0,8,UINT64_C(0)},
{narrow_half_probe_102,0,3,0,8,UINT64_C(0)},
{narrow_half_probe_103,0,3,0,8,UINT64_C(0)},
{narrow_half_probe_104,0,4,0,8,UINT64_C(0)},
{narrow_half_probe_105,0,4,0,8,UINT64_C(0)},
{narrow_half_probe_106,0,5,0,8,UINT64_C(0)},
{narrow_half_probe_107,0,5,0,8,UINT64_C(0)},
{narrow_half_probe_108,0,0,1,8,UINT64_C(0)},
{narrow_half_probe_109,0,0,1,8,UINT64_C(0)},
{narrow_half_probe_110,0,1,1,8,UINT64_C(0)},
{narrow_half_probe_111,0,1,1,8,UINT64_C(0)},
{narrow_half_probe_112,0,2,1,8,UINT64_C(0)},
{narrow_half_probe_113,0,2,1,8,UINT64_C(0)},
{narrow_half_probe_114,0,3,1,8,UINT64_C(0)},
{narrow_half_probe_115,0,3,1,8,UINT64_C(0)},
{narrow_half_probe_116,0,4,1,8,UINT64_C(0)},
{narrow_half_probe_117,0,4,1,8,UINT64_C(0)},
{narrow_half_probe_118,0,5,1,8,UINT64_C(0)},
{narrow_half_probe_119,0,5,1,8,UINT64_C(0)},
{narrow_half_probe_120,0,0,0,11,UINT64_C(0)},
{narrow_half_probe_121,0,0,0,11,UINT64_C(0)},
{narrow_half_probe_122,0,1,0,11,UINT64_C(0)},
{narrow_half_probe_123,0,1,0,11,UINT64_C(0)},
{narrow_half_probe_124,0,2,0,11,UINT64_C(0)},
{narrow_half_probe_125,0,2,0,11,UINT64_C(0)},
{narrow_half_probe_126,0,3,0,11,UINT64_C(0)},
{narrow_half_probe_127,0,3,0,11,UINT64_C(0)},
{narrow_half_probe_128,0,4,0,11,UINT64_C(0)},
{narrow_half_probe_129,0,4,0,11,UINT64_C(0)},
{narrow_half_probe_130,0,5,0,11,UINT64_C(0)},
{narrow_half_probe_131,0,5,0,11,UINT64_C(0)},
{narrow_half_probe_132,0,0,1,11,UINT64_C(0)},
{narrow_half_probe_133,0,0,1,11,UINT64_C(0)},
{narrow_half_probe_134,0,1,1,11,UINT64_C(0)},
{narrow_half_probe_135,0,1,1,11,UINT64_C(0)},
{narrow_half_probe_136,0,2,1,11,UINT64_C(0)},
{narrow_half_probe_137,0,2,1,11,UINT64_C(0)},
{narrow_half_probe_138,0,3,1,11,UINT64_C(0)},
{narrow_half_probe_139,0,3,1,11,UINT64_C(0)},
{narrow_half_probe_140,0,4,1,11,UINT64_C(0)},
{narrow_half_probe_141,0,4,1,11,UINT64_C(0)},
{narrow_half_probe_142,0,5,1,11,UINT64_C(0)},
{narrow_half_probe_143,0,5,1,11,UINT64_C(0)},
{narrow_half_probe_144,0,0,0,12,UINT64_C(0)},
{narrow_half_probe_145,0,0,0,12,UINT64_C(0)},
{narrow_half_probe_146,0,1,0,12,UINT64_C(0)},
{narrow_half_probe_147,0,1,0,12,UINT64_C(0)},
{narrow_half_probe_148,0,2,0,12,UINT64_C(0)},
{narrow_half_probe_149,0,2,0,12,UINT64_C(0)},
{narrow_half_probe_150,0,3,0,12,UINT64_C(0)},
{narrow_half_probe_151,0,3,0,12,UINT64_C(0)},
{narrow_half_probe_152,0,4,0,12,UINT64_C(0)},
{narrow_half_probe_153,0,4,0,12,UINT64_C(0)},
{narrow_half_probe_154,0,5,0,12,UINT64_C(0)},
{narrow_half_probe_155,0,5,0,12,UINT64_C(0)},
{narrow_half_probe_156,0,0,1,12,UINT64_C(0)},
{narrow_half_probe_157,0,0,1,12,UINT64_C(0)},
{narrow_half_probe_158,0,1,1,12,UINT64_C(0)},
{narrow_half_probe_159,0,1,1,12,UINT64_C(0)},
{narrow_half_probe_160,0,2,1,12,UINT64_C(0)},
{narrow_half_probe_161,0,2,1,12,UINT64_C(0)},
{narrow_half_probe_162,0,3,1,12,UINT64_C(0)},
{narrow_half_probe_163,0,3,1,12,UINT64_C(0)},
{narrow_half_probe_164,0,4,1,12,UINT64_C(0)},
{narrow_half_probe_165,0,4,1,12,UINT64_C(0)},
{narrow_half_probe_166,0,5,1,12,UINT64_C(0)},
{narrow_half_probe_167,0,5,1,12,UINT64_C(0)},
{narrow_half_probe_168,0,0,0,15,UINT64_C(0)},
{narrow_half_probe_169,0,0,0,15,UINT64_C(0)},
{narrow_half_probe_170,0,1,0,15,UINT64_C(0)},
{narrow_half_probe_171,0,1,0,15,UINT64_C(0)},
{narrow_half_probe_172,0,2,0,15,UINT64_C(0)},
{narrow_half_probe_173,0,2,0,15,UINT64_C(0)},
{narrow_half_probe_174,0,3,0,15,UINT64_C(0)},
{narrow_half_probe_175,0,3,0,15,UINT64_C(0)},
{narrow_half_probe_176,0,4,0,15,UINT64_C(0)},
{narrow_half_probe_177,0,4,0,15,UINT64_C(0)},
{narrow_half_probe_178,0,5,0,15,UINT64_C(0)},
{narrow_half_probe_179,0,5,0,15,UINT64_C(0)},
{narrow_half_probe_180,0,0,1,15,UINT64_C(0)},
{narrow_half_probe_181,0,0,1,15,UINT64_C(0)},
{narrow_half_probe_182,0,1,1,15,UINT64_C(0)},
{narrow_half_probe_183,0,1,1,15,UINT64_C(0)},
{narrow_half_probe_184,0,2,1,15,UINT64_C(0)},
{narrow_half_probe_185,0,2,1,15,UINT64_C(0)},
{narrow_half_probe_186,0,3,1,15,UINT64_C(0)},
{narrow_half_probe_187,0,3,1,15,UINT64_C(0)},
{narrow_half_probe_188,0,4,1,15,UINT64_C(0)},
{narrow_half_probe_189,0,4,1,15,UINT64_C(0)},
{narrow_half_probe_190,0,5,1,15,UINT64_C(0)},
{narrow_half_probe_191,0,5,1,15,UINT64_C(0)},
{narrow_half_probe_192,0,0,0,16,UINT64_C(0)},
{narrow_half_probe_193,0,0,0,16,UINT64_C(0)},
{narrow_half_probe_194,0,1,0,16,UINT64_C(0)},
{narrow_half_probe_195,0,1,0,16,UINT64_C(0)},
{narrow_half_probe_196,0,2,0,16,UINT64_C(0)},
{narrow_half_probe_197,0,2,0,16,UINT64_C(0)},
{narrow_half_probe_198,0,3,0,16,UINT64_C(0)},
{narrow_half_probe_199,0,3,0,16,UINT64_C(0)},
{narrow_half_probe_200,0,4,0,16,UINT64_C(0)},
{narrow_half_probe_201,0,4,0,16,UINT64_C(0)},
{narrow_half_probe_202,0,5,0,16,UINT64_C(0)},
{narrow_half_probe_203,0,5,0,16,UINT64_C(0)},
{narrow_half_probe_204,0,0,1,16,UINT64_C(0)},
{narrow_half_probe_205,0,0,1,16,UINT64_C(0)},
{narrow_half_probe_206,0,1,1,16,UINT64_C(0)},
{narrow_half_probe_207,0,1,1,16,UINT64_C(0)},
{narrow_half_probe_208,0,2,1,16,UINT64_C(0)},
{narrow_half_probe_209,0,2,1,16,UINT64_C(0)},
{narrow_half_probe_210,0,3,1,16,UINT64_C(0)},
{narrow_half_probe_211,0,3,1,16,UINT64_C(0)},
{narrow_half_probe_212,0,4,1,16,UINT64_C(0)},
{narrow_half_probe_213,0,4,1,16,UINT64_C(0)},
{narrow_half_probe_214,0,5,1,16,UINT64_C(0)},
{narrow_half_probe_215,0,5,1,16,UINT64_C(0)},
{narrow_half_probe_216,0,0,0,17,UINT64_C(0)},
{narrow_half_probe_217,0,0,0,17,UINT64_C(0)},
{narrow_half_probe_218,0,1,0,17,UINT64_C(0)},
{narrow_half_probe_219,0,1,0,17,UINT64_C(0)},
{narrow_half_probe_220,0,2,0,17,UINT64_C(0)},
{narrow_half_probe_221,0,2,0,17,UINT64_C(0)},
{narrow_half_probe_222,0,3,0,17,UINT64_C(0)},
{narrow_half_probe_223,0,3,0,17,UINT64_C(0)},
{narrow_half_probe_224,0,4,0,17,UINT64_C(0)},
{narrow_half_probe_225,0,4,0,17,UINT64_C(0)},
{narrow_half_probe_226,0,5,0,17,UINT64_C(0)},
{narrow_half_probe_227,0,5,0,17,UINT64_C(0)},
{narrow_half_probe_228,0,0,1,17,UINT64_C(0)},
{narrow_half_probe_229,0,0,1,17,UINT64_C(0)},
{narrow_half_probe_230,0,1,1,17,UINT64_C(0)},
{narrow_half_probe_231,0,1,1,17,UINT64_C(0)},
{narrow_half_probe_232,0,2,1,17,UINT64_C(0)},
{narrow_half_probe_233,0,2,1,17,UINT64_C(0)},
{narrow_half_probe_234,0,3,1,17,UINT64_C(0)},
{narrow_half_probe_235,0,3,1,17,UINT64_C(0)},
{narrow_half_probe_236,0,4,1,17,UINT64_C(0)},
{narrow_half_probe_237,0,4,1,17,UINT64_C(0)},
{narrow_half_probe_238,0,5,1,17,UINT64_C(0)},
{narrow_half_probe_239,0,5,1,17,UINT64_C(0)},
{narrow_half_probe_240,0,0,0,24,UINT64_C(0)},
{narrow_half_probe_241,0,0,0,24,UINT64_C(0)},
{narrow_half_probe_242,0,1,0,24,UINT64_C(0)},
{narrow_half_probe_243,0,1,0,24,UINT64_C(0)},
{narrow_half_probe_244,0,2,0,24,UINT64_C(0)},
{narrow_half_probe_245,0,2,0,24,UINT64_C(0)},
{narrow_half_probe_246,0,3,0,24,UINT64_C(0)},
{narrow_half_probe_247,0,3,0,24,UINT64_C(0)},
{narrow_half_probe_248,0,4,0,24,UINT64_C(0)},
{narrow_half_probe_249,0,4,0,24,UINT64_C(0)},
{narrow_half_probe_250,0,5,0,24,UINT64_C(0)},
{narrow_half_probe_251,0,5,0,24,UINT64_C(0)},
{narrow_half_probe_252,0,0,1,24,UINT64_C(0)},
{narrow_half_probe_253,0,0,1,24,UINT64_C(0)},
{narrow_half_probe_254,0,1,1,24,UINT64_C(0)},
{narrow_half_probe_255,0,1,1,24,UINT64_C(0)},
{narrow_half_probe_256,0,2,1,24,UINT64_C(0)},
{narrow_half_probe_257,0,2,1,24,UINT64_C(0)},
{narrow_half_probe_258,0,3,1,24,UINT64_C(0)},
{narrow_half_probe_259,0,3,1,24,UINT64_C(0)},
{narrow_half_probe_260,0,4,1,24,UINT64_C(0)},
{narrow_half_probe_261,0,4,1,24,UINT64_C(0)},
{narrow_half_probe_262,0,5,1,24,UINT64_C(0)},
{narrow_half_probe_263,0,5,1,24,UINT64_C(0)},
{narrow_half_probe_264,0,0,0,31,UINT64_C(0)},
{narrow_half_probe_265,0,0,0,31,UINT64_C(0)},
{narrow_half_probe_266,0,1,0,31,UINT64_C(0)},
{narrow_half_probe_267,0,1,0,31,UINT64_C(0)},
{narrow_half_probe_268,0,2,0,31,UINT64_C(0)},
{narrow_half_probe_269,0,2,0,31,UINT64_C(0)},
{narrow_half_probe_270,0,3,0,31,UINT64_C(0)},
{narrow_half_probe_271,0,3,0,31,UINT64_C(0)},
{narrow_half_probe_272,0,4,0,31,UINT64_C(0)},
{narrow_half_probe_273,0,4,0,31,UINT64_C(0)},
{narrow_half_probe_274,0,5,0,31,UINT64_C(0)},
{narrow_half_probe_275,0,5,0,31,UINT64_C(0)},
{narrow_half_probe_276,0,0,1,31,UINT64_C(0)},
{narrow_half_probe_277,0,0,1,31,UINT64_C(0)},
{narrow_half_probe_278,0,1,1,31,UINT64_C(0)},
{narrow_half_probe_279,0,1,1,31,UINT64_C(0)},
{narrow_half_probe_280,0,2,1,31,UINT64_C(0)},
{narrow_half_probe_281,0,2,1,31,UINT64_C(0)},
{narrow_half_probe_282,0,3,1,31,UINT64_C(0)},
{narrow_half_probe_283,0,3,1,31,UINT64_C(0)},
{narrow_half_probe_284,0,4,1,31,UINT64_C(0)},
{narrow_half_probe_285,0,4,1,31,UINT64_C(0)},
{narrow_half_probe_286,0,5,1,31,UINT64_C(0)},
{narrow_half_probe_287,0,5,1,31,UINT64_C(0)},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
