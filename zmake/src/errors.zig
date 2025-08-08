const std = @import("std");
const errors = @import("errors.zig");

pub const BuildError = error{
    NoSourceFiles,
    CompilationFailed,
    ExecutionFailed,
    InvalidFolder,
};

pub const ParserError = error{
    InvalidCommand,
};

pub fn handleError(err: anyerror, w: anytype) !void {
    switch (err) {
        errors.ParserError.InvalidCommand => try w.print("\n\x1b[31mError: invalid or non-existent command\x1b[0m\n", .{}),
        else => try w.print("\n\x1b[31mError: unexpected/uncategorized error... :(\x1b[0m\n", .{}),
    }
}
