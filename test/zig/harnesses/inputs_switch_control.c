#include <stdbool.h>
extern int z_dense_switch(int) __asm__("switch_control.dense_switch");
extern int z_branch_mix(int, int, bool) __asm__("switch_control.branch_mix");
int main(void) {
    if (z_dense_switch(0) != 11) return 1;
    if (z_dense_switch(2) != 17) return 2;
    if (z_dense_switch(99) != 23) return 3;
    if (z_branch_mix(10, 3, true) != 13) return 4;
    if (z_branch_mix(10, 3, false) != 7) return 5;
    return 0;
}

