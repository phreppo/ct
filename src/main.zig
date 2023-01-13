const std = @import("std");
const fs = std.fs;
const heap = std.heap;
const os = std.os;
const args = @import("./args.zig");

const Task = struct { file_name: []const u8, chunk_size: u64, from: u64, len: u64, answer: *u64 };

// Worker function run by each thread.
fn workerFunction(task: Task) !void {
    const lines = try countLinesChunk(task.file_name, task.from, task.len, task.chunk_size);
    std.debug.print("{any}: {d}\n", .{ task, lines });
    task.answer.* = lines;
}

pub fn main() !void {
    var parsed_config: args.ParseArgsError!args.Config = args.parse_args();
    if (parsed_config) |config| {
        var my_config = config; // We have to assign this because otherwise it is a constant.
        var arena = heap.ArenaAllocator.init(heap.page_allocator);
        var alloc = arena.allocator();

        const file_size = try getFileSize(my_config.file_name);
        std.debug.print("File size: {d} bytes\n", .{file_size});

        // We set the number of threads to be the minimum between what was provided by the user and the file size.
        // If the file size is less than the number of threads and we ignore this, where are divisions by zero.
        my_config.threads = std.math.min(my_config.threads, file_size);

        const avg_size = file_size / my_config.threads;
        var answers: std.ArrayList(u64) = std.ArrayList(u64).init(alloc);
        var j: u64 = 0;
        while (j < my_config.threads) : (j += 1) {
            try answers.append(0);
        }
        var tasks = std.ArrayList(Task).init(alloc);
        var initial_offset: u64 = 0;
        var i: u32 = 0;
        while (i < my_config.threads) : (i += 1) {
            const reminder: u64 = try std.math.rem(u64, file_size, avg_size);
            var current_size: u64 = avg_size;
            if (i < reminder) {
                current_size += 1;
            }
            const task = Task{ .file_name = my_config.file_name, .chunk_size = my_config.chunks_size, .from = initial_offset, .len = current_size, .answer = &(answers.items[i]) };
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
    } else |err| {
        args.printErrorMessage(err);
        std.os.exit(1);
    }
}

pub fn getFileSize(file_name: []const u8) !u64 {
    var file: fs.File = try fs.cwd().openFile(file_name, fs.File.OpenFlags{});
    defer file.close();
    const stat = try file.stat();
    return stat.size;
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
test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
