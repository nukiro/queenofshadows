const std = @import("std");

const action = @import("action.zig");

pub fn main(allocator: std.mem.Allocator, writer: std.fs.File.Writer, command: action.Command) !void {
    switch (command) {
        .help => try help(allocator, writer),
        .build => try build(allocator, writer),
        .clean => try clean(allocator, writer),
    }
}

fn help(allocator: std.mem.Allocator, writer: std.fs.File.Writer) !void {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    const w = buffer.writer();

    // goal
    try w.writeAll("C Project Builder\n");
    try w.writeAll("\n");
    // usage
    try w.writeAll("Usage:\n");
    try w.writeAll("  zmake [COMMAND] [OPTIONS]\n");
    try w.writeAll("\n");
    // commands
    try w.writeAll("Available Commands:\n");
    try w.writeAll("  build               Build the project\n");
    try w.writeAll("  clean               Clean all the project artifacts\n");
    try w.writeAll("  help                Help about any command\n");
    try w.writeAll("\n");

    // throw it to the terminal
    try writer.writeAll(buffer.items);
}

fn build(allocator: std.mem.Allocator, writer: std.fs.File.Writer) !void {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    const w = buffer.writer();

    // goal
    try w.writeAll("Build the project\n");
    try w.writeAll("\n");
    // usage
    try w.writeAll("Usage:\n");
    try w.writeAll("  zmake build [OPTIONS]\n");
    try w.writeAll("\n");

    // options
    try w.writeAll("Options:\n");
    try w.writeAll("  --folder <path>     Specify the project folder (required)\n");
    try w.writeAll("  --clean             Clean all project artifacts\n");
    try w.writeAll("  --static-library    Build C static library\n");
    try w.writeAll("  --no-debug          Don't set debug\n");
    try w.writeAll("  --no-run            Don't run the program after building\n");
    try w.writeAll("  --no-verbose        Don't enable verbose output\n");
    try w.writeAll("\n");

    // throw it to the terminal
    try writer.writeAll(buffer.items);
}

fn clean(allocator: std.mem.Allocator, writer: std.fs.File.Writer) !void {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    const w = buffer.writer();

    // goal
    try w.writeAll("Clean all the project artifacts\n");
    try w.writeAll("\n");
    // usage
    try w.writeAll("Usage:\n");
    try w.writeAll("  zmake clean [OPTIONS]\n");
    try w.writeAll("\n");

    // options
    try w.writeAll("Options:\n");
    try w.writeAll("  --folder <path>     Specify the project folder (required)\n");
    try w.writeAll("\n");

    // throw it to the terminal
    try writer.writeAll(buffer.items);
}
