const std = @import("std");

pub fn objects(allocator: std.mem.Allocator, files: std.ArrayList([]const u8), folder: []const u8, verbose: bool) void {
    // Try to remove obj directory if it's empty
    const obj_dir = try std.fmt.allocPrint(allocator, "{s}/obj", .{folder});
    defer allocator.free(obj_dir);

    std.fs.cwd().deleteDir(obj_dir) catch |err| {
        if (verbose and err != error.DirNotEmpty) {
            std.debug.print("Note: Could not remove obj directory: {}\n", .{err});
        }
    };

    for (files.items) |obj_file| {
        std.fs.cwd().deleteFile(obj_file) catch |err| {
            if (verbose) {
                std.debug.print("Warning: Could not delete {s}: {}\n", .{ obj_file, err });
            }
        };
        if (verbose) {
            std.debug.print("✓ Cleaned {s}\n", .{obj_file});
        }
    }
}
