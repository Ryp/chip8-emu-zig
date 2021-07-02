const std = @import("std");
const assert = std.debug.assert;

const cpu = @import("cpu.zig");

pub const Usage = enum { Read, Write, Execute };

//pub fn load_u16_big_endian(rawMem: const []u8) u16 {
//    const u16 msb = static_cast<u16>((*rawMem) << 8);
//    const u16 lsb = static_cast<u16>(*(rawMem + 1));
//
//    return msb | lsb;
//}

// Returns true if the address range is read/writeable/executable by the program,
// false otherwise.
pub fn is_valid_range(baseAddress: u16, sizeInBytes: u16, usage: Usage) bool {
    assert(sizeInBytes > 0); // Invalid address range size

    const endAddress: u16 = baseAddress + (sizeInBytes - 1);

    if (endAddress < baseAddress)
        return false; // Overflow

    switch (usage) {
        .Read => {
            return endAddress <= cpu.MaxProgramAddress;
        },
        .Write, .Execute => {
            return baseAddress >= cpu.MinProgramAddress and endAddress <= cpu.MaxProgramAddress;
        },
    }
}
