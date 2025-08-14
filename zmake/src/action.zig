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

pub const Build = struct {
    folder: []u8,
    output: []u8,
    executable: bool,

    const Self = @This();

    pub fn init(allocator: Allocator) !Self {
        return Self{
            .folder = try allocator.dupe(u8, "."),
            .output = try allocator.dupe(u8, "main"),
            .executable = true,
        };
    }

    pub fn deinit(self: *Self, allocator: Allocator) void {
        allocator.free(self.folder);
        allocator.free(self.output);
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
    // command specific options
    build: Build,
    run_after_build: bool = true,
    static_library: bool = false,
    executable: bool = true,

    const Self = @This();

    pub fn init(allocator: Allocator) !Action {
        return Action{ .build = try Build.init(allocator) };
    }

    pub fn deinit(self: *Action, allocator: Allocator) void {
        if (self.project) |f| allocator.free(f);
        self.build.deinit(allocator);
    }
};
