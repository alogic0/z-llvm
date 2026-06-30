extern int z_frontier_union_tag_match(int, int) __asm__("frontier_union_tags.frontier_union_tag_match");
extern int z_frontier_union_tag_reversed_arms(int, int) __asm__("frontier_union_tags.frontier_union_tag_reversed_arms");
extern int z_frontier_union_tag_small_payload_add(int, int) __asm__("frontier_union_tags.frontier_union_tag_small_payload_add");

int main(void) {
    if (z_frontier_union_tag_match(0, 35) != 42) return 1;
    if (z_frontier_union_tag_match(1, 26) != 42) return 2;
    if (z_frontier_union_tag_reversed_arms(0, 33) != 42) return 3;
    if (z_frontier_union_tag_reversed_arms(1, 26) != 42) return 4;
    if (z_frontier_union_tag_small_payload_add(0, 33) != 42) return 5;
    if (z_frontier_union_tag_small_payload_add(1, 26) != 42) return 6;
    return 0;
}
