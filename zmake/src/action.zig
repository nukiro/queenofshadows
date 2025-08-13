const std = @import("std");

const errors = @import("errors.zig");

const Allocator = std.mem.Allocator;
const eql = std.mem.eql;

pub const Command = enum {
    build,
    clean,
    help,

    // check if input fits with any command available
    // return null if not
    pub fn serialize(input: ?[]const u8) ?Command {
        const c = input orelse return null;

        if (eql(u8, c, "build")) {
            return Command.build;
        }

        if (eql(u8, c, "clean")) {
            return Command.clean;
        }

        if (eql(u8, c, "help") or eql(u8, c, "--help")) {
            return Command.help;
        }

        return null;
    }

    pub fn toString(self: Command) []const u8 {
        return switch (self) {
            .build => "BUILD",
            .clean => "CLEAN",
            .help => "HELP",
        };
    }
};

pub const Action = struct {
    // initialize as build command to not set it as undefined
    // which may cause errors.
    command: Command = .help,
    project: ?[]const u8 = null,
    source: ?[]const u8 = null,
    output: ?[]const u8 = null,
    debug: bool = true,
    verbose: bool = true,
    run_after_build: bool = true,
    clean_only: bool = false,
    executable: bool = true,
    static_library: bool = false,

    const Self = @This();

    pub fn init() Action {
        return Action{};
    }

    pub fn deinit(self: *Action, allocator: Allocator) void {
        if (self.project) |f| allocator.free(f);
        if (self.source) |s| allocator.free(s);
        if (self.output) |o| allocator.free(o);
    }
};
