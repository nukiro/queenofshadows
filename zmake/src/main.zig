const std = @import("std");

// Imports
const errors = @import("errors.zig");
const action = @import("action.zig");
const parser = @import("parser.zig");

// Aliases
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const BuildError = errors.BuildError;

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

fn findSourceFiles(allocator: Allocator, folder: []const u8) !ArrayList([]const u8) {
    var source_files = ArrayList([]const u8).init(allocator);

    var dir = std.fs.cwd().openDir(folder, .{ .iterate = true }) catch |err| switch (err) {
        error.FileNotFound => {
            print("Error: Folder '{s}' not found\n", .{folder});
            return BuildError.InvalidFolder;
        },
        else => return err,
    };
    defer dir.close();

    // Recursively find all .c files
    try findSourceFilesRecursive(allocator, folder, &source_files);

    if (source_files.items.len == 0) {
        print("Error: No .c files found in folder '{s}'\n", .{folder});
        return BuildError.NoSourceFiles;
    }

    return source_files;
}

fn compileLibSourceFile(allocator: Allocator, config: *const action.Action, source_file: []const u8) ![]const u8 {
    var cmd_args = ArrayList([]const u8).init(allocator);
    defer cmd_args.deinit();

    // Add compiler
    try cmd_args.append("gcc");

    // Add flags
    try cmd_args.append("-Wall");
    try cmd_args.append("-Wextra");
    try cmd_args.append("-pedantic");
    try cmd_args.append("-std=c23");

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
        print("{s}", .{stdout});
    }

    if (stderr.len > 0) {
        print("{s}", .{stderr});
    }

    switch (result) {
        .Exited => |code| {
            if (code != 0) {
                print("Compilation failed for {s} with exit code: {d}\n", .{ source_file, code });
                return BuildError.CompilationFailed;
            }
        },
        else => {
            print("Compilation process terminated unexpectedly for {s}\n", .{source_file});
            return BuildError.CompilationFailed;
        },
    }

    if (config.verbose) {
        print("✓ Compiled {s}\n", .{source_file});
    }

    return obj_name;
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
        print("{s}", .{stdout});
    }

    if (stderr.len > 0) {
        print("{s}", .{stderr});
    }

    switch (result) {
        .Exited => |code| {
            if (code != 0) {
                print("Compilation failed for {s} with exit code: {d}\n", .{ source_file, code });
                return BuildError.CompilationFailed;
            }
        },
        else => {
            print("Compilation process terminated unexpectedly for {s}\n", .{source_file});
            return BuildError.CompilationFailed;
        },
    }

    if (config.verbose) {
        print("✓ Compiled {s}\n", .{source_file});
    }

    return obj_name;
}

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
                return BuildError.CompilationFailed;
            }
        },
        else => {
            print("Linking process terminated unexpectedly\n", .{});
            return BuildError.CompilationFailed;
        },
    }

    if (config.verbose) {
        print("✓ Linked library: {s}\n", .{project_folder});
    }

    return lib_path;
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
        print("{s}", .{stdout});
    }

    if (stderr.len > 0) {
        print("{s}", .{stderr});
    }

    switch (result) {
        .Exited => |code| {
            if (code != 0) {
                print("Linking failed with exit code: {d}\n", .{code});
                return BuildError.CompilationFailed;
            }
        },
        else => {
            print("Linking process terminated unexpectedly\n", .{});
            return BuildError.CompilationFailed;
        },
    }

    if (config.verbose) {
        print("✓ Linked executable: {s}\n", .{output_name});
    }

    return exe_path;
}

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

fn cleanObjectFiles(object_files: ArrayList([]const u8), project_folder: []const u8, verbose: bool) void {
    // Try to remove obj directory if it's empty
    const obj_dir = std.fmt.allocPrint(std.heap.page_allocator, "{s}/obj", .{project_folder}) catch return;
    defer std.heap.page_allocator.free(obj_dir);

    std.fs.cwd().deleteDir(obj_dir) catch |err| {
        if (verbose and err != error.DirNotEmpty) {
            print("Note: Could not remove obj directory: {}\n", .{err});
        }
    };

    for (object_files.items) |obj_file| {
        std.fs.cwd().deleteFile(obj_file) catch |err| {
            if (verbose) {
                print("Warning: Could not delete {s}: {}\n", .{ obj_file, err });
            }
        };
        if (verbose) {
            print("✓ Cleaned {s}\n", .{obj_file});
        }
    }
}

fn ensureObjDirectory(project_folder: []const u8) !void {
    const obj_path = try std.fmt.allocPrint(std.heap.page_allocator, "{s}/obj", .{project_folder});
    defer std.heap.page_allocator.free(obj_path);

    std.fs.cwd().makeDir(obj_path) catch |err| switch (err) {
        error.PathAlreadyExists => {}, // Directory already exists, that's fine
        else => return err,
    };
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

fn buildStaticLibrary(allocator: Allocator, config: *const action.Action, source_files: ArrayList([]const u8)) ![]const u8 {
    // hold object file names
    var object_files = ArrayList([]const u8).init(allocator);
    // clean it before leave
    defer {
        for (object_files.items) |obj_file| {
            allocator.free(obj_file);
        }
        object_files.deinit();
    }

    const project_folder = config.project.?;

    // Ensure obj directory exists
    ensureObjDirectory(project_folder) catch |err| {
        print("Error: Could not create obj directory: {}\n", .{err});
        return BuildError.CompilationFailed;
    };

    // Compile each source file to object file in obj/ subdirectory
    print("Phase 1: Compiling source files to obj/...\n", .{});
    for (source_files.items) |source_file| {
        const obj_file = compileLibSourceFile(allocator, config, source_file) catch |err| {
            // Clean up any object files created so far
            cleanObjectFiles(object_files, project_folder, config.verbose);
            return err;
        };
        try object_files.append(obj_file);
    }

    // Link all object files into executable in project root
    print("Phase 2: Linking object files to executable...\n", .{});
    const lib_name = linkLibObjectFiles(allocator, config, object_files) catch |err| {
        // Clean up object files
        cleanObjectFiles(object_files, project_folder, config.verbose);
        return err;
    };

    ensureIncludeDirectory(project_folder) catch |err| {
        print("Error: Could not create include library directory: {}\n", .{err});
        return BuildError.CompilationFailed;
    };

    try copy(allocator, project_folder);

    print("Build successful!\n\n", .{});
    return lib_name;
}

fn buildExecutable(allocator: Allocator, config: *const action.Action, source_files: ArrayList([]const u8)) ![]const u8 {
    // hold object file names
    var object_files = ArrayList([]const u8).init(allocator);
    // clean it before leave
    defer {
        for (object_files.items) |obj_file| {
            allocator.free(obj_file);
        }
        object_files.deinit();
    }

    const project_folder = config.project.?;

    // Ensure obj directory exists
    ensureObjDirectory(project_folder) catch |err| {
        print("Error: Could not create obj directory: {}\n", .{err});
        return BuildError.CompilationFailed;
    };

    // Compile each source file to object file in obj/ subdirectory
    print("Phase 1: Compiling source files to obj/...\n", .{});
    for (source_files.items) |source_file| {
        const obj_file = compileSourceFile(allocator, config, source_file) catch |err| {
            // Clean up any object files created so far
            cleanObjectFiles(object_files, project_folder, config.verbose);
            return err;
        };
        try object_files.append(obj_file);
    }

    // Link all object files into executable in project root
    print("Phase 2: Linking object files to executable...\n", .{});
    const exe_name = linkObjectFiles(allocator, config, object_files) catch |err| {
        // Clean up object files
        cleanObjectFiles(object_files, project_folder, config.verbose);
        return err;
    };

    print("Build successful!\n\n", .{});
    return exe_name;
}

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
            return BuildError.InvalidFolder;
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
    var config = parser.parser(allocator, w) catch |err| {
        try errors.handleError(err, w);
        std.process.exit(1);
    };
    defer config.deinit(allocator);

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

    try w.writeAll("\n");
    return 0;
}
