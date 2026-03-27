cask "kubectx-bar" do
  version "1.0.0"
  sha256 "922f2a3f15a4cd208fdff830cddd033719275fa41fb8debc86235baf9dd4882c"

  url "https://github.com/mohsinzaheer25/KubeCtxBar/releases/download/v#{version}/KubeCtx-#{version}.zip"
  name "KubeCtx"
  desc "Kubernetes context switcher for the menu bar"
  homepage "https://github.com/mohsinzaheer25/KubeCtxBar"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "KubeCtx.app"

  zap trash: "~/Library/Preferences/com.kubectx.app.plist"
end
