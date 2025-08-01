const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Config = struct {
    project: ?[]const u8 = null,
    source: ?[]const u8 = null,
    output: ?[]const u8 = null,
    debug: bool = true,
    verbose: bool = true,
    run: bool = true,

    fn deinit(self: *Config, allocator: Allocator) void {
        if (self.project) |f| allocator.free(f);
        if (self.source) |s| allocator.free(s);
        if (self.output) |o| allocator.free(o);
    }
};

const BuildError = error{
    NoSourceFiles,
    CompilationFailed,
    ExecutionFailed,
    InvalidFolder,
};

fn printUsage() void {
    print("zmake - C Project Builder\n\n", .{});
    print("Usage: zmake [OPTIONS]\n\n", .{});
    print("Options:\n", .{});
    print("  --folder <path>     Specify the project folder (required)\n", .{});
    print("  --no-debug          Don't set debug\n", .{});
    print("  --no-run            Don't run the program after building\n", .{});
    print("  --no-verbose        Don't enable verbose output\n", .{});
    print("  --help              Show this help message\n\n", .{});
}

fn parseArgs(allocator: Allocator) !Config {
    var args = std.process.args();

    var config = Config{};

    _ = args.skip(); // Skip program name
    while (args.next()) |arg| {
        // option: help
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            printUsage();
            std.process.exit(0);
        }

        if (std.mem.eql(u8, arg, "--folder")) {
            if (args.next()) |folder| {
                config.project = try allocator.dupe(u8, folder);
                // find source folder into the project folder
                const source = try std.fmt.allocPrint(allocator, "{s}/src", .{folder});
                defer allocator.free(source);
                config.source = try allocator.dupe(u8, source);
            } else {
                print("Error: --folder requires a path argument\n", .{});
                return error.InvalidArgument;
            }
        }

        if (std.mem.eql(u8, arg, "--output")) {
            if (args.next()) |output| {
                config.output = try allocator.dupe(u8, output);
            } else {
                print("Error: --output requires a path argument\n", .{});
                return error.InvalidArgument;
            }
        }

        if (std.mem.eql(u8, arg, "--no-debug")) {
            config.verbose = false;
        }

        if (std.mem.eql(u8, arg, "--no-run")) {
            config.run = false;
        }

        if (std.mem.eql(u8, arg, "--no-verbose")) {
            config.verbose = false;
        }
    }

    // check if folder option which is required, exists
    if (config.project == null) {
        print("Error: --folder is required\n", .{});
        print("Use --help for usage information\n", .{});
        return error.InvalidArgument;
    }

    return config;
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

    var iterator = dir.iterate();
    while (try iterator.next()) |entry| {
        if (entry.kind == .file) {
            const name = entry.name;
            // get only c files
            if (std.mem.endsWith(u8, name, ".c")) {
                const full_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ folder, name });
                try source_files.append(full_path);
            }
        }
    }

    if (source_files.items.len == 0) {
        print("Error: No .c files found in folder '{s}'\n", .{folder});
        return BuildError.NoSourceFiles;
    }

    return source_files;
}

fn buildProject(allocator: Allocator, config: *const Config, source_files: ArrayList([]const u8)) ![]const u8 {
    var cmd_args = ArrayList([]const u8).init(allocator);
    defer cmd_args.deinit();

    // Add compiler
    try cmd_args.append("gcc");

    // Add flags
    try cmd_args.append("-Wall");
    try cmd_args.append("-Wextra");
    try cmd_args.append("-pedantic");
    try cmd_args.append("-std=c23");

    // Add source files
    for (source_files.items) |file| {
        try cmd_args.append(file);
    }

    // Add output
    const output_name = config.output orelse "main";
    try cmd_args.append("-o");
    try cmd_args.append(output_name);

    if (config.verbose) {
        print("Building with command: ", .{});
        for (cmd_args.items) |arg| {
            print("{s} ", .{arg});
        }
        print("\n", .{});
    }

    // Execute build command
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
                print("Build failed with exit code: {d}\n", .{code});
                return BuildError.CompilationFailed;
            }
        },
        else => {
            print("Build process terminated unexpectedly\n", .{});
            return BuildError.CompilationFailed;
        },
    }

    print("Build successful!\n", .{});
    return try allocator.dupe(u8, output_name);
}

fn runExecutable(allocator: Allocator, exe_name: []const u8, verbose: bool) !void {
    if (verbose) {
        print("Running: ./{s}\n", .{exe_name});
    }

    const cmd_args = [_][]const u8{std.fmt.allocPrint(allocator, "./{s}", .{exe_name}) catch return};
    defer allocator.free(cmd_args[0]);

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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // firstly, parse command arguments and check which are required
    var config = parseArgs(allocator) catch {
        std.process.exit(1);
    };
    defer config.deinit(allocator);

    // secondly, find c and h files into the source project folder
    const source_files = findSourceFiles(allocator, config.source.?) catch {
        std.process.exit(1);
    };
    defer {
        for (source_files.items) |file| {
            allocator.free(file);
        }
        source_files.deinit();
    }
    if (config.verbose) {
        print("Found {d} source files:\n", .{source_files.items.len});
        for (source_files.items) |file| {
            print("  {s}\n", .{file});
        }
    }

    // thirdly, build the project
    const exe_name = buildProject(allocator, &config, source_files) catch {
        std.process.exit(1);
    };
    defer allocator.free(exe_name);

    // fourthly, run the project
    if (config.run_after_build) {
        runExecutable(allocator, exe_name, config.verbose) catch {
            std.process.exit(1);
        };
    }
}
