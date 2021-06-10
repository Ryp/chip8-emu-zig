// #include "chip8/Config.h"
// #include "chip8/Cpu.h"
// #include "chip8/Execution.h"
//
// #include "sdl2/SDL2Backend.h"

const std = @import("std");

const chip8 = @import("chip8/chip8.zig");

pub fn main() !void {
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa = &general_purpose_allocator.allocator;
    const args = try std.process.argsAlloc(gpa);
    defer std.process.argsFree(gpa, args);

    for (args) |arg, i| {
        std.debug.print("{}: {s}\n", .{ i, arg });
    }

    //assert(args.size)
    //     if (ac != 2)
    //     {
    //         std::cerr << "error: missing rom file" << std::endl;
    //         return 1;
    //     }

    var config: chip8.EmuConfig = undefined;

    config.debugMode = true;
    config.palette.primary = chip8.Color{ .r = 1.0, .g = 1.0, .b = 1.0 };
    config.palette.secondary = chip8.Color{ .r = 0.14, .g = 0.14, .b = 0.14 };
    config.screenScale = 8;

    var cpu_state = try chip8.createCPUState();
    defer chip8.destroyCPUState(&cpu_state);

    // Load program in chip8 memory
    {
        // const programPath = args[1];
        // assert(programPath != nullptr);
        //
        // std::cout << "[INFO] loading program: " << programPath << std::endl;
        //
        // std::ifstream programFile(programPath, std::ios::binary | std::ios::ate);
        // const std::ifstream::pos_type programSizeInBytes = programFile.tellg();
        //
        // std::cout << "[INFO] rom size: " << programSizeInBytes << std::endl;
        //
        // std::vector<char> programContent(programSizeInBytes);
        //
        // programFile.seekg(0, std::ios::beg);
        // programFile.read(&(programContent[0]), programSizeInBytes);
        //
        // std::cout << "[INFO] program loaded" << std::endl;
        //
        // chip8::load_program(cpu_state, reinterpret_cast<const u8*>(programContent.data()), programSizeInBytes);
    }

    // sdl2::execute_main_loop(cpu_state, config);
}
