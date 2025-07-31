const std = @import("std");
const print = std.debug.print;
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

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var config = parseArgs(allocator) catch {
        std.process.exit(1);
    };
    defer config.deinit(allocator);
}
