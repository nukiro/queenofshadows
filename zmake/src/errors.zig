const std = @import("std");

pub const _ = error{
    BuildNoSourceFiles,
    BuildCompilationFailed,
    BuildExecutionFailed,
    BuildInvalidFolder,
    ParserInvalidCommand,
    ParserInvalidFolder,
    ParserInvalidFolderPath,
    ParserInvalidOutputPath,
};
