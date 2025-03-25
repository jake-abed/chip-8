# CHIP-8 in Zig

This is a CHIP-8 Emulator/Interpreter written in Zig. All instructions and
details were gleaned from reading
[Tobias V. Langhoff's guide](https://tobiasvl.github.io/blog/write-a-chip-8-emulator/)
and the [technical reference](http://devernay.free.fr/hacks/chip8/C8TECH10.HTM#3.1).

## Current Spec

The current spec targets the original implmentation for the COSMAC-VIP. An
eventual goal is to add flags to change opcode behavior for different platforms.

## Technology Used
- Zig
- Raylib

That's it. It's overall extremely simple.

## To-Do

1) Add sound to play when Sound Timer is active.
2) Flags for different architectures.

There are currently no plans to add additional bits of GUI functionality to the
emulator (loading roms or snapshots).
