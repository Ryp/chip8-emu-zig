const std = @import("std");
const assert = std.debug.assert;

const chip8 = @import("chip8/chip8.zig");
const sdl2 = @import("sdl2/sdl2_backend.zig");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = &general_purpose_allocator.allocator;

    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    assert(args.len == 2);

    var config: chip8.EmuConfig = undefined;

    config.palette.primary = chip8.Color{ .r = 1.0, .g = 1.0, .b = 1.0 };
    config.palette.secondary = chip8.Color{ .r = 0.14, .g = 0.14, .b = 0.14 };
    config.screenScale = 8;

    var cpu_state = try chip8.createCPUState();
    defer chip8.destroyCPUState(&cpu_state);

    // Load program in chip8 memory
    {
        std.debug.print("[INFO] loading program: {s}\n", .{args[1]});

        var file = try std.fs.cwd().openFile(args[1], .{});
        defer file.close();

        var buffer: [1024 * 4]u8 = undefined;
        const bytes_read = try file.read(buffer[0..buffer.len]);

        std.debug.print("[INFO] rom size: {}\n", .{bytes_read});
        std.debug.print("[INFO] program loaded\n", .{});

        chip8.load_program(&cpu_state, buffer[0..bytes_read]);
    }

    try sdl2.execute_main_loop(&cpu_state, config);
}
