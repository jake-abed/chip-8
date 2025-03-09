pub const packages = struct {
    pub const @"122098b9174895f9708bc824b0f9e550c401892c40a900006459acf2cbf78acd99bb" = struct {
        pub const available = false;
    };
    pub const @"1220e8fe9509f0843e5e22326300ca415c27afbfbba3992f3c3184d71613540b5564" = struct {
        pub const available = false;
    };
    pub const @"N-V-__8AAPZ7UgBpukXNy27vajQpyiPrEZpV6jOLzI6-Otc_" = struct {
        pub const build_root = "C:\\Users\\jakea\\AppData\\Local\\zig\\p\\N-V-__8AAPZ7UgBpukXNy27vajQpyiPrEZpV6jOLzI6-Otc_";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"raylib-5.5.0-AAAAAKVFzQDBCXvg8rGIQ5JgOXiiisWS6S7aLx8tzEIY" = struct {
        pub const build_root = "C:\\Users\\jakea\\AppData\\Local\\zig\\p\\raylib-5.5.0-AAAAAKVFzQDBCXvg8rGIQ5JgOXiiisWS6S7aLx8tzEIY";
        pub const build_zig = @import("raylib-5.5.0-AAAAAKVFzQDBCXvg8rGIQ5JgOXiiisWS6S7aLx8tzEIY");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "xcode_frameworks", "122098b9174895f9708bc824b0f9e550c401892c40a900006459acf2cbf78acd99bb" },
            .{ "emsdk", "1220e8fe9509f0843e5e22326300ca415c27afbfbba3992f3c3184d71613540b5564" },
        };
    };
    pub const @"raylib_zig-5.6.0-dev-KE8REE0uBQD5Lzuc6qSZPtE5li3iPyU4iGQEMPqOPI11" = struct {
        pub const build_root = "C:\\Users\\jakea\\AppData\\Local\\zig\\p\\raylib_zig-5.6.0-dev-KE8REE0uBQD5Lzuc6qSZPtE5li3iPyU4iGQEMPqOPI11";
        pub const build_zig = @import("raylib_zig-5.6.0-dev-KE8REE0uBQD5Lzuc6qSZPtE5li3iPyU4iGQEMPqOPI11");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "raylib", "raylib-5.5.0-AAAAAKVFzQDBCXvg8rGIQ5JgOXiiisWS6S7aLx8tzEIY" },
            .{ "raygui", "N-V-__8AAPZ7UgBpukXNy27vajQpyiPrEZpV6jOLzI6-Otc_" },
        };
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "raylib_zig", "raylib_zig-5.6.0-dev-KE8REE0uBQD5Lzuc6qSZPtE5li3iPyU4iGQEMPqOPI11" },
};
