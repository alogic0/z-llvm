extern long long z_i64_value(void) __asm__("i64_arithmetic.i64_value");
int main(void) {
    return z_i64_value() == 4 ? 0 : 1;
}

