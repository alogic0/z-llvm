#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef unsigned __int128 U128;
extern U128 frontier_identity96(U128);
extern U128 frontier_not96(U128);
extern U128 frontier_not65(U128);
extern uint64_t frontier_word_mask(uint64_t,uint64_t);
extern uint64_t frontier_shift4(uint32_t,uint32_t,uint64_t);
extern uint64_t frontier_shift9(uint32_t,uint32_t,uint64_t);
extern uint64_t frontier_shift16(uint32_t,uint32_t,uint64_t);
extern uint32_t frontier_vector_lane(uint32_t,uint32_t);
extern void frontier_vector_snapshot(void *,void *);
static const uint64_t call_mask=UINT64_C(0x9e3779b97f4a7c15);
static const uint32_t mutation=UINT32_C(0xa5a5a5a5);
__attribute__((noinline)) uint64_t frontier_clobber(uint64_t value) {
 __asm__ volatile("movabs $0x1122334455667788,%%rcx\n\t"
                  "movabs $0x2233445566778899,%%rdx\n\t"
                  "movabs $0x33445566778899aa,%%rsi\n\t"
                  "movabs $0x445566778899aabb,%%r8\n\t"
                  "movabs $0x5566778899aabbcc,%%r9\n\t"
                  "pxor %%xmm0,%%xmm0\n\tpxor %%xmm1,%%xmm1"
                  :::"rcx","rdx","rsi","r8","r9","xmm0","xmm1","cc","memory");
 return value^call_mask;
}
__attribute__((noinline)) void frontier_mutate(void *pointer) {
 uint32_t words[4];memcpy(words,pointer,16);
 for(unsigned n=0;n<4;++n) words[n]^=mutation;
 memcpy(pointer,words,16);
 __asm__ volatile("pxor %%xmm0,%%xmm0\n\tpxor %%xmm1,%%xmm1\n\t"
                  "movabs $0x1122334455667788,%%rcx\n\t"
                  "movabs $0x8877665544332211,%%rdx"
                  :::"xmm0","xmm1","rcx","rdx","cc","memory");
}
static const uint64_t edges[]={0,1,UINT64_MAX,UINT64_C(0x8000000000000000),
 UINT64_C(0x7fffffffffffffff),UINT64_C(0x100000000),UINT64_C(0xffffffff),
 UINT64_C(0x0123456789abcdef),UINT64_C(0xfedcba9876543210),
 UINT64_C(0x7f80000080000000),UINT64_C(0xff80000000000001),
 UINT64_C(0x7f8123457fcabcde),UINT64_C(0x00800000007fffff),
 UINT64_C(0x3f800000bf800000),UINT64_C(0xaaaaaaaa55555555),UINT64_C(0x100000001)};
static int check(U128 actual,U128 expected,unsigned kind,unsigned input,unsigned count,unsigned fault) {
 if(actual==expected) return 0;
 fprintf(stderr,"preopt-test-frontier kind=%u input=%u count=%u fault=%u actual=%016llx:%016llx expected=%016llx:%016llx\n",
  kind,input,count,fault,(unsigned long long)(actual>>64),(unsigned long long)actual,
  (unsigned long long)(expected>>64),(unsigned long long)expected);
 return 1;
}
int main(int argc,char **argv) {
 unsigned fault=argc==2?(unsigned)strtoul(argv[1],0,10):0;
 if(argc>2||fault>6) return 2;
 long page=sysconf(_SC_PAGESIZE);if(page<64) return 2;
 unsigned char *src_map=mmap(0,(size_t)page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
 unsigned char *dst_map=mmap(0,(size_t)page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
 if(src_map==MAP_FAILED||dst_map==MAP_FAILED) return 2;
 unsigned char *src=src_map+page,*dst=dst_map+page;
 if(mprotect(src,(size_t)page,PROT_READ|PROT_WRITE)||mprotect(dst,(size_t)page,PROT_READ|PROT_WRITE)) return 2;
 const U128 mask96=((U128)1<<96)-1,mask65=((U128)1<<65)-1;
 unsigned observations=0;
 for(unsigned i=0;i<512;++i) {
  uint64_t lo=edges[i&15],hi=edges[(i>>4)&15];
  if(i>=256) {lo^=(uint64_t)i*UINT64_C(0x5eed12349e3779b9);hi^=(uint64_t)i*UINT64_C(0xd1b54a32d192ed03);}
  U128 input=((U128)hi<<64)|lo,actual,expected;
  actual=frontier_identity96(input);expected=input&mask96;
  if(fault==1) actual^=(U128)1<<100;
  if(check(actual,expected,0,i,0,fault)) return 1;++observations;
  if(check(frontier_not96(input),(~input)&mask96,1,i,0,fault)) return 1;++observations;
  actual=frontier_not65(input);if(fault==2) actual^=(U128)1<<64;
  if(check(actual,(~input)&mask65,2,i,0,fault)) return 1;++observations;
  if(check(frontier_word_mask(lo,hi),(lo+UINT64_C(1234567890123))^(hi&UINT32_MAX),3,i,0,fault)) return 1;++observations;
  uint32_t raw=frontier_vector_lane((uint32_t)lo,(uint32_t)hi);
  if(fault==5) raw^=1;
  if(check(raw,(uint32_t)lo,4,i,0,fault)) return 1;++observations;
  uint32_t words[4]={(uint32_t)lo,(uint32_t)(lo>>32),(uint32_t)hi,(uint32_t)(hi>>32)},out[4],after[4];
  unsigned char *sp=(i%3)==0?src:(i%3)==1?src+page-16:src+33;
  unsigned char *dp=(i%3)==0?dst+page-16:(i%3)==1?dst:dst+31;
  memset(src,0xa5,(size_t)page);memset(dst,0x5a,(size_t)page);memcpy(sp,words,16);
  frontier_vector_snapshot(sp,dp);memcpy(out,dp,16);memcpy(after,sp,16);
  if(fault==6) out[0]^=1;
  for(unsigned n=0;n<4;++n) {
   if(check(out[n],words[n],5,i,n,fault)||check(after[n],words[n]^mutation,6,i,n,fault)) return 1;
  }
  for(unsigned char *p=src;p!=src+page;++p) if((p<sp||p>=sp+16)&&*p!=0xa5) return 1;
  for(unsigned char *p=dst;p!=dst+page;++p) if((p<dp||p>=dp+16)&&*p!=0x5a) return 1;
  ++observations;
  uint64_t keep=hi^lo,returned=keep^call_mask;
  uint32_t value16=(uint32_t)(lo^(lo>>32)^(i*257u));
  for(unsigned count=0;count<16;++count) {
   if(count<4) {
    unsigned original=i&15,shifted=(original<<count)&15,overflow=(shifted>>count)!=original;
    uint64_t value=frontier_shift4(i,count,keep),golden=((uint64_t)shifted|((uint64_t)overflow<<32))^returned;
    if(fault==3) value^=UINT64_C(1)<<32;
    if(check(value,golden,7,i,count,fault)) return 1;++observations;
   }
   if(count<9) {
    unsigned shifted=(i<<count)&511;int signed_value=(shifted&256)?(int)shifted-512:(int)shifted;
    int denominator=1<<count;
    int round=signed_value>=0?signed_value/denominator:-((-signed_value+denominator-1)/denominator);
    unsigned overflow=((unsigned)round&511)!=i;
    uint64_t value=frontier_shift9(i,count,keep),golden=((uint64_t)shifted|((uint64_t)overflow<<32))^returned;
    if(fault==4) value^=UINT64_C(1)<<8;
    if(check(value,golden,8,i,count,fault)) return 1;++observations;
   }
   unsigned original=value16&65535,shifted=(original<<count)&65535,overflow=(shifted>>count)!=original;
   uint64_t value=frontier_shift16(value16,count,keep),golden=((uint64_t)shifted|((uint64_t)overflow<<32))^returned;
   if(fault==3) value^=UINT64_C(1)<<32;
   if(check(value,golden,9,i,count,fault)) return 1;++observations;
  }
 }
 if(observations!=17920||munmap(src_map,(size_t)page*3)||munmap(dst_map,(size_t)page*3)) return 2;
 printf("preopt-test-frontier observations=%u independent-c-bit-goldens=logical-wide-masks=narrow-shifts=overflow=live-calls=fp-lanes=unaligned-page-edge-snapshots=preserved\n",observations);
 return 0;
}
