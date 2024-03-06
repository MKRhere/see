const std = @import("std");

fn ls(cwd: std.fs.Dir, input: []const u8, writer: std.fs.File.Writer) !void {
    var it = (try cwd.openDir(input, .{ .iterate = true })).iterate();
    var buf = std.io.bufferedWriter(writer);
    const bufWriter = buf.writer();
    while (try it.next()) |entry|
        try bufWriter.print("{s}\n", .{entry.name});
    try buf.flush();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const input = if (args.len > 1) args[1] else ".";

    const stdout = std.io.getStdOut();
    const cwd = std.fs.cwd();

    if (cwd.openFile(input, .{})) |file| {
        defer file.close();
        switch ((try file.stat()).kind) {
            .file => try stdout.writeFileAll(file, .{}),
            .directory => try ls(cwd, input, stdout.writer()),
            else => {},
        }
    } else |err| {
        if (err != error.IsDir) return err;
        try ls(cwd, input, stdout.writer());
    }
}
