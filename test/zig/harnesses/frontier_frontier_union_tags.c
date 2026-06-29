extern int z_frontier_union_tag_match(int, int) __asm__("frontier_union_tags.frontier_union_tag_match");

int main(void) {
    if (z_frontier_union_tag_match(0, 35) != 42) return 1;
    if (z_frontier_union_tag_match(1, 26) != 42) return 2;
    return 0;
}
