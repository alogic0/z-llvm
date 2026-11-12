#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
extern uint64_t module_alias_a(uint64_t);
extern uint64_t module_alias_b(uint64_t);
extern uint64_t module_alias_existing(uint64_t);
extern uint64_t module_alias_seen;
int main(int argc,char **argv) {
    unsigned fault=argc>1 ? (unsigned)strtoul(argv[1],NULL,10) : 0;
    size_t observations=0;
#define CHECK(c) do { ++observations; if(!(c)) { fprintf(stderr,"module-asm-aliases fault=%u observation=%zu\n",fault,observations); return 1; } } while(0)
    uint64_t (*volatile a)(uint64_t)=module_alias_a;
    uint64_t (*volatile b)(uint64_t)=module_alias_b;
    uint64_t (*volatile original)(uint64_t)=module_alias_existing;
    uintptr_t b_address=(uintptr_t)b;
    if(fault==2) b_address^=1;
    CHECK((uintptr_t)a==b_address);
    CHECK(a==original);
    for(uint64_t seed=0;seed<64;seed++) {
        uint64_t value=seed*UINT64_C(0x9e3779b97f4a7c15);
        uint64_t first=a(value);
        if(fault==1) first^=1;
        CHECK(first==value+99);
        CHECK(b(value)==value+99);
        CHECK(original(value)==value+99);
        if(fault==3) module_alias_seen^=1;
        CHECK(module_alias_seen==value);
    }
    printf("module-asm-aliases observations=%zu chains=binding=execution=preserved\n",observations);
    return 0;
}
