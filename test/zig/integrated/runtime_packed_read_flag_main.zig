const Flags = packed struct {
    low: u3,
    high: u4,
    set: bool,
};

export fn main() c_int {
    return if (readFlag(0x80)) 0 else 1;
}

fn readFlag(raw: u8) bool {
    const flags: Flags = @bitCast(raw);
    return flags.set;
}
