/* Included by the deterministic Zig fixture generator. */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
typedef unsigned __int128 u128;
typedef uint64_t (*operation)(uint64_t,uint64_t,uint64_t,uint64_t*);
struct wrapper { operation run; unsigned words,bits,prefix,constant; };
static const uint64_t abi_key=UINT64_C(0x9e3779b97f4a7c15);
static unsigned observations,inject_fault;
__attribute__((noinline)) uint64_t integer_abi_clobber(uint64_t value) {
    uint64_t result=value^abi_key;
    __asm__ volatile(
        "movabs $0x1111111133333333, %%rcx\n\t"
        "movabs $0x2222222244444444, %%rdx\n\t"
        "movabs $0x3333333355555555, %%rdi\n\t"
        "movabs $0x4444444466666666, %%rsi\n\t"
        "movabs $0x5555555577777777, %%r8\n\t"
        "movabs $0x6666666688888888, %%r9\n\t"
        "movabs $0x7777777799999999, %%r10\n\t"
        "movabs $0x88888888aaaaaaaa, %%r11\n\t"
        : "+a"(result) : : "rdi","rsi","rdx","rcx","r8","r9","r10","r11","memory","cc");
    return result;
}
static u128 mask_bits(unsigned bits) { return bits==128 ? ~(u128)0 : ((u128)1<<bits)-1; }
static u128 wide_expected(u128 wide,uint64_t hash,unsigned bits) {
    return (wide^(((u128)hash<<64)|(hash^abi_key)))&mask_bits(bits);
}
static uint64_t weighted(const uint64_t *args,unsigned count) {
    uint64_t result=0;
    for(unsigned i=0;i<count;i++)result+=args[i]*(2*i+1);
    return result;
}
static uint64_t word_expected(const uint64_t *args,unsigned count) {
    return weighted(args,count)^(args[0]^abi_key);
}
static uint64_t entry_expected(const uint64_t *args,unsigned count,u128 wide,uint64_t tail,unsigned bits) {
    wide&=mask_bits(bits);
    return (weighted(args,count)+(uint64_t)wide*3+(uint64_t)(wide>>64)*5+tail*19)^(args[0]^abi_key);
}
