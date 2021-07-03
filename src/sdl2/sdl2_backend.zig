const std = @import("std");
const assert = std.debug.assert;

const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const chip8 = @import("../chip8/chip8.zig");

fn fill_image_buffer(imageOutput: []u8, state: *chip8.CPUState, palette: chip8.Palette, scale: u32) void {
    const pixelFormatBGRASizeInBytes: u32 = 4;

    const primaryColorBGRA = [4]u8{
        @floatToInt(u8, palette.primary.b * 255.0),
        @floatToInt(u8, palette.primary.g * 255.0),
        @floatToInt(u8, palette.primary.r * 255.0),
        255,
    };
    const secondaryColorBGRA = [4]u8{
        @floatToInt(u8, palette.secondary.b * 255.0),
        @floatToInt(u8, palette.secondary.g * 255.0),
        @floatToInt(u8, palette.secondary.r * 255.0),
        255,
    };

    var j: u32 = 0;
    while (j < chip8.ScreenHeight * scale) {
        var i: u32 = 0;
        while (i < chip8.ScreenWidth * scale) {
            const pixelIndexFlatDst = j * chip8.ScreenWidth * scale + i;
            const pixelOutputOffsetInBytes = pixelIndexFlatDst * pixelFormatBGRASizeInBytes;
            const pixelValue = chip8.read_screen_pixel(state, i / scale, j / scale);

            if (pixelValue > 0) {
                imageOutput[pixelOutputOffsetInBytes + 0] = primaryColorBGRA[0];
                imageOutput[pixelOutputOffsetInBytes + 1] = primaryColorBGRA[1];
                imageOutput[pixelOutputOffsetInBytes + 2] = primaryColorBGRA[2];
                imageOutput[pixelOutputOffsetInBytes + 3] = primaryColorBGRA[3];
            } else {
                imageOutput[pixelOutputOffsetInBytes + 0] = secondaryColorBGRA[0];
                imageOutput[pixelOutputOffsetInBytes + 1] = secondaryColorBGRA[1];
                imageOutput[pixelOutputOffsetInBytes + 2] = secondaryColorBGRA[2];
                imageOutput[pixelOutputOffsetInBytes + 3] = secondaryColorBGRA[3];
            }

            i += 1;
        }

        j += 1;
    }
}

pub fn execute_main_loop(state: *chip8.CPUState, config: chip8.EmuConfig) !void {
    const pixelFormatBGRASizeInBytes: u32 = 4;
    //const scale = config.screenScale;
    const scale = 4; // FIXME
    const width = chip8.ScreenWidth * scale;
    const height = chip8.ScreenHeight * scale;
    const stride = width * pixelFormatBGRASizeInBytes; // No extra space between lines
    const size = stride * chip8.ScreenHeight * scale;

    var image: [size * 4]u8 = undefined;

    if (c.SDL_Init(c.SDL_INIT_EVERYTHING) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    const win = c.SDL_CreateWindow("CHIP-8 Emulator", c.SDL_WINDOWPOS_UNDEFINED, c.SDL_WINDOWPOS_UNDEFINED, width, height, c.SDL_WINDOW_SHOWN) orelse
        {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyWindow(win);

    const ren = c.SDL_CreateRenderer(win, -1, c.SDL_RENDERER_ACCELERATED) orelse {
        c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_DestroyRenderer(ren);

    var rmask: u32 = undefined;
    var gmask: u32 = undefined;
    var bmask: u32 = undefined;
    var amask: u32 = undefined;
    if (c.SDL_BYTEORDER == c.SDL_BIG_ENDIAN) {
        rmask = 0xff000000;
        gmask = 0x00ff0000;
        bmask = 0x0000ff00;
        amask = 0x000000ff;
    } else // little endian, like x86
    {
        rmask = 0x000000ff;
        gmask = 0x0000ff00;
        bmask = 0x00ff0000;
        amask = 0xff000000;
    }

    var depth: u32 = 32;
    var pitch: u32 = stride;

    const surf = c.SDL_CreateRGBSurfaceFrom(&image, width, height, @intCast(c_int, depth), @intCast(c_int, pitch), rmask, gmask, bmask, amask) orelse {
        c.SDL_Log("Unable to create surface: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    };
    defer c.SDL_FreeSurface(surf);

    var previousTimeMs: u32 = c.SDL_GetTicks();
    var shouldExit = false;

    while (!shouldExit) {
        // Poll events
        var sdlEvent: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&sdlEvent) > 0) {
            switch (@intToEnum(c.SDL_EventType, @intCast(c_int, sdlEvent.type))) {
                .SDL_QUIT => {
                    shouldExit = true;
                },
                .SDL_KEYDOWN => {
                    if (sdlEvent.key.keysym.sym == c.SDLK_ESCAPE)
                        shouldExit = true;
                },
                else => {},
            }
        }

        // Get keyboard state
        const sdlKeyStates: [*]const u8 = c.SDL_GetKeyboardState(null);
        chip8.set_key_pressed(state, 0x1, sdlKeyStates[c.SDL_SCANCODE_1] > 0);
        chip8.set_key_pressed(state, 0x2, sdlKeyStates[c.SDL_SCANCODE_2] > 0);
        chip8.set_key_pressed(state, 0x3, sdlKeyStates[c.SDL_SCANCODE_3] > 0);
        chip8.set_key_pressed(state, 0xC, sdlKeyStates[c.SDL_SCANCODE_4] > 0);
        chip8.set_key_pressed(state, 0x4, sdlKeyStates[c.SDL_SCANCODE_Q] > 0);
        chip8.set_key_pressed(state, 0x5, sdlKeyStates[c.SDL_SCANCODE_W] > 0);
        chip8.set_key_pressed(state, 0x6, sdlKeyStates[c.SDL_SCANCODE_E] > 0);
        chip8.set_key_pressed(state, 0xD, sdlKeyStates[c.SDL_SCANCODE_R] > 0);
        chip8.set_key_pressed(state, 0x7, sdlKeyStates[c.SDL_SCANCODE_A] > 0);
        chip8.set_key_pressed(state, 0x8, sdlKeyStates[c.SDL_SCANCODE_S] > 0);
        chip8.set_key_pressed(state, 0x9, sdlKeyStates[c.SDL_SCANCODE_D] > 0);
        chip8.set_key_pressed(state, 0xE, sdlKeyStates[c.SDL_SCANCODE_F] > 0);
        chip8.set_key_pressed(state, 0xA, sdlKeyStates[c.SDL_SCANCODE_Z] > 0);
        chip8.set_key_pressed(state, 0x0, sdlKeyStates[c.SDL_SCANCODE_X] > 0);
        chip8.set_key_pressed(state, 0xB, sdlKeyStates[c.SDL_SCANCODE_C] > 0);
        chip8.set_key_pressed(state, 0xF, sdlKeyStates[c.SDL_SCANCODE_V] > 0);

        const currentTimeMs: u32 = c.SDL_GetTicks();
        const deltaTimeMs: u32 = currentTimeMs - previousTimeMs;

        chip8.execute_step(config, state, deltaTimeMs);

        // fill_image_buffer(image, state, config.palette, scale); FIXME

        // Draw
        const tex = c.SDL_CreateTextureFromSurface(ren, surf) orelse {
            c.SDL_Log("Unable to create texture from surface: %s", c.SDL_GetError());
            return error.SDLInitializationFailed;
        };
        defer c.SDL_DestroyTexture(tex);

        _ = c.SDL_RenderClear(ren);
        _ = c.SDL_RenderCopy(ren, tex, null, null);

        // Present
        c.SDL_RenderPresent(ren);

        previousTimeMs = currentTimeMs;
    }
}
