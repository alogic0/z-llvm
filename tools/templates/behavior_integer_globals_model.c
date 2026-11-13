static uint64_t previous_salt;
static struct test_model oracle(const struct test_case *item,unsigned seed,uint64_t salt,unsigned char *input,unsigned char *expected,unsigned char *gold){
    (void)item;(void)seed;(void)input;(void)expected;size_t at=0;
    const unsigned char pair[]={0x44,0x33,0x22,0x11,0xff,0xff,0xff,0xff};memcpy(gold+at,pair,8);at+=8;
    unsigned char nested[64]={0};nested[0]=7;nested[48]=9;
    for(unsigned v=0;v<2;v++)for(unsigned lane=0;lane<3;lane++){uint32_t n=v*3+lane+1;memcpy(nested+16+v*16+lane*4,&n,4);}
    memcpy(gold+at,nested,64);at+=64;gold[at++]=13;
    const unsigned char packed[]={0x41,0x0c,2,0};memcpy(gold+at,packed,4);at+=4;
    const unsigned char strings[]={0x7b,0x2c,0x58,7,0x7d,0x2c,0x59,9};memcpy(gold+at,strings,8);at+=8;
    uint32_t writable=123,readonly=456;memcpy(gold+at,&writable,4);at+=4;memcpy(gold+at,&readonly,4);at+=4;
    uint64_t answer=previous_salt^salt;previous_salt=salt;
    if(at!=93)abort();return (struct test_model){1,1,93,SIZE_MAX,255,answer};
}
extern const unsigned char *integer_globals_readonly(void);
static int readonly_global_is_protected(void){
    const unsigned char *p=integer_globals_readonly();
    if(((uintptr_t)p&15)!=0)return 0;
    pid_t child=fork();if(child<0)return 0;if(child==0){struct rlimit no_core={0,0};if(setrlimit(RLIMIT_CORE,&no_core))_exit(2);*(volatile unsigned char *)(uintptr_t)p^=1;_exit(0);}
    int status;if(waitpid(child,&status,0)!=child)return 0;
    return WIFSIGNALED(status)&&WTERMSIG(status)==11;
}
