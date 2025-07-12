# AdGuard DNS Toggle

A modern macOS application for toggling AdGuard DNS protection via dnsproxy with a beautiful native UI.

## Features

- 🎨 **Modern UI**: Clean, native macOS interface with smooth animations and card-based layout
- 🌐 **Localization**: Full multi-language support (English, German, Russian) and in-app language selector
- 🛠️ **Diagnostics**: Built-in diagnostics window with logs, system checks, and troubleshooting tips
- 👋 **Onboarding**: Welcome window with quick start instructions on first launch
- 🔄 **Real-time Status**: Live monitoring of AdGuard DNS daemon status
- 🚀 **One-click Toggle**: Simple enable/disable with visual feedback
- 🛡️ **Secure**: Runs without root privileges for enhanced security
- 📱 **Dock & Tray Integration**: Native macOS app with custom icon and fully localized tray menu
- 🔔 **Notifications**: Native macOS notifications for status changes, errors, and connection monitoring
- ⚙️ **Modern Preferences**: Preferences window with sections, icons, and advanced settings (autostart, language, notifications)
- 🧩 **Single Instance**: Prevents multiple copies from running (even with LaunchAgent)
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
5. **Diagnostics**: Click the diagnostics icon to view logs and run system checks
6. **Preferences**: Open Preferences to configure autostart, language, notifications, and more
7. **Onboarding**: On first launch, a welcome window will guide you through the basics

## Localization

- The app supports English, German, and Russian.
- All UI elements, tooltips, diagnostics, and error messages are fully localized.
- You can select your preferred language in Preferences (System, English, German, Russian). Changing the language prompts for an app restart.
- The tray menu and all notifications are also localized.

## Diagnostics & Logging

- Centralized logging to `/tmp/adguard-dns-toggle-app.log` for all key operations (processes, file access, parsing, errors)
- Diagnostics window: View recent logs, run system checks, and copy logs for support
- Error reasons are shown directly in the UI cards for transparency

## Preferences & Notifications

- Modern Preferences window with sections and icons
- Options to enable/disable autostart (LaunchAgent), notifications, and connection monitoring
- Language selector for instant localization
- All settings are persistent and user-friendly

## Onboarding

- On first launch, a welcome window introduces the app's main features and usage tips
- The onboarding window appears only once, but can be reset via app settings (if needed)

## Single Instance Protection

- The app uses both process checks and a file lock to prevent multiple instances, even if started manually and via LaunchAgent simultaneously

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

Logs are available in `/tmp/adguard-dns-toggle-app.log` and in Console.app under the subsystem `com.adguard.toggle`.

## Troubleshooting

### Common Issues

1. **Daemon not starting**
   ```bash
   # Check launch agent status
   launchctl list | grep adguard
   
   # Check logs
   tail -f /tmp/adguard-daemon.log
   tail -f /tmp/adguard-dns-toggle-app.log
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

4. **App language not changing**
   - Make sure to restart the app after changing the language in Preferences.

5. **Multiple app instances**
   - The app prevents this, but if you see two icons, try unloading and reloading the LaunchAgent.

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
- Review the logs in Console.app and `/tmp/adguard-dns-toggle-app.log`
- Open an issue on GitHub

---

**Note**: This application requires dnsproxy to be installed via Homebrew. Make sure you have the latest version for best compatibility.
