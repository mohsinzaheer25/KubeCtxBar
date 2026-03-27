# Contributing to KubeCtx

Thank you for your interest in contributing to KubeCtx! This document provides guidelines and instructions for contributing.

## Code of Conduct

Be respectful and constructive. We welcome contributors of all experience levels.

## How to Contribute

### Reporting Bugs

1. Check if the issue already exists in [GitHub Issues](https://github.com/mohsinzaheer25/KubeCtxBar/issues)
2. If not, create a new issue with:
   - Clear title describing the bug
   - Steps to reproduce
   - Expected vs actual behavior
   - macOS version and KubeCtx version
   - Relevant kubeconfig details (sanitized)

### Suggesting Features

1. Check existing [issues](https://github.com/mohsinzaheer25/KubeCtxBar/issues) for similar requests
2. Create a new issue with:
   - Clear description of the feature
   - Use case / why it's needed
   - Any implementation ideas (optional)

### Submitting Code Changes

#### 1. Fork the Repository

Click the "Fork" button on GitHub to create your own copy.

#### 2. Clone Your Fork

```bash
git clone https://github.com/YOUR_USERNAME/KubeCtxBar.git
cd KubeCtxBar
```

#### 3. Set Up Remotes

```bash
# Add the original repo as upstream
git remote add upstream https://github.com/mohsinzaheer25/KubeCtxBar.git

# Verify remotes
git remote -v
# origin    https://github.com/YOUR_USERNAME/KubeCtxBar.git (fetch)
# origin    https://github.com/YOUR_USERNAME/KubeCtxBar.git (push)
# upstream  https://github.com/mohsinzaheer25/KubeCtxBar.git (fetch)
# upstream  https://github.com/mohsinzaheer25/KubeCtxBar.git (push)
```

#### 4. Create a Feature Branch

```bash
# Sync with upstream first
git fetch upstream
git checkout main
git merge upstream/main

# Create your branch
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring

#### 5. Make Your Changes

```bash
# Build to verify changes compile
swift build

# Run tests
swift test

# Test the app manually
swift run
```

#### 6. Commit Your Changes

```bash
git add .
git commit -m "Add: description of your change"
```

Commit message prefixes:
- `Add:` - New feature
- `Fix:` - Bug fix
- `Update:` - Enhancement to existing feature
- `Remove:` - Removing code/feature
- `Refactor:` - Code restructuring
- `Docs:` - Documentation only
- `Test:` - Adding/updating tests

#### 7. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

#### 8. Create a Pull Request

1. Go to your fork on GitHub
2. Click "Compare & pull request"
3. Fill in the PR template:
   - Clear title
   - Description of changes
   - Link to related issue (if any)
   - Screenshots (for UI changes)
4. Submit the PR

## Development Setup

### Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15+ or Xcode Command Line Tools
- Swift 5.9+

### Building

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run tests
swift test
```

### Project Structure

```
KubeCtxBar/
├── Package.swift              # SPM configuration
├── KubeCtxBar/
│   ├── KubeCtxBarApp.swift   # App entry point
│   ├── Core/                  # Business logic
│   │   ├── Models/           # Data models
│   │   ├── KubeConfigParser.swift
│   │   ├── ContextSwitcher.swift
│   │   └── KubeConfigWatcher.swift
│   ├── ViewModels/           # MVVM view models
│   ├── Views/                # SwiftUI views
│   ├── Design/               # Design system tokens
│   └── Resources/            # Info.plist, assets
├── KubeCtxBarTests/          # Unit tests
└── scripts/                  # Build/install scripts
```

## Code Style

- Follow existing code patterns
- Use Swift naming conventions (camelCase for variables, PascalCase for types)
- Keep functions focused and small
- Add documentation comments for public APIs
- No force unwrapping (`!`) unless absolutely necessary

## Testing

- Add tests for new functionality
- Tests must be read-only (no modifications to kubeconfig)
- All tests must pass before PR can be merged

```bash
swift test
```

## Pull Request Checklist

Before submitting your PR, verify:

- [ ] Code compiles without errors (`swift build`)
- [ ] All tests pass (`swift test`)
- [ ] Code follows the existing style
- [ ] Documentation updated (if needed)
- [ ] Commit messages are clear and follow conventions
- [ ] PR description explains the changes

## Syncing Your Fork

Keep your fork up to date:

```bash
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

## Questions?

Feel free to open an issue for any questions about contributing.

Thank you for contributing!
