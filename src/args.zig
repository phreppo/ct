const std = @import("std");
const mem = std.mem;
const os = std.os;

const DEFAULT_NUMBER_OF_THREADS: u64 = 1;
const DEFAULT_CHUNKS_SIZE: u64 = 1024 * 1024 * 2; // 2Mb by default.
const THREADS_LONG_FLAG: []const u8 = "--threads";
const THREADS_SHORT_FLAG: []const u8 = "-t";
const CHUNKS_LONG_FLAG: []const u8 = "--chunks-size";
const CHUNKS_SHORT_FLAG: []const u8 = "-c";

pub const Config = struct {
    file_name: []const u8,
    threads: u64 = DEFAULT_NUMBER_OF_THREADS,
    chunks_size: u64 = DEFAULT_CHUNKS_SIZE,
};

pub const ParseArgsError = error{ 
    /// The user did not provide an input file.
    FilePathNotProvided, 
    /// The user did not provide an argument for the thread option.
    ThreadOptionExpectsArgument, 
    /// The user did not provide an integer argument for the thread option.
    ThreadOptionExpectsInteger, 
    /// The user did not provide an argument for the chunks size option.
    ChunksSizeOptionExpectsArgument, 
    /// The user did not provide an integer argument for the chunks size option.
    ChunksSizeOptionExpectsInteger 
};

pub fn parse_args() ParseArgsError!Config {
    var i: usize = 1;
    var maybe_file_name: ?[]const u8 = null;
    var threads: u64 = DEFAULT_NUMBER_OF_THREADS;
    var chunks_size: u64 = DEFAULT_CHUNKS_SIZE;
    while (i < os.argv.len) : (i += 1) {
        const arg: []const u8 = mem.span(os.argv[i]);
        if (mem.eql(u8, arg, THREADS_LONG_FLAG) or mem.eql(u8, arg, THREADS_SHORT_FLAG)) {
            // Set the threads.
            i += 1;
            if (os.argv.len >= i) return error.ThreadOptionExpectsArgument;
            threads = std.fmt.parseInt(u64, mem.span(os.argv[i]), 10) catch return error.ThreadOptionExpectsInteger;
        } else if (mem.eql(u8, arg, CHUNKS_LONG_FLAG) or mem.eql(u8, arg, CHUNKS_SHORT_FLAG)) {
            // Set the chunks.
            i += 1;
            if (os.argv.len >= i) return error.ChunksSizeOptionExpectsArgument;
            chunks_size = std.fmt.parseInt(u64, mem.span(os.argv[i]), 10) catch return error.ChunksSizeOptionExpectsInteger;
        } else {
            // Set the name of the file.
            maybe_file_name = arg;
        }
    }
    if (maybe_file_name) |file_name| {
        return Config{
            .file_name = file_name,
            .threads = threads,
            .chunks_size = chunks_size,
        };
    } else return error.FilePathNotProvided;
}

pub fn printErrorMessage(err: ParseArgsError, writer: std.fs.File.Writer) !void {
    switch (err) {
        error.FilePathNotProvided => {
            try writer.print("Must provide an input file.\n", .{});
        },
        error.ThreadOptionExpectsArgument, error.ThreadOptionExpectsInteger => {
            try writer.print("{s} and {s} options expect an integer argument.\n", .{ THREADS_LONG_FLAG, THREADS_SHORT_FLAG });
        },
        error.ChunksSizeOptionExpectsArgument, error.ChunksSizeOptionExpectsInteger => {
            try writer.print("{s} and {s} options expect an integer argument.\n", .{ CHUNKS_LONG_FLAG, CHUNKS_SHORT_FLAG });
        },
    }
    try writer.print("\n", .{});
    try printHelpMessage(writer);
}

pub fn printHelpMessage(writer: std.fs.File.Writer) !void {
    try writer.print("usage: ct [OPTIONS] [input]\n", .{});
    try writer.print("OPTIONS\n", .{});
    try writer.print("\t{s},{s} <threads>\t\tSets the number of threads to use. (default: {d})\n", .{ THREADS_LONG_FLAG, THREADS_SHORT_FLAG, DEFAULT_NUMBER_OF_THREADS });
    try writer.print("\t{s},{s} <chunks-size>\tSets the size (in bytes) of the chunks allocated. (default: {d})\n", .{ CHUNKS_LONG_FLAG, CHUNKS_SHORT_FLAG, DEFAULT_CHUNKS_SIZE });
    try writer.print("ARGS\n", .{});
    try writer.print("\t<input>\t\tPath to the input file.\n", .{});
}
