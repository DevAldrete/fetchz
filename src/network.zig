//! Network information collection module
//! Handles gathering IP addresses, hostname, and network interface details.

const std = @import("std");
const builtin = @import("builtin");

pub const NetworkInfo = struct {
    hostname: []const u8,
    local_ip: []const u8,
    public_ip: []const u8,
    interfaces: []const Interface,

    allocator: std.mem.Allocator,

    pub fn deinit(self: *const NetworkInfo, allocator: std.mem.Allocator) void {
        allocator.free(self.hostname);
        allocator.free(self.local_ip);
        allocator.free(self.public_ip);
        for (self.interfaces) |iface| {
            allocator.free(iface.name);
            allocator.free(iface.ipv4);
            allocator.free(iface.ipv6);
            allocator.free(iface.mac);
        }
        allocator.free(self.interfaces);
    }
};

pub const Interface = struct {
    name: []const u8,
    ipv4: []const u8,
    ipv6: []const u8,
    mac: []const u8,
    is_up: bool,
    is_loopback: bool,
};

/// Collect all network information
pub fn collectNetworkInfo(allocator: std.mem.Allocator) !NetworkInfo {
    const hostname = try getHostname(allocator);
    const local_ip = try getLocalIP(allocator);
    const public_ip = try getPublicIP(allocator);
    const interfaces = try getNetworkInterfaces(allocator);

    return NetworkInfo{
        .hostname = hostname,
        .local_ip = local_ip,
        .public_ip = public_ip,
        .interfaces = interfaces,
        .allocator = allocator,
    };
}

fn getHostname(allocator: std.mem.Allocator) ![]const u8 {
    var uts: std.posix.utsname = undefined;
    const err = std.posix.system.uname(&uts);
    if (err != 0) {
        return allocator.dupe(u8, "unknown");
    }
    const nodename = std.mem.sliceTo(&uts.nodename, 0);
    return allocator.dupe(u8, nodename);
}

fn getLocalIP(allocator: std.mem.Allocator) ![]const u8 {
    // Try to get the local IP by creating a socket and connecting to a public address
    // This doesn't actually send data, just gets the local interface IP
    switch (builtin.os.tag) {
        .linux, .macos => {
            return getLocalIPViaSockets(allocator);
        },
        else => {
            return allocator.dupe(u8, "Unknown");
        },
    }
}

fn getLocalIPViaSockets(allocator: std.mem.Allocator) ![]const u8 {
    // Create a UDP socket
    const sock = std.posix.socket(
        std.posix.AF.INET,
        std.posix.SOCK.DGRAM,
        0,
    ) catch {
        return allocator.dupe(u8, "Unknown");
    };
    defer std.posix.close(sock);

    // Connect to a public DNS server (doesn't actually send data)
    var dest_addr: std.posix.sockaddr.in = .{
        .family = std.posix.AF.INET,
        .port = std.mem.nativeToBig(u16, 53),
        .addr = std.mem.nativeToBig(u32, 0x08080808), // 8.8.8.8
    };

    std.posix.connect(sock, @ptrCast(&dest_addr), @sizeOf(std.posix.sockaddr.in)) catch {
        return allocator.dupe(u8, "Unknown");
    };

    // Get the local address
    var local_addr: std.posix.sockaddr.in = undefined;
    var addr_len: std.posix.socklen_t = @sizeOf(std.posix.sockaddr.in);

    const result = std.posix.system.getsockname(
        sock,
        @ptrCast(&local_addr),
        &addr_len,
    );

    if (result != 0) {
        return allocator.dupe(u8, "Unknown");
    }

    // Convert the address to string
    const addr = std.mem.nativeToBig(u32, local_addr.addr);
    const ip_str = try std.fmt.allocPrint(allocator, "{}.{}.{}.{}", .{
        @as(u8, @truncate((addr >> 24) & 0xFF)),
        @as(u8, @truncate((addr >> 16) & 0xFF)),
        @as(u8, @truncate((addr >> 8) & 0xFF)),
        @as(u8, @truncate(addr & 0xFF)),
    });

    return ip_str;
}

fn getPublicIP(allocator: std.mem.Allocator) ![]const u8 {
    // Try using curl to get public IP from an API
    const result = runCommand(allocator, &.{ "curl", "-s", "-m", "2", "ifconfig.me" }) catch {
        return allocator.dupe(u8, "N/A");
    };
    defer allocator.free(result);

    if (result.len > 0 and result.len < 50) {
        const trimmed = std.mem.trim(u8, result, " \n\t\r");
        // Basic validation - should only contain digits and dots
        var valid = true;
        for (trimmed) |c| {
            if (!std.ascii.isDigit(c) and c != '.') {
                valid = false;
                break;
            }
        }
        if (valid and trimmed.len > 0) {
            return allocator.dupe(u8, trimmed);
        }
    }
    return allocator.dupe(u8, "N/A");
}

fn getNetworkInterfaces(allocator: std.mem.Allocator) ![]const Interface {
    var interfaces: std.ArrayList(Interface) = .empty;
    errdefer {
        for (interfaces.items) |iface| {
            allocator.free(iface.name);
            allocator.free(iface.ipv4);
            allocator.free(iface.ipv6);
            allocator.free(iface.mac);
        }
        interfaces.deinit(allocator);
    }

    switch (builtin.os.tag) {
        .linux => try getLinuxInterfaces(allocator, &interfaces),
        .macos => try getMacOSInterfaces(allocator, &interfaces),
        else => {},
    }

    return interfaces.toOwnedSlice(allocator);
}

fn getLinuxInterfaces(allocator: std.mem.Allocator, interfaces: *std.ArrayList(Interface)) !void {
    // Parse /proc/net/dev for interface names
    const dev_file = std.fs.openFileAbsolute("/proc/net/dev", .{}) catch return;
    defer dev_file.close();

    var buf: [4096]u8 = undefined;
    const bytes_read = try dev_file.readAll(&buf);
    var lines = std.mem.splitSequence(u8, buf[0..bytes_read], "\n");

    // Skip header lines
    _ = lines.next();
    _ = lines.next();

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (trimmed.len == 0) continue;

        // Interface name is before the colon
        if (std.mem.indexOf(u8, trimmed, ":")) |colon_idx| {
            const iface_name = std.mem.trim(u8, trimmed[0..colon_idx], " ");

            // Skip loopback for display purposes (but mark it)
            const is_loopback = std.mem.eql(u8, iface_name, "lo");

            // Get IP addresses for this interface
            const ipv4 = try getLinuxInterfaceIPv4(allocator, iface_name);
            const ipv6 = try allocator.dupe(u8, ""); // Simplified - IPv6 detection is more complex
            const mac = try getLinuxMAC(allocator, iface_name);

            try interfaces.append(allocator, .{
                .name = try allocator.dupe(u8, iface_name),
                .ipv4 = ipv4,
                .ipv6 = ipv6,
                .mac = mac,
                .is_up = true, // Simplified
                .is_loopback = is_loopback,
            });
        }
    }
}

fn getLinuxInterfaceIPv4(allocator: std.mem.Allocator, iface_name: []const u8) ![]const u8 {
    // Use ip command to get address
    const result = runCommand(allocator, &.{ "ip", "-4", "addr", "show", iface_name }) catch {
        return allocator.dupe(u8, "");
    };
    defer allocator.free(result);

    // Parse output for inet line
    var lines = std.mem.splitSequence(u8, result, "\n");
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (std.mem.startsWith(u8, trimmed, "inet ")) {
            const rest = trimmed["inet ".len..];
            // IP is before the slash
            if (std.mem.indexOf(u8, rest, "/")) |slash_idx| {
                return allocator.dupe(u8, rest[0..slash_idx]);
            } else if (std.mem.indexOf(u8, rest, " ")) |space_idx| {
                return allocator.dupe(u8, rest[0..space_idx]);
            }
        }
    }
    return allocator.dupe(u8, "");
}

fn getLinuxMAC(allocator: std.mem.Allocator, iface_name: []const u8) ![]const u8 {
    // Read from /sys/class/net/<iface>/address
    var path_buf: [256]u8 = undefined;
    const path = std.fmt.bufPrint(&path_buf, "/sys/class/net/{s}/address", .{iface_name}) catch {
        return allocator.dupe(u8, "");
    };

    const file = std.fs.openFileAbsolute(path, .{}) catch {
        return allocator.dupe(u8, "");
    };
    defer file.close();

    var buf: [32]u8 = undefined;
    const bytes_read = file.readAll(&buf) catch {
        return allocator.dupe(u8, "");
    };

    const mac = std.mem.trim(u8, buf[0..bytes_read], " \n\t");
    return allocator.dupe(u8, mac);
}

fn getMacOSInterfaces(allocator: std.mem.Allocator, interfaces: *std.ArrayList(Interface)) !void {
    // Use ifconfig to get interface info
    const result = runCommand(allocator, &.{ "ifconfig", "-a" }) catch return;
    defer allocator.free(result);

    var current_iface: ?[]const u8 = null;
    var current_ipv4: []const u8 = "";
    var current_mac: []const u8 = "";
    var current_is_loopback: bool = false;

    var lines = std.mem.splitSequence(u8, result, "\n");
    while (lines.next()) |line| {
        // New interface starts at column 0 (no leading whitespace)
        if (line.len > 0 and line[0] != ' ' and line[0] != '\t') {
            // Save previous interface if exists
            if (current_iface) |iface| {
                try interfaces.append(allocator, .{
                    .name = try allocator.dupe(u8, iface),
                    .ipv4 = if (current_ipv4.len > 0) try allocator.dupe(u8, current_ipv4) else try allocator.dupe(u8, ""),
                    .ipv6 = try allocator.dupe(u8, ""),
                    .mac = if (current_mac.len > 0) try allocator.dupe(u8, current_mac) else try allocator.dupe(u8, ""),
                    .is_up = true,
                    .is_loopback = current_is_loopback,
                });
            }

            // Parse new interface name (before colon)
            if (std.mem.indexOf(u8, line, ":")) |colon_idx| {
                current_iface = line[0..colon_idx];
                current_ipv4 = "";
                current_mac = "";
                current_is_loopback = std.mem.startsWith(u8, line, "lo");
            }
        } else {
            const trimmed = std.mem.trim(u8, line, " \t");

            // Look for inet (IPv4)
            if (std.mem.startsWith(u8, trimmed, "inet ")) {
                const rest = trimmed["inet ".len..];
                if (std.mem.indexOf(u8, rest, " ")) |space_idx| {
                    current_ipv4 = rest[0..space_idx];
                }
            }
            // Look for ether (MAC)
            else if (std.mem.startsWith(u8, trimmed, "ether ")) {
                const rest = trimmed["ether ".len..];
                if (std.mem.indexOf(u8, rest, " ")) |space_idx| {
                    current_mac = rest[0..space_idx];
                } else {
                    current_mac = rest;
                }
            }
        }
    }

    // Don't forget the last interface
    if (current_iface) |iface| {
        try interfaces.append(allocator, .{
            .name = try allocator.dupe(u8, iface),
            .ipv4 = if (current_ipv4.len > 0) try allocator.dupe(u8, current_ipv4) else try allocator.dupe(u8, ""),
            .ipv6 = try allocator.dupe(u8, ""),
            .mac = if (current_mac.len > 0) try allocator.dupe(u8, current_mac) else try allocator.dupe(u8, ""),
            .is_up = true,
            .is_loopback = current_is_loopback,
        });
    }
}

fn runCommand(allocator: std.mem.Allocator, argv: []const []const u8) ![]const u8 {
    var child = std.process.Child.init(argv, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Ignore;

    try child.spawn();

    const stdout = child.stdout.?;
    const output = try stdout.readToEndAlloc(allocator, 65536);

    _ = try child.wait();

    return output;
}
