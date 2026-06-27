extern int z_call_chain(int) __asm__("control_flow_calls.call_chain");
extern int z_loop_sum(int) __asm__("control_flow_calls.loop_sum");
int main(void) {
    if (z_call_chain(10) != 21) return 1;
    if (z_loop_sum(5) != 10) return 2;
    return 0;
}

