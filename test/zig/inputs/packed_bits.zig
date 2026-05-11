const Flags = packed struct {
    low: u3,
    high: u4,
    set: bool,
};

export fn read_flag(raw: u8) bool {
    const flags: Flags = @bitCast(raw);
    return flags.set;
}

export fn replace_low(raw: u8, value: u8) u8 {
    var flags: Flags = @bitCast(raw);
    flags.low = @truncate(value);
    return @bitCast(flags);
}
