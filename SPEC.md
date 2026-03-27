# SPEC.md — KubeCtx Bar
## macOS Menu Bar Kubernetes Context Switcher

> **For Claude Code:** Read this entire file before writing any code. This is the authoritative specification. Reference it throughout the session. Do not infer intent — ask if anything is ambiguous.

---

## 1. Product Overview

**KubeCtx Bar** is a native macOS menu bar application that lets engineers switch Kubernetes contexts the way Docker Desktop does — from a single, always-accessible icon in the system status bar. No terminal. No `kubectl config use-context`. Just click, pick, done.

The app targets DevOps/platform engineers who manage multiple clusters (local, staging, prod, EKS, GKE, AKS) daily and need zero-friction context switching without leaving their current workflow.

### Core Value Proposition
- Lives permanently in the macOS menu bar (top right tray)
- Click the icon → popover opens with a premium, glass-morphism UI
- Shows all contexts parsed from `~/.kube/config` (and any extra kubeconfig files)
- One click to switch the active context
- Reads the kubeconfig file in real-time; no manual refresh needed

---

## 2. Target User

| Attribute | Value |
|-----------|-------|
| Role | DevOps / Platform / Backend Engineer |
| OS | macOS 13 Ventura or later |
| Tools | kubectl, Helm, k9s, Lens, Docker Desktop |
| Pain point | Context switching via terminal is friction-heavy across 5–15 clusters |
| Device | Apple Silicon (M-series) primary; Intel secondary |

---

## 3. Tech Stack

| Layer | Technology | Reason |
|-------|------------|--------|
| Language | Swift 5.10+ (Swift 6 concurrency preferred) | Native performance, menu bar APIs |
| UI Framework | SwiftUI | Declarative, modern, `MenuBarExtra` support |
| Menu Bar | `MenuBarExtra` scene (macOS 13+) | First-class SwiftUI menu bar API |
| Popover style | `.window` style for `MenuBarExtra` | Allows custom glass UI beyond simple menu items |
| Config parsing | Pure Swift YAML parser (`Yams` via SPM) | Lightweight, no external tools |
| File watching | `DispatchSource.makeFileSystemObjectSource` | Real-time kubeconfig change detection |
| Shell execution | `Foundation.Process` | Run `kubectl config use-context` |
| Persistence | `UserDefaults` | Store preferences (launch at login, pinned contexts) |
| Package manager | Swift Package Manager (SPM) only | No CocoaPods, no Carthage |
| Min deployment | macOS 13.0 | `MenuBarExtra` requires macOS 13 |
| Architecture | MVVM | Clean separation of view/logic |

### SPM Dependencies
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
    // LaunchAtLogin via ServiceManagement framework (built-in, no SPM needed)
]
```

---

## 4. App Architecture

```
KubeCtxBar/
├── KubeCtxBarApp.swift          # @main entry point, MenuBarExtra scene
├── CLAUDE.md                    # Claude Code project memory (see below)
│
├── Core/
│   ├── KubeConfigParser.swift   # Parse ~/.kube/config + KUBECONFIG env var
│   ├── KubeConfigWatcher.swift  # DispatchSource file watcher
│   ├── ContextSwitcher.swift    # Shell: kubectl config use-context
│   └── Models/
│       ├── KubeContext.swift    # Context model (name, cluster, user, namespace)
│       └── KubeConfig.swift     # Full kubeconfig model
│
├── ViewModels/
│   └── ContextListViewModel.swift  # @Observable, bridges Core → Views
│
├── Views/
│   ├── MenuBarPopover.swift     # Root popover view (glass container)
│   ├── ContextRowView.swift     # Single context row with active indicator
│   ├── SearchBarView.swift      # Filter input at top of popover
│   ├── NamespaceBadge.swift     # Namespace pill badge
│   └── SettingsView.swift       # Preferences panel
│
├── Design/
│   └── DesignSystem.swift       # Colors, fonts, spacing constants
│
└── Resources/
    ├── Assets.xcassets          # App icons, menu bar icon (SF Symbol or custom)
    └── Info.plist
```

---

## 5. Functional Requirements

### FR-01: Menu Bar Icon
- Show a small Kubernetes wheel icon (use SF Symbol `"kubernetes"` if available, else custom SVG rendered as `NSImage` 18×18pt)
- Icon tint: matches system appearance (white on dark menubar, black on light)
- Show active context name abbreviated next to icon (truncate at 20 chars with `…`)
- Fallback icon text: `⎈` (helm/kube symbol, Unicode U+2388)

### FR-02: Popover Window
- Opens directly below the menu bar icon on click
- Width: 320pt fixed
- Height: dynamic, min 200pt, max 500pt (scrollable list)
- Click outside → dismiss popover

### FR-03: Context List
- Parse `~/.kube/config` on launch and on file change
- Also parse paths in `KUBECONFIG` environment variable (colon-separated)
- Merge all contexts, deduplicate by name
- Sort: active context first, then alphabetical
- Show for each row:
  - Context name (primary label)
  - Cluster name (secondary label, smaller, muted)
  - Namespace badge (if set, show pill with namespace name)
  - Active indicator: filled green circle on the left, or checkmark `✓`

### FR-04: Context Switching
- Tap a non-active row → run `kubectl config use-context <name>`
- Use `Process` to shell out, capture stderr
- On success: update ViewModel, show brief success flash on the row
- On error: show inline error banner at bottom of popover (red, dismissible)
- Do NOT show a system notification for routine switching (too noisy)

### FR-05: Search / Filter
- Search bar at top of context list
- Filters contexts in real-time by name or cluster name (case-insensitive, substring match)
- Show "No results" empty state with a small message

### FR-06: File Watching
- Watch `~/.kube/config` for changes using `DispatchSource`
- If `KUBECONFIG` is set, watch all paths listed
- Debounce reloads by 300ms to handle editors that write files in multiple steps
- On reload: preserve scroll position, keep the same active context selected

### FR-07: Settings Panel
- Accessible via gear icon in popover footer
- Options:
  - Launch at Login toggle (using `SMAppService` on macOS 13+)
  - Show namespace badge (toggle, default: ON)
  - Show cluster name (toggle, default: ON)
  - Additional kubeconfig paths (text field, comma or colon separated)

### FR-08: Keyboard Navigation
- `↑` / `↓` to navigate rows
- `Enter` / `Space` to switch to highlighted context
- `Escape` to dismiss popover
- `/` or `⌘F` to focus search bar

### FR-09: Empty State
- If no contexts found: show centered empty state illustration (SF Symbol `"server.rack"` large) with text "No contexts found in ~/.kube/config"

---

## 6. Design System — Premium Glass UI

> **IMPORTANT FOR CLAUDE CODE:** This is non-negotiable. The app must look premium. Do not use default SwiftUI list styles or plain backgrounds.

### 6.1 Visual Theme

| Token | Light Mode | Dark Mode |
|-------|-----------|-----------|
| `bg.primary` | `rgba(245,245,247,0.85)` | `rgba(28,28,30,0.85)` |
| `bg.row.hover` | `rgba(0,0,0,0.06)` | `rgba(255,255,255,0.08)` |
| `bg.row.active` | `rgba(52,199,89,0.15)` | `rgba(52,199,89,0.20)` |
| `accent.green` | `#34C759` (system green) | `#34C759` |
| `accent.blue` | `#007AFF` (system blue) | `#0A84FF` |
| `text.primary` | `#1C1C1E` | `#F2F2F7` |
| `text.secondary` | `#8E8E93` | `#8E8E93` |
| `border` | `rgba(0,0,0,0.08)` | `rgba(255,255,255,0.10)` |
| `shadow` | `rgba(0,0,0,0.15)` blur 20 | `rgba(0,0,0,0.40)` blur 20 |

### 6.2 Glass Morphism Container

```swift
// Apply to the root popover view
.background(.ultraThinMaterial)
.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
.shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 8)
.overlay(
    RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(.white.opacity(0.15), lineWidth: 0.5)
)
```

### 6.3 Typography

| Usage | Font | Size | Weight |
|-------|------|------|--------|
| Context name | SF Pro | 13pt | `.medium` |
| Cluster/namespace label | SF Pro | 11pt | `.regular` |
| Section headers | SF Pro | 11pt | `.semibold` |
| Search bar placeholder | SF Pro | 13pt | `.regular` |
| Active indicator label | SF Pro Rounded | 11pt | `.bold` |

Always use `Font.system(size:, weight:, design: .rounded)` for numeric/badge text.

### 6.4 Context Row Anatomy

```
┌─────────────────────────────────────────────────────┐
│  ●  context-name-here              [namespace-pill]  │
│     cluster.endpoint.io                              │
└─────────────────────────────────────────────────────┘

● = filled green circle (active) or empty circle (inactive)
[namespace-pill] = rounded rect, accent blue background, white text
```

Row height: 52pt. Corner radius on hover: 10pt. Horizontal padding: 12pt.

### 6.5 Animations
- Row tap: scale to 0.97 → spring back, duration 0.15s
- Popover appear: opacity 0→1 + translateY(-6→0), spring, damping 0.8
- Active context change: green circle animates with `.spring(response: 0.3)`
- Search filter: `.animation(.easeInOut(duration: 0.15), value: filteredContexts)`

### 6.6 Menu Bar Icon State
- Idle: `⎈` or kubernetes icon, system color
- Switching in progress: pulsing opacity animation on icon (0.5→1.0 loop)
- Error state: badge a small red dot on the icon using `NSStatusItem` overlay

---

## 7. Data Model

```swift
// Models/KubeContext.swift
struct KubeContext: Identifiable, Hashable {
    let id: String          // == name (unique per kubeconfig)
    let name: String        // context name as in kubeconfig
    let clusterName: String // cluster reference name
    let userName: String    // user reference name
    let namespace: String?  // optional namespace override
    let sourceFile: URL     // which kubeconfig file this came from
}

// Models/KubeConfig.swift
struct KubeConfig {
    let contexts: [KubeContext]
    let currentContext: String?
    let sourceFiles: [URL]
}
```

---

## 8. KubeConfig Parser — Exact Behavior

```
Path resolution order:
1. Check KUBECONFIG environment variable → split by ":"
2. If KUBECONFIG is empty → use ["~/.kube/config"]
3. Expand ~ using FileManager.default.homeDirectoryForCurrentUser
4. Skip paths that don't exist (no error, just skip)
5. Parse each with Yams, extract contexts array
6. Merge: if same context name appears in multiple files, first-file wins
7. currentContext comes from first file that defines it
```

---

## 9. Context Switching — Exact Behavior

```swift
// ContextSwitcher.swift
func switchContext(to name: String) async throws {
    // 1. Find kubectl: check /usr/local/bin/kubectl, /opt/homebrew/bin/kubectl, 
    //    /usr/bin/kubectl, then PATH via `which kubectl`
    // 2. Run: kubectl config use-context <name>
    // 3. Capture stdout + stderr
    // 4. Exit code 0 → success, update ViewModel.currentContext
    // 5. Non-zero exit → throw ContextSwitchError.kubectlFailed(stderr)
    // 6. Timeout: 5 seconds max
}
```

**Do NOT directly modify the kubeconfig YAML file.** Always shell to `kubectl` so it handles merging, backups, and file locking correctly.

---

## 10. Error Handling

| Error | User-facing message | Recovery |
|-------|--------------------|-|
| kubectl not found | "kubectl not found. Install with: brew install kubectl" | Show message with copy button |
| kubeconfig parse failure | "Could not read ~/.kube/config" | Show error, still show any contexts that parsed |
| Context switch failure | Stderr from kubectl | Red banner at popover bottom, auto-dismiss 5s |
| File permission denied | "Cannot read kubeconfig (permission denied)" | Show error icon next to header |

---

## 11. Acceptance Criteria

Each feature MUST pass before the feature is considered complete.

| ID | Criterion |
|----|-----------|
| AC-01 | App icon appears in macOS menu bar after launch |
| AC-02 | Clicking icon opens popover within 100ms |
| AC-03 | All contexts from `~/.kube/config` appear in list |
| AC-04 | Active context shows green indicator |
| AC-05 | Clicking a non-active context runs `kubectl config use-context` |
| AC-06 | After switch, green indicator moves to new context |
| AC-07 | Modifying kubeconfig externally refreshes list within 1 second |
| AC-08 | Search filters results in real time |
| AC-09 | App uses `.ultraThinMaterial` background (glass effect) |
| AC-10 | App does NOT appear in Dock or ⌘+Tab app switcher |
| AC-11 | Launch at Login setting persists across reboots |
| AC-12 | `KUBECONFIG` env var paths are respected |
| AC-13 | Keyboard navigation works (↑↓ Enter Esc) |
| AC-14 | Empty state shows when no contexts found |
| AC-15 | App binary is Apple Silicon native (arm64) |

---

## 12. Out of Scope (v1.0)

- Namespace switching within a context (v2 feature)
- Cluster health/status indicators (requires API calls, v2)
- Multiple window support
- iOS/iPadOS version
- Sparkle auto-update (v1.1)
- Direct kubeconfig editing in UI
- Cloud provider SSO/auth refresh (EKS token refresh, GKE auth)

---

## 13. File & Build Conventions

- **Xcode project name:** `KubeCtxBar`
- **Bundle ID:** `com.yourdomain.kubectxbar` (replace `yourdomain`)
- **Deployment target:** macOS 13.0
- **Swift version:** 5.10 minimum, prefer Swift 6 concurrency (`async/await`, `@Observable`)
- **No Storyboards, no XIBs** — SwiftUI only
- **LSUIElement = YES** in Info.plist (hide from Dock and app switcher)
- **NSPrincipalClass** must NOT be set (SwiftUI @main handles this)
- Code style: 4-space indentation, `// MARK: -` section dividers
- All async work on `@MainActor` unless explicitly documented otherwise
- No `DispatchQueue.main.async` — use `await MainActor.run {}` or `@MainActor` annotation

---

## 14. Implementation Phases

### Phase 1 — Core Shell (implement first, get working)
1. Xcode project setup with `MenuBarExtra`
2. `KubeConfigParser` — parse `~/.kube/config` with Yams
3. Basic context list in popover (no styling)
4. `ContextSwitcher` — shell to kubectl
5. Verify AC-01 through AC-06

### Phase 2 — Premium UI
1. Apply glass morphism background
2. `ContextRowView` with animated active indicator
3. `SearchBarView`
4. Popover appear/dismiss animations
5. Verify AC-07 through AC-09

### Phase 3 — Polish & Settings
1. `KubeConfigWatcher` — real-time file watching
2. `SettingsView` with launch at login
3. Keyboard navigation
4. Empty state, error states
5. Verify all remaining ACs (AC-10 through AC-15)

> **Claude Code instruction:** Complete Phase 1 fully before starting Phase 2. Run `swift build` after each file to catch errors early. Do not accumulate build errors.

---

## 15. Testing Checklist

Run these manual tests after each phase:

```
[ ] App launches without crash
[ ] Menu bar icon visible
[ ] Popover opens on click
[ ] Popover dismisses on outside click
[ ] Contexts load from ~/.kube/config
[ ] Context switch works (check kubectl config current-context after)
[ ] Switch error shows correctly (test with invalid context name)
[ ] Edit kubeconfig externally → list refreshes
[ ] Search works
[ ] Settings toggle persists after relaunch
[ ] App not in Dock
[ ] App not in ⌘+Tab
```
