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

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
