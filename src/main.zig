const std = @import("std");
const rl = @import("raylib");
const cpu = @import("cpu.zig");

pub fn init() !void {}

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

    const gpa = std.heap.smp_allocator;

    const chip8 = try gpa.create(cpu);

    chip8.init();

    try loadRom("src/roms/1-chip8-logo.ch8", chip8);

    rl.initWindow(screenWidth, screenHeight, "chip-8 in zig");
    rl.initAudioDevice();
    defer rl.closeAudioDevice();
    defer rl.closeWindow();

    const monitorWidth = rl.getMonitorWidth(0);
    const monitorHeight = rl.getMonitorHeight(0);

    rl.setTargetFPS(60);
    rl.setWindowPosition(@divFloor(monitorWidth, 2) - screenWidth / 2, @divFloor(monitorHeight, 2) - screenHeight / 2);

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        chip8.fetch();
        chip8.decode();

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        for (0.., chip8.display) |y, row| {
            for (0.., row) |x, pixel| {
                if (pixel == 1) {
                    const posX: i32 = pixelWidth * @as(i32, @intCast(x));
                    const posY: i32 = pixelWidth * @as(i32, @intCast(y));
                    rl.drawRectangle(posX, posY, pixelWidth, pixelHeight, rl.Color.white);
                }
            }
        }
    }

    std.debug.print("{any}\n", .{chip8.display});
}
