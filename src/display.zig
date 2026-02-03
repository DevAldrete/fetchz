//! Display and formatting module for fetchz
//! Handles rendering system information alongside ASCII art.

const std = @import("std");
const ascii = @import("ascii.zig");
const system = @import("system.zig");
const network = @import("network.zig");

const Color = ascii.Color;

/// Configuration for display options
pub const DisplayConfig = struct {
    show_colors: bool = true,
    show_ascii: bool = true,
    show_network: bool = true,
    compact: bool = false,
};

/// Render the full fetchz output
pub fn render(
    allocator: std.mem.Allocator,
    writer: anytype,
    sys_info: system.SystemInfo,
    net_info: network.NetworkInfo,
) !void {
    try renderWithConfig(allocator, writer, sys_info, net_info, .{});
}

/// Render with custom configuration
pub fn renderWithConfig(
    allocator: std.mem.Allocator,
    writer: anytype,
    sys_info: system.SystemInfo,
    net_info: network.NetworkInfo,
    config: DisplayConfig,
) !void {
    // Get the logo for this OS
    const logo = ascii.getLogoByName(sys_info.os_name);

    // Build info lines
    var info_lines: std.ArrayList([]const u8) = .empty;
    defer {
        for (info_lines.items) |line| {
            allocator.free(line);
        }
        info_lines.deinit(allocator);
    }

    // Title line: user@hostname
    const title = try std.fmt.allocPrint(allocator, "{s}{s}@{s}{s}", .{
        if (config.show_colors) logo.primary_color.boldCode() else "",
        sys_info.username,
        sys_info.hostname,
        if (config.show_colors) ascii.reset else "",
    });
    try info_lines.append(allocator, title);

    // Separator
    const sep_len = sys_info.username.len + 1 + sys_info.hostname.len;
    const separator = try allocator.alloc(u8, sep_len);
    @memset(separator, '-');
    try info_lines.append(allocator, separator);

    // OS
    try info_lines.append(allocator, try formatLine(allocator, "OS", sys_info.os_name, logo.primary_color, config.show_colors));

    // Kernel
    try info_lines.append(allocator, try formatLine(allocator, "Kernel", sys_info.kernel, logo.primary_color, config.show_colors));

    // Architecture
    try info_lines.append(allocator, try formatLine(allocator, "Arch", sys_info.arch, logo.primary_color, config.show_colors));

    // Uptime
    const uptime_str = try formatUptime(allocator, sys_info.uptime_seconds);
    defer allocator.free(uptime_str);
    try info_lines.append(allocator, try formatLine(allocator, "Uptime", uptime_str, logo.primary_color, config.show_colors));

    // Shell
    if (sys_info.shell_version.len > 0) {
        const shell_str = try std.fmt.allocPrint(allocator, "{s} {s}", .{ sys_info.shell, sys_info.shell_version });
        defer allocator.free(shell_str);
        try info_lines.append(allocator, try formatLine(allocator, "Shell", shell_str, logo.primary_color, config.show_colors));
    } else {
        try info_lines.append(allocator, try formatLine(allocator, "Shell", sys_info.shell, logo.primary_color, config.show_colors));
    }

    // Terminal
    try info_lines.append(allocator, try formatLine(allocator, "Terminal", sys_info.terminal, logo.primary_color, config.show_colors));

    // CPU
    const cpu_str = try std.fmt.allocPrint(allocator, "{s} ({d}C/{d}T)", .{
        sys_info.cpu_model,
        sys_info.cpu_cores,
        sys_info.cpu_threads,
    });
    defer allocator.free(cpu_str);
    try info_lines.append(allocator, try formatLine(allocator, "CPU", cpu_str, logo.primary_color, config.show_colors));

    // Memory
    const mem_str = try formatMemory(allocator, sys_info.memory_used, sys_info.memory_total);
    defer allocator.free(mem_str);
    try info_lines.append(allocator, try formatLine(allocator, "Memory", mem_str, logo.primary_color, config.show_colors));

    // Disk
    const disk_str = try formatDisk(allocator, sys_info.disk_used, sys_info.disk_total);
    defer allocator.free(disk_str);
    try info_lines.append(allocator, try formatLine(allocator, "Disk (/)", disk_str, logo.primary_color, config.show_colors));

    // Locale
    try info_lines.append(allocator, try formatLine(allocator, "Locale", sys_info.locale, logo.primary_color, config.show_colors));

    // Network info
    if (config.show_network) {
        // Empty line before network
        try info_lines.append(allocator, try allocator.dupe(u8, ""));

        // Local IP
        try info_lines.append(allocator, try formatLine(allocator, "Local IP", net_info.local_ip, logo.primary_color, config.show_colors));

        // Public IP
        try info_lines.append(allocator, try formatLine(allocator, "Public IP", net_info.public_ip, logo.primary_color, config.show_colors));

        // Network interfaces (only show ones with IP)
        for (net_info.interfaces) |iface| {
            if (!iface.is_loopback and iface.ipv4.len > 0) {
                const iface_str = try std.fmt.allocPrint(allocator, "{s}: {s}", .{ iface.name, iface.ipv4 });
                defer allocator.free(iface_str);
                try info_lines.append(allocator, try formatLine(allocator, "Interface", iface_str, logo.primary_color, config.show_colors));
            }
        }
    }

    // Empty line before color blocks
    try info_lines.append(allocator, try allocator.dupe(u8, ""));

    // Color blocks
    if (config.show_colors) {
        const color_line1 = try allocator.dupe(u8, "\x1b[40m   \x1b[41m   \x1b[42m   \x1b[43m   \x1b[44m   \x1b[45m   \x1b[46m   \x1b[47m   \x1b[0m");
        try info_lines.append(allocator, color_line1);
        const color_line2 = try allocator.dupe(u8, "\x1b[100m   \x1b[101m   \x1b[102m   \x1b[103m   \x1b[104m   \x1b[105m   \x1b[106m   \x1b[107m   \x1b[0m");
        try info_lines.append(allocator, color_line2);
    }

    // Render side by side
    if (config.show_ascii) {
        try renderSideBySide(writer, logo, info_lines.items, config.show_colors);
    } else {
        for (info_lines.items) |line| {
            try writer.print("{s}\n", .{line});
        }
    }
}

fn formatLine(allocator: std.mem.Allocator, label: []const u8, value: []const u8, color: Color, show_colors: bool) ![]const u8 {
    if (show_colors) {
        return std.fmt.allocPrint(allocator, "{s}{s}{s}: {s}", .{
            color.boldCode(),
            label,
            ascii.reset,
            value,
        });
    } else {
        return std.fmt.allocPrint(allocator, "{s}: {s}", .{ label, value });
    }
}

fn formatUptime(allocator: std.mem.Allocator, seconds: u64) ![]const u8 {
    const days = seconds / 86400;
    const hours = (seconds % 86400) / 3600;
    const mins = (seconds % 3600) / 60;

    if (days > 0) {
        return std.fmt.allocPrint(allocator, "{d} days, {d} hours, {d} mins", .{ days, hours, mins });
    } else if (hours > 0) {
        return std.fmt.allocPrint(allocator, "{d} hours, {d} mins", .{ hours, mins });
    } else {
        return std.fmt.allocPrint(allocator, "{d} mins", .{mins});
    }
}

fn formatMemory(allocator: std.mem.Allocator, used: u64, total: u64) ![]const u8 {
    const used_mib = used / (1024 * 1024);
    const total_mib = total / (1024 * 1024);
    const percent = if (total > 0) (used * 100) / total else 0;

    return std.fmt.allocPrint(allocator, "{d} MiB / {d} MiB ({d}%)", .{ used_mib, total_mib, percent });
}

fn formatDisk(allocator: std.mem.Allocator, used: u64, total: u64) ![]const u8 {
    const used_gib = used / (1024 * 1024 * 1024);
    const total_gib = total / (1024 * 1024 * 1024);
    const percent = if (total > 0) (used * 100) / total else 0;

    return std.fmt.allocPrint(allocator, "{d} GiB / {d} GiB ({d}%)", .{ used_gib, total_gib, percent });
}

fn renderSideBySide(writer: anytype, logo: ascii.Logo, info_lines: []const []const u8, show_colors: bool) !void {
    const logo_lines = logo.art;
    const logo_width = logo.width;
    const gap = 3;

    const max_lines = @max(logo_lines.len, info_lines.len);

    for (0..max_lines) |i| {
        // Print logo line (or padding)
        if (i < logo_lines.len) {
            if (show_colors) {
                try writer.print("{s}{s}{s}", .{ logo.primary_color.ansiCode(), logo_lines[i], ascii.reset });
            } else {
                try writer.print("{s}", .{logo_lines[i]});
            }
            // Pad to logo width if needed
            const line_len = logo_lines[i].len;
            if (line_len < logo_width) {
                try writeSpaces(writer, logo_width - line_len);
            }
        } else {
            try writeSpaces(writer, logo_width);
        }

        // Gap between logo and info
        try writeSpaces(writer, gap);

        // Print info line
        if (i < info_lines.len) {
            try writer.print("{s}", .{info_lines[i]});
        }

        try writer.print("\n", .{});
    }
}

fn writeSpaces(writer: anytype, count: usize) !void {
    for (0..count) |_| {
        try writer.writeByte(' ');
    }
}

/// Print a simple info-only output (no ASCII art)
pub fn printInfoOnly(writer: anytype, sys_info: system.SystemInfo) !void {
    try writer.print("OS: {s}\n", .{sys_info.os_name});
    try writer.print("Kernel: {s}\n", .{sys_info.kernel});
    try writer.print("Uptime: {d}s\n", .{sys_info.uptime_seconds});
    try writer.print("Shell: {s}\n", .{sys_info.shell});
    try writer.print("CPU: {s}\n", .{sys_info.cpu_model});
    try writer.print("Memory: {d} / {d} bytes\n", .{ sys_info.memory_used, sys_info.memory_total });
}
