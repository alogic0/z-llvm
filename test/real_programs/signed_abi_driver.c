#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
typedef uint64_t (*kernel)(const void *,void *,uint64_t);
extern uint32_t signed_physical_observer(const void *,const uint64_t *);
__asm__(".text\n.type signed_physical_observer,@function\nsigned_physical_observer:\n"
        "pushq %rbp\nmovq %rsp,%rbp\nsubq $464,%rsp\nmovq %rdi,%r11\nmovq %rsi,%r10\nxorl %eax,%eax\n"
        "1:\nmovq 48(%r10,%rax,8),%rdx\nmovq %rdx,(%rsp,%rax,8)\nincq %rax\ncmpq $58,%rax\njne 1b\n"
        "movq 0(%r10),%rdi\nmovq 8(%r10),%rsi\nmovq 16(%r10),%rdx\nmovq 24(%r10),%rcx\nmovq 32(%r10),%r8\nmovq 40(%r10),%r9\ncall *%r11\nleave\nret\n"
        ".size signed_physical_observer,.-signed_physical_observer\n.section .note.GNU-stack,\"\",@progbits\n.previous\n");
struct test_case {const void *entry;kernel probe;unsigned bits,slots,literals;};
static uint32_t expected_words[62];
static unsigned provider_bad;
static uint32_t extend(uint64_t word,unsigned bits,unsigned sign){uint32_t mask=(1u<<bits)-1,value=(uint32_t)word&mask;return sign&&(value&(1u<<(bits-1)))?value|~mask:value;}
static uint32_t reduce(const uint32_t *words,unsigned bits,unsigned count,uint64_t live){uint32_t result=(uint32_t)live;for(unsigned i=0;i<count;i++)result=(result^extend(words[i],bits,i%3==0))*37u+i*17u;return result;}
static uint32_t provider(const uint32_t *words,unsigned bits,unsigned count,void *output,uint64_t live){
    uint32_t mask=(1u<<bits)-1;for(unsigned i=0;i<count;i++){
        if(i%3==2){if((words[i]&mask)!=(expected_words[i]&mask))provider_bad=1;}
        else if(words[i]!=expected_words[i])provider_bad=1;
    }
    uint32_t result=reduce(words,bits,count,live);uint64_t out[2]={result,live};memcpy(output,out,sizeof out);return extend(result,bits,1);
}
static uint64_t random_word(uint64_t *state){*state^=*state<<13;*state^=*state>>7;*state^=*state<<17;return *state;}
static int run_all(const struct test_case *cases,size_t count,int argc,char **argv){
    unsigned fault=argc>1?(unsigned)strtoul(argv[1],0,10):0;size_t page=(size_t)sysconf(_SC_PAGESIZE);uint64_t state=UINT64_C(0x213799abacbdcedf);size_t observations=0;
    unsigned char *mapping=mmap(0,page*3,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);if(mapping==MAP_FAILED||mprotect(mapping+page,page,PROT_READ|PROT_WRITE))return 2;
    uint64_t *input=(uint64_t *)(mapping+2*page-512);
    for(size_t k=0;k<count;k++)for(unsigned seed=0;seed<512;seed++){
        const struct test_case *test=&cases[k];uint64_t args[64]={0},saved[64],live=random_word(&state);uint32_t words[62],probe_words[62];
        struct {uint64_t before,value,live,after;} out={UINT64_C(0xabcdef0123456789),0,0,UINT64_C(0x123456789abcdef0)};
        uint32_t mask=(1u<<test->bits)-1;
        for(unsigned i=0;i<64;i++)input[i]=random_word(&state);
        for(unsigned i=0;i<test->slots;i++){
            uint64_t raw=seed<256?(uint64_t)(seed+i*17u):input[i];uint32_t logical=(uint32_t)raw&mask;
            words[i]=extend(logical,test->bits,i%3==0);
            uint32_t physical=i%3==2?(uint32_t)raw:words[i];args[i]=(random_word(&state)&UINT64_C(0xffffffff00000000))|physical;
            input[i]=(random_word(&state)&UINT64_C(0xffffffff00000000))|(uint32_t)raw;
            uint32_t outgoing=test->literals&&i%4==0?(i%3==0?mask-1:mask):logical;
            probe_words[i]=extend(outgoing,test->bits,i%3==0);expected_words[i]=probe_words[i];
        }
        memcpy(saved,input,sizeof saved);args[test->slots]=(uintptr_t)&out.value;args[test->slots+1]=live;
        uint32_t expected=reduce(words,test->bits,test->slots,live),returned=signed_physical_observer(test->entry,args);
        if(fault==1)returned^=1;
        if((returned&mask)!=(expected&mask)||out.value!=expected||out.live!=live||out.before!=UINT64_C(0xabcdef0123456789)||out.after!=UINT64_C(0x123456789abcdef0)||memcmp(input,saved,sizeof saved)){fprintf(stderr,"signed-abi entry case=%zu seed=%u bits=%u slots=%u expected-low=%08x got=%08x fault=%u\n",k,seed,test->bits,test->slots,expected&mask,returned,fault);return 1;}
        observations+=4;provider_bad=0;out.value=out.live=0;
        uint64_t actual=test->probe(input,&out.value,live);uint32_t result=reduce(probe_words,test->bits,test->slots,live);int64_t signed_result=(int32_t)extend(result,test->bits,1);
        if(fault==2)out.live^=1;if(fault==3)input[0]^=1;
        if(actual!=((uint64_t)signed_result^live)||out.value!=result||out.live!=live||provider_bad||out.before!=UINT64_C(0xabcdef0123456789)||out.after!=UINT64_C(0x123456789abcdef0)||memcmp(input,saved,sizeof saved)){fprintf(stderr,"signed-abi outgoing case=%zu seed=%u bits=%u slots=%u provider_bad=%u fault=%u\n",k,seed,test->bits,test->slots,provider_bad,fault);return 1;}
        observations+=4;
    }
    if(munmap(mapping,page*3))return 2;
    printf("signed-abi observations=%zu c-physical-carriers=defined-return-payloads=ccc-fastcc=signed-zero-extension=register-stack-64-arguments=exact-stores=guard-pages=preserved\n",observations);return 0;
}
extern void signed_abi_entry_0(void);
extern uint64_t signed_abi_probe_0(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_0(uint32_t a0,void *out,uint64_t live){const uint32_t words[]={a0};return provider(words,8,1,out,live);}
extern void signed_abi_entry_1(void);
extern uint64_t signed_abi_probe_1(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_1(uint32_t a0,void *out,uint64_t live){const uint32_t words[]={a0};return provider(words,8,1,out,live);}
extern void signed_abi_entry_2(void);
extern uint64_t signed_abi_probe_2(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_2(uint32_t a0,void *out,uint64_t live){const uint32_t words[]={a0};return provider(words,8,1,out,live);}
extern void signed_abi_entry_3(void);
extern uint64_t signed_abi_probe_3(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_3(uint32_t a0,void *out,uint64_t live){const uint32_t words[]={a0};return provider(words,8,1,out,live);}
extern void signed_abi_entry_4(void);
extern uint64_t signed_abi_probe_4(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_4(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3};return provider(words,8,4,out,live);}
extern void signed_abi_entry_5(void);
extern uint64_t signed_abi_probe_5(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_5(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3};return provider(words,8,4,out,live);}
extern void signed_abi_entry_6(void);
extern uint64_t signed_abi_probe_6(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_6(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3};return provider(words,8,4,out,live);}
extern void signed_abi_entry_7(void);
extern uint64_t signed_abi_probe_7(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_7(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3};return provider(words,8,4,out,live);}
extern void signed_abi_entry_8(void);
extern uint64_t signed_abi_probe_8(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_8(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8};return provider(words,8,9,out,live);}
extern void signed_abi_entry_9(void);
extern uint64_t signed_abi_probe_9(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_9(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8};return provider(words,8,9,out,live);}
extern void signed_abi_entry_10(void);
extern uint64_t signed_abi_probe_10(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_10(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8};return provider(words,8,9,out,live);}
extern void signed_abi_entry_11(void);
extern uint64_t signed_abi_probe_11(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_11(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8};return provider(words,8,9,out,live);}
extern void signed_abi_entry_12(void);
extern uint64_t signed_abi_probe_12(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_12(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,uint32_t a9,uint32_t a10,uint32_t a11,uint32_t a12,uint32_t a13,uint32_t a14,uint32_t a15,uint32_t a16,uint32_t a17,uint32_t a18,uint32_t a19,uint32_t a20,uint32_t a21,uint32_t a22,uint32_t a23,uint32_t a24,uint32_t a25,uint32_t a26,uint32_t a27,uint32_t a28,uint32_t a29,uint32_t a30,uint32_t a31,uint32_t a32,uint32_t a33,uint32_t a34,uint32_t a35,uint32_t a36,uint32_t a37,uint32_t a38,uint32_t a39,uint32_t a40,uint32_t a41,uint32_t a42,uint32_t a43,uint32_t a44,uint32_t a45,uint32_t a46,uint32_t a47,uint32_t a48,uint32_t a49,uint32_t a50,uint32_t a51,uint32_t a52,uint32_t a53,uint32_t a54,uint32_t a55,uint32_t a56,uint32_t a57,uint32_t a58,uint32_t a59,uint32_t a60,uint32_t a61,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42,a43,a44,a45,a46,a47,a48,a49,a50,a51,a52,a53,a54,a55,a56,a57,a58,a59,a60,a61};return provider(words,8,62,out,live);}
extern void signed_abi_entry_13(void);
extern uint64_t signed_abi_probe_13(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_13(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,uint32_t a9,uint32_t a10,uint32_t a11,uint32_t a12,uint32_t a13,uint32_t a14,uint32_t a15,uint32_t a16,uint32_t a17,uint32_t a18,uint32_t a19,uint32_t a20,uint32_t a21,uint32_t a22,uint32_t a23,uint32_t a24,uint32_t a25,uint32_t a26,uint32_t a27,uint32_t a28,uint32_t a29,uint32_t a30,uint32_t a31,uint32_t a32,uint32_t a33,uint32_t a34,uint32_t a35,uint32_t a36,uint32_t a37,uint32_t a38,uint32_t a39,uint32_t a40,uint32_t a41,uint32_t a42,uint32_t a43,uint32_t a44,uint32_t a45,uint32_t a46,uint32_t a47,uint32_t a48,uint32_t a49,uint32_t a50,uint32_t a51,uint32_t a52,uint32_t a53,uint32_t a54,uint32_t a55,uint32_t a56,uint32_t a57,uint32_t a58,uint32_t a59,uint32_t a60,uint32_t a61,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42,a43,a44,a45,a46,a47,a48,a49,a50,a51,a52,a53,a54,a55,a56,a57,a58,a59,a60,a61};return provider(words,8,62,out,live);}
extern void signed_abi_entry_14(void);
extern uint64_t signed_abi_probe_14(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_14(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,uint32_t a9,uint32_t a10,uint32_t a11,uint32_t a12,uint32_t a13,uint32_t a14,uint32_t a15,uint32_t a16,uint32_t a17,uint32_t a18,uint32_t a19,uint32_t a20,uint32_t a21,uint32_t a22,uint32_t a23,uint32_t a24,uint32_t a25,uint32_t a26,uint32_t a27,uint32_t a28,uint32_t a29,uint32_t a30,uint32_t a31,uint32_t a32,uint32_t a33,uint32_t a34,uint32_t a35,uint32_t a36,uint32_t a37,uint32_t a38,uint32_t a39,uint32_t a40,uint32_t a41,uint32_t a42,uint32_t a43,uint32_t a44,uint32_t a45,uint32_t a46,uint32_t a47,uint32_t a48,uint32_t a49,uint32_t a50,uint32_t a51,uint32_t a52,uint32_t a53,uint32_t a54,uint32_t a55,uint32_t a56,uint32_t a57,uint32_t a58,uint32_t a59,uint32_t a60,uint32_t a61,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42,a43,a44,a45,a46,a47,a48,a49,a50,a51,a52,a53,a54,a55,a56,a57,a58,a59,a60,a61};return provider(words,8,62,out,live);}
extern void signed_abi_entry_15(void);
extern uint64_t signed_abi_probe_15(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_15(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,uint32_t a9,uint32_t a10,uint32_t a11,uint32_t a12,uint32_t a13,uint32_t a14,uint32_t a15,uint32_t a16,uint32_t a17,uint32_t a18,uint32_t a19,uint32_t a20,uint32_t a21,uint32_t a22,uint32_t a23,uint32_t a24,uint32_t a25,uint32_t a26,uint32_t a27,uint32_t a28,uint32_t a29,uint32_t a30,uint32_t a31,uint32_t a32,uint32_t a33,uint32_t a34,uint32_t a35,uint32_t a36,uint32_t a37,uint32_t a38,uint32_t a39,uint32_t a40,uint32_t a41,uint32_t a42,uint32_t a43,uint32_t a44,uint32_t a45,uint32_t a46,uint32_t a47,uint32_t a48,uint32_t a49,uint32_t a50,uint32_t a51,uint32_t a52,uint32_t a53,uint32_t a54,uint32_t a55,uint32_t a56,uint32_t a57,uint32_t a58,uint32_t a59,uint32_t a60,uint32_t a61,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42,a43,a44,a45,a46,a47,a48,a49,a50,a51,a52,a53,a54,a55,a56,a57,a58,a59,a60,a61};return provider(words,8,62,out,live);}
extern void signed_abi_entry_16(void);
extern uint64_t signed_abi_probe_16(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_16(uint32_t a0,void *out,uint64_t live){const uint32_t words[]={a0};return provider(words,16,1,out,live);}
extern void signed_abi_entry_17(void);
extern uint64_t signed_abi_probe_17(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_17(uint32_t a0,void *out,uint64_t live){const uint32_t words[]={a0};return provider(words,16,1,out,live);}
extern void signed_abi_entry_18(void);
extern uint64_t signed_abi_probe_18(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_18(uint32_t a0,void *out,uint64_t live){const uint32_t words[]={a0};return provider(words,16,1,out,live);}
extern void signed_abi_entry_19(void);
extern uint64_t signed_abi_probe_19(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_19(uint32_t a0,void *out,uint64_t live){const uint32_t words[]={a0};return provider(words,16,1,out,live);}
extern void signed_abi_entry_20(void);
extern uint64_t signed_abi_probe_20(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_20(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3};return provider(words,16,4,out,live);}
extern void signed_abi_entry_21(void);
extern uint64_t signed_abi_probe_21(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_21(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3};return provider(words,16,4,out,live);}
extern void signed_abi_entry_22(void);
extern uint64_t signed_abi_probe_22(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_22(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3};return provider(words,16,4,out,live);}
extern void signed_abi_entry_23(void);
extern uint64_t signed_abi_probe_23(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_23(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3};return provider(words,16,4,out,live);}
extern void signed_abi_entry_24(void);
extern uint64_t signed_abi_probe_24(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_24(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8};return provider(words,16,9,out,live);}
extern void signed_abi_entry_25(void);
extern uint64_t signed_abi_probe_25(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_25(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8};return provider(words,16,9,out,live);}
extern void signed_abi_entry_26(void);
extern uint64_t signed_abi_probe_26(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_26(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8};return provider(words,16,9,out,live);}
extern void signed_abi_entry_27(void);
extern uint64_t signed_abi_probe_27(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_27(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8};return provider(words,16,9,out,live);}
extern void signed_abi_entry_28(void);
extern uint64_t signed_abi_probe_28(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_28(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,uint32_t a9,uint32_t a10,uint32_t a11,uint32_t a12,uint32_t a13,uint32_t a14,uint32_t a15,uint32_t a16,uint32_t a17,uint32_t a18,uint32_t a19,uint32_t a20,uint32_t a21,uint32_t a22,uint32_t a23,uint32_t a24,uint32_t a25,uint32_t a26,uint32_t a27,uint32_t a28,uint32_t a29,uint32_t a30,uint32_t a31,uint32_t a32,uint32_t a33,uint32_t a34,uint32_t a35,uint32_t a36,uint32_t a37,uint32_t a38,uint32_t a39,uint32_t a40,uint32_t a41,uint32_t a42,uint32_t a43,uint32_t a44,uint32_t a45,uint32_t a46,uint32_t a47,uint32_t a48,uint32_t a49,uint32_t a50,uint32_t a51,uint32_t a52,uint32_t a53,uint32_t a54,uint32_t a55,uint32_t a56,uint32_t a57,uint32_t a58,uint32_t a59,uint32_t a60,uint32_t a61,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42,a43,a44,a45,a46,a47,a48,a49,a50,a51,a52,a53,a54,a55,a56,a57,a58,a59,a60,a61};return provider(words,16,62,out,live);}
extern void signed_abi_entry_29(void);
extern uint64_t signed_abi_probe_29(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_29(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,uint32_t a9,uint32_t a10,uint32_t a11,uint32_t a12,uint32_t a13,uint32_t a14,uint32_t a15,uint32_t a16,uint32_t a17,uint32_t a18,uint32_t a19,uint32_t a20,uint32_t a21,uint32_t a22,uint32_t a23,uint32_t a24,uint32_t a25,uint32_t a26,uint32_t a27,uint32_t a28,uint32_t a29,uint32_t a30,uint32_t a31,uint32_t a32,uint32_t a33,uint32_t a34,uint32_t a35,uint32_t a36,uint32_t a37,uint32_t a38,uint32_t a39,uint32_t a40,uint32_t a41,uint32_t a42,uint32_t a43,uint32_t a44,uint32_t a45,uint32_t a46,uint32_t a47,uint32_t a48,uint32_t a49,uint32_t a50,uint32_t a51,uint32_t a52,uint32_t a53,uint32_t a54,uint32_t a55,uint32_t a56,uint32_t a57,uint32_t a58,uint32_t a59,uint32_t a60,uint32_t a61,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42,a43,a44,a45,a46,a47,a48,a49,a50,a51,a52,a53,a54,a55,a56,a57,a58,a59,a60,a61};return provider(words,16,62,out,live);}
extern void signed_abi_entry_30(void);
extern uint64_t signed_abi_probe_30(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_30(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,uint32_t a9,uint32_t a10,uint32_t a11,uint32_t a12,uint32_t a13,uint32_t a14,uint32_t a15,uint32_t a16,uint32_t a17,uint32_t a18,uint32_t a19,uint32_t a20,uint32_t a21,uint32_t a22,uint32_t a23,uint32_t a24,uint32_t a25,uint32_t a26,uint32_t a27,uint32_t a28,uint32_t a29,uint32_t a30,uint32_t a31,uint32_t a32,uint32_t a33,uint32_t a34,uint32_t a35,uint32_t a36,uint32_t a37,uint32_t a38,uint32_t a39,uint32_t a40,uint32_t a41,uint32_t a42,uint32_t a43,uint32_t a44,uint32_t a45,uint32_t a46,uint32_t a47,uint32_t a48,uint32_t a49,uint32_t a50,uint32_t a51,uint32_t a52,uint32_t a53,uint32_t a54,uint32_t a55,uint32_t a56,uint32_t a57,uint32_t a58,uint32_t a59,uint32_t a60,uint32_t a61,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42,a43,a44,a45,a46,a47,a48,a49,a50,a51,a52,a53,a54,a55,a56,a57,a58,a59,a60,a61};return provider(words,16,62,out,live);}
extern void signed_abi_entry_31(void);
extern uint64_t signed_abi_probe_31(const void *,void *,uint64_t);
__attribute__((noinline)) uint32_t signed_abi_external_31(uint32_t a0,uint32_t a1,uint32_t a2,uint32_t a3,uint32_t a4,uint32_t a5,uint32_t a6,uint32_t a7,uint32_t a8,uint32_t a9,uint32_t a10,uint32_t a11,uint32_t a12,uint32_t a13,uint32_t a14,uint32_t a15,uint32_t a16,uint32_t a17,uint32_t a18,uint32_t a19,uint32_t a20,uint32_t a21,uint32_t a22,uint32_t a23,uint32_t a24,uint32_t a25,uint32_t a26,uint32_t a27,uint32_t a28,uint32_t a29,uint32_t a30,uint32_t a31,uint32_t a32,uint32_t a33,uint32_t a34,uint32_t a35,uint32_t a36,uint32_t a37,uint32_t a38,uint32_t a39,uint32_t a40,uint32_t a41,uint32_t a42,uint32_t a43,uint32_t a44,uint32_t a45,uint32_t a46,uint32_t a47,uint32_t a48,uint32_t a49,uint32_t a50,uint32_t a51,uint32_t a52,uint32_t a53,uint32_t a54,uint32_t a55,uint32_t a56,uint32_t a57,uint32_t a58,uint32_t a59,uint32_t a60,uint32_t a61,void *out,uint64_t live){const uint32_t words[]={a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18,a19,a20,a21,a22,a23,a24,a25,a26,a27,a28,a29,a30,a31,a32,a33,a34,a35,a36,a37,a38,a39,a40,a41,a42,a43,a44,a45,a46,a47,a48,a49,a50,a51,a52,a53,a54,a55,a56,a57,a58,a59,a60,a61};return provider(words,16,62,out,live);}
static const struct test_case cases[]={
{(const void *)signed_abi_entry_0,signed_abi_probe_0,8,1,0},
{(const void *)signed_abi_entry_1,signed_abi_probe_1,8,1,1},
{(const void *)signed_abi_entry_2,signed_abi_probe_2,8,1,0},
{(const void *)signed_abi_entry_3,signed_abi_probe_3,8,1,1},
{(const void *)signed_abi_entry_4,signed_abi_probe_4,8,4,0},
{(const void *)signed_abi_entry_5,signed_abi_probe_5,8,4,1},
{(const void *)signed_abi_entry_6,signed_abi_probe_6,8,4,0},
{(const void *)signed_abi_entry_7,signed_abi_probe_7,8,4,1},
{(const void *)signed_abi_entry_8,signed_abi_probe_8,8,9,0},
{(const void *)signed_abi_entry_9,signed_abi_probe_9,8,9,1},
{(const void *)signed_abi_entry_10,signed_abi_probe_10,8,9,0},
{(const void *)signed_abi_entry_11,signed_abi_probe_11,8,9,1},
{(const void *)signed_abi_entry_12,signed_abi_probe_12,8,62,0},
{(const void *)signed_abi_entry_13,signed_abi_probe_13,8,62,1},
{(const void *)signed_abi_entry_14,signed_abi_probe_14,8,62,0},
{(const void *)signed_abi_entry_15,signed_abi_probe_15,8,62,1},
{(const void *)signed_abi_entry_16,signed_abi_probe_16,16,1,0},
{(const void *)signed_abi_entry_17,signed_abi_probe_17,16,1,1},
{(const void *)signed_abi_entry_18,signed_abi_probe_18,16,1,0},
{(const void *)signed_abi_entry_19,signed_abi_probe_19,16,1,1},
{(const void *)signed_abi_entry_20,signed_abi_probe_20,16,4,0},
{(const void *)signed_abi_entry_21,signed_abi_probe_21,16,4,1},
{(const void *)signed_abi_entry_22,signed_abi_probe_22,16,4,0},
{(const void *)signed_abi_entry_23,signed_abi_probe_23,16,4,1},
{(const void *)signed_abi_entry_24,signed_abi_probe_24,16,9,0},
{(const void *)signed_abi_entry_25,signed_abi_probe_25,16,9,1},
{(const void *)signed_abi_entry_26,signed_abi_probe_26,16,9,0},
{(const void *)signed_abi_entry_27,signed_abi_probe_27,16,9,1},
{(const void *)signed_abi_entry_28,signed_abi_probe_28,16,62,0},
{(const void *)signed_abi_entry_29,signed_abi_probe_29,16,62,1},
{(const void *)signed_abi_entry_30,signed_abi_probe_30,16,62,0},
{(const void *)signed_abi_entry_31,signed_abi_probe_31,16,62,1},
};
int main(int argc,char **argv){return run_all(cases,sizeof cases/sizeof cases[0],argc,argv);}
