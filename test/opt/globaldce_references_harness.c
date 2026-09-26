#include <assert.h>
#include <stdio.h>

extern int dce_export(void);
extern int (*dce_alias_pointer(void))(void);
extern int dce_call_callback(void);
extern int dce_read_array(void);
extern int dce_read_expression(void);

int main(void) {
    assert(dce_export() == 19);
    assert(dce_alias_pointer()() == 19);
    assert(dce_call_callback() == 19);
    assert(dce_read_array() == 23);
    assert(dce_read_expression() == 23);
    puts("ok GlobalDCE references: 5 entry points");
    return 0;
}
