const std = @import("std");

pub fn menu(allocator: std.mem.Allocator, writer: std.fs.File.Writer) !void {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    const w = buffer.writer();

    // add help menu to the buffer writer
    try w.writeAll("Usage: zmake [COMMAND] [OPTIONS]\n\n");
    try w.writeAll("Options:\n");
    try w.writeAll("  --folder <path>     Specify the project folder (required)\n");
    try w.writeAll("  --clean             Clean all project artifacts\n");
    try w.writeAll("  --static-library    Build C static library\n");
    try w.writeAll("  --no-debug          Don't set debug\n");
    try w.writeAll("  --no-run            Don't run the program after building\n");
    try w.writeAll("  --no-verbose        Don't enable verbose output\n");
    try w.writeAll("  --help              Show this help message\n\n");

    // throw it to the terminal
    try writer.writeAll(buffer.items);
}
