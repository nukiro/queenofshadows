const std = @import("std");

const action = @import("action.zig");
const helper = @import("helper.zig");
const errors = @import("errors.zig");

const Allocator = std.mem.Allocator;

const print = std.debug.print;
const eql = std.mem.eql;

fn parseFolder(perform: *action.Action, allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    if (args.next()) |folder| {
        perform.project = try allocator.dupe(u8, folder);
        // find source folder into the project folder
        const source = try std.fmt.allocPrint(allocator, "{s}/src", .{folder});
        defer allocator.free(source);
        perform.source = try allocator.dupe(u8, source);
    } else {
        return errors.ParserError.InvalidFolderPath;
    }
}

fn parseBuild(perform: *action.Action, allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    while (args.next()) |arg| {
        // folder argument (required)
        if (std.mem.eql(u8, arg, "--folder")) {
            try parseFolder(perform, allocator, args);
        }

        if (std.mem.eql(u8, arg, "--output")) {
            if (args.next()) |output| {
                perform.output = try allocator.dupe(u8, output);
            } else {
                return errors.ParserError.InvalidOutputPath;
            }
        }

        if (std.mem.eql(u8, arg, "--no-debug")) {
            perform.debug = false;
        }

        if (std.mem.eql(u8, arg, "--no-run")) {
            perform.run_after_build = false;
        }

        if (std.mem.eql(u8, arg, "--no-verbose")) {
            perform.verbose = false;
        }

        if (std.mem.eql(u8, arg, "--static-library")) {
            perform.static_library = true;
            perform.executable = false;
        }
    }
}

fn parseClean(perform: *action.Action, allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    while (args.next()) |arg| {
        // folder argument (required)
        if (std.mem.eql(u8, arg, "--folder")) {
            try parseFolder(perform, allocator, args);
        }

        if (std.mem.eql(u8, arg, "--no-verbose")) {
            perform.verbose = false;
        }
    }
}

pub fn parser(allocator: Allocator, writer: std.fs.File.Writer) !action.Action {
    var args = std.process.args();
    _ = args.skip(); // Skip program name

    var perform = action.Action.init();

    // == Parse Mandatory Arguments [COMMAND] ==
    // next argument after program name must be the command which will be perfomed
    const command = action.Command.serialize(args.next()) orelse return errors.ParserError.InvalidCommand;
    perform.command = command;

    // == Parse Optional Arguments [OPTIONS] by command ==
    switch (perform.command) {
        .help => try helper.menu(allocator, writer),
        .build => try parseBuild(&perform, allocator, &args),
        .clean => try parseClean(&perform, allocator, &args),
    }

    // check if all required options exists
    if (perform.project == null) {
        return errors.ParserError.InvalidFolder;
    }

    return perform;
}
