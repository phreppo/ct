const std = @import("std");
const fs = std.fs;
const heap = std.heap;
const os = std.os;
const args = @import("./args.zig");
const cnt = @import("./cnt.zig");

pub fn main() !void {
    if (args.parse_args()) |config| {
        const lines = try cnt.run(config);
        const stdout = std.io.getStdOut().writer();
        try stdout.print("{d}\n", .{lines});
    } else |err| {
        args.printErrorMessage(err, std.io.getStdErr().writer());
        std.os.exit(1);
    }
}
