const std = @import("std");

const Self = @This();

// 4kb of memory.
memory: [4096]u8,

// Display is essentially just 64*32 on or off pixels. Could also be
// represented as [64][32]u8 as well.
display: [32][64]u8, // [y][x]u8 for graphics

// Opcode stores the two u8 memory addresses as one 16-bit opcode
opcode: u16,

// Program Counter (PC) which points to current instruction (u16)
pc: u16,

// Index register to point at memory locations:
ir: u16,

// Stack & Stack Pointer
stack: [32]u16,
sp: u16,

// Timers
delay_timer: u8,
sound_timer: u8,

// Variable Registers - 16 bytes 0 - 15
registers: [16]u8,

pub fn init(self: *Self) *Self {
    self.memory = [_]u8{0} * 0x050 ++ [_]u8{
        0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
        0x20, 0x60, 0x20, 0x20, 0x70, // 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
        0x90, 0x90, 0xF0, 0x10, 0x10, // 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
        0xF0, 0x10, 0x20, 0x40, 0x40, // 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
        0xF0, 0x90, 0xF0, 0x90, 0x90, // A
        0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
        0xF0, 0x80, 0x80, 0x80, 0xF0, // C
        0xE0, 0x90, 0x90, 0x90, 0xE0, // D
        0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
        0xF0, 0x80, 0xF0, 0x80, 0x80, // F
    } ++ [_]u8{0} * (4096 - 512);

    self.display = [_][64]u8{[_]u8{0} * 64} * 32;

    self.pc = 0;

    self.ir = 0;

    self.stack = [_]u16{0} * 0x20;
    self.sp = 0;

    self.delay_timer = 0;
    self.sound_timer = 0;

    self.registers = [_]u8{0} * 0x10;
    // We may need to set certain registers to certain values off rip.

    return self.*;
}

fn fetch(self: *Self) void {
    const first_half = self.memory[self.pc];
    const second_half = self.memory[self.pc + 1];

    self.opcode = (first_half << 8) | second_half;
    self.pc += 2;
}

// Implement @bitCast?
fn decode(self: *Self) void {
    const nibble: u4 = @as(u4, self.opcode >> 12);
    const nnn: u12 = @as(u12, self.opcode >> 4);
    const x: u4 = @as(u4, nnn << 8);
    const y: u4 = @as(u4, (nnn & 0x0F0) >> 4);
    const z: u4 = @as(u4, nnn & 0xF);
    const kk: u8 = @as(u8, nnn & 0xFF);

    switch (nibble) {
        0x0 => {
            switch (nnn) {
                0x0E0 => {
                    for (self.display) |row| {
                        for (self.display[row]) |col| {
                            self.display[row][col] = 0x0;
                        }
                    }
                },
                0x0EE => {
                    // To-do: implement return from subroutine.
                    return;
                },
                else => {
                    return;
                },
            }
        },
        0x1 => {
            self.pc = nnn;
        },
        0x2 => {
            self.stack[self.sp] = self.pc;
            self.sp += 1;
            self.pc = self.opcode & 0x0FFF;
        },
        0x3 => {
            // Implement skip one instruction if register x == nn
        },
        0x4 => {
            // Implement skip one instruction if register x != nn
        },
        0x5 => {
            // Implement skip one instruction if contents of
            // register x == register y
        },
        0x6 => {
            self.registers[x] = kk; // set register x to kk
        },
        0x7 => {
            self.registers[x] += kk;
        },
        0x8 => {
            const vx = self.registers[x];
            const vy = self.registers[y];
            switch (z) {
                0x0 => {
                    self.registers[x] = vy;
                },
                0x1 => {
                    self.registers[x] = vx | vy;
                },
                0x2 => {
                    self.registers[x] = vx & vy;
                },
                0x3 => {
                    self.registers[x] = vx ^ vy;
                },
                0x4 => {
                    self.registers[x] +%= vy;
                    _, const overflow = @addWithOverflow(vx, vy);
                    if (overflow == 1) {
                        self.registers[0xF] = 0x01;
                    }
                },
                else => {},
            }
        },
        0xA => {
            self.ir = @as(u16, nnn);
        },
        0xD => {
            //const vx = self.registers[x];
            //const vy = self.registers[y];
        },
    }
}
