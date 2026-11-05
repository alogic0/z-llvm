#include <stdint.h>
#include <stdio.h>
#include <string.h>
typedef struct { uint64_t first, second; } Pair;
extern unsigned char pointer_flow_data[8];
extern Pair pointer_flow_phi_pi(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_select_pi(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_loop_pi(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_constant_pi(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_phi_ip(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_select_ip(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_loop_ip(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_constant_ip(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_phi_pp(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_select_pp(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_loop_pp(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_constant_pp(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_phi_ii(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_select_ii(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_loop_ii(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_constant_ii(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_global_phi(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_global_select(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_constant_cast(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_global_call(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_global_index(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_constant_gep(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_global_load(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
extern Pair pointer_flow_global_offset(void *, uint64_t, uint64_t, uint64_t, uint64_t *);
__attribute__((noinline)) uint64_t pointer_flow_clobber(uint64_t value) {
    uint64_t result = value ^ UINT64_C(0xdeadbeef12345678);
    __asm__ volatile ("mov $1, %%rax; mov $3, %%rcx; mov $5, %%rdx; mov $7, %%rsi; mov $9, %%rdi; mov $11, %%r8; mov $13, %%r9; mov $15, %%r10; mov $17, %%r11"
      : : : "rax", "rcx", "rdx", "rsi", "rdi", "r8", "r9", "r10", "r11", "cc", "memory");
    return result;
}
__attribute__((noinline)) uint64_t pointer_flow_helper(void *p, void *q, uint64_t salt) {
    uint64_t result = (uintptr_t)p ^ (uintptr_t)q ^ salt;
    pointer_flow_clobber(result);
    return result;
}
int main(void) {
    const uint64_t inputs[] = {0, 1, 7, 255, UINT32_MAX, UINT64_C(1)<<63, UINT64_MAX, UINT64_C(0xdeadbeef01234567)};
    unsigned observations = 0;
    for (unsigned i=0; i<8; ++i) for (unsigned j=0; j<8; ++j) {
        uint64_t a=inputs[i], b=inputs[j], choice=(uint64_t)(i*8+j);
        void *p=(void *)(uintptr_t)(a ^ UINT64_C(0x1234));
        struct { uint64_t before, value, after; } out;

        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_phi_pi(p,a,b,choice,&out.value); uint64_t x=((choice & 1) ? (uintptr_t)p : 0), y=((choice & 1) ? b : a);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_phi_pi i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_select_pi(p,a,b,choice,&out.value); uint64_t x=((choice & 1) ? (uintptr_t)p : 0), y=((choice & 1) ? b : a);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_select_pi i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_loop_pi(p,a,b,choice,&out.value); uint64_t x=((uintptr_t)p), y=(b + (choice & 7));
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_loop_pi i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_constant_pi(p,a,b,choice,&out.value); uint64_t x=((choice & 1) ? (uintptr_t)pointer_flow_data : 0), y=((choice & 1) ? UINT64_MAX : 0);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_constant_pi i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_phi_ip(p,a,b,choice,&out.value); uint64_t x=((choice & 1) ? a : b), y=((choice & 1) ? b : (uintptr_t)p);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_phi_ip i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_select_ip(p,a,b,choice,&out.value); uint64_t x=((choice & 1) ? a : b), y=((choice & 1) ? b : (uintptr_t)p);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_select_ip i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_loop_ip(p,a,b,choice,&out.value); uint64_t x=(a), y=(b + (choice & 7));
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_loop_ip i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_constant_ip(p,a,b,choice,&out.value); uint64_t x=((choice & 1) ? (UINT64_C(1) << 63) : 0), y=((choice & 1) ? UINT64_MAX : 0);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_constant_ip i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_phi_pp(p,a,b,choice,&out.value); uint64_t x=((choice & 1) ? (uintptr_t)p : 0), y=((choice & 1) ? b : (uintptr_t)p);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_phi_pp i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_select_pp(p,a,b,choice,&out.value); uint64_t x=((choice & 1) ? (uintptr_t)p : 0), y=((choice & 1) ? b : (uintptr_t)p);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_select_pp i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_loop_pp(p,a,b,choice,&out.value); uint64_t x=((uintptr_t)p), y=(b + (choice & 7));
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_loop_pp i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_constant_pp(p,a,b,choice,&out.value); uint64_t x=((choice & 1) ? (uintptr_t)pointer_flow_data : 0), y=((choice & 1) ? UINT64_MAX : 0);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_constant_pp i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_phi_ii(p,a,b,choice,&out.value); uint64_t x=((choice & 1) ? a : b), y=((choice & 1) ? b : a);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_phi_ii i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_select_ii(p,a,b,choice,&out.value); uint64_t x=((choice & 1) ? a : b), y=((choice & 1) ? b : a);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_select_ii i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_loop_ii(p,a,b,choice,&out.value); uint64_t x=(a), y=(b + (choice & 7));
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_loop_ii i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_constant_ii(p,a,b,choice,&out.value); uint64_t x=((choice & 1) ? (UINT64_C(1) << 63) : 0), y=((choice & 1) ? UINT64_MAX : 0);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_constant_ii i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_global_phi(p,a,b,choice,&out.value); uint64_t x=((choice & 1) ? (uintptr_t)pointer_flow_data : 0), y=(b);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_global_phi i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_global_select(p,a,b,choice,&out.value); uint64_t x=((choice & 1) ? (uintptr_t)pointer_flow_data : 0), y=(b);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_global_select i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_constant_cast(p,a,b,choice,&out.value); uint64_t x=(UINT64_MAX), y=(b);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_constant_cast i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_global_call(p,a,b,choice,&out.value); uint64_t x=((uintptr_t)pointer_flow_data ^ b), y=(b);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_global_call i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_global_index(p,a,b,choice,&out.value); uint64_t x=(1 + 2 * (choice & 7)), y=(b);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_global_index i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_constant_gep(p,a,b,choice,&out.value); uint64_t x=(9), y=(b);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_constant_gep i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_global_load(p,a,b,choice,&out.value); uint64_t x=(1), y=(b);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_global_load i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
        memset(&out, 0xa5, sizeof(out));
        { Pair got=pointer_flow_global_offset(p,a,b,choice,&out.value); uint64_t x=((uintptr_t)(pointer_flow_data + 3)), y=(b);
          if (got.first!=x || got.second!=y || out.value!=(a ^ UINT64_C(0xdeadbeef12345678)) || out.before!=UINT64_C(0xa5a5a5a5a5a5a5a5) || out.after!=UINT64_C(0xa5a5a5a5a5a5a5a5)) {
            fprintf(stderr,"pointer_flow_global_offset i=%u j=%u got=%llx,%llx expected=%llx,%llx out=%llx\n",i,j,(unsigned long long)got.first,(unsigned long long)got.second,(unsigned long long)x,(unsigned long long)y,(unsigned long long)out.value); return 1; } ++observations; }
    }
    printf("pointer-flow observations=%u phi=select=loops=constants=globals=calls=live=guards=preserved\n", observations);
    return 0;
}
