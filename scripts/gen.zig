//usr/bin/env zig run "$0" -- "$@"; exit
const std = @import("std");
const fs = std.fs;

const EXAMPLES_PATH_PREFIX = "files/";

pub fn main() !void {
    std.debug.print("I am a script!\n", .{});
    var file = try create_file("salve");
    defer file.close();
}

// TODO: finire questa cosa.
pub fn create_file(file_name: []const u8, size: u64) !fs.File {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var allocator = arena.allocator();
    try fs.cwd().makePath(EXAMPLES_PATH_PREFIX);
    const open_flags = fs.File.CreateFlags{};
    const path: []const u8 = try std.mem.concat(allocator, u8, &([_][]const u8{ EXAMPLES_PATH_PREFIX, file_name }));
    return try fs.cwd().createFile(path, open_flags);
}
