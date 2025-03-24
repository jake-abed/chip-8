const std = @import("std");
const rl = @import("raylib");
const cpu = @import("cpu.zig");
const KeyboardKey = rl.KeyboardKey;

pub fn loadRom(file: []const u8, chip8: *cpu) !void {
    var inputFile = try std.fs.cwd().openFile(file, .{});
    defer inputFile.close();

    const size = try inputFile.getEndPos();
    std.debug.print("ROM FILE SIZE: {any}\n", .{size});

    var reader = inputFile.reader();

    var i: usize = 0;
    while (i < size) : (i += 1) {
        chip8.memory[i + 0x200] = try reader.readByte();
    }

    std.debug.print("ROM LOADED SUCCESSFULLY\n", .{});
}

pub fn main() !void {
    const screenWidth = 1024;
    const screenHeight = 512;
    const pixelWidth: comptime_int = screenWidth / 64;
    const pixelHeight: comptime_int = screenHeight / 32;

    const keys = [16]KeyboardKey{
        KeyboardKey.x,
        KeyboardKey.one,
        KeyboardKey.two,
        KeyboardKey.three,
        KeyboardKey.q,
        KeyboardKey.w,
        KeyboardKey.e,
        KeyboardKey.a,
        KeyboardKey.s,
        KeyboardKey.d,
        KeyboardKey.z,
        KeyboardKey.c,
        KeyboardKey.four,
        KeyboardKey.r,
        KeyboardKey.f,
        KeyboardKey.v,
    };

    const gpa = std.heap.smp_allocator;

    const chip8 = try gpa.create(cpu);
    try chip8.init();

    var args = try std.process.argsWithAllocator(gpa);
    _ = args.skip();
    const rom = args.next() orelse "";
    std.debug.print("{s}", .{rom});
    try loadRom(rom, chip8);

    rl.initWindow(screenWidth, screenHeight, "chip-8 in zig");
    rl.initAudioDevice();
    defer rl.closeAudioDevice();
    defer rl.closeWindow();

    const monitorWidth = rl.getMonitorWidth(0);
    const monitorHeight = rl.getMonitorHeight(0);

    rl.setTargetFPS(144);

    rl.setWindowPosition(@divFloor(monitorWidth, 2) - screenWidth / 2, @divFloor(monitorHeight, 2) - screenHeight / 2);

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        for (0..16) |i| {
            const keyPressed: u8 = if (rl.isKeyDown(keys[i])) 1 else 0;
            chip8.keys[i] = keyPressed;
        }

        chip8.cycle();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        for (0..32, chip8.display) |y, row| {
            for (0..64, row) |x, pixel| {
                if (pixel == 1) {
                    const posX: i32 = pixelWidth * (@as(i32, @intCast(x)) - 1);
                    const posY: i32 = pixelHeight * (@as(i32, @intCast(y)) + 1);
                    rl.drawRectangle(posX, posY, pixelWidth, pixelHeight, rl.Color.white);
                }
            }
        }
    }
}
