# Homebrew Installation

KubeCtx can be installed via Homebrew using our custom tap.

## Install

```bash
brew install --cask mohsinzaheer25/tap/kubectx-bar
```

Or tap first, then install:

```bash
brew tap mohsinzaheer25/tap
brew install --cask kubectx-bar
```

## Uninstall

```bash
brew uninstall --cask kubectx-bar
```

## Update

```bash
brew upgrade --cask kubectx-bar
```

## Tap Repository

The Homebrew tap is maintained at: https://github.com/mohsinzaheer25/homebrew-tap

## For Maintainers

### Releasing a New Version

1. **Build the app**
   ```bash
   cd /path/to/KubeCtxBar
   ./scripts/install.sh
   ```

2. **Create a zip of the app**
   ```bash
   cd /Applications
   zip -r KubeCtx-X.Y.Z.zip KubeCtx.app
   ```

3. **Create a GitHub release**
   ```bash
   gh release create vX.Y.Z KubeCtx-X.Y.Z.zip \
     --repo mohsinzaheer25/KubeCtxBar \
     --title "KubeCtx vX.Y.Z" \
     --notes "Release notes here"
   ```

4. **Get the SHA256**
   ```bash
   shasum -a 256 KubeCtx-X.Y.Z.zip
   ```

5. **Update the cask in homebrew-tap**
   - Update `version` to `X.Y.Z`
   - Update `sha256` with the new hash
   - Commit and push to https://github.com/mohsinzaheer25/homebrew-tap
