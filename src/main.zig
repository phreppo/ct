const std = @import("std");
const fs = std.fs;
const heap = std.heap;
const os = std.os;

const DEFAULT_CHUNK_SIZE: u64 = 1024 * 32;
const DEFAULT_NUMBER_OF_THREADS: u32 = 2;

const Task = struct { file_name: []const u8, chunk_size: u64, from: u64, len: u64, answer: *u64 };

// Worker function run by each thread.
fn workerFunction(task: Task) !void {
    const lines = try countLinesChunk(task.file_name, task.from, task.len, task.chunk_size);
    std.debug.print("{any}: {d}\n", .{ task, lines });
    task.answer.* = lines;
}

pub fn main() !void {
    if (os.argv.len != 3) {
        std.debug.print("Must supply exactly two argument.\n", .{});
        os.exit(1);
    }

    const file_name: []const u8 = manyPtrToSlice(os.argv[1]);
    std.debug.print("File: {s}\n", .{file_name});
    const file_size = try getFileSize(file_name);
    std.debug.print("File size: {d} bytes\n", .{file_size});
    // var timer = try std.time.Timer.start();
    const nthreads: u64 = try std.fmt.parseInt(u64, manyPtrToSlice(os.argv[2]), 10);
    std.debug.print("Using {d} threads.\n", .{nthreads});
    // const lines = try countLinesByte(file_name, 0, file_size);
    // var countLinesByteTime = timer.lap() / 100_000;
    // std.debug.print("countLinesByte lines: {d}\n", .{lines});
    // std.debug.print("countLinesByte time(ms): {d}\n", .{countLinesByteTime});
    // timer.reset();
    // const linesReadline = try countLinesReadline(file_name, 0, file_size, 51200);
    // var countLinesReadlineTime = timer.lap() / 100_000;
    // std.debug.print("countLinesReadline lines: {d}\n", .{linesReadline});
    // std.debug.print("countLinesReadline time(ms): {d}\n", .{countLinesReadlineTime});
    // timer.reset();
    // const linesChunk = try countLinesChunk(file_name, 0, file_size, 51200);
    // var countLinesChunkTime = timer.lap() / 100_000;
    // std.debug.print("countLinesChunk lines: {d}\n", .{linesChunk});
    // std.debug.print("countLinesChunk time(ms): {d}\n", .{countLinesChunkTime});
    // const nthreads: u32 = DEFAULT_NUMBER_OF_THREADS;
    const avg_size = file_size / nthreads;
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    var alloc = arena.allocator();
    var answers: std.ArrayList(u64) = std.ArrayList(u64).init(alloc);
    var j: u64 = 0;
    while (j < nthreads) : (j += 1) {
        try answers.append(0);
    }
    var tasks = std.ArrayList(Task).init(alloc);
    var initial_offset: u64 = 0;
    var i: u32 = 0;
    while (i < nthreads) : (i += 1) {
        const reminder: u64 = try std.math.rem(u64, file_size, avg_size);
        var current_size: u64 = avg_size;
        if (i < reminder) {
            current_size += 1;
        }
        const task = Task{ .file_name = file_name, .chunk_size = DEFAULT_CHUNK_SIZE, .from = initial_offset, .len = current_size, .answer = &(answers.items[i]) };
        try tasks.append(task);
        initial_offset += current_size;
    }
    var threads: std.ArrayList(std.Thread) = std.ArrayList(std.Thread).init(alloc);
    i = 0;
    for (tasks.items) |task| {
        var thread = try std.Thread.spawn(.{}, workerFunction, .{task});
        try threads.append(thread);
    }
    for (threads.items) |thread| {
        thread.join();
    }
    var lines: u64 = 0;
    for (answers.items) |answer| {
        lines += answer;
    }
    std.debug.print("Lines: {d}\n", .{lines});
}

fn manyPtrToSlice(ptr: [*:0]const u8) []const u8 {
    var l: usize = 0;
    var i: usize = 0;
    while (ptr[i] != 0) : (i += 1) l += 1;
    return ptr[0..l];
}

pub fn getFileSize(file_name: []const u8) !u64 {
    var file: fs.File = try fs.cwd().openFile(file_name, fs.File.OpenFlags{});
    defer file.close();
    const stat = try file.stat();
    return stat.size;
}

pub fn countLinesByte(file_name: []const u8, from: u64, len: u64) !u64 {
    var file = try fs.cwd().openFile(file_name, fs.File.OpenFlags{});
    try file.seekTo(from);
    var reader = file.reader();
    var i: u64 = 0;
    var lines: u64 = 0;
    while (i < len) : (i += 1) {
        var c = reader.readByte() catch return lines;
        if (c == '\n') {
            lines += 1;
        }
    }
    return lines;
}

pub fn countLinesReadline(file_name: []const u8, from: u64, len: u64, chunk_size: u64) !u64 {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    var alloc = arena.allocator();
    var chunk = try alloc.alloc(u8, chunk_size);
    var file = try fs.cwd().openFile(file_name, fs.File.OpenFlags{});
    try file.seekTo(from);
    var reader = file.reader();
    var i: u64 = 0;
    var lines: u64 = 0;
    while (i < len) : (i += 1) {
        _ = reader.readUntilDelimiter(chunk, '\n') catch return lines;
        lines += 1;
    }
    return lines;
}

pub fn countLinesChunk(file_name: []const u8, from: u64, len: u64, chunk_size: u64) !u64 {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    var alloc = arena.allocator();
    const actual_chunk_size = if (len >= chunk_size) chunk_size else len;
    var chunk = try alloc.alloc(u8, actual_chunk_size);
    var file = try fs.cwd().openFile(file_name, fs.File.OpenFlags{ .lock = .Shared, .lock_nonblocking = true });
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
test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
