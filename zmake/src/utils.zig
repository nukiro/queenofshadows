const std = @import("std");

pub fn lowercase(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const result = try allocator.alloc(u8, input.len);

    for (input, result) |char, *out_char| {
        if (char >= 'A' and char <= 'Z') {
            out_char.* = char + 32;
        } else {
            out_char.* = char;
        }
    }

    return result;
}

test "utils -> lowercase: converts uppercase letters to lowercase" {
    const allocator = std.testing.allocator;

    const input = "HELLO";

    const result = try lowercase(allocator, input);
    defer allocator.free(result);

    try std.testing.expectEqualStrings("hello", result);
}
