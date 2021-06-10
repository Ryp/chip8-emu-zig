const std = @import("std");
const assert = std.debug.assert;

const VRegisterCount: u32 = 16;
const StackSize: u32 = 16;
const MemorySizeInBytes: u32 = 0x1000;

// Fonts
const FontTableGlyphCount: u32 = 16;
const GlyphSizeInBytes: u16 = 5;

// Display
const ScreenWidth: u32 = 64;
const ScreenHeight: u32 = 32;
const ScreenLineSizeInBytes: u32 = ScreenWidth / 8;

// Memory
const MinProgramAddress: u16 = 0x0200;
const MaxProgramAddress: u16 = 0x0FFF;

// Timings
const DelayTimerFrequency: u32 = 60;
const InstructionExecutionFrequency: u32 = 500;
const DelayTimerPeriodMs: u32 = 1000 / DelayTimerFrequency;
const InstructionExecutionPeriodMs: u32 = 1000 / InstructionExecutionFrequency;

const VRegisterName = enum { V0, V1, V2, V3, V4, V5, V6, V7, V8, V9, VA, VB, VC, VD, VE, VF };

pub const CPUState = struct {
    pc: u16,
    sp: u8,
    stack: [StackSize]u16,
    vRegisters: [VRegisterCount]u8,
    i: u16,

    delayTimer: u8,
    soundTimer: u8,

    // Implementation detail
    delayTimerAccumulator: u32,
    executionTimerAccumulator: u32,

    memory: []u8, // FIXME so this is a slice?

    keyState: u16,

    keyStatePrev: u16,
    isWaitingForKey: bool,

    fontTableOffsets: [FontTableGlyphCount]u16,
    screen: [ScreenHeight][ScreenLineSizeInBytes]u8,
};

const FontTableOffsetInBytes: u16 = 0x0000;
const FontTable = [FontTableGlyphCount][GlyphSizeInBytes]u8{
    [_]u8{ 0xF0, 0x90, 0x90, 0x90, 0xF0 }, // 0
    [_]u8{ 0x20, 0x60, 0x20, 0x20, 0x70 }, // 1
    [_]u8{ 0xF0, 0x10, 0xF0, 0x80, 0xF0 }, // etc...
    [_]u8{ 0xF0, 0x10, 0xF0, 0x10, 0xF0 },
    [_]u8{ 0x90, 0x90, 0xF0, 0x10, 0x10 },
    [_]u8{ 0xF0, 0x80, 0xF0, 0x10, 0xF0 },
    [_]u8{ 0xF0, 0x80, 0xF0, 0x90, 0xF0 },
    [_]u8{ 0xF0, 0x10, 0x20, 0x40, 0x40 },
    [_]u8{ 0xF0, 0x90, 0xF0, 0x90, 0xF0 },
    [_]u8{ 0xF0, 0x90, 0xF0, 0x10, 0xF0 },
    [_]u8{ 0xF0, 0x90, 0xF0, 0x90, 0x90 },
    [_]u8{ 0xE0, 0x90, 0xE0, 0x90, 0xE0 },
    [_]u8{ 0xF0, 0x80, 0x80, 0x80, 0xF0 },
    [_]u8{ 0xE0, 0x90, 0x90, 0x90, 0xE0 },
    [_]u8{ 0xF0, 0x80, 0xF0, 0x80, 0xF0 },
    [_]u8{ 0xF0, 0x80, 0xF0, 0x80, 0x80 },
};

fn load_font_table(state: *CPUState) void {
    const tableOffset: u16 = FontTableOffsetInBytes;
    const tableSize: u16 = FontTableGlyphCount * GlyphSizeInBytes;

    // Make sure we don't spill in program addressable space.
    assert((tableOffset + tableSize - 1) < MinProgramAddress);

    // Copy font table into memory
    for (FontTable) |glyphs, i| {
        for (glyphs) |byte, j| {
            const offset: u16 = FontTableOffsetInBytes + @intCast(u16, i) * GlyphSizeInBytes + @intCast(u16, j);
            state.memory[offset] = byte;
        }
    }

    // Assing font table addresses in memory
    for (state.fontTableOffsets) |*value, i| {
        value.* = tableOffset + GlyphSizeInBytes * @intCast(u16, i);
    }
}

pub fn createCPUState() !CPUState {
    var state: CPUState = std.mem.zeroes(CPUState);

    const allocator: *std.mem.Allocator = std.heap.page_allocator;

    // Leave the memory uninitialized. This is very useful when debugging with valgrind.
    state.memory = try allocator.alloc(u8, MemorySizeInBytes);
    errdefer allocator.free(state.memory);

    // Set PC to first address
    state.pc = MinProgramAddress;

    load_font_table(&state);

    return state;
}

pub fn destroyCPUState(state: *CPUState) void {
    const allocator: *std.mem.Allocator = std.heap.page_allocator;

    allocator.free(state.memory);

    state.memory = undefined;
}
