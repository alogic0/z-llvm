struct Inner { int a; int b; };
struct Outer { struct Inner left; struct Inner right; };
extern int z_frontier_record_sum(int, int) __asm__("frontier_nested_records.frontier_record_sum");
extern int z_frontier_record_update(int, int) __asm__("frontier_nested_records.frontier_record_update");
extern int z_frontier_nested_field_left_b(const struct Outer *) __asm__("frontier_nested_records.frontier_nested_field_left_b");
extern int z_frontier_nested_field_right_a(const struct Outer *) __asm__("frontier_nested_records.frontier_nested_field_right_a");
extern unsigned long z_frontier_aggregate_init_tuple_sum(unsigned long, unsigned long) __asm__("frontier_nested_records.frontier_aggregate_init_tuple_sum");
extern unsigned long z_frontier_aggregate_projection_tuple_second(unsigned long, unsigned long) __asm__("frontier_nested_records.frontier_aggregate_projection_tuple_second");
int main(void) {
    const struct Outer record = { { 10, 20 }, { 30, 40 } };
    if (z_frontier_record_sum(11, 31) != 42) return 1;
    if (z_frontier_record_update(1, 10) != 11) return 2;
    if (z_frontier_record_update(0, 10) != 12) return 3;
    if (z_frontier_nested_field_left_b(&record) != 20) return 4;
    if (z_frontier_nested_field_right_a(&record) != 30) return 5;
    if (z_frontier_aggregate_init_tuple_sum(17UL, 25UL) != 42UL) return 6;
    if (z_frontier_aggregate_projection_tuple_second(99UL, 37UL) != 37UL) return 7;
    return 0;
}
