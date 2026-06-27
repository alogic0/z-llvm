extern int z_expanded_optional_branch(int, int) __asm__("expanded_branch_arrays.expanded_optional_branch");
int main(void) {
    if (z_expanded_optional_branch(1, 11) != 11) return 1;
    if (z_expanded_optional_branch(0, 11) != -5) return 2;
    return 0;
}

