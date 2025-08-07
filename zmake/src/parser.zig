const std = @import("std");
const configuration = @import("config.zig");
const helper = @import("helper.zig");

const Allocator = std.mem.Allocator;
const print = std.debug.print;
const Config = configuration.Config;

pub fn arguments(allocator: Allocator) !Config {
    var args = std.process.args();

    var config = Config{};

    _ = args.skip(); // Skip program name
    while (args.next()) |arg| {
        // option: help
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            helper.menu();
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

        if (std.mem.eql(u8, arg, "--clean")) {
            config.clean_only = true;
        }

        if (std.mem.eql(u8, arg, "--no-debug")) {
            config.debug = false;
        }

        if (std.mem.eql(u8, arg, "--no-run")) {
            config.run_after_build = false;
        }

        if (std.mem.eql(u8, arg, "--no-verbose")) {
            config.verbose = false;
        }

        if (std.mem.eql(u8, arg, "--static-library")) {
            config.static_library = true;
            config.executable = false;
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
