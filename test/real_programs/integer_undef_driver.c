#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
struct test_case{kernel run;unsigned kind,bits,to;};
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t page=(size_t)sysconf(_SC_PAGESIZE),observations=0;
 unsigned char *im=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0),*om=mmap(0,page*4,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(im==MAP_FAILED||om==MAP_FAILED||mprotect(im+page,page,PROT_READ|PROT_WRITE)||mprotect(om+page,page*2,PROT_READ|PROT_WRITE))return 2;
 for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
  const struct test_case *c=&cases[which];unsigned extent=((c->kind==2?c->bits:c->to)+7)/8;if(extent+64>page*2)return 2;uint64_t words[6];for(unsigned i=0;i<6;i++)words[i]=UINT64_C(0x9182736455aaccdd)^(seed*UINT64_C(0x3141592653589793))^(i*UINT64_C(0x12345678abcdef01));unsigned char *input=im+2*page-48,*out=om+3*page-16-32-extent,saved[48];memcpy(input,words,48);memcpy(saved,input,48);memset(out-16,0xa5,extent+64);
  uint64_t checksum=words[4],salt=words[5]^seed;for(unsigned i=0;i<6;i++)checksum=checksum*UINT64_C(1099511628211)^words[i];uint64_t answer=c->run(input,out,salt);if(fault==1){if(c->kind==2)out[0]^=1;else{uint64_t invalid=UINT64_C(1)<<(c->kind==1?c->bits-1:c->bits);memcpy(out,&invalid,extent);}}if(fault==2)answer^=1;if(fault==3)out[extent+32]^=1;
#define CHECK(v) do{++observations;if(!(v)){fprintf(stderr,"integer-undef case=%zu kind=%u bits=%u to=%u seed=%u observation=%zu fault=%u\n",which,c->kind,c->bits,c->to,seed,observations,fault);return 1;}}while(0)
  CHECK(answer==(checksum^salt));if(c->kind==2){uint64_t first,last;memcpy(&first,out,8);memcpy(&last,out+extent-8,8);CHECK(first==words[0]);CHECK(last==words[1]);}else{uint64_t value=0;memcpy(&value,out,extent);if(c->kind==1){int64_t signed_value;if(c->to==64)memcpy(&signed_value,&value,8);else{signed_value=(int64_t)value;if(value&(UINT64_C(1)<<(c->to-1)))signed_value-=INT64_C(1)<<c->to;}CHECK(signed_value>=-(INT64_C(1)<<(c->bits-1))&&signed_value<=(INT64_C(1)<<(c->bits-1))-1);}else CHECK(value<=((UINT64_C(1)<<c->bits)-1));}
  uint64_t marker,tail[3];memcpy(&marker,out+extent,8);memcpy(tail,out+extent+8,24);CHECK(marker==words[4]);CHECK(tail[0]==checksum);CHECK(tail[1]==salt);CHECK(tail[2]==words[0]);unsigned pre=0,post=0;for(unsigned i=0;i<16;i++){pre|=out[(int)i-16]^0xa5;post|=out[extent+32+i]^0xa5;}CHECK(pre==0);CHECK(post==0);CHECK(memcmp(input,saved,48)==0);
#undef CHECK
 }
 printf("integer-undef observations=%zu refinement-domains=defined-endpoints=guard-pages=live-aliases=client-request-marker=preserved\n",observations);if(munmap(im,page*3)||munmap(om,page*4))return 2;return 0;
}
extern uint64_t integer_undef_probe_0(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_1(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_2(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_3(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_4(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_5(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_6(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_7(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_8(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_9(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_10(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_11(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_12(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_13(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_14(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_15(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_16(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_17(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_18(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_19(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_20(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_21(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_22(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_23(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_24(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_25(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_26(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_27(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_28(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_29(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_30(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_31(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_32(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_33(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_34(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_35(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_36(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_37(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_38(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_39(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_40(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_41(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_42(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_43(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_44(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_45(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_46(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_47(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_48(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_49(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_50(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_51(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_52(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_53(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_54(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_55(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_56(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_57(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_58(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_59(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_60(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_61(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_62(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_63(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_64(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_65(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_66(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_67(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_68(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_69(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_70(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_71(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_72(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_73(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_74(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_75(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_76(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_77(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_78(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_79(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_80(const void *,void *,uint64_t);
extern uint64_t integer_undef_probe_81(const void *,void *,uint64_t);
static const struct test_case cases[]={
{integer_undef_probe_0,0,1,8},
{integer_undef_probe_1,0,1,8},
{integer_undef_probe_2,1,1,8},
{integer_undef_probe_3,1,1,8},
{integer_undef_probe_4,0,1,16},
{integer_undef_probe_5,0,1,16},
{integer_undef_probe_6,1,1,16},
{integer_undef_probe_7,1,1,16},
{integer_undef_probe_8,0,1,32},
{integer_undef_probe_9,0,1,32},
{integer_undef_probe_10,1,1,32},
{integer_undef_probe_11,1,1,32},
{integer_undef_probe_12,0,1,64},
{integer_undef_probe_13,0,1,64},
{integer_undef_probe_14,1,1,64},
{integer_undef_probe_15,1,1,64},
{integer_undef_probe_16,0,4,8},
{integer_undef_probe_17,0,4,8},
{integer_undef_probe_18,1,4,8},
{integer_undef_probe_19,1,4,8},
{integer_undef_probe_20,0,4,16},
{integer_undef_probe_21,0,4,16},
{integer_undef_probe_22,1,4,16},
{integer_undef_probe_23,1,4,16},
{integer_undef_probe_24,0,4,32},
{integer_undef_probe_25,0,4,32},
{integer_undef_probe_26,1,4,32},
{integer_undef_probe_27,1,4,32},
{integer_undef_probe_28,0,4,64},
{integer_undef_probe_29,0,4,64},
{integer_undef_probe_30,1,4,64},
{integer_undef_probe_31,1,4,64},
{integer_undef_probe_32,0,7,8},
{integer_undef_probe_33,0,7,8},
{integer_undef_probe_34,1,7,8},
{integer_undef_probe_35,1,7,8},
{integer_undef_probe_36,0,7,16},
{integer_undef_probe_37,0,7,16},
{integer_undef_probe_38,1,7,16},
{integer_undef_probe_39,1,7,16},
{integer_undef_probe_40,0,7,32},
{integer_undef_probe_41,0,7,32},
{integer_undef_probe_42,1,7,32},
{integer_undef_probe_43,1,7,32},
{integer_undef_probe_44,0,7,64},
{integer_undef_probe_45,0,7,64},
{integer_undef_probe_46,1,7,64},
{integer_undef_probe_47,1,7,64},
{integer_undef_probe_48,0,15,16},
{integer_undef_probe_49,0,15,16},
{integer_undef_probe_50,1,15,16},
{integer_undef_probe_51,1,15,16},
{integer_undef_probe_52,0,15,32},
{integer_undef_probe_53,0,15,32},
{integer_undef_probe_54,1,15,32},
{integer_undef_probe_55,1,15,32},
{integer_undef_probe_56,0,15,64},
{integer_undef_probe_57,0,15,64},
{integer_undef_probe_58,1,15,64},
{integer_undef_probe_59,1,15,64},
{integer_undef_probe_60,0,31,32},
{integer_undef_probe_61,0,31,32},
{integer_undef_probe_62,1,31,32},
{integer_undef_probe_63,1,31,32},
{integer_undef_probe_64,0,31,64},
{integer_undef_probe_65,0,31,64},
{integer_undef_probe_66,1,31,64},
{integer_undef_probe_67,1,31,64},
{integer_undef_probe_68,3,8,64},
{integer_undef_probe_69,3,8,64},
{integer_undef_probe_70,3,63,64},
{integer_undef_probe_71,3,63,64},
{integer_undef_probe_72,2,129,0},
{integer_undef_probe_73,2,129,0},
{integer_undef_probe_74,2,512,0},
{integer_undef_probe_75,2,512,0},
{integer_undef_probe_76,2,800,0},
{integer_undef_probe_77,2,800,0},
{integer_undef_probe_78,2,1024,0},
{integer_undef_probe_79,2,1024,0},
{integer_undef_probe_80,2,64000,0},
{integer_undef_probe_81,2,64000,0},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
