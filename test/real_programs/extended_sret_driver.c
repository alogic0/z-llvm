#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
typedef struct { long double a,b; } Pair80;
typedef struct { __float128 a; uint64_t tag; } Pair128;
extern Pair80 sret_pair80(long double);
extern Pair128 sret_pair128(__float128);
extern Pair80 sret_call80(long double);
extern Pair128 sret_call128(__float128);
extern long double sret_sign80(long double,long double);
extern __float128 sret_sign128(__float128,__float128);
extern void *probe_sret80(Pair80 *,const long double *);
extern void *probe_sret128(Pair128 *,const __float128 *);
Pair80 external_pair80(long double x) { return (Pair80){x,-x}; }
Pair128 external_pair128(__float128 x) { return (Pair128){x,UINT64_C(0x123456789abcdef0)}; }
__asm__(".text\n.globl probe_sret80\n.type probe_sret80,@function\n"
 "probe_sret80:\n subq $24,%rsp\n movdqu (%rsi),%xmm0\n movdqu %xmm0,(%rsp)\n"
 " call sret_pair80\n addq $24,%rsp\n ret\n.size probe_sret80,.-probe_sret80\n"
 ".globl probe_sret128\n.type probe_sret128,@function\n"
 "probe_sret128:\n subq $8,%rsp\n movdqu (%rsi),%xmm0\n call sret_pair128\n"
 " addq $8,%rsp\n ret\n.size probe_sret128,.-probe_sret128\n");
static int same80(long double x,long double y) { return memcmp(&x,&y,10)==0; }
static unsigned __int128 bits128(__float128 x) { unsigned __int128 b; memcpy(&b,&x,16); return b; }
static __float128 value128(unsigned __int128 b) { __float128 x; memcpy(&x,&b,16); return x; }
int main(int argc,char **argv) {
 unsigned fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10) : 0;
 size_t observations=0;
#define CHECK(c) do { ++observations; if(!(c)) { fprintf(stderr,"extended-sret fault=%u observation=%zu\n",fault,observations); return 1; } } while(0)
 for(unsigned seed=0;seed<32;seed++) {
  long double x=((long double)(int)seed-16.0L)/8.0L;
  long double sign=seed&1 ? -1.0L : 1.0L;
  unsigned __int128 qb=((unsigned __int128)(0x3ff0+seed)<<112) | ((unsigned __int128)UINT64_C(0xfedcba9876543210)<<32) | seed;
  if(seed&2) qb|=(unsigned __int128)1<<127;
  if(seed==28) qb=0;
  if(seed==29) qb=(unsigned __int128)1<<127;
  if(seed==30) qb=((unsigned __int128)0x7fff<<112);
  if(seed==31) qb=((unsigned __int128)0x7fff<<112)|((unsigned __int128)1<<111)|UINT64_C(0x123456789);
  __float128 q=value128(qb), qs=value128((unsigned __int128)(seed&1)<<127);
  struct { uint64_t pre[2]; Pair80 value; uint64_t post[2]; } a;
  struct { uint64_t pre[2]; Pair128 value; uint64_t post[2]; } b;
  memset(&a,0x5a,sizeof(a)); memset(&b,0x5a,sizeof(b));
  a.value=sret_pair80(x);
  if(fault==1) ((unsigned char *)&a.value.a)[0]^=1;
  CHECK(same80(a.value.a,x)); CHECK(same80(a.value.b,-x));
  b.value=sret_pair128(q);
  CHECK(bits128(b.value.a)==qb); CHECK(b.value.tag==UINT64_C(0x123456789abcdef0));
  a.value=sret_call80(x);
  CHECK(same80(a.value.a,x)); CHECK(same80(a.value.b,-x));
  b.value=sret_call128(q);
  CHECK(bits128(b.value.a)==qb); CHECK(b.value.tag==UINT64_C(0x123456789abcdef0));
  CHECK(probe_sret80(&a.value,&x)==&a.value);
  CHECK(probe_sret128(&b.value,&q)==&b.value);
  long double expected=x<0 ? -x : x;
  if(seed==16) expected=0.0L;
  if(seed&1) expected=-expected;
  CHECK(same80(sret_sign80(x,sign),expected));
  const unsigned __int128 signbit=(unsigned __int128)1<<127;
  CHECK(bits128(sret_sign128(q,qs))==((qb&~signbit)|((unsigned __int128)(seed&1)<<127)));
  if(fault==2) a.pre[0]^=1;
  if(fault==3) b.post[1]^=1;
  CHECK(a.pre[0]==UINT64_C(0x5a5a5a5a5a5a5a5a)&&a.pre[1]==a.pre[0]);
  CHECK(a.post[0]==UINT64_C(0x5a5a5a5a5a5a5a5a)&&a.post[1]==a.post[0]);
  CHECK(b.pre[0]==UINT64_C(0x5a5a5a5a5a5a5a5a)&&b.pre[1]==b.pre[0]);
  CHECK(b.post[0]==UINT64_C(0x5a5a5a5a5a5a5a5a)&&b.post[1]==b.post[0]);
 }
 printf("extended-sret observations=%zu natural-c=rax=payloads=guards=preserved\n",observations);
 return 0;
}
