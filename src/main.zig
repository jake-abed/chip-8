const std = @import("std");
const rl = @import("raylib");

pub fn init() !void {}

pub fn main() !void {
    const screenWidth = 1024;
    const screenHeight = 512;
    const pixelWidth: comptime_int = screenWidth / 64;
    const pixelHeight: comptime_int = screenHeight / 32;

    rl.initWindow(screenWidth, screenHeight, "chip-8 in zig");
    rl.initAudioDevice();
    defer rl.closeAudioDevice();
    defer rl.closeWindow();

    const monitorWidth = rl.getMonitorWidth(0);
    const monitorHeight = rl.getMonitorHeight(0);

    rl.setTargetFPS(60);
    rl.setWindowPosition(@divFloor(monitorWidth, 2) - screenWidth / 2, @divFloor(monitorHeight, 2) - screenHeight / 2);

    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        rl.drawRectangle(screenWidth / 2 - pixelWidth, screenHeight / 2 - pixelHeight, pixelWidth, pixelHeight, rl.Color.white);
    }
}
