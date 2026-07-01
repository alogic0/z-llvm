extern int z_frontier_union_tag_match(int, int) __asm__("frontier_union_tags.frontier_union_tag_match");
extern int z_frontier_union_tag_reversed_arms(int, int) __asm__("frontier_union_tags.frontier_union_tag_reversed_arms");
extern int z_frontier_union_tag_small_payload_add(int, int) __asm__("frontier_union_tags.frontier_union_tag_small_payload_add");
extern int z_frontier_union_tag_reordered_fields(int, int) __asm__("frontier_union_tags.frontier_union_tag_reordered_fields");
extern int z_frontier_union_init_tag_only(int, int) __asm__("frontier_union_tags.frontier_union_init_tag_only");

int main(void) {
    if (z_frontier_union_tag_match(0, 35) != 42) return 1;
    if (z_frontier_union_tag_match(1, 26) != 42) return 2;
    if (z_frontier_union_tag_reversed_arms(0, 33) != 42) return 3;
    if (z_frontier_union_tag_reversed_arms(1, 26) != 42) return 4;
    if (z_frontier_union_tag_small_payload_add(0, 33) != 42) return 5;
    if (z_frontier_union_tag_small_payload_add(1, 26) != 42) return 6;
    if (z_frontier_union_tag_reordered_fields(0, 33) != 42) return 7;
    if (z_frontier_union_tag_reordered_fields(1, 26) != 42) return 8;
    if (z_frontier_union_init_tag_only(0, 9) != 41) return 9;
    if (z_frontier_union_init_tag_only(1, 9) != 42) return 10;
    return 0;
}
