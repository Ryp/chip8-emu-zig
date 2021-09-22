const std = @import("std");
const assert = std.debug.assert;

const cpu = @import("cpu.zig");
const config = @import("config.zig");
const memory = @import("memory.zig");
const instruction = @import("instruction.zig");

pub fn load_program(state: *cpu.CPUState, program: []u8) void {
    assert((program.len & 0x0001) == 0); // Unaligned size
    assert(memory.is_valid_range(cpu.MinProgramAddress, @intCast(u16, program.len), memory.Usage.Write));

    for (program) |byte, i| {
        const offset: u16 = cpu.MinProgramAddress + @intCast(u16, i);
        state.memory[offset] = byte;
    }
}

fn load_next_instruction(state: *cpu.CPUState) u16 {
    const msb = @intCast(u16, state.memory[state.pc]) << 8;
    const lsb = @intCast(u16, state.memory[state.pc + 1]);

    return msb | lsb;
}

pub fn execute_step(state: *cpu.CPUState, deltaTimeMs: u32) void {
    var instructionsToExecute = update_timers(state, deltaTimeMs);
    var i: u32 = 0;

    while (i < instructionsToExecute) {
        // Simulate logic
        const nextInstruction = load_next_instruction(state);
        execute_instruction(state, nextInstruction);

        i += 1;
    }
}

// Returns execution counter
fn update_timers(state: *cpu.CPUState, deltaTimeMs: u32) u32 {
    // Update delay timer
    state.delayTimerAccumulator += deltaTimeMs;

    const delayTimerDecrement: i32 = @intCast(i32, state.delayTimerAccumulator / cpu.DelayTimerPeriodMs);
    state.delayTimer = @intCast(u8, std.math.max(0, @intCast(i32, state.delayTimer) - delayTimerDecrement));

    // Remove accumulated ticks
    state.delayTimerAccumulator = state.delayTimerAccumulator % cpu.DelayTimerPeriodMs;

    // Update execution counter
    state.executionTimerAccumulator += deltaTimeMs;

    const executionCounter = state.executionTimerAccumulator / cpu.InstructionExecutionPeriodMs;
    state.executionTimerAccumulator = state.executionTimerAccumulator % cpu.InstructionExecutionPeriodMs;

    // TODO Handle sound
    if (state.soundTimer > 0)
        state.soundTimer -= 1;

    return executionCounter;
}

pub fn execute_instruction(state: *cpu.CPUState, instruction_num: u16) void {
    // Save PC for later
    const pcSave = state.pc;

    // Decode and execute
    if (instruction_num == 0x00E0) {
        // 00E0 - CLS
        instruction.execute_cls(state);
    } else if (instruction_num == 0x00EE) {
        // 00EE - RET
        instruction.execute_ret(state);
    } else if ((instruction_num & 0xF000) == 0x0000) {
        // 0nnn - SYS addr
        const address = instruction_num & 0x0FFF;

        instruction.execute_sys(state, address);
    } else if ((instruction_num & 0xF000) == 0x1000) {
        // 1nnn - JP addr
        const address = instruction_num & 0x0FFF;

        instruction.execute_jp(state, address);
    } else if ((instruction_num & 0xF000) == 0x2000) {
        // 2nnn - CALL addr
        const address = instruction_num & 0x0FFF;

        instruction.execute_call(state, address);
    } else if ((instruction_num & 0xF000) == 0x3000) {
        // 3xkk - SE Vx, byte
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const value = @intCast(u8, instruction_num & 0x00FF);

        instruction.execute_se(state, registerName, value);
    } else if ((instruction_num & 0xF000) == 0x4000) {
        // 4xkk - SNE Vx, byte
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const value = @intCast(u8, instruction_num & 0x00FF);

        instruction.execute_sne(state, registerName, value);
    } else if ((instruction_num & 0xF00F) == 0x5000) {
        // 5xy0 - SE Vx, Vy
        const registerLHS = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const registerRHS = @intCast(u8, (instruction_num & 0x00F0) >> 4);

        instruction.execute_se2(state, registerLHS, registerRHS);
    } else if ((instruction_num & 0xF000) == 0x6000) {
        // 6xkk - LD Vx, byte
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const value = @intCast(u8, instruction_num & 0x00FF);

        instruction.execute_ld(state, registerName, value);
    } else if ((instruction_num & 0xF000) == 0x7000) {
        // 7xkk - ADD Vx, byte
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const value = @intCast(u8, instruction_num & 0x00FF);

        instruction.execute_add(state, registerName, value);
    } else if ((instruction_num & 0xF00F) == 0x8000) {
        // 8xy0 - LD Vx, Vy
        const registerLHS = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const registerRHS = @intCast(u8, (instruction_num & 0x00F0) >> 4);

        instruction.execute_ld2(state, registerLHS, registerRHS);
    } else if ((instruction_num & 0xF00F) == 0x8001) {
        // 8xy1 - OR Vx, Vy
        const registerLHS = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const registerRHS = @intCast(u8, (instruction_num & 0x00F0) >> 4);

        instruction.execute_or(state, registerLHS, registerRHS);
    } else if ((instruction_num & 0xF00F) == 0x8002) {
        // 8xy2 - AND Vx, Vy
        const registerLHS = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const registerRHS = @intCast(u8, (instruction_num & 0x00F0) >> 4);

        instruction.execute_and(state, registerLHS, registerRHS);
    } else if ((instruction_num & 0xF00F) == 0x8003) {
        // 8xy3 - XOR Vx, Vy
        const registerLHS = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const registerRHS = @intCast(u8, (instruction_num & 0x00F0) >> 4);

        instruction.execute_xor(state, registerLHS, registerRHS);
    } else if ((instruction_num & 0xF00F) == 0x8004) {
        // 8xy4 - ADD Vx, Vy
        const registerLHS = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const registerRHS = @intCast(u8, (instruction_num & 0x00F0) >> 4);

        instruction.execute_add2(state, registerLHS, registerRHS);
    } else if ((instruction_num & 0xF00F) == 0x8005) {
        // 8xy5 - SUB Vx, Vy
        const registerLHS = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const registerRHS = @intCast(u8, (instruction_num & 0x00F0) >> 4);

        instruction.execute_sub(state, registerLHS, registerRHS);
    } else if ((instruction_num & 0xF00F) == 0x8006) {
        // 8xy6 - SHR Vx {, Vy}
        const registerLHS = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const registerRHS = @intCast(u8, (instruction_num & 0x00F0) >> 4);

        instruction.execute_shr1(state, registerLHS, registerRHS);
    } else if ((instruction_num & 0xF00F) == 0x8007) {
        // 8xy7 - SUBN Vx, Vy
        const registerLHS = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const registerRHS = @intCast(u8, (instruction_num & 0x00F0) >> 4);

        instruction.execute_subn(state, registerLHS, registerRHS);
    } else if ((instruction_num & 0xF00F) == 0x800E) {
        // 8xyE - SHL Vx {, Vy}
        const registerLHS = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const registerRHS = @intCast(u8, (instruction_num & 0x00F0) >> 4);

        instruction.execute_shl1(state, registerLHS, registerRHS);
    } else if ((instruction_num & 0xF00F) == 0x9000) {
        // 9xy0 - SNE Vx, Vy
        const registerLHS = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const registerRHS = @intCast(u8, (instruction_num & 0x00F0) >> 4);

        instruction.execute_sne2(state, registerLHS, registerRHS);
    } else if ((instruction_num & 0xF000) == 0xA000) {
        // Annn - LD I, addr
        const address = instruction_num & 0x0FFF;

        instruction.execute_ldi(state, address);
    } else if ((instruction_num & 0xF000) == 0xB000) {
        // Bnnn - JP V0, addr
        const address = instruction_num & 0x0FFF;

        instruction.execute_jp2(state, address);
    } else if ((instruction_num & 0xF000) == 0xC000) {
        // Cxkk - RND Vx, byte
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const value = @intCast(u8, instruction_num & 0x00FF);

        instruction.execute_rnd(state, registerName, value);
    } else if ((instruction_num & 0xF000) == 0xD000) {
        // Dxyn - DRW Vx, Vy, nibble
        const registerLHS = @intCast(u8, (instruction_num & 0x0F00) >> 8);
        const registerRHS = @intCast(u8, (instruction_num & 0x00F0) >> 4);
        const size = @intCast(u8, instruction_num & 0x000F);

        instruction.execute_drw(state, registerLHS, registerRHS, size);
    } else if ((instruction_num & 0xF0FF) == 0xE09E) {
        // Ex9E - SKP Vx
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);

        instruction.execute_skp(state, registerName);
    } else if ((instruction_num & 0xF0FF) == 0xE0A1) {
        // ExA1 - SKNP Vx
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);

        instruction.execute_sknp(state, registerName);
    } else if ((instruction_num & 0xF0FF) == 0xF007) {
        // Fx07 - LD Vx, DT
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);

        instruction.execute_ldt(state, registerName);
    } else if ((instruction_num & 0xF0FF) == 0xF00A) {
        // Fx0A - LD Vx, K
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);

        instruction.execute_ldk(state, registerName);
    } else if ((instruction_num & 0xF0FF) == 0xF015) {
        // Fx15 - LD DT, Vx
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);

        instruction.execute_lddt(state, registerName);
    } else if ((instruction_num & 0xF0FF) == 0xF018) {
        // Fx18 - LD ST, Vx
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);

        instruction.execute_ldst(state, registerName);
    } else if ((instruction_num & 0xF0FF) == 0xF01E) {
        // Fx1E - ADD I, Vx
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);

        instruction.execute_addi(state, registerName);
    } else if ((instruction_num & 0xF0FF) == 0xF029) {
        // Fx29 - LD F, Vx
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);

        instruction.execute_ldf(state, registerName);
    } else if ((instruction_num & 0xF0FF) == 0xF033) {
        // Fx33 - LD B, Vx
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);

        instruction.execute_ldb(state, registerName);
    } else if ((instruction_num & 0xF0FF) == 0xF055) {
        // Fx55 - LD [I], Vx
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);

        instruction.execute_ldai(state, registerName);
    } else if ((instruction_num & 0xF0FF) == 0xF065) {
        // Fx65 - LD Vx, [I]
        const registerName = @intCast(u8, (instruction_num & 0x0F00) >> 8);

        instruction.execute_ldm(state, registerName);
    } else {
        assert(false); // Unknown instruction
    }

    // Increment PC only if it was NOT overriden by an instruction,
    // or if we are waiting for user input.
    if (pcSave == state.pc and !state.isWaitingForKey)
        state.pc += 2;

    // Save previous key state
    state.keyStatePrev = state.keyState;
}
