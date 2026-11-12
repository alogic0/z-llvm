#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef uint64_t (*kernel)(void *,uint64_t);
struct test_case{unsigned bits,op;kernel run;};
static uint64_t model(unsigned bits,unsigned op,unsigned sample){
 uint64_t mask=bits==64?UINT64_MAX:(UINT64_C(1)<<bits)-1;
 uint64_t xs[]={0,1,mask,UINT64_C(1)<<(bits-1)},shifts[]={0,bits>1?1:0,bits-1,bits/2},divisors[]={1,1,mask,1},others[]={mask,mask,1,1};
 uint64_t x=xs[sample],y=(op>=6&&op<=8?shifts:op>=9?divisors:others)[sample],r;
 switch(op){case 0:r=x+y;break;case 1:r=x-y;break;case 2:r=x*y;break;case 3:r=x&y;break;case 4:r=x|y;break;case 5:r=x^y;break;case 6:r=x<<y;break;case 7:r=x>>y;break;case 8:{int64_t sign=(int64_t)(x<<(64-bits));sign>>=64-bits;r=(uint64_t)(sign>>y);break;}case 9:r=x/y;break;case 10:r=x%y;break;default:abort();}return r&mask;
}
static size_t observations;
static void check(int pass,unsigned slot,unsigned seed,unsigned fault){observations++;if(!pass){fprintf(stderr,"integer-constant-pairs slot=%u seed=%u observation=%zu fault=%u\n",slot,seed,observations,fault);exit(1);}}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;if(fault>3)return 2;
 for(unsigned slot=0;slot<count;slot++)for(unsigned seed=0;seed<64;seed++){
  struct{unsigned char pre[9],data[32],post[9];}out;memset(&out,0xa5,sizeof out);uint64_t salt=(seed+slot*37)*UINT64_C(0xf06dea67e461de5b);
  uint64_t returned=cases[slot].run(out.data,salt);if(fault==1)returned^=1;if(fault==2)out.data[0]^=1;if(fault==3)out.post[0]^=1;
  check(returned==(salt^90),slot,seed,fault);for(unsigned sample=0;sample<4;sample++){uint64_t actual;memcpy(&actual,out.data+sample*8,8);check(actual==(model(cases[slot].bits,cases[slot].op,sample)^salt),slot,seed,fault);}
  int pre=1,post=1;for(unsigned i=0;i<9;i++){pre&=out.pre[i]==0xa5;post&=out.post[i]==0xa5;}check(pre,slot,seed,fault);check(post,slot,seed,fault);
 }
 if(count!=66||observations!=29568)return 2;printf("integer-constant-pairs observations=%zu defined-literal-operations=modular-widths=live-values=exact-stores=preserved\n",observations);return 0;
}
extern uint64_t constant_pairs_1_add(void *,uint64_t);
extern uint64_t constant_pairs_1_sub(void *,uint64_t);
extern uint64_t constant_pairs_1_mul(void *,uint64_t);
extern uint64_t constant_pairs_1_and(void *,uint64_t);
extern uint64_t constant_pairs_1_or(void *,uint64_t);
extern uint64_t constant_pairs_1_xor(void *,uint64_t);
extern uint64_t constant_pairs_1_shl(void *,uint64_t);
extern uint64_t constant_pairs_1_lshr(void *,uint64_t);
extern uint64_t constant_pairs_1_ashr(void *,uint64_t);
extern uint64_t constant_pairs_1_udiv(void *,uint64_t);
extern uint64_t constant_pairs_1_urem(void *,uint64_t);
extern uint64_t constant_pairs_3_add(void *,uint64_t);
extern uint64_t constant_pairs_3_sub(void *,uint64_t);
extern uint64_t constant_pairs_3_mul(void *,uint64_t);
extern uint64_t constant_pairs_3_and(void *,uint64_t);
extern uint64_t constant_pairs_3_or(void *,uint64_t);
extern uint64_t constant_pairs_3_xor(void *,uint64_t);
extern uint64_t constant_pairs_3_shl(void *,uint64_t);
extern uint64_t constant_pairs_3_lshr(void *,uint64_t);
extern uint64_t constant_pairs_3_ashr(void *,uint64_t);
extern uint64_t constant_pairs_3_udiv(void *,uint64_t);
extern uint64_t constant_pairs_3_urem(void *,uint64_t);
extern uint64_t constant_pairs_8_add(void *,uint64_t);
extern uint64_t constant_pairs_8_sub(void *,uint64_t);
extern uint64_t constant_pairs_8_mul(void *,uint64_t);
extern uint64_t constant_pairs_8_and(void *,uint64_t);
extern uint64_t constant_pairs_8_or(void *,uint64_t);
extern uint64_t constant_pairs_8_xor(void *,uint64_t);
extern uint64_t constant_pairs_8_shl(void *,uint64_t);
extern uint64_t constant_pairs_8_lshr(void *,uint64_t);
extern uint64_t constant_pairs_8_ashr(void *,uint64_t);
extern uint64_t constant_pairs_8_udiv(void *,uint64_t);
extern uint64_t constant_pairs_8_urem(void *,uint64_t);
extern uint64_t constant_pairs_17_add(void *,uint64_t);
extern uint64_t constant_pairs_17_sub(void *,uint64_t);
extern uint64_t constant_pairs_17_mul(void *,uint64_t);
extern uint64_t constant_pairs_17_and(void *,uint64_t);
extern uint64_t constant_pairs_17_or(void *,uint64_t);
extern uint64_t constant_pairs_17_xor(void *,uint64_t);
extern uint64_t constant_pairs_17_shl(void *,uint64_t);
extern uint64_t constant_pairs_17_lshr(void *,uint64_t);
extern uint64_t constant_pairs_17_ashr(void *,uint64_t);
extern uint64_t constant_pairs_17_udiv(void *,uint64_t);
extern uint64_t constant_pairs_17_urem(void *,uint64_t);
extern uint64_t constant_pairs_32_add(void *,uint64_t);
extern uint64_t constant_pairs_32_sub(void *,uint64_t);
extern uint64_t constant_pairs_32_mul(void *,uint64_t);
extern uint64_t constant_pairs_32_and(void *,uint64_t);
extern uint64_t constant_pairs_32_or(void *,uint64_t);
extern uint64_t constant_pairs_32_xor(void *,uint64_t);
extern uint64_t constant_pairs_32_shl(void *,uint64_t);
extern uint64_t constant_pairs_32_lshr(void *,uint64_t);
extern uint64_t constant_pairs_32_ashr(void *,uint64_t);
extern uint64_t constant_pairs_32_udiv(void *,uint64_t);
extern uint64_t constant_pairs_32_urem(void *,uint64_t);
extern uint64_t constant_pairs_64_add(void *,uint64_t);
extern uint64_t constant_pairs_64_sub(void *,uint64_t);
extern uint64_t constant_pairs_64_mul(void *,uint64_t);
extern uint64_t constant_pairs_64_and(void *,uint64_t);
extern uint64_t constant_pairs_64_or(void *,uint64_t);
extern uint64_t constant_pairs_64_xor(void *,uint64_t);
extern uint64_t constant_pairs_64_shl(void *,uint64_t);
extern uint64_t constant_pairs_64_lshr(void *,uint64_t);
extern uint64_t constant_pairs_64_ashr(void *,uint64_t);
extern uint64_t constant_pairs_64_udiv(void *,uint64_t);
extern uint64_t constant_pairs_64_urem(void *,uint64_t);
static const struct test_case cases[]={
{1,0,constant_pairs_1_add},
{1,1,constant_pairs_1_sub},
{1,2,constant_pairs_1_mul},
{1,3,constant_pairs_1_and},
{1,4,constant_pairs_1_or},
{1,5,constant_pairs_1_xor},
{1,6,constant_pairs_1_shl},
{1,7,constant_pairs_1_lshr},
{1,8,constant_pairs_1_ashr},
{1,9,constant_pairs_1_udiv},
{1,10,constant_pairs_1_urem},
{3,0,constant_pairs_3_add},
{3,1,constant_pairs_3_sub},
{3,2,constant_pairs_3_mul},
{3,3,constant_pairs_3_and},
{3,4,constant_pairs_3_or},
{3,5,constant_pairs_3_xor},
{3,6,constant_pairs_3_shl},
{3,7,constant_pairs_3_lshr},
{3,8,constant_pairs_3_ashr},
{3,9,constant_pairs_3_udiv},
{3,10,constant_pairs_3_urem},
{8,0,constant_pairs_8_add},
{8,1,constant_pairs_8_sub},
{8,2,constant_pairs_8_mul},
{8,3,constant_pairs_8_and},
{8,4,constant_pairs_8_or},
{8,5,constant_pairs_8_xor},
{8,6,constant_pairs_8_shl},
{8,7,constant_pairs_8_lshr},
{8,8,constant_pairs_8_ashr},
{8,9,constant_pairs_8_udiv},
{8,10,constant_pairs_8_urem},
{17,0,constant_pairs_17_add},
{17,1,constant_pairs_17_sub},
{17,2,constant_pairs_17_mul},
{17,3,constant_pairs_17_and},
{17,4,constant_pairs_17_or},
{17,5,constant_pairs_17_xor},
{17,6,constant_pairs_17_shl},
{17,7,constant_pairs_17_lshr},
{17,8,constant_pairs_17_ashr},
{17,9,constant_pairs_17_udiv},
{17,10,constant_pairs_17_urem},
{32,0,constant_pairs_32_add},
{32,1,constant_pairs_32_sub},
{32,2,constant_pairs_32_mul},
{32,3,constant_pairs_32_and},
{32,4,constant_pairs_32_or},
{32,5,constant_pairs_32_xor},
{32,6,constant_pairs_32_shl},
{32,7,constant_pairs_32_lshr},
{32,8,constant_pairs_32_ashr},
{32,9,constant_pairs_32_udiv},
{32,10,constant_pairs_32_urem},
{64,0,constant_pairs_64_add},
{64,1,constant_pairs_64_sub},
{64,2,constant_pairs_64_mul},
{64,3,constant_pairs_64_and},
{64,4,constant_pairs_64_or},
{64,5,constant_pairs_64_xor},
{64,6,constant_pairs_64_shl},
{64,7,constant_pairs_64_lshr},
{64,8,constant_pairs_64_ashr},
{64,9,constant_pairs_64_udiv},
{64,10,constant_pairs_64_urem},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
