const std = @import("std");
const fs = std.fs;
const heap = std.heap;
const os = std.os;
const args = @import("./args.zig");
const ct = @import("./ct.zig");

pub fn main() !void {
    if (args.parse_args()) |config| {
        const lines = try ct.run(config);
        const stdout = std.io.getStdOut().writer();
        try stdout.print("{d}\n", .{lines});
    } else |err| {
        try args.printErrorMessage(err, std.io.getStdErr().writer());
        std.os.exit(1);
    }
}
