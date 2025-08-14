// Imports
const std = @import("std");

// Local
const errors = @import("errors.zig");
const action = @import("action.zig");

// Aliases
const Allocator = std.mem.Allocator;
const Writer = std.fs.File.Writer;
const ArrayList = std.ArrayList;

fn summary(allocator: Allocator, writer: Writer, perform: action.Action) !void {
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    const w = buffer.writer();

    try w.print("Command\t{s}\n", .{perform.command.toString()});
    try w.print("Project\t{s}\n", .{perform.project.?});
    // try w.print("Source\t{s}\n", .{perform.source.?});
    // try w.print("Output\t{s}\n", .{perform.output.?});
    try w.writeAll("\n");

    // throw it to the terminal
    try writer.writeAll(buffer.items);
}

pub fn main(allocator: Allocator, writer: Writer, perform: action.Action) !void {
    try summary(allocator, writer, perform);
    // find c and h files within the source project folder
    const files = findSourceFiles(allocator, perform.source.?) catch |err| {
        return err;
    };
    defer {
        for (files.items) |file| {
            allocator.free(file);
        }
        files.deinit();
    }

    if (perform.verbose) {
        std.debug.print("Found {d} source files:\n", .{files.items.len});
        for (files.items) |file| {
            std.debug.print("  {s}\n", .{file});
        }
        std.debug.print("\n", .{});
    }

    // build the project: executable or a library

    // run if it is required
}

fn findSourceFilesRecursive(allocator: Allocator, folder: []const u8, source_files: *ArrayList([]const u8)) !void {
    var dir = std.fs.cwd().openDir(folder, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => return,
        else => return err,
    };
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
            try findSourceFilesRecursive(allocator, sub_folder, source_files);
        }
    }
}

fn findSourceFiles(allocator: std.mem.Allocator, folder: []const u8) !ArrayList([]const u8) {
    var source_files = ArrayList([]const u8).init(allocator);

    var dir = std.fs.cwd().openDir(folder, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => {
            // std.debug.print("Error: Folder '{s}' not found\n", .{folder});
            return errors.List.BuildInvalidFolder;
        },
        else => return err,
    };
    defer dir.close();

    // Recursively find all .c files
    try findSourceFilesRecursive(allocator, folder, &source_files);

    if (source_files.items.len == 0) {
        std.debug.print("Error: No .c files found in folder '{s}'\n", .{folder});
        return errors.List.BuildNoSourceFiles;
    }

    return source_files;
}
