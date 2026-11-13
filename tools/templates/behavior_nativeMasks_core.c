#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(void *,const void *,const void *,uint64_t);
struct test_case {kernel run;unsigned bits,predicate;};
static uint64_t raw(unsigned bits,unsigned seed,unsigned lane,unsigned side){
 const uint64_t f[]={0,0x80000000,1,0x3f800000,0xbf800000,0x7f800000,0xff800000,0x7fc00123,0xffc00456};
 const uint64_t d[]={0,UINT64_C(0x8000000000000000),1,UINT64_C(0x3ff0000000000000),UINT64_C(0xbff0000000000000),UINT64_C(0x7ff0000000000000),UINT64_C(0xfff0000000000000),UINT64_C(0x7ff8000000000123),UINT64_C(0xfff8000000000456)};
 unsigned index=(seed+lane+side)%9;
 return bits==32?f[index]:d[index];
}
static int compare(unsigned bits,unsigned predicate,uint64_t x,uint64_t y){
 double a,b;if(bits==32){uint32_t lx=x,ly=y;float fa,fb;memcpy(&fa,&lx,4);memcpy(&fb,&ly,4);a=fa;b=fb;}else{memcpy(&a,&x,8);memcpy(&b,&y,8);}
 int unordered=__builtin_isnan(a)||__builtin_isnan(b),ordered=!unordered;
 const int results[]={0,ordered&&a==b,ordered&&a>b,ordered&&a>=b,ordered&&a<b,ordered&&a<=b,ordered&&a!=b,ordered,unordered||a==b,unordered||a>b,unordered||a>=b,unordered||a<b,unordered||a<=b,unordered||a!=b,unordered,1};
 return results[predicate];
}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t observations=0,page=(size_t)sysconf(_SC_PAGESIZE);
 unsigned char *maps[3];for(unsigned i=0;i<3;i++){maps[i]=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(maps[i]==MAP_FAILED||mprotect(maps[i]+page,page,PROT_READ|PROT_WRITE))return 2;}
 for(size_t which=0;which<count;which++)for(unsigned seed=0;seed<64;seed++){
  unsigned bits=cases[which].bits,bytes=bits/8,lanes=128/bits;unsigned char *a=maps[0]+2*page-16,*b=maps[1]+2*page-16,*out=maps[2]+2*page-24;
  unsigned char expected[16],saved_a[16],saved_b[16],guard[8];memset(guard,0xa5,8);
  for(unsigned lane=0;lane<lanes;lane++){uint64_t x=raw(bits,seed,lane,0),y=raw(bits,seed*7,lane,seed%3),answer=compare(bits,cases[which].predicate,x,y)?x:y;memcpy(a+lane*bytes,&x,bytes);memcpy(b+lane*bytes,&y,bytes);memcpy(expected+lane*bytes,&answer,bytes);}
  memcpy(saved_a,a,16);memcpy(saved_b,b,16);memset(out-8,0xa5,32);
  uint64_t salt=seed*UINT64_C(0x9182736455aaccdd),answer=cases[which].run(out,a,b,salt);
  if(fault==1)out[0]^=1;if(fault==2)answer^=1;if(fault==3)out[16]^=1;
#define CHECK(c) do{++observations;if(!(c)){fprintf(stderr,"native-fp-mask case=%zu seed=%u observation=%zu fault=%u\n",which,seed,observations,fault);return 1;}}while(0)
  CHECK(answer==(salt^90));for(unsigned lane=0;lane<lanes;lane++)CHECK(memcmp(out+lane*bytes,expected+lane*bytes,bytes)==0);CHECK(memcmp(out-8,guard,8)==0);CHECK(memcmp(out+16,guard,8)==0);CHECK(memcmp(a,saved_a,16)==0);CHECK(memcmp(b,saved_b,16)==0);
#undef CHECK
 }
 for(unsigned i=0;i<3;i++)if(munmap(maps[i],page*3))return 2;
 printf("native-fp-masks observations=%zu all-sixteen-predicates=physical-xmm-returns=raw-payloads=stack-storage=guard-pages=preserved\n",observations);return 0;
}
