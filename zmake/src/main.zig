const std = @import("std");
const print = std.debug.print;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Config = struct {
    folder: ?[]const u8 = null,
    output: ?[]const u8 = null,
    debug: bool = false,
    verbose: bool = false,
    compiler: []const u8 = "gcc",
    run_after_build: bool = true,

    fn deinit(self: *Config, allocator: Allocator) void {
        if (self.folder) |f| allocator.free(f);
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
    print("  -o <key>=<value>    Set build options (debug=true/false, output=name)\n", .{});
    print("  --compiler <name>   Specify compiler (default: gcc)\n", .{});
    print("  --no-run           Don't run the program after building\n", .{});
    print("  --verbose          Enable verbose output\n", .{});
    print("  --help             Show this help message\n\n", .{});
    print("Examples:\n", .{});
    print("  zmake --folder playground/camera -o debug=true\n", .{});
    print("  zmake --folder myproject -o output=myapp -o debug=false\n", .{});
    print("  zmake --folder src --compiler clang --verbose\n", .{});
}

fn parseArgs(allocator: Allocator) !Config {
    var args = std.process.args();
    _ = args.skip(); // Skip program name

    var config = Config{};

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            printUsage();
            std.process.exit(0);
        } else if (std.mem.eql(u8, arg, "--folder")) {
            if (args.next()) |folder| {
                config.folder = try allocator.dupe(u8, folder);
            } else {
                print("Error: --folder requires a path argument\n", .{});
                return error.InvalidArgument;
            }
        } else if (std.mem.eql(u8, arg, "--compiler")) {
            if (args.next()) |compiler| {
                config.compiler = compiler;
            } else {
                print("Error: --compiler requires a compiler name\n", .{});
                return error.InvalidArgument;
            }
        } else if (std.mem.eql(u8, arg, "--no-run")) {
            config.run_after_build = false;
        } else if (std.mem.eql(u8, arg, "--verbose")) {
            config.verbose = true;
        } else if (std.mem.eql(u8, arg, "-o")) {
            if (args.next()) |option| {
                try parseOption(&config, allocator, option);
            } else {
                print("Error: -o requires a key=value argument\n", .{});
                return error.InvalidArgument;
            }
        } else {
            print("Error: Unknown argument '{s}'\n", .{arg});
            print("Use --help for usage information\n", .{});
            return error.InvalidArgument;
        }
    }

    if (config.folder == null) {
        print("Error: --folder is required\n", .{});
        print("Use --help for usage information\n", .{});
        return error.InvalidArgument;
    }

    return config;
}

fn parseOption(config: *Config, allocator: Allocator, option: []const u8) !void {
    if (std.mem.indexOf(u8, option, "=")) |eq_pos| {
        const key = option[0..eq_pos];
        const value = option[eq_pos + 1 ..];

        if (std.mem.eql(u8, key, "debug")) {
            if (std.mem.eql(u8, value, "true")) {
                config.debug = true;
            } else if (std.mem.eql(u8, value, "false")) {
                config.debug = false;
            } else {
                print("Error: debug option must be 'true' or 'false'\n", .{});
                return error.InvalidArgument;
            }
        } else if (std.mem.eql(u8, key, "output")) {
            config.output = try allocator.dupe(u8, value);
        } else {
            print("Warning: Unknown option '{s}'\n", .{key});
        }
    } else {
        print("Error: Option must be in key=value format\n", .{});
        return error.InvalidArgument;
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

    var iterator = dir.iterate();
    while (try iterator.next()) |entry| {
        if (entry.kind == .file) {
            const name = entry.name;
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
    try cmd_args.append(config.compiler);

    // Add debug flags
    if (config.debug) {
        try cmd_args.append("-g");
        try cmd_args.append("-DDEBUG");
    } else {
        try cmd_args.append("-O2");
        try cmd_args.append("-DNDEBUG");
    }

    // Add source files
    for (source_files.items) |file| {
        try cmd_args.append(file);
    }

    // Add output
    const output_name = config.output orelse "main";
    try cmd_args.append("-o");
    try cmd_args.append(output_name);

    // Add common flags
    try cmd_args.append("-Wall");
    try cmd_args.append("-Wextra");

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

    var config = parseArgs(allocator) catch {
        std.process.exit(1);
    };
    defer config.deinit(allocator);

    const source_files = findSourceFiles(allocator, config.folder.?) catch {
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

    const exe_name = buildProject(allocator, &config, source_files) catch {
        std.process.exit(1);
    };
    defer allocator.free(exe_name);

    if (config.run_after_build) {
        runExecutable(allocator, exe_name, config.verbose) catch {
            std.process.exit(1);
        };
    }
}
