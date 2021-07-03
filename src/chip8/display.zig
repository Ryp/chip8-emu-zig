const std = @import("std");
const assert = std.debug.assert;

const cpu = @import("cpu.zig");

pub fn read_screen_pixel(state: *cpu.CPUState, x: u32, y: u32) u8 {
    const screenOffsetByte = x / 8;
    const screenOffsetBit = @intCast(u3, x % 8);

    const value = (state.screen[y][screenOffsetByte] >> screenOffsetBit) & 0x1;

    assert(value == 0 or value == 1);

    return value;
}

pub fn write_screen_pixel(state: *cpu.CPUState, x: u32, y: u32, value: u8) void {
    assert(value == 0 or value == 1);

    const screenOffsetByte = x / 8;
    const screenOffsetBit = @intCast(u3, x % 8);

    const mask: u8 = @as(u8, 1) << screenOffsetBit;
    const screenByteValue = state.screen[y][screenOffsetByte];

    state.screen[y][screenOffsetByte] = (screenByteValue & ~mask) | (value << screenOffsetBit);
}
