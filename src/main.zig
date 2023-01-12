const std = @import("std");

fn WorkerContext(comptime t: type) type {
    return struct {
        n: t,
    };
}

// Worker function run by each thread.
fn workerFunction(ctx: WorkerContext(i32)) void {
    std.debug.print("Hello from {d}\n", .{ctx.n});
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var threads: std.ArrayList(std.Thread) = std.ArrayList(std.Thread).init(allocator);
    var i: i32 = 0;
    while (i < 8) : (i += 1) {
        const worker_ctx: WorkerContext(i32) = .{
            .n = i,
        };
        // Start a new thread and pass the context to the worker thread.
        var thread = try std.Thread.spawn(.{}, workerFunction, .{worker_ctx});
        try threads.append(thread);
    }

    for (threads.items) |thread| {
        thread.join();
    }

    std.debug.print("Done!\n", .{});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
