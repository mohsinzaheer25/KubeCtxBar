import Foundation
import OSLog

final class KubeConfigWatcher {
    
    private static let logger = Logger(subsystem: "com.kubectxbar.app", category: "Watcher")
    
    private let paths: [URL]
    private let onChange: @Sendable () -> Void
    private var sources: [DispatchSourceFileSystemObject] = []
    private var fileDescriptors: [Int32] = []
    private let debounceInterval: TimeInterval = 0.3
    private var debounceWorkItem: DispatchWorkItem?
    
    init(paths: [URL], onChange: @escaping @Sendable () -> Void) {
        self.paths = paths
        self.onChange = onChange
    }
    
    deinit {
        stop()
    }
    
    func start() {
        stop()
        
        for path in paths {
            watchFile(at: path)
        }
        
        Self.logger.info("Started watching \(self.paths.count) kubeconfig file(s)")
    }
    
    func stop() {
        for source in sources {
            source.cancel()
        }
        sources.removeAll()
        
        for fd in fileDescriptors {
            close(fd)
        }
        fileDescriptors.removeAll()
        
        debounceWorkItem?.cancel()
        debounceWorkItem = nil
    }
    
    private func watchFile(at url: URL) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            Self.logger.error("Failed to open file for watching: \(url.path)")
            return
        }
        
        fileDescriptors.append(fd)
        
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .extend],
            queue: .main
        )
        
        source.setEventHandler { [weak self] in
            self?.handleFileChange(url: url)
        }
        
        source.setCancelHandler {
            close(fd)
        }
        
        source.resume()
        sources.append(source)
        
        Self.logger.debug("Watching: \(url.path)")
    }
    
    private func handleFileChange(url: URL) {
        Self.logger.debug("File changed: \(url.path)")
        
        debounceWorkItem?.cancel()
        
        let workItem = DispatchWorkItem { [weak self] in
            self?.onChange()
        }
        
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
}
