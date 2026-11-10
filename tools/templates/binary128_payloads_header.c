/* Generated binary128 C oracle: raw transport and independent C numerical operations. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef __float128 quad;
typedef unsigned __int128 u128;
static unsigned observations, inject_fault;
static const uint64_t key=UINT64_C(0x9e3779b97f4a7c15);
static u128 bits(quad x) { u128 u; memcpy(&u,&x,16); return u; }
static quad payload(u128 u) { quad x; memcpy(&x,&u,16); return x; }
static u128 words(uint64_t lo,uint64_t hi) { return (u128)hi<<64|lo; }
static uint64_t rotate(uint64_t x,unsigned n) { return x<<n|x>>(64-n); }
__attribute__((noinline)) uint64_t binary128_clobber(uint64_t seed) {
 __asm__ volatile(
  "movabs $0x1122334455667788,%%rax\n\t"
  "movabs $0x8877665544332211,%%rcx\n\t"
  "movabs $0x9988776655443322,%%rdx\n\t"
  "movabs $0xaabbccddeeff0011,%%rdi\n\t"
  "movabs $0xbbaa998877665544,%%rsi\n\t"
  "movabs $0xccddeeff00112233,%%r8\n\t"
  "movabs $0xddccbbaa99887766,%%r9\n\t"
  "movabs $0xeeff001122334455,%%r10\n\t"
  "movabs $0xffeeddccbbaa9988,%%r11\n\t"
  "pxor %%xmm0,%%xmm0\n\tpxor %%xmm1,%%xmm1\n\t"
  "pxor %%xmm2,%%xmm2\n\tpxor %%xmm3,%%xmm3\n\t"
  "pxor %%xmm4,%%xmm4\n\tpxor %%xmm5,%%xmm5\n\t"
  "pxor %%xmm6,%%xmm6\n\tpxor %%xmm7,%%xmm7\n\t"
  "pxor %%xmm8,%%xmm8\n\tpxor %%xmm9,%%xmm9\n\t"
  "pxor %%xmm10,%%xmm10\n\tpxor %%xmm11,%%xmm11\n\t"
  "pxor %%xmm12,%%xmm12\n\tpxor %%xmm13,%%xmm13\n\t"
  "pxor %%xmm14,%%xmm14\n\tpxor %%xmm15,%%xmm15"
  :::"rax","rcx","rdx","rdi","rsi","r8","r9","r10","r11",
  "xmm0","xmm1","xmm2","xmm3","xmm4","xmm5","xmm6","xmm7",
  "xmm8","xmm9","xmm10","xmm11","xmm12","xmm13","xmm14","xmm15","cc","memory");
 return seed^key;
}
static u128 helper_expected(u128 x,u128 y,uint64_t seed) {
 return words(rotate((uint64_t)x,13)^(uint64_t)(y>>64)^seed,
  rotate((uint64_t)y,29)+(uint64_t)(x>>64)+key);
}
__attribute__((noinline)) quad binary128_helper(quad x,quad y,uint64_t seed) {
 u128 result=helper_expected(bits(x),bits(y),seed);
 (void)binary128_clobber(seed+1);
 return payload(result);
}
extern quad binary128_identity(quad);
extern u128 binary128_bits(quad);
extern quad binary128_from_bits(u128);
extern quad binary128_load_index(const quad*,uint64_t);
extern quad binary128_transport(quad,quad,uint64_t,uint64_t*);
extern quad binary128_call_constant(quad,uint64_t,uint64_t*);
extern quad binary128_eight(quad,quad,quad,quad,quad,quad,quad,quad,uint64_t);
static int check_bits(const char *name,u128 actual,u128 expected) {
 if(actual!=expected) { fprintf(stderr,"binary128 %s actual=%016llx:%016llx expected=%016llx:%016llx fault=%u\n",
 name,(unsigned long long)(actual>>64),(unsigned long long)actual,
 (unsigned long long)(expected>>64),(unsigned long long)expected,inject_fault); return 1; }
 observations++; return 0;
}
static int check_quad(const char *name,quad actual,quad expected) { return check_bits(name,bits(actual),bits(expected)); }
