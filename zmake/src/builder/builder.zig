// Imports
const std = @import("std");

// Local
const errors = @import("../errors.zig");
pub const action = @import("../action.zig");
pub const utils = @import("../utils.zig");
const find = @import("find.zig");
const build = @import("build.zig");

// Aliases
const Allocator = std.mem.Allocator;
const Writer = std.fs.File.Writer;
const ArrayList = std.ArrayList;

fn summary(allocator: Allocator, writer: Writer, perform: action.Action) !void {
    const builder = perform.builder.?;

    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    const w = buffer.writer();

    try w.writeAll("\x1b[1;4mBuild Command\x1b[0m\n");
    try w.print("Folder\t=> {s}\n", .{perform.folder});
    if (builder.debug) try w.writeAll("Debug\t=> True\n");

    if (builder.executable) {
        try w.print("The executable: '{s}' will be built. ", .{builder.output});
        if (builder.run) try w.writeAll("It will be executed after the compilation.");
        try w.writeAll("\n");
    } else try w.print("The library: '{s}' will be built.\n", .{builder.output});

    try w.writeAll("\n");

    // throw it to the terminal
    try writer.writeAll(buffer.items);
}

pub fn main(allocator: Allocator, writer: Writer, perform: action.Action) !void {
    try summary(allocator, writer, perform);

    // find c and h files within the source project folder
    const files = try find.source(allocator, writer, perform);
    defer {
        for (files.items) |file| {
            allocator.free(file);
        }
        files.deinit();
    }

    // build the project: executable or a library
    _ = try build.executable(allocator, writer, perform);

    // run if it is required
}
