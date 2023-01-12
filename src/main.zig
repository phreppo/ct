const std = @import("std");

fn WorkerContext(comptime t: type) type {
    return struct {
        n: t,
    };
}

// Worker function run by each thread.
fn workerFunction(ctx: WorkerContext(u32)) void {
    const result: u32 = fib(ctx.n);
    std.debug.print("Fib of {d} is {d}\n", .{ctx.n, result});
}

fn fib(n : u32) u32 {
    if (n == 0 or n == 1) {
        return n;
    } else {
        return fib(n - 1) + fib(n - 2);
    }
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var threads: std.ArrayList(std.Thread) = std.ArrayList(std.Thread).init(allocator);
    var i: u32 = 0;
    while (i < 8) : (i += 1) {
        const worker_ctx: WorkerContext(u32) = .{
            .n = 40,
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
