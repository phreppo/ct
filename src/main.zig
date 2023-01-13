const std = @import("std");
const fs = std.fs;
const heap = std.heap;
const os = std.os;
const args = @import("./args.zig");
const cnt = @import("./cnt.zig");

pub fn main() !void {
    var parsed_config: args.ParseArgsError!args.Config = args.parse_args();
    if (parsed_config) |config| {
        try cnt.run(config);
    } else |err| {
        args.printErrorMessage(err);
        std.os.exit(1);
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
