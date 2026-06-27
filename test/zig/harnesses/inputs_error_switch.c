extern int z_error_switch(unsigned char) __asm__("error_switch.error_switch");
int main(void) {
    if (z_error_switch(0) != 0) return 1;
    if (z_error_switch(1) != -1) return 2;
    if (z_error_switch(2) != -2) return 3;
    return 0;
}

