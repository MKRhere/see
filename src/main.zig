const std = @import("std");
const fs = std.fs;
const path = std.fs.path;

const File = std.fs.File;
const Dir = std.fs.Dir;

const allocator = std.heap.page_allocator;

fn printAll(reader: anytype) !void {
    const stdout = std.io.getStdOut().writer();

    var buffer: [100]u8 = undefined;
    try reader.seekTo(0);

    var bytes_read: usize = try reader.readAll(&buffer);
    while (bytes_read != 0) : (bytes_read = try reader.readAll(&buffer)) {
        try stdout.print("{s}", .{buffer});
        buffer = [_]u8{0} ** @intCast(u8, 100);
    }
}

pub fn main() anyerror!void {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const input = if (args.len > 1) args[1] else ".";

    const stdout = std.io.getStdOut().writer();

    const cwd = fs.cwd();
    const file = try cwd.openFile(input, .{});
    defer file.close();
    const stat = try file.stat();

    switch (stat.kind) {
        File.Kind.File => {
            try printAll(file);
        },
        File.Kind.Directory => {
            const dir = try cwd.openDir(input, .{ .iterate = true });
            var iter = dir.iterate();

            while (try iter.next()) |entry| {
                try stdout.print("{s}\n", .{entry.name});
            }
        },
        else => {},
    }
}
