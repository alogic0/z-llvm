#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct { uintptr_t p; uint64_t n; } Pair;
typedef uint64_t (*Binary)(uint64_t,uint64_t);
static void clobber(void) {
    __asm__ volatile("mov $17, %%rax\n\tmov $19, %%rcx\n\tmov $23, %%rdx\n\t"
        "mov $29, %%rsi\n\tmov $31, %%rdi\n\tmov $37, %%r8\n\t"
        "mov $41, %%r9\n\tmov $43, %%r10\n\tmov $47, %%r11"
        : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc", "memory");
}
__attribute__((noinline)) uint64_t calls_binary(uint64_t a,uint64_t b) { uint64_t r=a+3*b; clobber(); return r; }
__attribute__((noinline)) void *calls_get_target(void *p) { clobber(); return p; }
__attribute__((noinline)) uint64_t calls_self(void *p,uint64_t a) { if(p!=(void*)calls_self) abort(); clobber(); return a+7; }
__attribute__((noinline)) Pair calls_pair_helper(void *p,uint64_t a) { Pair r={(uintptr_t)p,a+7}; clobber(); return r; }
__attribute__((noinline)) void *calls_pointer_helper(void *p) { clobber(); return p; }
__attribute__((noinline)) uint64_t calls_empty(void) { clobber(); return UINT64_C(0xdeadbeefcafe0123); }
#define CLOBBER "xorl %edi,%edi\n" "xorl %esi,%esi\n" "xorl %edx,%edx\n" "xorl %ecx,%ecx\n" "xorl %r8d,%r8d\n" "xorl %r9d,%r9d\n" "xorl %r10d,%r10d\n" "xorl %r11d,%r11d\n"
#define DIRTY(n,mask,padding) ".globl calls_dirty_" #n "\n.type calls_dirty_" #n ",@function\ncalls_dirty_" #n ":\nmovl %edi,%eax\nxorl $90,%eax\nandl $" #mask ",%eax\nmovabsq $" #padding ",%r10\norq %r10,%rax\n" CLOBBER "ret\n.size calls_dirty_" #n ",.-calls_dirty_" #n "\n"
__asm__(".text\n" DIRTY(1,1,0xdeadbeefcafefffe) DIRTY(8,255,0xdeadbeefcafeff00) DIRTY(16,65535,0xdeadbeefcafe0000));
extern void calls_dirty_1(void),calls_dirty_8(void),calls_dirty_16(void);
extern uint64_t calls_alias(void *,uint64_t), calls_noargs(void *);
extern uint64_t calls_pair(void *,void *,uint64_t,Pair *);
extern void *calls_pointer(void *,void *);
extern uint32_t calls_sat32(uint32_t,uint32_t);
extern uint64_t calls_sat64(uint64_t,uint64_t), calls_sat_loaded(const uint64_t *,const uint64_t *,uint64_t *), calls_constant(uint64_t,uint64_t *);

extern uint64_t calls_plain(void *,uint64_t,uint64_t,uint64_t *);
extern uint64_t calls_loaded(void *,uint64_t,uint64_t,uint64_t *);
extern uint64_t calls_returned(void *,uint64_t,uint64_t,uint64_t *);
extern uint64_t calls_narrow_1(void *,uint64_t,uint64_t,uint64_t *);
extern uint64_t calls_narrow_8(void *,uint64_t,uint64_t,uint64_t *);
extern uint64_t calls_narrow_16(void *,uint64_t,uint64_t,uint64_t *);
extern uint64_t calls_frame(void *,uint64_t,uint64_t,uint64_t *);
extern uint64_t calls_entry_7(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t calls_out_7(void *,uint64_t,uint64_t,uint64_t *);
extern uint64_t calls_helper_7(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
__attribute__((noinline)) uint64_t calls_helper_body_7(uint64_t a0, uint64_t a1, uint64_t a2, uint64_t a3, uint64_t a4, uint64_t a5, uint64_t a6) { uint64_t r=a0*1+a1*3+a2*5+a3*7+a4*9+a5*11+a6*13; clobber(); return r; }
__asm__(".text\n.globl calls_helper_7\n.type calls_helper_7,@function\ncalls_helper_7:\nmovq %rsp,%r10\nandl $15,%r10d\ncmpl $8,%r10d\njne 1f\njmp calls_helper_body_7\n1: ud2\n.size calls_helper_7,.-calls_helper_7\n");
extern uint64_t calls_entry_8(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t calls_out_8(void *,uint64_t,uint64_t,uint64_t *);
extern uint64_t calls_helper_8(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
__attribute__((noinline)) uint64_t calls_helper_body_8(uint64_t a0, uint64_t a1, uint64_t a2, uint64_t a3, uint64_t a4, uint64_t a5, uint64_t a6, uint64_t a7) { uint64_t r=a0*1+a1*3+a2*5+a3*7+a4*9+a5*11+a6*13+a7*15; clobber(); return r; }
__asm__(".text\n.globl calls_helper_8\n.type calls_helper_8,@function\ncalls_helper_8:\nmovq %rsp,%r10\nandl $15,%r10d\ncmpl $8,%r10d\njne 1f\njmp calls_helper_body_8\n1: ud2\n.size calls_helper_8,.-calls_helper_8\n");
extern uint64_t calls_entry_9(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t calls_out_9(void *,uint64_t,uint64_t,uint64_t *);
extern uint64_t calls_helper_9(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
__attribute__((noinline)) uint64_t calls_helper_body_9(uint64_t a0, uint64_t a1, uint64_t a2, uint64_t a3, uint64_t a4, uint64_t a5, uint64_t a6, uint64_t a7, uint64_t a8) { uint64_t r=a0*1+a1*3+a2*5+a3*7+a4*9+a5*11+a6*13+a7*15+a8*17; clobber(); return r; }
__asm__(".text\n.globl calls_helper_9\n.type calls_helper_9,@function\ncalls_helper_9:\nmovq %rsp,%r10\nandl $15,%r10d\ncmpl $8,%r10d\njne 1f\njmp calls_helper_body_9\n1: ud2\n.size calls_helper_9,.-calls_helper_9\n");
extern uint64_t calls_entry_16(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t calls_out_16(void *,uint64_t,uint64_t,uint64_t *);
extern uint64_t calls_helper_16(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
__attribute__((noinline)) uint64_t calls_helper_body_16(uint64_t a0, uint64_t a1, uint64_t a2, uint64_t a3, uint64_t a4, uint64_t a5, uint64_t a6, uint64_t a7, uint64_t a8, uint64_t a9, uint64_t a10, uint64_t a11, uint64_t a12, uint64_t a13, uint64_t a14, uint64_t a15) { uint64_t r=a0*1+a1*3+a2*5+a3*7+a4*9+a5*11+a6*13+a7*15+a8*17+a9*19+a10*21+a11*23+a12*25+a13*27+a14*29+a15*31; clobber(); return r; }
__asm__(".text\n.globl calls_helper_16\n.type calls_helper_16,@function\ncalls_helper_16:\nmovq %rsp,%r10\nandl $15,%r10d\ncmpl $8,%r10d\njne 1f\njmp calls_helper_body_16\n1: ud2\n.size calls_helper_16,.-calls_helper_16\n");
__attribute__((noinline)) uint64_t calls_frame_helper(uint64_t a,uint64_t b,uint64_t c,uint64_t d,uint64_t e,uint64_t f,uint32_t x,uint64_t *p,void *nullp) {
    if(a!=1 || b!=2 || c!=3 || d!=4 || e!=5 || f!=6 || nullp) abort();
    uint64_t r=*p+x; *p=r^UINT64_C(0xdeadbeefcafe0123); clobber(); return r;
}
extern uint64_t calls_entry_mixed(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,const uint64_t *);
extern uint64_t calls_entry_branch(uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t,uint64_t);
extern uint64_t calls_repeated(void *,uint64_t,uint64_t,uint64_t *);
int main(void) {
    const uint64_t values[]={0,1,255,65536,UINT32_MAX,UINT64_MAX,UINT64_C(1)<<63,UINT64_C(0xdeadbeef01234567)};
    const uint64_t guard=UINT64_C(0xa5a5a5a5a5a5a5a5);
    unsigned observations=0;
    for(unsigned i=0;i<8;++i) for(unsigned j=0;j<8;++j) {
        uint64_t a=values[i],b=values[j],out[]={guard,0,guard};
        Binary target=calls_binary;
        uint64_t (*functions[])(void*,uint64_t,uint64_t,uint64_t*)={calls_plain,calls_loaded,calls_returned};
        for(unsigned f=0;f<3;++f) {
            void *callee=f==1?(void*)&target:(void*)target;
            if(functions[f](callee,a,b,out+1)!=(b+3*a)+(a^b) || out[1]!=b+3*a || out[0]!=guard || out[2]!=guard) return 1;
            ++observations;
        }
        if(calls_alias((void*)calls_self,a)!=a+7) return 2;
        ++observations;
        struct { uint64_t before; Pair pair; uint64_t after; } paired={guard,{0,0},guard};
        if(calls_pair((void*)calls_pair_helper,&out,a,&paired.pair)!=((a+7)^a) || paired.pair.p!=(uintptr_t)&out || paired.pair.n!=a+7 || paired.before!=guard || paired.after!=guard) return 3;
        ++observations;
        if(calls_pointer((void*)calls_pointer_helper,(void*)(uintptr_t)b)!=(void*)(uintptr_t)b) return 4;
        ++observations;
        if(calls_noargs((void*)calls_empty)!=UINT64_C(0xdeadbeefcafe0123)) return 5;
        ++observations;
        uint64_t (*narrow[])(void*,uint64_t,uint64_t,uint64_t*)={calls_narrow_1,calls_narrow_8,calls_narrow_16};
        void *dirty[]={(void*)calls_dirty_1,(void*)calls_dirty_8,(void*)calls_dirty_16};
        uint64_t masks[]={1,255,65535};
        for(unsigned f=0;f<3;++f) {
            uint64_t payload=(a^90)&masks[f];
            if(narrow[f](dirty[f],a,b,out+1)!=payload+(a^b) || out[1]!=payload || out[0]!=guard || out[2]!=guard) return 6;
            ++observations;
        }

        if(calls_entry_7(b,a,b,a,b,a,b)!=b*28+a*21) return 7;
        ++observations;
        if(calls_out_7((void*)calls_helper_7,a,b,out+1)!=(b*28+a*21)+(a^b) || out[1]!=b*28+a*21 || out[0]!=guard || out[2]!=guard) return 27;
        ++observations;
        if(calls_entry_8(b,a,b,a,b,a,b,a)!=b*28+a*36) return 8;
        ++observations;
        if(calls_out_8((void*)calls_helper_8,a,b,out+1)!=(b*28+a*36)+(a^b) || out[1]!=b*28+a*36 || out[0]!=guard || out[2]!=guard) return 28;
        ++observations;
        if(calls_entry_9(b,a,b,a,b,a,b,a,b)!=b*45+a*36) return 9;
        ++observations;
        if(calls_out_9((void*)calls_helper_9,a,b,out+1)!=(b*45+a*36)+(a^b) || out[1]!=b*45+a*36 || out[0]!=guard || out[2]!=guard) return 29;
        ++observations;
        if(calls_entry_16(b,a,b,a,b,a,b,a,b,a,b,a,b,a,b,a)!=b*120+a*136) return 16;
        ++observations;
        if(calls_out_16((void*)calls_helper_16,a,b,out+1)!=(b*120+a*136)+(a^b) || out[1]!=b*120+a*136 || out[0]!=guard || out[2]!=guard) return 36;
        ++observations;
        if(calls_entry_mixed(a,b,a,b,a,b,a,&b)!=(((uint32_t)a+b)^a)) return 45;
        ++observations;
        if(calls_entry_branch(a,b,a,b,a,b,a)!=(a==0?a+b:a^b)) return 46;
        ++observations;
        if(calls_repeated((void*)calls_helper_9,a,b,out+1)!=((b*45+a*36)^(a*45+b*36))+a || out[1]!=b*45+a*36 || out[0]!=guard || out[2]!=guard) return 47;
        ++observations;
        uint64_t r=b+(uint32_t)a;
        if(calls_frame((void*)calls_frame_helper,a,b,out+1)!=r+(a^b) || out[1]!=(r^UINT64_C(0xdeadbeefcafe0123)) || out[0]!=guard || out[2]!=guard) return 40;
        ++observations;
        if(calls_sat32(a,b)!=((uint32_t)a<(uint32_t)b?0:(uint32_t)a-(uint32_t)b)) return 41;
        ++observations;
        if(calls_sat64(a,b)!=(a<b?0:a-b)) return 42;
        ++observations;
        if(calls_sat_loaded(&a,&b,out+1)!=(a^b) || out[1]!=(a<b?0:a-b) || out[0]!=guard || out[2]!=guard) return 43;
        ++observations;
        if(calls_constant(a,out+1)!=(a==0) || out[1]!=(UINT64_C(1)<<63) || out[0]!=guard || out[2]!=guard) return 44;
        ++observations;
    }
    printf("indirect-stack-calls observations=%u targets=returns=stack=alignment=scalar=live=guards=preserved\n",observations);
    return 0;
}
