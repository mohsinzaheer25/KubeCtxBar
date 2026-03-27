# Homebrew Installation

## Setting up Homebrew Tap

To distribute KubeCtx via Homebrew, you need to create a tap repository:

### 1. Create a Tap Repository

1. Go to GitHub and create a new repository named `homebrew-tap`
2. Clone it locally:
   ```bash
   git clone https://github.com/mohsinzaheer25/homebrew-tap.git
   cd homebrew-tap
   ```

### 2. Add the Cask

1. Create the Casks directory:
   ```bash
   mkdir -p Casks
   ```

2. Copy the cask file:
   ```bash
   cp /path/to/KubeCtxBar/homebrew/kubectx-bar.rb Casks/
   ```

3. Commit and push:
   ```bash
   git add .
   git commit -m "Add kubectx-bar cask"
   git push
   ```

### 3. Create a Release

1. Build the app:
   ```bash
   cd /path/to/KubeCtxBar
   ./scripts/install.sh
   ```

2. Create a zip file:
   ```bash
   cd /Applications
   zip -r KubeCtx.app.zip KubeCtx.app
   ```

3. Create a GitHub release:
   - Go to https://github.com/mohsinzaheer25/KubeCtxBar/releases
   - Click "Create a new release"
   - Tag: `v1.0.0`
   - Upload `KubeCtx.app.zip`

4. Update the cask with the SHA256:
   ```bash
   shasum -a 256 KubeCtx.app.zip
   ```
   Update `sha256` in `kubectx-bar.rb`

### 4. Users Can Now Install

```bash
brew tap mohsinzaheer25/tap
brew install --cask kubectx-bar
```

## Alternative: Build from Source Formula

If you prefer users to build from source, use the formula in `kubectx-bar-formula.rb`.
