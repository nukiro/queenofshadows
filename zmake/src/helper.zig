const std = @import("std");

const print = std.debug.print;

pub fn menu() void {
    print("zmake - C Project Builder\n\n", .{});
    print("Usage: zmake [OPTIONS]\n\n", .{});
    print("Options:\n", .{});
    print("  --folder <path>     Specify the project folder (required)\n", .{});
    print("  --clean             Clean all project artifacts\n", .{});
    print("  --static-library    Build C static library\n", .{});
    print("  --no-debug          Don't set debug\n", .{});
    print("  --no-run            Don't run the program after building\n", .{});
    print("  --no-verbose        Don't enable verbose output\n", .{});
    print("  --help              Show this help message\n\n", .{});
}
