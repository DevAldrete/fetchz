//! fetchz - A fast, simple system information tool written in Zig
//! Usage: fetchz [options]
//!
//! Options:
//!   -h, --help       Show this help message
//!   -v, --version    Show version information
//!   -n, --no-ascii   Disable ASCII art logo
//!   -c, --no-color   Disable colored output
//!   --no-network     Disable network information
//!   --compact        Compact output mode

const std = @import("std");
const fetchz = @import("fetchz");

const version = "0.1.0";

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var config = fetchz.display.DisplayConfig{};
    var show_help = false;
    var show_version = false;

    for (args[1..]) |arg| {
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            show_help = true;
        } else if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--version")) {
            show_version = true;
        } else if (std.mem.eql(u8, arg, "-n") or std.mem.eql(u8, arg, "--no-ascii")) {
            config.show_ascii = false;
        } else if (std.mem.eql(u8, arg, "-c") or std.mem.eql(u8, arg, "--no-color")) {
            config.show_colors = false;
        } else if (std.mem.eql(u8, arg, "--no-network")) {
            config.show_network = false;
        } else if (std.mem.eql(u8, arg, "--compact")) {
            config.compact = true;
        } else {
            std.debug.print("Unknown option: {s}\n", .{arg});
            std.debug.print("Try 'fetchz --help' for more information.\n", .{});
            std.process.exit(1);
        }
    }

    // Get stdout writer with buffering
    const stdout_file = std.fs.File.stdout();
    var stdout_buffer: [8192]u8 = undefined;
    var bw = stdout_file.writer(&stdout_buffer);
    const stdout = &bw.interface;

    if (show_help) {
        try printHelp(stdout);
        try stdout.flush();
        return;
    }

    if (show_version) {
        try stdout.print("fetchz {s}\n", .{version});
        try stdout.print("A fast, simple system information tool written in Zig\n", .{});
        try stdout.flush();
        return;
    }

    // Collect system information
    const sys_info = fetchz.system.collectSystemInfo(allocator) catch |err| {
        std.debug.print("Error collecting system info: {}\n", .{err});
        std.process.exit(1);
    };
    defer sys_info.deinit(allocator);

    // Collect network information
    const net_info = fetchz.network.collectNetworkInfo(allocator) catch |err| {
        std.debug.print("Error collecting network info: {}\n", .{err});
        std.process.exit(1);
    };
    defer net_info.deinit(allocator);

    // Render output
    fetchz.display.renderWithConfig(allocator, stdout, sys_info, net_info, config) catch |err| {
        std.debug.print("Error rendering output: {}\n", .{err});
        std.process.exit(1);
    };

    try stdout.flush();
}

fn printHelp(writer: anytype) !void {
    try writer.print(
        \\fetchz - A fast, simple system information tool written in Zig
        \\
        \\USAGE:
        \\    fetchz [OPTIONS]
        \\
        \\OPTIONS:
        \\    -h, --help       Show this help message and exit
        \\    -v, --version    Show version information and exit
        \\    -n, --no-ascii   Disable ASCII art logo
        \\    -c, --no-color   Disable colored output
        \\    --no-network     Disable network information display
        \\    --compact        Use compact output mode
        \\
        \\EXAMPLES:
        \\    fetchz              Show full system information with ASCII art
        \\    fetchz --no-ascii   Show system information without logo
        \\    fetchz --no-color   Show output without ANSI colors
        \\
        \\SOURCE:
        \\    https://github.com/yourusername/fetchz
        \\
    , .{});
}

test "argument parsing" {
    // Basic test to ensure main compiles
    const allocator = std.testing.allocator;
    _ = allocator;
}
