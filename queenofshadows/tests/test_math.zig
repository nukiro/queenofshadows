const std = @import("std");
const c = @cImport({
    @cInclude("mathlib.h");
});

const Operation = c.Operation;
const OpType = c.OpType;

const OperationError = error{ DivideByZero, InvalidOperation };

pub fn safeRunOperation(op: Operation) OperationError!i32 {
    return switch (op.op) {
        c.OP_ADD, c.OP_SUB, c.OP_MUL => c.run_operation(op),
        c.OP_DIV => if (op.b != 0)
            c.run_operation(op)
        else
            error.DivideByZero,
        else => error.InvalidOperation,
    };
}

test "C add and mul" {
    try std.testing.expect(c.add(2, 3) == 5);
    try std.testing.expect(c.mul(2, 4) == 8);
}

test "C struct and enum: run_operation with OP_ADD" {
    const op: c.Operation = .{
        .a = 10,
        .b = 5,
        .op = c.OP_ADD,
    };
    try std.testing.expect(c.run_operation(op) == 15);
}

test "run_operation handles division" {
    const op: c.Operation = .{
        .a = 20,
        .b = 4,
        .op = c.OP_DIV,
    };
    try std.testing.expect(c.run_operation(op) == 5);
}

test "safeRunOperation handles valid operations" {
    const op: c.Operation = .{ .a = 7, .b = 3, .op = c.OP_SUB };
    const result = try safeRunOperation(op);
    try std.testing.expect(result == 4);
}

test "safeRunOperation prevents division by zero" {
    const op: c.Operation = .{ .a = 10, .b = 0, .op = c.OP_DIV };
    const result = safeRunOperation(op);
    try std.testing.expectError(error.DivideByZero, result);
}

test "safeRunOperation catches invalid enum" {
    const op: c.Operation = .{ .a = 1, .b = 1, .op = @as(c.OpType, @intCast(9999)) };
    const result = safeRunOperation(op);
    try std.testing.expectError(error.InvalidOperation, result);
}
