//usr/bin/env zig run "$0" -- "$@"; exit
const std = @import("std");
const fs = std.fs;

const Sample = struct { file_name: []const u8, kb_size: u64 };

const EXAMPLES_PATH_PREFIX = "files/";
const FILES = [_]Sample{
    Sample{ .file_name = "1kb", .kb_size = 1 },
    Sample{ .file_name = "512kb", .kb_size = 512 },
    Sample{ .file_name = "1Mb", .kb_size = 1024 },
    Sample{ .file_name = "1Gb", .kb_size = 1024 * 1024 },
    Sample{ .file_name = "2Gb", .kb_size = 1024 * 1024 * 2 },
    Sample{ .file_name = "4Gb", .kb_size = 1024 * 1024 * 4 },
    Sample{ .file_name = "8Gb", .kb_size = 1024 * 1024 * 8 },
    Sample{ .file_name = "16Gb", .kb_size = 1024 * 1024 * 16 },
};

pub fn main() !void {
    std.debug.print("Generating sample files.\n", .{});
    for (FILES) |file| {
        std.debug.print("Writing file '{s}' of size {d}Kb.\n", .{ file.file_name, file.kb_size });
        try create_file_and_write_random_kb(file.file_name, file.kb_size);
    }
}

fn create_file_and_write_random_kb(file_name: []const u8, kb: u64) !void {
    var file = try create_file_to_write(file_name);
    defer file.close();
    try write_random_kb(file, kb);
}

fn create_file_to_write(file_name: []const u8) !fs.File {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var allocator = arena.allocator();
    try fs.cwd().makePath(EXAMPLES_PATH_PREFIX);
    const open_flags = fs.File.CreateFlags{};
    const path: []const u8 = try std.mem.concat(allocator, u8, &([_][]const u8{ EXAMPLES_PATH_PREFIX, file_name }));
    return try fs.cwd().createFile(path, open_flags);
}

fn write_random_kb(file: std.fs.File, kb: u64) !void {
    std.debug.assert(kb > 0);
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var allocator = arena.allocator();
    // Alloc one kb for buffered write.
    var chunk = try allocator.alloc(u8, 1024);
    var rand = std.rand.DefaultPrng.init(0);
    var i: usize = 0;
    while (i < kb) : (i += 1) {
        var j: usize = 0;
        while (j < 1024) : (j += 1)
            chunk[j] = if (rand.random().boolean()) '\n' else 'a';
        try file.writeAll(chunk);
    }
}
