//! fetchz - A fast, simple system information tool written in Zig
//! Inspired by neofetch and fastfetch, but dead simple and more detailed.

const std = @import("std");
const builtin = @import("builtin");

pub const system = @import("system.zig");
pub const display = @import("display.zig");
pub const ascii = @import("ascii.zig");
pub const network = @import("network.zig");

/// Main entry point for the library
pub fn fetch(allocator: std.mem.Allocator, writer: anytype) !void {
    const info = try system.collectSystemInfo(allocator);
    defer info.deinit(allocator);

    const net_info = try network.collectNetworkInfo(allocator);
    defer net_info.deinit(allocator);

    try display.render(allocator, writer, info, net_info);
}

test "basic library test" {
    var output = std.ArrayList(u8).init(std.testing.allocator);
    defer output.deinit();
    try fetch(std.testing.allocator, output.writer());
}
