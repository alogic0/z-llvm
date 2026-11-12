#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t v128 __attribute__((vector_size(16)));
typedef v128 (*body_fn)(v128,v128);
typedef uint64_t (*probe_fn)(void *,const void *,const void *,uint64_t);
struct abi_case{unsigned n,bits;probe_fn probe;body_fn body;};
static __attribute__((noinline)) v128 raw_model(v128 x,v128 y,unsigned n,unsigned bits){
 unsigned char a[16],b[16],out[16]={0};memcpy(a,&x,16);memcpy(b,&y,16);
 for(unsigned i=0;i<n;i++)memcpy(out+i*bits/8,(i%2?a:b)+(n-1-i)*bits/8,bits/8);
 v128 result;memcpy(&result,out,16);return result;
}
static size_t observations;
static void check(int pass,unsigned slot,unsigned seed,unsigned fault){observations++;if(!pass){fprintf(stderr,"small-fp-vector-abi slot=%u seed=%u observation=%zu fault=%u\n",slot,seed,observations,fault);exit(1);}}
static uint64_t payload(unsigned bits,unsigned index){
 static const uint64_t half[]={0,0x8000,1,0x7c00,0xfc00,0x7c01,0x7e55,0xfea1,0x3555,0x8001};
 static const uint64_t single[]={0,0x80000000,1,0x7f800000,0xff800000,0x7f800001,0x7fc01234,0xffc05678,0x3eaaaaab,0x80000001};
 static const uint64_t dbl[]={0,UINT64_C(0x8000000000000000),1,UINT64_C(0x7ff0000000000000),UINT64_C(0xfff0000000000000),UINT64_C(0x7ff0000000000001),UINT64_C(0x7ff8000000001234),UINT64_C(0xfff8000000005678),UINT64_C(0x3fd5555555555555),UINT64_C(0x8000000000000001)};
 return (bits==16?half:bits==32?single:dbl)[index%10];
}
static int run_all(const struct abi_case *cases,size_t count,int argc,char **argv){
 unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;if(fault>3)return 2;
 size_t page=(size_t)sysconf(_SC_PAGESIZE);unsigned char *map=mmap(0,page*4,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
 if(map==MAP_FAILED||mprotect(map+page,page,PROT_NONE)||mprotect(map+3*page,page,PROT_NONE))return 2;
 for(unsigned slot=0;slot<count;slot++){unsigned n=cases[slot].n,bits=cases[slot].bits,bytes=n*bits/8;for(unsigned seed=0;seed<64;seed++){
  unsigned char *ap=map+page-bytes,*bp=map+3*page-bytes,sa[16],sb[16],ax[16],bx[16];
  memset(ax,0xa5,16);memset(bx,0x5a,16);
  for(unsigned i=0;i<n;i++){uint64_t a=payload(bits,seed+i),b=payload(bits,seed*3+i+4);if(seed>=32){a^=seed*UINT64_C(0x8123456789abcdef);b^=seed*UINT64_C(0xf06dea67e461de5b);}memcpy(ap+i*bits/8,&a,bits/8);memcpy(bp+i*bits/8,&b,bits/8);}
  memcpy(sa,ap,bytes);memcpy(sb,bp,bytes);memcpy(ax,ap,bytes);memcpy(bx,bp,bytes);
  v128 x,y;memcpy(&x,ax,16);memcpy(&y,bx,16);v128 expected=raw_model(x,y,n,bits),actual=cases[slot].body(x,y);
  check(memcmp(&actual,&expected,bytes)==0,slot,seed,fault);
  struct{unsigned char pre[9],data[32],post[9];}out;memset(&out,0xa5,sizeof out);
  uint64_t salt=(seed+slot*37)*UINT64_C(0xf06dea67e461de5b);uint64_t returned=cases[slot].probe(out.data,ap,bp,salt);
  if(fault==1)returned^=1;if(fault==2)out.data[0]^=1;if(fault==3)out.post[0]^=1;
  check(returned==(salt^90),slot,seed,fault);check(memcmp(out.data,&expected,bytes)==0,slot,seed,fault);check(memcmp(out.data+16,&expected,bytes)==0,slot,seed,fault);
  int pre=1,post=1,gap0=1,gap1=1;for(unsigned i=0;i<9;i++){pre&=out.pre[i]==0xa5;post&=out.post[i]==0xa5;}for(unsigned i=bytes;i<16;i++){gap0&=out.data[i]==0xa5;gap1&=out.data[i+16]==0xa5;}
  check(pre,slot,seed,fault);check(post,slot,seed,fault);check(gap0,slot,seed,fault);check(gap1,slot,seed,fault);check(memcmp(ap,sa,bytes)==0,slot,seed,fault);check(memcmp(bp,sb,bytes)==0,slot,seed,fault);
 }}
 if(munmap(map,page*4)||count!=16||observations!=10240)return 2;
 printf("small-fp-vector-abi observations=%zu llvm-c-local-interop=ccc-fastcc=raw-payloads=exact-stores=guard-pages=preserved\n",observations);return 0;
}
