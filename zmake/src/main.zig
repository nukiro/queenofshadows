const std = @import("std");

// Imports
const errors = @import("errors.zig");
const helper = @import("helper.zig");
const handler = @import("handler.zig");
const action = @import("action.zig");
const parser = @import("parser.zig");
const builder = @import("builder/builder.zig");

// Aliases
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

// fn compileLibSourceFile(allocator: Allocator, config: *const action.Action, source_file: []const u8) ![]const u8 {
//     var cmd_args = ArrayList([]const u8).init(allocator);
//     defer cmd_args.deinit();

//     // Add compiler
//     try cmd_args.append("gcc");

//     // Add flags
//     try cmd_args.append("-Wall");
//     try cmd_args.append("-Wextra");
//     try cmd_args.append("-pedantic");
//     try cmd_args.append("-std=c23");

//     // Add compile-only flag
//     try cmd_args.append("-c");

//     // Add source file
//     try cmd_args.append(source_file);

//     // Generate object file name in obj/ subdirectory
//     const base_name = std.fs.path.basename(source_file);
//     // Remove .c extension
//     const project_folder = config.project.?;

//     var obj_name: []u8 = undefined;
//     if (try extractPathAfterSrc(allocator, source_file)) |prefix_file| {
//         defer allocator.free(prefix_file);
//         obj_name = try std.fmt.allocPrint(allocator, "{s}/obj/{s}_{s}.o", .{ project_folder, prefix_file, base_name[0 .. base_name.len - 2] }); // Remove .c extension
//         try cmd_args.append("-o");
//         try cmd_args.append(obj_name);
//     } else {
//         obj_name = try std.fmt.allocPrint(allocator, "{s}/obj/{s}.o", .{ project_folder, base_name[0 .. base_name.len - 2] }); // Remove .c extension
//         try cmd_args.append("-o");
//         try cmd_args.append(obj_name);
//     }

//     // Execute compile command
//     var child = std.process.Child.init(cmd_args.items, allocator);
//     child.stdout_behavior = .Pipe;
//     child.stderr_behavior = .Pipe;

//     try child.spawn();

//     const stdout = try child.stdout.?.readToEndAlloc(allocator, 1024 * 1024);
//     defer allocator.free(stdout);
//     const stderr = try child.stderr.?.readToEndAlloc(allocator, 1024 * 1024);
//     defer allocator.free(stderr);

//     const result = try child.wait();

//     if (stdout.len > 0) {
//         print("{s}", .{stdout});
//     }

//     if (stderr.len > 0) {
//         print("{s}", .{stderr});
//     }

//     switch (result) {
//         .Exited => |code| {
//             if (code != 0) {
//                 print("Compilation failed for {s} with exit code: {d}\n", .{ source_file, code });
//                 return BuildError.CompilationFailed;
//             }
//         },
//         else => {
//             print("Compilation process terminated unexpectedly for {s}\n", .{source_file});
//             return BuildError.CompilationFailed;
//         },
//     }

//     if (config.verbose) {
//         print("✓ Compiled {s}\n", .{source_file});
//     }

//     return obj_name;
// }

fn linkLibObjectFiles(allocator: Allocator, config: *const action.Action, object_files: ArrayList([]const u8)) ![]const u8 {
    var cmd_args = ArrayList([]const u8).init(allocator);
    defer cmd_args.deinit();

    // Add compiler/linker
    try cmd_args.append("ar");
    try cmd_args.append("rcs");

    // Add output
    const project_folder = config.project.?;
    const lib_path = try std.fmt.allocPrint(allocator, "{s}/lib{s}.a", .{ project_folder, project_folder });
    try cmd_args.append(lib_path);

    // Add object files
    for (object_files.items) |obj_file| {
        try cmd_args.append(obj_file);
    }

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
        print("{s}", .{stdout});
    }

    if (stderr.len > 0) {
        print("{s}", .{stderr});
    }

    switch (result) {
        .Exited => |code| {
            if (code != 0) {
                print("Linking failed with exit code: {d}\n", .{code});
                return error.BuildCompilationFailed;
            }
        },
        else => {
            print("Linking process terminated unexpectedly\n", .{});
            return error.BuildCompilationFailed;
        },
    }

    if (config.verbose) {
        print("✓ Linked library: {s}\n", .{project_folder});
    }

    return lib_path;
}

fn ensureIncludeDirectory(project_folder: []const u8) !void {
    const obj_path = try std.fmt.allocPrint(std.heap.page_allocator, "{s}/include", .{project_folder});
    defer std.heap.page_allocator.free(obj_path);

    std.fs.cwd().makeDir(obj_path) catch |err| switch (err) {
        error.PathAlreadyExists => {}, // Directory already exists, that's fine
        else => return err,
    };
}

fn copy(allocator: Allocator, project_folder: []const u8) !void {
    const source_path = try std.fmt.allocPrint(allocator, "{s}/src/{s}.h", .{ project_folder, project_folder });
    defer allocator.free(source_path);
    const dest_path = try std.fmt.allocPrint(allocator, "{s}/include/{s}.h", .{ project_folder, project_folder });
    defer allocator.free(dest_path);

    // Open the source file for reading
    const source_file = try std.fs.cwd().openFile(source_path, .{});
    defer source_file.close();

    // Read all contents into memory
    const source_contents = try source_file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(source_contents);

    // Create or overwrite the destination file for writing
    const dest_file = try std.fs.cwd().createFile(dest_path, .{ .truncate = true });
    defer dest_file.close();

    // Write contents to destination
    _ = try dest_file.writeAll(source_contents);
}

// fn buildStaticLibrary(allocator: Allocator, config: *const action.Action, source_files: ArrayList([]const u8)) ![]const u8 {
//     // hold object file names
//     var object_files = ArrayList([]const u8).init(allocator);
//     // clean it before leave
//     defer {
//         for (object_files.items) |obj_file| {
//             allocator.free(obj_file);
//         }
//         object_files.deinit();
//     }

//     const project_folder = config.project.?;

//     // Ensure obj directory exists
//     ensureObjDirectory(project_folder) catch |err| {
//         print("Error: Could not create obj directory: {}\n", .{err});
//         return BuildError.CompilationFailed;
//     };

//     // Compile each source file to object file in obj/ subdirectory
//     print("Phase 1: Compiling source files to obj/...\n", .{});
//     for (source_files.items) |source_file| {
//         const obj_file = compileLibSourceFile(allocator, config, source_file) catch |err| {
//             // Clean up any object files created so far
//             cleanObjectFiles(object_files, project_folder, config.verbose);
//             return err;
//         };
//         try object_files.append(obj_file);
//     }

//     // Link all object files into executable in project root
//     print("Phase 2: Linking object files to executable...\n", .{});
//     const lib_name = linkLibObjectFiles(allocator, config, object_files) catch |err| {
//         // Clean up object files
//         cleanObjectFiles(object_files, project_folder, config.verbose);
//         return err;
//     };

//     ensureIncludeDirectory(project_folder) catch |err| {
//         print("Error: Could not create include library directory: {}\n", .{err});
//         return BuildError.CompilationFailed;
//     };

//     try copy(allocator, project_folder);

//     print("Build successful!\n\n", .{});
//     return lib_name;
// }

fn runExecutable(allocator: Allocator, exe_path: []const u8, verbose: bool) !void {
    if (verbose) {
        print("Running: {s}\n\n", .{exe_path});
    }

    const cmd_args = [_][]const u8{exe_path};

    var child = std.process.Child.init(&cmd_args, allocator);

    const result = try child.spawnAndWait();

    switch (result) {
        .Exited => |code| {
            if (code != 0) {
                print("Program exited with code: {d}\n", .{code});
            }
        },
        else => {
            print("Program terminated unexpectedly\n", .{});
        },
    }
}

fn cleanAllArtifacts(allocator: Allocator, config: *const action.Action) !void {
    const project_folder = config.project.?;

    print("Cleaning build artifacts in: {s}\n", .{project_folder});

    var cleaned_count: u32 = 0;

    // Clean obj directory and its contents
    const obj_dir_path = try std.fmt.allocPrint(allocator, "{s}/obj", .{project_folder});
    defer allocator.free(obj_dir_path);

    // Try to open obj directory
    var obj_dir = std.fs.cwd().openDir(obj_dir_path, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => {
            print("Error: Folder '{s}' not found\n", .{obj_dir_path});
            return error.BuildInvalidFolder;
        },
        else => return err,
    };
    defer obj_dir.close();

    var iterator = obj_dir.iterate();
    while (try iterator.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".o")) {
            const obj_file_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ obj_dir_path, entry.name });
            defer allocator.free(obj_file_path);

            std.fs.cwd().deleteFile(obj_file_path) catch |err| {
                if (config.verbose) {
                    print("Warning: Could not delete {s}: {}\n", .{ obj_file_path, err });
                }
                continue;
            };

            if (config.verbose) {
                print("✓ Removed {s}\n", .{obj_file_path});
            }
            cleaned_count += 1;
        }
    }

    // Try to remove the obj directory if it's empty
    std.fs.cwd().deleteDir(obj_dir_path) catch |err| {
        if (config.verbose and err != error.DirNotEmpty) {
            print("Note: Could not remove obj directory: {}\n", .{err});
        }
    };
    if (config.verbose) {
        print("✓ Removed obj directory\n", .{});
    }

    const include_dir_path = try std.fmt.allocPrint(allocator, "{s}/include", .{project_folder});
    defer allocator.free(include_dir_path);

    const cwd = std.fs.cwd();

    cwd.deleteTree(include_dir_path) catch |err| {
        return err;
    };

    // Clean potential executables
    const possible_executables = [_][]const u8{
        config.output orelse "main",
        "main",
        "app",
        "program",
        "libraykit.a", // remove it from here and find .a file in lib folder
    };

    for (possible_executables) |exe_name| {
        const exe_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ project_folder, exe_name });
        defer allocator.free(exe_path);

        std.fs.cwd().deleteFile(exe_path) catch |err| {
            if (config.verbose and err != error.FileNotFound) {
                print("Note: Could not delete {s}: {}\n", .{ exe_path, err });
            }
            continue;
        };

        if (config.verbose) {
            print("✓ Removed {s}\n", .{exe_path});
        }
        cleaned_count += 1;
    }

    if (cleaned_count > 0) {
        print("✓ Cleaned {d} build artifacts\n", .{cleaned_count});
    } else {
        print("No build artifacts found to clean\n", .{});
    }
}

pub fn main() !u8 {
    const w = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // firstly, parse command arguments and check required ones exist
    var perform = parser.parser(allocator, w) catch |err| {
        try handler.errors(err, w, null);
        std.process.exit(1);
    };
    defer perform.deinit(allocator);

    // process regarding action
    switch (perform.command) {
        .build => builder.main(allocator, w, perform) catch |err| {
            try handler.errors(err, w, perform);
            std.process.exit(1);
        },
        .clean => {},
        .help => try helper.main(allocator, w, .help),
    }

    // // Handle clean-only operation
    // if (config.clean_only) {
    //     cleanAllArtifacts(allocator, &config) catch {
    //         std.process.exit(1);
    //     };
    //     return;
    // }

    // // secondly, find c and h files into the source project folder
    // const source_files = findSourceFiles(allocator, config.source.?) catch {
    //     std.process.exit(1);
    // };
    // defer {
    //     for (source_files.items) |file| {
    //         allocator.free(file);
    //     }
    //     source_files.deinit();
    // }
    // if (config.verbose) {
    //     print("Found {d} source files:\n", .{source_files.items.len});
    //     for (source_files.items) |file| {
    //         print("  {s}\n", .{file});
    //     }
    //     print("\n", .{});
    // }

    // // thirdly, build an executable or a library
    // if (config.static_library) {
    //     const lib_name = buildStaticLibrary(allocator, &config, source_files) catch {
    //         std.process.exit(1);
    //     };
    //     defer allocator.free(lib_name);
    //     return;
    // }
    // // build the exe
    // const exe_name = buildExecutable(allocator, &config, source_files) catch {
    //     std.process.exit(1);
    // };
    // defer allocator.free(exe_name);

    // // fourthly, run the executable
    // if (config.run_after_build) {
    //     runExecutable(allocator, exe_name, config.verbose) catch {
    //         std.process.exit(1);
    //     };
    // }

    return 0;
}
