const std = @import("std");

const errors = @import("errors.zig");

const Allocator = std.mem.Allocator;
const eql = std.mem.eql;

pub const Command = enum {
    build,
    clean,
    help,

    const Self = @This();

    // check if input fits with any command available, return null if not
    pub fn serialize(input: ?[]const u8) ?Self {
        const c = input orelse return null;

        if (eql(u8, c, "build")) {
            return .build;
        }

        if (eql(u8, c, "clean")) {
            return .clean;
        }

        if (eql(u8, c, "help") or eql(u8, c, "--help")) {
            return .help;
        }

        return null;
    }

    pub fn toString(self: Self) []const u8 {
        return switch (self) {
            .build => "Build",
            .clean => "Clean",
            .help => "Help",
        };
    }
};

pub const Build = struct {
    output: []u8,
    executable: bool = true,
    run: bool = true,
    debug: bool = true,

    const Self = @This();

    pub fn init(allocator: Allocator) !Self {
        return Self{
            .output = try allocator.dupe(u8, "main"),
        };
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        allocator.free(self.output);
    }
};

pub const Action = struct {
    command: Command = .help,
    verbose: bool = true,
    folder: []u8,
    // command specific options
    build: ?Build = null,

    const Self = @This();

    pub fn init(allocator: Allocator) !Action {
        return Action{ .folder = try allocator.dupe(u8, "./") };
    }

    pub fn deinit(self: *Action, allocator: Allocator) void {
        allocator.free(self.folder);
        self.build.?.deinit(allocator);
    }
};
