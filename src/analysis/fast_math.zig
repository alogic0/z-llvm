const ir = @import("../ir.zig");

pub fn noNaNs(flags: ir.FastMathFlags) bool {
    return flags.fast or flags.nnan;
}

pub fn noInfs(flags: ir.FastMathFlags) bool {
    return flags.fast or flags.ninf;
}

pub fn noSignedZeros(flags: ir.FastMathFlags) bool {
    return flags.fast or flags.nsz;
}

pub fn allowReciprocal(flags: ir.FastMathFlags) bool {
    return flags.fast or flags.arcp;
}

pub fn allowContract(flags: ir.FastMathFlags) bool {
    return flags.fast or flags.contract;
}

pub fn approximateFunctions(flags: ir.FastMathFlags) bool {
    return flags.fast or flags.afn;
}

pub fn allowReassociation(flags: ir.FastMathFlags) bool {
    return flags.fast or flags.reassoc;
}

pub fn allowAddZeroFold(flags: ir.FastMathFlags) bool {
    return noSignedZeros(flags);
}

pub fn allowSelfOrderedCompareFold(flags: ir.FastMathFlags) bool {
    return noNaNs(flags);
}

pub fn allowFpValueNumbering(flags: ir.FastMathFlags) bool {
    _ = flags;
    return true;
}

pub fn sameFlags(a: ir.FastMathFlags, b: ir.FastMathFlags) bool {
    return a.fast == b.fast and
        a.nnan == b.nnan and
        a.ninf == b.ninf and
        a.nsz == b.nsz and
        a.arcp == b.arcp and
        a.contract == b.contract and
        a.afn == b.afn and
        a.reassoc == b.reassoc;
}

pub fn intersect(a: ir.FastMathFlags, b: ir.FastMathFlags) ir.FastMathFlags {
    var result: ir.FastMathFlags = .{
        .nnan = noNaNs(a) and noNaNs(b),
        .ninf = noInfs(a) and noInfs(b),
        .nsz = noSignedZeros(a) and noSignedZeros(b),
        .arcp = allowReciprocal(a) and allowReciprocal(b),
        .contract = allowContract(a) and allowContract(b),
        .afn = approximateFunctions(a) and approximateFunctions(b),
        .reassoc = allowReassociation(a) and allowReassociation(b),
    };
    if (result.nnan and result.ninf and result.nsz and result.arcp and
        result.contract and result.afn and result.reassoc)
    {
        result = .{ .fast = true };
    }
    return result;
}
