const lib = @import("zlog_lib");

const std = @import("std");

const temporal = @import("temporal");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

fn write(logger: Logger, comptime fmt: []const u8, args: anytype) !void {
    var buffer = ArrayList(u8).init(logger.allocator);
    defer buffer.deinit();

    const writer = buffer.writer();

    // datetime
    const dt = temporal.DateTime.now();
    // Print it
    try writer.print(
        "[{}] ",
        .{dt},
    );

    try writer.print(fmt, args);
    try writer.writeAll("\n");
    // Write to output
    try std.io.getStdOut().writer().writeAll(buffer.items);
}

const Logger = struct {
    allocator: Allocator,

    pub fn init(allocator: Allocator) Logger {
        return Logger{ .allocator = allocator };
    }

    pub fn debug(self: Logger, comptime fmt: []const u8, args: anytype) !void {
        try write(self, fmt, args);
    }
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello World\n", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const logger = Logger.init(allocator);
    try logger.debug("hello {s}", .{"world"});
    // try stdout.print("{d}\n", .{logger.attributes.number});

    const ts = std.time.milliTimestamp();
    const dt = temporal.DateTime.from(ts);
    try stdout.print("Unix millis: {} -> {}\n", .{ ts, dt });
}
