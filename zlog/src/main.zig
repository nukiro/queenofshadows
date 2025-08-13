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

        pub fn write(self: *Self, comptime level: []const u8, comptime fmt: []const u8, args: anytype) !void {
            self.mutex.lock();
            defer self.mutex.unlock();

            var buffer = ArrayList(u8).init(self.allocator);
            defer buffer.deinit();

            const w = buffer.writer();

            const dt = temporal.DateTime.now();
            try w.print("{}\t", .{dt});

            // Add the level
            try w.writeAll(level);
            try w.writeAll("\t");

            // Add the actual message
            try w.print(fmt, args);

            try w.writeAll("\n");

            // Write directly to the stored writer
            try self.writer.writeAll(buffer.items);
        }

        pub fn debug(self: *Self, comptime fmt: []const u8, args: anytype) !void {
            try self.write("\x1b[4mDEBUG\x1b[0m", fmt, args);
        }

        pub fn info(self: *Self, comptime fmt: []const u8, args: anytype) !void {
            try self.write("\x1b[32mINFO\x1b[0m", fmt, args);
        }

        pub fn warn(self: *Self, comptime fmt: []const u8, args: anytype) !void {
            try self.write("\x1b[33mWARN\x1b[0m", fmt, args);
        }

        pub fn err(self: *Self, comptime fmt: []const u8, args: anytype) !void {
            try self.write("\x1b[31mERROR\x1b[0m", fmt, args);
        }

        pub fn fatal(self: *Self, comptime fmt: []const u8, args: anytype) !void {
            try self.write("\x1b[35mFATAL\x1b[0m", fmt, args);
        }
    };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const stdout = std.io.getStdOut().writer();
    var logger = GenericLogger(std.fs.File.Writer).init(allocator, stdout);

    try logger.debug("This is a {s} message", .{"DEBUG"});
    try logger.info("This is a {s} message", .{"INFO"});
    try logger.warn("This is a {s} message", .{"WARN"});
    try logger.err("This is a {s} message", .{"ERROR"});
    try logger.fatal("This is a {s} message", .{"FATAL"});
}
