//! System information collection module
//! Handles gathering OS, kernel, CPU, memory, disk, and other system details.

const std = @import("std");
const builtin = @import("builtin");

/// Contains all collected system information
pub const SystemInfo = struct {
    // Basic info
    hostname: []const u8,
    username: []const u8,
    os_name: []const u8,
    os_version: []const u8,
    kernel: []const u8,
    arch: []const u8,

    // Uptime
    uptime_seconds: u64,

    // Shell
    shell: []const u8,
    shell_version: []const u8,

    // Terminal
    terminal: []const u8,

    // CPU
    cpu_model: []const u8,
    cpu_cores: u32,
    cpu_threads: u32,

    // Memory (in bytes)
    memory_total: u64,
    memory_used: u64,
    memory_available: u64,

    // Disk (in bytes)
    disk_total: u64,
    disk_used: u64,
    disk_available: u64,

    // Locale
    locale: []const u8,

    allocator: std.mem.Allocator,

    pub fn deinit(self: *const SystemInfo, allocator: std.mem.Allocator) void {
        allocator.free(self.hostname);
        allocator.free(self.username);
        allocator.free(self.os_name);
        allocator.free(self.os_version);
        allocator.free(self.kernel);
        allocator.free(self.shell);
        allocator.free(self.shell_version);
        allocator.free(self.terminal);
        allocator.free(self.cpu_model);
        allocator.free(self.locale);
        // arch is compile-time constant, no need to free
    }
};

/// Collect all system information
pub fn collectSystemInfo(allocator: std.mem.Allocator) !SystemInfo {
    return switch (builtin.os.tag) {
        .linux => collectLinuxInfo(allocator),
        .macos => collectMacOSInfo(allocator),
        else => @compileError("Unsupported operating system"),
    };
}

// ============================================================================
// Linux Implementation
// ============================================================================

fn collectLinuxInfo(allocator: std.mem.Allocator) !SystemInfo {
    const hostname = try getHostname(allocator);
    const username = try getUsername(allocator);
    const os_info = try getLinuxOSInfo(allocator);
    const kernel = try getLinuxKernel(allocator);
    const uptime = try getLinuxUptime();
    const shell_info = try getShellInfo(allocator);
    const terminal = try getTerminal(allocator);
    const cpu_info = try getLinuxCPUInfo(allocator);
    const mem_info = try getLinuxMemoryInfo();
    const disk_info = try getLinuxDiskInfo(allocator);
    const locale = try getLocale(allocator);

    return SystemInfo{
        .hostname = hostname,
        .username = username,
        .os_name = os_info.name,
        .os_version = os_info.version,
        .kernel = kernel,
        .arch = @tagName(builtin.cpu.arch),
        .uptime_seconds = uptime,
        .shell = shell_info.name,
        .shell_version = shell_info.version,
        .terminal = terminal,
        .cpu_model = cpu_info.model,
        .cpu_cores = cpu_info.cores,
        .cpu_threads = cpu_info.threads,
        .memory_total = mem_info.total,
        .memory_used = mem_info.used,
        .memory_available = mem_info.available,
        .disk_total = disk_info.total,
        .disk_used = disk_info.used,
        .disk_available = disk_info.available,
        .locale = locale,
        .allocator = allocator,
    };
}

fn getLinuxOSInfo(allocator: std.mem.Allocator) !struct { name: []const u8, version: []const u8 } {
    // Try /etc/os-release first
    if (std.fs.openFileAbsolute("/etc/os-release", .{})) |file| {
        defer file.close();
        var name: []const u8 = try allocator.dupe(u8, "Linux");
        var version: []const u8 = try allocator.dupe(u8, "Unknown");

        var buf: [4096]u8 = undefined;
        const bytes_read = try file.readAll(&buf);
        var lines = std.mem.splitSequence(u8, buf[0..bytes_read], "\n");

        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "PRETTY_NAME=")) {
                const raw = line["PRETTY_NAME=".len..];
                const unquoted = std.mem.trim(u8, raw, "\"");
                allocator.free(name);
                name = try allocator.dupe(u8, unquoted);
            } else if (std.mem.startsWith(u8, line, "VERSION_ID=")) {
                const raw = line["VERSION_ID=".len..];
                const unquoted = std.mem.trim(u8, raw, "\"");
                allocator.free(version);
                version = try allocator.dupe(u8, unquoted);
            }
        }
        return .{ .name = name, .version = version };
    } else |_| {
        return .{
            .name = try allocator.dupe(u8, "Linux"),
            .version = try allocator.dupe(u8, "Unknown"),
        };
    }
}

fn getLinuxKernel(allocator: std.mem.Allocator) ![]const u8 {
    var uts: std.posix.utsname = undefined;
    const err = std.posix.system.uname(&uts);
    if (err != 0) {
        return allocator.dupe(u8, "Unknown");
    }
    const release = std.mem.sliceTo(&uts.release, 0);
    return allocator.dupe(u8, release);
}

fn getLinuxUptime() !u64 {
    if (std.fs.openFileAbsolute("/proc/uptime", .{})) |file| {
        defer file.close();
        var buf: [64]u8 = undefined;
        const bytes_read = try file.readAll(&buf);
        var parts = std.mem.splitSequence(u8, buf[0..bytes_read], " ");
        if (parts.next()) |uptime_str| {
            // Parse the floating point uptime
            var int_parts = std.mem.splitSequence(u8, uptime_str, ".");
            if (int_parts.next()) |int_str| {
                return std.fmt.parseInt(u64, int_str, 10) catch 0;
            }
        }
    } else |_| {}
    return 0;
}

const CPUInfo = struct {
    model: []const u8,
    cores: u32,
    threads: u32,
};

fn getLinuxCPUInfo(allocator: std.mem.Allocator) !CPUInfo {
    var model: []const u8 = try allocator.dupe(u8, "Unknown");
    var threads: u32 = 0;
    var cores: u32 = 0;
    var physical_ids = std.AutoHashMap(u32, void).init(allocator);
    defer physical_ids.deinit();

    if (std.fs.openFileAbsolute("/proc/cpuinfo", .{})) |file| {
        defer file.close();
        var buf: [32768]u8 = undefined;
        const bytes_read = try file.readAll(&buf);
        var lines = std.mem.splitSequence(u8, buf[0..bytes_read], "\n");

        while (lines.next()) |line| {
            if (std.mem.startsWith(u8, line, "model name")) {
                if (std.mem.indexOf(u8, line, ":")) |colon_idx| {
                    const value = std.mem.trim(u8, line[colon_idx + 1 ..], " \t");
                    if (std.mem.eql(u8, model, "Unknown")) {
                        allocator.free(model);
                        model = try allocator.dupe(u8, value);
                    }
                }
            } else if (std.mem.startsWith(u8, line, "processor")) {
                threads += 1;
            } else if (std.mem.startsWith(u8, line, "cpu cores")) {
                if (std.mem.indexOf(u8, line, ":")) |colon_idx| {
                    const value = std.mem.trim(u8, line[colon_idx + 1 ..], " \t");
                    cores = std.fmt.parseInt(u32, value, 10) catch cores;
                }
            }
        }
    } else |_| {}

    if (cores == 0) cores = threads;

    return CPUInfo{
        .model = model,
        .cores = if (cores > 0) cores else 1,
        .threads = if (threads > 0) threads else 1,
    };
}

const MemoryInfo = struct {
    total: u64,
    used: u64,
    available: u64,
};

fn getLinuxMemoryInfo() !MemoryInfo {
    var total: u64 = 0;
    var available: u64 = 0;
    var free: u64 = 0;
    var buffers: u64 = 0;
    var cached: u64 = 0;

    if (std.fs.openFileAbsolute("/proc/meminfo", .{})) |file| {
        defer file.close();
        var buf: [4096]u8 = undefined;
        const bytes_read = try file.readAll(&buf);
        var lines = std.mem.splitSequence(u8, buf[0..bytes_read], "\n");

        while (lines.next()) |line| {
            const parsed = parseMemInfoLine(line);
            if (std.mem.eql(u8, parsed.key, "MemTotal")) {
                total = parsed.value * 1024; // Convert from KB to bytes
            } else if (std.mem.eql(u8, parsed.key, "MemAvailable")) {
                available = parsed.value * 1024;
            } else if (std.mem.eql(u8, parsed.key, "MemFree")) {
                free = parsed.value * 1024;
            } else if (std.mem.eql(u8, parsed.key, "Buffers")) {
                buffers = parsed.value * 1024;
            } else if (std.mem.eql(u8, parsed.key, "Cached")) {
                cached = parsed.value * 1024;
            }
        }
    } else |_| {}

    // If MemAvailable isn't present (older kernels), estimate it
    if (available == 0) {
        available = free + buffers + cached;
    }

    return MemoryInfo{
        .total = total,
        .used = total -| available,
        .available = available,
    };
}

fn parseMemInfoLine(line: []const u8) struct { key: []const u8, value: u64 } {
    if (std.mem.indexOf(u8, line, ":")) |colon_idx| {
        const key = std.mem.trim(u8, line[0..colon_idx], " \t");
        const rest = std.mem.trim(u8, line[colon_idx + 1 ..], " \t");
        var parts = std.mem.splitSequence(u8, rest, " ");
        if (parts.next()) |value_str| {
            const value = std.fmt.parseInt(u64, value_str, 10) catch 0;
            return .{ .key = key, .value = value };
        }
    }
    return .{ .key = "", .value = 0 };
}

const DiskInfo = struct {
    total: u64,
    used: u64,
    available: u64,
};

fn getLinuxDiskInfo(allocator: std.mem.Allocator) !DiskInfo {
    // Use df command to get disk info
    const result = try runCommand(allocator, &.{ "df", "-B1", "/" });
    defer allocator.free(result);

    var lines = std.mem.splitSequence(u8, result, "\n");
    _ = lines.next(); // Skip header

    if (lines.next()) |line| {
        return parseDfLine(line);
    }

    return DiskInfo{ .total = 0, .used = 0, .available = 0 };
}

fn parseDfLine(line: []const u8) DiskInfo {
    // df -B1 output: Filesystem 1B-blocks Used Available Use% Mounted
    var parts = std.mem.tokenizeAny(u8, line, " \t");

    _ = parts.next(); // filesystem
    const total_str = parts.next() orelse return DiskInfo{ .total = 0, .used = 0, .available = 0 };
    const used_str = parts.next() orelse return DiskInfo{ .total = 0, .used = 0, .available = 0 };
    const avail_str = parts.next() orelse return DiskInfo{ .total = 0, .used = 0, .available = 0 };

    const total = std.fmt.parseInt(u64, total_str, 10) catch 0;
    const used = std.fmt.parseInt(u64, used_str, 10) catch 0;
    const available = std.fmt.parseInt(u64, avail_str, 10) catch 0;

    return DiskInfo{
        .total = total,
        .used = used,
        .available = available,
    };
}

// ============================================================================
// macOS Implementation
// ============================================================================

fn collectMacOSInfo(allocator: std.mem.Allocator) !SystemInfo {
    const hostname = try getHostname(allocator);
    const username = try getUsername(allocator);
    const os_info = try getMacOSInfo(allocator);
    const kernel = try getMacOSKernel(allocator);
    const uptime = try getMacOSUptime();
    const shell_info = try getShellInfo(allocator);
    const terminal = try getTerminal(allocator);
    const cpu_info = try getMacOSCPUInfo(allocator);
    const mem_info = try getMacOSMemoryInfo(allocator);
    const disk_info = try getMacOSDiskInfo(allocator);
    const locale = try getLocale(allocator);

    return SystemInfo{
        .hostname = hostname,
        .username = username,
        .os_name = os_info.name,
        .os_version = os_info.version,
        .kernel = kernel,
        .arch = @tagName(builtin.cpu.arch),
        .uptime_seconds = uptime,
        .shell = shell_info.name,
        .shell_version = shell_info.version,
        .terminal = terminal,
        .cpu_model = cpu_info.model,
        .cpu_cores = cpu_info.cores,
        .cpu_threads = cpu_info.threads,
        .memory_total = mem_info.total,
        .memory_used = mem_info.used,
        .memory_available = mem_info.available,
        .disk_total = disk_info.total,
        .disk_used = disk_info.used,
        .disk_available = disk_info.available,
        .locale = locale,
        .allocator = allocator,
    };
}

fn getMacOSInfo(allocator: std.mem.Allocator) !struct { name: []const u8, version: []const u8 } {
    var name: []const u8 = try allocator.dupe(u8, "macOS");
    var version: []const u8 = try allocator.dupe(u8, "Unknown");

    // Use sw_vers to get version info
    const result = try runCommand(allocator, &.{ "sw_vers", "-productVersion" });
    defer allocator.free(result);
    if (result.len > 0) {
        allocator.free(version);
        version = try allocator.dupe(u8, std.mem.trim(u8, result, " \n\t"));

        // Determine macOS name from version
        const major = getMajorVersion(version);
        const macos_name = switch (major) {
            15 => "macOS Sequoia",
            14 => "macOS Sonoma",
            13 => "macOS Ventura",
            12 => "macOS Monterey",
            11 => "macOS Big Sur",
            10 => "macOS Catalina",
            else => "macOS",
        };
        allocator.free(name);
        name = try allocator.dupe(u8, macos_name);
    }

    return .{ .name = name, .version = version };
}

fn getMajorVersion(version: []const u8) u32 {
    var parts = std.mem.splitSequence(u8, version, ".");
    if (parts.next()) |major_str| {
        return std.fmt.parseInt(u32, major_str, 10) catch 0;
    }
    return 0;
}

fn getMacOSKernel(allocator: std.mem.Allocator) ![]const u8 {
    var uts: std.posix.utsname = undefined;
    const err = std.posix.system.uname(&uts);
    if (err != 0) {
        return allocator.dupe(u8, "Unknown");
    }
    const release = std.mem.sliceTo(&uts.release, 0);
    return allocator.dupe(u8, release);
}

fn getMacOSUptime() !u64 {
    // Use sysctl to get boot time
    const boot_time = std.posix.system.CLOCK.UPTIME_RAW;
    var ts: std.posix.timespec = undefined;
    const result = std.posix.system.clock_gettime(boot_time, &ts);
    if (result == 0) {
        return @intCast(ts.sec);
    }
    return 0;
}

fn getMacOSCPUInfo(allocator: std.mem.Allocator) !CPUInfo {
    var model: []const u8 = try allocator.dupe(u8, "Unknown");
    var cores: u32 = 1;
    var threads: u32 = 1;

    // Get CPU brand string
    const brand_result = try runCommand(allocator, &.{ "sysctl", "-n", "machdep.cpu.brand_string" });
    defer allocator.free(brand_result);
    if (brand_result.len > 0) {
        allocator.free(model);
        model = try allocator.dupe(u8, std.mem.trim(u8, brand_result, " \n\t"));
    }

    // Get core count
    const cores_result = try runCommand(allocator, &.{ "sysctl", "-n", "hw.physicalcpu" });
    defer allocator.free(cores_result);
    if (cores_result.len > 0) {
        cores = std.fmt.parseInt(u32, std.mem.trim(u8, cores_result, " \n\t"), 10) catch 1;
    }

    // Get thread count
    const threads_result = try runCommand(allocator, &.{ "sysctl", "-n", "hw.logicalcpu" });
    defer allocator.free(threads_result);
    if (threads_result.len > 0) {
        threads = std.fmt.parseInt(u32, std.mem.trim(u8, threads_result, " \n\t"), 10) catch 1;
    }

    return CPUInfo{
        .model = model,
        .cores = cores,
        .threads = threads,
    };
}

fn getMacOSMemoryInfo(allocator: std.mem.Allocator) !MemoryInfo {
    var total: u64 = 0;
    var available: u64 = 0;

    // Get total memory via sysctl command
    const total_result = try runCommand(allocator, &.{ "sysctl", "-n", "hw.memsize" });
    defer allocator.free(total_result);
    if (total_result.len > 0) {
        total = std.fmt.parseInt(u64, std.mem.trim(u8, total_result, " \n\t"), 10) catch 0;
    }

    // Get page size and vm_stat for available memory calculation
    const vm_result = try runCommand(allocator, &.{"vm_stat"});
    defer allocator.free(vm_result);

    var free_pages: u64 = 0;
    var inactive_pages: u64 = 0;
    var page_size: u64 = 4096;

    // Parse vm_stat output
    var lines = std.mem.splitSequence(u8, vm_result, "\n");
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "Mach Virtual Memory Statistics")) {
            // First line sometimes contains page size
            if (std.mem.indexOf(u8, line, "page size of ")) |idx| {
                const rest = line[idx + "page size of ".len ..];
                var parts = std.mem.splitSequence(u8, rest, " ");
                if (parts.next()) |ps| {
                    page_size = std.fmt.parseInt(u64, ps, 10) catch 4096;
                }
            }
        } else if (std.mem.startsWith(u8, line, "Pages free:")) {
            free_pages = parseVmStatLine(line);
        } else if (std.mem.startsWith(u8, line, "Pages inactive:")) {
            inactive_pages = parseVmStatLine(line);
        }
    }

    available = (free_pages + inactive_pages) * page_size;

    return MemoryInfo{
        .total = total,
        .used = total -| available,
        .available = available,
    };
}

fn parseVmStatLine(line: []const u8) u64 {
    // Lines are like "Pages free:                              123456."
    if (std.mem.indexOf(u8, line, ":")) |colon_idx| {
        const rest = std.mem.trim(u8, line[colon_idx + 1 ..], " \t.");
        return std.fmt.parseInt(u64, rest, 10) catch 0;
    }
    return 0;
}

fn getMacOSDiskInfo(allocator: std.mem.Allocator) !DiskInfo {
    // Use df command to get disk info (macOS df output is similar to Linux)
    const result = try runCommand(allocator, &.{ "df", "-k", "/" });
    defer allocator.free(result);

    var lines = std.mem.splitSequence(u8, result, "\n");
    _ = lines.next(); // Skip header

    if (lines.next()) |line| {
        return parseDfLineKB(line);
    }

    return DiskInfo{ .total = 0, .used = 0, .available = 0 };
}

fn parseDfLineKB(line: []const u8) DiskInfo {
    // df -k output: Filesystem 1024-blocks Used Available Capacity Mounted
    var parts = std.mem.tokenizeAny(u8, line, " \t");

    _ = parts.next(); // filesystem
    const total_str = parts.next() orelse return DiskInfo{ .total = 0, .used = 0, .available = 0 };
    const used_str = parts.next() orelse return DiskInfo{ .total = 0, .used = 0, .available = 0 };
    const avail_str = parts.next() orelse return DiskInfo{ .total = 0, .used = 0, .available = 0 };

    // Values are in KB, convert to bytes
    const total = (std.fmt.parseInt(u64, total_str, 10) catch 0) * 1024;
    const used = (std.fmt.parseInt(u64, used_str, 10) catch 0) * 1024;
    const available = (std.fmt.parseInt(u64, avail_str, 10) catch 0) * 1024;

    return DiskInfo{
        .total = total,
        .used = used,
        .available = available,
    };
}

// ============================================================================
// Common Functions
// ============================================================================

fn getHostname(allocator: std.mem.Allocator) ![]const u8 {
    var uts: std.posix.utsname = undefined;
    const err = std.posix.system.uname(&uts);
    if (err != 0) {
        return allocator.dupe(u8, "unknown");
    }
    const nodename = std.mem.sliceTo(&uts.nodename, 0);
    return allocator.dupe(u8, nodename);
}

fn getUsername(allocator: std.mem.Allocator) ![]const u8 {
    if (std.posix.getenv("USER")) |user| {
        return allocator.dupe(u8, user);
    }
    if (std.posix.getenv("LOGNAME")) |user| {
        return allocator.dupe(u8, user);
    }
    return allocator.dupe(u8, "unknown");
}

const ShellInfo = struct {
    name: []const u8,
    version: []const u8,
};

fn getShellInfo(allocator: std.mem.Allocator) !ShellInfo {
    const shell_path = std.posix.getenv("SHELL") orelse "/bin/sh";

    // Extract shell name from path
    var name: []const u8 = undefined;
    if (std.mem.lastIndexOf(u8, shell_path, "/")) |idx| {
        name = try allocator.dupe(u8, shell_path[idx + 1 ..]);
    } else {
        name = try allocator.dupe(u8, shell_path);
    }

    // Try to get shell version
    var version: []const u8 = try allocator.dupe(u8, "");
    if (std.mem.eql(u8, name, "bash")) {
        const result = try runCommand(allocator, &.{ "bash", "--version" });
        defer allocator.free(result);
        if (extractVersion(result, "version ")) |ver| {
            allocator.free(version);
            version = try allocator.dupe(u8, ver);
        }
    } else if (std.mem.eql(u8, name, "zsh")) {
        const result = try runCommand(allocator, &.{ "zsh", "--version" });
        defer allocator.free(result);
        if (extractVersion(result, "zsh ")) |ver| {
            allocator.free(version);
            version = try allocator.dupe(u8, ver);
        }
    } else if (std.mem.eql(u8, name, "fish")) {
        const result = try runCommand(allocator, &.{ "fish", "--version" });
        defer allocator.free(result);
        if (extractVersion(result, "fish, version ")) |ver| {
            allocator.free(version);
            version = try allocator.dupe(u8, ver);
        }
    }

    return ShellInfo{ .name = name, .version = version };
}

fn extractVersion(output: []const u8, prefix: []const u8) ?[]const u8 {
    if (std.mem.indexOf(u8, output, prefix)) |start| {
        const rest = output[start + prefix.len ..];
        // Find end of version (space, newline, or special char)
        var end: usize = 0;
        for (rest, 0..) |c, i| {
            if (c == ' ' or c == '\n' or c == '(' or c == '-') {
                end = i;
                break;
            }
            end = i + 1;
        }
        if (end > 0) {
            return rest[0..end];
        }
    }
    return null;
}

fn getTerminal(allocator: std.mem.Allocator) ![]const u8 {
    // Try common terminal environment variables
    if (std.posix.getenv("TERM_PROGRAM")) |term| {
        return allocator.dupe(u8, term);
    }
    if (std.posix.getenv("TERMINAL")) |term| {
        return allocator.dupe(u8, term);
    }
    if (std.posix.getenv("TERM")) |term| {
        return allocator.dupe(u8, term);
    }
    return allocator.dupe(u8, "Unknown");
}

fn getLocale(allocator: std.mem.Allocator) ![]const u8 {
    if (std.posix.getenv("LANG")) |lang| {
        return allocator.dupe(u8, lang);
    }
    if (std.posix.getenv("LC_ALL")) |lang| {
        return allocator.dupe(u8, lang);
    }
    return allocator.dupe(u8, "C");
}

fn runCommand(allocator: std.mem.Allocator, argv: []const []const u8) ![]const u8 {
    var child = std.process.Child.init(argv, allocator);
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Ignore;

    try child.spawn();

    const stdout = child.stdout.?;
    const output = try stdout.readToEndAlloc(allocator, 4096);

    _ = try child.wait();

    return output;
}
