#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(void *,const void *,const void *,uint64_t);
struct test_case {kernel run;unsigned bits,lanes,maximum;};
static size_t observations;
#define RUN(B,F) static int run_##B(const struct test_case *cases,size_t count,unsigned char **maps,size_t page,unsigned fault){ \
 for(size_t which=0;which<count;which++)if(cases[which].bits==B)for(unsigned seed=0;seed<64;seed++){ \
  unsigned n=cases[which].lanes,bytes=B/8,maximum=cases[which].maximum;size_t size=n*bytes; \
  unsigned char *a=maps[0]+2*page-size,*b=maps[1]+2*page-size,*out=maps[2]+2*page-size-8;F left[4],right[4],expected[4]; \
  unsigned char saved_a[64],saved_b[64],guard[8];memset(guard,0xa5,8); \
  for(unsigned lane=0;lane<n;lane++){ \
   left[lane]=(F)((int)((seed*7+lane*11)%31)-15)/(F)4;right[lane]=(F)((int)((seed*13+lane*3)%31)-15)/(F)4; \
   if(seed==0){left[lane]=(F)0;right[lane]=(F)-0.0;}if(seed==1){left[lane]=(F)-0.0;right[lane]=(F)0;} \
   if(seed==2){left[lane]=(F)__builtin_infl();right[lane]=(F)-__builtin_infl();}if(seed==3){left[lane]=(F)__builtin_nanl("");right[lane]=(F)(lane-2.0);} \
   if(seed==4){right[lane]=(F)__builtin_nanl("");left[lane]=(F)(lane-2.0);}if(seed==5)left[lane]=right[lane]=(F)__builtin_nanl(""); \
   if(seed==6)left[lane]=right[lane]=(F)-0.0;if(seed==7)left[lane]=right[lane]=(F)0; \
   F x=left[lane],y=right[lane];if(__builtin_isnan(x))expected[lane]=y;else if(__builtin_isnan(y))expected[lane]=x; \
   else if(x==(F)0&&y==(F)0){int negative=maximum?(__builtin_signbit(x)&&__builtin_signbit(y)):(__builtin_signbit(x)||__builtin_signbit(y));expected[lane]=negative?(F)-0.0:(F)0;} \
   else expected[lane]=maximum?(x>y?x:y):(x<y?x:y); \
   memcpy(a+lane*bytes,&left[lane],bytes);memcpy(b+lane*bytes,&right[lane],bytes); \
  } \
  memcpy(saved_a,a,size);memcpy(saved_b,b,size);memset(out-8,0xa5,size+16);uint64_t salt=seed*UINT64_C(0x9182736455aaccdd),answer=cases[which].run(out,a,b,salt); \
  if(fault==1)out[0]^=1;if(fault==2)answer^=1;if(fault==3)out[size]^=1; \
  if(++observations,answer!=(salt^90)){fprintf(stderr,"vector-extrema return bits=%u seed=%u fault=%u\n",B,seed,fault);return 1;} \
  for(unsigned lane=0;lane<n;lane++){F actual=(F)0;memcpy(&actual,out+lane*bytes,bytes);F wanted=expected[lane];int equal=__builtin_isnan(wanted)?__builtin_isnan(actual):(actual==wanted&&(wanted!=(F)0||!!__builtin_signbit(actual)==!!__builtin_signbit(wanted)));++observations;if(!equal){fprintf(stderr,"vector-extrema bits=%u lanes=%u max=%u seed=%u lane=%u fault=%u\n",B,n,maximum,seed,lane,fault);return 1;}} \
  observations+=4;if(memcmp(out-8,guard,8)||memcmp(out+size,guard,8)||memcmp(a,saved_a,size)||memcmp(b,saved_b,size)){fprintf(stderr,"vector-extrema guards bits=%u seed=%u fault=%u\n",B,seed,fault);return 1;} \
 }return 0; \
}
RUN(16,_Float16) RUN(32,float) RUN(64,double) RUN(80,long double) RUN(128,__float128)
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t page=(size_t)sysconf(_SC_PAGESIZE);unsigned char *maps[3];
 for(unsigned i=0;i<3;i++){maps[i]=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(maps[i]==MAP_FAILED||mprotect(maps[i]+page,page,PROT_READ|PROT_WRITE))return 2;}
 if(run_16(cases,count,maps,page,fault)||run_32(cases,count,maps,page,fault)||run_64(cases,count,maps,page,fault)||run_80(cases,count,maps,page,fault)||run_128(cases,count,maps,page,fault))return 1;
 for(unsigned i=0;i<3;i++)if(munmap(maps[i],page*3))return 2;
 printf("vector-fp-extrema observations=%zu five-formats=independent-c-model=canonical-zero-ties=quiet-nan-classification=exact-stores=guard-pages=preserved\n",observations);return 0;
}
