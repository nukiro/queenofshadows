const std = @import("std");

const action = @import("builder.zig").action;

fn objects(allocator: std.mem.Allocator, config: *const action.Action, object_files: std.ArrayList([]const u8)) ![]const u8 {
    var cmd_args = std.ArrayList([]const u8).init(allocator);
    defer cmd_args.deinit();

    // Add compiler/linker
    try cmd_args.append("gcc");

    // Add object files
    for (object_files.items) |obj_file| {
        try cmd_args.append(obj_file);
    }

    // Add our libraries
    try cmd_args.append("-L./raykit");
    try cmd_args.append("-lraykit");

    // Add output
    const output_name = config.output orelse "main";
    const project_folder = config.project.?;
    const exe_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ project_folder, output_name });
    try cmd_args.append("-o");
    try cmd_args.append(exe_path);

    // Add libraries
    try cmd_args.append("-lraylib");
    try cmd_args.append("-lm");
    try cmd_args.append("-ldl");
    try cmd_args.append("-lpthread");
    try cmd_args.append("-lGL");
    try cmd_args.append("-lrt");
    try cmd_args.append("-lX11");

    // Execute link command
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
                std.debug.print("Linking failed with exit code: {d}\n", .{code});
                return error.BuildCompilationFailed;
            }
        },
        else => {
            std.debug.print("Linking process terminated unexpectedly\n", .{});
            return error.BuildCompilationFailed;
        },
    }

    if (config.verbose) {
        std.debug.print("✓ Linked executable: {s}\n", .{output_name});
    }

    return exe_path;
}
