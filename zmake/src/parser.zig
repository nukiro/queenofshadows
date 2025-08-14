const std = @import("std");

const action = @import("action.zig");
const helper = @import("helper.zig");
const errors = @import("errors.zig");

const Allocator = std.mem.Allocator;

const eql = std.mem.eql;

fn parseFolder(allocator: std.mem.Allocator, perform: *action.Action, args: *std.process.ArgIterator) !void {
    // next argument after --folder which was found in the previous one
    if (args.next()) |folder| {
        perform.folder = try allocator.dupe(u8, folder);
    } else {
        return errors.List.ParserInvalidFolderPath;
    }
}

fn parseBuild(allocator: std.mem.Allocator, perform: *action.Action, args: *std.process.ArgIterator) !void {
    // init build structure
    var build = try action.Build.init(allocator);

    // parse arguments
    while (args.next()) |arg| {
        if (eql(u8, arg, "--folder")) {
            try parseFolder(allocator, perform, args);
        }

        if (eql(u8, arg, "--no-verbose")) {
            perform.verbose = false;
        }

        // specific arguments
        if (eql(u8, arg, "--output")) {
            if (args.next()) |output| {
                build.output = try allocator.dupe(u8, output);
            } else {
                return errors.List.ParserInvalidOutputPath;
            }
        }

        if (eql(u8, arg, "--no-debug")) {
            build.debug = false;
        }

        if (eql(u8, arg, "--library")) {
            build.executable = false;
        }

        if (eql(u8, arg, "--no-run")) {
            build.run = false;
        }
    }

    perform.build = build;
}

fn parseClean(allocator: std.mem.Allocator, perform: *action.Action, args: *std.process.ArgIterator) !void {
    while (args.next()) |arg| {
        if (eql(u8, arg, "--folder")) {
            try parseFolder(allocator, perform, args);
        }

        if (eql(u8, arg, "--no-verbose")) {
            perform.verbose = false;
        }
    }
}

pub fn parser(allocator: Allocator, writer: std.fs.File.Writer) !action.Action {
    var args = std.process.args();
    // skip program name
    _ = args.skip();

    // init performing action with default values (help command)
    var perform = try action.Action.init(allocator);

    // next argument after program name (which was skipped)
    // must be the command which will be perfomed
    const command = action.Command.serialize(args.next()) orelse {
        try helper.main(allocator, writer, .help);
        return errors.List.ParserInvalidCommand;
    };
    // update performing action with the command
    perform.command = command;

    // parse command argument by command
    switch (perform.command) {
        .build => parseBuild(allocator, &perform, &args) catch |err| {
            try helper.main(allocator, writer, .build);
            return err;
        },
        .clean => parseClean(allocator, &perform, &args) catch |err| {
            try helper.main(allocator, writer, .clean);
            return err;
        },
        .help => {}, // do nothing
    }

    return perform;
}
