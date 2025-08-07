const std = @import("std");

const Allocator = std.mem.Allocator;

pub const Config = struct {
    project: ?[]const u8 = null,
    source: ?[]const u8 = null,
    output: ?[]const u8 = null,
    debug: bool = true,
    verbose: bool = true,
    run_after_build: bool = true,
    clean_only: bool = false,
    executable: bool = true,
    static_library: bool = false,

    pub fn deinit(self: *Config, allocator: Allocator) void {
        if (self.project) |f| allocator.free(f);
        if (self.source) |s| allocator.free(s);
        if (self.output) |o| allocator.free(o);
    }
};
