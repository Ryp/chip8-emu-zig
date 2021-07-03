const std = @import("std");
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

const cpu = @import("cpu.zig");
const execution = @import("execution.zig");
const keyboard = @import("keyboard.zig");

test "CLS" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.screen[0][0] = 0b11001100;
    state.screen[cpu.ScreenHeight - 1][cpu.ScreenLineSizeInBytes - 1] = 0b10101010;

    execution.execute_instruction(&state, 0x00E0);

    try expectEqual(state.screen[0][0], 0x00);
    try expectEqual(state.screen[cpu.ScreenHeight - 1][cpu.ScreenLineSizeInBytes - 1], 0x00);
}

test "JP" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    execution.execute_instruction(&state, 0x1240);

    try expectEqual(state.pc, 0x0240);

    execution.execute_instruction(&state, 0x1FFE);

    try expectEqual(state.pc, 0x0FFE);
}

test "CALL/RET" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    execution.execute_instruction(&state, 0x2F00);

    try expectEqual(state.sp, 1);
    try expectEqual(state.pc, 0x0F00);

    execution.execute_instruction(&state, 0x2A00);

    try expectEqual(state.sp, 2);
    try expectEqual(state.pc, 0x0A00);

    execution.execute_instruction(&state, 0x00EE);

    try expectEqual(state.sp, 1);
    try expectEqual(state.pc, 0x0F02);

    execution.execute_instruction(&state, 0x00EE);

    try expectEqual(state.sp, 0);
    try expectEqual(state.pc, cpu.MinProgramAddress + 2);
}

test "SE" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    execution.execute_instruction(&state, 0x3000);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 0);
    try expectEqual(state.pc, cpu.MinProgramAddress + 4);
}

test "SNE" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    execution.execute_instruction(&state, 0x40FF);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 0);
    try expectEqual(state.pc, cpu.MinProgramAddress + 4);
}

test "SE2" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    execution.execute_instruction(&state, 0x5120);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 0);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V1)], 0);
    try expectEqual(state.pc, cpu.MinProgramAddress + 4);
}

test "LD" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    execution.execute_instruction(&state, 0x06042);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 0x42);

    execution.execute_instruction(&state, 0x06A33);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VA)], 0x33);
}

test "ADD" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V2)], 0x00);

    execution.execute_instruction(&state, 0x7203);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V2)], 0x03);

    execution.execute_instruction(&state, 0x7204);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V2)], 0x07);
}

test "LD2" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.V3)] = 32;

    execution.execute_instruction(&state, 0x8030);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 32);
}

test "OR" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.VC)] = 0xF0;
    state.vRegisters[@enumToInt(cpu.Register.VD)] = 0x0F;

    execution.execute_instruction(&state, 0x8CD1);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VC)], 0xFF);
}

test "AND" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.VC)] = 0xF0;
    state.vRegisters[@enumToInt(cpu.Register.VD)] = 0x0F;

    execution.execute_instruction(&state, 0x8CD2);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VC)], 0x00);

    state.vRegisters[@enumToInt(cpu.Register.VC)] = 0xF0;
    state.vRegisters[@enumToInt(cpu.Register.VD)] = 0xFF;

    execution.execute_instruction(&state, 0x8CD2);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VC)], 0xF0);
}

test "XOR" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.VC)] = 0x10;
    state.vRegisters[@enumToInt(cpu.Register.VD)] = 0x1F;

    execution.execute_instruction(&state, 0x8CD3);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VC)], 0x0F);
}

test "ADD" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.V0)] = 8;
    state.vRegisters[@enumToInt(cpu.Register.V1)] = 8;

    execution.execute_instruction(&state, 0x8014);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 16);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VF)], 0);

    state.vRegisters[@enumToInt(cpu.Register.V0)] = 128;
    state.vRegisters[@enumToInt(cpu.Register.V1)] = 130;

    execution.execute_instruction(&state, 0x8014);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 2);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VF)], 1);
}

test "SUB" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.V0)] = 8;
    state.vRegisters[@enumToInt(cpu.Register.V1)] = 7;

    execution.execute_instruction(&state, 0x8015);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 1);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VF)], 1);

    state.vRegisters[@enumToInt(cpu.Register.V0)] = 8;
    state.vRegisters[@enumToInt(cpu.Register.V1)] = 9;

    execution.execute_instruction(&state, 0x8015);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 255);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VF)], 0);
}

test "SHR" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.V0)] = 8;

    execution.execute_instruction(&state, 0x8016);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 4);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VF)], 0);

    execution.execute_instruction(&state, 0x8026);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 2);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VF)], 0);

    execution.execute_instruction(&state, 0x8026);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 1);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VF)], 0);

    execution.execute_instruction(&state, 0x8026);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 0);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VF)], 1);
}

test "SUBN" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.V0)] = 7;
    state.vRegisters[@enumToInt(cpu.Register.V1)] = 8;

    execution.execute_instruction(&state, 0x8017);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 1);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VF)], 1);

    state.vRegisters[@enumToInt(cpu.Register.V0)] = 2;
    state.vRegisters[@enumToInt(cpu.Register.V1)] = 1;

    execution.execute_instruction(&state, 0x8017);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 255);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VF)], 0);
}

test "SHL" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.V0)] = 64;

    execution.execute_instruction(&state, 0x801E);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 128);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VF)], 0);

    execution.execute_instruction(&state, 0x801E);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 0);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.VF)], 1);
}

test "SNE2" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.V9)] = 64;
    state.vRegisters[@enumToInt(cpu.Register.VA)] = 64;

    execution.execute_instruction(&state, 0x99A0);

    try expectEqual(state.pc, cpu.MinProgramAddress + 2);

    state.vRegisters[@enumToInt(cpu.Register.VA)] = 0;
    execution.execute_instruction(&state, 0x99A0);

    try expectEqual(state.pc, cpu.MinProgramAddress + 6);
}

test "LDI" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    execution.execute_instruction(&state, 0xA242);

    try expectEqual(state.i, 0x0242);
}

test "JP2" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.V0)] = 0x02;

    execution.execute_instruction(&state, 0xB240);

    try expectEqual(state.pc, 0x0242);
}

test "RND" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    execution.execute_instruction(&state, 0xC10F);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V1)] & 0xF0, 0);

    execution.execute_instruction(&state, 0xC1F0);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V1)] & 0x0F, 0);
}

test "DRW" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    // TODO
    // execution.execute_instruction(&state, 0x00E0); // Clear screen
    // state.vRegisters[@enumToInt(cpu.Register.V0)] = 0x0F; // Set digit to print
    // state.vRegisters[@enumToInt(cpu.Register.V1)] = 0x00; // Set digit to print
    // execution.execute_instruction(&state, 0xF029); // Load digit sprite address
    // execution.execute_instruction(&state, 0xD115); // Draw sprite
    // for (int i = 0; i < 10; i++)
    // {
    //     cpu.write_screen_pixel(state, cpu.ScreenWidth - i - 1, cpu.ScreenHeight - i - 1, 1);
    // }
}

test "SKP" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.VA)] = 0x0F;
    state.keyState = 0x8000;

    execution.execute_instruction(&state, 0xEA9E);

    try expectEqual(state.pc, cpu.MinProgramAddress + 4); // Skipped

    execution.execute_instruction(&state, 0xEB9E);

    try expectEqual(state.pc, cpu.MinProgramAddress + 6); // Did not skip

}

test "SKNP" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.VA)] = 0xF;
    state.keyState = 0x8000;

    execution.execute_instruction(&state, 0xEBA1);

    try expectEqual(state.pc, cpu.MinProgramAddress + 4); // Skipped

    execution.execute_instruction(&state, 0xEAA1);

    try expectEqual(state.pc, cpu.MinProgramAddress + 6); // Did not skip
}

test "LDT" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.delayTimer = 42;
    state.vRegisters[@enumToInt(cpu.Register.V4)] = 0;

    execution.execute_instruction(&state, 0xF407);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V4)], 42);
}

test "LDK" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    try expect(!state.isWaitingForKey);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V1)], 0);

    execution.execute_instruction(&state, 0xF10A);

    try expect(state.isWaitingForKey);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V1)], 0);

    keyboard.set_key_pressed(&state, 0xA, true);

    execution.execute_instruction(&state, 0xF10A);

    try expect(!state.isWaitingForKey);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V1)], 0xA);
}

test "LDDT" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.V5)] = 66;

    execution.execute_instruction(&state, 0xF515);

    try expectEqual(state.delayTimer, 66);
}

test "LDST" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.V6)] = 33;

    execution.execute_instruction(&state, 0xF618);

    try expectEqual(state.soundTimer, 33);
}

test "ADDI" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.V9)] = 10;
    state.i = cpu.MinProgramAddress;

    execution.execute_instruction(&state, 0xF91E);

    try expectEqual(state.i, cpu.MinProgramAddress + 10);
}

test "LDF" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.vRegisters[@enumToInt(cpu.Register.V0)] = 9;

    execution.execute_instruction(&state, 0xF029);

    try expectEqual(state.i, state.fontTableOffsets[9]);

    state.vRegisters[@enumToInt(cpu.Register.V0)] = 0xF;

    execution.execute_instruction(&state, 0xF029);

    try expectEqual(state.i, state.fontTableOffsets[0xF]);
}

test "LDB" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.i = cpu.MinProgramAddress;
    state.vRegisters[@enumToInt(cpu.Register.V7)] = 109;

    execution.execute_instruction(&state, 0xF733);

    try expectEqual(state.memory[state.i + 0], 1);
    try expectEqual(state.memory[state.i + 1], 0);
    try expectEqual(state.memory[state.i + 2], 9);

    state.vRegisters[@enumToInt(cpu.Register.V7)] = 255;

    execution.execute_instruction(&state, 0xF733);

    try expectEqual(state.memory[state.i + 0], 2);
    try expectEqual(state.memory[state.i + 1], 5);
    try expectEqual(state.memory[state.i + 2], 5);
}

test "LDAI" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.i = cpu.MinProgramAddress;
    state.memory[state.i + 0] = 0xF4;
    state.memory[state.i + 1] = 0x33;
    state.memory[state.i + 2] = 0x82;
    state.memory[state.i + 3] = 0x73;

    state.vRegisters[@enumToInt(cpu.Register.V0)] = 0xE4;
    state.vRegisters[@enumToInt(cpu.Register.V1)] = 0x23;
    state.vRegisters[@enumToInt(cpu.Register.V2)] = 0x00;

    execution.execute_instruction(&state, 0xF155);

    try expectEqual(state.memory[state.i + 0], 0xE4);
    try expectEqual(state.memory[state.i + 1], 0x23);
    try expectEqual(state.memory[state.i + 2], 0x82);
    try expectEqual(state.memory[state.i + 3], 0x73);
}

test "LDM" {
    var state = try cpu.createCPUState();
    defer cpu.destroyCPUState(&state);

    state.i = cpu.MinProgramAddress;
    state.vRegisters[@enumToInt(cpu.Register.V0)] = 0xF4;
    state.vRegisters[@enumToInt(cpu.Register.V1)] = 0x33;
    state.vRegisters[@enumToInt(cpu.Register.V2)] = 0x82;
    state.vRegisters[@enumToInt(cpu.Register.V3)] = 0x73;

    state.memory[state.i + 0] = 0xE4;
    state.memory[state.i + 1] = 0x23;
    state.memory[state.i + 2] = 0x00;

    execution.execute_instruction(&state, 0xF165);

    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V0)], 0xE4);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V1)], 0x23);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V2)], 0x82);
    try expectEqual(state.vRegisters[@enumToInt(cpu.Register.V3)], 0x73);
}
