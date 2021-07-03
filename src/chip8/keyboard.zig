const std = @import("std");
const assert = std.debug.assert;

const cpu = @import("cpu.zig");

// Original keyboard layout:
// 1  2  3  C
// 4  5  6  D
// 7  8  9  E
// A  0  B  F
const KeyIDCount: u8 = 16;

pub fn is_key_pressed(state: *cpu.CPUState, key: u8) bool {
    assert(key < KeyIDCount); // Invalid key

    return (state.keyState & @intCast(u16, @as(u16, 1) << @intCast(u4, key))) > 0;
}

// If multiple keys are pressed at the same time, only register one.
pub fn get_key_pressed(keyState: u16) u8 {
    assert(keyState != 0);

    var i: u4 = 0;
    while (i < 16) {
        if (((@intCast(u16, 1) << i) & keyState) > 0)
            return i;

        i += 1;
    }

    assert(false);
    return 0x0;
}

pub fn set_key_pressed(state: *cpu.CPUState, key: u8, pressedState: bool) void {
    assert(key < KeyIDCount); // Invalid key

    const keyMask = @intCast(u16, 1) << @intCast(u4, key);
    state.keyState = (state.keyState & ~keyMask) | (if (pressedState) keyMask else 0);
}
