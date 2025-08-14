const std = @import("std");

const action = @import("../action.zig");

// Aliases
const Allocator = std.mem.Allocator;
const Writer = std.fs.File.Writer;
const ArrayList = std.ArrayList;

fn recursive(allocator: Allocator, folder: []const u8, source_files: *ArrayList([]const u8)) !void {
    var dir = try std.fs.cwd().openDir(folder, .{ .iterate = true });
    defer dir.close();

    var iterator = dir.iterate();
    while (try iterator.next()) |entry| {
        if (entry.kind == .file) {
            const name = entry.name;
            if (std.mem.endsWith(u8, name, ".c")) {
                const full_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ folder, name });
                try source_files.append(full_path);
            }
        } else if (entry.kind == .directory) {
            // Skip common non-source directories
            if (std.mem.eql(u8, entry.name, "obj") or
                std.mem.eql(u8, entry.name, "build") or
                std.mem.eql(u8, entry.name, "bin") or
                std.mem.eql(u8, entry.name, ".git") or
                std.mem.eql(u8, entry.name, ".vscode") or
                std.mem.eql(u8, entry.name, "node_modules"))
            {
                continue;
            }

            // Recursively search subdirectories
            const sub_folder = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ folder, entry.name });
            defer allocator.free(sub_folder);
            try recursive(allocator, sub_folder, source_files);
        }
    }
}

pub fn source(allocator: std.mem.Allocator, writer: std.fs.File.Writer, perform: action.Action) !ArrayList([]const u8) {
    const builder = perform.builder.?;

    var files = ArrayList([]const u8).init(allocator);

    // check if the directory exists

    const folder = if (std.mem.eql(u8, ".", builder.source)) try std.fmt.allocPrint(allocator, "{s}", .{perform.folder}) else try std.fmt.allocPrint(allocator, "{s}/{s}", .{ perform.folder, builder.source });
    defer allocator.free(folder);
    var dir = std.fs.cwd().openDir(folder, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return error.BuildInvalidFolder,
        else => return err,
    };
    defer dir.close();

    // Recursively find all files
    try recursive(allocator, folder, &files);

    if (files.items.len == 0) return error.BuildNoSourceFiles;

    if (perform.verbose) {
        try writer.print("Found {d} source files:\n", .{files.items.len});
        for (files.items) |file| {
            try writer.print("  {s}\n", .{file});
        }
        try writer.writeAll("\n");
    }

    return files;
}
