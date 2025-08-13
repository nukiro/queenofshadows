const std = @import("std");
const errors = @import("errors.zig");
const helper = @import("helper.zig");

pub const BuildError = error{
    NoSourceFiles,
    CompilationFailed,
    ExecutionFailed,
    InvalidFolder,
};

pub const ParserError = error{
    InvalidCommand,
    InvalidFolder,
    InvalidFolderPath,
    InvalidOutputPath,
};

pub fn handleError(allocator: std.mem.Allocator, err: anyerror, w: std.fs.File.Writer) !void {
    switch (err) {
        errors.ParserError.InvalidCommand => try w.writeAll("\x1b[1;31mError: invalid or non-existent command.\x1b[0m\n"),
        errors.ParserError.InvalidFolder => try w.writeAll("\x1b[1;31mError: invalid or non-existent folder.\x1b[0m\n"),
        errors.ParserError.InvalidFolderPath => try w.writeAll("\x1b[1;31mError: --folder requires a path argument.\x1b[0m\n"),
        errors.ParserError.InvalidOutputPath => try w.writeAll("\x1b[1;31mError: --output requires an argument.\x1b[0m\n"),
        else => try w.writeAll("\x1b[1;31mError: unexpected/uncategorized error... :(\x1b[0m\n"),
    }

    try w.writeAll("\n");
    try helper.menu(allocator, w);
}
