const std = @import("std");

// Local Imports
const action = @import("action.zig");

pub fn errors(err: anyerror, w: std.fs.File.Writer, perform: ?action.Action) !void {
    switch (err) {
        error.ParserInvalidCommand => try w.writeAll(" \x1b[31m✖ Error: invalid or non-existent command.\x1b[0m\n"),
        error.ParserInvalidFolder => try w.writeAll(" \x1b[31m✖ Error: invalid or non-existent folder.\x1b[0m\n"),
        error.ParserInvalidFolderPath => try w.writeAll(" \x1b[31m✖ Error: --folder requires a path argument.\x1b[0m\n"),
        error.ParserInvalidOutputPath => try w.writeAll(" \x1b[31m✖ Error: --output requires an argument.\x1b[0m\n"),
        error.BuildInvalidFolder => try w.print(" \x1b[31m✖ Error: folder '{s}' not found.\x1b[0m\n", .{perform.?.folder}),
        error.BuildNoSourceFiles => try w.print(" \x1b[31m✖ Error: No .c/.h files found in folder '{s}'.\x1b[0m\n", .{perform.?.folder}),
        else => try w.writeAll(" \x1b[31m✖ Error: unexpected/uncategorized error... :(\x1b[0m\n"),
    }

    try w.writeAll("\n");
}
