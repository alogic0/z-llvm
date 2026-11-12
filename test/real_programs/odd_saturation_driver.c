#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(void *,uint64_t,uint64_t,uint64_t);
struct test_case { unsigned bits,subtract; kernel run; };
static uint64_t model(unsigned bits,unsigned subtract,uint64_t left,uint64_t right,unsigned mode) {
 unsigned __int128 sign=(unsigned __int128)1<<(bits-1),mask=(sign<<1)-1;
 unsigned __int128 x=(mode==1||mode==3)?mask:(left&mask),y=(mode==2||mode==3)?1:(right&mask);
 __int128 sx=(__int128)(x^sign)-(__int128)sign,sy=(__int128)(y^sign)-(__int128)sign;
 __int128 result=subtract?sx-sy:sx+sy,minimum=-(__int128)sign,maximum=(__int128)(sign-1);
 if(result<minimum)result=minimum;if(result>maximum)result=maximum;
 return (uint64_t)((unsigned __int128)result&mask);
}
static size_t observations;
static void check(int pass,unsigned slot,unsigned seed,unsigned fault) {
 observations++;if(!pass){fprintf(stderr,"odd-saturation slot=%u seed=%u observation=%zu fault=%u\n",slot,seed,observations,fault);exit(1);}
}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv) {
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;if(fault>3)return 2;
 size_t page=(size_t)sysconf(_SC_PAGESIZE);
 unsigned char *out=mmap(0,page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
 if(out==MAP_FAILED||mprotect(out+page,page,PROT_NONE))return 2;
 unsigned char *payload=out+page-32;
 for(unsigned slot=0;slot<count;slot++)for(unsigned seed=0;seed<64;seed++) {
  unsigned bits=cases[slot].bits;uint64_t sign=UINT64_C(1)<<(bits-1),mask=bits==64?UINT64_MAX:(UINT64_C(1)<<bits)-1;
  uint64_t samples[]={0,1,mask,mask-1,sign,sign-1,UINT64_C(0x123456789abcdef0),UINT64_C(0xfedcba9876543210)};
  uint64_t left=samples[seed&7],right=samples[seed>>3],salt=(seed+slot*37)*UINT64_C(0xf06dea67e461de5b);
  memset(out,0xa5,page);uint64_t returned=cases[slot].run(payload,left,right,salt);
  if(fault==1)returned^=1;if(fault==2)payload[0]^=1;if(fault==3)payload[-1]^=1;
  check(returned==(salt^90),slot,seed,fault);
  for(unsigned mode=0;mode<4;mode++){uint64_t actual;memcpy(&actual,payload+mode*8,8);check(actual==(model(bits,cases[slot].subtract,left,right,mode)^salt),slot,seed,fault);}
  check(payload[-1]==0xa5,slot,seed,fault);int untouched=1;for(size_t i=0;i<page-33;i++)untouched&=out[i]==0xa5;check(untouched,slot,seed,fault);
 }
 if(count!=124||observations!=55552)return 2;
 munmap(out,page*2);printf("odd-saturation observations=%zu all-proved-widths=logical-signs=literal-modes=live-values=exact-stores=guard-page=preserved\n",observations);return 0;
}
extern uint64_t odd_saturation_1_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_1_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_2_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_2_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_3_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_3_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_4_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_4_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_5_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_5_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_6_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_6_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_7_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_7_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_8_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_8_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_9_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_9_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_10_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_10_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_11_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_11_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_12_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_12_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_13_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_13_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_14_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_14_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_15_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_15_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_16_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_16_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_17_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_17_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_18_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_18_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_19_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_19_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_20_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_20_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_21_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_21_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_22_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_22_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_23_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_23_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_24_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_24_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_25_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_25_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_26_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_26_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_27_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_27_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_28_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_28_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_29_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_29_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_30_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_30_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_31_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_31_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_32_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_32_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_33_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_33_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_34_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_34_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_35_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_35_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_36_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_36_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_37_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_37_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_38_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_38_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_39_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_39_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_40_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_40_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_41_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_41_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_42_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_42_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_43_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_43_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_44_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_44_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_45_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_45_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_46_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_46_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_47_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_47_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_48_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_48_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_49_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_49_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_50_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_50_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_53_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_53_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_54_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_54_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_55_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_55_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_56_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_56_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_57_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_57_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_58_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_58_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_59_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_59_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_60_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_60_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_61_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_61_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_62_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_62_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_63_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_63_1(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_64_0(void *,uint64_t,uint64_t,uint64_t);
extern uint64_t odd_saturation_64_1(void *,uint64_t,uint64_t,uint64_t);
static const struct test_case cases[]={
{1,0,odd_saturation_1_0},
{1,1,odd_saturation_1_1},
{2,0,odd_saturation_2_0},
{2,1,odd_saturation_2_1},
{3,0,odd_saturation_3_0},
{3,1,odd_saturation_3_1},
{4,0,odd_saturation_4_0},
{4,1,odd_saturation_4_1},
{5,0,odd_saturation_5_0},
{5,1,odd_saturation_5_1},
{6,0,odd_saturation_6_0},
{6,1,odd_saturation_6_1},
{7,0,odd_saturation_7_0},
{7,1,odd_saturation_7_1},
{8,0,odd_saturation_8_0},
{8,1,odd_saturation_8_1},
{9,0,odd_saturation_9_0},
{9,1,odd_saturation_9_1},
{10,0,odd_saturation_10_0},
{10,1,odd_saturation_10_1},
{11,0,odd_saturation_11_0},
{11,1,odd_saturation_11_1},
{12,0,odd_saturation_12_0},
{12,1,odd_saturation_12_1},
{13,0,odd_saturation_13_0},
{13,1,odd_saturation_13_1},
{14,0,odd_saturation_14_0},
{14,1,odd_saturation_14_1},
{15,0,odd_saturation_15_0},
{15,1,odd_saturation_15_1},
{16,0,odd_saturation_16_0},
{16,1,odd_saturation_16_1},
{17,0,odd_saturation_17_0},
{17,1,odd_saturation_17_1},
{18,0,odd_saturation_18_0},
{18,1,odd_saturation_18_1},
{19,0,odd_saturation_19_0},
{19,1,odd_saturation_19_1},
{20,0,odd_saturation_20_0},
{20,1,odd_saturation_20_1},
{21,0,odd_saturation_21_0},
{21,1,odd_saturation_21_1},
{22,0,odd_saturation_22_0},
{22,1,odd_saturation_22_1},
{23,0,odd_saturation_23_0},
{23,1,odd_saturation_23_1},
{24,0,odd_saturation_24_0},
{24,1,odd_saturation_24_1},
{25,0,odd_saturation_25_0},
{25,1,odd_saturation_25_1},
{26,0,odd_saturation_26_0},
{26,1,odd_saturation_26_1},
{27,0,odd_saturation_27_0},
{27,1,odd_saturation_27_1},
{28,0,odd_saturation_28_0},
{28,1,odd_saturation_28_1},
{29,0,odd_saturation_29_0},
{29,1,odd_saturation_29_1},
{30,0,odd_saturation_30_0},
{30,1,odd_saturation_30_1},
{31,0,odd_saturation_31_0},
{31,1,odd_saturation_31_1},
{32,0,odd_saturation_32_0},
{32,1,odd_saturation_32_1},
{33,0,odd_saturation_33_0},
{33,1,odd_saturation_33_1},
{34,0,odd_saturation_34_0},
{34,1,odd_saturation_34_1},
{35,0,odd_saturation_35_0},
{35,1,odd_saturation_35_1},
{36,0,odd_saturation_36_0},
{36,1,odd_saturation_36_1},
{37,0,odd_saturation_37_0},
{37,1,odd_saturation_37_1},
{38,0,odd_saturation_38_0},
{38,1,odd_saturation_38_1},
{39,0,odd_saturation_39_0},
{39,1,odd_saturation_39_1},
{40,0,odd_saturation_40_0},
{40,1,odd_saturation_40_1},
{41,0,odd_saturation_41_0},
{41,1,odd_saturation_41_1},
{42,0,odd_saturation_42_0},
{42,1,odd_saturation_42_1},
{43,0,odd_saturation_43_0},
{43,1,odd_saturation_43_1},
{44,0,odd_saturation_44_0},
{44,1,odd_saturation_44_1},
{45,0,odd_saturation_45_0},
{45,1,odd_saturation_45_1},
{46,0,odd_saturation_46_0},
{46,1,odd_saturation_46_1},
{47,0,odd_saturation_47_0},
{47,1,odd_saturation_47_1},
{48,0,odd_saturation_48_0},
{48,1,odd_saturation_48_1},
{49,0,odd_saturation_49_0},
{49,1,odd_saturation_49_1},
{50,0,odd_saturation_50_0},
{50,1,odd_saturation_50_1},
{53,0,odd_saturation_53_0},
{53,1,odd_saturation_53_1},
{54,0,odd_saturation_54_0},
{54,1,odd_saturation_54_1},
{55,0,odd_saturation_55_0},
{55,1,odd_saturation_55_1},
{56,0,odd_saturation_56_0},
{56,1,odd_saturation_56_1},
{57,0,odd_saturation_57_0},
{57,1,odd_saturation_57_1},
{58,0,odd_saturation_58_0},
{58,1,odd_saturation_58_1},
{59,0,odd_saturation_59_0},
{59,1,odd_saturation_59_1},
{60,0,odd_saturation_60_0},
{60,1,odd_saturation_60_1},
{61,0,odd_saturation_61_0},
{61,1,odd_saturation_61_1},
{62,0,odd_saturation_62_0},
{62,1,odd_saturation_62_1},
{63,0,odd_saturation_63_0},
{63,1,odd_saturation_63_1},
{64,0,odd_saturation_64_0},
{64,1,odd_saturation_64_1},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
