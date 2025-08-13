const lib = @import("zlog_lib");

const std = @import("std");

const temporal = @import("temporal");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn GenericLogger(comptime WriterType: type) type {
    return struct {
        allocator: Allocator,
        writer: WriterType,
        mutex: std.Thread.Mutex = .{},

        const Self = @This();

        pub fn init(allocator: Allocator, writer: WriterType) Self {
            return Self{
                .allocator = allocator,
                .writer = writer,
            };
        }

        pub fn write(self: *Self, comptime fmt: []const u8, args: anytype) !void {
            self.mutex.lock();
            defer self.mutex.unlock();

            var buffer = ArrayList(u8).init(self.allocator);
            defer buffer.deinit();

            const w = buffer.writer();

            const dt = temporal.DateTime.now();
            try w.print("{} ", .{dt});

            // Add the actual message
            try w.print(fmt, args);

            try w.writeAll("\n");

            // Write directly to the stored writer
            try self.writer.writeAll(buffer.items);
        }
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();
    var logger = GenericLogger(std.fs.File.Writer).init(allocator, stdout);

    try logger.write("Hello World", .{});
}
