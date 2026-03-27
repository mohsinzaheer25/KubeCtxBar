import Foundation
import OSLog
import SwiftUI

// MARK: - View Model

@MainActor
class ContextListViewModel: ObservableObject {
    
    private static let logger = Logger(subsystem: "com.kubectxbar.app", category: "ViewModel")
    
    // MARK: - Published State
    
    @Published var contexts: [KubeContext] = []
    @Published var currentContext: String?
    @Published var isLoading = false
    @Published var isSwitching = false
    @Published var searchText = ""
    @Published var errorMessage: String?
    @Published var showSettings = false
    @Published var recentlySwitchedContext: String?
    
    // MARK: - Dependencies
    
    private let parser: KubeConfigParser
    private let switcher: ContextSwitcher
    private var watcher: KubeConfigWatcher?
    
    // MARK: - Testing Support
    
    init(parser: KubeConfigParser = KubeConfigParser(), switcher: ContextSwitcher = ContextSwitcher()) {
        self.parser = parser
        self.switcher = switcher
    }
    
    // MARK: - Computed Properties
    
    var filteredContexts: [KubeContext] {
        let sorted = contexts.sorted { lhs, rhs in
            if lhs.name == currentContext { return true }
            if rhs.name == currentContext { return false }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
        
        guard !searchText.isEmpty else { return sorted }
        
        let query = searchText.lowercased()
        return sorted.filter { context in
            context.name.lowercased().contains(query) ||
            context.clusterName.lowercased().contains(query) ||
            context.displayName.lowercased().contains(query) ||
            context.displayClusterName.lowercased().contains(query)
        }
    }
    
    var hasContexts: Bool {
        !contexts.isEmpty
    }
    
    var menuBarTitle: String {
        guard let current = currentContext else { return "⎈" }
        if current.count > 20 {
            return String(current.prefix(19)) + "…"
        }
        return current
    }
    
    // MARK: - Initialization
    
    convenience init() {
        self.init(parser: KubeConfigParser(), switcher: ContextSwitcher())
        Task {
            await loadContexts()
            setupWatcher()
        }
    }
    
    // MARK: - Public Actions
    
    func loadContexts() async {
        Self.logger.debug("Loading contexts")
        isLoading = true
        errorMessage = nil
        
        do {
            let config = try parser.parse()
            contexts = config.contexts
            currentContext = config.currentContext
            Self.logger.info("Loaded \(config.contexts.count) contexts, current: \(config.currentContext ?? "none")")
        } catch {
            Self.logger.error("Failed to load contexts: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func switchTo(_ context: KubeContext) async {
        guard context.name != currentContext else { return }
        
        Self.logger.info("User requested switch to: \(context.name)")
        isSwitching = true
        errorMessage = nil
        
        do {
            try await switcher.switchContext(to: context.name)
            currentContext = context.name
            
            recentlySwitchedContext = context.name
            Task {
                try? await Task.sleep(for: .milliseconds(800))
                recentlySwitchedContext = nil
            }
            
        } catch {
            Self.logger.error("Switch failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            
            Task {
                try? await Task.sleep(for: .seconds(5))
                if errorMessage == error.localizedDescription {
                    errorMessage = nil
                }
            }
        }
        
        isSwitching = false
    }
    
    func dismissError() {
        errorMessage = nil
    }
    
    func refresh() async {
        await loadContexts()
    }
    
    // MARK: - File Watching
    
    private func setupWatcher() {
        let paths = parser.resolveKubeconfigPaths()
        guard !paths.isEmpty else {
            Self.logger.warning("No kubeconfig paths to watch")
            return
        }
        
        watcher = KubeConfigWatcher(paths: paths) { [weak self] in
            Task { @MainActor [weak self] in
                Self.logger.debug("Kubeconfig changed, reloading")
                await self?.loadContexts()
            }
        }
        watcher?.start()
    }
}
