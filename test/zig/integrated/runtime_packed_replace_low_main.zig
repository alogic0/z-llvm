const Flags = packed struct {
    low: u3,
    high: u4,
    set: bool,
};

export fn main() c_int {
    return if (replaceLow(0xff, 5) == 0xfd) 0 else 1;
}

fn replaceLow(raw: u8, replacement: u8) u8 {
    var flags: Flags = @bitCast(raw);
    flags.low = @truncate(replacement);
    return @bitCast(flags);
}
