const std = @import("std");

const Self = @This();

// 4kb of memory.
memory: [4096]u8,

// Display is essentially just 64*32 on or off pixels. Could also be
// represented as [64][32]u8 as well.
display: [32][64]u8, // [y][x]u8 for graphics

// Keys 0-F represented as u8 integers. 0 is off, 1+ is on.
keys: [16]u8,

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

// Random Number Generator
rand: std.Random,

pub fn init(self: *Self) !void {
    self.memory = [_]u8{0} ** 0x050 ++ [_]u8{
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
    } ++ [_]u8{0} ** (4096 - 0x050 - (5 * 16));

    self.display = [_][64]u8{[_]u8{0} ** 64} ** 32;

    self.keys = [_]u8{0} ** 16;

    self.pc = 0x200;

    self.ir = 0;

    self.stack = [_]u16{0} ** 0x20;
    self.sp = 0;

    self.delay_timer = 0;
    self.sound_timer = 0;

    self.registers = [_]u8{0} ** 0x10;

    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    self.rand = prng.random();
}

fn incrementPC(self: *Self) void {
    self.pc += 2;
}

fn decrementPC(self: *Self) void {
    self.pc -= 2;
}

fn fetch(self: *Self) void {
    const first_half = @as(u16, self.memory[self.pc]);
    const second_half = @as(u16, self.memory[self.pc + 1]);

    self.opcode = @as(u16, (first_half << 0x08) | second_half);
    self.incrementPC();
}

fn decode(self: *Self) void {
    const nibble: u4 = @intCast(self.opcode >> 12);
    const nnn: u12 = @intCast(self.opcode & 0x0FFF);
    const x: u4 = @intCast((self.opcode & 0x0F00) >> 8);
    const y: u4 = @intCast((self.opcode & 0x00F0) >> 4);
    const z: u4 = @intCast(self.opcode & 0x000F);
    const kk: u8 = @intCast(self.opcode & 0x00FF);

    switch (nibble) {
        0x0 => {
            switch (nnn) {
                0x0E0 => {
                    std.debug.print("clearing display\n", .{});
                    for (0.., self.display) |y_pos, row| {
                        for (0.., row) |x_pos, _| {
                            self.display[y_pos][x_pos] = 0x0;
                        }
                    }
                },
                0x0EE => {
                    self.sp -= 1;
                    self.pc = self.stack[self.sp];
                },
                else => {},
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
            const vx: u8 = self.registers[x];
            if (vx == kk) {
                self.pc += 2;
            }
        },
        0x4 => {
            const vx: u8 = self.registers[x];
            if (vx != kk) {
                self.pc += 2;
            }
        },
        0x5 => {
            // Implement skip one instruction if contents of
            // register x == register y
            const vx: u8 = self.registers[x];
            const vy: u8 = self.registers[y];
            if (vx == vy) {
                self.pc += 2;
            }
        },
        0x6 => {
            self.registers[x] = kk; // set register x to kk
        },
        0x7 => {
            self.registers[x] +%= kk;
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
                0x5 => {
                    if (vx > vy) {
                        self.registers[0xF] = 1;
                    } else {
                        self.registers[0xF] = 0;
                    }

                    self.registers[x] = vx -% vy;
                },
                0x6 => {
                    self.registers[x] = vy;
                    const low_bit: u1 = @intCast(vy & 1);

                    if (low_bit == 1) {
                        self.registers[0xF] = 1;
                    } else {
                        self.registers[0xF] = 0;
                    }

                    self.registers[x] = @intCast(self.registers[x] >> 1);
                },
                0x7 => {
                    if (vy > vx) {
                        self.registers[0xF] = 1;
                    } else {
                        self.registers[0xF] = 0;
                    }

                    self.registers[x] = vy -% vx;
                },
                0xE => {
                    self.registers[x] = vy;
                    const low_bit: u1 = @intCast(vy & 1);

                    if (low_bit == 1) {
                        self.registers[0xF] = 1;
                    } else {
                        self.registers[0xF] = 0;
                    }

                    self.registers[x] = @intCast(self.registers[x] << 1);
                },
                else => {},
            }
        },
        0xA => {
            self.ir = @as(u16, nnn);
        },
        0xB => {
            self.ir = @as(u16, nnn + self.registers[0]);
        },
        0xC => {
            const num = self.rand.int(u8);
            self.registers[x] = num & kk;
        },
        0xD => {
            const vx = self.registers[x];
            const vy = self.registers[y];
            self.registers[0xF] = 0x0;

            var i: usize = 0;
            while (i < z) : (i += 1) {
                const spr_line = self.memory[self.ir + i];

                var col: usize = 0;
                while (col < 8) : (col += 1) {
                    const sig_bit: u8 = 128;
                    if ((spr_line & (sig_bit >> @intCast(col))) != 0) {
                        const x_pos = (vx + col) % 64;
                        const y_pos = (vy + i) % 32;

                        self.display[y_pos][x_pos] ^= 1;

                        if (self.display[y_pos][x_pos] == 0) {
                            self.registers[0xF] = 1;
                        }
                    }
                }
            }
        },
        0xF => {
            const vx = self.registers[x];

            switch (kk) {
                0x07 => {
                    self.registers[x] = self.delay_timer;
                },
                0x15 => {
                    self.delay_timer = vx;
                },
                0x18 => {
                    self.sound_timer = vx;
                },
                0x1E => {
                    self.ir += vx;
                },
                0x33 => {
                    self.memory[self.ir] = vx / 100;
                    self.memory[self.ir + 1] = (vx / 10) % 10;
                    self.memory[self.ir + 2] = vx % 10;
                },
                0x55 => {
                    var i: u8 = 0;
                    while (i <= x) : (i += 1) {
                        self.memory[self.ir + i] = self.registers[i];
                    }
                },
                0x65 => {
                    var i: u8 = 0;
                    while (i <= x) : (i += 1) {
                        self.registers[i] = self.memory[self.ir + i];
                    }
                },
                else => {},
            }
        },
        else => {},
    }
}

pub fn cycle(self: *Self) void {
    self.fetch();
    self.decode();

    if (self.delay_timer > 0) {
        self.delay_timer -= 1;
    }

    if (self.sound_timer > 0) {
        self.sound_timer -= 1;
    }
}
