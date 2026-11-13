#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
struct test_case { kernel run; unsigned bits,lanes,subtract,literal; };
static void put_bits(unsigned char *p,unsigned offset,unsigned count,uint64_t value){for(unsigned i=0;i<count;i++){unsigned bit=offset+i;p[bit/8]=(p[bit/8]&~(1u<<(bit%8)))|(((value>>i)&1u)<<(bit%8));}}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
 unsigned char *map=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_READ|PROT_WRITE))return 2;
 for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
  const struct test_case *c=&cases[which];unsigned extent=(c->bits*c->lanes+7)/8,used=48+extent*2;unsigned char *input=map+2*page-used,saved[112],expected[32]={0};
  uint64_t mask=(UINT64_C(1)<<c->bits)-1,words[6];for(unsigned i=0;i<6;i++)words[i]=UINT64_C(0x9123456789abcdef)^(seed*UINT64_C(0x3141592653589793))^(i*UINT64_C(0x12345678abcdef01));
  memcpy(input,words,48);memset(input+48,0xa5,extent*2);
  for(unsigned lane=0;lane<c->lanes;lane++){
   uint64_t edge[]={0,1,mask,mask-1,mask/2,mask/2+1,mask/2+2,2};unsigned k=(seed+lane)%8;
   uint64_t a=seed<32?edge[k]:(words[lane%6]&mask),b=seed<32?edge[(seed/8+lane*3)%8]:((words[(lane+1)%6]>>1)&mask);
   put_bits(input+48,lane*c->bits,c->bits,a);put_bits(input+48+extent,lane*c->bits,c->bits,b);
   if(c->literal==1)a=mask;if(c->literal==2)b=mask;
   __uint128_t mathematical=c->subtract?(a>=b?(__uint128_t)a-b:0):(__uint128_t)a+b;
   uint64_t value=mathematical>mask?mask:(uint64_t)mathematical;put_bits(expected,lane*c->bits,c->bits,value);
  }
  memcpy(saved,input,used);uint64_t salt=UINT64_C(0x9182736455aaccdd)^seed,checksum=0;for(unsigned i=0;i<6;i++)checksum=checksum*UINT64_C(1099511628211)^words[i];
  unsigned char output[88];memset(output,0xa5,sizeof output);uint64_t answer=c->run(input,output+16,salt),tail[3];memcpy(tail,output+16+extent,24);
  if(fault==1)output[16]^=1;if(fault==2)answer^=1;if(fault==3)output[16+extent+24]^=1;
  unsigned tail_bits=(c->bits*c->lanes)%8;if(tail_bits)output[16+extent-1]&=(1u<<tail_bits)-1;
#define CHECK(v) do{++observations;if(!(v)){fprintf(stderr,"unsigned-odd-saturation case=%zu bits=%u lanes=%u seed=%u observation=%zu fault=%u\n",which,c->bits,c->lanes,seed,observations,fault);return 1;}}while(0)
  CHECK(answer==(checksum^salt));CHECK(memcmp(output+16,expected,extent)==0);CHECK(tail[0]==checksum);CHECK(tail[1]==salt);CHECK(tail[2]==words[0]);
  unsigned pre=0,post=0;for(unsigned i=0;i<16;i++){pre|=output[i]^0xa5;post|=output[16+extent+24+i]^0xa5;}CHECK(pre==0);CHECK(post==0);CHECK(memcmp(input,saved,used)==0);
#undef CHECK
 }
 printf("unsigned-odd-saturation observations=%zu integer-clamp-model=packed-vectors=literal-modes=live-aliases=stack-calls=guard-pages=preserved\n",observations);return munmap(map,page*3)!=0;
}
extern uint64_t unsigned_odd_probe_0(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_1(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_2(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_3(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_4(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_5(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_6(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_7(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_8(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_9(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_10(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_11(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_12(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_13(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_14(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_15(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_16(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_17(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_18(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_19(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_20(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_21(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_22(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_23(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_24(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_25(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_26(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_27(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_28(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_29(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_30(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_31(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_32(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_33(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_34(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_35(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_36(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_37(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_38(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_39(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_40(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_41(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_42(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_43(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_44(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_45(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_46(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_47(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_48(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_49(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_50(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_51(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_52(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_53(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_54(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_55(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_56(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_57(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_58(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_59(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_60(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_61(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_62(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_63(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_64(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_65(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_66(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_67(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_68(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_69(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_70(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_71(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_72(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_73(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_74(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_75(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_76(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_77(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_78(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_79(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_80(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_81(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_82(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_83(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_84(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_85(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_86(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_87(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_88(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_89(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_90(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_91(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_92(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_93(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_94(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_95(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_96(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_97(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_98(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_99(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_100(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_101(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_102(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_103(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_104(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_105(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_106(const void *,void *,uint64_t);
extern uint64_t unsigned_odd_probe_107(const void *,void *,uint64_t);
static const struct test_case cases[]={
{unsigned_odd_probe_0,40,1,0,0},
{unsigned_odd_probe_1,40,1,0,0},
{unsigned_odd_probe_2,40,1,0,1},
{unsigned_odd_probe_3,40,1,0,1},
{unsigned_odd_probe_4,40,1,0,2},
{unsigned_odd_probe_5,40,1,0,2},
{unsigned_odd_probe_6,40,1,1,0},
{unsigned_odd_probe_7,40,1,1,0},
{unsigned_odd_probe_8,40,1,1,1},
{unsigned_odd_probe_9,40,1,1,1},
{unsigned_odd_probe_10,40,1,1,2},
{unsigned_odd_probe_11,40,1,1,2},
{unsigned_odd_probe_12,40,2,0,0},
{unsigned_odd_probe_13,40,2,0,0},
{unsigned_odd_probe_14,40,2,0,1},
{unsigned_odd_probe_15,40,2,0,1},
{unsigned_odd_probe_16,40,2,0,2},
{unsigned_odd_probe_17,40,2,0,2},
{unsigned_odd_probe_18,40,2,1,0},
{unsigned_odd_probe_19,40,2,1,0},
{unsigned_odd_probe_20,40,2,1,1},
{unsigned_odd_probe_21,40,2,1,1},
{unsigned_odd_probe_22,40,2,1,2},
{unsigned_odd_probe_23,40,2,1,2},
{unsigned_odd_probe_24,40,4,0,0},
{unsigned_odd_probe_25,40,4,0,0},
{unsigned_odd_probe_26,40,4,0,1},
{unsigned_odd_probe_27,40,4,0,1},
{unsigned_odd_probe_28,40,4,0,2},
{unsigned_odd_probe_29,40,4,0,2},
{unsigned_odd_probe_30,40,4,1,0},
{unsigned_odd_probe_31,40,4,1,0},
{unsigned_odd_probe_32,40,4,1,1},
{unsigned_odd_probe_33,40,4,1,1},
{unsigned_odd_probe_34,40,4,1,2},
{unsigned_odd_probe_35,40,4,1,2},
{unsigned_odd_probe_36,48,1,0,0},
{unsigned_odd_probe_37,48,1,0,0},
{unsigned_odd_probe_38,48,1,0,1},
{unsigned_odd_probe_39,48,1,0,1},
{unsigned_odd_probe_40,48,1,0,2},
{unsigned_odd_probe_41,48,1,0,2},
{unsigned_odd_probe_42,48,1,1,0},
{unsigned_odd_probe_43,48,1,1,0},
{unsigned_odd_probe_44,48,1,1,1},
{unsigned_odd_probe_45,48,1,1,1},
{unsigned_odd_probe_46,48,1,1,2},
{unsigned_odd_probe_47,48,1,1,2},
{unsigned_odd_probe_48,48,2,0,0},
{unsigned_odd_probe_49,48,2,0,0},
{unsigned_odd_probe_50,48,2,0,1},
{unsigned_odd_probe_51,48,2,0,1},
{unsigned_odd_probe_52,48,2,0,2},
{unsigned_odd_probe_53,48,2,0,2},
{unsigned_odd_probe_54,48,2,1,0},
{unsigned_odd_probe_55,48,2,1,0},
{unsigned_odd_probe_56,48,2,1,1},
{unsigned_odd_probe_57,48,2,1,1},
{unsigned_odd_probe_58,48,2,1,2},
{unsigned_odd_probe_59,48,2,1,2},
{unsigned_odd_probe_60,48,4,0,0},
{unsigned_odd_probe_61,48,4,0,0},
{unsigned_odd_probe_62,48,4,0,1},
{unsigned_odd_probe_63,48,4,0,1},
{unsigned_odd_probe_64,48,4,0,2},
{unsigned_odd_probe_65,48,4,0,2},
{unsigned_odd_probe_66,48,4,1,0},
{unsigned_odd_probe_67,48,4,1,0},
{unsigned_odd_probe_68,48,4,1,1},
{unsigned_odd_probe_69,48,4,1,1},
{unsigned_odd_probe_70,48,4,1,2},
{unsigned_odd_probe_71,48,4,1,2},
{unsigned_odd_probe_72,56,1,0,0},
{unsigned_odd_probe_73,56,1,0,0},
{unsigned_odd_probe_74,56,1,0,1},
{unsigned_odd_probe_75,56,1,0,1},
{unsigned_odd_probe_76,56,1,0,2},
{unsigned_odd_probe_77,56,1,0,2},
{unsigned_odd_probe_78,56,1,1,0},
{unsigned_odd_probe_79,56,1,1,0},
{unsigned_odd_probe_80,56,1,1,1},
{unsigned_odd_probe_81,56,1,1,1},
{unsigned_odd_probe_82,56,1,1,2},
{unsigned_odd_probe_83,56,1,1,2},
{unsigned_odd_probe_84,56,2,0,0},
{unsigned_odd_probe_85,56,2,0,0},
{unsigned_odd_probe_86,56,2,0,1},
{unsigned_odd_probe_87,56,2,0,1},
{unsigned_odd_probe_88,56,2,0,2},
{unsigned_odd_probe_89,56,2,0,2},
{unsigned_odd_probe_90,56,2,1,0},
{unsigned_odd_probe_91,56,2,1,0},
{unsigned_odd_probe_92,56,2,1,1},
{unsigned_odd_probe_93,56,2,1,1},
{unsigned_odd_probe_94,56,2,1,2},
{unsigned_odd_probe_95,56,2,1,2},
{unsigned_odd_probe_96,56,4,0,0},
{unsigned_odd_probe_97,56,4,0,0},
{unsigned_odd_probe_98,56,4,0,1},
{unsigned_odd_probe_99,56,4,0,1},
{unsigned_odd_probe_100,56,4,0,2},
{unsigned_odd_probe_101,56,4,0,2},
{unsigned_odd_probe_102,56,4,1,0},
{unsigned_odd_probe_103,56,4,1,0},
{unsigned_odd_probe_104,56,4,1,1},
{unsigned_odd_probe_105,56,4,1,1},
{unsigned_odd_probe_106,56,4,1,2},
{unsigned_odd_probe_107,56,4,1,2},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
