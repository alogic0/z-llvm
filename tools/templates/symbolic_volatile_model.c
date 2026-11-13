extern unsigned char symbolic_volatile_plain[8192];
static unsigned char *symbolic_volatile_quoted_address(void){unsigned char *p;__asm__("leaq \"symbolic volatile storage\"(%%rip),%0":"=r"(p));return p;}
static unsigned char *volatile_base,*volatile_expected;static size_t volatile_width,volatile_window;
__attribute__((noinline)) void complete_volatile_change(void *p,uint64_t bytes){if(p!=volatile_expected||bytes!=volatile_width)abort();for(size_t i=0;i<bytes;i++)((unsigned char *)p)[i]^=0x5a;}
__attribute__((noinline)) void complete_volatile_snapshot(void *out){memcpy(out,volatile_base+volatile_window,128);}
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)input;(void)expected;size_t bytes=item->bits?item->bits/8:8,offset=item->kind%8192;volatile_base=item->kind/8192?symbolic_volatile_quoted_address():symbolic_volatile_plain;
    if(sysconf(_SC_PAGESIZE)!=4096||((uintptr_t)volatile_base&4095)||mprotect(volatile_base+4096,4096,PROT_NONE))abort();
    for(size_t i=0;i<4096;i++)volatile_base[i]=(unsigned char)((seed*37+i*19)^(i>>3));volatile_expected=volatile_base+offset;volatile_width=bytes;volatile_window=offset>64?offset-64:0;if(volatile_window>3968)volatile_window=3968;
    memcpy(gold,volatile_expected,bytes);for(size_t i=0;i<bytes;i++)gold[bytes+i]=gold[i]^0x5a;uint64_t token=clobber_model(salt);memcpy(gold+2*bytes,&token,8);memcpy(gold+2*bytes+8,volatile_base+volatile_window,128);
    for(size_t i=0;i<bytes;i++)gold[2*bytes+8+offset-volatile_window+i]^=0x5a;
    return (struct test_model){1,1,2*bytes+8+128,SIZE_MAX,255,token};
}
