const std = @import("std");

// Days in each month (non-leap year)
const DAYS_IN_MONTH = [_]u8{ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
// Cumulative days from start of year to start of each month (non-leap year)
const DAYS_BEFORE_MONTH = [_]u16{ 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334 };

fn isLeapYear(year: u32) bool {
    return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0);
}

fn daysInMonth(year: u32, month: u8) u8 {
    if (month == 2 and isLeapYear(year)) {
        return 29;
    }
    return DAYS_IN_MONTH[month - 1];
}

fn calculateFormMillis(unix_millis: i64) DateTime {
    // Extract milliseconds
    const millis = @as(u16, @intCast(@mod(unix_millis, 1000)));

    // Convert to seconds
    const unix_seconds = @divFloor(unix_millis, 1000);

    // Calculate days since Unix epoch (1970-01-01)
    const seconds_per_day = 86400;
    const days_since_epoch = @divFloor(unix_seconds, seconds_per_day);

    // Calculate seconds within the day
    const seconds_in_day = @mod(unix_seconds, seconds_per_day);

    // Calculate time components
    const hour = @as(u8, @intCast(@divFloor(seconds_in_day, 3600)));
    const minute = @as(u8, @intCast(@divFloor(@mod(seconds_in_day, 3600), 60)));
    const second = @as(u8, @intCast(@mod(seconds_in_day, 60)));

    // Calculate weekday (January 1, 1970 was a Thursday = 4)
    const weekday = @as(u8, @intCast(@mod(days_since_epoch + 4, 7)));

    // Calculate year, month, day
    var year: u32 = 1970;
    var remaining_days = days_since_epoch;

    // Handle years
    while (true) {
        const days_in_year: i64 = if (isLeapYear(year)) 366 else 365;
        if (remaining_days < days_in_year) break;
        remaining_days -= days_in_year;
        year += 1;
    }

    // Handle months
    var month: u8 = 1;
    while (month <= 12) {
        const days_in_current_month = daysInMonth(year, month);
        if (remaining_days < days_in_current_month) break;
        remaining_days -= days_in_current_month;
        month += 1;
    }

    // Remaining days is the day of month (1-based)
    const day = @as(u8, @intCast(remaining_days + 1));

    return DateTime{
        .year = year,
        .month = month,
        .day = day,
        .hour = hour,
        .minute = minute,
        .second = second,
        .millisecond = millis,
        .weekday = weekday,
    };
}

pub const DateTime = struct {
    year: u32,
    month: u8, // 1-12
    day: u8, // 1-31
    hour: u8, // 0-23
    minute: u8, // 0-59
    second: u8, // 0-59
    millisecond: u16, // 0-999
    weekday: u8, // 0=Sunday, 1=Monday, ..., 6=Saturday

    pub fn format(
        self: DateTime,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{:04}-{:02}-{:02} {:02}:{:02}:{:02}.{:03}", .{ self.year, self.month, self.day, self.hour, self.minute, self.second, self.millisecond });
    }

    pub fn ISO(self: DateTime, allocator: std.mem.Allocator) ![]u8 {
        return std.fmt.allocPrint(allocator, "{:04}-{:02}-{:02}T{:02}:{:02}:{:02}.{:03}Z", .{ self.year, self.month, self.day, self.hour, self.minute, self.second, self.millisecond });
    }

    pub fn date(self: DateTime, allocator: std.mem.Allocator) ![]u8 {
        return std.fmt.allocPrint(allocator, "{:04}-{:02}-{:02}", .{ self.year, self.month, self.day });
    }

    pub fn time(self: DateTime, allocator: std.mem.Allocator) ![]u8 {
        return std.fmt.allocPrint(allocator, "{:02}:{:02}:{:02}", .{ self.hour, self.minute, self.second });
    }

    pub fn now() DateTime {
        return calculateFormMillis(std.time.milliTimestamp());
    }

    pub fn from(unix_millis: i64) DateTime {
        return calculateFormMillis(unix_millis);
    }
};

test "from 0" {
    const allocator = std.testing.allocator;
    const dt = try DateTime.from(0).ISO(allocator);
    defer allocator.free(dt);

    try std.testing.expectEqualStrings("1970-01-01T00:00:00.000Z", dt);
}
