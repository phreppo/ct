const std = @import("std");
const os = std.os;

const DEFAULT_NUMBER_OF_THREADS: u64 = 2;
const DEFAULT_CHUNKS_SIZE: u64 = 1024 * 1024;
const THREADS_LONG_FLAG: []const u8 = "--threads";
const THREADS_SHORT_FLAG: []const u8 = "-t";
const CHUNKS_LONG_FLAG: []const u8 = "--chunks-size";
const CHUNKS_SHORT_FLAG: []const u8 = "-c";

pub const Config = struct {
    file_name: []const u8 = "",
    threads: u64 = DEFAULT_NUMBER_OF_THREADS,
    chunks_size: u64 = DEFAULT_CHUNKS_SIZE,
};

pub const ParseArgsError = error{
    FilePathNotProvided,
};

pub fn parse_args() ParseArgsError!Config {
    var i: usize = 1;
    var config = Config{};
    var maybe_file_name: ?[]const u8 = null;
    var threads: u64 = DEFAULT_NUMBER_OF_THREADS;
    var chunks_size: u64 = DEFAULT_CHUNKS_SIZE;
    while (i < os.argv.len) : (i += 1) {
        const arg = manyPtrToSlice(os.argv[i]);
        if (std.mem.eql(u8, arg, THREADS_LONG_FLAG) or std.mem.eql(u8, arg, THREADS_SHORT_FLAG)) {
            // Set the threads.
            i += 1;
            threads = std.fmt.parseInt(u64, manyPtrToSlice(os.argv[i]), 10) catch unreachable;
            config.threads = threads;
        } else if (std.mem.eql(u8, arg, CHUNKS_LONG_FLAG) or std.mem.eql(u8, arg, THREADS_SHORT_FLAG)) {
            // Set the chunks.
            i += 1;
            chunks_size = std.fmt.parseInt(u64, manyPtrToSlice(os.argv[i]), 10) catch unreachable;
            config.chunks_size = chunks_size;
        } else {
            // Set the name of the file.
            maybe_file_name = arg;
        }
    }
    if (maybe_file_name) |file_name| {
        config.file_name = file_name;
        return config;
    } else {
        return error.FilePathNotProvided;
    }
}

fn manyPtrToSlice(ptr: [*:0]const u8) []const u8 {
    var l: usize = 0;
    var i: usize = 0;
    while (ptr[i] != 0) : (i += 1) l += 1;
    return ptr[0..l];
}

pub fn printErrorMessage(err: ParseArgsError) void {
    switch (err) {
        error.FilePathNotProvided => {
            const stderr = std.io.getStdErr().writer();
            stderr.print("Must provide an input file.\n", .{}) catch std.os.exit(1);
        },
    }
    printHelpMessage() catch std.os.exit(1);
}

pub fn printHelpMessage() !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.print("usage: cnt [OPTIONS] [input]\n", .{});
    try stderr.print("OPTIONS\n", .{});
    try stderr.print("\t{s},{s} <threads>\t\tSets the number of threads to use.\n", .{ THREADS_LONG_FLAG, THREADS_SHORT_FLAG });
    try stderr.print("\t{s},{s} <chunks-size>\tSets the size of the chunks allocated.\n", .{ CHUNKS_LONG_FLAG, CHUNKS_SHORT_FLAG });
    try stderr.print("ARGS\n", .{});
    try stderr.print("\t<input>\t\tPath to the input file.\n", .{});
}
