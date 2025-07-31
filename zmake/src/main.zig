const std = @import("std");
const print = std.debug.print;

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

fn parseArgs() !void {
    var args = std.process.args();
    _ = args.skip(); // Skip program name

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            printUsage();
            std.process.exit(0);
        } else {
            print("Error: Unknown argument '{s}'\n", .{arg});
            print("Use --help for usage information\n", .{});
            return error.InvalidArgument;
        }
    }
}

pub fn main() !void {
    parseArgs() catch {
        std.process.exit(1);
    };
}
