const std = @import("std");
const assert = std.debug.assert;

const cpu = @import("cpu.zig");
const memory = @import("memory.zig");
const keyboard = @import("keyboard.zig");
const display = @import("display.zig");

// Clear the display.
pub fn execute_cls(state: *cpu.CPUState) void {
    for (state.screen) |*row| {
        for (row) |*byte| {
            byte.* = 0x0;
        }
    }
}

// Return from a subroutine.
// The interpreter sets the program counter to the address at the top of the stack,
// then subtracts 1 from the stack pointer.
pub fn execute_ret(state: *cpu.CPUState) void {
    assert(state.sp > 0); // Stack Underflow

    const nextPC = state.stack[state.sp] + 2;
    assert(memory.is_valid_range(nextPC, 2, memory.Usage.Execute));

    state.pc = nextPC;
    state.sp = if (state.sp > 0) (state.sp - 1) else state.sp;
}

// Jump to a machine code routine at nnn.
// This instruction is only used on the old computers on which Chip-8 was originally implemented.
// NOTE: We choose to ignore it since we don't load any code into system memory.
pub fn execute_sys(state: *cpu.CPUState, address: u16) void {
    // noop
}

// Jump to location nnn.
// The interpreter sets the program counter to nnn.
pub fn execute_jp(state: *cpu.CPUState, address: u16) void {
    assert((address & 0x0001) == 0); // Unaligned address
    assert(memory.is_valid_range(address, 2, memory.Usage.Execute));

    state.pc = address;
}

// Call subroutine at nnn.
// The interpreter increments the stack pointer, then puts the current PC on the top of the stack.
// The PC is then set to nnn.
pub fn execute_call(state: *cpu.CPUState, address: u16) void {
    assert((address & 0x0001) == 0); // Unaligned address
    assert(memory.is_valid_range(address, 2, memory.Usage.Execute));

    assert(state.sp < cpu.StackSize); // Stack overflow

    state.sp = if (state.sp < cpu.StackSize) (state.sp + 1) else state.sp; // Increment sp
    state.stack[state.sp] = state.pc; // Put PC on top of the stack
    state.pc = address; // Set PC to new address
}

// Skip next instruction if Vx = kk.
// The interpreter compares register Vx to kk, and if they are equal,
// increments the program counter by 2.
pub fn execute_se(state: *cpu.CPUState, registerName: u8, value: u8) void {
    assert((registerName & 0xF0) == 0); // Invalid register
    assert(memory.is_valid_range(state.pc, 6, memory.Usage.Execute));

    const registerValue = state.vRegisters[registerName];

    if (registerValue == value)
        state.pc += 4;
}

// Skip next instruction if Vx != kk.
// The interpreter compares register Vx to kk, and if they are not equal,
// increments the program counter by 2.
pub fn execute_sne(state: *cpu.CPUState, registerName: u8, value: u8) void {
    const registerValue = state.vRegisters[registerName];

    assert((registerName & 0xF0) == 0); // Invalid register
    assert(memory.is_valid_range(state.pc, 6, memory.Usage.Execute));

    if (registerValue != value)
        state.pc += 4;
}

// Skip next instruction if Vx = Vy.
// The interpreter compares register Vx to register Vy, and if they are equal,
// increments the program counter by 2.
pub fn execute_se2(state: *cpu.CPUState, registerLHS: u8, registerRHS: u8) void {
    assert((registerLHS & 0xF0) == 0); // Invalid register
    assert((registerRHS & 0xF0) == 0); // Invalid register
    assert(memory.is_valid_range(state.pc, 6, memory.Usage.Execute));

    const registerValueLHS = state.vRegisters[registerLHS];
    const registerValueRHS = state.vRegisters[registerRHS];

    if (registerValueLHS == registerValueRHS)
        state.pc += 4;
}

// Set Vx = kk.
// The interpreter puts the value kk into register Vx.
pub fn execute_ld(state: *cpu.CPUState, registerName: u8, value: u8) void {
    assert((registerName & 0xF0) == 0); // Invalid register

    state.vRegisters[registerName] = value;
}

// Set Vx = Vx + kk.
// Adds the value kk to the value of register Vx, then stores the result in Vx.
// NOTE: Carry in NOT set.
// NOTE: Overflows will just wrap the value around.
pub fn execute_add(state: *cpu.CPUState, registerName: u8, value: u8) void {
    assert((registerName & 0xF0) == 0); // Invalid register

    const registerValue = state.vRegisters[registerName];
    const sum = registerValue +% value;

    state.vRegisters[registerName] = sum;
}

// Set Vx = Vy.
// Stores the value of register Vy in register Vx.
pub fn execute_ld2(state: *cpu.CPUState, registerLHS: u8, registerRHS: u8) void {
    assert((registerLHS & 0xF0) == 0); // Invalid register
    assert((registerRHS & 0xF0) == 0); // Invalid register

    state.vRegisters[registerLHS] = state.vRegisters[registerRHS];
}

// Set Vx = Vx OR Vy.
// Performs a bitwise OR on the values of Vx and Vy, then stores the result in Vx.
// A bitwise OR compares the corrseponding bits from two values, and if either bit is 1,
// then the same bit in the result is also 1. Otherwise, it is 0.
pub fn execute_or(state: *cpu.CPUState, registerLHS: u8, registerRHS: u8) void {
    assert((registerLHS & 0xF0) == 0); // Invalid register
    assert((registerRHS & 0xF0) == 0); // Invalid register

    state.vRegisters[registerLHS] |= state.vRegisters[registerRHS];
}

// Set Vx = Vx AND Vy.
// Performs a bitwise AND on the values of Vx and Vy, then stores the result in Vx.
// A bitwise AND compares the corrseponding bits from two values, and if both bits are 1,
// then the same bit in the result is also 1. Otherwise, it is 0.
pub fn execute_and(state: *cpu.CPUState, registerLHS: u8, registerRHS: u8) void {
    assert((registerLHS & 0xF0) == 0); // Invalid register
    assert((registerRHS & 0xF0) == 0); // Invalid register

    state.vRegisters[registerLHS] &= state.vRegisters[registerRHS];
}

// Set Vx = Vx XOR Vy.
// Performs a bitwise exclusive OR on the values of Vx and Vy, then stores the result in Vx.
// An exclusive OR compares the corrseponding bits from two values, and if the bits are not both the same,
// then the corresponding bit in the result is set to 1.  Otherwise, it is 0.
pub fn execute_xor(state: *cpu.CPUState, registerLHS: u8, registerRHS: u8) void {
    assert((registerLHS & 0xF0) == 0); // Invalid register
    assert((registerRHS & 0xF0) == 0); // Invalid register

    state.vRegisters[registerLHS] = state.vRegisters[registerLHS] ^ state.vRegisters[registerRHS];
}

// Set Vx = Vx + Vy, set VF = carry.
// The values of Vx and Vy are added together.
// If the result is greater than 8 bits (i.e., > 255,) VF is set to 1, otherwise 0.
// Only the lowest 8 bits of the result are kept, and stored in Vx.
pub fn execute_add2(state: *cpu.CPUState, registerLHS: u8, registerRHS: u8) void {
    assert((registerLHS & 0xF0) == 0); // Invalid register
    assert((registerRHS & 0xF0) == 0); // Invalid register

    const valueLHS = state.vRegisters[registerLHS];
    const valueRHS = state.vRegisters[registerRHS];
    const result = valueLHS +% valueRHS;

    state.vRegisters[registerLHS] = result;
    state.vRegisters[@enumToInt(cpu.Register.VF)] = if (result > valueLHS) 0 else 1; // Set carry
}

// Set Vx = Vx - Vy, set VF = NOT borrow.
// If Vx > Vy, then VF is set to 1, otherwise 0.
// Then Vy is subtracted from Vx, and the results stored in Vx.
pub fn execute_sub(state: *cpu.CPUState, registerLHS: u8, registerRHS: u8) void {
    assert((registerLHS & 0xF0) == 0); // Invalid register
    assert((registerRHS & 0xF0) == 0); // Invalid register

    const valueLHS = state.vRegisters[registerLHS];
    const valueRHS = state.vRegisters[registerRHS];
    const result = valueLHS -% valueRHS;

    state.vRegisters[registerLHS] = result;
    state.vRegisters[@enumToInt(cpu.Register.VF)] = if (valueLHS > valueRHS) 1 else 0; // Set carry
}

// Set Vx = Vx SHR 1.
// If the least-significant bit of Vx is 1, then VF is set to 1, otherwise 0.
// Then Vx is divided by 2.
// NOTE: registerRHS is just ignored apparently.
pub fn execute_shr1(state: *cpu.CPUState, registerLHS: u8, registerRHS: u8) void {
    assert((registerLHS & 0xF0) == 0); // Invalid register
    assert((registerRHS & 0xF0) == 0); // Invalid register

    const valueLHS = state.vRegisters[registerLHS];

    state.vRegisters[registerLHS] = valueLHS >> 1;
    state.vRegisters[@enumToInt(cpu.Register.VF)] = valueLHS & 0x01; // Set carry
}

// Set Vx = Vy - Vx, set VF = NOT borrow.
// If Vy > Vx, then VF is set to 1, otherwise 0.
// Then Vx is subtracted from Vy, and the results stored in Vx.
pub fn execute_subn(state: *cpu.CPUState, registerLHS: u8, registerRHS: u8) void {
    assert((registerLHS & 0xF0) == 0); // Invalid register
    assert((registerRHS & 0xF0) == 0); // Invalid register

    const valueLHS = state.vRegisters[registerLHS];
    const valueRHS = state.vRegisters[registerRHS];
    const result = valueRHS -% valueLHS;

    state.vRegisters[registerLHS] = result;
    state.vRegisters[@enumToInt(cpu.Register.VF)] = if (valueRHS > valueLHS) 1 else 0; // Set carry
}

// Set Vx = Vx SHL 1.
// If the most-significant bit of Vx is 1, then VF is set to 1, otherwise to 0. Then Vx is multiplied by 2.
// NOTE: registerRHS is just ignored apparently.
pub fn execute_shl1(state: *cpu.CPUState, registerLHS: u8, registerRHS: u8) void {
    assert((registerLHS & 0xF0) == 0); // Invalid register
    assert((registerRHS & 0xF0) == 0); // Invalid register

    const valueLHS = state.vRegisters[registerLHS];

    state.vRegisters[registerLHS] = valueLHS << 1;
    state.vRegisters[@enumToInt(cpu.Register.VF)] = if ((valueLHS & 0x80) > 0) 1 else 0; // Set carry
}

// Skip next instruction if Vx != Vy.
// The values of Vx and Vy are compared, and if they are not equal, the program counter is increased by 2.
pub fn execute_sne2(state: *cpu.CPUState, registerLHS: u8, registerRHS: u8) void {
    assert((registerLHS & 0xF0) == 0); // Invalid register
    assert((registerRHS & 0xF0) == 0); // Invalid register
    assert(memory.is_valid_range(state.pc, 6, memory.Usage.Execute));

    const valueLHS = state.vRegisters[registerLHS];
    const valueRHS = state.vRegisters[registerRHS];

    if (valueLHS != valueRHS)
        state.pc += 4;
}

// Set I = nnn.
// The value of register I is set to nnn.
pub fn execute_ldi(state: *cpu.CPUState, address: u16) void {
    state.i = address;
}

// Jump to location nnn + V0.
// The program counter is set to nnn plus the value of V0.
pub fn execute_jp2(state: *cpu.CPUState, baseAddress: u16) void {
    const offset: u16 = state.vRegisters[@enumToInt(cpu.Register.V0)];
    const targetAddress = baseAddress + offset;

    assert((targetAddress & 0x0001) == 0); // Unaligned address
    assert(memory.is_valid_range(targetAddress, 2, memory.Usage.Execute));

    state.pc = targetAddress;
}

// Set Vx = random byte AND kk.
// The interpreter generates a random number from 0 to 255, which is then ANDed with the value kk.
// The results are stored in Vx. See instruction 8xy2 for more information on AND.
pub fn execute_rnd(state: *cpu.CPUState, registerName: u8, value: u8) void {
    assert((registerName & 0xF0) == 0); // Invalid register

    const seed: u64 = 0x42;

    var rng = std.rand.DefaultPrng.init(seed);
    const randomValue = rng.random.int(u8);

    state.vRegisters[registerName] = randomValue & value;
}

// Display n-byte sprite starting at memory location I at (Vx, Vy), set VF = collision.
// The interpreter reads n bytes from memory, starting at the address stored in I.
// These bytes are then displayed as sprites on screen at coordinates (Vx, Vy).
// Sprites are XORed onto the existing screen. If this causes any pixels to be erased, VF is set to 1,
// otherwise it is set to 0.
// If the sprite is positioned so part of it is outside the coordinates of the display,
// it wraps around to the opposite side of the screen. See instruction 8xy3 for more information on XOR,
// and section 2.4, Display, for more information on the Chip-8 screen and sprites.
pub fn execute_drw(state: *cpu.CPUState, registerLHS: u8, registerRHS: u8, size: u8) void {
    assert((registerLHS & 0xF0) == 0); // Invalid register
    assert((registerRHS & 0xF0) == 0); // Invalid register
    assert(memory.is_valid_range(state.i, size, memory.Usage.Read));

    const spriteStartX: u32 = state.vRegisters[registerLHS];
    const spriteStartY: u32 = state.vRegisters[registerRHS];

    var collision = false;

    // Sprites are made of rows of 1 byte each.
    for (state.memory[state.i .. state.i + size]) |spriteRow, rowIndex| {
        const screenY: u32 = (spriteStartY + @intCast(u32, rowIndex)) % cpu.ScreenHeight;

        var pixelIndex: u32 = 0;
        while (pixelIndex < 8) {
            const spritePixelValue = (spriteRow >> (7 - @intCast(u3, pixelIndex))) & 0x1;
            const screenX = (spriteStartX + pixelIndex) % cpu.ScreenWidth;

            const screenPixelValue = display.read_screen_pixel(state, screenX, screenY);

            const result = screenPixelValue ^ spritePixelValue;

            // A pixel was erased
            if (screenPixelValue > 0 and result != 0)
                collision = true;

            display.write_screen_pixel(state, screenX, screenY, result);

            pixelIndex += 1;
        }
    }

    state.vRegisters[@enumToInt(cpu.Register.VF)] = if (collision) 1 else 0;
}

// Skip next instruction if key with the value of Vx is pressed.
// Checks the keyboard, and if the key corresponding to the value of Vx is currently in the down position,
// PC is increased by 2.
pub fn execute_skp(state: *cpu.CPUState, registerName: u8) void {
    assert((registerName & 0xF0) == 0); // Invalid register
    assert(memory.is_valid_range(state.pc, 6, memory.Usage.Execute));

    const keyID = state.vRegisters[registerName];

    if (keyboard.is_key_pressed(state, keyID))
        state.pc += 4;
}

// Skip next instruction if key with the value of Vx is not pressed.
// Checks the keyboard, and if the key corresponding to the value of Vx is currently in the up position,
// PC is increased by 2.
pub fn execute_sknp(state: *cpu.CPUState, registerName: u8) void {
    assert((registerName & 0xF0) == 0); // Invalid register
    assert(memory.is_valid_range(state.pc, 6, memory.Usage.Execute));

    const key = state.vRegisters[registerName];

    if (!keyboard.is_key_pressed(state, key))
        state.pc += 4;
}

// Set Vx = delay timer value.
// The value of DT is placed into Vx.
pub fn execute_ldt(state: *cpu.CPUState, registerName: u8) void {
    assert((registerName & 0xF0) == 0); // Invalid register

    state.vRegisters[registerName] = state.delayTimer;
}

// Wait for a key press, store the value of the key in Vx.
// All execution stops until a key is pressed, then the value of that key is stored in Vx.
pub fn execute_ldk(state: *cpu.CPUState, registerName: u8) void {
    assert((registerName & 0xF0) == 0); // Invalid register

    // If we enter for the first time, set the waiting flag.
    if (!state.isWaitingForKey) {
        state.isWaitingForKey = true;
    } else {
        const keyStatePressMask = ~state.keyStatePrev & state.keyState;
        // When waiting, check the key states.
        if (keyStatePressMask > 0) {
            state.vRegisters[registerName] = keyboard.get_key_pressed(keyStatePressMask);
            state.isWaitingForKey = false;
        }
    }
}

// Set delay timer = Vx.
// DT is set equal to the value of Vx.
pub fn execute_lddt(state: *cpu.CPUState, registerName: u8) void {
    assert((registerName & 0xF0) == 0); // Invalid register

    state.delayTimer = state.vRegisters[registerName];
}

// Set sound timer = Vx.
// ST is set equal to the value of Vx.
pub fn execute_ldst(state: *cpu.CPUState, registerName: u8) void {
    assert((registerName & 0xF0) == 0); // Invalid register

    state.soundTimer = state.vRegisters[registerName];
}

// Set I = I + Vx.
// The values of I and Vx are added, and the results are stored in I.
// NOTE: Carry in NOT set.
// NOTE: Overflows will just wrap the value around.
pub fn execute_addi(state: *cpu.CPUState, registerName: u8) void {
    assert((registerName & 0xF0) == 0); // Invalid register

    const registerValue: u16 = state.vRegisters[registerName];
    const sum = state.i +% registerValue;

    assert(sum >= state.i); // Overflow

    state.i = sum;
}

// Set I = location of sprite for digit Vx.
// The value of I is set to the location for the hexadecimal sprite corresponding to the value of Vx.
// See section 2.4, Display, for more information on the Chip-8 hexadecimal font.
pub fn execute_ldf(state: *cpu.CPUState, registerName: u8) void {
    assert((registerName & 0xF0) == 0); // Invalid register

    const glyphIndex = state.vRegisters[registerName];

    assert((glyphIndex & 0xF0) == 0); // Invalid index

    state.i = state.fontTableOffsets[glyphIndex];
}

// Store BCD representation of Vx in memory locations I, I+1, and I+2.
// The interpreter takes the decimal value of Vx, and places the hundreds digit in memory at location in I,
// the tens digit at location I+1, and the ones digit at location I+2.
pub fn execute_ldb(state: *cpu.CPUState, registerName: u8) void {
    assert((registerName & 0xF0) == 0); // Invalid register
    assert(memory.is_valid_range(state.i, 3, memory.Usage.Write));

    const registerValue = state.vRegisters[registerName];

    state.memory[state.i + 0] = (registerValue / 100) % 10;
    state.memory[state.i + 1] = (registerValue / 10) % 10;
    state.memory[state.i + 2] = (registerValue) % 10;
}

// Store registers V0 through Vx in memory starting at location I.
// The interpreter copies the values of registers V0 through Vx into memory,
// starting at the address in I.
pub fn execute_ldai(state: *cpu.CPUState, registerName: u8) void {
    const registerIndexMax = registerName;

    assert((registerIndexMax & 0xF0) == 0); // Invalid register
    assert(memory.is_valid_range(state.i, registerIndexMax + 1, memory.Usage.Write));

    for (state.vRegisters[0 .. registerIndexMax + 1]) |reg, index| {
        state.memory[state.i + index] = reg;
    }
}

// Read registers V0 through Vx from memory starting at location I.
// The interpreter reads values from memory starting at location I into registers V0 through Vx.
pub fn execute_ldm(state: *cpu.CPUState, registerName: u8) void {
    const registerIndexMax = registerName;

    assert((registerIndexMax & 0xF0) == 0); // Invalid register
    assert(memory.is_valid_range(state.i, registerIndexMax + 1, memory.Usage.Read));

    for (state.memory[state.i .. state.i + registerIndexMax + 1]) |byte, index| {
        state.vRegisters[index] = byte;
    }
}
