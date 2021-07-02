const std = @import("std");
const assert = std.debug.assert;

const cpu = @import("cpu.zig");
const memory = @import("memory.zig");

pub fn load_program(state: *cpu.CPUState, program: []u8) void {
    assert((program.len & 0x0001) == 0); // Unaligned size
    assert(memory.is_valid_range(cpu.MinProgramAddress, @intCast(u16, program.len), memory.Usage.Write));

    for (program) |byte, i| {
        const offset: u16 = cpu.MinProgramAddress + @intCast(u16, i);
        state.memory[offset] = byte;
    }
}

//u16 load_next_instruction(CPUState& state)
//{
//    const u8* instructionPtr = &(state.memory[state.pc]);
//
//    return load_u16_big_endian(instructionPtr);
//}
//
//pub fn execute_step(config: chip8.EmuConfig, state: *CPUState, u32 deltaTimeMs) void
//{
//    uint instructionsToExecute = 0;
//    update_timers(state, instructionsToExecute, deltaTimeMs);
//
//    for (uint i = 0; i < instructionsToExecute; i++)
//    {
//        // Simulate logic
//        u16 nextInstruction = load_next_instruction(state);
//        execute_instruction(config, state, nextInstruction);
//    }
//}
//
//void update_timers(CPUState& state, unsigned int& executionCounter, unsigned int deltaTimeMs)
//{
//    // Update delay timer
//    state.delayTimerAccumulator += deltaTimeMs;
//
//    const uint delayTimerDecrement = state.delayTimerAccumulator / DelayTimerPeriodMs;
//    state.delayTimer = std::max(0, static_cast<int>(state.delayTimer) - static_cast<int>(delayTimerDecrement));
//
//    // Remove accumulated ticks
//    state.delayTimerAccumulator = state.delayTimerAccumulator % DelayTimerPeriodMs;
//
//    // Update execution counter
//    state.executionTimerAccumulator += deltaTimeMs;
//
//    executionCounter = state.executionTimerAccumulator / InstructionExecutionPeriodMs;
//    state.executionTimerAccumulator = state.executionTimerAccumulator % InstructionExecutionPeriodMs;
//
//    // TODO Handle sound
//    if (state.soundTimer > 0)
//        state.soundTimer--;
//}
//
//void execute_instruction(const EmuConfig& config, CPUState& state, u16 instruction)
//{
//    // Save PC for later
//    const u16 pcSave = state.pc;
//
//    // Decode and execute
//    if (instruction == 0x00E0)
//    {
//        // 00E0 - CLS
//        execute_cls(state);
//    }
//    else if (instruction == 0x00EE)
//    {
//        // 00EE - RET
//        execute_ret(state);
//    }
//    else if ((instruction & ~0x0FFF) == 0x0000)
//    {
//        // 0nnn - SYS addr
//        const u16 address = instruction & 0x0FFF;
//
//        execute_sys(state, address);
//    }
//    else if ((instruction & ~0x0FFF) == 0x1000)
//    {
//        // 1nnn - JP addr
//        const u16 address = instruction & 0x0FFF;
//
//        execute_jp(state, address);
//    }
//    else if ((instruction & ~0x0FFF) == 0x2000)
//    {
//        // 2nnn - CALL addr
//        const u16 address = instruction & 0x0FFF;
//
//        execute_call(state, address);
//    }
//    else if ((instruction & ~0x0FFF) == 0x3000)
//    {
//        // 3xkk - SE Vx, byte
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 value = static_cast<u8>(instruction & 0x00FF);
//
//        execute_se(state, registerName, value);
//    }
//    else if ((instruction & ~0x0FFF) == 0x4000)
//    {
//        // 4xkk - SNE Vx, byte
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 value = static_cast<u8>(instruction & 0x00FF);
//
//        execute_sne(state, registerName, value);
//    }
//    else if ((instruction & ~0x0FF0) == 0x5000)
//    {
//        // 5xy0 - SE Vx, Vy
//        const u8 registerLHS = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 registerRHS = static_cast<u8>((instruction & 0x00F0) >> 4);
//
//        execute_se2(state, registerLHS, registerRHS);
//    }
//    else if ((instruction & ~0x0FFF) == 0x6000)
//    {
//        // 6xkk - LD Vx, byte
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 value = static_cast<u8>(instruction & 0x00FF);
//
//        execute_ld(state, registerName, value);
//    }
//    else if ((instruction & ~0x0FFF) == 0x7000)
//    {
//        // 7xkk - ADD Vx, byte
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 value = static_cast<u8>(instruction & 0x00FF);
//
//        execute_add(state, registerName, value);
//    }
//    else if ((instruction & ~0x0FF0) == 0x8000)
//    {
//        // 8xy0 - LD Vx, Vy
//        const u8 registerLHS = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 registerRHS = static_cast<u8>((instruction & 0x00F0) >> 4);
//
//        execute_ld2(state, registerLHS, registerRHS);
//    }
//    else if ((instruction & ~0x0FF0) == 0x8001)
//    {
//        // 8xy1 - OR Vx, Vy
//        const u8 registerLHS = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 registerRHS = static_cast<u8>((instruction & 0x00F0) >> 4);
//
//        execute_or(state, registerLHS, registerRHS);
//    }
//    else if ((instruction & ~0x0FF0) == 0x8002)
//    {
//        // 8xy2 - AND Vx, Vy
//        const u8 registerLHS = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 registerRHS = static_cast<u8>((instruction & 0x00F0) >> 4);
//
//        execute_and(state, registerLHS, registerRHS);
//    }
//    else if ((instruction & ~0x0FF0) == 0x8003)
//    {
//        // 8xy3 - XOR Vx, Vy
//        const u8 registerLHS = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 registerRHS = static_cast<u8>((instruction & 0x00F0) >> 4);
//
//        execute_xor(state, registerLHS, registerRHS);
//    }
//    else if ((instruction & ~0x0FF0) == 0x8004)
//    {
//        // 8xy4 - ADD Vx, Vy
//        const u8 registerLHS = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 registerRHS = static_cast<u8>((instruction & 0x00F0) >> 4);
//
//        execute_add2(state, registerLHS, registerRHS);
//    }
//    else if ((instruction & ~0x0FF0) == 0x8005)
//    {
//        // 8xy5 - SUB Vx, Vy
//        const u8 registerLHS = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 registerRHS = static_cast<u8>((instruction & 0x00F0) >> 4);
//
//        execute_sub(state, registerLHS, registerRHS);
//    }
//    else if ((instruction & ~0x0FF0) == 0x8006)
//    {
//        // 8xy6 - SHR Vx {, Vy}
//        const u8 registerLHS = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 registerRHS = static_cast<u8>((instruction & 0x00F0) >> 4);
//
//        execute_shr1(state, registerLHS, registerRHS);
//    }
//    else if ((instruction & ~0x0FF0) == 0x8007)
//    {
//        // 8xy7 - SUBN Vx, Vy
//        const u8 registerLHS = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 registerRHS = static_cast<u8>((instruction & 0x00F0) >> 4);
//
//        execute_subn(state, registerLHS, registerRHS);
//    }
//    else if ((instruction & ~0x0FF0) == 0x800E)
//    {
//        // 8xyE - SHL Vx {, Vy}
//        const u8 registerLHS = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 registerRHS = static_cast<u8>((instruction & 0x00F0) >> 4);
//
//        execute_shl1(state, registerLHS, registerRHS);
//    }
//    else if ((instruction & ~0x0FF0) == 0x9000)
//    {
//        // 9xy0 - SNE Vx, Vy
//        const u8 registerLHS = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 registerRHS = static_cast<u8>((instruction & 0x00F0) >> 4);
//
//        execute_sne2(state, registerLHS, registerRHS);
//    }
//    else if ((instruction & ~0x0FFF) == 0xA000)
//    {
//        // Annn - LD I, addr
//        const u16 address = instruction & 0x0FFF;
//
//        execute_ldi(state, address);
//    }
//    else if ((instruction & ~0x0FFF) == 0xB000)
//    {
//        // Bnnn - JP V0, addr
//        const u16 address = instruction & 0x0FFF;
//
//        execute_jp2(state, address);
//    }
//    else if ((instruction & ~0x0FFF) == 0xC000)
//    {
//        // Cxkk - RND Vx, byte
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 value = static_cast<u8>(instruction & 0x00FF);
//
//        execute_rnd(state, registerName, value);
//    }
//    else if ((instruction & ~0x0FFF) == 0xD000)
//    {
//        // Dxyn - DRW Vx, Vy, nibble
//        const u8 registerLHS = static_cast<u8>((instruction & 0x0F00) >> 8);
//        const u8 registerRHS = static_cast<u8>((instruction & 0x00F0) >> 4);
//        const u8 size = static_cast<u8>(instruction & 0x000F);
//
//        execute_drw(state, registerLHS, registerRHS, size);
//    }
//    else if ((instruction & ~0x0F00) == 0xE09E)
//    {
//        // Ex9E - SKP Vx
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//
//        execute_skp(state, registerName);
//    }
//    else if ((instruction & ~0x0F00) == 0xE0A1)
//    {
//        // ExA1 - SKNP Vx
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//
//        execute_sknp(state, registerName);
//    }
//    else if ((instruction & ~0x0F00) == 0xF007)
//    {
//        // Fx07 - LD Vx, DT
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//
//        execute_ldt(state, registerName);
//    }
//    else if ((instruction & ~0x0F00) == 0xF00A)
//    {
//        // Fx0A - LD Vx, K
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//
//        execute_ldk(state, registerName);
//    }
//    else if ((instruction & ~0x0F00) == 0xF015)
//    {
//        // Fx15 - LD DT, Vx
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//
//        execute_lddt(state, registerName);
//    }
//    else if ((instruction & ~0x0F00) == 0xF018)
//    {
//        // Fx18 - LD ST, Vx
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//
//        execute_ldst(state, registerName);
//    }
//    else if ((instruction & ~0x0F00) == 0xF01E)
//    {
//        // Fx1E - ADD I, Vx
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//
//        execute_addi(state, registerName);
//    }
//    else if ((instruction & ~0x0F00) == 0xF029)
//    {
//        // Fx29 - LD F, Vx
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//
//        execute_ldf(state, registerName);
//    }
//    else if ((instruction & ~0x0F00) == 0xF033)
//    {
//        // Fx33 - LD B, Vx
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//
//        execute_ldb(state, registerName);
//    }
//    else if ((instruction & ~0x0F00) == 0xF055)
//    {
//        // Fx55 - LD [I], Vx
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//
//        execute_ldai(state, registerName);
//    }
//    else if ((instruction & ~0x0F00) == 0xF065)
//    {
//        // Fx65 - LD Vx, [I]
//        const u8 registerName = static_cast<u8>((instruction & 0x0F00) >> 8);
//
//        execute_ldm(state, registerName);
//    }
//    else
//    {
//        Assert(false); // Unknown instruction
//    }
//
//    // Increment PC only if it was NOT overriden by an instruction,
//    // or if we are waiting for user input.
//    if (pcSave == state.pc && !state.isWaitingForKey)
//        state.pc += 2;
//
//    // Save previous key state
//    state.keyStatePrev = state.keyState;
//}
