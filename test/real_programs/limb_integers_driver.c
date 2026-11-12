#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
extern uint64_t call_in140(unsigned char *,const uint64_t *,const uint64_t *,uint64_t);
extern uint64_t call_in495(unsigned char *,const uint64_t *,uint64_t);
extern uint64_t call_in200(unsigned char *,const uint64_t *,const uint64_t *,uint64_t);
extern uintptr_t call_ret256(unsigned char *,const uint64_t *,uint64_t);
extern uintptr_t call_ret256_default(unsigned char *,const uint64_t *,uint64_t);
extern uint64_t wide_outbound(unsigned char *,const unsigned char *,const unsigned char *,uint64_t);
__asm__(
".text\n.globl call_in140\n.type call_in140,@function\ncall_in140:\n"
" push %rbx\n mov %rcx,%rbx\n mov %rsi,%rax\n mov %rdx,%r10\n"
" mov 0(%rax),%rsi\n mov 8(%rax),%rdx\n mov 16(%rax),%rcx\n"
" mov 0(%r10),%r8\n mov 8(%r10),%r9\n sub $16,%rsp\n mov %rbx,0(%rsp)\n"
" call wide_in140\n add $16,%rsp\n pop %rbx\n ret\n.size call_in140,.-call_in140\n"
".globl call_in200\n.type call_in200,@function\ncall_in200:\n"
" mov %rsi,%rax\n mov %rdx,%r10\n mov %rcx,%r9\n sub $24,%rsp\n"
" mov 0(%r10),%r11\n mov %r11,0(%rsp)\n mov 8(%r10),%r11\n mov %r11,8(%rsp)\n"
" mov 0(%rax),%rsi\n mov 8(%rax),%rdx\n mov 16(%rax),%rcx\n mov 24(%rax),%r8\n"
" call wide_in200\n add $24,%rsp\n ret\n.size call_in200,.-call_in200\n"
".globl call_in495\n.type call_in495,@function\ncall_in495:\n"
" mov %rsi,%rax\n mov %rdx,%r11\n sub $40,%rsp\n"
" mov 40(%rax),%r10\n mov %r10,0(%rsp)\n mov 48(%rax),%r10\n mov %r10,8(%rsp)\n"
" mov 56(%rax),%r10\n mov %r10,16(%rsp)\n mov %r11,24(%rsp)\n"
" mov 0(%rax),%rsi\n mov 8(%rax),%rdx\n mov 16(%rax),%rcx\n mov 24(%rax),%r8\n mov 32(%rax),%r9\n"
" call wide_in495\n add $40,%rsp\n ret\n.size call_in495,.-call_in495\n"
".globl call_ret256\n.type call_ret256,@function\ncall_ret256:\n"
" mov %rsi,%rax\n mov %rdx,%r9\n mov 0(%rax),%rsi\n mov 8(%rax),%rdx\n mov 16(%rax),%rcx\n mov 24(%rax),%r8\n"
" sub $8,%rsp\n call wide_ret256\n add $8,%rsp\n ret\n.size call_ret256,.-call_ret256\n"
".globl call_ret256_default\n.type call_ret256_default,@function\ncall_ret256_default:\n"
" mov %rsi,%rax\n mov %rdx,%r9\n mov 0(%rax),%rsi\n mov 8(%rax),%rdx\n mov 16(%rax),%rcx\n mov 24(%rax),%r8\n"
" sub $8,%rsp\n call wide_ret256_default\n add $8,%rsp\n ret\n.size call_ret256_default,.-call_ret256_default\n"
".globl oracle256\n.type oracle256,@function\noracle256:\n"
" mov %rsi,%rax\n xor %r8,%rax\n xor 56(%rsp),%rax\n mov %rax,0(%rdi)\n"
" mov %rdx,%rax\n add %r9,%rax\n mov %rax,8(%rdi)\n"
" mov %rcx,%rax\n and $4095,%rax\n xor 8(%rsp),%rax\n movabs $0x7fffffffffff,%r10\n and 48(%rsp),%r10\n xor %r10,%rax\n mov %rax,16(%rdi)\n"
" mov 16(%rsp),%rax\n add 24(%rsp),%rax\n add 32(%rsp),%rax\n add 40(%rsp),%rax\n mov %rax,24(%rdi)\n"
" mov %rdi,%rax\n ret\n.size oracle256,.-oracle256\n"
".section .note.GNU-stack,\"\",@progbits\n");
static size_t observations;
static unsigned fault;
#define CHECK(c) do { ++observations; if(!(c)) { fprintf(stderr,"limb-integers fault=%u observation=%zu\n",fault,observations); exit(1); } } while(0)
struct guarded { uint64_t pre[2]; unsigned char bytes[80]; uint64_t post[2]; };
static void verify(const struct guarded *g,const unsigned char *expected) {
 CHECK(g->pre[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&g->pre[1]==g->pre[0]);
 CHECK(g->post[0]==UINT64_C(0xa5a5a5a5a5a5a5a5)&&g->post[1]==g->post[0]);
 for(unsigned i=0;i<80;i++) CHECK(g->bytes[i]==expected[i]);
}
int main(int argc,char **argv) {
 fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10) : 0;
 const size_t page=(size_t)sysconf(_SC_PAGESIZE);
 unsigned char *ma=mmap(NULL,page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
 unsigned char *mb=mmap(NULL,page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
 if(ma==MAP_FAILED || mb==MAP_FAILED || mprotect(ma+page,page,PROT_NONE)!=0 || mprotect(mb+page,page,PROT_NONE)!=0) return 1;
 unsigned char *pa=ma+page-18,*pb=mb+page-62;
 for(unsigned seed=0;seed<32;seed++) {
  uint64_t a[4],b[8],pair[2];
  for(unsigned i=0;i<4;i++) a[i]=seed==0 ? 0 : seed==1 ? UINT64_MAX : (seed*UINT64_C(0x9e3779b97f4a7c15))^(i*UINT64_C(0xd6e8feb86659fd93));
  for(unsigned i=0;i<8;i++) b[i]=seed==0 ? 0 : seed==1 ? UINT64_MAX : (seed*UINT64_C(0xa0761d6478bd642f))^(i*UINT64_C(0x94d049bb133111eb));
  pair[0]=b[2];pair[1]=b[3];
  const uint64_t salt=seed*UINT64_C(0xe7037ed1a0b428db),shift=salt&511;
  _Alignas(16) struct guarded g;
  unsigned char expected[80];
  memset(&g,0xa5,sizeof g);memset(expected,0xa5,sizeof expected);
  memcpy(expected,a,18); expected[17]&=15;memcpy(expected+32,pair,16);
  uint64_t got=call_in140(g.bytes,a,pair,salt);
  if(fault==1) got^=1;
  if(fault==2) g.pre[0]^=1;
  if(fault==3) g.post[1]^=1;
  CHECK(got==(a[0]^pair[0]^salt));verify(&g,expected);
  memset(&g,0xa5,sizeof g);memset(expected,0xa5,sizeof expected);
  memcpy(expected,a,25);memcpy(expected+32,pair,16);
  CHECK(call_in200(g.bytes,a,pair,salt)==(a[0]^pair[0]^salt));verify(&g,expected);
  memset(&g,0xa5,sizeof g);memset(expected,0xa5,sizeof expected);
  memcpy(expected,b,62);expected[61]&=127;memcpy(expected+64,&shift,2);
  CHECK(call_in495(g.bytes,b,shift)==(b[0]^shift));verify(&g,expected);
  memset(&g,0xa5,sizeof g);memset(expected,0xa5,sizeof expected);
  uint64_t returned[4]={a[0]^salt,a[1],a[2],a[3]};memcpy(expected,returned,32);
  CHECK(call_ret256(g.bytes,a,salt)==(uintptr_t)g.bytes);verify(&g,expected);
  memset(&g,0xa5,sizeof g);
  CHECK(call_ret256_default(g.bytes,a,salt)==(uintptr_t)g.bytes);verify(&g,expected);
  memcpy(pa,a,18);memcpy(pb,b,62);
  memset(&g,0xa5,sizeof g);memset(expected,0xa5,sizeof expected);
  const uint64_t result[4]={a[0]^b[0]^salt,a[1]+b[1],(a[2]&4095)^b[2]^(b[7]&UINT64_C(0x7fffffffffff)),b[3]+b[4]+b[5]+b[6]};
  memcpy(expected,result,32);
  CHECK(wide_outbound(g.bytes,pa,pb,salt)==result[0]);verify(&g,expected);
 }
 munmap(ma,page*2);munmap(mb,page*2);
 printf("limb-integers observations=%zu abi=split-words=hidden-return=rax=guard-pages=preserved\n",observations);
 return 0;
}
