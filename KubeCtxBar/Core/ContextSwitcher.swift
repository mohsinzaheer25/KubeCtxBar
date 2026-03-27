import Foundation
import OSLog

// MARK: - Errors

enum ContextSwitchError: LocalizedError {
    case kubectlNotFound
    case switchFailed(String)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .kubectlNotFound:
            return "kubectl not found. Install with: brew install kubectl"
        case .switchFailed(let stderr):
            return stderr.isEmpty ? "Context switch failed" : stderr
        case .timeout:
            return "Context switch timed out"
        }
    }
}

// MARK: - Context Switcher

actor ContextSwitcher {
    
    private static let logger = Logger(subsystem: "com.kubectxbar.app", category: "Switcher")
    
    private let kubectlPaths = [
        "/opt/homebrew/bin/kubectl",
        "/usr/local/bin/kubectl",
        "/usr/bin/kubectl"
    ]
    
    // MARK: - Public API
    
    func switchContext(to name: String) async throws {
        let kubectlPath = try findKubectl()
        
        Self.logger.info("Switching to context: \(name)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: kubectlPath)
        process.arguments = ["config", "use-context", name]
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        do {
            try process.run()
        } catch {
            Self.logger.error("Failed to launch kubectl: \(error.localizedDescription)")
            throw ContextSwitchError.switchFailed("Failed to run kubectl: \(error.localizedDescription)")
        }
        
        let completed = await withCheckedContinuation { continuation in
            Task {
                let timeoutTask = Task {
                    try await Task.sleep(for: .seconds(5))
                    return false
                }
                
                let waitTask = Task.detached {
                    process.waitUntilExit()
                    return true
                }
                
                if let result = await waitTask.value as Bool? {
                    timeoutTask.cancel()
                    continuation.resume(returning: result)
                } else if (try? await timeoutTask.value) == false {
                    process.terminate()
                    continuation.resume(returning: false)
                }
            }
        }
        
        guard completed else {
            Self.logger.error("kubectl timed out")
            throw ContextSwitchError.timeout
        }
        
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stderr = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if process.terminationStatus != 0 {
            Self.logger.error("kubectl failed: \(stderr)")
            throw ContextSwitchError.switchFailed(stderr)
        }
        
        Self.logger.info("Successfully switched to context: \(name)")
    }
    
    // MARK: - kubectl Discovery
    
    private func findKubectl() throws -> String {
        for path in kubectlPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                Self.logger.debug("Found kubectl at: \(path)")
                return path
            }
        }
        
        if let pathFromWhich = findKubectlViaWhich() {
            return pathFromWhich
        }
        
        Self.logger.error("kubectl not found in any known location")
        throw ContextSwitchError.kubectlNotFound
    }
    
    private func findKubectlViaWhich() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["kubectl"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !path.isEmpty,
                   FileManager.default.isExecutableFile(atPath: path) {
                    Self.logger.debug("Found kubectl via which: \(path)")
                    return path
                }
            }
        } catch {
            Self.logger.debug("which kubectl failed: \(error.localizedDescription)")
        }
        
        return nil
    }
}
