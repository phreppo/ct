const std = @import("std");
const fs = std.fs;
const heap = std.heap;

const DEFAULT_CHUNK_SIZE: u64 = 15;
const DEFAULT_NUMBER_OF_THREADS: u32 = 2;

const Task = struct { file_name: []const u8, chunk_size: u64, offset: u64, len: u64 };

// Worker function run by each thread.
fn workerFunction(task: Task) !void {
    var file: fs.File = try fs.cwd().openFile(task.file_name, fs.File.OpenFlags{});
    defer file.close();
    try file.seekTo(task.offset);
    // Prepare the source data structure.
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var arena_allocator = arena.allocator();
    var source = std.ArrayList(u8).init(arena_allocator);
    defer source.deinit();

    // Reas just the first chunk.
    const reader = file.reader();
    var buffer: []u8 = try arena_allocator.alloc(u8, task.chunk_size);
    var bytes_read: usize = try reader.read(buffer);
    std.debug.print("worker:\n{s}\n", .{buffer[0..bytes_read]});
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

pub fn countLinesChunk(file_name: []const u8, from: u64, len: u64, chunk_size: u64) !u64 {
    var arena = heap.ArenaAllocator.init(heap.page_allocator);
    var alloc = arena.allocator();
    var chunk = try alloc.alloc(u8, chunk_size);
    var file = try fs.cwd().openFile(file_name, fs.File.OpenFlags{});
    try file.seekTo(from);
    var reader = file.reader();
    var bytes_read: usize = 0;
    var lines: u64 = 0;
    while (bytes_read < len) {
        bytes_read += try reader.read(chunk);
        for (chunk) |c| {
            if (c == '\n') {
                lines += 1;
            }
        }
    }
    return lines;
}

pub fn main() !void {
    const file_name: []const u8 = "file.txt";
    std.debug.print("File: {s}\n", .{file_name});
    const file_size = try getFileSize(file_name);
    std.debug.print("{d}\n", .{file_size});
    var timer = try std.time.Timer.start();
    // const lines = try countLinesByte(file_name, 0, file_size);
    // var countLinesByteTime = timer.lap() / 1000;
    // std.debug.print("countLinesByte lines: {d}\n", .{lines});
    // std.debug.print("countLinesByte time(ms): {d}\n", .{countLinesByteTime});
    // timer.reset();
    const linesChunk = try countLinesChunk(file_name, 0, file_size, 51200);
    var countLinesChunkTime = timer.lap() / 1000;
    std.debug.print("countLinesChunk lines: {d}\n", .{linesChunk});
    std.debug.print("countLinesChunk time(ms): {d}\n", .{countLinesChunkTime});
    // const nthreads: u32 = DEFAULT_NUMBER_OF_THREADS;
    // const avg_size = stat.size / nthreads;
    // var arena = heap.ArenaAllocator.init(heap.page_allocator);
    // var alloc = arena.allocator();
    // var tasks = std.ArrayList(Task).init(alloc);
    // var initial_offset: u64 = 0;
    // var i: u32 = 0;
    // while (i < nthreads) : (i += 1) {
    //     const reminder: u64 = try std.math.rem(u64, stat.size, avg_size);
    //     var current_size: u64 = avg_size;
    //     if (i < reminder) {
    //         current_size += 1;
    //     }
    //     const task = Task{ .file_name = file_name, .chunk_size = DEFAULT_CHUNK_SIZE, .offset = initial_offset, .len = current_size };
    //     try tasks.append(task);
    //     initial_offset += current_size;
    // }
    // std.debug.print("{any}\n", .{tasks.items});
    // var threads: std.ArrayList(std.Thread) = std.ArrayList(std.Thread).init(alloc);
    // i = 0;
    // for (tasks.items) |task| {
    //     var thread = try std.Thread.spawn(.{}, workerFunction, .{task});
    //     try threads.append(thread);
    // }
    // for (threads.items) |thread| {
    //     thread.join();
    // }
    // std.debug.print("Done!\n", .{});
}

pub fn getFileSize(file_name: []const u8) !u64 {
    var file: fs.File = try fs.cwd().openFile(file_name, fs.File.OpenFlags{});
    defer file.close();
    const stat = try file.stat();
    return stat.size;
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
