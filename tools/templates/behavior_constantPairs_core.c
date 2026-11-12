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
