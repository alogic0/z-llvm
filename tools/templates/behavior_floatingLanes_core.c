#define _GNU_SOURCE
#define __STDC_WANT_IEC_60559_TYPES_EXT__ 1
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(void *,const void *,const void *,const void *,uint64_t);
#define DECL(B,N,O) extern uint64_t floating_lane_##B##_##N##_##O(void *,const void *,const void *,const void *,uint64_t)
#define OPS(B,N) DECL(B,N,trunc);DECL(B,N,round);DECL(B,N,ceil);DECL(B,N,floor);DECL(B,N,log10);DECL(B,N,log2);DECL(B,N,log);DECL(B,N,exp2);DECL(B,N,exp);DECL(B,N,tan);DECL(B,N,cos);DECL(B,N,sin);DECL(B,N,sqrt);DECL(B,N,fma)
#define LENGTHS(B) OPS(B,1);OPS(B,2);OPS(B,3);OPS(B,4)
LENGTHS(16);LENGTHS(32);LENGTHS(64);LENGTHS(80);LENGTHS(128);
#define ROW(B,N) {floating_lane_##B##_##N##_trunc,floating_lane_##B##_##N##_round,floating_lane_##B##_##N##_ceil,floating_lane_##B##_##N##_floor,floating_lane_##B##_##N##_log10,floating_lane_##B##_##N##_log2,floating_lane_##B##_##N##_log,floating_lane_##B##_##N##_exp2,floating_lane_##B##_##N##_exp,floating_lane_##B##_##N##_tan,floating_lane_##B##_##N##_cos,floating_lane_##B##_##N##_sin,floating_lane_##B##_##N##_sqrt,floating_lane_##B##_##N##_fma}
#define TABLE(B) {ROW(B,1),ROW(B,2),ROW(B,3),ROW(B,4)}
#define ORACLE(B,F,S) static __attribute__((noinline)) F expected_##B(unsigned op,F a,F b,F c){switch(op){case 0:return trunc##S(a);case 1:return round##S(a);case 2:return ceil##S(a);case 3:return floor##S(a);case 4:return log10##S(a);case 5:return log2##S(a);case 6:return log##S(a);case 7:return exp2##S(a);case 8:return exp##S(a);case 9:return tan##S(a);case 10:return cos##S(a);case 11:return sin##S(a);case 12:return sqrt##S(a);case 13:return fma##S(a,b,c);default:abort();}}
ORACLE(32,float,f) ORACLE(64,double,) ORACLE(80,long double,l) ORACLE(128,_Float128,f128)
static __attribute__((noinline)) _Float16 expected_16(unsigned op,_Float16 a,_Float16 b,_Float16 c){return op==13?(_Float16)fma((double)a,(double)b,(double)c):(_Float16)expected_32(op,(float)a,(float)b,(float)c);}
static uint64_t observations;
static void check(int pass,unsigned bits,unsigned n,unsigned op,unsigned sample,unsigned fault){observations++;if(!pass){fprintf(stderr,"floating-lanes bits=%u n=%u op=%u sample=%u observation=%llu fault=%u\n",bits,n,op,sample,(unsigned long long)observations,fault);exit(1);}}
#define RUN(B,F) \
static void run_##B(unsigned char *map,size_t page,unsigned fault){const kernel functions[4][14]=TABLE(B);const unsigned bytes=B/8; \
 for(unsigned n=1;n<=4;n++)for(unsigned op=0;op<14;op++)for(unsigned sample=0;sample<32;sample++){ \
 F a[4],b[4],c[4],wanted[4];for(unsigned i=0;i<n;i++){ \
  a[i]=(F)((int)((sample*7+i*11)%63)-31)/(F)8;b[i]=(F)((int)((sample*13+i*7)%31)-15)/(F)4;c[i]=(F)((int)((sample*3+i*5)%17)-8)/(F)16; \
  if(sample==0)a[i]=(F)0.0;if(sample==1)a[i]=(F)-0.0;if(sample==2)a[i]=(F)__builtin_infl();if(sample==3)a[i]=(F)-__builtin_infl();if(sample==4)a[i]=(F)__builtin_nanl(""); \
  if(sample==5)a[i]=(F)0x1p-24L;if(sample==6)a[i]=(F)-0x1p-24L;if(sample==7){a[i]=(F)-1.5;b[i]=(F)2;c[i]=(F)3;} \
  if(sample==8){a[i]=(F)1.5;b[i]=(F)1.5;c[i]=(F)-2.25;} \
  if(sample==9){long double delta=B==16?0x1p-6L:B==32?0x1p-12L:B==64?0x1p-27L:B==80?0x1p-32L:0x1p-57L;a[i]=(F)(1.0L+delta);b[i]=a[i];c[i]=(F)-1;} \
  wanted[i]=expected_##B(op,a[i],b[i],c[i]); \
 } \
 unsigned char *ap=map+page-n*bytes,*bp=map+3*page-n*bytes,*cp=map+5*page-n*bytes; \
 for(unsigned i=0;i<n;i++){memcpy(ap+i*bytes,&a[i],bytes);memcpy(bp+i*bytes,&b[i],bytes);memcpy(cp+i*bytes,&c[i],bytes);} \
 unsigned char sa[64],sb[64],sc[64];memcpy(sa,ap,n*bytes);memcpy(sb,bp,n*bytes);memcpy(sc,cp,n*bytes); \
 struct{unsigned char pre[9],data[64],post[9];}out;memset(&out,0xa5,sizeof out);uint64_t salt=(sample+n*131+op*17)*UINT64_C(0x9e3779b97f4a7c15);uint64_t result=functions[n-1][op](out.data,ap,bp,cp,salt); \
 if(fault==1)result^=1;if(fault==2)memset(out.data,0xff,n*bytes);if(fault==3)out.post[0]^=1; \
 int equal=1;for(unsigned i=0;i<n;i++){F actual=(F)0;memcpy(&actual,out.data+i*bytes,bytes);if(__builtin_isnan(wanted[i]))equal&=__builtin_isnan(actual);else equal&=actual==wanted[i]&&(wanted[i]!=(F)0||__builtin_signbit(actual)==__builtin_signbit(wanted[i]));} \
 int pre=1,post=1,tail=1;for(unsigned i=0;i<9;i++){pre&=out.pre[i]==0xa5;post&=out.post[i]==0xa5;}for(unsigned i=n*bytes;i<64;i++)tail&=out.data[i]==0xa5; \
 check(result==(salt^90),B,n,op,sample,fault);check(equal,B,n,op,sample,fault);check(pre,B,n,op,sample,fault);check(tail,B,n,op,sample,fault);check(post,B,n,op,sample,fault);check(memcmp(ap,sa,n*bytes)==0,B,n,op,sample,fault);check(memcmp(bp,sb,n*bytes)==0,B,n,op,sample,fault);check(memcmp(cp,sc,n*bytes)==0,B,n,op,sample,fault); \
 }}
RUN(16,_Float16) RUN(32,float) RUN(64,double) RUN(80,long double) RUN(128,_Float128)
int main(int argc,char **argv){unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;if(fault>3)return 2;size_t page=(size_t)sysconf(_SC_PAGESIZE);unsigned char *map=mmap(0,page*6,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(map==MAP_FAILED||mprotect(map+page,page,PROT_NONE)||mprotect(map+3*page,page,PROT_NONE)||mprotect(map+5*page,page,PROT_NONE))return 2;run_16(map,page,fault);run_32(map,page,fault);run_64(map,page,fault);run_80(map,page,fault);run_128(map,page,fault);if(munmap(map,page*6)||observations!=71680)return 2;printf("floating-lanes observations=%llu all-five-formats=unary-math=fused-multiply-add=exact-tails=live-values=guard-pages=preserved\n",(unsigned long long)observations);return 0;}
