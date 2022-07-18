const std = @import("std");

const fs = std.fs;
const File = std.fs.File;

fn copy(reader: File.Reader, writer: File.Writer) !void {
    var buf: [1024 * 1024 * 4]u8 = undefined;
    while (true) {
        const bytesRead = try reader.read(&buf);
        if (bytesRead == 0) return;
        try writer.writeAll(buf[0..bytesRead]);
    }
}

fn ls(cwd: std.fs.Dir, input: []const u8, writer: File.Writer) !void {
    var it = (try cwd.openIterableDir(input, .{})).iterate();
    while (try it.next()) |entry|
        try writer.print("{s}\n", .{entry.name});
}

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());
    var allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const input = if (args.len > 1) args[1] else ".";

    const stdout = std.io.getStdOut().writer();

    const cwd = fs.cwd();

    if (cwd.openFile(input, .{})) |file| {
        defer file.close();
        switch ((try file.stat()).kind) {
            .File => try copy(file.reader(), stdout),
            .Directory => try ls(cwd, input, stdout),
            else => {},
        }
    } else |err| {
        if (err != error.IsDir) return err;
        try ls(cwd, input, stdout);
    }
}
