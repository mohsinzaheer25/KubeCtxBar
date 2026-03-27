# KubeCtx

A lightweight macOS menu bar application for quickly switching Kubernetes contexts.

![macOS](https://img.shields.io/badge/macOS-14.0+-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange?logo=swift)
[![GitHub stars](https://img.shields.io/github/stars/mohsinzaheer25/KubeCtxBar?style=social)](https://github.com/mohsinzaheer25/KubeCtxBar)

<p align="center">
  <img src="assets/screenshot.png" alt="KubeCtx Screenshot" width="320">
</p>

## Features

- **Quick Context Switching** - Switch Kubernetes contexts with a single click
- **Menu Bar Native** - Lives in your menu bar, no dock icon
- **Smart Name Extraction** - Automatically extracts readable names from EKS ARNs, GKE contexts, etc.
- **Real-time Updates** - Automatically detects kubeconfig changes
- **Search & Filter** - Quickly find contexts with built-in search
- **Keyboard Navigation** - Use arrow keys and Enter to navigate
- **Launch at Login** - Start automatically when you log in
- **Lightweight** - Minimal memory footprint, native Swift/SwiftUI

## Installation

### Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/mohsinzaheer25/KubeCtxBar/main/scripts/install.sh | bash
```

### Using Homebrew

```bash
brew tap mohsinzaheer25/tap
brew install --cask kubectx-bar
```

### Manual Installation

#### Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode Command Line Tools (`xcode-select --install`)
- kubectl installed and configured

#### Build from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/mohsinzaheer25/KubeCtxBar.git
   cd KubeCtxBar
   ```

2. **Build the release**
   ```bash
   swift build -c release
   ```

3. **Run the install script**
   ```bash
   ./scripts/install.sh
   ```

   Or manually create the app bundle:
   ```bash
   # Create app structure
   mkdir -p KubeCtx.app/Contents/MacOS
   mkdir -p KubeCtx.app/Contents/Resources
   
   # Copy executable
   cp .build/release/KubeCtxBar KubeCtx.app/Contents/MacOS/KubeCtx
   
   # Copy Info.plist (edit CFBundleExecutable to "KubeCtx")
   cp KubeCtxBar/Resources/Info.plist KubeCtx.app/Contents/
   
   # Copy icon
   cp AppIcon.icns KubeCtx.app/Contents/Resources/
   
   # Sign the app
   codesign --force --sign - KubeCtx.app
   
   # Move to Applications
   mv KubeCtx.app /Applications/
   
   # Remove quarantine
   xattr -cr /Applications/KubeCtx.app
   ```

4. **Launch the app**
   ```bash
   open /Applications/KubeCtx.app
   ```

## Usage

1. **Click the icon** in your menu bar to open the context list
2. **Click a context** to switch to it
3. **Use search** to filter contexts (or press `/` to focus search)
4. **Keyboard navigation**: Use `↑`/`↓` arrows and `Enter` to select

### Settings

- **Launch at Login** - Automatically start KubeCtx when you log in
- Access settings via the gear icon in the footer

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `/` | Focus search |
| `↑` / `↓` | Navigate contexts |
| `Enter` | Switch to selected context |
| `Esc` | Close settings / Clear search |

## Configuration

KubeCtx reads your Kubernetes configuration from:

1. `~/.kube/config` (default)
2. Paths specified in the `KUBECONFIG` environment variable

### Supported Cloud Providers

KubeCtx automatically extracts friendly names from:

- **AWS EKS** - Extracts cluster name from ARN
- **Google GKE** - Extracts cluster name from context
- **DigitalOcean** - Extracts cluster name
- **Minikube, Kind, k3d** - Shows with appropriate badges
- **Rancher, Docker Desktop** - Recognized and labeled

## Development

### Requirements

- macOS 14.0+
- Swift 5.9+
- Xcode 15+ (for development)

### Project Structure

```
KubeCtxBar/
├── Package.swift           # Swift Package Manager config
├── KubeCtxBar/
│   ├── KubeCtxBarApp.swift # App entry point
│   ├── Core/               # Business logic
│   │   ├── Models/         # Data models
│   │   ├── KubeConfigParser.swift
│   │   ├── ContextSwitcher.swift
│   │   └── KubeConfigWatcher.swift
│   ├── ViewModels/         # MVVM view models
│   ├── Views/              # SwiftUI views
│   ├── Design/             # Design system
│   └── Resources/          # Info.plist, assets
├── KubeCtxBarTests/        # Unit tests
└── scripts/
    └── install.sh          # Installation script
```

### Building for Development

```bash
# Debug build
swift build

# Run tests
swift test

# Release build
swift build -c release
```

### Running from Source

```bash
swift run
```

## Troubleshooting

### App shows "damaged or incomplete" error

Run:
```bash
xattr -cr /Applications/KubeCtx.app
```

### Contexts not showing

1. Verify kubectl works: `kubectl config get-contexts`
2. Check kubeconfig path: `echo $KUBECONFIG`
3. Ensure `~/.kube/config` exists and is readable

### Context switch fails

1. Ensure kubectl is in PATH
2. Check kubectl works: `kubectl config use-context <context-name>`

## Uninstall

```bash
# Remove the app
rm -rf /Applications/KubeCtx.app

# Remove preferences (optional)
defaults delete com.kubectx.app
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by [kubectx](https://github.com/ahmetb/kubectx)
- Built with SwiftUI and ❤️
