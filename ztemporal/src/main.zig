const std = @import("std");
const ztemporal = @import("ztemporal_lib");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const test_timestamps = [_]i64{
        0, // 1970-01-01 00:00:00.000
        1234567890123, // 2009-02-13 23:31:30.123
        1640995200000, // 2022-01-01 00:00:00.000
        1704067200500, // 2024-01-01 00:00:00.500
        std.time.milliTimestamp(), // Current time
    };

    for (test_timestamps) |timestamp| {
        const dt = ztemporal.DateTime.from(timestamp);
        try stdout.print("Unix millis: {} -> {}\n", .{ timestamp, dt });
    }
}
