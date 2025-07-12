# AdGuard DNS Toggle

A modern macOS application for toggling AdGuard DNS protection via dnsproxy with a beautiful native UI.

## Features

- 🎨 **Modern UI**: Clean, native macOS interface with smooth animations
- 🔄 **Real-time Status**: Live monitoring of AdGuard DNS daemon status
- 🚀 **One-click Toggle**: Simple enable/disable with visual feedback
- 🛡️ **Secure**: Runs without root privileges for enhanced security
- 📱 **Dock Integration**: Native macOS app with custom icon
- 🔧 **Configurable**: Environment variables for customization

## Requirements

- macOS 11.0 or later
- Homebrew (for dnsproxy installation)
- AdGuard DNS subscription (optional, for custom upstream servers)

## Installation

### 1. Install Dependencies

```bash
# Install dnsproxy via Homebrew
brew install adguard/tap/dnsproxy

# Verify installation
dnsproxy --version
```

### 2. Build and Install

```bash
# Clone the repository
git clone <repository-url>
cd adguard-dns-toggle

# Build the application
./Build.sh

# The app bundle will be created as "AdGuard DNS Toggle.app"
```

### 3. Setup Daemon

```bash
# Install the launch agent
cp LaunchAgents/com.adguard.toggle.daemon.plist ~/Library/LaunchAgents/

# Load the daemon
launchctl load ~/Library/LaunchAgents/com.adguard.toggle.daemon.plist
```

## Usage

1. **Launch the app**: Double-click `AdGuard DNS Toggle.app` or run from terminal
2. **Check status**: The app shows current AdGuard DNS status
3. **Toggle protection**: Click the button to enable/disable AdGuard DNS
4. **Monitor**: Status updates automatically every 3 seconds

## Configuration

### Environment Variables

You can customize the daemon behavior by setting environment variables:

```bash
# DNS proxy settings
export DNSPROXY_PATH="/opt/homebrew/bin/dnsproxy"
export CONFIG_PATH="/path/to/dnsproxy-config.yml"
export PORT="53535"
export LISTEN_ADDR="127.0.0.1"

# File paths
export PID_FILE="/tmp/dnsproxy.pid"
export CMD_PIPE="/tmp/adguard-cmd-pipe"
export LOG_FILE="/tmp/adguard-daemon.log"
```

### DNS Configuration

Edit `Scripts/dnsproxy-config.yml` to customize DNS settings:

```yaml
upstream_dns:
  - 176.103.130.130
  - 176.103.130.131

upstream_dns_file: ""
upstream_timeout: 10s

local_dns:
  - 127.0.0.1:53

max_goroutines: 300

local_ip: 127.0.0.1
local_port: 53535
```

## Architecture

### Components

- **App**: SwiftUI/macOS application with native UI
- **Daemon**: Bash script managing dnsproxy process
- **Launch Agent**: macOS service for automatic startup
- **Configuration**: YAML-based DNS proxy settings

### Communication

The app communicates with the daemon via named pipes:
- Command pipe: `/tmp/adguard-cmd-pipe`
- Status monitoring: PID file and process checking
- Logging: Structured logging with timestamps

## Development

### Building

```bash
# Development build
cd AdGuardDNSController
swift build

# Release build with app bundle
./Build.sh
```

### Project Structure

```
adguard-dns-toggle/
├── AdGuardDNSController/     # Swift application
│   ├── Sources/             # Swift source files
│   ├── Resources/           # App resources and config
│   └── Package.swift        # Swift Package Manager config
├── Scripts/                 # Shell scripts
│   ├── daemon.sh           # Main daemon script
│   └── dnsproxy-config.yml # DNS proxy configuration
├── LaunchAgents/           # macOS launch agents
└── Build.sh               # Build script
```

### Logging

The application uses structured logging with different categories:
- `app`: Application lifecycle events
- `ui`: User interface interactions
- `daemon`: Daemon communication
- `network`: Network operations

Logs are available in Console.app under the subsystem `com.adguard.toggle`.

## Troubleshooting

### Common Issues

1. **Daemon not starting**
   ```bash
   # Check launch agent status
   launchctl list | grep adguard
   
   # Check logs
   tail -f /tmp/adguard-daemon.log
   ```

2. **Permission denied**
   ```bash
   # Fix script permissions
   chmod +x Scripts/daemon.sh
   chmod +x Build.sh
   ```

3. **dnsproxy not found**
   ```bash
   # Install dnsproxy
   brew install adguard/tap/dnsproxy
   ```

### Debug Mode

Enable debug logging by setting the environment variable:
```bash
export OS_ACTIVITY_MODE=debug
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the troubleshooting section
- Review the logs in Console.app
- Open an issue on GitHub

---

**Note**: This application requires dnsproxy to be installed via Homebrew. Make sure you have the latest version for best compatibility.
