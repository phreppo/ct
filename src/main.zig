const std = @import("std");
const fs = std.fs;
const heap = std.heap;
const os = std.os;
const args = @import("./args.zig");
const ct = @import("./ct.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var allocator = arena.allocator();
    defer arena.deinit();
    if (args.parse_args(allocator)) |config| {
        defer config.deinit();
        try ct.run(config);
    } else |err| {
        try args.printErrorMessage(err, std.io.getStdErr().writer());
        if (err != error.WantsHelp) {
            std.os.exit(1);
        }
    }
}
