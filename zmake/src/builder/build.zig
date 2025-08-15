// Imports
const std = @import("std");

const utils = @import("builder.zig").utils;
const action = @import("builder.zig").action;

const clean = @import("clean.zig");
const compile = @import("compile.zig");

// Aliases
const Allocator = std.mem.Allocator;
const Writer = std.fs.File.Writer;
const ArrayList = std.ArrayList;

pub fn executable(allocator: Allocator, writer: Writer, perform: action.Action, files: ArrayList([]const u8)) ![]const u8 {
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

    // Compile each source file to object file in obj/ subdirectory
    try writer.print("Phase 1: Compiling source files to {s}/...\n", .{dir});
    for (files.items) |file| {
        const object = compile.source(allocator, perform, file) catch |err| {
            // std.debug.print("{s}", err);
            // Clean up any object files created so far
            try clean.objects(allocator, objects, perform.folder, perform.verbose);
            return err;
        };
        try objects.append(object);
    }

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
