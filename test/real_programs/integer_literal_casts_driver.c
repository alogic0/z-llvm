#define _GNU_SOURCE
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
extern uint64_t integer_literal_casts(unsigned char *,uint64_t,uint64_t);
static void fail(const char *what) { fprintf(stderr,"literal-casts failure: %s\n",what); exit(1); }
int main(int argc,char **argv) {
    int fault=argc>1?atoi(argv[1]):0;
    if(fault<0 || fault>3) return 2;
    size_t page=(size_t)sysconf(_SC_PAGESIZE);
    unsigned char *map=mmap(0,page*2,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    if(map==MAP_FAILED || mprotect(map+page,page,PROT_NONE)) fail("mapping");
    unsigned char *out=map+page-186*8;
    const unsigned widths[]={2,3,6,7,9,15,17,31,33,47,52,62,63},destinations[]={8,16,32,64};
    uint64_t observations=0;
    for(unsigned sample=0;sample<128;sample++) {
        uint64_t salt=UINT64_C(0xd34a76c5890bf21e)*sample,seed=~salt;
        memset(out,0xa6,186*8);out[-1]=0x5b;
        uint64_t actual=integer_literal_casts(out,salt,seed);
        if(fault==1) actual^=1;
        if(fault==2) out[0]^=1;
        if(fault==3) out[-1]^=1;
        if(fault) fprintf(stderr,"fault=%d\n",fault);
        if(actual!=(seed^salt) || out[-1]!=0x5b) fail("return, live inputs or exact prefix");
        observations++;
        unsigned index=0;
        for(unsigned bi=0;bi<sizeof widths/sizeof widths[0];bi++) {
            unsigned bits=widths[bi];
            int64_t sign=INT64_C(1)<<(bits-1);
            uint64_t mask=(UINT64_C(1)<<bits)-1;
            const int64_t literals[]={0,1,-1,-sign,sign-1,(int64_t)mask};
            for(unsigned di=0;di<4;di++) if(destinations[di]>bits) for(unsigned v=0;v<6;v++) {
                uint64_t expected=(((uint64_t)literals[v]&mask)^salt)+seed,value;
                memcpy(&value,out+index*8,8);
                if(value!=expected) fail("source-width bit pattern");
                observations++;index++;
            }
        }
        if(index!=186) fail("case count");
    }
    if(munmap(map,page*2) || observations!=23936) fail("final accounting");
    printf("literal-casts observations=%llu odd-width-source-bits=native-destinations=live-values=guard-pages=preserved\n",(unsigned long long)observations);
    return 0;
}
