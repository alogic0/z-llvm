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
