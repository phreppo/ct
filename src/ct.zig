const std = @import("std");
const fs = std.fs;
const heap = std.heap;
const os = std.os;
const args = @import("./args.zig");

const Task = struct {
    /// Name of the file to open.
    file_name: []const u8,
    /// Size to use for the chunk.
    chunk_size: u64, 
    /// Offset in the input file.
    from: u64, 
    /// Number of bytes to read.
    len: u64, 
    /// Address for writing the answer for the ask.
    answer: *u64 
};

pub fn run(config: args.Config) !u64 {
    // TODO: the last thread should be executed in the current thread, without spawning a new one.
    const file_size = try getFileSize(config.file_name);
    if (file_size == 0) return 0;

    // We set the number of threads to be the minimum between what was provided by the user and the file size.
    // If the file size is less than the number of threads and we ignore this, where are divisions by zero.
    const nthreads = std.math.min(config.threads, file_size);
    const avg_size = file_size / nthreads;

    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    var alloc = arena.allocator();
    var answers: std.ArrayList(u64) = std.ArrayList(u64).init(alloc);
    var i: u64 = 0;
    while (i < nthreads) : (i += 1) {
        try answers.append(0);
    }
    var tasks = std.ArrayList(Task).init(alloc);
    var initial_offset: u64 = 0;
    i = 0;
    while (i < nthreads) : (i += 1) {
        const reminder: u64 = try std.math.rem(u64, file_size, avg_size);
        var current_size: u64 = avg_size;
        if (i < reminder) current_size += 1;
        const task = Task{ 
            .file_name = config.file_name, 
            .chunk_size = config.chunks_size, 
            .from = initial_offset, 
            .len = current_size, 
            .answer = &(answers.items[i]) 
        };
        try tasks.append(task);
        initial_offset += current_size;
    }
    var threads: std.ArrayList(std.Thread) = std.ArrayList(std.Thread).init(alloc);
    i = 0;
    for (tasks.items) |task| {
        var thread = try std.Thread.spawn(.{}, workerFunction, .{task});
        try threads.append(thread);
    }
    for (threads.items) |thread| thread.join();
    var lines: u64 = 0;
    for (answers.items) |answer| lines += answer;
    return lines;
}

pub fn getFileSize(file_name: []const u8) !u64 {
    var file: fs.File = try fs.cwd().openFile(file_name, fs.File.OpenFlags{});
    defer file.close();
    const stat = try file.stat();
    return stat.size;
}

// Worker function run by each thread.
fn workerFunction(task: Task) !void {
    const lines = try countLinesChunk(task.file_name, task.from, task.len, task.chunk_size);
    task.answer.* = lines;
}

pub fn countLinesChunk(file_name: []const u8, from: u64, len: u64, chunk_size: u64) !u64 {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    var alloc = arena.allocator();
    const actual_chunk_size = if (len >= chunk_size) chunk_size else len;
    var chunk = try alloc.alloc(u8, actual_chunk_size);
    const open_flags = fs.File.OpenFlags{ .lock = .Shared, .lock_nonblocking = true };
    var file = try fs.cwd().openFile(file_name, open_flags);
    try file.seekTo(from);
    var reader = file.reader();
    var bytes_read: usize = 0;
    var lines: u64 = 0;
    while (bytes_read < len) {
        var current_bytes_read = try reader.readAll(chunk);
        bytes_read += current_bytes_read;
        for (chunk[0..current_bytes_read]) |c| {
            if (c == '\n') {
                lines += 1;
            }
        }
    }
    return lines;
}

const testing = std.testing;
test "six lines" {
    const conf: args.Config = args.Config{
        .file_name = "tests/five-lines.txt",
    };
    try testing.expectEqual(@as(u64, 5), try run(conf));
}
test "zero lines" {
    const conf: args.Config = args.Config{
        .file_name = "tests/zero-lines.txt",
    };
    try testing.expectEqual(@as(u64, 0), try run(conf));
}
test "zero lines non-empty" {
    const conf: args.Config = args.Config{
        .file_name = "tests/zero-non-empty.txt",
    };
    try testing.expectEqual(@as(u64, 0), try run(conf));
}
