const std = @import("std");

const helper = @import("helper.zig");
const errors = @import("errors.zig");

const Allocator = std.mem.Allocator;

const eql = std.mem.eql;

pub const Command = enum {
    build,
    clean,

    pub fn serialize(input: []const u8) ?Command {
        if (eql(u8, input, "build")) {
            return Command.build;
        }

        if (eql(u8, input, "clean")) {
            return Command.clean;
        }

        return null;
    }
};

pub const Action = struct {
    command: Command = undefined,
    project: ?[]const u8 = null,
    source: ?[]const u8 = null,
    output: ?[]const u8 = null,
    debug: bool = true,
    verbose: bool = true,
    run_after_build: bool = true,
    clean_only: bool = false,
    executable: bool = true,
    static_library: bool = false,

    pub fn init(command: Command) Action {
        return Action{ .command = command };
    }

    pub fn deinit(self: *Action, allocator: Allocator) void {
        if (self.project) |f| allocator.free(f);
        if (self.source) |s| allocator.free(s);
        if (self.output) |o| allocator.free(o);
    }
};
