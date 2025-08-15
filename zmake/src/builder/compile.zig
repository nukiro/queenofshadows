const std = @import("std");

const action = @import("builder.zig").action;

fn extractPathAfterSrc(allocator: std.mem.Allocator, path: []const u8) !?[]u8 {
    // Find "src/" in the path
    const src_marker = "src/";
    const src_index = std.mem.indexOf(u8, path, src_marker);

    if (src_index == null) {
        return null; // "src/" not found
    }

    // Start after "src/"
    const start_index = src_index.? + src_marker.len;

    if (start_index >= path.len) {
        return null; // Nothing after "src/"
    }

    const path_after_src = path[start_index..];

    // Find the last '/' to remove the filename
    const last_slash = std.mem.lastIndexOf(u8, path_after_src, "/");

    if (last_slash == null) {
        return null; // No directory structure after src/
    }

    const result = path_after_src[0..last_slash.?];

    // Create a copy and replace '/' with '_'
    const result_copy = try allocator.dupe(u8, result);
    std.mem.replaceScalar(u8, result_copy, '/', '_');

    return result_copy;
}

pub fn source(allocator: std.mem.Allocator, perform: action.Action, file: []const u8) ![]const u8 {
    var cmd_args = std.ArrayList([]const u8).init(allocator);
    defer cmd_args.deinit();

    // Add compiler
    try cmd_args.append("gcc");

    // Add flags
    try cmd_args.append("-Wall");
    try cmd_args.append("-Wextra");
    try cmd_args.append("-pedantic");
    try cmd_args.append("-std=c23");

    // Add our library headers
    try cmd_args.append("-I./raykit/include");

    // Add compile-only flag
    try cmd_args.append("-c");

    // Add source file
    try cmd_args.append(file);

    // Generate object file name in obj/ subdirectory
    const base_name = std.fs.path.basename(file);
    // Remove .c extension
    const project_folder = perform.folder;

    var obj_name: []u8 = undefined;
    if (try extractPathAfterSrc(allocator, file)) |prefix_file| {
        defer allocator.free(prefix_file);
        obj_name = try std.fmt.allocPrint(allocator, "{s}/obj/{s}_{s}.o", .{ project_folder, prefix_file, base_name[0 .. base_name.len - 2] }); // Remove .c extension
        try cmd_args.append("-o");
        try cmd_args.append(obj_name);
    } else {
        obj_name = try std.fmt.allocPrint(allocator, "{s}/obj/{s}.o", .{ project_folder, base_name[0 .. base_name.len - 2] }); // Remove .c extension
        try cmd_args.append("-o");
        try cmd_args.append(obj_name);
    }

    try cmd_args.append("-o");
    try cmd_args.append(obj_name);

    // Execute compile command
    var child = std.process.Child.init(cmd_args.items, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    const stdout = try child.stdout.?.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(stdout);
    const stderr = try child.stderr.?.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(stderr);

    const result = try child.wait();

    if (stdout.len > 0) {
        std.debug.print("{s}", .{stdout});
    }

    if (stderr.len > 0) {
        std.debug.print("{s}", .{stderr});
    }

    switch (result) {
        .Exited => |code| {
            if (code != 0) {
                std.debug.print("Compilation failed for {s} with exit code: {d}\n", .{ file, code });
                return error.BuildCompilationFailed;
            }
        },
        else => {
            std.debug.print("Compilation process terminated unexpectedly for {s}\n", .{file});
            return error.BuildCompilationFailed;
        },
    }

    if (perform.verbose) {
        std.debug.print("✓ Compiled {s}\n", .{file});
    }

    return obj_name;
}
