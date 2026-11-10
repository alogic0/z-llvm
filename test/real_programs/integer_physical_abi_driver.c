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
extern uint64_t integer_abi_words18(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_abi_call_words18(uint64_t,uint64_t,uint64_t,uint64_t*);
uint64_t integer_abi_external_words18(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5,uint64_t a6,uint64_t a7,uint64_t a8,uint64_t a9,uint64_t a10,uint64_t a11,uint64_t a12,uint64_t a13,uint64_t a14,uint64_t a15,uint64_t a16,uint64_t a17) { uint64_t hash=0;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 hash+=a5*UINT64_C(11);
 hash+=a6*UINT64_C(13);
 hash+=a7*UINT64_C(15);
 hash+=a8*UINT64_C(17);
 hash+=a9*UINT64_C(19);
 hash+=a10*UINT64_C(21);
 hash+=a11*UINT64_C(23);
 hash+=a12*UINT64_C(25);
 hash+=a13*UINT64_C(27);
 hash+=a14*UINT64_C(29);
 hash+=a15*UINT64_C(31);
 hash+=a16*UINT64_C(33);
 hash+=a17*UINT64_C(35);
 return hash^integer_abi_clobber(a0); }
extern uint64_t integer_abi_words32(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_abi_call_words32(uint64_t,uint64_t,uint64_t,uint64_t*);
uint64_t integer_abi_external_words32(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5,uint64_t a6,uint64_t a7,uint64_t a8,uint64_t a9,uint64_t a10,uint64_t a11,uint64_t a12,uint64_t a13,uint64_t a14,uint64_t a15,uint64_t a16,uint64_t a17,uint64_t a18,uint64_t a19,uint64_t a20,uint64_t a21,uint64_t a22,uint64_t a23,uint64_t a24,uint64_t a25,uint64_t a26,uint64_t a27,uint64_t a28,uint64_t a29,uint64_t a30,uint64_t a31) { uint64_t hash=0;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 hash+=a5*UINT64_C(11);
 hash+=a6*UINT64_C(13);
 hash+=a7*UINT64_C(15);
 hash+=a8*UINT64_C(17);
 hash+=a9*UINT64_C(19);
 hash+=a10*UINT64_C(21);
 hash+=a11*UINT64_C(23);
 hash+=a12*UINT64_C(25);
 hash+=a13*UINT64_C(27);
 hash+=a14*UINT64_C(29);
 hash+=a15*UINT64_C(31);
 hash+=a16*UINT64_C(33);
 hash+=a17*UINT64_C(35);
 hash+=a18*UINT64_C(37);
 hash+=a19*UINT64_C(39);
 hash+=a20*UINT64_C(41);
 hash+=a21*UINT64_C(43);
 hash+=a22*UINT64_C(45);
 hash+=a23*UINT64_C(47);
 hash+=a24*UINT64_C(49);
 hash+=a25*UINT64_C(51);
 hash+=a26*UINT64_C(53);
 hash+=a27*UINT64_C(55);
 hash+=a28*UINT64_C(57);
 hash+=a29*UINT64_C(59);
 hash+=a30*UINT64_C(61);
 hash+=a31*UINT64_C(63);
 return hash^integer_abi_clobber(a0); }
extern uint64_t integer_abi_entry65_5(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_abi_call65_5_value(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external65_5_value(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,65) | ~mask_bits(65); }
extern uint64_t integer_abi_call65_5_constant(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external65_5_constant(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,65) | ~mask_bits(65); }
extern uint64_t integer_abi_entry65_7(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_abi_call65_7_value(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external65_7_value(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5,uint64_t a6,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 hash+=a5*UINT64_C(11);
 hash+=a6*UINT64_C(13);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,65) | ~mask_bits(65); }
extern uint64_t integer_abi_call65_7_constant(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external65_7_constant(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5,uint64_t a6,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 hash+=a5*UINT64_C(11);
 hash+=a6*UINT64_C(13);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,65) | ~mask_bits(65); }
extern uint64_t integer_abi_entry66_5(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_abi_call66_5_value(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external66_5_value(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,66) | ~mask_bits(66); }
extern uint64_t integer_abi_call66_5_constant(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external66_5_constant(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,66) | ~mask_bits(66); }
extern uint64_t integer_abi_entry66_7(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_abi_call66_7_value(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external66_7_value(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5,uint64_t a6,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 hash+=a5*UINT64_C(11);
 hash+=a6*UINT64_C(13);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,66) | ~mask_bits(66); }
extern uint64_t integer_abi_call66_7_constant(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external66_7_constant(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5,uint64_t a6,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 hash+=a5*UINT64_C(11);
 hash+=a6*UINT64_C(13);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,66) | ~mask_bits(66); }
extern uint64_t integer_abi_entry80_5(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_abi_call80_5_value(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external80_5_value(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,80) | ~mask_bits(80); }
extern uint64_t integer_abi_call80_5_constant(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external80_5_constant(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,80) | ~mask_bits(80); }
extern uint64_t integer_abi_entry80_7(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_abi_call80_7_value(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external80_7_value(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5,uint64_t a6,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 hash+=a5*UINT64_C(11);
 hash+=a6*UINT64_C(13);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,80) | ~mask_bits(80); }
extern uint64_t integer_abi_call80_7_constant(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external80_7_constant(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5,uint64_t a6,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 hash+=a5*UINT64_C(11);
 hash+=a6*UINT64_C(13);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,80) | ~mask_bits(80); }
extern uint64_t integer_abi_entry96_5(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_abi_call96_5_value(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external96_5_value(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,96) | ~mask_bits(96); }
extern uint64_t integer_abi_call96_5_constant(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external96_5_constant(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,96) | ~mask_bits(96); }
extern uint64_t integer_abi_entry96_7(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_abi_call96_7_value(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external96_7_value(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5,uint64_t a6,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 hash+=a5*UINT64_C(11);
 hash+=a6*UINT64_C(13);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,96) | ~mask_bits(96); }
extern uint64_t integer_abi_call96_7_constant(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external96_7_constant(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5,uint64_t a6,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 hash+=a5*UINT64_C(11);
 hash+=a6*UINT64_C(13);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,96) | ~mask_bits(96); }
extern uint64_t integer_abi_entry127_5(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_abi_call127_5_value(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external127_5_value(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,127) | ~mask_bits(127); }
extern uint64_t integer_abi_call127_5_constant(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external127_5_constant(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,127) | ~mask_bits(127); }
extern uint64_t integer_abi_entry127_7(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t integer_abi_call127_7_value(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external127_7_value(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5,uint64_t a6,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 hash+=a5*UINT64_C(11);
 hash+=a6*UINT64_C(13);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,127) | ~mask_bits(127); }
extern uint64_t integer_abi_call127_7_constant(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external127_7_constant(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5,uint64_t a6,uint64_t lo,uint64_t hi,uint64_t tail) {
 u128 wide=((u128)hi<<64)|lo;
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 hash+=a5*UINT64_C(11);
 hash+=a6*UINT64_C(13);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,127) | ~mask_bits(127); }
extern uint64_t integer_abi_entry128_5(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,u128,uint64_t);
extern uint64_t integer_abi_call128_5_value(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external128_5_value(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,u128 wide,uint64_t tail) {
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,128) | ~mask_bits(128); }
extern uint64_t integer_abi_call128_5_constant(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external128_5_constant(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,u128 wide,uint64_t tail) {
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,128) | ~mask_bits(128); }
extern uint64_t integer_abi_entry128_7(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,u128,uint64_t);
extern uint64_t integer_abi_call128_7_value(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external128_7_value(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5,uint64_t a6,u128 wide,uint64_t tail) {
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 hash+=a5*UINT64_C(11);
 hash+=a6*UINT64_C(13);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,128) | ~mask_bits(128); }
extern uint64_t integer_abi_call128_7_constant(uint64_t,uint64_t,uint64_t,uint64_t*);
u128 integer_abi_external128_7_constant(uint64_t a0,uint64_t a1,uint64_t a2,uint64_t a3,uint64_t a4,uint64_t a5,uint64_t a6,u128 wide,uint64_t tail) {
 uint64_t hash=tail*19;
 hash+=a0*UINT64_C(1);
 hash+=a1*UINT64_C(3);
 hash+=a2*UINT64_C(5);
 hash+=a3*UINT64_C(7);
 hash+=a4*UINT64_C(9);
 hash+=a5*UINT64_C(11);
 hash+=a6*UINT64_C(13);
 (void)integer_abi_clobber(hash); return wide_expected(wide,hash,128) | ~mask_bits(128); }
static const struct wrapper cases[]={
 {integer_abi_call_words18,18,0,0,0},
 {integer_abi_call_words32,32,0,0,0},
 {integer_abi_call65_5_value,0,65,5,0},
 {integer_abi_call65_5_constant,0,65,5,1},
 {integer_abi_call65_7_value,0,65,7,0},
 {integer_abi_call65_7_constant,0,65,7,1},
 {integer_abi_call66_5_value,0,66,5,0},
 {integer_abi_call66_5_constant,0,66,5,1},
 {integer_abi_call66_7_value,0,66,7,0},
 {integer_abi_call66_7_constant,0,66,7,1},
 {integer_abi_call80_5_value,0,80,5,0},
 {integer_abi_call80_5_constant,0,80,5,1},
 {integer_abi_call80_7_value,0,80,7,0},
 {integer_abi_call80_7_constant,0,80,7,1},
 {integer_abi_call96_5_value,0,96,5,0},
 {integer_abi_call96_5_constant,0,96,5,1},
 {integer_abi_call96_7_value,0,96,7,0},
 {integer_abi_call96_7_constant,0,96,7,1},
 {integer_abi_call127_5_value,0,127,5,0},
 {integer_abi_call127_5_constant,0,127,5,1},
 {integer_abi_call127_7_value,0,127,7,0},
 {integer_abi_call127_7_constant,0,127,7,1},
 {integer_abi_call128_5_value,0,128,5,0},
 {integer_abi_call128_5_constant,0,128,5,1},
 {integer_abi_call128_7_value,0,128,7,0},
 {integer_abi_call128_7_constant,0,128,7,1},
};
static int check_value(uint64_t actual,uint64_t expected,const char *name) {
    if(inject_fault==1)actual^=1;
    if(actual!=expected) {
        fprintf(stderr,"integer ABI entry mismatch function=%s actual=%llx expected=%llx fault=%u\n",name,(unsigned long long)actual,(unsigned long long)expected,inject_fault);
        return 1;
    }
    ++observations;
    return 0;
}
static int check_wrapper(const struct wrapper *test,uint64_t a,uint64_t b,uint64_t salt,const uint64_t *args) {
    uint64_t box[6]={abi_key,0,0,0,0,abi_key^1},*out=box+1;
    uint64_t low,high,nested,probe=salt^abi_key;
    if(test->words) {
        low=nested=word_expected(args,test->words); high=0;
    } else {
        u128 wide=test->constant ? mask_bits(test->bits) : (((u128)b<<64)|a)&mask_bits(test->bits);
        uint64_t hash=weighted(args,test->prefix)+salt*19;
        u128 result=wide_expected(wide,hash,test->bits);
        low=(uint64_t)result; high=(uint64_t)(result>>64);
        nested=entry_expected(args,test->prefix,result,salt,test->bits);
    }
    uint64_t expected=low^high^nested^probe^a^b^salt;
    uint64_t actual=test->run(a,b,salt,out);
    if(inject_fault==1)actual^=1;
    if(inject_fault>=2&&inject_fault<=5)out[inject_fault-2]^=1;
    if(inject_fault==6)box[0]^=1;
    if(inject_fault==7)box[5]^=1;
    if(actual!=expected||out[0]!=low||out[1]!=high||out[2]!=nested||out[3]!=probe||box[0]!=abi_key||box[5]!=(abi_key^1)) {
        fprintf(stderr,"integer ABI call mismatch words=%u bits=%u prefix=%u constant=%u a=%llx b=%llx salt=%llx actual=%llx expected=%llx fields=%llx,%llx,%llx,%llx expected_fields=%llx,%llx,%llx,%llx fault=%u\n",test->words,test->bits,test->prefix,test->constant,(unsigned long long)a,(unsigned long long)b,(unsigned long long)salt,(unsigned long long)actual,(unsigned long long)expected,(unsigned long long)out[0],(unsigned long long)out[1],(unsigned long long)out[2],(unsigned long long)out[3],(unsigned long long)low,(unsigned long long)high,(unsigned long long)nested,(unsigned long long)probe,inject_fault);
        return 1;
    }
    ++observations;
    return 0;
}
int main(int argc,char **argv) {
 if(argc==2)inject_fault=(unsigned)strtoul(argv[1],0,10);
 if(argc>2||inject_fault>7)return 2;
 const uint64_t values[]={0,1,2,0x7fffffff,0x80000000,0x8000000000000000ULL,UINT64_MAX-1,UINT64_MAX};
 for(unsigned i=0;i<8;i++)for(unsigned j=0;j<8;j++)for(unsigned k=0;k<8;k++){
 uint64_t a=values[i],b=values[j],salt=values[k],high=b^salt,tail=a+salt,args[32];
 for(unsigned n=0;n<32;n++)args[n]=(a+(n+1)*abi_key)^b^salt;
 if(check_value(integer_abi_words18(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13],args[14],args[15],args[16],args[17]),word_expected(args,18),"integer_abi_words18"))return 1;
 if(check_value(integer_abi_words32(args[0],args[1],args[2],args[3],args[4],args[5],args[6],args[7],args[8],args[9],args[10],args[11],args[12],args[13],args[14],args[15],args[16],args[17],args[18],args[19],args[20],args[21],args[22],args[23],args[24],args[25],args[26],args[27],args[28],args[29],args[30],args[31]),word_expected(args,32),"integer_abi_words32"))return 1;
 if(check_value(integer_abi_entry65_5(args[0],args[1],args[2],args[3],args[4],a,high,tail),entry_expected(args,5,((u128)high<<64)|a,tail,65),"integer_abi_entry65_5"))return 1;
 if(check_value(integer_abi_entry65_7(args[0],args[1],args[2],args[3],args[4],args[5],args[6],a,high,tail),entry_expected(args,7,((u128)high<<64)|a,tail,65),"integer_abi_entry65_7"))return 1;
 if(check_value(integer_abi_entry66_5(args[0],args[1],args[2],args[3],args[4],a,high,tail),entry_expected(args,5,((u128)high<<64)|a,tail,66),"integer_abi_entry66_5"))return 1;
 if(check_value(integer_abi_entry66_7(args[0],args[1],args[2],args[3],args[4],args[5],args[6],a,high,tail),entry_expected(args,7,((u128)high<<64)|a,tail,66),"integer_abi_entry66_7"))return 1;
 if(check_value(integer_abi_entry80_5(args[0],args[1],args[2],args[3],args[4],a,high,tail),entry_expected(args,5,((u128)high<<64)|a,tail,80),"integer_abi_entry80_5"))return 1;
 if(check_value(integer_abi_entry80_7(args[0],args[1],args[2],args[3],args[4],args[5],args[6],a,high,tail),entry_expected(args,7,((u128)high<<64)|a,tail,80),"integer_abi_entry80_7"))return 1;
 if(check_value(integer_abi_entry96_5(args[0],args[1],args[2],args[3],args[4],a,high,tail),entry_expected(args,5,((u128)high<<64)|a,tail,96),"integer_abi_entry96_5"))return 1;
 if(check_value(integer_abi_entry96_7(args[0],args[1],args[2],args[3],args[4],args[5],args[6],a,high,tail),entry_expected(args,7,((u128)high<<64)|a,tail,96),"integer_abi_entry96_7"))return 1;
 if(check_value(integer_abi_entry127_5(args[0],args[1],args[2],args[3],args[4],a,high,tail),entry_expected(args,5,((u128)high<<64)|a,tail,127),"integer_abi_entry127_5"))return 1;
 if(check_value(integer_abi_entry127_7(args[0],args[1],args[2],args[3],args[4],args[5],args[6],a,high,tail),entry_expected(args,7,((u128)high<<64)|a,tail,127),"integer_abi_entry127_7"))return 1;
 if(check_value(integer_abi_entry128_5(args[0],args[1],args[2],args[3],args[4],((u128)high<<64)|a,tail),entry_expected(args,5,((u128)high<<64)|a,tail,128),"integer_abi_entry128_5"))return 1;
 if(check_value(integer_abi_entry128_7(args[0],args[1],args[2],args[3],args[4],args[5],args[6],((u128)high<<64)|a,tail),entry_expected(args,7,((u128)high<<64)|a,tail,128),"integer_abi_entry128_7"))return 1;
 for(unsigned n=0;n<sizeof(cases)/sizeof(cases[0]);n++)if(check_wrapper(cases+n,a,b,salt,args))return 1;
 }
 printf("integer-physical-abi observations=%u scalar=split=aligned=wide=nested=clobbers=guards=preserved\n",observations);
 return observations!=20480;
}
