#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef struct { double lo,hi; } Pair;
extern Pair preopt_pair_read(const void *);
extern Pair preopt_pair_snapshot(void *);
extern double preopt_table_private(uint64_t,_Bool);
extern double preopt_table_wide(unsigned __int128);
extern double preopt_table_pair(uint32_t);
extern double preopt_table_roundtrip(uint64_t);
__attribute__((noinline)) void preopt_mutate(void *p) {
 uint64_t words[2];memcpy(words,p,16);words[0]^=UINT64_MAX;words[1]^=UINT64_MAX;
 memcpy(p,words,16);
 __asm__ volatile("pxor %%xmm0,%%xmm0\n\tpxor %%xmm1,%%xmm1\n\t"
                  "movabs $0x1122334455667788,%%rcx\n\t"
                  "movabs $0x8877665544332211,%%rdx"
                  :::"xmm0","xmm1","rcx","rdx","cc","memory");
}
static const uint64_t payloads[]={0,1,UINT64_C(0x8000000000000000),
 UINT64_C(0x7ff0000000000000),UINT64_C(0xfff0000000000000),UINT64_C(0x7ff123456789abcd),
 UINT64_C(0xfff8abcd01234567),UINT64_C(0x0010000000000000),UINT64_C(0x000fffffffffffff),
 UINT64_C(0x3ff0000000000000),UINT64_C(0x0123456789abcdef),UINT64_MAX,2,7,15,16};
static int mismatch(unsigned which,unsigned i,unsigned j,unsigned fault,unsigned observations) {
 fprintf(stderr,"preopt-memory case=%u i=%u j=%u fault=%u observation=%u\n",which,i,j,fault,observations);
 return 1;
}
int main(int argc,char **argv) {
 unsigned fault=argc==2?(unsigned)strtoul(argv[1],0,10):0;
 if(argc>2||fault>6) return 2;
 long page=sysconf(_SC_PAGESIZE);if(page<64) return 2;
 unsigned char *mapping=mmap(0,(size_t)page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
 if(mapping==MAP_FAILED) return 2;
 unsigned char *area=mapping+page;
 if(mprotect(area,(size_t)page,PROT_READ|PROT_WRITE)) return 2;
 unsigned observations=0;
 for(unsigned i=0;i!=16;++i) for(unsigned j=0;j!=16;++j) {
  uint64_t a=payloads[i],b=payloads[j],expected[2]={a,b},actual[2];
  unsigned location=(i+j)%3;
  unsigned char *p=location==0?area:location==1?area+page-16:area+33;
  for(unsigned which=0;which!=2;++which) {
   memset(area,0xa5,(size_t)page);memcpy(p,expected,16);
   Pair value=which?preopt_pair_snapshot(p):preopt_pair_read(p);
   memcpy(actual,&value,16);
   if(fault==1&&which==0) {uint64_t tmp=actual[0];actual[0]=actual[1];actual[1]=tmp;}
   if(fault==2&&which==1) actual[1]^=1;
   if(actual[0]!=a||actual[1]!=b) return mismatch(which,i,j,fault,observations);
   uint64_t after[2];memcpy(after,p,16);
   if(after[0]!=(which?~a:a)||after[1]!=(which?~b:b)) return mismatch(which,i,j,fault,observations);
   for(unsigned char *q=area;q!=area+page;++q)
    if((q<p||q>=p+16)&&*q!=0xa5) return mismatch(which,i,j,fault,observations);
   ++observations;
  }
  for(unsigned which=0;which!=4;++which) {
   _Bool choose=(i+j)&1;
   uint64_t input=(b&~UINT64_C(255))|(i*16+j);
   double value=which==3?preopt_table_roundtrip(input):which==2?preopt_table_pair((uint32_t)input):which?preopt_table_wide(((unsigned __int128)a<<64)|input):preopt_table_private(input,choose);
   unsigned index=which==2?2*((unsigned)input&255)+1:(unsigned)(input^(which||choose?0:3))&15;
   double golden=(index+1)*(which==3?2.5:1.25);uint64_t raw,golden_raw;
   memcpy(&raw,&value,8);memcpy(&golden_raw,&golden,8);
   if(fault==3&&which==0) raw^=1;
   if(fault==4&&which==1) raw^=1;
   if(fault==5&&which==2) raw^=1;
   if(fault==6&&which==3) raw^=1;
   if(raw!=golden_raw) return mismatch(which+2,i,j,fault,observations);
   ++observations;
  }
 }
 if(munmap(mapping,(size_t)page*3)) return 2;
 printf("preopt-memory observations=%u exact-fp-payload-pair-snapshots=caller-clobbers=protected-page-edges=unaligned=uniform-private-stores=wide-masks=preserved\n",observations);
 return 0;
}
