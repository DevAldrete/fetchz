# fetchz

A fast, simple system information tool written in Zig. Inspired by [neofetch](https://github.com/dylanaraps/neofetch) and [fastfetch](https://github.com/fastfetch-cli/fastfetch), but dead simple and more detailed.

```
        _nnnn_                     aldrete@Aldretes-MacBook-Air.local
       dGGGGMMb                    ----------------------------------
      @p~qp~~qMb                   OS: macOS
      M|@||@) M|                   Kernel: 25.2.0
      @,----.JM|                   Arch: aarch64
     JS^\__/  qKL                  Uptime: 5 hours, 44 mins
    dZP        qKRb                Shell: zsh (or your favorite shell)
   dZP          qKKb               Terminal: tmux (or your favorite terminal)
  fZP            SMMb              CPU: <your-cpu> (and your cores)
  HZM            MMMM              Memory: <memory-using> MiB / <total-memory> MiB (XX%)
  FqM            MMMM              Disk (/): <storage-used> GiB / <total-storage> GiB (XX%)
__| ".        |\dS"qML             Locale: en_US.UTF-8
|    `.       | `' \Zq
_)      \.___.,|     .'            Local IP: <your-ip>
\____   )MMMMMP|   .'              Public IP: N/A
     `-'       `--'                Interface: <interface-network>: <interface-network>
                                   Interface: <bridge>: <bridge>
```

## Features

- **Fast**: Written in Zig, compiles to a ~337KB binary
- **Simple**: No config files, no dependencies, just run it
- **Detailed**: Shows essential system info plus network details
- **Cross-platform**: Supports Linux and macOS
- **Customizable**: CLI flags for different output modes
- **22+ distro logos**: ASCII art for popular Linux distributions and macOS

## Installation

### Build from source

Requires Zig 0.15.0 or later:

```bash
git clone https://github.com/yourusername/fetchz.git
cd fetchz
zig build -Doptimize=ReleaseFast
./zig-out/bin/fetchz
```

### Install to system

```bash
sudo cp zig-out/bin/fetchz /usr/local/bin/
```

## Usage

```bash
fetchz              # Show full system information with ASCII art
fetchz --no-ascii   # Show system information without logo
fetchz --no-color   # Show output without ANSI colors
fetchz --no-network # Hide network information
fetchz --help       # Show help message
fetchz --version    # Show version
```

### Command Line Options

| Option | Short | Description |
|--------|-------|-------------|
| `--help` | `-h` | Show help message and exit |
| `--version` | `-v` | Show version information |
| `--no-ascii` | `-n` | Disable ASCII art logo |
| `--no-color` | `-c` | Disable colored output |
| `--no-network` | | Hide network information |
| `--compact` | | Use compact output mode |

## Information Displayed

### System

- **OS**: Operating system name and version
- **Kernel**: Kernel version
- **Arch**: CPU architecture
- **Uptime**: System uptime
- **Shell**: Current shell and version
- **Terminal**: Terminal emulator
- **CPU**: CPU model, cores, and threads
- **Memory**: Used/total RAM with percentage
- **Disk**: Used/total disk space for root partition
- **Locale**: System locale setting

### Network

- **Local IP**: Local network IP address
- **Public IP**: Public-facing IP address (via ifconfig.me)
- **Interfaces**: Active network interfaces with IPs

## Supported Distros (ASCII Art)

- Arch Linux, Artix, EndeavourOS
- Ubuntu, Kubuntu, Xubuntu, Lubuntu
- Debian
- Fedora, Nobara
- macOS
- NixOS
- Gentoo
- openSUSE, Tumbleweed
- Manjaro, Garuda
- Linux Mint
- Pop!_OS
- Void Linux
- Alpine Linux
- CentOS
- Red Hat Enterprise Linux
- Rocky Linux, AlmaLinux
- FreeBSD, GhostBSD
- OpenBSD
- Slackware
- Kali Linux
- Zorin OS
- elementary OS
- Generic Linux (Tux)

## Project Structure

```
fetchz/
├── src/
│   ├── main.zig      # CLI entry point
│   ├── root.zig      # Library root
│   ├── system.zig    # System info collection
│   ├── network.zig   # Network info collection
│   ├── display.zig   # Output formatting
│   └── ascii.zig     # ASCII art logos
├── build.zig         # Zig build configuration
└── build.zig.zon     # Package manifest
```

## Why Zig?

- **No runtime dependencies**: Single static binary
- **Fast compilation**: Incremental builds are nearly instant
- **Memory safety**: Catches bugs at compile time
- **Cross-compilation**: Build for any platform from any platform
- **Small binaries**: ~337KB release binary vs megabytes for alternatives

## License

MIT

## Contributing

Contributions are welcome! Feel free to:

- Add support for more distros
- Improve system detection
- Add new information fields
- Fix bugs or improve performance
