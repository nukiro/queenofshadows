const std = @import("std");
const print = std.debug.print;
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

pub fn handleError(err: anyerror) void {
    switch (err) {
        errors.ParserError.InvalidCommand => print("error in command\n", .{}),
        else => print("something happend...\n", .{}),
    }
}
