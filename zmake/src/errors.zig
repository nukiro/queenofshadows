const std = @import("std");

pub const List = error{
    BuildNoSourceFiles,
    BuildCompilationFailed,
    BuildExecutionFailed,
    BuildInvalidFolder,
    ParserInvalidCommand,
    ParserInvalidFolder,
    ParserInvalidFolderPath,
    ParserInvalidOutputPath,
};
