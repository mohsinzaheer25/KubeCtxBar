# Homebrew Cask for KubeCtx
# 
# To use this cask, you need to create a tap repository:
# 1. Create a repo named "homebrew-tap" on GitHub
# 2. Add this file as Casks/kubectx-bar.rb
# 3. Users can then install via: brew tap mohsinzaheer25/tap && brew install --cask kubectx-bar
#
# For releases, create a GitHub release with a zip file of KubeCtx.app

cask "kubectx-bar" do
  version "1.0.0"
  sha256 :no_check  # Update this with actual SHA256 when you create releases

  url "https://github.com/mohsinzaheer25/KubeCtxBar/releases/download/v#{version}/KubeCtx.app.zip"
  name "KubeCtx"
  desc "Kubernetes context switcher for macOS menu bar"
  homepage "https://github.com/mohsinzaheer25/KubeCtxBar"

  depends_on macos: ">= :sonoma"

  app "KubeCtx.app"

  zap trash: [
    "~/Library/Preferences/com.kubectx.app.plist",
  ]
end
