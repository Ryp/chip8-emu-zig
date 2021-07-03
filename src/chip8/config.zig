pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
};

pub const Palette = struct {
    primary: Color,
    secondary: Color,
};

pub const EmuConfig = struct {
    palette: Palette,
    screenScale: u32,
};
