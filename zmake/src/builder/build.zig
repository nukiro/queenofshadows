// Imports
const std = @import("std");

const utils = @import("builder.zig").utils;
const action = @import("builder.zig").action;

const clean = @import("clean.zig");

// Aliases
const Allocator = std.mem.Allocator;
const Writer = std.fs.File.Writer;
const ArrayList = std.ArrayList;

fn extractPathAfterSrc(allocator: Allocator, path: []const u8) !?[]u8 {
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

fn compileSourceFile(allocator: Allocator, config: *const action.Action, source_file: []const u8) ![]const u8 {
    var cmd_args = ArrayList([]const u8).init(allocator);
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
    try cmd_args.append(source_file);

    // Generate object file name in obj/ subdirectory
    const base_name = std.fs.path.basename(source_file);
    // Remove .c extension
    const project_folder = config.project.?;

    var obj_name: []u8 = undefined;
    if (try extractPathAfterSrc(allocator, source_file)) |prefix_file| {
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
                std.debug.print("Compilation failed for {s} with exit code: {d}\n", .{ source_file, code });
                return error.BuildCompilationFailed;
            }
        },
        else => {
            std.debug.print("Compilation process terminated unexpectedly for {s}\n", .{source_file});
            return error.BuildCompilationFailed;
        },
    }

    if (config.verbose) {
        std.debug.print("✓ Compiled {s}\n", .{source_file});
    }

    return obj_name;
}

fn linkObjectFiles(allocator: Allocator, config: *const action.Action, object_files: ArrayList([]const u8)) ![]const u8 {
    var cmd_args = ArrayList([]const u8).init(allocator);
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

pub fn executable(allocator: Allocator, writer: Writer, perform: action.Action) ![]const u8 {
    // hold object file names
    var objects = ArrayList([]const u8).init(allocator);
    // clean it before leave
    defer {
        for (objects.items) |obj_file| {
            allocator.free(obj_file);
        }
        objects.deinit();
    }

    // Ensure objects directory exists
    const dir = try std.fmt.allocPrint(allocator, "{s}/obj", .{perform.folder});
    defer allocator.free(dir);
    try utils.createDirectory(dir, writer);

    // // Compile each source file to object file in obj/ subdirectory
    // std.debug.print("Phase 1: Compiling source files to obj/...\n", .{});
    // for (files.items) |source_file| {
    //     const obj_file = compileSourceFile(allocator, perform, source_file) catch |err| {
    //         // Clean up any object files created so far
    //         clean.objects(objects, project_folder, perform.verbose);
    //         return err;
    //     };
    //     try objects.append(obj_file);
    // }

    // // Link all object files into executable in project root
    // std.debug.print("Phase 2: Linking object files to executable...\n", .{});
    // const exe_name = linkObjectFiles(allocator, perform, objects) catch |err| {
    //     // Clean up object files
    //     clean.objects(objects, project_folder, perform.verbose);
    //     return err;
    // };

    // std.debug.print("Build successful!\n\n", .{});
    // return exe_name;
    return "hello";
}
